#!/usr/bin/env perl

use strict;
use warnings;

use Config::Utils qw(hash);
use Dumpvalue;

# Object.
my $self = {
        'config' => {},
        'set_conflicts' => 1,
        'stack' => [],
};

# Add records.
hash($self, ['foo', 'baz1'], 'bar');
hash($self, ['foo', 'baz2'], 'bar');

# Dump.
my $dump = Dumpvalue->new;
$dump->dumpValues($self);

# Output:
# 0  HASH(0x955f3c8)
#    'config' => HASH(0x955f418)
#       'foo' => HASH(0x955f308)
#          'baz1' => 'bar'
#          'baz2' => 'bar'
#    'set_conflicts' => 1
#    'stack' => ARRAY(0x955cc38)
#         empty array 