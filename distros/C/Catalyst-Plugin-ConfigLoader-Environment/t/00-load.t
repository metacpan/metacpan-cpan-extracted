#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::ConfigLoader::Environment' );
}

diag( "Testing Catalyst::Plugin::ConfigLoader::Environment $Catalyst::Plugin::ConfigLoader::Environment::VERSION, Perl $], $^X" );
