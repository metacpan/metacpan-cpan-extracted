#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bundle::CIPRES' );
}

diag( "Testing Bundle::CIPRES $Bundle::CIPRES::VERSION, Perl $], $^X" );