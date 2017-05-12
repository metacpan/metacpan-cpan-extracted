#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::MyFirstModule::DRPENGUIN' ) || print "Bail out!\n";
}

diag( "Testing Acme::MyFirstModule::DRPENGUIN $Acme::MyFirstModule::DRPENGUIN::VERSION, Perl $], $^X" );
