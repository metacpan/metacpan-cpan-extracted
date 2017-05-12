#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Params qw(params);

# Definition.
my $self = {};
my $def_hr = {
        'par' => ['_par', undef, 'SCALAR', 1],
};

# Check.
# output_structure, definition, array of pairs (key, value).
params($self, $def_hr, ['bad_par', 1]);

# Output:
# Unknown parameter 'bad_par'.