#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'AI::Perceptron::Simple' ) || print "Bail out!\n";
}

diag( "Testing AI::Perceptron::Simple $AI::Perceptron::Simple::VERSION, Perl $], $^X" );
