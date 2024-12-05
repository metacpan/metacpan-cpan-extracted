#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Circle::Miner' ) || print "Bail out!\n";
}

diag( "Testing Circle::Miner $Circle::Miner::VERSION, Perl $], $^X" );
