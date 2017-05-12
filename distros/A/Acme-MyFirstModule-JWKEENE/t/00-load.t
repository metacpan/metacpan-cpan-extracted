#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::MyFirstModule::JWKEENE' ) || print "Bail out!\n";
}

diag( "Testing Acme::MyFirstModule::JWKEENE $Acme::MyFirstModule::JWKEENE::VERSION, Perl $], $^X" );
