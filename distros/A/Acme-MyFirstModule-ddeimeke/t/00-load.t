#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::MyFirstModule::ddeimeke' ) || print "Bail out!\n";
}

diag( "Testing Acme::MyFirstModule::ddeimeke $Acme::MyFirstModule::ddeimeke::VERSION, Perl $], $^X" );
