#!/bin/bash
# compares validating Bags with different fixity algorithms
#
# needs hyperfine

testdir=$1

if [[ ! -d "$testdir" ]]; then
  echo "Error, no existing testdir givem, got '$testdir'"
  exit;
fi

TMPDIR=$(mktemp -d)

echo -n "preparing..."
for ALGO in blake3 md5 sha256 sha512; do
  mkdir "${TMPDIR}/${ALGO}"
  cp -a "${testdir}" "${TMPDIR}/${ALGO}/"
  perl -I ../lib/ "store_bag_${ALGO}.pl" "${TMPDIR}/${ALGO}"
done
echo " ... done"

hyperfine --warmup 1 \
          --parameter-list ALGO blake3,md5,sha256,sha512 \
          "perl -I ../lib verify_bag_{ALGO}.pl ${TMPDIR}/${ALGO}"

rm -Rf "${TMPDIR}"