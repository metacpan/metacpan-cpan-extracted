#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache2::FixupLastModified' );
}

diag( "Testing Apache2::FixupLastModified $Apache2::FixupLastModified::VERSION, Perl $], $^X" );
