#!/usr/bin/env perl

use strict;
use warnings;

use Data::Metadata::KeyValue;

my $obj = Data::Metadata::KeyValue->new(
        'id' => 7,
        'key' => 'text',
        'value' => 'This is text',
);

# Print out.
print 'id: '.$obj->id."\n";
print 'key: '.$obj->key."\n";
print 'value: '.$obj->value."\n";

# Output:
# id: 7
# key: text
# value: This is text