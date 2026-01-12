#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use lib 'lib';

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required for testing';
}

use TestSchema;
use DBIx::Class::Async::Schema;

# Setup test database
my $dbfile = 't/test_row_id.db';
unlink $dbfile if -e $dbfile;

# Create and deploy schema
my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
$schema->deploy;

# Create async schema
my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

# Create test data
my $user1 = $schema->resultset('User')->create({
    name   => 'Alice',
    email  => 'alice@example.com',
    active => 1,
});

my $user2 = $schema->resultset('User')->create({
    name   => 'Bob',
    email  => 'bob@example.com',
    active => 1,
});

subtest 'id() - basic functionality' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user1->id)->get;

    can_ok($row, 'id');

    my $id = $row->id;
    ok(defined $id, 'id() returns a value');
    is($id, $user1->id, 'id() returns correct value');
};

subtest 'id() - scalar context' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user1->id)->get;

    my $id = $row->id;

    ok(defined $id, 'Returns defined value in scalar context');
    ok(!ref($id), 'Returns scalar (not reference) for single PK');
    is($id, $user1->id, 'Correct ID value');
};

subtest 'id() - list context' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user1->id)->get;

    my @ids = $row->id;

    is(scalar @ids, 1, 'Returns 1 element in list context (single PK)');
    ok(defined $ids[0], 'First element is defined');
    is($ids[0], $user1->id, 'Correct ID in list');
};

subtest 'id() - different rows have different IDs' => sub {
    plan tests => 3;

    my $row1 = $async_schema->resultset('User')->find($user1->id)->get;
    my $row2 = $async_schema->resultset('User')->find($user2->id)->get;

    my $id1 = $row1->id;
    my $id2 = $row2->id;

    ok(defined $id1, 'First row has ID');
    ok(defined $id2, 'Second row has ID');
    isnt($id1, $id2, 'Different rows have different IDs');
};

subtest 'id() - works after create' => sub {
    plan tests => 3;

    my $new_user = $async_schema->resultset('User')
        ->create({
            name   => 'NewUser',
            email  => 'new@example.com',
            active => 1,
        })->get;

    my $id = $new_user->id;

    ok(defined $id, 'ID is defined after create');
    ok($id > 0, 'ID is positive');

    # Verify it's the same as in database
    my $db_user = $schema->resultset('User')->find($id);
    is($db_user->name, 'NewUser', 'ID matches database record');
};

subtest 'id() - works after update' => sub {
    plan tests => 2;

    my $row = $async_schema->resultset('User')->find($user1->id)->get;

    my $id_before = $row->id;

    # Update the row
    $row->update({ name => 'UpdatedName' })->get;

    my $id_after = $row->id;

    is($id_after, $id_before, 'ID unchanged after update');
    ok(defined $id_after, 'ID still defined after update');
};

subtest 'id() - works with find' => sub {
    plan tests => 2;

    my $row = $async_schema->resultset('User')->find($user1->id)->get;

    ok($row, 'Found row');
    is($row->id, $user1->id, 'ID matches find parameter');
};

subtest 'id() - consistency across operations' => sub {
    plan tests => 4;

    # Create
    my $user = $async_schema->resultset('User')
        ->create({
            name   => 'Consistent',
            email  => 'consistent@example.com',
            active => 1,
        })->get;

    my $id_after_create = $user->id;
    ok(defined $id_after_create, 'Has ID after create');

    # Update
    $user->update({ name => 'ConsistentUpdated' })->get;
    my $id_after_update = $user->id;
    is($id_after_update, $id_after_create, 'Same ID after update');

    # Refetch
    my $refetched = $async_schema->resultset('User')
        ->find($id_after_create)->get;
    is($refetched->id, $id_after_create, 'Same ID when refetched');

    # List context
    my @ids = $refetched->id;
    is($ids[0], $id_after_create, 'Same ID in list context');
};

