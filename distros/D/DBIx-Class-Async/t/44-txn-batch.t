#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use lib 'lib', 't/lib';

use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async;
use DBIx::Class::Async::Schema;

subtest "Async db txn_batch" => sub {
    # 1. Create a temporary file for the database
    my (undef, $db_file) = tempfile(UNLINK => 1);
    my $dsn = "dbi:SQLite:dbname=$db_file";

    # 2. Initialise sync schema
    my $schema = TestSchema->connect($dsn);

    # 3. Deploy the schema
    $schema->deploy();

    # 4. Initialise async db
    my $async_db = DBIx::Class::Async->new(
        schema_class => 'TestSchema',
        connect_info => [ $dsn, '', '' ],
        workers      => 1,
    );

    # 5. Create a user
    my $user = $async_db->create(
        'User',
        { name  => 'Original Name',
          email => 'original@test.com'
        })->get;

    my $user_id = $user->{id};

    my @batch = (
        {
            type      => 'create',
            resultset => 'User',
            data      => { name => 'New Batch User', email => 'batch@test.com' }
        },
        {
            type      => 'update',
            resultset => 'User',
            id        => $user_id,
            data      => { name => 'Updated Name' }
        }
    );

    # 6. Perform txn using async db
    my $count = $async_db->txn_batch(\@batch)->get;
    is($count, 2, "Async db executed 2 operations.");

    my $updated = $schema->resultset('User')->find($user_id);
    is($updated->name, 'Updated Name', "Async db update persisted.");

    my $new_user = $schema->resultset('User')->find({ email => 'batch@test.com' });
    is($new_user->name, 'New Batch User', "Async db create persisted.");
};

subtest "Async schema txn_batch" => sub {
    # 1. Create a temporary file for the database
    my (undef, $db_file) = tempfile(UNLINK => 1);
    my $dsn = "dbi:SQLite:dbname=$db_file";

    # 2. Initialise async schema
    my $loop = IO::Async::Loop->new;
    my $async_schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef, undef, { RaiseError => 1 },
        { workers => 1, schema_class => 'TestSchema', loop => $loop }
    );

    # 3. Deploy the schema
    $async_schema->deploy()->get;

    # 4. Create a user
    my $user = $async_schema->resultset('User')->create({
        name  => 'Original Name',
        email => 'original@test.com'
    })->get;

    my $user_id = $user->id;

    my @batch = (
        {
            type      => 'create',
            resultset => 'User',
            data      => { name => 'New Batch User', email => 'batch@test.com' }
        },
        {
            type      => 'update',
            resultset => 'User',
            id        => $user_id,
            data      => { name => 'Updated Name' }
        }
    );

    # 5. Perform txn using async schema
    my $count = $async_schema->txn_batch(\@batch)->get;
    is($count, 2, "Async schema executed 2 operations.");

    my $updated = $async_schema->resultset('User')->find($user_id)->get;
    is($updated->name, 'Updated Name', "Async schema update persisted.");

    my $new_user = $async_schema->resultset('User')->find({ email => 'batch@test.com' })->get;
    is($new_user->name, 'New Batch User', "Async schema create persisted.");
};

done_testing();
