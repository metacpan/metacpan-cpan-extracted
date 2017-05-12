#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Params qw(params);
use Data::Printer;

# Definition.
my $self = {};
my $def_hr = {
        'par' => ['_par', undef, 'SCALAR', 1],
};

# Check.
# output_structure, definition, array of pairs (key, value).
params($self, $def_hr, ['par', 1]);

# Dump $self.
p $self;

# Output:
# \ {
#     _par   1
# }