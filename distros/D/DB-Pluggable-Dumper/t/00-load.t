#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'DB::Pluggable::Dumper' );
}

diag( "Testing DB::Pluggable::Dumper $DB::Pluggable::Dumper::VERSION, Perl $], $^X" );
