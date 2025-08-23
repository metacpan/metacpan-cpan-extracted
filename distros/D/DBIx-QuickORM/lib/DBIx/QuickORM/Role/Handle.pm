package DBIx::QuickORM::Role::Handle;
use strict;
use warnings;

our $VERSION = '0.000019';

use Carp qw/croak/;

use Role::Tiny;

requires qw{
    handle
    clone

    is_aside
    is_async
    is_forked
    is_sync

    by_id
    by_ids

    all
    one
    count
    first
    iterate
    iterator

    delete
    insert
    update
    vivify
    upsert

    connection
    dialect
    source
    sql_builder
    sync
    aside
    async
    forked
    data_only
    fields
    limit
    omit
    order_by
    row
    where

    cross_join
    full_join
    inner_join
    left_join
    right_join
};

sub internal_transactions    { croak "Not Supported" }
sub internal_txns            { croak "Not Supported" }
sub insert_and_refresh       { croak "Not Supported" }
sub auto_refresh             { croak "Not Supported" }
sub no_internal_transactions { croak "Not Supported" }
sub no_internal_txns         { croak "Not Supported" }

sub any { shift->first(@_) }

1;
