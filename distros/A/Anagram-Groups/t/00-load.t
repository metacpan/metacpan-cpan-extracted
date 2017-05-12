#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Anagram::Groups' ) || print "Bail out!\n";
}

diag( "Testing Anagram::Groups $Anagram::Groups::VERSION, Perl $], $^X" );
