#!/bin/sh

if [ "x$1" = "x" ]; then
    echo "Usage: $0 path/to/script.pl";
    exit;
fi

SCRIPT="$1"
NAME=$(basename $1)

fatpack trace $SCRIPT
fatpack packlists-for $(cat fatpacker.trace) > packlists
fatpack tree $(cat packlists)
(fatpack file; cat $SCRIPT) > $NAME.packed
rm -rf fatlib/ fatpacker.trace packlists
