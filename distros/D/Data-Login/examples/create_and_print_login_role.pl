#!/usr/bin/env perl

use strict;
use warnings;

use Data::Login::Role;

my $obj = Data::Login::Role->new(
        'active' => 1,
        'id' => 2,
        'role' => 'admin',
);

# Print out.
print 'Active flag: '.$obj->active."\n";
print 'Id: '.$obj->id."\n";
print 'Role: '.$obj->role."\n";

# Output:
# TODO