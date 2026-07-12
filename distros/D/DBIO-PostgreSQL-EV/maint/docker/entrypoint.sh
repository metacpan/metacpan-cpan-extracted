#!/bin/sh
# Container entrypoint: prepend $EXTRA_LIB_DIR and /src/lib to @INC
# then hand off to prove OR perl. $EXTRA_LIB_DIR lets callers mount a
# directory of in-development Perl modules so live tests pick up the
# newest DBIO::PostgreSQL (the CPAN version lags behind and lacks
# async_backend).
#
# Why -I rather than PERL5LIB: cpanm installs site_perl under
# /usr/local/share/perl/5.36.0 which Perl walks BEFORE PERL5LIB; setting
# PERL5LIB only would still resolve DBIO::PostgreSQL from the image's
# CPAN release and silently disable the async backend. -I puts the
# mount point at the front of @INC so the dev copy always wins.
#
# /src/lib is the in-image checkout of this distribution (we COPY it into
# the image but do not install it -- cpanm --installdeps wouldn't see our
# own .pm anyway). prove -l would have done this automatically; we
# replicate it here so callers can also run the demo through `perl
# /src/demo/dbio-demo-async`.
#
# If the first arg is "perl" we run it directly (handy for `demo/` and
# one-off debugging); otherwise we hand off to prove.
set -eu

EXTRA_INC="-I /src/lib"
if [ -n "${EXTRA_LIB_DIR:-}" ] && [ -d "$EXTRA_LIB_DIR" ]; then
    EXTRA_INC="${EXTRA_INC} -I ${EXTRA_LIB_DIR}"
fi

if [ "${1:-}" = "perl" ]; then
    shift
    exec perl ${EXTRA_INC} "$@"
fi

exec prove ${EXTRA_INC} "$@"