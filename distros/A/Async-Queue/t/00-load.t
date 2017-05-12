#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Async::Queue' ) || print "Bail out!\n";
}

diag( "Testing Async::Queue $Async::Queue::VERSION, Perl $], $^X" );
