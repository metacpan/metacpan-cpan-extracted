#!/usr/bin/perl
use strict;
use warnings;
use AI::ActivationFunctions qw(relu sigmoid softmax relu_derivative sigmoid_derivative);

print "=== Simple Neural Network Demo ===\n\n";

# Simple neural network layer simulation
sub neural_layer {
    my ($inputs, $weights, $biases, $activation) = @_;
    
    # Linear transformation: Wx + b
    my @output;
    for my $i (0..$#$weights) {
        my $sum = $biases->[$i];
        for my $j (0..$#$inputs) {
            $sum += $weights->[$i][$j] * $inputs->[$j];
        }
        push @output, $sum;
    }
    
    # Apply activation function
    return $activation->(\@output);
}

# Training data: OR gate
my @training_data = (
    { input => [0, 0], output => [0] },
    { input => [0, 1], output => [1] },
    { input => [1, 0], output => [1] },
    { input => [1, 1], output => [1] },
);

# Initialize weights and biases randomly
my @weights = (
    [rand() - 0.5, rand() - 0.5],  # hidden layer weights
);
my @biases = (rand() - 0.5);

print "Initial weights: [", $weights[0][0], ", ", $weights[0][1], "]\n";
print "Initial bias: ", $biases[0], "\n\n";

# Simple forward pass
print "Forward pass through network:\n";
foreach my $example (@training_data) {
    my $input = $example->{input};
    my $target = $example->{output}[0];
    
    # Forward pass
    my $hidden = neural_layer($input, \@weights, \@biases, \&sigmoid);
    my $prediction = $hidden->[0];
    
    # Calculate error
    my $error = $target - $prediction;
    
    printf("Input: [%d, %d] -> Prediction: %.4f (Target: %d, Error: %.4f)\n",
           $input->[0], $input->[1], $prediction, $target, $error);
}

# Backpropagation example
print "\nBackpropagation step (simplified):\n";
my $example = $training_data[1];  # [0
