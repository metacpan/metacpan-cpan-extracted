#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
	use_ok( 'CPANPLUS::Dist::Gentoo' );
	use_ok( 'CPANPLUS::Dist::Gentoo::Maps' );
}

diag( "Testing CPANPLUS::Dist::Gentoo $CPANPLUS::Dist::Gentoo::VERSION, Perl $], $^X" );
