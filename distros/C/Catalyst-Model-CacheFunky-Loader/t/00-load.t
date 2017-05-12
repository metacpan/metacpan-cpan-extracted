#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Model::CacheFunky::Loader' );
}

diag( "Testing Catalyst::Model::CacheFunky::Loader $Catalyst::Model::CacheFunky::Loader::VERSION, Perl $], $^X" );
