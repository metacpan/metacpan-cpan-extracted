#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Cache::Range' ) || print "Bail out!
";
}

diag( "Testing Cache::Range $Cache::Range::VERSION, Perl $], $^X" );
