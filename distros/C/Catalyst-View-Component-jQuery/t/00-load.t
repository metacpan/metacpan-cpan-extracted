#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::Component::jQuery' );
}

diag( "Testing Catalyst::View::Component::jQuery $Catalyst::View::Component::jQuery::VERSION, Perl $], $^X" );
