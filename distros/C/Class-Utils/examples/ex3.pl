#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params_pub);

# Hash reference with default parameters.
my $self = {
        'public' => 'default',
};

# Set params.
set_params_pub($self,
        'public' => 'value',
        '_private' => 'value',
);

# Print 'test' variable.
print $self->{'public'}."\n";

# Output:
# value