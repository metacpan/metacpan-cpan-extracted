#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Action::Serialize::SimpleXLSX' );
}

diag( "Testing Catalyst::Action::Serialize::SimpleXLSX $Catalyst::Action::Serialize::SimpleXLSX::VERSION, Perl $], $^X" );
