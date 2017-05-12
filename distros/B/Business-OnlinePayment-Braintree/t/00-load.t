#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Business::OnlinePayment::Braintree' ) || print "Bail out!\n";
}

diag( "Testing Business::OnlinePayment::Braintree $Business::OnlinePayment::Braintree::VERSION, Perl $], $^X" );
