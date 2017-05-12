#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Toodledo' );
}

diag( "Testing App::Toodledo $App::Toodledo::VERSION, Perl $], $^X" );
