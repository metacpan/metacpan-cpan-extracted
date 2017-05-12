#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer2::Plugin::HTTP::Bundle' ) || print "Bail out!\n";
}

diag( "Testing Dancer2::Plugin::HTTP::Bundle $Dancer2::Plugin::HTTP::Bundle::VERSION, Perl $], $^X" );
