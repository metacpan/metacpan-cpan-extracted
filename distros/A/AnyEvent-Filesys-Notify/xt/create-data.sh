#!/bin/bash

data="t/data"
mkdir "$data"

for f in $( gseq 1 20 ) ; do
    touch "$data/$( printf 'ex%04d' $f )"
done

for d in $( gseq 1 10 ) ; do
    dir="$data/$( printf 'dir%04d' $d )"
    mkdir "$dir"
    for f in $( gseq 1 20 ) ; do
        touch "$dir/$( printf 'ex%04d' $f )"
    done
done
