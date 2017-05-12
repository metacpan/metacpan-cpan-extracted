#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::ForExample' );
}

diag( "Testing App::ForExample $App::ForExample::VERSION, Perl $], $^X" );
