#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Prereq::F' ) || print "Bail out!\n";
}

diag( "Testing Acme::Prereq::F $Acme::Prereq::F::VERSION, Perl $], $^X" );
