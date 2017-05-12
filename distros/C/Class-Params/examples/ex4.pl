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
        'par' => ['_par', 'Moo', ['ARRAY', 'Moo'], 0],
};

# Fake class.
my $moo = bless {}, 'Moo';

# Check right 'par' parameter which has array of 'Moo' objects.
params($self, $def_hr, ['par', [$moo, $moo]]);

# Dump $self.
p $self;

# Output like:
# \ {
#     _par   [
#         [0] Moo  {
#             public methods (0)
#             private methods (0)
#             internals: {}
#         },
#         [1] var{_par}[0]
#     ]
# }