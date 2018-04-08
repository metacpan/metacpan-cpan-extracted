#!/usr/bin/env bash

# Check external dependencies

#----------------------------#
# prepare
#----------------------------#
hash mummer 2>/dev/null || hash sparsemem 2>/dev/null ||{
    echo >&2 "mummer or sparsemem is required but it's not installed.";
    exit 1;
}

hash raxmlHPC 2>/dev/null || hash raxmlHPC-PTHREADS 2>/dev/null || {
    echo >&2 "raxml is required but it's not installed.";
    exit 1;
}

hash Rscript 2>/dev/null || {
    echo >&2 "R is required but it's not installed.";
    exit 1;
}

hash makeblastdb 2>/dev/null || hash blastn 2>/dev/null || {
    echo >&2 "ncbi-blast+ is required but it's not installed.";
    exit 1;
}

hash lastz 2>/dev/null || {
    echo >&2 "lastz is required but it's not installed.";
    exit 1;
}

hash faops 2>/dev/null || {
    echo >&2 "faops is required but it's not installed.";
    exit 1;
}

for f in faToTwoBit axtChain chainAntiRepeat chainMergeSort chainPreNet chainNet netSyntenic netChainSubset chainStitchId netSplit netToAxt axtSort axtToMaf netFilter chainSplit; do
    hash ${f} 2>/dev/null || {
        echo >&2 "kent-tools ${f} is required but it's not installed.";
        exit 1;
    }
done

echo OK
