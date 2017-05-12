#!/bin/bash

NAME=Benchmark/Featureset/StopwordLists
export NAME

mkdir -p /dev/shm/html/Perl-modules/html/$NAME

# My web server's doc root is /dev/shm/html/.
# For non-Debian user's, /dev/shm/ is the built-in RAM disk.

pod2html.pl -i lib/$NAME.pm -o /dev/shm/html/Perl-modules/html/$NAME.html
