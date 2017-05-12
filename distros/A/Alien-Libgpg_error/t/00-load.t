#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Alien::Libgpg_error' ) || print "Bail out!\n";
}

diag( "Testing Alien::Libgpg_error $Alien::Libgpg_error::VERSION, Perl $], $^X" );
