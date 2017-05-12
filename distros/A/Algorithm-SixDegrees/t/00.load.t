#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Algorithm::SixDegrees' );
}

diag( "Testing Algorithm::SixDegrees $Algorithm::SixDegrees::VERSION" );
