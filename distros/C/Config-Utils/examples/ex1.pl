#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Utils qw(conflict);

# Object.
my $self = {
        'set_conflicts' => 1,
        'stack' => [],
};

# Conflict.
conflict($self, {'key' => 'value'}, 'key');

# Output:
# ERROR: Conflict in 'key'.