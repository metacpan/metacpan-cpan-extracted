#!perl -T

use lib qw( lib );

use Test::More tests => 1;

BEGIN {
	use_ok( 'CMS::JoomlaToDrupal' );
}

diag( "Testing CMS::JoomlaToDrupal $CMS::JoomlaToDrupal::VERSION, Perl $], $^X" );
