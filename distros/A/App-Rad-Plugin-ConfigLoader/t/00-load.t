#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Rad::Plugin::ConfigLoader' );
}

diag( "Testing App::Rad::Plugin::ConfigLoader $App::Rad::Plugin::ConfigLoader::VERSION, Perl $], $^X" );
