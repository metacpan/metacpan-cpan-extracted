#!perl -T
use v5.16.2;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Machi' ) || print "Bail out!\n";
}

diag( "Testing Acme::Machi $Acme::Machi::VERSION, Perl $], $^X" );
