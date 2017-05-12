#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::OnlinePayment::PaymenTech' );
}

diag( "Testing Business::OnlinePayment::PaymenTech $Business::OnlinePayment::PaymenTech::VERSION, Perl $], $^X" );
