#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Engine::SCGI' );
}

diag( "Testing Catalyst::Engine::SCGI $Catalyst::Engine::SCGI::VERSION, Perl $], $^X" );
