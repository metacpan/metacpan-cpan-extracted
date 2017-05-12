#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Prima::REPL' )
		or BAIL_OUT('Unable to load App::Prima::REPL!');
}

diag( "Testing App::Prima::REPL $App::Prima::REPL::VERSION, Perl $], $^X" );