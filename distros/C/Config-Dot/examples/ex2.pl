#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot;

# Object with data.
my $c = Config::Dot->new(
        'config' => {
                'key1' => {
                        'subkey1' => 'value1',
                },
                'key2' => 'value2',
        },
);

# Serialize.
print $c->serialize."\n";

# Output:
# key1=subkey1.value1
# key2=value2