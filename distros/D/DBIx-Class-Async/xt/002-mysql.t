#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib "xt/lib";
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

my $DSN  = $ENV{DBIC_ASYNC_MYSQL_DSN}
    || 'dbi:mysql:database=testdb;host=localhost;port=3306';
my $USER = $ENV{DBIC_ASYNC_MYSQL_USER} || 'root';
my $PASS = $ENV{DBIC_ASYNC_MYSQL_PASS} || 'root';

{
    eval { require DBD::mysql };
    if ($@) {
        plan skip_all => 'DBD::mysql not installed';
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

isa_ok($schema, 'DBIx::Class::Async::Schema', 'Schema connected to MySQL');

$schema->await($schema->deploy({ add_drop_table => 1 }));

subtest 'Basic CRUD — User' => sub {
    my $user_rs = $schema->resultset('User');
    isa_ok($user_rs, 'DBIx::Class::Async::ResultSet');

    # Create
    my $user = $user_rs->create({
        name   => 'MySQL User',
        email  => 'mysql@example.com',
        active => 1,
    })->get;

    isa_ok($user, 'DBIx::Class::Async::Row', 'create() returns a Row');
    is($user->name,  'MySQL User',          'name is correct');
    is($user->email, 'mysql@example.com',   'email is correct');
    ok($user->id,                            'id was assigned by AUTO_INCREMENT');

    # Read
    my $found = $user_rs->find($user->id)->get;
    isa_ok($found, 'DBIx::Class::Async::Row', 'find() returns a Row');
    is($found->name, 'MySQL User', 'find() name matches');

    # Update
    my $updated = $found->update({ name => 'Updated MySQL User', active => 0 })->get;
    is($updated->name,   'Updated MySQL User', 'update() name correct');
    is($updated->active, 0,                     'update() active correct');

    # Delete
    $updated->delete->get;
    my $gone = $user_rs->find($updated->id)->get;
    ok(!defined $gone, 'Row is gone after delete()');
};

subtest 'Search and count' => sub {
    my $user_rs = $schema->resultset('User');
    my $before  = $user_rs->count->get;

    $user_rs->create({ name => 'Search One',   email => 's1@mysql.com', active => 1 })->get;
    $user_rs->create({ name => 'Search Two',   email => 's2@mysql.com', active => 0 })->get;
    $user_rs->create({ name => 'Search Three', email => 's3@mysql.com', active => 1 })->get;

    my $after = $user_rs->count->get;
    is($after, $before + 3, 'count() increased by 3');

    my $active = $user_rs->search({ active => 1 })->all->get;
    isa_ok($active, 'ARRAY', 'search()->all() returns arrayref');
    cmp_ok(scalar @$active, '>=', 2, 'At least 2 active users found');
};

subtest 'Relationships — belongs_to and has_many' => sub {
    my $user_rs  = $schema->resultset('User');
    my $order_rs = $schema->resultset('Order');

    my $user = $user_rs->create({
        name  => 'Rel User',
        email => 'rel@mysql.com',
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
    is($order_user->id, $user->id, 'belongs_to correct user');

    # has_many
    my $user_orders = $user->orders->all->get;
    is(scalar @$user_orders, 1, 'has_many returns 1 order');
};

subtest 'Transactions — txn_do' => sub {
    my $user_rs = $schema->resultset('User');
    my $before  = $user_rs->count->get;

    $schema->txn_do([
        { action => 'create', resultset => 'User',
          data   => { name => 'Txn User A', email => 'txna@mysql.com' } },
        { action => 'create', resultset => 'User',
          data   => { name => 'Txn User B', email => 'txnb@mysql.com' } },
    ])->get;

    my $after = $user_rs->count->get;
    is($after, $before + 2, 'txn_do committed both rows');
};

subtest 'Concurrent async queries' => sub {
    my $user_rs = $schema->resultset('User');
    my $f_count = $user_rs->count;
    my $f_all   = $user_rs->search({ active => 1 })->all;

    my ($count, $active) = Future->needs_all($f_count, $f_all)->get;

    cmp_ok($count,  '>=', 1, 'Concurrent count() successful');
    isa_ok($active, 'ARRAY', 'Concurrent search() successful');
};

$schema->disconnect;

done_testing;
