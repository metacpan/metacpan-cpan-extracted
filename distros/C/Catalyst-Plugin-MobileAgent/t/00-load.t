#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::MobileAgent' );
}

diag( "Testing Catalyst::Plugin::MobileAgent $Catalyst::Plugin::MobileAgent::VERSION, Perl $], $^X" );
