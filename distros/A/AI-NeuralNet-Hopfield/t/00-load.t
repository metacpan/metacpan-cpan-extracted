#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'AI::NeuralNet::Hopfield' ) || print "Bail out!\n";
	use_ok( 'Math::SparseMatrix' ) || print "Bail out\n";

}

diag( "Testing AI::NeuralNet::Hopfield $AI::NeuralNet::Hopfield::VERSION, Perl $], $^X" );
