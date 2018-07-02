#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::boxmuller' ) || print "Bail out!\n";
}

diag( "Testing App::boxmuller $App::boxmuller::VERSION, Perl $], $^X" );
