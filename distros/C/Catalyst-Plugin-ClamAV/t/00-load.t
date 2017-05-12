#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Plugin::ClamAV' );
}

diag( "Testing Catalyst::Plugin::ClamAV $Catalyst::Plugin::ClamAV::VERSION, Perl $], $^X" );
