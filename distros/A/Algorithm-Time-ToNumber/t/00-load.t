#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Algorithm::Time::ToNumber' ) || print "Bail out!\n";
}

diag( "Testing Algorithm::Time::ToNumber $Algorithm::Time::ToNumber::VERSION, Perl $], $^X" );
