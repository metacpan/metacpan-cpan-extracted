#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'AnyEvent::HTTPBenchmark' ) || print "Bail out!
";
}

diag( "Testing AnyEvent::HTTPBenchmark $AnyEvent::HTTPBenchmark::VERSION, Perl $], $^X" );
