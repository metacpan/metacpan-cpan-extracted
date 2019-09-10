#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Douglas_Peucker' ) || print "Bail out!\n";
}

diag( "Testing Data::Douglas_Peucker $Data::Douglas_Peucker::VERSION, Perl $], $^X" );
