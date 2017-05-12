#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CouchDB::View' );
}

diag( "Testing CouchDB::View $CouchDB::View::VERSION, Perl $], $^X" );
