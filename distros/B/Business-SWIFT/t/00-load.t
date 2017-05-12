#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::SWIFT' );
}

diag( "Testing Business::SWIFT $Business::SWIFT::VERSION, Perl $], $^X" );
