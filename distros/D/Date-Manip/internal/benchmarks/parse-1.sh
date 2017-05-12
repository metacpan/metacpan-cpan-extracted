#!/bin/sh

./parse-1.in.pl > parse-1.in

time ./parse-1.dm.pl
time ./parse-1.dt.pl

rm -f parse-1.in
