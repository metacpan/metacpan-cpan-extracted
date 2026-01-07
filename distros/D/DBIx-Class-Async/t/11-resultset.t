#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use Test::Deep;
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
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => $schema_class, loop => $loop }
);

# Test 1: ResultSet creation and basics
subtest 'ResultSet basics' => sub {

    my $rs = $schema->resultset('User');
    isa_ok($rs, 'DBIx::Class::Async::ResultSet', 'ResultSet object');

    is($rs->source_name, 'User', 'Correct source name');

    my $source = $rs->result_source;
    isa_ok($source, 'DBIx::Class::ResultSource::Table', 'Result source');
    is($source->source_name, 'User', 'Source name matches');

    # Test as_query
    my ($cond, $attrs) = $rs->as_query;
    is_deeply($cond, {}, 'Empty conditions by default');
    is_deeply($attrs, {}, 'Empty attributes by default');

    # Test search returns new resultset
    my $rs2 = $rs->search({ active => 1 });
    isa_ok($rs2, 'DBIx::Class::Async::ResultSet', 'Search returns ResultSet');
    isnt($rs, $rs2, 'Search returns new instance');
};

# Test 2: Search operations
subtest 'Search operations' => sub {

    my $rs = $schema->resultset('User');

    # Test async search - search() builds query, all_future() executes
    my $search_rs = $rs->search({ active => 1 });
    my $future    = $search_rs->all_future;
    isa_ok($future, 'Future', 'all_future() returns Future');

    my $results = $future->get;
    isa_ok($results, 'ARRAY', 'Future resolves to array of rows');

    # Count active users using async
    my $count_rs     = $schema->resultset('User')->search({ active => 1 });
    my $count_future = $count_rs->count_future;
    isa_ok($count_future, 'Future', 'count_future() returns Future');

    my $active_count = $count_future->get;
    cmp_ok($active_count, '==', 3, 'Found 3 active users');

    # Search with attributes
    my $ordered_rs = $rs->search(
        { active   => 1 },
        { order_by => 'name DESC', rows => 2 }
    );

    my $ordered_future  = $ordered_rs->all_future;
    my $ordered_results = $ordered_future->get;

    cmp_ok(scalar @$ordered_results, '==', 2, 'Limited to 2 rows');

    # Get names from results
    my @names = map { $_->{name} } @$ordered_results;
    is_deeply(\@names, ['Diana', 'Bob'], 'Correct order and limit')
        or diag("Got names: @names");

    # Empty search
    my $empty_rs      = $rs->search({ active => 999 });
    my $empty_future  = $empty_rs->all_future;
    my $empty_results = $empty_future->get;
    is(scalar @$empty_results, 0, 'No results for impossible condition');
};

# Test 3: Find operations
subtest 'Find operations' => sub {

    my $rs = $schema->resultset('User');

    # Find existing using single_future (for single row)
    my $user_future = $rs->find(1);
    isa_ok($user_future, 'Future', 'find() returns Future');

    my $user = $user_future->get;
    isa_ok($user, 'DBIx::Class::Async::Row', 'Found User row');
    is($user->id, 1, 'Correct user ID');
    is($user->name, 'Alice', 'Correct user name');

    # Find non-existing
    my $not_found_future = $rs->find(999);
    my $not_found        = $not_found_future->get;
    ok(!defined $not_found, 'find() returns undef for non-existing');

    # Find with string ID
    my $string_user = $rs->find('2')->get;
    ok($string_user && $string_user->id == 2, 'find() works with string ID');

    # Test single_future method directly
    my $single_user = $rs->search({ id => 1 })->single_future->get;
    is($single_user->name, 'Alice', 'single_future() works');
};

# Test 4: Create operations
subtest 'Create operations' => sub {

    my $rs = $schema->resultset('User');
    my $new_user = {
        name   => 'Eve',
        email  => 'eve@example.com',
        active => 1,
    };

    my $create_future = $rs->create($new_user);
    isa_ok($create_future, 'Future', 'create() returns Future');

    my $user = $create_future->get;
    isa_ok($user, 'DBIx::Class::Async::Row', 'create() returns Row object');
    is($user->name, 'Eve', 'Created user has correct name');

    # Verify persistence
    my $found = $rs->find($user->id)->get; # You can do it in one line if you like
    ok($found, 'Found the user in the database');
    is($found->email, 'eve@example.com', 'User email matches in database');
};

# Test 5: Sync iteration (if you added next() method)
subtest 'Sync iteration with next()' => sub {

    my $rs = $schema->resultset('User');
    if (!$rs->can('next')) {
        plan skip_all => 'next() method not implemented';
    }

    my $search_rs = $rs->search({ active => 1 });

    # Get all results sync
    my $future        = $search_rs->all_future;
    my $async_results = $future->get;
    my $async_count   = scalar @$async_results;

    # Iterate with next()
    $search_rs->reset;  # Start from beginning
    my $sync_count = 0;
    while (my $row = $search_rs->next) {
        $sync_count++;
    }

    is($sync_count, $async_count, 'next() iterates all rows');

    # Test reset
    $search_rs->reset;
    my $first = $search_rs->next;
    ok($first, 'reset() allows re-iteration');

    # Test get() returns arrayref
    my $all = $search_rs->get;
    isa_ok($all, 'ARRAY');
    cmp_ok(scalar @$all, '==', $sync_count, 'get() returns all rows');
};

# Test 6: Update operations (update to use async)
subtest 'Update operations' => sub {

    my $rs = $schema->resultset('User');

    my $user = $rs->create({ name => 'Dave', email => 'dave@ex.com' })->get;
    ok($user->id, "User was created with ID: " . $user->id);

    my $updated = $user->update({ name => 'Dave Updated' })->get;
    is($updated->name, 'Dave Updated', 'Local object updated');

    my $refetched = $rs->find($user->id)->get;
    is($refetched->name, 'Dave Updated', 'Database record updated');

    # Bulk update via resultset
    my $bulk_update_future = $schema->resultset('User')
                                    ->search({ active => 1 })
                                    ->update({ active => 0 });

    my $updated_count = $bulk_update_future->get;
    cmp_ok($updated_count, '>=', 1, 'Bulk update affected at least one row');

    # Count inactive users
    my $count_future = $rs->search({ active => 0 })->count_future;
    my $inactive_count = $count_future->get;
    cmp_ok($inactive_count, '>=', 1, 'Users were deactivated');
};

$schema->disconnect;
teardown_test_db();

done_testing();
