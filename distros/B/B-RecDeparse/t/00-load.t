#!perl -T

use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
 use_ok( 'B::RecDeparse' );
}

diag( "Testing B::RecDeparse $B::RecDeparse::VERSION, Perl $], $^X" );
