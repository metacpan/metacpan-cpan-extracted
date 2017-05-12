#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::MyFirstModule::DRZIGMAN' ) || print "Bail out!\n";
}

diag( "Testing Acme::MyFirstModule::DRZIGMAN $Acme::MyFirstModule::DRZIGMAN::VERSION, Perl $], $^X" );
