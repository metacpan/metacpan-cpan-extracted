#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use lib 'lib';
use DBIx::Class::Async::Schema;

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required for testing';
}

use TestSchema;
use DBIx::Class::Async;

# Setup test database
my $dbfile = 't/test_related_resultset.db';
unlink $dbfile if -e $dbfile;

# Step 1: Create and deploy schema using regular DBIx::Class
my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile", undef, undef, {});
ok($schema, 'Schema created');

eval { $schema->deploy };
if ($@) {
    diag("Schema deployment failed: $@");
    BAIL_OUT("Cannot deploy schema");
}

# Verify tables exist
{
    my $dbh = $schema->storage->dbh;
    my @tables = $dbh->tables(undef, undef, '%', 'TABLE');
    ok(scalar(@tables) >= 2, 'Tables created');
}

# Step 2: Create async schema wrapper
my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    {
        sqlite_unicode => 1,
    },
    {
        workers      => 2,
        schema_class => 'TestSchema',
    }
);
ok($async_schema, 'Async schema created');
isa_ok($async_schema, 'DBIx::Class::Async::Schema', 'Correct schema type');

# Step 3: Populate test data using regular schema
my ($alice, $bob, $charlie, $order1, $order2, $order3, $order4);

eval {
    # Create users
    $alice = $schema->resultset('User')->create({
        name   => 'Alice',
        email  => 'alice@example.com',
        active => 1,
    });

    $bob = $schema->resultset('User')->create({
        name   => 'Bob',
        email  => 'bob@example.com',
        active => 1,
    });

    $charlie = $schema->resultset('User')->create({
        name   => 'Charlie',
        email  => 'charlie@example.com',
        active => 0,
    });

    # Create orders for Alice
    $order1 = $schema->resultset('Order')->create({
        user_id => $alice->id,
        amount  => 100.50,
        status  => 'completed',
    });

    $order2 = $schema->resultset('Order')->create({
        user_id => $alice->id,
        amount  => 250.75,
        status  => 'pending',
    });

    # Create orders for Bob
    $order3 = $schema->resultset('Order')->create({
        user_id => $bob->id,
        amount  => 50.25,
        status  => 'completed',
    });

    $order4 = $schema->resultset('Order')->create({
        user_id => $bob->id,
        amount  => 75.00,
        status  => 'pending',
    });
};

if ($@) {
    diag("Test data creation failed: $@");
    BAIL_OUT("Cannot create test data");
}

# Verify data was inserted
my $user_count = $schema->resultset('User')->count;
my $order_count = $schema->resultset('Order')->count;
is($user_count, 3, 'Created 3 users');
is($order_count, 4, 'Created 4 orders');

subtest 'related_resultset - basic functionality' => sub {
    plan tests => 3;

    # Test that the method exists
    my $rs = $async_schema->resultset('Order');
    can_ok($rs, 'related_resultset');

    # Test creating a related resultset
    my $related_rs = eval { $rs->related_resultset('user') };
    if ($@) {
        diag("Error creating related_resultset: $@");
        fail("related_resultset creation failed");
        fail("placeholder");
    } else {
        isa_ok($related_rs, 'DBIx::Class::Async::ResultSet',
            'related_resultset returns a ResultSet');
        is($related_rs->source_name, 'User',
            'Related ResultSet has correct source name');
    }
};

