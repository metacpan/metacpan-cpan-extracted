#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Benchmark::Chart' ) || print "Bail out!\n";
}

diag( "Testing Benchmark::Chart $Benchmark::Chart::VERSION, Perl $], $^X" );
