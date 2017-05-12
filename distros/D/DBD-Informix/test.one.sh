#!/bin/sh
#
# @(#)$Id: test.one.sh,v 2015.1 2015/10/29 11:46:10 jleffler Exp $
#
# Run specified test(s)
#
# Copyright 1997-99 Jonathan Leffler
# Copyright 2000    Informix Software Inc
# Copyright 2002    IBM
# Copyright 2015    Jonathan Leffler

PERL_DL_NONLAZY=1
export PERL_DL_NONLAZY

for test in "$@"
do
    rm -f core
    ${PERL:-perl} \
        -I./blib/arch \
        -I./blib/lib \
        "$test"
    if [ -f core ]
    then
        save=core.`basename $test .t`
        mv core $save
        x=`echo "### TEST FAILED -- CORE DUMP SAVED AS $save ###" | sed 's/./#/g'`
        echo
        echo $x
        echo "### TEST FAILED -- CORE DUMP SAVED AS $save ###"
        echo $x
    fi
done
