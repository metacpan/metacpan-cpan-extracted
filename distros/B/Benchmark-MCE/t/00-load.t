#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Benchmark::MCE' ) || print "Bail out!\n";
}

diag( "Testing Benchmark::MCE $Benchmark::MCE::VERSION, Perl $], $^X" );
