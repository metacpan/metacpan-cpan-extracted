#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Tail' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::Tail $Dancer::Plugin::Tail::VERSION, Perl $], $^X" );


