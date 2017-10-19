#!/usr/bin/env bash

# Check external dependencies

#----------------------------#
# prepare
#----------------------------#
hash seqtk 2>/dev/null || {
    echo >&2 "seqtk is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install homebrew/science/seqtk";
    exit 1;
}

hash fastqc 2>/dev/null || {
    echo >&2 "fastqc is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install homebrew/science/fastqc";
    exit 1;
}

hash tally 2>/dev/null || {
    echo >&2 "tally is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install wang-q/tap/reaper";
    exit 1;
}

hash sickle 2>/dev/null || {
    echo >&2 "sickle is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install homebrew/science/sickle";
    exit 1;
}

hash scythe 2>/dev/null || {
    echo >&2 "scythe is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install wang-q/tap/scythe";
    exit 1;
}

hash faops 2>/dev/null || {
    echo >&2 "faops is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install wang-q/tap/faops";
    exit 1;
}

#----------------------------#
# superreads
#----------------------------#
hash jellyfish 2>/dev/null || {
    echo >&2 "jellyfish is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install homebrew/science/jellyfish";
    exit 1;
}

hash jq 2>/dev/null || {
    echo >&2 "jq is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install jq";
    exit 1;
}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    hash create_k_unitigs_large_k 2>/dev/null || {
        echo >&2 "superreads is required but it's not installed.";
        echo >&2 "Install with homebrew: brew install wang-q/tap/superreads";
        exit 1;
    }
fi

#----------------------------#
# anchors
#----------------------------#
hash bbmap.sh 2>/dev/null || {
    echo >&2 "bbmap.sh is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install homebrew/science/bbtools";
    exit 1;
}

hash jrunlist 2>/dev/null || {
    echo >&2 "jrunlist is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install wang-q/tap/jrunlist";
    exit 1;
}

hash runlist 2>/dev/null || {
    echo >&2 "runlist is required but it's not installed.";
    echo >&2 "Install with cpanm: cpanm App::RL";
    exit 1;
}

#----------------------------#
# group anchors
#----------------------------#
# faops
# runlist

hash dot 2>/dev/null || {
    echo >&2 "GraphViz is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install graphviz";
    exit 1;
}

hash fasta2DB 2>/dev/null || {
    echo >&2 "DAZZ_DB is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install wang-q/tap/dazz_db@20161112";
    exit 1;
}

hash daligner 2>/dev/null || {
    echo >&2 "daligner is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install wang-q/tap/daligner@20170203";
    exit 1;
}

hash jrange 2>/dev/null || {
    echo >&2 "jrange is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install wang-q/tap/jrange";
    exit 1;
}

hash minimap 2>/dev/null || {
    echo >&2 "minimap is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install homebrew/science/minimap";
    exit 1;
}

hash miniasm 2>/dev/null || {
    echo >&2 "miniasm is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install homebrew/science/miniasm";
    exit 1;
}

hash poa 2>/dev/null || {
    echo >&2 "poa is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install homebrew/science/poa";
    exit 1;
}

perl -MGraphViz -e "1" 2>/dev/null || {
    echo >&2 "GraphViz is required but it's not installed.";
    echo >&2 "Install with cpanm: cpanm GraphViz";
    exit 1;
}

perl -MAlignDB::IntSpan -e "1" 2>/dev/null || {
    echo >&2 "AlignDB::IntSpan is required but it's not installed.";
    echo >&2 "Install with cpanm: cpanm AlignDB::IntSpan";
    exit 1;
}

perl -MGraph -e "1" 2>/dev/null || {
    echo >&2 "Graph is required but it's not installed.";
    echo >&2 "Install with cpanm: cpanm Graph";
    exit 1;
}

#----------------------------#
# sr_stat.sh
#----------------------------#
# faops

perl -MNumber::Format -e "1" 2>/dev/null || {
    echo >&2 "Number::Format is required but it's not installed.";
    echo >&2 "Install with cpanm: cpanm Number::Format";
    exit 1;
}

#----------------------------#
# sort_on_ref.sh
#----------------------------#
# faops

hash sparsemem 2>/dev/null || {
    echo >&2 "sparsemem is required but it's not installed.";
    echo >&2 "Install with homebrew: brew install wang-q/tap/sparsemem";
    exit 1;
}

hash fasops 2>/dev/null || {
    echo >&2 "fasops is required but it's not installed.";
    echo >&2 "Install with cpanm: cpanm App::Fasops";
    exit 1;
}

hash rangeops 2>/dev/null || {
    echo >&2 "rangeops is required but it's not installed.";
    echo >&2 "Install with cpanm: cpanm App::Rangeops";
    exit 1;
}

echo OK
