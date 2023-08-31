#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Benchmark::DKbench' ) || print "Bail out!\n";
}

diag( "Testing Benchmark::DKbench $Benchmark::DKbench::VERSION, Perl $], $^X" );
