#!perl -T
use v5.10;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Assert::Conditional' ) || print "Bail out!\n";
}

diag( "Testing Assert::Conditional $Assert::Conditional::VERSION, Perl $], $^X" );
