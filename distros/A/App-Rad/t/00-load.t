#!perl -T

use Test::More tests => 4;

BEGIN {
	use_ok( 'App::Rad' );
	use_ok( 'App::Rad::Help' );
	use_ok( 'App::Rad::Include' );
	use_ok( 'App::Rad::Exclude' );
}

diag( "Testing App::Rad $App::Rad::VERSION, Perl $], $^X" );
