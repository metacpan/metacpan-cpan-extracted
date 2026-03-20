#!perl
use v5.36;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Chess4p' ) || print "Bail out!\n";
}

diag( "Testing Chess4p $Chess4p::VERSION, Perl $], $^X" );
