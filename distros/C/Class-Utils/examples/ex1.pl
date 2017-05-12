#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);

# Hash reference with default parameters.
my $self = {
       'test' => 'default',
};

# Set params.
set_params($self, 'test', 'real_value');

# Print 'test' variable.
print $self->{'test'}."\n";

# Output:
# real_value