#!/bin/bash
# make clean
# if read from stdin
# uncomment the next line
# pgplot_dir=$1
pgplot_dir=/usr/local/pgplot
export PGPLOT_DIR=$pgplot_dir
echo "PGPLOT_DIR is now: $PGPLOT_DIR"
make immodpg1.1
