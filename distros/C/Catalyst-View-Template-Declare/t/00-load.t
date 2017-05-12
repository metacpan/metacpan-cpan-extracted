#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::Template::Declare' );
}

diag( "Testing Catalyst::View::Template::Declare $Catalyst::View::Template::Declare::VERSION, Perl $], $^X" );
