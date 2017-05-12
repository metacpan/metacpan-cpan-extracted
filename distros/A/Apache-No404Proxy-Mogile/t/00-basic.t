#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache::No404Proxy::Mogile' );
}

diag( "Testing Apache::No404Proxy::Mogile $Apache::No404Proxy::Mogile::VERSION, Perl $], $^X" );
