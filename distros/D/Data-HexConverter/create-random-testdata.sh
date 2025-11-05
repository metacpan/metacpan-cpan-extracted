#!/usr/bin/env bash

# This script generates random test hex data files for testing purposes.

dataFile="testdata.hex"
> $dataFile

for i in {1..1000}; do
	size=$(((RANDOM * 64) + 517))
	dd status=none if=/dev/urandom bs=$size count=1 | hexdump -ve '1/1 "%.2x"' \
		| dd status=none conv=ucase \
		| awk '{ printf("%s\n",$0) }' >> $dataFile

	echo "Added $size bytes to $dataFile"
done

