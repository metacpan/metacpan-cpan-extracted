#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Catalyst::Model::DBIDM' );
	use_ok( 'Catalyst::Helper::Model::DBIDM' );
}

diag( "Testing Catalyst::Model::DBIDM $Catalyst::Model::DBIDM::VERSION, Perl $], $^X" );
