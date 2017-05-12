#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::Facebook' );
}

diag( "Testing Catalyst::Plugin::Facebook $Catalyst::Plugin::Facebook::VERSION, Perl $], $^X" );
