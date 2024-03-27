#!/usr/bin/env perl

use strict;
use warnings;

use Data::Login::Role;

my $obj = Data::Login::Role->new(
        'id' => 2,
        'role' => 'admin',
        'valid_from' => DateTime->new(
                'day' => 1,
                'month' => 1,
                'year' => 2024,
        ),
        'valid_from' => DateTime->new(
                'day' => 31,
                'month' => 12,
                'year' => 2024,
        ),
);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Role: '.$obj->role."\n";
print 'Valid from: '.$obj->valid_from->ymd."\n";
print 'Valid to: '.$obj->valid_from->ymd."\n";

# Output:
# Id: 2
# Role: admin
# Valid from: 2024-01-01
# Valid to: 2024-12-31