#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use Future::AsyncAwait;
use DBIx::Class::Async::Schema;

use lib 't/lib';
use TestDB;

my $db_file      = setup_test_db();
my $loop         = IO::Async::Loop->new;
my $schema_class = get_test_schema_class();

my $schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => $schema_class, loop => $loop }
);

my $email_counter = 0;
sub unique_email {
    return 'test' . $email_counter++ . '@example.com';
}

subtest 'update_or_insert - insert when not in storage' => sub {

    my $test = async sub {
        # Create a new row object (not in database yet)
        my $user = $schema->resultset('User')->new_result({
            name  => 'New User',
            email => unique_email(),
        });

        ok(!$user->in_storage, 'Row is not in storage initially');

        my $result = await $user->update_or_insert({
            name  => 'New User',
            email => $user->get_column('email') // unique_email(),
        });

        ok(defined $result->id, 'Result has an ID');
        is($result->get_column('name'), 'New User', 'Name is correct');
    };

    eval { $test->()->get; };
    if ($@) {
        fail("Test failed with error: $@");
    }
};

subtest 'update_or_insert - update when in storage' => sub {

    my $test = async sub {
        # Create and insert a user
        my $user = await $schema->resultset('User')->create({
            name  => 'Original Name',
            email => unique_email(),
        });

        ok($user->in_storage, 'Row is in storage');
        my $original_id = $user->id;

        # Modify the user using set_column
        $user->set_column('name', 'Updated Name');

        # Call update_or_insert - should update
        my $result = await $user->update_or_insert;

        is($result->id, $original_id, 'ID unchanged (same row)');
        is($result->get_column('name'), 'Updated Name', 'Name was updated');

        # Verify in database
        my $found = await $schema->resultset('User')->find($original_id);
        is($found->get_column('name'), 'Updated Name', 'Update persisted to database');
        is($found->get_column('email'), $user->get_column('email'), 'Other columns unchanged');
    };

    eval { $test->()->get; };
    if ($@) {
        fail("Test failed with error: $@");
    }
};

subtest 'insert_or_update - alias works for insert' => sub {

    my $test = async sub {
        my $user = $schema->resultset('User')->new_result({
            name  => 'Alias Test Insert',
            email => unique_email(),
        });

        ok(!$user->in_storage, 'Row not in storage');

        # Use the alias method
        my $result = await $user->insert_or_update;

        ok($result->in_storage, 'Row inserted via alias');
        is($result->name, 'Alias Test Insert', 'Data correct');
    };

    eval { $test->()->get; };
    if ($@) {
        fail("Test failed with error: $@");
    }
};

subtest 'insert_or_update - alias works for update' => sub {

    my $test = async sub {
        my $user = await $schema->resultset('User')->create({
            name  => 'Alias Test Update',
            email => unique_email(),
        });

        my $original_id = $user->id;
        $user->set_column('name', 'Updated via Alias');

        # Use the alias method
        my $result = await $user->insert_or_update;

        is($result->id, $original_id, 'Same row updated');

        # Fetch fresh from database to verify the update persisted
        my $found = await $schema->resultset('User')->find($original_id);
        is($found->get_column('name'), 'Updated via Alias', 'Update persisted');
        is($found->get_column('email'), $user->get_column('email'), 'Email unchanged');
    };

    eval { $test->()->get; };
    if ($@) {
        fail("Test failed with error: $@");
    }
};

subtest 'Multiple update_or_insert calls' => sub {

    my $test = async sub {
        # First call - insert
        my $user = $schema->resultset('User')->new_result({
            name  => 'Multi Test',
            email => unique_email(),
        });

        my $result1 = await $user->update_or_insert;
        ok($result1->in_storage, 'First call inserted');
        my $id = $result1->id;

        # Second call - update
        #$user->name('Multi Test Updated 1');
        $user->set_column('name', 'Multi Test Updated 1');
        my $result2 = await $user->update_or_insert;
        is($result2->id, $id, 'Second call updated same row');
        is($result2->name, 'Multi Test Updated 1', 'Second update correct');

        # Third call - another update
        $user->name('Multi Test Updated 2');
        my $result3 = await $user->update_or_insert;
        is($result3->id, $id, 'Third call updated same row');
        is($result3->name, 'Multi Test Updated 2', 'Third update correct');

        # Verify final state
        my $found = await $schema->resultset('User')->find($id);
        is($found->name, 'Multi Test Updated 2', 'Final state correct');
    };

    eval { $test->()->get; };
    if ($@) {
        fail("Test failed with error: $@");
    }
};

subtest 'update_or_insert with unique constraints' => sub {

    my $test = async sub {
        my $unique_email = unique_email();

        # Create user with unique email
        my $user1 = await $schema->resultset('User')->create({
            name  => 'User 1',
            email => $unique_email,
        });

        my $user2 = $schema->resultset('User')->new_result({
            name  => 'User 2',
            email => $unique_email,
        });

        # This should fail due to unique constraint
        my $error;
        eval {
            await $user2->update_or_insert;
        };
        $error = $@;

        ok($error, 'Insert with duplicate email fails');
        like($error, qr/UNIQUE|constraint/i, 'Error mentions unique constraint');

        $user1->name('User 1 Updated');

        my $updated = await $user1->update_or_insert;
        is($updated->name, 'User 1 Updated', 'Update with same email works');
        is($updated->email, $unique_email, 'Email unchanged');
    };

    eval { $test->()->get; };
    if ($@) {
        fail("Test failed with error: $@");
    }
};

$schema->disconnect;
teardown_test_db();

done_testing();
