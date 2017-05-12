#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Model::DBIC::Schema::QueryLog' );
}

diag( "Testing Catalyst::Model::DBIC::Schema::QueryLog $Catalyst::Model::DBIC::Schema::QueryLog::VERSION, Perl $], $^X" );
