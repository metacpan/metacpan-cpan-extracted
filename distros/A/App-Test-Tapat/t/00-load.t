#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Test::Tapat' );
}

diag( "Testing App::Test::Tapat $App::Test::Tapat::VERSION, Perl $], $^X" );
