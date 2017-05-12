#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::DRM' );
}

diag( "Testing Acme::DRM $Acme::DRM::VERSION, Perl $], $^X" );
