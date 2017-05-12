#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::ConfigurablePathTo' );
}

diag( "Testing Catalyst::Plugin::ConfigurablePathTo $Catalyst::Plugin::ConfigurablePathTo::VERSION, Perl $], $^X" );
