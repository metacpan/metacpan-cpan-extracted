#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Bit::Manip::PP' ) || print "Bail out!\n";
}

diag( "Testing Bit::Manip::PP $Bit::Manip::PP::VERSION, Perl $], $^X" );
