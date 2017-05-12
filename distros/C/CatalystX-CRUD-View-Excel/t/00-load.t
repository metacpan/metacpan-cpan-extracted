#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CatalystX::CRUD::View::Excel' );
}

diag( "Testing CatalystX::CRUD::View::Excel $CatalystX::CRUD::View::Excel::VERSION, Perl $], $^X" );
