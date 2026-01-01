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

throws_ok {
    DBIx::Class::Async->new();
} qr/schema_class required/, 'schema_class required';

throws_ok {
    DBIx::Class::Async->new(schema_class => 'TestSchema');
} qr/connect_info required/, 'connect_info required';

throws_ok {
    DBIx::Class::Async->new(
        schema_class => 'NonExistent::Schema',
        connect_info => ["dbi:SQLite:$db_file"],
    );
} qr/Cannot load schema class/, 'invalid schema class';

my $async_db;
lives_ok {
    $async_db = DBIx::Class::Async->new(
        schema_class => 'TestSchema',
        connect_info => ["dbi:SQLite:$db_file", '', '', {
            sqlite_use_immediate_transaction => 0,
        }],
        workers => 2,
    );
} 'constructor succeeds with valid params';

isa_ok($async_db, 'DBIx::Class::Async');
isa_ok($async_db->loop, 'IO::Async::Loop');
is($async_db->schema_class, 'TestSchema', 'schema_class accessor works');

lives_ok {
    $async_db->disconnect;
} 'disconnect works';

done_testing;
