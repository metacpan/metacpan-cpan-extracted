#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::TW::Invoice::U420' );
}

diag( "Testing Business::TW::Invoice::U420 $Business::TW::Invoice::U420::VERSION, Perl $], $^X" );
