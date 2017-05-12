#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Cache::Meh' ) || print "Bail out!\n";
}

diag( "Testing Cache::Meh $Cache::Meh::VERSION, Perl $], $^X" );
