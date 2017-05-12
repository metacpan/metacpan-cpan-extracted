#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bundle::SDK::COG' );
}

diag( "Testing Bundle::SDK::COG $Bundle::SDK::COG::VERSION, Perl $], $^X" );
