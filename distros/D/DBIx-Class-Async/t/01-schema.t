#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use Test::Deep;

use lib 't/lib';
use DBIx::Class::Async::Schema;
use TestDB;

# Setup test database
my $db_file = setup_test_db();


# Test 1: Basic schema creation
subtest 'Schema creation' => sub {

    my $schema_class = get_test_schema_class();

    # Test normal DBIx::Class::Async::Schema usage
    my $schema;
    lives_ok {
        $schema = DBIx::Class::Async::Schema->connect(
            "dbi:SQLite:dbname=$db_file",
            undef,
            undef,
            { sqlite_unicode => 1 },
            { workers => 1, schema_class => $schema_class }
        );
    } 'Schema connects successfully';

    isa_ok($schema, 'DBIx::Class::Async::Schema', 'Schema object');

    # Test sources
    my @sources = $schema->sources;
    cmp_ok(scalar @sources, '>=', 2, 'Has at least 2 sources');
    ok(grep(/^User$/, @sources), 'Has User source');
    ok(grep(/^Order$/, @sources), 'Has Order source');

    # Test source method
    my $user_source = $schema->source('User');
    isa_ok($user_source, 'DBIx::Class::ResultSource::Table', 'User source');
};

# Test 2: Storage compatibility
subtest 'Storage compatibility' => sub {

    my $schema_class = get_test_schema_class();
    my $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 1, schema_class => $schema_class }
    );

    my $storage = $schema->storage;
    isa_ok($storage, 'DBIx::Class::Async::Storage', 'Storage object');

    is($storage->schema, $schema, 'Storage references schema');

    # Storage methods
    ok(!defined $storage->dbh, 'dbh returns undef in async storage');

    lives_ok { $storage->disconnect } 'disconnect works';
};

# Test 3: Schema cloning
subtest 'Schema cloning' => sub {

    my $schema_class = get_test_schema_class();
    my $schema1 = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file",
        undef,
        undef,
        { sqlite_unicode => 1 },
        { workers => 1, schema_class => $schema_class }
    );

    my $schema2 = $schema1->clone;
    isa_ok($schema2, 'DBIx::Class::Async::Schema', 'Cloned schema');

    isnt($schema1->{async_db}, $schema2->{async_db}, 'Async DB instances are different');

    # Both should have same sources
    cmp_bag([$schema1->sources], [$schema2->sources], 'Cloned schema has same sources');
};

# Test 4: Error handling
subtest 'Error handling' => sub {

    throws_ok {
        DBIx::Class::Async::Schema->connect();
    } qr/schema_class is required/, 'connect() without args dies';

    throws_ok {
        DBIx::Class::Async::Schema->connect(
            "dbi:SQLite:dbname=$db_file",
            undef,
            undef,
            { sqlite_unicode => 1 }
        );
    } qr/schema_class.*required/, 'connect() without schema_class dies';

    throws_ok {
        my $schema_class = get_test_schema_class();
        my $schema = DBIx::Class::Async::Schema->connect(
            "dbi:SQLite:dbname=$db_file",
            undef,
            undef,
            { sqlite_unicode => 1 },
            { workers => 1, schema_class => $schema_class }
        );
        $schema->resultset();
    } qr/resultset.*requires a source name/, 'resultset() without source dies';
};

# Cleanup
teardown_test_db();
done_testing;
