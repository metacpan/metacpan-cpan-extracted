#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::Spec;
use File::Copy;
use File::Temp;
use Test::More;
use Test::Exception;

use lib "$FindBin::Bin/lib";
use DBIx::Class::Async;

my $source_db = File::Spec->catfile($FindBin::Bin, 'test.db');

unless (-e $source_db) {
    plan skip_all => "Source test database not found: $source_db";
}

my $temp_db = File::Temp->new(
    TEMPLATE => 'test_XXXXXX',
    SUFFIX   => '.db',
    UNLINK   => 1,
);

my $temp_db_path = $temp_db->filename;

copy($source_db, $temp_db_path) or
    plan skip_all => "Failed to copy database: $!";

my $db_file = $temp_db_path;

my $async_db;
eval {
    $async_db = DBIx::Class::Async->new(
        schema_class => 'TestSchema',
        connect_info => ["dbi:SQLite:$db_file", '', '', {
            sqlite_use_immediate_transaction => 0,
        }],
        workers   => 2,
        cache_ttl => 0,
    );
};

if ($@) {
    fail("Failed to create async_db: $@");
    for (1..17) { fail("skipped due to construction failure"); }
    return;
}

my $users_future = $async_db->search('User', { active => 1 });
isa_ok($users_future, 'Future', 'search returns Future');

$users_future->on_ready(sub { $async_db->loop->stop; });
$async_db->loop->run;

my $users = $users_future->get;

ok(ref $users eq 'ARRAY', 'search returns arrayref');

if (ref $users eq 'ARRAY' && @$users) {
    cmp_ok(scalar @$users, '>=', 1, 'search returns results');
    is($users->[0]{name}, 'Test User', 'search returns correct data');
} else {
    fail('no users returned');
    fail('no users returned');
}

my $user = $async_db->find('User', 1)->get;
is($user->{id}, 1, 'find returns correct user');
is($user->{name}, 'Test User', 'find returns correct data');

my $nonexistent = $async_db->find('User', 999)->get;
is($nonexistent, undef, 'find returns undef for non-existent id');

my $new_user = $async_db->create(
    'User',
    { name => 'New User', email => 'new\@example.com' }
)->get;

ok($new_user->{id}, 'create returns new user with id');
is($new_user->{name}, 'New User', 'create returns correct data');

my $updated = $async_db->update(
    'User',
    $new_user->{id},
    { name => 'Updated User' }
)->get;

is($updated->{name}, 'Updated User', 'update modifies data');

my $update_nonexistent = $async_db->update(
    'User',
    999,
    { name => 'Should not exist' }
)->get;

is($update_nonexistent, undef, 'update returns undef for non-existent id');

my $delete_result = $async_db->delete('User', $new_user->{id})->get;
is($delete_result, 1, 'delete returns success');

my $delete_nonexistent = $async_db->delete('User', 999)->get;
is($delete_nonexistent, 0, 'delete returns 0 for non-existent id');

my $count_all = $async_db->count('User')->get;
cmp_ok($count_all, '>=', 2, 'count returns correct total');

my $count_active = $async_db->count('User', { active => 1 })->get;
cmp_ok($count_active, '>=', 1, 'count with conditions works');

my $raw_results = $async_db->raw_query(
    'SELECT * FROM users WHERE active = ?',
    [1]
)->get;

cmp_ok(scalar @$raw_results, '>=', 1, 'raw_query returns results');
is($raw_results->[0]{active}, 1, 'raw_query respects bind parameters');

my $empty_raw = $async_db->raw_query(
    'SELECT * FROM users WHERE id = ?',
    [999]
)->get;

is(scalar @$empty_raw, 0, 'raw_query returns empty array for no results');

$async_db->disconnect;

done_testing;
