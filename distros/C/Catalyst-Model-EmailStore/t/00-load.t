#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'Catalyst::Model::EmailStore' );
	use_ok( 'Catalyst::Helper::Model::EmailStore' );
}
