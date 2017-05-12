#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Action::Serialize::SimpleExcel' );
}

diag( "Testing Catalyst::Action::Serialize::SimpleExcel $Catalyst::Action::Serialize::SimpleExcel::VERSION, Perl $], $^X" );
