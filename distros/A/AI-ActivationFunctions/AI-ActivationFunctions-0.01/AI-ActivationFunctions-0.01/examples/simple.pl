#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use AI::ActivationFunctions qw(:all);

print "=== Demonstração Completa ===\n\n";

print "1. Funções Básicas:\n";
printf("   relu(5)        = %d\n", relu(5));
printf("   relu(-3)       = %d\n", relu(-3));
printf("   prelu(-2, 0.1) = %.1f\n", prelu(-2, 0.1));
printf("   sigmoid(0)     = %.4f\n", sigmoid(0));
printf("   tanh(1)        = %.4f\n", tanh(1));

print "\n2. Funções Avançadas:\n";
printf("   elu(-1, 1)     = %.4f\n", elu(-1, 1));
printf("   swish(1)       = %.4f\n", swish(1));
printf("   gelu(1)        = %.4f\n", gelu(1));

print "\n3. Derivadas (para backpropagation):\n";
printf("   relu_derivative(5)     = %d\n", relu_derivative(5));
printf("   relu_derivative(-5)    = %d\n", relu_derivative(-5));
printf("   sigmoid_derivative(0)  = %.4f\n", sigmoid_derivative(0));

print "\n4. Softmax (distribuição):\n";
my $scores = [1.0, 2.0, 3.0];
my $probs = softmax($scores);
printf("   Entrada:  [%.1f, %.1f, %.1f]\n", @$scores);
printf("   Saída:    [%.4f, %.4f, %.4f]\n", @$probs);
printf("   Soma:     %.4f\n", $probs->[0] + $probs->[1] + $probs->[2]);

print "\n=== Fim da Demonstração ===\n";
