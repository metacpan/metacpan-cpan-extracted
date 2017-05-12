#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Benchmark::Perl::Formance::Cargo' );
}

diag( "Testing Benchmark::Perl::Formance::Cargo $Benchmark::Perl::Formance::Cargo::VERSION, Perl $], $^X" );
