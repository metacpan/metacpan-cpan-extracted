#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Dancer::Plugin::KossyValidator' );
}

diag( "Testing Dancer::Plugin::KossyValidator $Dancer::Plugin::KossyValidator::VERSION, Perl $], $^X" );
