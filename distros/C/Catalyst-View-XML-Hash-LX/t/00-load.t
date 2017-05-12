#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::XML::Hash::LX' );
}

diag( "Testing Catalyst::View::XML::Hash::LX $Catalyst::View::XML::Hash::LX::VERSION, Perl $], $^X" );
