#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::REPL' );
}

diag( "Testing App::REPL $App::REPL::VERSION, Perl $], $^X" );
