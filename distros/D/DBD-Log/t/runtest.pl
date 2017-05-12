#!/opt/perl/bin/perl -I../lib

use Test::Harness;

@tests=<*.t>;

runtests( @tests);
