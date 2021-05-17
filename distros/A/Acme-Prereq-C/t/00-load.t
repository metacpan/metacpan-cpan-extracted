#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Prereq::C' ) || print "Bail out!\n";
}

diag( "Testing Acme::Prereq::C $Acme::Prereq::C::VERSION, Perl $], $^X" );
