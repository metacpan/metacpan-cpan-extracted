#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Hospital::Bed' ) || print "Bail out!\n";
}

diag( "Testing Acme::Hospital::Bed $Acme::Hospital::Bed::VERSION, Perl $], $^X" );
