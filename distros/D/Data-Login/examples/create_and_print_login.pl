#!/usr/bin/env perl

use strict;
use warnings;

use Data::HashType;
use Data::Login;
use Data::Login::Role;
use DateTime;

my $obj = Data::Login->new(
        'hash_type' => Data::HashType->new(
                'id' => 1,
                'name' => 'SHA-512',
                'valid_from' => DateTime->new(
                        'day' => 1,
                        'month' => 1,
                        'year' => 2024,
                ),
        ),
        'id' => 2,
        'login_name' => 'michal.josef.spacek',
        'password_hash' => '24ea354ebd9198257b8837fd334ac91663bf52c05658eae3c9e6ad0c87c659c62e43a2e1e5a1e573962da69c523bf1f680c70aedd748cd2b71a6d3dbe42ae972',
        'roles' => [
                Data::Login::Role->new(
                        'active' => 1,
                        'id' => 1,
                        'role' => 'Admin',
                ),
                Data::Login::Role->new(
                        'active' => 1,
                        'id' => 2,
                        'role' => 'User',
                ),
                Data::Login::Role->new(
                        'active' => 0,
                        'id' => 3,
                        'role' => 'Bad',
                ),
        ],
        'valid_from' => DateTime->new(
                'day' => 1,
                'month' => 1,
                'year' => 2024,
        ),
);

# Print out.
print 'Hash type: '.$obj->hash_type->name."\n";
print 'Id: '.$obj->id."\n";
print 'Login name: '.$obj->login_name."\n";
print 'Password hash: '.$obj->password_hash."\n";
print "Active roles:\n";
print join "\n", map { $_->active ? ' - '.$_->role : () } @{$obj->roles};
print "\n";
print 'Valid from: '.$obj->valid_from->ymd."\n";

# Output:
# Hash type: SHA-512
# Id: 2
# Login name: michal.josef.spacek
# Password hash: 24ea354ebd9198257b8837fd334ac91663bf52c05658eae3c9e6ad0c87c659c62e43a2e1e5a1e573962da69c523bf1f680c70aedd748cd2b71a6d3dbe42ae972
# Active roles:
#  - Admin
#  - User
# Valid from: 2024-01-01