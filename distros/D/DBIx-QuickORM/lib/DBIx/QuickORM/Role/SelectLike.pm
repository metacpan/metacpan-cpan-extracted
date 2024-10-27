package DBIx::QuickORM::Role::SelectLike;
use strict;
use warnings;

our $VERSION = '0.000002';

use Role::Tiny;

with 'DBIx::QuickORM::Role::HasORM';

# row manipulation
requires qw{
    all
    any
    count
    find
    find_or_insert
    insert
    insert_row
    update
    update_or_insert
};

# Find scaffolding bits
requires qw{
    source
    table
};

# Returns select objects
requires qw{
    aside
    async
    forked
    relations
    select
    aggregate
};

# Utility
requires qw{
    shotgun
};

1;
