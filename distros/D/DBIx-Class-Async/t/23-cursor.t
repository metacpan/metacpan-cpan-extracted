#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use IO::Async::Loop;
use Future::AsyncAwait;
use DBIx::Class::Async::Schema;

use lib 't/lib';

require_ok('DBIx::Class::Async::ResultSet');
require_ok('DBIx::Class::Async::Cursor');

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

subtest 'Cursor iteration logic' => sub {
    # 1. Test basic instantiation
    my $mock_rs = bless { _source_name => 'User' }, 'DBIx::Class::Async::ResultSet';
    my $cursor = $mock_rs->cursor;
    isa_ok($cursor, 'DBIx::Class::Async::Cursor', 'Cursor object created');

    # 2. Test state initial values
    is($cursor->{page}, 1, 'Initial page is 1');
    is($cursor->{finished}, 0, 'Cursor not finished on start');
};

subtest 'Async Flow Test' => sub {
    my $rs      = $schema->resultset('User');
    my $exp_cnt = $rs->count_future->get;
    my $cursor  = $rs->cursor;

    my $iter = (async sub {
        my $i = 0;
        while (my $row = await $cursor->next) {
            $i++;
        }
        return $i;
    })->();

    my $got_cnt = $iter->get;

    is($exp_cnt, $got_cnt, "Cursor iterated through all $exp_cnt rows");
};

$schema->disconnect;
teardown_test_db();

done_testing();
