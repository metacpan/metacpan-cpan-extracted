#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CPANPLUS::Dist::Arch' );
}

diag( "Testing CPANPLUS::Dist::Arch $CPANPLUS::Dist::Arch::VERSION, Perl $], $^X" );
