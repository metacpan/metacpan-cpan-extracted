#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Blessed::Merge' ) || print "Bail out!\n";
}

diag( "Testing Blessed::Merge $Blessed::Merge::VERSION, Perl $], $^X" );
