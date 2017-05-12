#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::TimeClock' ) || print "Bail out!\n";
}

diag( "Testing App::TimeClock $App::TimeClock::VERSION, Perl $], $^X" );
