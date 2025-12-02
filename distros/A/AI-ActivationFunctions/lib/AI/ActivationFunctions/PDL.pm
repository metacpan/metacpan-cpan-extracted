package AI::ActivationFunctions;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(relu prelu leaky_relu sigmoid tanh softmax elu swish gelu relu_derivative sigmoid_derivative);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# ReLU - MUITO simples
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
    return $x > 0 ? $x : 0.01 * $x;
}

# Sigmoid
sub sigmoid {
    my ($x) = @_;
    return 1 / (1 + exp(-$x));
}

# Tanh - versão correta (sem CORE::tanh)
sub tanh {
    my ($x) = @_;
    my $e2x = exp(2 * $x);
    return ($e2x - 1) / ($e2x + 1);
}

# Softmax para array
sub softmax {
    my ($array) = @_;
    
    # Encontrar máximo para estabilidade numérica
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

# GELU (Gaussian Error Linear Unit) - usado em BERT/GPT
sub gelu {
    my ($x) = @_;
    return 0.5 * $x * (1 + tanh(sqrt(2/3.141592653589793) * 
        ($x + 0.044715 * $x**3)));
}

# Derivada da ReLU (para backpropagation)
sub relu_derivative {
    my ($x) = @_;
    return $x > 0 ? 1 : 0;
}

# Derivada da Sigmoid (para backpropagation)
sub sigmoid_derivative {
    my ($x) = @_;
    my $s = sigmoid($x);
    return $s * (1 - $s);
}



1;
