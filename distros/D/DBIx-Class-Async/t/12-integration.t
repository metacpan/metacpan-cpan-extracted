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

# Test 1: Full workflow
subtest 'Complete workflow' => sub {

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 2, schema_class => $schema_class, loop => $loop }
    );

    # 1. Search with pagination - returns hashrefs, not Row objects
    my $users_rs = $schema->resultset('User')
                          ->search({ active   => 1 },
                                   { order_by => 'name', rows => 2 });

    my $users      = $users_rs->all_future->get;
    my @user_names = map { $_->{name} } @$users;

    is_deeply(\@user_names, ['Alice', 'Bob'], 'Pagination works');

    # 2. Create new user - returns Row object
    my $new_user = $schema->resultset('User')->create({
        name   => 'Integration Test',
        email  => 'integration@example.com',
        active => 1,
    })->get;

    ok($new_user->id, 'Created new user');

    # 3. Create order for user
    my $new_order = $schema->resultset('Order')->create({
        user_id => $new_user->id,
        amount  => 99.99,
        status  => 'pending',
    })->get;

    ok($new_order->id, 'Created new order');

    # 4. Fetch with relationships
    my $fetched_user = $schema->resultset('User')->find($new_user->id)->get;
    my $orders = $fetched_user->orders->all->get;

    cmp_ok(scalar @$orders, '>=', 1, 'User has orders');
    is($orders->[0]->user_id, $new_user->id, 'Order belongs to user');

    # 5. Update via row object
    $orders->[0]->update({ status => 'completed' })->get;

    # Reload to verify
    my $reloaded_order = $schema->resultset('Order')->find($orders->[0]->id)->get;
    is($reloaded_order->status, 'completed', 'Order update worked');

    # 6. Delete order first (to avoid foreign key constraint)
    my $order_id = $orders->[0]->id;
    $orders->[0]->delete->get;

    my $re_check = $schema->resultset('Order')->search(
        { id => $order_id },
        { result_class => 'DBIx::Class::ResultClass::HashRefInflator' }
    )->single_future;
    my $deleted_order = $re_check->get;
    ok(!$deleted_order, 'Order was deleted');

    # 7. Now delete user
    my $user_id = $new_user->id;
    $new_user->delete->get;

    my $deleted_user = $schema->resultset('User')->find($user_id)->get;
    ok(!$deleted_user, 'User was deleted');

    # 8. Bulk update
    my $bulk_update = $schema->resultset('User')
        ->search({ active => 1 })
        ->update({ active => 0 })
        ->get;

    cmp_ok($bulk_update, '>=', 0, 'Bulk update completed');

    # 9. Count after bulk update
    my $inactive_count = $schema->resultset('User')
        ->search({ active => 0 })
        ->count_future
        ->get;

    cmp_ok($inactive_count, '>=', 1, 'Count works after update');

    # 10. Reset
    $schema->resultset('User')
        ->search({ active => 0 })
        ->update({ active => 1 })
        ->get;

    # 11. Disconnect
    lives_ok { $schema->disconnect } 'Disconnect works';
};

# Test 2: Async behavior
subtest 'Async behavior' => sub {

    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 2, schema_class => $schema_class, loop => $loop }
    );

    my @futures;

    push @futures, $schema->resultset('User')->count_future;
    push @futures, $schema->resultset('User')->search({ active => 1 })->count_future;
    push @futures, $schema->resultset('User')->search({ active => 0 })->count_future;
    push @futures, $schema->resultset('Order')->count_future;

    # Wait for all
    my $wait_future = Future->wait_all(@futures);
    $wait_future->get;

    # Check all completed
    my $all_done = 1;
    foreach my $f (@futures) {
        $all_done &&= $f->is_ready;
    }

    ok($all_done, 'All concurrent futures completed');

    # Verify results
    my $user_count = $futures[0]->get;
    my $active_count = $futures[1]->get;
    my $inactive_count = $futures[2]->get;
    my $order_count = $futures[3]->get;

    cmp_ok($user_count, '>', 0, 'User count valid');
    cmp_ok($active_count + $inactive_count, '<=', $user_count, 'Counts consistent');
    cmp_ok($order_count, '>=', 0, 'Order count valid');

    pass('All async operations completed');

    $schema->disconnect;
};

teardown_test_db();

done_testing();
