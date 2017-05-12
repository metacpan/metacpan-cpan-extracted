#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'BigIP::ParseConfig' );
}

diag( "Testing BigIP::ParseConfig $BigIP::ParseConfig::VERSION, Perl $], $^X" );

