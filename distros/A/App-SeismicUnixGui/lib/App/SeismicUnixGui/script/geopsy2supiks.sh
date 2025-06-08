#!/bin/sh
 
set -x

DATA_IN=$1

DATA_OUT='../'$DATA_IN

awk '{print $1, $2 }' $DATA_IN >$DATA_OUT

