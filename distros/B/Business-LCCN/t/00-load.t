#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Business::LCCN' );
}

diag( "Testing Business::LCCN $Business::LCCN::VERSION, Perl $], $^X" );
