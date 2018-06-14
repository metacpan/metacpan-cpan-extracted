#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CLI::Coin::Toss' ) || print "Bail out!\n";
}

diag( "Testing CLI::Coin::Toss $CLI::Coin::Toss::VERSION, Perl $], $^X" );
