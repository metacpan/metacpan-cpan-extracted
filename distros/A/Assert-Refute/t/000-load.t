#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    require_ok( 'Assert::Refute' ) || print "Bail out!\n";
}

diag( "Testing Assert::Refute $Assert::Refute::VERSION, Perl $], $^X" );
