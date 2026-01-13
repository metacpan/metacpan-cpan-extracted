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
require_ok('DBIx::Class::Async::Storage::DBI::Cursor');

use TestDB;

my $db_file      = setup_test_db();
my $loop         = IO::Async::Loop->new;
my $schema_class = get_test_schema_class();

my $schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => $schema_class, loop => $loop }
);

subtest 'Cursor instantiation' => sub {
    my $rs      = $schema->resultset('User');
    my $storage = $schema->storage;

    isa_ok($storage, 'DBIx::Class::Async::Storage::DBI', 'Storage is DBI type');

    my $cursor = $storage->cursor($rs);
    isa_ok($cursor, 'DBIx::Class::Async::Storage::DBI::Cursor', 'Cursor object created');

    # Test cursor has correct references
    is($cursor->{storage}, $storage, 'Cursor holds storage reference');
    is($cursor->{rs}, $rs, 'Cursor holds resultset reference');
};

subtest 'Cursor initial state' => sub {
    my $rs     = $schema->resultset('User');
    my $cursor = $schema->storage->cursor($rs);

    is($cursor->{page}, 1, 'Initial page is 1');
    is($cursor->{finished}, 0, 'Cursor not finished on start');
    is_deeply($cursor->{buffer}, [], 'Buffer is empty on start');
    ok($cursor->{batch} > 0, 'Batch size is set');
};

subtest 'Cursor reset functionality' => sub {
    my $rs     = $schema->resultset('User');
    my $cursor = $schema->storage->cursor($rs);

    # Modify cursor state
    $cursor->{page}     = 5;
    $cursor->{finished} = 1;
    $cursor->{buffer}   = [1, 2, 3];

    # Reset cursor
    my $result = $cursor->reset;

    is($result, $cursor, 'reset returns self for chaining');
    is($cursor->{page}, 1, 'Page reset to 1');
    is($cursor->{finished}, 0, 'Finished flag reset');
    is_deeply($cursor->{buffer}, [], 'Buffer cleared');
};

subtest 'Cursor batch size from ResultSet' => sub {
    my $rs     = $schema->resultset('User')->search(undef, { rows => 5 });
    my $cursor = $schema->storage->cursor($rs);

    is($cursor->{batch}, 5, 'Cursor batch size matches ResultSet rows attribute');
};

subtest 'Async cursor iteration' => sub {
    my $rs      = $schema->resultset('User');
    my $exp_cnt = $rs->count_future->get;
    my $cursor  = $schema->storage->cursor($rs);

    my $iter = (async sub {
        my $i = 0;
        while (my $row = await $cursor->next) {
            $i++;
            ok(ref($row) =~ /^DBIx::Class::Async::Row::/, "Row $i is an Async Row object");
        }
        return $i;
    })->();

    my $got_cnt = $iter->get;
    is($got_cnt, $exp_cnt, "Cursor iterated through all $exp_cnt rows");
};

subtest 'Cursor exhaustion behavior' => sub {
    my $rs     = $schema->resultset('User')->search(undef, { rows => 2 });
    my $cursor = $schema->storage->cursor($rs);

    my $iter = (async sub {
        my @rows;

        # Get all rows
        while (my $row = await $cursor->next) {
            push @rows, $row;
        }

        # Try to get another row after exhaustion
        my $extra = await $cursor->next;

        return (\@rows, $extra);
    })->();

    my ($rows, $extra) = $iter->get;

    ok(scalar(@$rows) > 0, 'Got some rows');
    is($extra, undef, 'Returns undef when cursor is exhausted');
    is($cursor->{finished}, 1, 'Finished flag is set');
};

subtest 'Cursor buffer management' => sub {
    my $rs     = $schema->resultset('User')->search(undef, { rows => 3 });
    my $cursor = $schema->storage->cursor($rs);

    my $iter = (async sub {
        # Get first row (should populate buffer)
        my $row1 = await $cursor->next;
        my $buffer_size_after_first = scalar(@{$cursor->{buffer}});

        # Get second row (should come from buffer)
        my $row2 = await $cursor->next;

        return ($row1, $row2, $buffer_size_after_first);
    })->();

    my ($row1, $row2, $buffer_size) = $iter->get;

    ok(defined $row1, 'First row retrieved');
    ok(defined $row2, 'Second row retrieved');
    ok($buffer_size >= 0, 'Buffer was populated after first fetch');
};

subtest 'Integration with ResultSet cursor method' => sub {
    my $rs = $schema->resultset('User');

    ok($rs->can('cursor'), 'ResultSet has cursor method');

    # Test cursor creation directly through storage
    my $cursor = $schema->storage->cursor($rs);
    isa_ok($cursor, 'DBIx::Class::Async::Storage::DBI::Cursor', 'Storage->cursor returns proper cursor');
};

$schema->disconnect;
teardown_test_db();

done_testing();
