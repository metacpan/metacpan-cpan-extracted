#!/usr/bin/env perl

use strict;
use warnings;

use Class::Utils qw(set_params);

# Hash reference with default parameters.
my $self = {};

# Set bad params.
set_params($self, 'bad', 'value');

# Turn error >>Unknown parameter 'bad'.<<.