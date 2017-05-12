#!perl 

use Test::More 0.98 tests => 2;

BEGIN {
	use_ok( 'Catalyst::Authentication::Store::CouchDB' );
	use_ok( 'Catalyst::Authentication::Store::CouchDB::User' );
}

diag( "Testing Catalyst::Authentication::Store::CouchDB $Catalyst::Authentication::Store::CouchDB::VERSION, Perl $], $^X" );
