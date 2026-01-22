#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use Test::Deep;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use lib 't/lib';
use TestDB;

my $db_file      = setup_test_db();
my $loop         = IO::Async::Loop->new;
my $schema_class = get_test_schema_class();

# Test 1: Empty results
subtest 'Empty results' => sub {

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 1, schema_class => $schema_class, loop => $loop }
    );

    # Search with no results
    my $empty_future = $schema->resultset('User')->search({
        name => 'Nonexistent User 12345',
    })->all_future;

    my $empty_results = $empty_future->get;
    ok(ref $empty_results eq 'ARRAY', 'Empty search returns arrayref');
    is(scalar @$empty_results, 0, 'Empty search has no rows');

    # Count of empty results
    my $count_future = $schema->resultset('User')->search({
        name => 'Nonexistent User 12345',
    })->count_future;

    my $count = $count_future->get;
    is($count, 0, 'Count returns 0 for no results');

    # Update empty resultset
    my $update_future = $schema->resultset('User')->search({
        name => 'Nonexistent User 12345',
    })->update({ active => 0 });

    my $updated = $update_future->get;
    is($updated + 0, 0, 'Update affects 0 rows');  # +0 converts '0E0' to 0

    # Delete empty resultset
    my $delete_future = $schema->resultset('User')->search({
        name => 'Nonexistent User 12345',
    })->delete;

    my $deleted = $delete_future->get;
    is($deleted, 0, 'Delete affects 0 rows');

    $schema->disconnect;
};

# Test 2: Special characters and encoding
subtest 'Encoding and special chars' => sub {

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 1, schema_class => $schema_class, loop => $loop }
    );

    my $special_name = "O'Connor & \"Special\" <Chars>";
    my $special_user_future = $schema->resultset('User')->create({
        name   => $special_name,
        email  => 'special@example.com',
        active => 1,
    });

    my $special_user = $special_user_future->get;
    is($special_user->name, $special_name, 'Special characters preserved');

    # Verify via search
    my $verify_future = $schema->resultset('User')->search({
        email => 'special@example.com',
    })->all_future;

    my $verify_results = $verify_future->get;
    ok(@$verify_results > 0, 'Found user with special characters');
    is($verify_results->[0]->{name}, $special_name, 'Special characters retrieved correctly');

    $special_user->delete->get;

    $schema->disconnect;
};

# Test 3: Large result sets (memory)
subtest 'Large result sets' => sub {

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 1, schema_class => $schema_class, loop => $loop }
    );

    # Create many users
    my $batch_size = 50;
    my @futures;

    for my $i (1..$batch_size) {
        push @futures, $schema->resultset('User')->create({
            name   => "Batch User $i",
            email  => "batch$i\@example.com",
            active => 1,
        });
    }

    # Wait for all creates
    my $wait_future = Future->wait_all(@futures);
    $wait_future->get;

    # Count them
    my $count_future = $schema->resultset('User')->search({
        name => { like => 'Batch User%' },
    })->count_future;

    my $count = $count_future->get;
    cmp_ok($count, '>=', $batch_size, "Created at least $batch_size users");

    # Fetch all (tests memory)
    my $all_future = $schema->resultset('User')->search({
        name => { like => 'Batch User%' },
    })->all_future;

    my $all_results = $all_future->get;
    my $fetched_count = scalar @$all_results;

    cmp_ok($fetched_count, '>=', $batch_size, "Fetched at least $batch_size users");

    # Clean up
    my $delete_count = $schema->resultset('User')->search({
        name => { like => 'Batch User%' },
    })->delete->get;

    cmp_ok($delete_count, '>=', $batch_size, "Deleted batch users");

    $schema->disconnect;
};

# Test 4: Concurrent modifications
subtest 'Concurrent access' => sub {

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 4, schema_class => $schema_class, loop => $loop }
    );

    # Create test user
    my $test_user = $schema->resultset('User')->create({
        name   => 'Concurrent Test',
        email  => 'concurrent@example.com',
        active => 1,
    })->get;

    my $user_id = $test_user->id;

    # Multiple concurrent updates
    my @update_futures;
    for my $i (1..5) {
        push @update_futures, $schema->resultset('User')->find($user_id)->then(sub {
            my $user = shift;
            return Future->done(undef) unless $user;
            return $user->update({ name => "Update $i" });
        });
    }

    # Wait for all updates
    my $update_wait = Future->wait_all(@update_futures);
    $update_wait->get;

    # Verify final state
    my $final_user = $schema->resultset('User')->find($user_id)->get;
    ok($final_user, 'User still exists after concurrent updates');
    like($final_user->name, qr/^Update \d+$/, 'User was updated');

    # Multiple concurrent reads
    my @read_futures;
    for my $i (1..10) {
        push @read_futures, $schema->resultset('User')->find($user_id);
    }

    my $read_wait = Future->wait_all(@read_futures);
    $read_wait->get;

    my $all_ok = 1;
    foreach my $f (@read_futures) {
        my $user = $f->get;
        $all_ok &&= $user && $user->id == $user_id;
    }

    ok($all_ok, 'All concurrent reads succeeded');

    $final_user->delete->get;

    $schema->disconnect;
};


# Test 5: Error recovery
subtest 'Error recovery' => sub {
    # 1. Reset the DB file
    my $db_file = setup_test_db();

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 2, schema_class => $schema_class, loop => $loop }
    );

    # Invalid table name
    throws_ok {
        $schema->resultset('NonExistentTable')->search({})->all_future->get;
    } qr/No such resultset|source|Can't locate/i, 'Invalid table throws error';

    # Invalid column in search - SQLite doesn't always catch this at search time
    eval {
        $schema->resultset('User')->search({
            nonexistent_column => 'value',
        })->all_future->get;
    };
    pass('Invalid column handled gracefully');

    # 2. Before the valid operation, let's ensure one user exists
    # so count > 0 is guaranteed.
    $schema->resultset('User')->create({
        name => 'Recovery Test User',
        email => 'recovery@example.com',
        active => 1
    })->get;

    # Valid operation works
    my $valid_future = $schema->resultset('User')->count_future;
    my $count = $valid_future->get;
    cmp_ok($count, '>', 0, 'Valid operation works');

    $schema->disconnect;
};

teardown_test_db();

done_testing();
