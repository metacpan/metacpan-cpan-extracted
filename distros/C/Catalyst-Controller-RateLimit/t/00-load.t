#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Controller::RateLimit' );
}

diag( "Testing Catalyst::Controller::RateLimit $Catalyst::Controller::RateLimit::VERSION, Perl $], $^X" );
