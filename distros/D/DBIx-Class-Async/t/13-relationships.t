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

my $async_db = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => ["dbi:SQLite:$db_file", '', '', {
        sqlite_use_immediate_transaction => 0,
    }],
    workers => 2,
);

my $users_with_orders = $async_db->search_with_prefetch(
    'User',
    { 'me.id' => 1 },
    'orders',
)->get;

is(scalar @$users_with_orders, 1, 'prefetch returns results');

# Test that basic search still works
my $users = $async_db->search('User', { id => 1 })->get;
is(scalar @$users, 1, 'basic search works');

subtest 'result_class HashRefInflator works' => sub {
    my $results = $async_db->search_with_prefetch(
        'User',
        { 'me.id' => 1 },
        'orders',
        { result_class => 'DBIx::Class::ResultClass::HashRefInflator' }
    )->get;

    ok(ref $results eq 'ARRAY', 'Got array of results');
    ok(ref $results->[0] eq 'HASH', 'Result is a plain hash');
    ok(exists $results->[0]{orders}, 'Prefetched data is included in hash');
};

$async_db->disconnect;

done_testing;
