#!perl -T

use Test::More tests => 1;

BEGIN {
        use lib qw( ../CatalystX-CRUD/lib );
	use_ok( 'CatalystX::CRUD::Model::RDBO' );
}

diag( "Testing CatalystX::CRUD::Model::RDBO $CatalystX::CRUD::Model::RDBO::VERSION, Perl $], $^X" );
