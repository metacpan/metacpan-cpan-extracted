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

hash FastTree 2>/dev/null || {
    echo >&2 "FastTree is required but it's not installed.";
}

hash nw_order 2>/dev/null || {
    echo >&2 "newick-utils is required but it's not installed.";
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

hash spanr 2>/dev/null || {
    echo >&2 "spanr is required but it's not installed.";
    exit 1;
}

hash linkr 2>/dev/null || {
    echo >&2 "linkr is required but it's not installed.";
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

Rscript -e 'if(!require(ape)){ q(status = 1) }' 2>/dev/null || {
    echo >&2 "R package ape is optional but it's not installed.";
}

Rscript -e 'if(!require(tidyr)){ q(status = 1) }' 2>/dev/null || {
    echo >&2 "R package tidyr is optional but it's not installed.";
}

Rscript -e 'if(!require(readr)){ q(status = 1) }' 2>/dev/null || {
    echo >&2 "R package readr is optional but it's not installed.";
}

hash tsv-select 2>/dev/null || {
    echo >&2 "tsv-utils is optional but it's not installed.";
    exit 1;
}

hash circos 2>/dev/null || {
    echo >&2 "circos is optional but it's not installed.";
}

hash RepeatMasker 2>/dev/null || {
    echo >&2 "RepeatMasker is optional but it's not installed.";
}

hash snp-sites 2>/dev/null || {
    echo >&2 "snp-sites is optional but it's not installed.";
}

hash bcftools 2>/dev/null || {
    echo >&2 "bcftools is optional but it's not installed.";
}

hash raxmlHPC 2>/dev/null || hash raxmlHPC-SSE3 2>/dev/null || hash raxmlHPC-PTHREADS 2>/dev/null || {
    echo >&2 "raxml is optional but it's not installed.";
    exit 1;
}

echo >&2 OK

exit;
