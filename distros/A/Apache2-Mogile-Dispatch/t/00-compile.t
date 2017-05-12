#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache2::Mogile::Dispatch' );
}

diag( "Testing Apache2::Mogile::Dispatch $Apache2::Mogile::Dispatch::VERSION, Perl $], $^X" );

