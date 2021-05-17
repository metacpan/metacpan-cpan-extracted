#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Prereq::D' ) || print "Bail out!\n";
}

diag( "Testing Acme::Prereq::D $Acme::Prereq::D::VERSION, Perl $], $^X" );
