#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Framework' );
}

diag( "Testing App::Framework $App::Framework::VERSION, Perl $], $^X" );
