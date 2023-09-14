#!/usr/bin/env perl

use strict;
use warnings;

use Data::HashType;

my $obj = Data::HashType->new(
        'active' => 1,
        'id' => 10,
        'name' => 'SHA-256',
);

# Print out.
print 'Name: '.$obj->name."\n";
print 'Active: '.$obj->active."\n";
print 'Id: '.$obj->id."\n";

# Output:
# Name: SHA-256
# Active: 1
# Id: 10