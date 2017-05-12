#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::OnlinePayment::Jety' );
}

diag( "Testing Business::OnlinePayment::Jety $Business::OnlinePayment::Jety::VERSION, Perl $], $^X" );
