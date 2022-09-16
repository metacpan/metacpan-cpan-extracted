#!/usr/bin/env perl

use strict;
use warnings;

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