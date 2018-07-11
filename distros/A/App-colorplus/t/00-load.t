#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::colorplus' ) || print "Bail out!\n";
}

diag( "Testing App::colorplus $App::colorplus::VERSION, Perl $], $^X" );
