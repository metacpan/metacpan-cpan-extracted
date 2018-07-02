#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::saikoro' ) || print "Bail out!\n";
}

diag( "Testing App::saikoro $App::saikoro::VERSION, Perl $], $^X" );
