#!/usr/bin/perl

##
## Test suite for AI::Perceptron
##

use Test::More 'no_plan'; # tests => 3;

use_ok( 'AI::Perceptron' );

my $p = AI::Perceptron->new
          ->num_inputs( 2 )
          ->learning_rate( 0.01 )
          ->threshold( 0.8 )
          ->weights([ -0.5, 0.5 ])
          ->max_iterations( 20 );

# get the current output of the node given a training example:
my @inputs = ( 1, 1 );
my $target_output  = 1;
my $current_output = $p->compute_output( @inputs );

ok( defined $current_output,         'compute_output' );
is( $current_output, $target_output, 'expected output for preset weights' );

# train the perceptron until it gets it right:
my @training_examples = ( [ -$target_output, @inputs ] );
is( $p->add_examples( @training_examples ), $p, 'add_examples' );
is( $p->train, $p, 'train' );
is( $p->compute_output( @inputs ), -$target_output, 'perceptron re-trained' );
