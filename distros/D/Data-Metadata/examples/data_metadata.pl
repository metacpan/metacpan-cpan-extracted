#!/usr/bin/env perl

use strict;
use warnings;

use Data::Metadata;
use Data::Metadata::KeyValue;

my $obj = Data::Metadata->new(
        'id' => 7,
        'key_values' => [
                Data::Metadata::KeyValue->new(
                        'id' => 1,
                        'key' => 'text',
                        'value' => 'This is text',
                ),
        ],
);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Number of key/value items: '.scalar @{$obj->key_values}."\n";

# Output:
# Id: 7
# Number of key/value items: 1