#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Config::KeyValue' );
}

diag( "Testing Config::KeyValue $Config::KeyValue::VERSION, Perl $], $^X" );
