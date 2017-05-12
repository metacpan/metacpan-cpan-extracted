#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'ACME::THEDANIEL::Utils' ) || print "Bail out!\n";
}

diag( "Testing ACME::THEDANIEL::Utils $ACME::THEDANIEL::Utils::VERSION, Perl $], $^X" );
