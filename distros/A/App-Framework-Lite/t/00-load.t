#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Framework::Lite' );
}

diag( "Testing App::Framework::Lite $App::Framework::Lite::VERSION, Perl $], $^X" );
