#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::Component::ESI' );
}

diag( "Testing Catalyst::View::Component::ESI $Catalyst::View::Component::ESI::VERSION, Perl $], $^X" );
