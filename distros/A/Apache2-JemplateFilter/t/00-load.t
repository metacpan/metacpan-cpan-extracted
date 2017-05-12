#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache2::JemplateFilter' );
}

diag( "Testing Apache2::JemplateFilter $Apache2::JemplateFilter::VERSION, Perl $], $^X" );
