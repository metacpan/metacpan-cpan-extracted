#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::XML::Generator' );
}

diag( "Testing Catalyst::View::XML::Generator $Catalyst::View::XML::Generator::VERSION, Perl $], $^X" );
