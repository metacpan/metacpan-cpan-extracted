#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Rad::Plugin::TT' );
}

diag( "Testing App::Rad::Plugin::TT $App::Rad::Plugin::TT::VERSION, Perl $], $^X" );
