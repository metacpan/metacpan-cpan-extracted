#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::MyFirstModule::MALLEN' ) || print "Bail out!\n";
}

diag( "Testing Acme::MyFirstModule::MALLEN $Acme::MyFirstModule::MALLEN::VERSION, Perl $], $^X" );
