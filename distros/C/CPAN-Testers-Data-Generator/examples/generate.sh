#!/usr/bin/bash

BASE=/home/barbie/projects/cpantesters/generate

date
mkdir -p $BASE/logs

cd $BASE
perl bin/cpanstats \
    --config=data/settings.ini     \
    --log=../db/logs/cpanstats.log \
    --nonstop                      \
    >>logs/cpanstats.out

