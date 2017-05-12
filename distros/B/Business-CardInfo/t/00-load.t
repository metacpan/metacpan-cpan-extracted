#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::CardInfo' );
}

diag( "Testing Business::CardInfo $Business::CardInfo::VERSION, Perl $], $^X" );
