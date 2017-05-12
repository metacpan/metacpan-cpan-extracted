#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Archive::StringToZip' );
}

diag( "Testing Archive::StringToZip $Archive::StringToZip::VERSION, Perl $], $^X" );
