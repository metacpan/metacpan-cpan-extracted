#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::MyFirstModule::ASTPL' ) || print "Bail out!\n";
}

diag( "Testing Acme::MyFirstModule::ASTPL $Acme::MyFirstModule::ASTPL::VERSION, Perl $], $^X" );
