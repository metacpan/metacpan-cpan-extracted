#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Chemistry::File::InternalCoords' );
}

diag( "Testing Chemistry::File::InternalCoords $Chemistry::File::InternalCoords::VERSION, Perl $], $^X" );
