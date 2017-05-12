#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Async::Event::Interval' ) || print "Bail out!\n";
}

diag( "Testing Async::Event::Interval $Async::Event::Interval::VERSION, Perl $], $^X" );
