#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Prereq::E' ) || print "Bail out!\n";
}

diag( "Testing Acme::Prereq::E $Acme::Prereq::E::VERSION, Perl $], $^X" );