subtest 'related_resultset - Order to User (belongs_to)' => sub {
    plan tests => 6;

    # Get orders with pending status
    my $pending_orders_rs = $async_schema->resultset('Order')
        ->search({ status => 'pending' });

    # Get related users
    my $users_rs = eval { $pending_orders_rs->related_resultset('user') };

    if ($@) {
        diag("Error in related_resultset: $@");
        BAIL_OUT("Cannot continue without working related_resultset");
    }

    isa_ok($users_rs, 'DBIx::Class::Async::ResultSet');
    is($users_rs->source_name, 'User', 'Correct source name');

    # Try to fetch the users
    my $users = eval { $users_rs->all->get };

    if ($@) {
        diag("Error fetching users: $@");
        use Data::Dumper;
        diag("SQL attrs: " . Dumper($users_rs->{_attrs}));
        diag("SQL cond: " . Dumper($users_rs->{_cond}));
        fail("Could not fetch users");
        fail("placeholder 1");
        fail("placeholder 2");
        fail("placeholder 3");
    } else {
        isa_ok($users, 'ARRAY', 'Got arrayref');
        ok(scalar @$users > 0, 'Found at least one user with pending orders');

        # Check that we got actual user objects
        my $user = $users->[0];
        isa_ok($user, 'DBIx::Class::Async::Row', 'Got Row object');
        ok($user->name, 'User has name: ' . $user->name);
    }
};

subtest 'related_resultset - User to Orders (has_many)' => sub {
    plan tests => 6;

    # Get active users
    my $active_users_rs = $async_schema->resultset('User')
        ->search({ active => 1 });

    # Get their orders
    my $orders_rs = eval { $active_users_rs->related_resultset('orders') };

    if ($@) {
        diag("Error in related_resultset: $@");
        BAIL_OUT("Cannot continue without working related_resultset");
    }

    isa_ok($orders_rs, 'DBIx::Class::Async::ResultSet');
    is($orders_rs->source_name, 'Order', 'Correct source name');

    # Try to fetch the orders
    my $orders = eval { $orders_rs->all->get };

    if ($@) {
        diag("Error fetching orders: $@");
        use Data::Dumper;
        diag("SQL attrs: " . Dumper($orders_rs->{_attrs}));
        diag("SQL cond: " . Dumper($orders_rs->{_cond}));
        fail("Could not fetch orders");
        fail("placeholder 1");
        fail("placeholder 2");
        fail("placeholder 3");
    } else {
        isa_ok($orders, 'ARRAY', 'Got arrayref');
        ok(scalar @$orders > 0, 'Found at least one order for active users');

        # Check that we got actual order objects
        my $order = $orders->[0];
        isa_ok($order, 'DBIx::Class::Async::Row', 'Got Row object');
        ok($order->status, 'Order has status: ' . $order->status);
    }
};

subtest 'related_resultset - chaining searches' => sub {
    plan tests => 4;

    # Chain: pending orders -> users -> active only
    my $rs = eval {
        $async_schema->resultset('Order')
            ->search({ status => 'pending' })
            ->related_resultset('user')
            ->search({ active => 1 })
    };

    if ($@) {
        diag("Error creating chain: $@");
        fail("Chain creation failed");
        fail("placeholder 1");
        fail("placeholder 2");
        fail("placeholder 3");
        return;
    }

    isa_ok($rs, 'DBIx::Class::Async::ResultSet', 'Chain returns ResultSet');

    my $results = eval { $rs->all->get };

    if ($@) {
        diag("Error executing chain: $@");
        fail("Chain execution failed");
        fail("placeholder 1");
        fail("placeholder 2");
    } else {
        isa_ok($results, 'ARRAY', 'Got results');

        # Verify all are active
        my $all_active = 1;
        foreach my $user (@$results) {
            $all_active = 0 unless $user->active;
        }

        ok($all_active || scalar(@$results) == 0,
            'All results match criteria (or empty)');

        pass('Chain completed successfully');
    }
};

subtest 'related_resultset - error handling' => sub {
    plan tests => 2;

    my $rs = $async_schema->resultset('User');

    # Test invalid relationship name
    eval {
        $rs->related_resultset('nonexistent_relation');
    };
    like($@, qr/No such relationship/, 'Dies on invalid relationship');

    # Test missing relationship name
    eval {
        $rs->related_resultset();
    };
    like($@, qr/required/, 'Dies when relationship name missing');
};

# Cleanup
END {
    unlink $dbfile if -e $dbfile;
}

done_testing();
