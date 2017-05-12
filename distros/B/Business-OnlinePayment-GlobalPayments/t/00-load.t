#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::OnlinePayment::GlobalPayments' );
}

diag( "Testing Business::OnlinePayment::GlobalPayments $Business::OnlinePayment::GlobalPayments::VERSION, Perl $], $^X" );
