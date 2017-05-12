#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Setenv' );
}

diag( "Testing Catalyst::Plugin::Setenv $Catalyst::Plugin::Setenv::VERSION, Perl $], $^X" );