subtest 'id() - error: called as class method' => sub {
    plan tests => 1;

    eval {
        DBIx::Class::Async::Row->id();
    };
    like($@, qr/cannot be called as a class method/i,
        'Dies when called as class method');
};

subtest 'id() - with all operations' => sub {
    plan tests => 5;

    # Create
    my $user = $async_schema->resultset('User')
        ->create({
            name   => 'AllOps',
            email  => 'allops@example.com',
            active => 1,
        })->get;

    my $original_id = $user->id;
    ok($original_id, 'Has ID after create');

    # Search
    my $users = $async_schema->resultset('User')
        ->search({ id => $original_id })
        ->all->get;
    is($users->[0]->id, $original_id, 'ID correct via search');

    # Find
    my $found = $async_schema->resultset('User')
        ->find($original_id)->get;
    is($found->id, $original_id, 'ID correct via find');

    # Update
    $found->update({ active => 0 })->get;
    is($found->id, $original_id, 'ID unchanged after update');

    # Verify in database
    my $db_check = $schema->resultset('User')->find($original_id);
    is($db_check->id, $original_id, 'ID matches in database');
};

subtest 'id() - numeric vs string comparison' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user1->id)->get;

    my $id_num = $row->id;
    my $id_str = "" . $row->id;

    ok($id_num == $user1->id, 'Numeric comparison works');
    ok($id_str eq $user1->id, 'String comparison works');
    is($id_num, $id_str, 'Numeric and string representations match');
};

subtest 'id() - with relationships' => sub {
    plan tests => 4;

    # Create user and order
    my $user = $schema->resultset('User')->create({
        name   => 'RelUser',
        email  => 'reluser@example.com',
        active => 1,
    });

    my $order = $schema->resultset('Order')->create({
        user_id => $user->id,
        amount  => 100.00,
        status  => 'completed',
    });

    # Get via async
    my $async_order = $async_schema->resultset('Order')
        ->find($order->id)->get;

    ok($async_order->id, 'Order has ID');
    is($async_order->id, $order->id, 'Order ID matches');

    # Access related user
    my $related_user = $async_order->user->get;
    ok($related_user->id, 'Related user has ID');
    is($related_user->id, $user->id, 'Related user ID matches');
};

subtest 'id() - immutability' => sub {
    plan tests => 3;

    my $row = $async_schema->resultset('User')->find($user1->id)->get;

    my $id1 = $row->id;
    my $id2 = $row->id;
    my $id3 = $row->id;

    is($id1, $id2, 'Multiple calls return same value');
    is($id2, $id3, 'ID is stable');
    is($id1, $user1->id, 'ID matches expected value');
};

subtest 'id() - works with slice' => sub {
    plan tests => 2;

    # Use list context to get actual rows
    my @users = $async_schema->resultset('User')
        ->search({}, { order_by => 'id' })
        ->slice(0, 1);

    ok($users[0]->id, 'First sliced user has ID');
    ok($users[1]->id, 'Second sliced user has ID');
};

subtest 'id() - with count and aggregate' => sub {
    plan tests => 2;

    my $count = $async_schema->resultset('User')->count->get;
    ok($count > 0, 'Have users');

    # Get first user by ID
    my $first = $async_schema->resultset('User')
        ->search({}, { order_by => 'id', rows => 1 })
        ->all->get;

    ok($first->[0]->id, 'First user has ID');
};

subtest 'id() - return value consistency' => sub {
    plan tests => 4;

    my $row = $async_schema->resultset('User')->find($user1->id)->get;

    # Scalar context
    my $scalar_id = $row->id;

    # List context
    my @list_ids = $row->id;

    # Array context with assignment
    my ($first_id) = $row->id;

    is($scalar_id, $user1->id, 'Scalar context correct');
    is($list_ids[0], $user1->id, 'List context correct');
    is($first_id, $user1->id, 'Array assignment correct');
    is($scalar_id, $list_ids[0], 'Scalar and list return same value');
};

# Cleanup
END {
    unlink $dbfile if -e $dbfile;
}

done_testing();
