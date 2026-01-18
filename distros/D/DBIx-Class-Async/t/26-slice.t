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
my $dbfile = 't/test_slice.db';
unlink $dbfile if -e $dbfile;

# Create and deploy schema
my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile", undef, undef, {});
$schema->deploy;

# Create async schema
my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

# Populate test data - create 20 users
for my $i (1..20) {
    $schema->resultset('User')->create({
        name   => "User$i",
        email  => "user$i\@example.com",
        active => ($i % 2 == 0) ? 1 : 0,  # Even IDs are active
    });
}

# Verify data
is($schema->resultset('User')->count, 20, 'Created 20 users');

subtest 'slice - basic functionality in list context' => sub {
    plan tests => 8;

    my $rs = $async_schema->resultset('User')
        ->search({}, { order_by => 'id' });

    # Test: Get first 3 records (0, 1, 2)
    my @first_three = $rs->slice(0, 2);
    is(scalar @first_three, 3, 'Got 3 records');
    is($first_three[0]->name, 'User1', 'First record correct');
    is($first_three[1]->name, 'User2', 'Second record correct');
    is($first_three[2]->name, 'User3', 'Third record correct');

    # Test: Get middle records (5, 6, 7)
    my @middle = $rs->slice(5, 7);
    is(scalar @middle, 3, 'Got 3 middle records');
    is($middle[0]->name, 'User6', 'First middle record correct');
    is($middle[2]->name, 'User8', 'Last middle record correct');

    # Test: Get single record (slice of 1)
    my @single = $rs->slice(10, 10);
    is(scalar @single, 1, 'Got 1 record');
};

subtest 'slice - scalar context returns ResultSet' => sub {
    plan tests => 6;

    my $rs = $async_schema->resultset('User')
        ->search({}, { order_by => 'id' });

    # Get a sliced ResultSet
    my $sliced_rs = $rs->slice(0, 4);

    isa_ok($sliced_rs, 'DBIx::Class::Async::ResultSet',
        'Scalar context returns ResultSet');

    # Verify the ResultSet has correct attributes
    my $attrs = $sliced_rs->_resolved_attrs;
    is($attrs->{offset}, 0, 'Offset is correct');
    is($attrs->{rows}, 5, 'Rows is correct (5 records: 0-4)');

    # Fetch and verify
    my $results = $sliced_rs->all->get;
    is(scalar @$results, 5, 'ResultSet returns 5 records');
    is($results->[0]->name, 'User1', 'First record correct');
    is($results->[4]->name, 'User5', 'Last record correct');
};

subtest 'slice - chaining with other operations' => sub {
    plan tests => 5;

    my $rs = $async_schema->resultset('User')
        ->search({}, { order_by => 'id' });

    # Chain slice with count
    my $count = $rs->slice(5, 14)->count->get;
    is($count, 10, 'Count on sliced ResultSet works');

    # Chain search with slice
    my @active_slice = $rs->search({ active => 1 })
        ->slice(0, 2);
    is(scalar @active_slice, 3, 'Got 3 active users');

    # All should be active
    my $all_active = 1;
    foreach my $user (@active_slice) {
        $all_active = 0 unless $user->active;
    }
    ok($all_active, 'All sliced users are active');

    # Slice then search (scalar context)
    my $sliced_then_filtered = $rs->slice(0, 9)
        ->search({ active => 1 });

    isa_ok($sliced_then_filtered, 'DBIx::Class::Async::ResultSet',
        'Can chain search after slice');

    my $filtered_results = $sliced_then_filtered->all->get;
    cmp_ok(scalar @$filtered_results, '<=', 10,
        'Filtered slice has at most 10 records');
};

subtest 'slice - edge cases' => sub {
    plan tests => 6;

    my $rs = $async_schema->resultset('User')
        ->search({}, { order_by => 'id' });

    # Test: Last records
    my @last_two = $rs->slice(18, 19);
    is(scalar @last_two, 2, 'Got last 2 records');
    is($last_two[0]->name, 'User19', 'Second to last record');
    is($last_two[1]->name, 'User20', 'Last record');

    # Test: Slice beyond available records
    my @beyond = $rs->slice(15, 25);
    cmp_ok(scalar @beyond, '<=', 5, 'Slice beyond end returns available records');

    # Test: Single element slice
    my @one = $rs->slice(0, 0);
    is(scalar @one, 1, 'Single element slice works');
    is($one[0]->name, 'User1', 'Single element is correct');
};

subtest 'slice - with ordering' => sub {
    plan tests => 4;

    # Order by name descending
    my $rs = $async_schema->resultset('User')
        ->search({}, { order_by => { -desc => 'name' } });

    my @first_three = $rs->slice(0, 2);
    is(scalar @first_three, 3, 'Got 3 records with ordering');

    # With descending order, User9 comes before User8, User7, etc.
    # (User9, User8, User7, ... User20, User2, User19, ...)
    ok($first_three[0]->name, 'First record exists');

    # Test with offset
    my @offset_slice = $rs->slice(5, 7);
    is(scalar @offset_slice, 3, 'Slice with offset works');

    # Verify all are Row objects
    my $all_rows = 1;
    foreach my $user (@offset_slice) {
        $all_rows = 0 unless $user->isa('DBIx::Class::Async::Row');
    }
    ok($all_rows, 'All sliced records are Row objects');
};

subtest 'slice - error handling' => sub {
    plan tests => 4;

    my $rs = $async_schema->resultset('User');

    # Test: Missing arguments
    eval { $rs->slice(0) };
    like($@, qr/requires two arguments/, 'Dies without both arguments');

    # Test: Negative indices
    eval { $rs->slice(-1, 5) };
    like($@, qr/non-negative/, 'Dies with negative first index');

    eval { $rs->slice(0, -1) };
    like($@, qr/non-negative/, 'Dies with negative last index');

    # Test: First > Last
    eval { $rs->slice(5, 2) };
    like($@, qr/less than or equal/, 'Dies when first > last');
};

subtest 'slice - comparison with rows/offset' => sub {
    plan tests => 3;

    my $rs = $async_schema->resultset('User')
        ->search({}, { order_by => 'id' });

    # Using slice
    my @slice_results = $rs->slice(5, 9);

    # Using rows/offset directly
    my $manual_rs = $rs->search(undef, { offset => 5, rows => 5 });
    my @manual_results = @{ $manual_rs->all->get };  # Dereference the arrayref

    is(scalar @slice_results, scalar @manual_results,
        'slice and manual offset/rows return same count');

    is($slice_results[0]->name, $manual_results[0]->name,
        'First record matches');

    is($slice_results[4]->name, $manual_results[4]->name,
        'Last record matches');
};

subtest 'slice - pagination use case' => sub {
    plan tests => 4;

    my $rs = $async_schema->resultset('User')
        ->search({}, { order_by => 'id' });

    my $page_size = 5;

    # Page 1 (records 0-4)
    my @page1 = $rs->slice(0, $page_size - 1);
    is(scalar @page1, 5, 'Page 1 has 5 records');
    is($page1[0]->name, 'User1', 'Page 1 starts correctly');

    # Page 2 (records 5-9)
    my @page2 = $rs->slice($page_size, ($page_size * 2) - 1);
    is(scalar @page2, 5, 'Page 2 has 5 records');
    is($page2[0]->name, 'User6', 'Page 2 starts correctly');
};

# Cleanup
END {
    unlink $dbfile if -e $dbfile;
}

done_testing();
