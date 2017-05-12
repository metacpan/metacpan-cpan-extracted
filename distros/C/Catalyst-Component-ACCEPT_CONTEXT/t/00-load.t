#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Component::ACCEPT_CONTEXT' );
}

diag( "Testing Catalyst::Component::ACCEPT_CONTEXT $Catalyst::Component::ACCEPT_CONTEXT::VERSION, Perl $], $^X" );
