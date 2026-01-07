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
    workers => 3,
);

# Create concurrent operations
my @futures;
for my $i (1..5) {
    push @futures, $async_db->search('User', {}, { rows => 1 });
}

# Wait for all
my @results = Future->wait_all(@futures)->get;

is(scalar @results, 5, 'all concurrent operations completed');

my $success_count = grep { $_->is_done && !$_->failure } @results;
is($success_count, 5, 'all concurrent operations succeeded');

$async_db->disconnect;

done_testing;
