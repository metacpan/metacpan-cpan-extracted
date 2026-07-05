#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Algorithm::EventsPerSecond' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::EventsPerSecond $Algorithm::EventsPerSecond::VERSION, Perl $], $^X" );
