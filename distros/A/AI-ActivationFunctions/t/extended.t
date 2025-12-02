#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;  # Plan primeiro

# Importar funções específicas
use AI::ActivationFunctions qw(elu swish gelu relu_derivative sigmoid_derivative);

# Teste ELU
my $elu_pos = elu(1, 1);
is(sprintf("%.1f", $elu_pos), "1.0", 'elu(1,1) = 1.0');

my $elu_neg = elu(-1, 1);
ok($elu_neg > -0.64 && $elu_neg < -0.63, "elu(-1,1) ≈ -0.632 ($elu_neg)");

# Teste Swish
my $swish1 = swish(1);
ok($swish1 > 0.73 && $swish1 < 0.74, "swish(1) ≈ 0.731 ($swish1)");

# Teste GELU
my $gelu0 = gelu(0);
ok(abs($gelu0) < 0.001, "gelu(0) ≈ 0 ($gelu0)");

my $gelu1 = gelu(1);
ok($gelu1 > 0.84 && $gelu1 < 0.85, "gelu(1) ≈ 0.841 ($gelu1)");

# Teste derivadas
is(relu_derivative(5), 1, 'relu_derivative(5) = 1');
is(relu_derivative(-5), 0, 'relu_derivative(-5) = 0');

my $sigmoid_deriv = sigmoid_derivative(0);
ok($sigmoid_deriv > 0.24 && $sigmoid_deriv < 0.26, 
   "sigmoid_derivative(0) ≈ 0.25 ($sigmoid_deriv)");
