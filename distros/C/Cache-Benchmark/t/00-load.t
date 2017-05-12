#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Cache::Benchmark' );
}

diag( "Testing Cache::Benchmark $Cache::Benchmark::VERSION, Perl $], $^X" );
