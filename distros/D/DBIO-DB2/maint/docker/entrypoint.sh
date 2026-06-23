#!/bin/bash
# Entrypoint for the dbio-db2 integration test container.
#
# 1. Install per-repo cpanfile deps against the mounted source (dbio core is
#    not on CPAN, so it is mounted, not installed).
# 2. Wait for the DB2 server to accept connections.
# 3. Run the integration tests with dbio core on @INC.
set -euo pipefail

DBIO_CORE=${DBIO_CORE:-/src/dbio}
DBIO_DB2=${DBIO_DB2:-/src/dbio-db2}

echo "==> Installing cpanfile deps (dbio core + dbio-db2)"
cpanm --notest --installdeps "$DBIO_CORE"  || true
cpanm --notest --installdeps "$DBIO_DB2"   || true

echo "==> Waiting for DB2 at ${DBIO_TEST_DB2_DSN}"
# Probe with a trivial connect loop. DB2 first-boot instance setup is slow
# (minutes), so allow a generous window.
tries=0
until perl -MDBI -e '
    use strict; use warnings;
    my ($dsn,$u,$p) = @ENV{qw/DBIO_TEST_DB2_DSN DBIO_TEST_DB2_USER DBIO_TEST_DB2_PASS/};
    my $dbh = DBI->connect($dsn, $u, $p, { RaiseError => 1, PrintError => 0 });
    $dbh->disconnect; exit 0;
  ' 2>/dev/null; do
  tries=$((tries+1))
  if [ "$tries" -ge 120 ]; then
    echo "!! DB2 did not become reachable in time" >&2
    exit 1
  fi
  sleep 5
done
echo "==> DB2 reachable after $((tries*5))s"

cd "$DBIO_DB2"
# With explicit args, run exactly those test files; otherwise run the whole
# suite (offline tests pass too, the integration ones now have a live DB2).
if [ "$#" -gt 0 ]; then
  exec prove -lv -I"$DBIO_CORE/lib" "$@"
else
  exec prove -lv -I"$DBIO_CORE/lib" t/
fi
