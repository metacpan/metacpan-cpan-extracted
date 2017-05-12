#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Utils qw(hash_array);
use Dumpvalue;

# Object.
my $self = {
        'config' => {},
        'set_conflicts' => 1,
        'stack' => [],
};

# Add records.
hash_array($self, ['foo', 'baz'], 'bar');
hash_array($self, ['foo', 'baz'], 'bar');

# Dump.
my $dump = Dumpvalue->new;
$dump->dumpValues($self);

# Output:
# 0  HASH(0x8edf890)
#    'config' => HASH(0x8edf850)
#       'foo' => HASH(0x8edf840)
#          'baz' => ARRAY(0x8edf6d0)
#             0  'bar'
#             1  'bar'
#    'set_conflicts' => 1
#    'stack' => ARRAY(0x8edf6e0)
#         empty array