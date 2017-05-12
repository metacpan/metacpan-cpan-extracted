#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache2::FixRemote' );
}

diag( "Testing Apache2::FixRemote $Apache2::FixRemote::VERSION, Perl $], $^X" );
