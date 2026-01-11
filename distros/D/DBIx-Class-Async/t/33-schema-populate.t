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

my $dbfile = 't/test_populate.db';
unlink $dbfile if -e $dbfile;

my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile");
$schema->deploy;

my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

sub reset_data {
    $schema->resultset('Order')->delete;
    $schema->resultset('User')->delete;
}

subtest 'populate - hashref format via schema' => sub {

    reset_data();

    my $users = $async_schema->populate('User', [
        { name => 'Alice', email => 'alice@example.com', active => 1 },
        { name => 'Bob',   email => 'bob@example.com',   active => 1 },
        { name => 'Carol', email => 'carol@example.com', active => 0 },
    ])->get;

    isa_ok($users, 'ARRAY', 'Returns arrayref');
    is(scalar @$users, 3, 'Created 3 users');

    isa_ok($users->[0], 'DBIx::Class::Async::Row', 'First element is Row object');
    is($users->[0]->name, 'Alice', 'First user is Alice');
    is($users->[1]->name, 'Bob', 'Second user is Bob');
    is($users->[2]->name, 'Carol', 'Third user is Carol');
};

subtest 'populate - column list format via schema' => sub {

    reset_data();

    my $users = $async_schema->populate('User', [
        [qw/ name email active /],
        ['Alice', 'alice@example.com', 1],
        ['Bob',   'bob@example.com',   1],
        ['Carol', 'carol@example.com', 0],
    ])->get;

    isa_ok($users, 'ARRAY', 'Returns arrayref');
    is(scalar @$users, 3, 'Created 3 users');

    isa_ok($users->[0], 'DBIx::Class::Async::Row', 'First element is Row object');
    is($users->[0]->name, 'Alice', 'First user is Alice');
    is($users->[1]->name, 'Bob', 'Second user is Bob');
    is($users->[2]->name, 'Carol', 'Third user is Carol');
};

subtest 'populate - hashref format via resultset' => sub {

    reset_data();

    my $rs = $async_schema->resultset('User');
    my $users = $rs->populate([
        { name => 'Dave',  email => 'dave@example.com',  active => 1 },
        { name => 'Eve',   email => 'eve@example.com',   active => 1 },
    ])->get;

    is(scalar @$users, 2, 'Created 2 users');
    is($users->[0]->name, 'Dave', 'First user is Dave');
    is($users->[1]->name, 'Eve', 'Second user is Eve');

    # Verify in database
    my $count = $schema->resultset('User')->count;
    is($count, 2, 'Database has 2 users');

    my $dave = $schema->resultset('User')->find({ name => 'Dave' });
    is($dave->email, 'dave@example.com', 'Dave has correct email');
};

subtest 'populate - column list format via resultset' => sub {

    reset_data();

    my $rs = $async_schema->resultset('User');
    my $users = $rs->populate([
        [qw/ name email active /],
        ['Frank', 'frank@example.com', 1],
        ['Grace', 'grace@example.com', 0],
    ])->get;

    is(scalar @$users, 2, 'Created 2 users');
    is($users->[0]->name, 'Frank', 'First user is Frank');

    # Verify active status
    ok($users->[0]->active, 'Frank is active');
    ok(!$users->[1]->active, 'Grace is not active');
};

subtest 'populate - single record' => sub {

    reset_data();

    my $users = $async_schema->populate('User', [
        { name => 'Solo', email => 'solo@example.com', active => 1 },
    ])->get;

    is(scalar @$users, 1, 'Created 1 user');
    is($users->[0]->name, 'Solo', 'User is Solo');

    my $count = $schema->resultset('User')->count;
    is($count, 1, 'Database has 1 user');
};

subtest 'populate - many records' => sub {

    reset_data();

    my @data;
    for my $i (1..50) {
        push @data, {
            name   => "User$i",
            email  => "user$i\@example.com",
            active => ($i % 2),
        };
    }

    my $users = $async_schema->populate('User', \@data)->get;

    is(scalar @$users, 50, 'Created 50 users');

    my $count = $schema->resultset('User')->count;
    is($count, 50, 'Database has 50 users');

    my $active_count = $schema->resultset('User')->search({ active => 1 })->count;
    is($active_count, 25, '25 users are active');
};

subtest 'populate - with relationships' => sub {

    reset_data();

    # Create users first
    my $users = $async_schema->populate('User', [
        { name => 'Alice', email => 'alice@example.com', active => 1 },
        { name => 'Bob',   email => 'bob@example.com',   active => 1 },
    ])->get;

    my $alice_id = $users->[0]->id;
    my $bob_id = $users->[1]->id;

    my $orders = $async_schema->populate('Order', [
        { user_id => $alice_id, amount => 100.00, status => 'completed' },
        { user_id => $alice_id, amount => 50.00,  status => 'pending' },
        { user_id => $bob_id,   amount => 75.00,  status => 'completed' },
    ])->get;

    is(scalar @$orders, 3, 'Created 3 orders');
    is($orders->[0]->user_id, $alice_id, 'First order belongs to Alice');
    is($orders->[1]->user_id, $alice_id, 'Second order belongs to Alice');
    is($orders->[2]->user_id, $bob_id, 'Third order belongs to Bob');

    my $alice = $schema->resultset('User')->find($alice_id);
    my $alice_orders = $alice->orders->count;
    is($alice_orders, 2, 'Alice has 2 orders');
};

