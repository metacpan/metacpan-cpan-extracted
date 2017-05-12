#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::Helper::InitScript::FreeBSD' );
}

diag( "Testing Catalyst::Helper::InitScript::FreeBSD $Catalyst::Helper::InitScript::FreeBSD::VERSION, Perl $], $^X" );
