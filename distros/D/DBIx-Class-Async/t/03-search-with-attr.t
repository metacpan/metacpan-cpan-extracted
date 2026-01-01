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

my $ordered_users = $async_db->search(
    'User',
    {},
    { order_by => 'name DESC', rows => 1 }
)->get;

is(scalar @$ordered_users, 1, 'rows limit works');
ok($ordered_users->[0]{name}, 'ordered search returns data');

my $all_users = $async_db->search('User')->get;
cmp_ok(scalar @$all_users, '>=', 2, 'search without conditions works');

$async_db->disconnect;

done_testing;
