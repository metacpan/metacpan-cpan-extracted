#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Baseball::Sabermetrics' );
}

diag( "Testing Sabermetrics $Baseball::Sabermetrics::VERSION, Perl $], $^X" );
