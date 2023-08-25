#!/bin/bash

WORKDIR=${0%/*}
BASEDIR="$WORKDIR/.."
cd "$BASEDIR" || exit

if [[ ! -f Makefile ]]; then
    perl Makefile.PL || exit
fi

if ! make test TEST_FILES='t/*.t dev-t/*.t'; then
    printf 'Developer tests failed!\n' >&2
    exit 1
fi
