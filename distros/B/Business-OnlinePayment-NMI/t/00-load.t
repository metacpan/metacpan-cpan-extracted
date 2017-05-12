#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::OnlinePayment::NMI' );
}

diag( "Testing Business::OnlinePayment::NMI $Business::OnlinePayment::NMI::VERSION, Perl $], $^X" );
