package AI::ActivationFunctions;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.01';
our $ABSTRACT = 'Activation functions for neural networks in Perl';

# Lista COMPLETA de funções exportáveis
our @EXPORT_OK = qw(
    relu prelu leaky_relu 
    sigmoid tanh softmax
    elu swish gelu
    relu_derivative sigmoid_derivative
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    basic => [qw(relu prelu leaky_relu sigmoid tanh softmax)],
    advanced => [qw(elu swish gelu)],
    derivatives => [qw(relu_derivative sigmoid_derivative)],
);

# ReLU
sub relu {
    my ($x) = @_;
    return $x > 0 ? $x : 0;
}

# PReLU
sub prelu {
    my ($x, $alpha) = @_;
    $alpha //= 0.01;
    return $x > 0 ? $x : $alpha * $x;
}

# Leaky ReLU
sub leaky_relu {
    my ($x) = @_;
    return prelu($x, 0.01);
}

# Sigmoid
sub sigmoid {
    my ($x) = @_;
    return 1 / (1 + exp(-$x));
}

# Tanh
sub tanh {
    my ($x) = @_;
    my $e2x = exp(2 * $x);
    return ($e2x - 1) / ($e2x + 1);
}

# Softmax para array
sub softmax {
    my ($array) = @_;
    
    return undef unless ref($array) eq 'ARRAY';
    
    # Encontrar máximo
    my $max = $array->[0];
    foreach my $val (@$array) {
        $max = $val if $val > $max;
    }
    
    # Calcular exponenciais
    my @exp_vals;
    my $sum = 0;
    foreach my $val (@$array) {
        my $exp_val = exp($val - $max);
        push @exp_vals, $exp_val;
        $sum += $exp_val;
    }
    
    # Normalizar
    return [map { $_ / $sum } @exp_vals];
}

# ELU (Exponential Linear Unit)
sub elu {
    my ($x, $alpha) = @_;
    $alpha //= 1.0;
    return $x > 0 ? $x : $alpha * (exp($x) - 1);
}

# Swish (Google)
sub swish {
    my ($x) = @_;
    return $x * sigmoid($x);
}

# GELU (Gaussian Error Linear Unit)
sub gelu {
    my ($x) = @_;
    return 0.5 * $x * (1 + tanh(sqrt(2/3.141592653589793) * 
        ($x + 0.044715 * $x**3)));
}

# Derivada da ReLU
sub relu_derivative {
    my ($x) = @_;
    return $x > 0 ? 1 : 0;
}

# Derivada da Sigmoid
sub sigmoid_derivative {
    my ($x) = @_;
    my $s = sigmoid($x);
    return $s * (1 - $s);
}

1;


=head1 NAME

AI::ActivationFunctions - Activation functions for neural networks in Perl

=head1 VERSION

Version 0.01

=head1 ABSTRACT

Activation functions for neural networks in Perl

=head1 SYNOPSIS

    use AI::ActivationFunctions qw(relu prelu sigmoid);

    my $result = relu(-5);  # returns 0
    my $prelu_result = prelu(-2, 0.1);  # returns -0.2

    # Array version works too
    my $array_result = relu([-2, -1, 0, 1, 2]);  # returns [0, 0, 0, 1, 2]

=head1 DESCRIPTION

This module provides various activation functions commonly used in neural networks
and machine learning. It includes basic functions like ReLU and sigmoid, as well
as advanced functions like GELU and Swish.

=head1 FUNCTIONS

=head2 Basic Functions

=over 4

=item * relu($input)

Rectified Linear Unit. Returns max(0, $input).

=item * prelu($input, $alpha=0.01)

Parametric ReLU. Returns $input if $input > 0, else $alpha * $input.

=item * leaky_relu($input)

Leaky ReLU with alpha=0.01.

=item * sigmoid($input)

Sigmoid function: 1 / (1 + exp(-$input)).

=item * tanh($input)

Hyperbolic tangent function.

=item * softmax(\@array)

Softmax function for probability distributions.

=back

=head2 Advanced Functions

=over 4

=item * elu($input, $alpha=1.0)

Exponential Linear Unit.

=item * swish($input)

Swish activation function.

=item * gelu($input)

Gaussian Error Linear Unit (used in transformers like BERT, GPT).

=back

=head2 Derivatives

=over 4

=item * relu_derivative($input)

Derivative of ReLU for backpropagation.

=item * sigmoid_derivative($input)

Derivative of sigmoid for backpropagation.

=back

=head1 EXPORT

By default nothing is exported. You can export specific functions:

    use AI::ActivationFunctions qw(relu prelu);  # specific functions
    use AI::ActivationFunctions qw(:basic);      # basic functions
    use AI::ActivationFunctions qw(:all);        # all functions

=head1 SEE ALSO

=over 4

=item * L<PDL> - Perl Data Language for numerical computing

=item * L<AI::TensorFlow> - Perl interface to TensorFlow

=item * L<AI::MXNet> - Perl interface to Apache MXNet

=back

=head1 AUTHOR

Your Name <your.email@example.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
