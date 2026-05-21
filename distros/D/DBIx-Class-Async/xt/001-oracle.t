#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib "xt/lib";
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

my $DSN  = $ENV{DBIC_ASYNC_ORACLE_DSN}
    || 'dbi:Oracle:host=localhost;port=1521;service_name=FREEPDB1';
my $USER = $ENV{DBIC_ASYNC_ORACLE_USER} || 'dbictest';
my $PASS = $ENV{DBIC_ASYNC_ORACLE_PASS} || 'dbictest123';

{
    eval { require DBD::Oracle };
    if ($@) {
        plan skip_all => 'DBD::Oracle not installed';
    }
}

my $loop   = IO::Async::Loop->new;
my $schema = DBIx::Class::Async::Schema->connect(
    $DSN, $USER, $PASS, {},
    {
        workers      => 2,
        schema_class => 'TestSchema',
        async_loop   => $loop,
    },
);

$schema->await($schema->deploy({ add_drop_table => 1 }));

isa_ok($schema, 'DBIx::Class::Async::Schema', 'Schema connected to Oracle');

subtest 'Basic CRUD — User' => sub {
    my $user_rs = $schema->resultset('User');
    isa_ok($user_rs, 'DBIx::Class::Async::ResultSet');

    # Create
    my $user = $user_rs->create({
        name   => 'Oracle User',
        email  => 'oracle@example.com',
        active => 1,
    })->get;

    isa_ok($user,    'DBIx::Class::Async::Row', 'create() returns a Row');
    is($user->name,  'Oracle User',             'name is correct');
    is($user->email, 'oracle@example.com',      'email is correct');
    ok($user->id,                               'id was assigned by Oracle sequence');

    # Read
    my $found = $user_rs->find($user->id)->get;
    isa_ok($found, 'DBIx::Class::Async::Row', 'find() returns a Row');
    is($found->name, 'Oracle User', 'find() name matches');

    # Update
    my $updated = $found->update({ name => 'Updated Oracle User', active => 0 })->get;
    is($updated->name,   'Updated Oracle User', 'update() name correct');
    is($updated->active, 0,                     'update() active correct');

    # Delete
    $updated->delete->get;
    my $gone = $user_rs->find($updated->id)->get;
    ok(!defined $gone, 'Row is gone after delete()');
};

subtest 'Search and count' => sub {
    my $user_rs = $schema->resultset('User');
    my $before  = $user_rs->count->get;

    $user_rs->create({ name => 'Search One',   email => 's1@oracle.com', active => 1 })->get;
    $user_rs->create({ name => 'Search Two',   email => 's2@oracle.com', active => 0 })->get;
    $user_rs->create({ name => 'Search Three', email => 's3@oracle.com', active => 1 })->get;

    my $after = $user_rs->count->get;
    is($after, $before + 3, 'count() increased by 3 after creates');

    my $active = $user_rs->search({ active => 1 })->all->get;
    isa_ok($active, 'ARRAY', 'search()->all() returns arrayref');
    cmp_ok(scalar @$active, '>=', 2, 'At least 2 active users found');

    my $active_count = $user_rs->search({ active => 1 })->count->get;
    cmp_ok($active_count, '>=', 2, 'search()->count() works on Oracle');
};

subtest 'Relationships — belongs_to and has_many' => sub {
    my $user_rs  = $schema->resultset('User');
    my $order_rs = $schema->resultset('Order');

    my $user = $user_rs->create({
        name  => 'Rel User',
        email => 'rel@oracle.com',
    })->get;

    my $order = $order_rs->create({
        user_id => $user->id,
        amount  => 99.99,
        status  => 'paid',
    })->get;

    isa_ok($order, 'DBIx::Class::Async::Row', 'order created');
    is(sprintf('%.2f', $order->amount), '99.99', 'amount is correct');
    is($order->user_id, $user->id, 'FK user_id correct');

    # belongs_to
    my $order_user = $order->user->get;
    isa_ok($order_user, 'DBIx::Class::Async::Row', 'belongs_to returns Row');
    is($order_user->id, $user->id, 'belongs_to correct user');

    # has_many
    my $user_orders = $user->orders->all->get;
    is(scalar @$user_orders, 1,           'has_many returns 1 order');
    is($user_orders->[0]->id, $order->id, 'has_many correct order');
};

subtest 'Transactions — txn_do' => sub {
    my $user_rs = $schema->resultset('User');
    my $before  = $user_rs->count->get;

    # Successful transaction
    $schema->txn_do([
        { action => 'create', resultset => 'User',
          data   => { name => 'Txn User A', email => 'txna@oracle.com' } },
        { action => 'create', resultset => 'User',
          data   => { name => 'Txn User B', email => 'txnb@oracle.com' } },
    ])->get;

    my $after = $user_rs->count->get;
    is($after, $before + 2, 'txn_do committed both rows');
};

subtest 'Concurrent async queries' => sub {
    my $user_rs = $schema->resultset('User');

    # Fire two queries simultaneously and wait for both
    my $f_count = $user_rs->count;
    my $f_all   = $user_rs->search({ active => 1 })->all;

    my ($count, $active) = Future->needs_all($f_count, $f_all)->get;

    cmp_ok($count,  '>=', 1, 'Concurrent count() returned a result');
    isa_ok($active, 'ARRAY', 'Concurrent search()->all() returned arrayref');
};

$schema->disconnect;

done_testing;
