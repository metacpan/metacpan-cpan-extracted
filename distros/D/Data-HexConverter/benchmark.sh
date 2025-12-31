#!/usr/bin/env bash

# run benchmark.pl with all available implementations and collect results
#

banner () {
	echo
	echo "=============================="
	echo "$*"
	echo "=============================="
	echo
}

echo
echo "avx512 may not be supported on all CPUs, fallback is most likely avx2"

for hex2binImplemtation in scalar sse2 avx2 avx512
do
	banner "hex2bin: $hex2binImplemtation"
	HEXSIMD_FORCE=$hex2binImplemtation ./benchmark.pl
done

echo

