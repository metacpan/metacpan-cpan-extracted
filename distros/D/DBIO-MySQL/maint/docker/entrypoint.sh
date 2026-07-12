#!/bin/bash
# Entrypoint for the dbio-mysql genuine-DBD::mysql test container.
#
# The image bakes the slow, host-unbuildable part: genuine Oracle
# libmysqlclient-dev + DBD::mysql (see Dockerfile.test for WHY the host cannot
# build it). Source is mounted, not baked, so editing tests never rebuilds:
#
#   /src/dbio         dbio core        (CPAN lags the dev tree -> mounted, -I wins)
#   /src/dbio-async   DBIO::Async      (NOT on CPAN at all -> mounted)
#   /src/dbio-mysql   this dist        (the driver under test -> mounted)
#
# Steps:
#   1. Install any cpanfile-dep delta the baked base image is missing (the heavy
#      tree is already baked; this only catches deps added to the dev cpanfiles
#      since the image was built). Non-fatal: a missing module surfaces loudly in
#      the test run itself.
#   2. Wait for the MySQL server to accept a real dbi:mysql: connection through
#      the genuine DBD::mysql client (proves auth + the driver, not just a TCP
#      port). compose already gates on healthcheck; this is the belt-and-braces
#      driver-level probe.
#   3. Run the tests with dbio core + dbio-async + this dist prepended to @INC so
#      the mounted dev copies win over anything installed from CPAN.
#
# Default target is t/55-future-io-live.t (the live future_io roundtrip that
# needs a real DB); pass explicit files to run others.
set -euo pipefail

DBIO_CORE=${DBIO_CORE:-/src/dbio}
DBIO_ASYNC=${DBIO_ASYNC:-/src/dbio-async}
DBIO_MYSQL=${DBIO_MYSQL:-/src/dbio-mysql}

# -I order: this dist first, then async, then core. All ahead of site_perl so the
# mounted dev code wins (the CPAN DBIO is baked only for its dependency tree).
INC="-I${DBIO_MYSQL}/lib -I${DBIO_ASYNC}/lib -I${DBIO_CORE}/lib"

echo "==> Installing any cpanfile-dep delta (heavy tree is already baked)"
cpanm --notest --installdeps "$DBIO_CORE"  || true
cpanm --notest --installdeps "$DBIO_ASYNC" || true
cpanm --notest --installdeps "$DBIO_MYSQL" || true

echo "==> Waiting for MySQL at ${DBIO_TEST_MYSQL_DSN} via genuine DBD::mysql"
tries=0
until perl -MDBI -e '
    use strict; use warnings;
    my ($dsn,$u,$p) = @ENV{qw/DBIO_TEST_MYSQL_DSN DBIO_TEST_MYSQL_USER DBIO_TEST_MYSQL_PASS/};
    my $dbh = DBI->connect($dsn, $u, $p, { RaiseError => 1, PrintError => 0 });
    $dbh->disconnect; exit 0;
  ' 2>/dev/null; do
  tries=$((tries+1))
  if [ "$tries" -ge 60 ]; then
    echo "!! MySQL did not become reachable via DBD::mysql in time" >&2
    exit 1
  fi
  sleep 3
done
echo "==> MySQL reachable after $((tries*3))s"

cd "$DBIO_MYSQL"
if [ "$#" -gt 0 ]; then
  # shellcheck disable=SC2086
  exec nice -n 19 ionice -c3 prove -lv $INC "$@"
else
  # shellcheck disable=SC2086
  exec nice -n 19 ionice -c3 prove -lv $INC t/55-future-io-live.t
fi
