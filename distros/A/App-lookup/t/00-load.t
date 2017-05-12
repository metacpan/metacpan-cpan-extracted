#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::lookup' ) || print "Bail out!\n";
}

diag( "Testing App::lookup $App::lookup::VERSION, Perl $], $^X" );
