#!/usr/bin/env bash

# Check external dependencies

#----------------------------#
# required
#----------------------------#
hash pigz 2>/dev/null || {
    echo >&2 "pigz is required but it's not installed.";
    exit 1;
}

hash samtools 2>/dev/null || {
    echo >&2 "samtools is required but it's not installed.";
    exit 1;
}

hash mummer 2>/dev/null || hash sparsemem 2>/dev/null || {
    echo >&2 "mummer or sparsemem is required but it's not installed.";
    exit 1;
}

hash raxmlHPC 2>/dev/null || hash raxmlHPC-PTHREADS 2>/dev/null || {
    echo >&2 "raxml is required but it's not installed.";
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

hash multiz 2>/dev/null || {
    echo >&2 "multiz is required but it's not installed.";
    exit 1;
}

hash mafft 2>/dev/null || {
    echo >&2 "mafft is required but it's not installed.";
    exit 1;
}

hash fasops 2>/dev/null || {
    echo >&2 "fasops is required but it's not installed.";
    exit 1;
}

hash rangeops 2>/dev/null || {
    echo >&2 "rangeops is required but it's not installed.";
    exit 1;
}

#----------------------------#
# kent-tools
#----------------------------#
for f in faToTwoBit axtChain chainAntiRepeat chainMergeSort chainPreNet chainNet netSyntenic netChainSubset chainStitchId netSplit netToAxt axtSort axtToMaf netFilter chainSplit; do
    hash ${f} 2>/dev/null || {
        echo >&2 "${f} from kent-tools is required but it's not installed.";
        exit 1;
    }
done

#----------------------------#
# optional
#----------------------------#
hash Rscript 2>/dev/null || {
    echo >&2 "R is required but it's not installed.";
}

hash circos 2>/dev/null || {
    echo >&2 "circos is optional but it's not installed.";
}

hash RepeatMasker 2>/dev/null || {
    echo >&2 "RepeatMasker is optional but it's not installed.";
}

hash jrange 2>/dev/null || {
    echo >&2 "jrange is optional but it's not installed.";
}

hash snp-sites 2>/dev/null || {
    echo >&2 "snp-sites is optional but it's not installed.";
}

hash bcftools 2>/dev/null || {
    echo >&2 "bcftools is optional but it's not installed.";
}

echo >&2 OK

exit;
