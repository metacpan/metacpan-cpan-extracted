#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Benchmark::Serialize' );
}

diag( "Testing Benchmark::Serialize $Benchmark::Serialize::VERSION, Perl $], $^X" );
