#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::Buffalo::Buffalo' ) || print "Bail out!\n";
}

diag( "Testing Acme::Buffalo::Buffalo $Acme::Buffalo::Buffalo::VERSION, Perl $], $^X" );
