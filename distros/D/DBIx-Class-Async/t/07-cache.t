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
    workers   => 2,
    cache_ttl => 60,
);

# First query (should miss cache)
my $results1 = $async_db->search('User', { active => 1 })->get;

# Second identical query (should hit cache)
my $results2 = $async_db->search('User', { active => 1 })->get;

is(scalar @$results2, scalar @$results1, 'cached results have same count');

my $stats = $async_db->stats;
cmp_ok($stats->{cache_hits}, '>=', 1, 'cache hits recorded');
cmp_ok($stats->{cache_misses}, '>=', 1, 'cache misses recorded');

# Test with cache disabled
my $async_db_no_cache = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => ["dbi:SQLite:$db_file", '', '', {
        sqlite_use_immediate_transaction => 0,
    }],
    workers   => 2,
    cache_ttl => 0,
);

my $results3 = $async_db_no_cache->search('User')->get;
ok(scalar @$results3, 'search works with cache disabled');

$async_db->disconnect;
$async_db_no_cache->disconnect;

done_testing;
