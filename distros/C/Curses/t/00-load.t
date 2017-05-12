#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Curses' );
}

diag( "Testing Curses $Curses::VERSION, Perl $]" );
