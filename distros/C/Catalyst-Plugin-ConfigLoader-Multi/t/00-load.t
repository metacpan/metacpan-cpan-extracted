#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::ConfigLoader::Multi' );
}

diag( "Testing Catalyst::Plugin::ConfigLoader::Multi $Catalyst::Plugin::ConfigLoader::Multi::VERSION, Perl $], $^X" );
