#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::OnlinePayment::WesternACH' );
}

diag( "Testing Business::OnlinePayment::WesternACH $Business::OnlinePayment::WesternACH::VERSION, Perl $], $^X" );
