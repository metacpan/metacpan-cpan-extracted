#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Prereq::Itself' ) || print "Bail out!\n";
}

diag( "Testing Acme::Prereq::Itself $Acme::Prereq::Itself::VERSION, Perl $], $^X" );
