#!perl -T
use v5.22;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Date::Advent' ) || print "Bail out!\n";
}

diag( "Testing Date::Advent $Date::Advent::VERSION, Perl $], $^X" );
