#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Acme::stickpin' ) || print "Bail out!\n";
}

diag( "Testing Acme::stickpin $Acme::stickpin::VERSION, Perl $], $^X" );
