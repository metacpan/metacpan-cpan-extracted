#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use Future::AsyncAwait;
use File::Temp qw(tempfile);
use lib 't/lib';
use TestSchema;
use DBIx::Class::Async::Schema;

my $loop = IO::Async::Loop->new;
my ( $fh, $db_file ) = tempfile( UNLINK => 1 );

my $schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file",
    undef, undef, { RaiseError => 1 },
    { workers => 1, schema_class => 'TestSchema', loop => $loop }
);

$loop->await(
    (async sub {
    eval {
        # 1. Setup Data (MUST happen first)
        await $schema->deploy;
        my $rs = $schema->resultset('User');

        await $rs->create({ name => 'Alice', email => 'alice@test.com', active => 1 });
        await $rs->create({ name => 'Bob',   email => 'bob@test.com',   active => 1 });
        await $rs->create({ name => 'Charlie', email => 'charlie@test.com', active => 0 });

        # 2. Test count_literal
        my $active_count = await $rs->count_literal('active = ?', 1);
        is($active_count, 2, "count_literal returned correct count for active users");

        # 3. Test search_literal (with Multiple Bind Values)
        my $literal_rs = $rs->search_literal('name = ? OR email = ?', 'Alice', 'bob@test.com');
        my $found = await $literal_rs->all;
        is(scalar @$found, 2, "search_literal found correct number of rows with multiple binds");
        is($found->[0]->name, 'Alice', "search_literal retrieved correct accessor data");

        # 4. Test Chaining after search_literal
        my $chained_count = await $rs->search_literal('active = ?', 1)
                                     ->search({ name => 'Alice' })
                                     ->count;
        is($chained_count, 1, "Chaining standard search() after search_literal() works");

        # 5. Test count_rs (Standalone execution)
        # Note: count_rs returns a ResultSet, so we await single
        my $cnt_rs = $rs->search({ active => 1 })->count_rs;
        my $cnt_row = await $cnt_rs->single_future;
        is($cnt_row->get_column('count'), 2, "count_rs works as a standalone executed ResultSet");

        # 6. Test count_rs (Subquery usage via as_query)
        # We want to find users whose ID is in the set of active user IDs
        my $id_subquery = $rs->search(
                { active => 1 },
                { select => ['id'] } # This is the standard way to do a single-column subquery
        )->as_query;
        my $complex_rs = $rs->search({ id => { -in => $id_subquery } });

        my $subquery_results = await $complex_rs->all;
        is(scalar @$subquery_results, 2, "as_query successfully generated a valid subquery");
    };

    if ($@) {
        fail("Test suite crashed: $@");
    }

    done_testing();
})->() );
