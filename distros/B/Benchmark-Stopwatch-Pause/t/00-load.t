#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Benchmark::Stopwatch::Pause' );
}

diag( "Testing Benchmark::Stopwatch::Pause $Benchmark::Stopwatch::Pause::VERSION, Perl $], $^X" );
