#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Deep;
use Test::Exception;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use lib 't/lib';
use TestDB;

my $db_file      = setup_test_db();
my $loop         = IO::Async::Loop->new;
my $schema_class = get_test_schema_class();
my $schema       = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file",
    undef,
    undef,
    {
        sqlite_unicode => 1,
        on_connect_do  => [
            'PRAGMA journal_mode=WAL',
            'PRAGMA synchronous=NORMAL',
            'PRAGMA busy_timeout=5000',
        ],
    },
    { workers => 2, schema_class => $schema_class, loop => $loop }
);

# Test 1: Row object creation and basics
subtest 'Row basics' => sub {

    my $rs          = $schema->resultset('User');
    my $user_future = $rs->find(1);
    my $user        = $user_future->get;

    isa_ok($user, 'DBIx::Class::Async::Row', 'Row object');

    # Test get_column
    is($user->get_column('name'), 'Alice', 'get_column() works');
    is($user->get_column('email'), 'alice@example.com', 'get_column() works for email');

    # Test column accessor via method call
    is($user->name, 'Alice', 'Column accessor via method');
    is($user->email, 'alice@example.com', 'Column accessor via method');

    # Test get_columns
    my %columns = $user->get_columns;
    is_deeply(
        \%columns,
        {
            id     => 1,
            name   => 'Alice',
            email  => 'alice@example.com',
            active => 1,
        },
        'get_columns() returns all columns'
    );

    my %inflated = $user->get_inflated_columns;
    is($inflated{name}, 'Alice', 'get_inflated_columns includes name');

    ok($user->in_storage, 'Row is in storage');
};

# Test 2: Row update operations
subtest 'Row updates' => sub {

    my $rs = $schema->resultset('User');

    my $user_future = $rs->find(2);
    my $user        = $user_future->get;

    ok($user, 'Found user with id=2 (Bob)');
    is($user->name, 'Bob', 'User is Bob');

    # Update via row object
    my $update_future = $user->update({
        name  => 'Bob Updated',
        email => 'bob.updated@example.com'
    });

    isa_ok($update_future, 'Future', 'Row update returns Future');

    # Verify persistence
    my $updated = $update_future->get;
    isa_ok($updated, 'DBIx::Class::Async::Row', 'Returns Row');
    is($updated->name, 'Bob Updated', 'Name was updated');
    is($updated->email, 'bob.updated@example.com', 'Email was updated');

    # Force a reload from DB to prove it hit the disk
    my $discard_future = $updated->discard_changes;
    $discard_future->get;

    is($updated->name, 'Bob Updated', 'Update persisted after discard_changes');
    is($updated->email, 'bob.updated@example.com', 'Email persisted after discard_changes');
};

# Test 3: Row delete operations
subtest 'Row deletion' => sub {

    my $rs = $schema->resultset('User');

    # Create a user to delete
    my $new_user = $rs->create({
        name   => 'Temp User',
        email  => 'temp@example.com',
        active => 1,
    })->get;

    my $temp_id = $new_user->id;
    ok($temp_id, 'Created temp user with id');

    # Delete the row
    my $delete_future = $new_user->delete;
    isa_ok($delete_future, 'Future', 'Row delete returns Future');

    my $deleted = $delete_future->get;
    ok(defined $deleted, 'Delete completed');

    # Verify deletion from database
    my $check = $rs->find($temp_id)->get;
    ok(!$check, 'Row was deleted from database');

    # Row object should know it's not in storage
    ok(!$new_user->in_storage, 'Row object knows it\'s not in storage');
};

# Test 4: Relationships
subtest 'Row relationships' => sub {

    my $user_rs  = $schema->resultset('User');
    my $order_rs = $schema->resultset('Order');

    # User with orders (Alice, id=1)
    my $user = $user_rs->find(1)->get;
    ok($user, 'Found Alice (user id=1)');

    # Test related_resultset
    my $orders_rs = $user->related_resultset('orders');
    isa_ok($orders_rs, 'DBIx::Class::Async::ResultSet', 'related_resultset() works');
    is($orders_rs->source_name, 'Order', 'Correct related resultset');

    # Get orders via relationship
    my $orders = $user->orders->all->get;
    isa_ok($orders, 'ARRAY', 'Relationship returns arrayref');
    is(scalar @$orders, 2, 'Alice has 2 orders');

    my $first_order = $orders->[0];
    isa_ok($first_order, 'DBIx::Class::Async::Row', 'Order is Row object');
    is($first_order->user_id, 1, 'Order belongs to user');

    # Test belongs_to relationship
    my $order = $order_rs->find(1)->get;
    ok($order, 'Found order id=1');

    my $order_user = $order->user->get;
    isa_ok($order_user, 'DBIx::Class::Async::Row', 'Order->user returns Row');
    is($order_user->id, 1, 'Order belongs to correct user (Alice)');

    # 1. Capture the ResultSet object itself
    my $orders_rs1 = $user->orders;
    isa_ok($orders_rs1, 'DBIx::Class::Async::ResultSet');

    # 2. Get the data from it
    my $data1 = $orders_rs1->all->get;

    # 3. Call the accessor again - should return the SAME ResultSet object
    my $orders_rs2 = $user->orders;

    is($orders_rs1, $orders_rs2, 'The ResultSet object itself is cached in the Row');

    # 4. (Optional) Check that the data matches
    my $data2 = $orders_rs2->all->get;
    is_deeply($data1, $data2, 'The data retrieved via the cached ResultSet is identical');
};

# Test 5: Error handling
subtest 'Row errors' => sub {

    my $rs   = $schema->resultset('User');
    my $user = $rs->find(1)->get;

    # Invalid column access
    throws_ok {
        $user->get_column('nonexistent');
    } qr/No such column/, 'Invalid column throws error';

    # Invalid column via method
    throws_ok {
        $user->nonexistent_column
    } qr/Method .*nonexistent_column.* not found/, 'Invalid method throws error';

    # Invalid relationship
    throws_ok {
        $user->related_resultset('nonexistent');
    } qr/No such relationship/, 'Invalid relationship throws error';

    # Update without data
    throws_ok {
        $user->update();
    } qr/Usage/, 'Update without data dies';

    # Update deleted row
    my $temp_user = $rs->create({
        name   => 'Temp',
        email  => 'temp2@example.com',
        active => 1,
    })->get;

    $temp_user->delete->get;

    throws_ok {
        $temp_user->update({ name => 'Updated' });
    } qr/not in storage/, 'Update deleted row fails';

    # Delete already deleted row
    my $delete_again = $temp_user->delete;
    my $result = $delete_again->get;
    ok(!$result, 'Delete already deleted returns false');
};

# Test 6: Row inflation (if implemented)
subtest 'Row inflation' => sub {

    my $rs   = $schema->resultset('User');
    my $user = $rs->find(1)->get;

    # Test that we can access all columns
    ok(defined $user->id, 'ID is accessible');
    ok(defined $user->name, 'Name is accessible');
    ok(defined $user->active, 'Active is accessible');
};

$schema->disconnect;
teardown_test_db();

done_testing();
