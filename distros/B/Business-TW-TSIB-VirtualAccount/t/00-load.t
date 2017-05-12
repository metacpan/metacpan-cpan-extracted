#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::TW::TSIB::VirtualAccount' );
}

diag( "Testing Business::TW::TSIB::VirtualAccount $Business::TW::TSIB::VirtualAccount::VERSION, Perl $], $^X" );
