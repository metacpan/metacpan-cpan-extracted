#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;
use Test::Deep;
use Test::Exception;

use lib 't/lib';
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

my $schema_class = "TestSchema";
my $loop = IO::Async::Loop->new;
my ($fh, $db_file) = File::Temp::tempfile(SUFFIX => '.db', UNLINK => 1);
my $schema;

subtest 'Schema creation' => sub {
    lives_ok {
        $schema = DBIx::Class::Async::Schema->connect(
            "dbi:SQLite:dbname=$db_file", undef, undef, {},
            { workers      => 2,
              schema_class => $schema_class,
              async_loop   => $loop,
              cache_ttl    => 60
            });
    } 'Schema connects successfully';

    isa_ok($schema, 'DBIx::Class::Async::Schema', 'Schema object');
    my @sources = $schema->sources;
    cmp_ok(scalar @sources, '>=', 2, 'Has at least 2 sources');
    ok(grep(/^User$/, @sources), 'Has User source');
    ok(grep(/^Order$/, @sources), 'Has Order source');
    ok(grep(/^Product$/, @sources), 'Has Product source');

    my $user_source = $schema->source('User');
    isa_ok($user_source, 'DBIx::Class::ResultSource::Table', 'User source');
};

subtest 'Storage compatibility' => sub {
    $schema = DBIx::Class::Async::Schema->connect(
        "dbi:SQLite:dbname=$db_file", undef, undef, {},
        { workers      => 2,
          schema_class => $schema_class,
          async_loop   => $loop,
          cache_ttl    => 60
        });

    my $storage = $schema->storage;
    isa_ok($storage, 'DBIx::Class::Async::Storage', 'Storage object');

    is($storage->schema, $schema, 'Storage references schema');

    # Storage methods
    ok(!defined $storage->dbh, 'dbh returns undef in async storage');

    lives_ok { $storage->disconnect } 'disconnect works';
};

subtest 'Schema cloning' => sub {
    my $new_schema = $schema->clone;
    isa_ok($new_schema, 'DBIx::Class::Async::Schema', 'Cloned schema');
    is($schema->{_async_db}, $new_schema->{_async_db},
        'Cloned schema shares async_db with parent (shared worker pool)');
    cmp_bag([$schema->sources], [$new_schema->sources], 'Cloned schema has same sources');
};

subtest 'Error handling' => sub {
    throws_ok {
        DBIx::Class::Async::Schema->connect();
    } qr/schema_class is required/, 'connect() without args dies';

    throws_ok {
        DBIx::Class::Async::Schema->connect(
            "dbi:SQLite:dbname=$db_file", undef, undef, {}
        );
    } qr/schema_class.*required/, 'connect() without schema_class dies';

    throws_ok {
        my $schema = DBIx::Class::Async::Schema->connect(
            "dbi:SQLite:dbname=$db_file", undef, undef, {},
            { workers => 1, schema_class => $schema_class }
        );
        $schema->resultset();
    } qr/resultset.*requires a source name/, 'resultset() without source dies';
};

done_testing;
