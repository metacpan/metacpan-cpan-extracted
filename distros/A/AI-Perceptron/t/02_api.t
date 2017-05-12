#!/usr/bin/perl

##
## API tests for AI::Perceptron
##

use Test::More 'no_plan'; # tests => 3;

use AI::Perceptron;

my $p = AI::Perceptron->new
                      ->num_inputs( 3 )
                      ->learning_rate( 0.01 )
                      ->threshold( 0.02 )
                      ->weights([ 0.1, 0.2, -0.3 ])
                      ->max_iterations( 5 )
                      ->training_examples( [ -1 => 1, 2 ] );

is( $p->num_inputs,             3,      'num_inputs' );
is( $p->learning_rate,          0.01,   'learning_rate' );
is( $p->threshold,              0.02,   'threshold' );
is( $p->max_iterations,         5,      'threshold' );
isa_ok( $p->weights,           'ARRAY', 'weights' );
isa_ok( $p->training_examples, 'ARRAY', 'examples' );

is( $p->add_examples( [-1 => 1, 1] ), $p, 'add_examples' );
can_ok( $p, 'add_example',                'add_example' );

##
## backwards compat
##

my $pc = new AI::Perceptron(
			    Inputs => 2,
			    N      => 0.001,
			    W      => [ -0.1, 0.2, 0.3 ],
			   );

is( $pc->num_inputs,     2,       'num_inputs() [compat]' );
is( $pc->learning_rate,  0.001,   'learning_rate() [compat]' );
is( $pc->threshold,     -0.1,     'threshold() [compat]' );

my @weights = $pc->weights;
is( @weights, 3, 'weights() in list context [compat]' );

