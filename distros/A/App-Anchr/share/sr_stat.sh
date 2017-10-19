#!/usr/bin/env bash

USAGE="Usage: $0 STAT_TASK(1|2) RESULT_DIR(header) [GENOME_SIZE]"

if [ "$#" -lt 1 ]; then
    echo >&2 "$USAGE"
    exit 1
fi

#----------------------------#
# Colors in term
#----------------------------#
# http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
GREEN=
RED=
NC=
if tty -s < /dev/fd/1 2> /dev/null; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    NC='\033[0m' # No Color
fi

log_warn () {
    echo >&2 -e "${RED}==> $@ <==${NC}"
}

log_info () {
    echo >&2 -e "${GREEN}==> $@${NC}"
}

log_debug () {
    echo >&2 -e "==> $@"
}

#----------------------------#
# Parameters
#----------------------------#
STAT_TASK=$1
RESULT_DIR=$2
GENOME_SIZE=$3

#----------------------------#
# Run
#----------------------------#
stat_format () {
    echo $(faops n50 -H -N 50 -S -C $1) \
        | perl -nla -MNumber::Format -e '
            printf qq{%d\t%s\t%d\n}, $F[0], Number::Format::format_bytes($F[1], base => 1000,), $F[2];
        '
}

if [ "${STAT_TASK}" = "1" ]; then
    if [ "${RESULT_DIR}" = "header" ]; then
        printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
            "Name" \
            "SumIn" "CovIn" \
            "SumOut" "CovOut" "Discard%" \
            "AvgRead" "Kmer" \
            "RealG" "EstG" "Est/Real" \
            "RunTime"
        printf "|:--|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|\n"
    elif [ "${GENOME_SIZE}" -ne "${GENOME_SIZE}" ]; then
        log_warn "Need a integer for GENOME_SIZE"
        exit 1;
    elif [ -e "${RESULT_DIR}/environment.json" ]; then
        log_debug "${RESULT_DIR}"
        cd "${RESULT_DIR}"

        SUM_IN=$( cat environment.json | jq '.SUM_IN | tonumber' )
        SUM_OUT=$( cat environment.json | jq '.SUM_OUT | tonumber' )
        EST_G=$( cat environment.json | jq '.ESTIMATED_GENOME_SIZE | tonumber' )
        SECS=$( cat environment.json | jq '.RUNTIME | tonumber' )

        printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
            $( basename $( pwd ) ) \
            $( perl -MNumber::Format -e "print Number::Format::format_bytes(${SUM_IN}, base => 1000,);" ) \
            $( perl -e "printf qq{%.1f}, ${SUM_IN} / ${GENOME_SIZE};" ) \
            $( perl -MNumber::Format -e "print Number::Format::format_bytes(${SUM_OUT}, base => 1000,);" ) \
            $( perl -e "printf qq{%.1f}, ${SUM_OUT} / ${GENOME_SIZE};" ) \
            $( perl -e "printf qq{%.3f%%}, (1 - ${SUM_OUT} / ${SUM_IN}) * 100;" ) \
            $( cat environment.json | jq '.PE_AVG_READ_LENGTH | tonumber' ) \
            $( cat environment.json | jq '.KMER' ) \
            $( perl -MNumber::Format -e "print Number::Format::format_bytes(${GENOME_SIZE}, base => 1000,);" ) \
            $( perl -MNumber::Format -e "print Number::Format::format_bytes(${EST_G}, base => 1000,);" ) \
            $( perl -e "printf qq{%.2f}, ${EST_G} / ${GENOME_SIZE}" ) \
            $( printf "%d:%02d'%02d''\n" $((${SECS}/3600)) $((${SECS}%3600/60)) $((${SECS}%60)) )
    else
        log_warn "RESULT_DIR not exists"
    fi

elif [ "${STAT_TASK}" = "2" ]; then
    if [ "${RESULT_DIR}" = "header" ]; then
        printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
            "Name" \
            "SumCor" "CovCor" \
            "N50SR"     "Sum" "#" \
            "N50Anchor" "Sum" "#" \
            "N50Others" "Sum" "#" \
            "Kmer" "RunTimeKU" "RunTimeAN"
        printf "|:--|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|\n"
    elif [ "${GENOME_SIZE}" -ne "${GENOME_SIZE}" ]; then
        log_warn "Need a integer for GENOME_SIZE"
        exit 1;
    elif [ -d "${RESULT_DIR}/anchor" ]; then
        log_debug "${RESULT_DIR}"
        cd "${RESULT_DIR}"

        SUM_COR=$( cat environment.json | jq '.SUM_COR | tonumber' )
        SECS_KU=$( cat environment.json | jq '.RUNTIME | tonumber' )
        SECS_AN=$(expr $(stat -c %Y anchor/anchor.success) - $(stat -c %Y anchor/anchors.sh))

        printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n" \
            $( basename $( pwd ) ) \
            $( perl -MNumber::Format -e "print Number::Format::format_bytes(${SUM_COR}, base => 1000,);" ) \
            $( perl -e "printf qq{%.1f}, ${SUM_COR} / ${GENOME_SIZE};" ) \
            $( stat_format anchor/SR.fasta ) \
            $( stat_format anchor/pe.anchor.fa ) \
            $( stat_format anchor/pe.others.fa ) \
            $( cat environment.json | jq '.KMER' ) \
            $( printf "%d:%02d'%02d''\n" $((${SECS_KU}/3600)) $((${SECS_KU}%3600/60)) $((${SECS_KU}%60)) ) \
            $( printf "%d:%02d'%02d''\n" $((${SECS_AN}/3600)) $((${SECS_AN}%3600/60)) $((${SECS_AN}%60)) )
    else
        log_warn "RESULT_DIR/anchor not exists"
    fi

else
    log_warn "Unsupported STAT_TASK"
fi
