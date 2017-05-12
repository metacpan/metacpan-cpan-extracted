#!perl 

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Authentication::Store::DBIx::Class' );
}

diag( "Testing Catalyst::Authentication::Store::DBIx::Class $Catalyst::Authentication::Store::DBIx::Class::VERSION, Perl $], $^X" );
