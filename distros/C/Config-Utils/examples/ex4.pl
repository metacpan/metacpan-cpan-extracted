#!/usr/bin/env perl

use strict;
use warnings;

use Config::Utils qw(hash_array);
use Dumpvalue;

# Object.
my $self = {
        'callback' => sub {
                my ($key_ar, $value) = @_;
                return uc($value);
        },
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
#    'callback' => CODE(0x8405c40)
#       -> &CODE(0x8405c40) in ???
#    'config' => HASH(0x8edf850)
#       'foo' => HASH(0x8edf840)
#          'baz' => ARRAY(0x8edf6d0)
#             0  'BAR'
#             1  'BAR'
#    'set_conflicts' => 1
#    'stack' => ARRAY(0x8edf6e0)
#         empty array