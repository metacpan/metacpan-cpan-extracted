#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Install' );
}

diag( "Testing App::Install $App::Install::VERSION, Perl $], $^X" );
