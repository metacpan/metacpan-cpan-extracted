#!/usr/bin/perl

use strict;
use warnings;

use AI::FANN qw(:all);

my $n = 500;

if ($ARGV[0] eq 'train') {

    # create an ANN with 2 inputs, a hidden layer with 3 neurons and an
    # output layer with 1 neuron:
    my $ann = AI::FANN->new_standard(2, 5, 3, 1);

    $ann->hidden_activation_function(FANN_SIGMOID_SYMMETRIC);
    $ann->output_activation_function(FANN_SIGMOID_SYMMETRIC);

    my $train = AI::FANN::TrainData->new_empty($n, 2, 1);

    for (0..$n-1) {
        my $a = rand(2) - 1;
        my $b = rand(2) - 1;
        my $c = 0.5 * ($a + $b);

        $train->data($_, [$a, $b], [$c]);
    }

    $ann->train_on_data($train, 25000, 250, 0.00001);
    $ann->save("add.ann");
}
elsif ($ARGV[0] eq 'test') {

    my $ann = AI::FANN->new_from_file("add.ann");

    for (1..10) {
        my $a = rand(2) - 1;
        my $b = rand(2) - 1;

        my $c = 0.5 * ($a + $b);

        my $out = $ann->run([$a, $b]);
        printf "%f + %f = %f (good: %f, error: %4.1f%%)\n",
            $a, $b, $out->[0], $c, 50*abs($out->[0] - $c);
    }
}

else {
    die "bad action\n"
}
