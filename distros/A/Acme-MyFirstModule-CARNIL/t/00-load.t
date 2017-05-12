#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::MyFirstModule::CARNIL' ) || print "Bail out!\n";
}

diag( "Testing Acme::MyFirstModule::CARNIL $Acme::MyFirstModule::CARNIL::VERSION, Perl $], $^X" );
