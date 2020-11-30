#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Alien::libsnappy' ) || print "Bail out!\n";
}

diag( "Testing Alien::libsnappy $Alien::libsnappy::VERSION, Perl $], $^X" );