subtest 'populate - returns Future' => sub {

    reset_data();

    my $future = $async_schema->populate('User', [
        { name => 'Future', email => 'future@example.com', active => 1 },
    ]);

    isa_ok($future, 'Future', 'Returns Future object');
    ok(!$future->is_ready, 'Future is not ready immediately');

    my $users = $future->get;
    is(scalar @$users, 1, 'Future resolves to correct result');
};

subtest 'populate - with default values' => sub {

    reset_data();

    # Don't specify 'active', it should use default value of 1
    my $users = $async_schema->populate('User', [
        { name => 'Default1', email => 'default1@example.com' },
        { name => 'Default2', email => 'default2@example.com' },
    ])->get;

    is(scalar @$users, 2, 'Created 2 users');
    ok($users->[0]->active, 'First user has default active=1');
    ok($users->[1]->active, 'Second user has default active=1');
};

subtest 'populate - error: empty data' => sub {

    eval {
        $async_schema->populate('User', [])->get;
    };
    like($@, qr/cannot be empty/i, 'Dies with empty array');
};

subtest 'populate - error: not an arrayref' => sub {

    eval {
        $async_schema->populate('User', { name => 'Test' })->get;
    };
    like($@, qr/must be an arrayref/i, 'Dies when not an arrayref');
};

subtest 'populate - error: missing source name' => sub {

    eval {
        $async_schema->populate(undef, [{ name => 'Test' }])->get;
    };
    like($@, qr/required/i, 'Dies without source name');
};

subtest 'populate - error: column count mismatch' => sub {

    reset_data();

    eval {
        $async_schema->populate('User', [
            [qw/ name email /],
            ['Alice', 'alice@example.com', 1],  # Too many values
        ])->get;
    };
    like($@, qr/different number/i, 'Dies when values count differs from columns');
};

subtest 'populate - mixed with manual creates' => sub {

    reset_data();

    # Manual create
    $async_schema->resultset('User')
        ->create({ name => 'Manual', email => 'manual@example.com', active => 1 })
        ->get;

    # Populate
    $async_schema->populate('User', [
        { name => 'Pop1', email => 'pop1@example.com', active => 1 },
        { name => 'Pop2', email => 'pop2@example.com', active => 1 },
    ])->get;

    my $total = $schema->resultset('User')->count;
    is($total, 3, 'Total of 3 users (1 manual + 2 populate)');

    my $manual = $schema->resultset('User')->find({ name => 'Manual' });
    ok($manual, 'Manual user exists');

    my $pop1 = $schema->resultset('User')->find({ name => 'Pop1' });
    ok($pop1, 'Populated user exists');
};

subtest 'populate - verify all records inserted' => sub {

    reset_data();

    my $users = $async_schema->populate('User', [
        { name => 'Test1', email => 'test1@example.com', active => 1 },
        { name => 'Test2', email => 'test2@example.com', active => 0 },
        { name => 'Test3', email => 'test3@example.com', active => 1 },
    ])->get;

    is(scalar @$users, 3, 'Returned 3 objects');

    is($schema->resultset('User')->count, 3, 'Database has 3 records');

    ok($schema->resultset('User')->find({ name => 'Test1' }), 'Test1 exists');
    ok($schema->resultset('User')->find({ name => 'Test2' }), 'Test2 exists');
};

subtest 'populate - objects have IDs' => sub {

    reset_data();

    my $users = $async_schema->populate('User', [
        { name => 'HasID1', email => 'hasid1@example.com', active => 1 },
        { name => 'HasID2', email => 'hasid2@example.com', active => 1 },
    ])->get;

    ok($users->[0]->id, 'First user has ID');
    ok($users->[1]->id, 'Second user has ID');
    isnt($users->[0]->id, $users->[1]->id, 'IDs are different');
    ok($users->[0]->in_storage, 'First user is in storage');
};

subtest 'populate - column list with null values' => sub {

    reset_data();

    my $users = $async_schema->populate('User', [
        [qw/ name email active /],
        ['WithEmail', 'with@example.com', 1],
        ['NoEmail', undef, 0],  # NULL email
    ])->get;

    is(scalar @$users, 2, 'Created 2 users');
    is($users->[0]->email, 'with@example.com', 'First has email');
    ok(!defined $users->[1]->email, 'Second has NULL email');
};

subtest 'populate - comparison with multiple creates' => sub {

    reset_data();

    my $start = time;
    my $users = $async_schema->populate('User', [
        map { { name => "Bulk$_", email => "bulk$_\@example.com", active => 1 } } 1..10
    ])->get;
    my $populate_time = time - $start;

    is(scalar @$users, 10, 'Populate created 10 users');

    reset_data();

    # Using individual creates
    $start = time;
    my @individual;
    for my $i (1..10) {
        my $user = $async_schema->resultset('User')
            ->create({ name => "Individual$i", email => "individual$i\@example.com", active => 1 })
            ->get;
        push @individual, $user;
    }
    my $individual_time = time - $start;

    is(scalar @individual, 10, 'Individual creates made 10 users');

    # Note: populate should generally be faster, but we don't test timing
    # as it can vary based on system load
};

END {
    unlink $dbfile if -e $dbfile;
}

done_testing();
