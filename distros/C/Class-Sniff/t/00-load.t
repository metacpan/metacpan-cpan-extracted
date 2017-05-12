#!perl -T

use Test::Most tests => 1, 'bail';

BEGIN {
	use_ok( 'Class::Sniff' );
}

diag( "Testing Class::Sniff $Class::Sniff::VERSION, Perl $], $^X" );
