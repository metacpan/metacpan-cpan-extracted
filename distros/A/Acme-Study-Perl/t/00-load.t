#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Acme::Study::Perl' );
}

diag( "Testing Acme::Study::Perl $Acme::Study::Perl::VERSION, Perl $], $^X" );
