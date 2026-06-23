#!/usr/bin/env perl
# t/40-diff.t — DBIO::DuckDB::Deploy diff round-trip.
#
# 1. Connect to empty DuckDB (no_deploy), diff vs desired schema ->
#    should emit CREATE TABLE ops for artist + cd.
# 2. Apply the diff.
# 3. Diff again -> should be empty (idempotent).

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Test;
use DBIO::DuckDB::Deploy;

my $schema = DBIO::DuckDB::Test->init_schema(no_deploy => 1);
my $deploy = DBIO::DuckDB::Deploy->new(schema => $schema);

my $diff1 = $deploy->diff;
ok $diff1->has_changes, 'empty DB has diff vs desired schema';
like $diff1->as_sql, qr/CREATE TABLE "?artist"?/, 'diff creates artist';
like $diff1->as_sql, qr/CREATE TABLE "?cd"?/,     'diff creates cd';
like $diff1->as_sql, qr/CREATE SEQUENCE/,         'diff emits sequences for auto-increment';
like $diff1->summary, qr/\+ table: artist/,       'summary mentions artist';
like $diff1->summary, qr/\+ table: cd/,           'summary mentions cd';

$deploy->apply($diff1);
pass 'applied initial diff';

my $diff2 = $deploy->diff;
ok !$diff2->has_changes, 'second diff is empty (idempotent deploy)'
  or diag "remaining diff:\n" . $diff2->as_sql;

done_testing;
