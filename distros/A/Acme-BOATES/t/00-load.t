#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::BOATES' ) || print "Bail out!\n";
}

diag( "Testing Acme::BOATES $Acme::BOATES::VERSION, Perl $], $^X" );
