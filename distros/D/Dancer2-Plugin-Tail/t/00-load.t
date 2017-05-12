#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::Tail' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin::Tail $Dancer2::Plugin::Tail::VERSION, Perl $], $^X" );
