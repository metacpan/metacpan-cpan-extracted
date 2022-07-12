#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::MHFS' ) || print "Bail out!\n";
}

diag( "Testing App::MHFS $App::MHFS::VERSION, Perl $], $^X" );
