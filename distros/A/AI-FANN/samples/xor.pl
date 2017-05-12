#!/usr/bin/perl

use strict;
use warnings;

use AI::FANN qw(:all);

if ($ARGV[0] eq 'train') {

    # create an ANN with 2 inputs, a hidden layer with 3 neurons and an
    # output layer with 1 neuron:
    my $ann = AI::FANN->new_standard(2, 3, 1);

    $ann->hidden_activation_function(FANN_SIGMOID_SYMMETRIC);
    $ann->output_activation_function(FANN_SIGMOID_SYMMETRIC);

    # create the training data for a XOR operator:
    my $xor_train = AI::FANN::TrainData->new( [-1, -1], [-1],
                                              [-1, 1], [1],
                                              [1, -1], [1],
                                              [1, 1], [-1] );

    $ann->train_on_data($xor_train, 500000, 100, 0.0001);

    $ann->save("xor.ann");

}
elsif ($ARGV[0] eq 'test') {

    my $ann = AI::FANN->new_from_file("xor.ann");

    for my $a (-1, 1) {
        for my $b (-1, 1) {
            my $out = $ann->run([$a, $b]);
            printf "xor(%f, %f) = %f\n", $a, $b, $out->[0];
        }
    }

}
else {
    die "bad action\n"
}
