#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::ConfigLoader::Remote' );
}

diag( "Testing Catalyst::Plugin::ConfigLoader::Remote $Catalyst::Plugin::ConfigLoader::Remote::VERSION, Perl $], $^X" );
