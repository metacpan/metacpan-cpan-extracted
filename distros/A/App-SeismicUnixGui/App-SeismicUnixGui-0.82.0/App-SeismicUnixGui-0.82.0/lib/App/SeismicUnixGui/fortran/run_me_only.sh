#!/bin/sh
# make clean
# read from stdin
pgplot_dir=$1
export PGPLOT_DIR=$pgplot_dir
echo "PGPLOT_DIR is now: $PGPLOT_DIR"
make immodpg1.1
