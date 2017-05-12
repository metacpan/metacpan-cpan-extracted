#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DBIPR' );
}

diag( "Testing DBIPR $DBIPR::VERSION, Perl $], $^X" );
