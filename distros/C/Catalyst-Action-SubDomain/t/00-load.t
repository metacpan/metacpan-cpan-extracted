#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Action::SubDomain' );
}

diag( "Testing Catalyst::Action::SubDomain $Catalyst::Action::SubDomain::VERSION, Perl $], $^X" );
