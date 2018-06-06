#!/bin/bash
# A frontend to run deparsing via B::DeparseTree
if [[ $0 != ${BASH_SOURCE[0]} ]] ; then
    echo "This script should not be sourced."
    exit 1
fi

if (($# != 1)) ; then
    echo >&2 "Usage: $0 perl-program"
    exit 1
fi
PERL=${PERL:-perl}
my_dir=$(dirname ${BASH_SOURCE[0]})
# $PERL -I${my_dir}/../lib -MO=Deparse,sC $1
$PERL -I${my_dir}/../lib -MO=DeparseTree,sC $1
exit $?
