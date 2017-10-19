#!/usr/bin/env bash

USAGE="Usage: $0 FA_FILE REF_FILE OUT_BASE"

if [ "$#" -lt 3 ]; then
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
FA_FILE=$1
REF_FILE=$2
OUT_BASE=${3:-sort}

[ -e ${FA_FILE} ] || {
    log_warn "Can't find [${FA_FILE}].";
    exit 1;
}

[ -e ${REF_FILE} ] || {
    log_warn "Can't find [${REF_FILE}].";
    exit 1;
}

#----------------------------#
# Run
#----------------------------#
# create tmp dir
MY_TMP_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`

log_info "Temp dir: ${MY_TMP_DIR}"

log_info "To positive strands"
perl ~/Scripts/egaz/sparsemem_exact.pl \
    -f ${FA_FILE} -g ${REF_FILE} \
    --length 500 -o ${MY_TMP_DIR}/replace.tsv

cat ${MY_TMP_DIR}/replace.tsv \
    | perl -nla -e '/\(\-\)/ and print $F[0];' \
    > ${MY_TMP_DIR}/rc.list

faops rc -l 0 -f ${MY_TMP_DIR}/rc.list ${FA_FILE} ${MY_TMP_DIR}/strand.fa

log_info "Recreate replace.tsv"
# now all positive strands
perl ~/Scripts/egaz/sparsemem_exact.pl \
    -f ${MY_TMP_DIR}/strand.fa -g ${REF_FILE} \
    --length 500 -o ${MY_TMP_DIR}/replace.tsv

log_info "Replace headers"
# pretend to be a fas file
faops replace ${MY_TMP_DIR}/strand.fa ${MY_TMP_DIR}/replace.tsv ${MY_TMP_DIR}/replace.fa

log_info "Sort"
faops size ${MY_TMP_DIR}/replace.fa | cut -f 1 > ${MY_TMP_DIR}/heads.list
# rangeops would remove invalid headers
rangeops sort ${MY_TMP_DIR}/heads.list -o stdout > ${MY_TMP_DIR}/heads.sort
# append invalid headers
grep -Fx -f ${MY_TMP_DIR}/heads.sort -v ${MY_TMP_DIR}/heads.list >> ${MY_TMP_DIR}/heads.sort

faops order -l 0 ${MY_TMP_DIR}/replace.fa ${MY_TMP_DIR}/heads.sort ${MY_TMP_DIR}/sort.fa

mv ${MY_TMP_DIR}/sort.fa ${OUT_BASE}.fa
mv ${MY_TMP_DIR}/replace.tsv ${OUT_BASE}.replace.tsv

# clean tmp dir
rm -fr ${MY_TMP_DIR}
