#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Hoge' );
}

diag( "Testing Acme::Hoge $Acme::Hoge::VERSION, Perl $], $^X" );
