#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Circle::Wallet' ) || print "Bail out!\n";
}

diag( "Testing Circle::Wallet $Circle::Wallet::VERSION, Perl $], $^X" );
