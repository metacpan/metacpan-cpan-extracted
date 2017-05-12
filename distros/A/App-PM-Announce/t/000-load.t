#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::PM::Announce' );
}

diag( "Testing App::PM::Announce $App::PM::Announce::VERSION, Perl $], $^X" );
