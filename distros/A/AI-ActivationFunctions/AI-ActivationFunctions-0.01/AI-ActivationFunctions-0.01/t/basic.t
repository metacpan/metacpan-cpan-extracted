#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 17;  # Agora 17 testes!

# Carregar e importar
use AI::ActivationFunctions qw(relu prelu leaky_relu sigmoid tanh softmax);

# Teste 1: ReLU
is(relu(5), 5, 'relu(5) = 5');
is(relu(-5), 0, 'relu(-5) = 0');
is(relu(0), 0, 'relu(0) = 0');

# Teste 2: PReLU
is(prelu(2, 0.1), 2, 'prelu(2, 0.1) = 2');
is(sprintf("%.1f", prelu(-2, 0.1)), "-0.2", 'prelu(-2, 0.1) = -0.2');
is(sprintf("%.2f", prelu(-2)), "-0.02", 'prelu(-2) com alpha padrão = -0.02');

# Teste 3: Leaky ReLU
is(leaky_relu(2), 2, 'leaky_relu(2) = 2');
is(sprintf("%.2f", leaky_relu(-2)), "-0.02", 'leaky_relu(-2) = -0.02');

# Teste 4: Sigmoid
my $sigmoid0 = sigmoid(0);
ok($sigmoid0 > 0.49 && $sigmoid0 < 0.51, "sigmoid(0) ≈ 0.5 ($sigmoid0)");

my $sigmoid1 = sigmoid(1);
ok($sigmoid1 > 0.73 && $sigmoid1 < 0.74, "sigmoid(1) ≈ 0.731 ($sigmoid1)");

# Teste 5: Tanh
my $tanh0 = tanh(0);
ok(abs($tanh0) < 0.001, "tanh(0) ≈ 0 ($tanh0)");

my $tanh1 = tanh(1);
ok($tanh1 > 0.76 && $tanh1 < 0.77, "tanh(1) ≈ 0.761 ($tanh1)");

# Teste 6: Softmax
my $scores = [1, 2, 3];
my $probs = softmax($scores);

is(ref($probs), 'ARRAY', 'softmax retorna arrayref');
is(scalar @$probs, 3, 'softmax retorna 3 elementos');

my $sum = 0;
$sum += $_ for @$probs;
ok(abs($sum - 1) < 0.0001, "softmax soma ≈ 1 ($sum)");

# Verifica ordem (maior score = maior probabilidade)
ok($probs->[2] > $probs->[1], "Prob[2] > Prob[1]");
ok($probs->[1] > $probs->[0], "Prob[1] > Prob[0]");
