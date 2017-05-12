#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::MultiModule' ) || print "Bail out!\n";
}

