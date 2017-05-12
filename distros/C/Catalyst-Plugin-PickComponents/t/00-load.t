#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::PickComponents' );
}

diag( "Testing Catalyst::Plugin::PickComponents $Catalyst::Plugin::PickComponents::VERSION, Perl $], $^X" );
