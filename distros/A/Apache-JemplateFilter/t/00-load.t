#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Apache::JemplateFilter' );
}

diag( "Testing Apache::JemplateFilter $Apache::JemplateFilter::VERSION, Perl $], $^X" );
