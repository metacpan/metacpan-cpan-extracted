#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'B::XPath' );
}

diag( "Testing B::XPath $B::XPath::VERSION, Perl $], $^X" );
