#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Circle::Node' ) || print "Bail out!\n";
}

diag( "Testing Circle::Node $Circle::Node::VERSION, Perl $], $^X" );
