#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::TW::TSIB::CStorePayment' );
}

diag( "Testing Business::TW::TSIB::CStorePayment $Business::TW::TSIB::CStorePayment::VERSION, Perl $], $^X" );
