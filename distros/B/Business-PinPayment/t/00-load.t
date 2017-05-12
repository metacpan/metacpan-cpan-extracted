#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::PinPayment' ) || print "Bail out!\n";
}

diag( "Testing Business::PinPayment $Business::PinPayment::VERSION, Perl $], $^X" );
