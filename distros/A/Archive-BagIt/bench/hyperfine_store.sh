#!/bin/bash
# compares storing Bags with different fixity algorithms
#
# needs hyperfine

testdir=$1

if [[ ! -d "$testdir" ]]; then
  echo "Error, no existing testdir givem, got '$testdir'"
  exit;
fi

TMPDIR=$(mktemp -d)

hyperfine --prepare "cp -a $testdir ${TMPDIR}" \
          --parameter-list ALGO blake3,md5,sha256,sha512 \
          --ignore-failure "perl -I ../lib store_bag_{ALGO}.pl" \
          --cleanup "rm -Rf ${TMPDIR}/*"

rm -Rf "${TMPDIR}"