#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib';

use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

my $loop = IO::Async::Loop->new;

# 1. Setup the Database File
my $db_file = "test.db";
unlink $db_file if -e $db_file; # Start fresh

my $async_db = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file",
    undef, undef, { sqlite_unicode => 1 },
    {
        workers      => 2,
        schema_class => 'TestSchema',
        loop         => $loop
    }
);

# 2. Deploy the Schema (Sync)
my $manager = $async_db->{async_db};
my $schema_class = $manager->{schema_class};
my $connect_info = $manager->{connect_info};

# Manually create a sync schema instance for deployment/population
my $sync_schema = $schema_class->connect(@$connect_info);

if (!$sync_schema) {
    die "Could not instantiate $schema_class for sync setup";
}

$sync_schema->deploy({ add_drop_table => 1 });

# 3. Populate Data (Sync)
# Creating 2 users and 4 orders so the prefetch has data to find
my $u1 = $sync_schema->resultset('User')->create({ name => 'Bob', email => 'bob@test.com' });
my $u2 = $sync_schema->resultset('User')->create({ name => 'Alice', email => 'alice@test.com' });

$sync_schema->resultset('Order')->create({ user_id => $u1->id, amount => 10, status => 'new' });
$sync_schema->resultset('Order')->create({ user_id => $u1->id, amount => 20, status => 'new' });
$sync_schema->resultset('Order')->create({ user_id => $u2->id, amount => 30, status => 'completed' });
$sync_schema->resultset('Order')->create({ user_id => $u2->id, amount => 40, status => 'completed' });

# --- Begin Async Tests ---

my $user_rs = $async_db->resultset('User');
ok($user_rs, 'User resultset exists');

my $order_rs = $async_db->resultset('Order');
ok($order_rs, 'Order resultset exists');

# 4. Test Prefetch
my $rs = $async_db->resultset('Order')->search(
    {},
    { prefetch => 'user' }
);

# Get the Future and resolve it
my $orders = $rs->all->get;

is(scalar @$orders, 4, 'Got 4 orders');

# 5. Access prefetched relationship
my $order = $orders->[0];
my $user_future = $order->user;

isa_ok($user_future, 'Future', 'user() returns a Future');

# This get should be instantaneous because data was prefetched
my $user = $user_future->get;
isa_ok($user, 'DBIx::Class::Async::Row', 'Got user Row object');
ok($user->name, 'User has a name: ' . $user->name);

# 6. Verify multiple orders' users
my @user_names;
foreach my $ord (@$orders) {
    # Each of these .get calls should resolve immediately without a new SQL query
    my $u = $ord->user->get;
    push @user_names, $u->name;
}

is(scalar @user_names, 4, 'Got all 4 user names from prefetched data');
cmp_deeply(\@user_names, [qw/Bob Bob Alice Alice/], 'User names match expected order');

done_testing();

# Cleanup
unlink $db_file;
