#!/usr/bin/env perl

use strict;
use warnings;

use Data::HashType;
use DateTime;

my $obj = Data::HashType->new(
        'id' => 10,
        'name' => 'SHA-256',
        'valid_from' => DateTime->new(
                'year' => 2024,
                'month' => 1,
                'day' => 1,
        ),
);

# Print out.
print 'Name: '.$obj->name."\n";
print 'Id: '.$obj->id."\n";
print 'Valid from: '.$obj->valid_from->ymd."\n";

# Output:
# Name: SHA-256
# Id: 10
# Valid from: 2024-01-01