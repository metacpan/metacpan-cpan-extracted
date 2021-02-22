#!/usr/bin/env perl

use strict;
use warnings;

use Class::Params qw(params);

# Definition.
my $self = {};
my $def_hr = {
        'par' => ['_par', 'Moo', ['ARRAY', 'Moo'], 0],
};

# Fake class.
my $moo = bless {}, 'Moo';

# Check bad 'par' parameter which has bad 'bar' scalar.
params($self, $def_hr, ['par', [$moo, 'bar']]);

# Output like:
# Bad parameter 'par' class.