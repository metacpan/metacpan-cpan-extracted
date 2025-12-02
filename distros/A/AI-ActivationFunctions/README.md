# AI::ActivationFunctions

Activation functions for neural networks and machine learning in Perl.

## Installation

```bash
cpanm AI::ActivationFunctions


## Usage

use AI::ActivationFunctions qw(relu prelu sigmoid softmax);

# Basic usage
my $result = relu(-5);  # returns 0

# With custom parameter
my $prelu = prelu(-2, 0.1);  # returns -0.2

# Probability distribution
my $probs = softmax([1, 2, 3]);

# Functions

relu($x) - Rectified Linear Unit

prelu($x, $alpha=0.01) - Parametric ReLU

leaky_relu($x) - Leaky ReLU

sigmoid($x) - Sigmoid function

tanh($x) - Hyperbolic tangent

softmax(\@array) - Softmax function

elu($x, $alpha=1.0) - Exponential Linear Unit

swish($x) - Swish activation

gelu($x) - Gaussian Error Linear Unit

relu_derivative($x) - ReLU derivative

sigmoid_derivative($x) - Sigmoid derivative

