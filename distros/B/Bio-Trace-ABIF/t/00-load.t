#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Bio::Trace::ABIF' );
}

diag( "Testing Bio::Trace::ABIF $Bio::Trace::ABIF::VERSION, Perl $], $^X" );
