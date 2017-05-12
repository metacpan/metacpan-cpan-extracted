#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::Countdown' ) || print "Bail out!\n";
}

diag( "Testing App::Countdown $App::Countdown::VERSION, Perl $], $^X" );
