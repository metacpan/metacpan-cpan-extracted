#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::ALEXEY::Utils' ) || print "Bail out!\n";
}

diag( "Testing Acme::ALEXEY::Utils $Acme::ALEXEY::Utils::VERSION, Perl $], $^X" );
