#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'CMS::Joomla' );
}

diag( "Testing CMS::Joomla $CMS::Joomla::VERSION, Perl $], $^X" );
