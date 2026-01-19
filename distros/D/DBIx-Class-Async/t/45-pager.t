#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use lib 'lib', 't/lib';

use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

# 1. Setup Database
my (undef, $db_file) = tempfile(UNLINK => 1);
my $dsn = "dbi:SQLite:dbname=$db_file";
my $schema = TestSchema->connect($dsn);
$schema->deploy();

# 2. Populate with 25 users
for my $i (1..25) {
    $schema->resultset('User')->create({
        name  => "User $i",
        email => "user$i\@test.com"
    });
}
$schema->storage->disconnect;

# 3. Setup Async Schema
my $loop = IO::Async::Loop->new;
my $async_schema = DBIx::Class::Async::Schema->connect(
    $dsn, undef, undef, {},
    { workers => 1, schema_class => 'TestSchema', loop => $loop }
);

subtest "ResultSet count vs count_total" => sub {
    my $rs = $async_schema->resultset('User')->page(1); # 10 rows per page

    # Verify count() respects the slice (your existing logic)
    my $page_count = $rs->count->get;
    is($page_count, 10, "count() returns the slice size (10)");

    # Verify count_total() ignores the slice
    my $total_count = $rs->count_total->get;
    is($total_count, 25, "count_total() returns the full table size (25)");
};

subtest "Full Pager Integration" => sub {
    # 1. Test the logic with an unordered RS
    my $rs = $async_schema->resultset('User')->page(3);
    my $pager = $rs->pager;

    is($pager->current_page, 3, "Pager on correct page");

    # 2. Verify total entries logic
    my $total_f = $pager->total_entries;
    is($total_f->get, 25, "Pager total_entries is correct");

    # 3. Verify pagination math
    is($pager->last_page, 3, "Last page is 3 (10+10+5)");
    is($pager->entries_on_this_page, 5, "Entries on page 3 is 5");
    ok($pager->previous_page, "Has a previous page");
    ok(!$pager->next_page, "No next page (this is the last page)");
};

subtest "Search with Pager (Parallel)" => sub {
    my $rs = $async_schema->resultset('User');

    # We want page 2 (rows 11-20)
    my $f = $rs->search_with_pager(undef, { page => 2, rows => 10 });

    # Wait for the combined result
    my ($rows, $pager) = $f->get;

    is(scalar @$rows, 10, "Fetched 10 rows for page 2");
    is($rows->[0]->name, "User 11", "First row is User 11");
    is($pager->total_entries->get, 25, "Pager still knows there are 25 total");
    is($pager->current_page, 2, "Pager correctly reports page 2");
};

subtest "Ordering Check" => sub {
    my $rs = $async_schema->resultset('User');
    ok( !$rs->is_ordered, "New resultset is not ordered" );

    my $ordered_rs = $rs->search(undef, { order_by => { -desc => 'created_at' } });
    ok( $ordered_rs->is_ordered, "Resultset with order_by returns true for is_ordered" );
};

done_testing;
