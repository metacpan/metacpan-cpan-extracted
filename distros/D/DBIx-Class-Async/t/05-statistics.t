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

$async_db->search('User')->get;
$async_db->count('User')->get;

my $stats = $async_db->stats;

ok(exists $stats->{queries}, 'queries stat exists');
cmp_ok($stats->{queries}, '>=', 2, 'queries counted');
ok(exists $stats->{errors}, 'errors stat exists');
ok(exists $stats->{cache_hits}, 'cache_hits stat exists');
ok(exists $stats->{cache_misses}, 'cache_misses stat exists');

$async_db->disconnect;

done_testing;
