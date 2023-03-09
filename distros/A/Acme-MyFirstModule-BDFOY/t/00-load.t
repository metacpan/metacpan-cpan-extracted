#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::MyFirstModule::BDFOY' ) || print "Bail out!\n";
}

diag( "Testing Acme::MyFirstModule::BDFOY $Acme::MyFirstModule::BDFOY::VERSION, Perl $], $^X" );
