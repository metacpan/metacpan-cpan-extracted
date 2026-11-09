use strict;
use warnings;
use Test::More;

# t/19-dialect-live.t — FINAL, PREWHERE and LIMIT n BY against a real
# ClickHouse server, reached over the MySQL wire protocol.
#
# ClickHouse has NO embedded / in-memory mode, so this cannot run unattended:
# it needs a real server and is gated on DBIO_TEST_CLICKHOUSE_DSN. Without it
# the file skips cleanly. The offline counterpart is t/11-sqlmaker-dialect.t,
# which pins the rendered SQL and the bind order for all three attributes
# without a server.
#
# These three attributes are the only genuinely new API this driver adds to
# the resultset (DBIO::ClickHouse::SQLMaker/CLICKHOUSE RESULTSET ATTRIBUTES),
# and t/11 can only prove that we emit a particular string. What it cannot
# prove -- and what every assertion here is about -- is that ClickHouse PARSES
# that string and MEANS by it what the POD claims:
#
#   * FINAL is emitted in the alias form, `FROM `t` `me` FINAL`. DBIO always
#     aliases its primary table, so the bare-table form ClickHouse's own
#     documentation shows is not reachable from here; if the alias form did not
#     parse, the attribute would be unusable rather than merely differently
#     spelled. It also has to survive a join (where it marks the primary table
#     only) and it has to actually deduplicate a ReplacingMergeTree.
#
#   * PREWHERE has to accept a column that is not in the SELECT list -- which is
#     the whole point of the clause, filtering before the remaining columns of
#     the granule are read -- and it has to actually filter rather than being
#     parsed and ignored.
#
#   * LIMIT n BY has to coexist with the ordinary LIMIT in one statement:
#     `ORDER BY x LIMIT 3 BY col LIMIT ? OFFSET ?` is two LIMIT clauses,
#     and one of them is inlined while the other is bound.
#
# Plus one storage hook that has no offline test at all: a complex prefetch
# rewrites the query into an outer SELECT over a subquery, and
# DBIO::ClickHouse::Storage/_adjust_select_args_for_complex_prefetch strips the
# dialect attributes from the outer half. FINAL on a subquery is a syntax
# error, so the server is the only place that hook can be shown to work.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;

my $schema    = DBIO::ClickHouse::Test->init_schema;
my $snapshots = $schema->resultset('Snapshot');
my $hits      = $schema->resultset('Hit');

# A second version of snapshot 1. ReplacingMergeTree keeps both rows until a
# merge happens (which may be at any moment, or never), so only the FINAL
# reads below are deterministic -- the un-FINAL count is noted, not asserted.
$snapshots->populate([ { id => 1, label => 'alpha-v2', version => 2 } ]);

note 'rows for snapshot 1 without FINAL: '
   . $snapshots->search({ id => 1 })->count
   . ' (2 until a background merge collapses them, 1 after -- both legal)';

# --- FINAL ------------------------------------------------------------------

{
  my $rs = $snapshots->search({ id => 1 }, { final => 1 });

  is $rs->count, 1,
    'FINAL in the alias form (FROM `t` `me` FINAL) parses and collapses the '
  . 'ReplacingMergeTree to one row per key';

  is $rs->single->label, 'alpha-v2',
    '... keeping the row with the higher version, which is what the engine argument selects';

  is $snapshots->search(undef, { final => 1 })->count, 3,
    'and the whole table reads back as one row per key';
}

# FINAL marks the primary table of a join and no other. Six join rows collapse
# to five exactly because snapshot 1 stopped being two rows.
{
  my $rs = $snapshots->search(
    { 'hits.hits' => { '>' => 1 } }, { join => 'hits', final => 1 },
  );

  is $rs->count, 5,
    'FINAL parses with a join attached, and deduplicates the primary table '
  . 'inside it (5 matching hits, each seen once)';
}

# --- PREWHERE ---------------------------------------------------------------

{
  my $rs = $hits->search(
    { url => '/c' },
    { prewhere => { hits => { '>' => 50 } }, columns => ['url'] },
  );

  is $rs->count, 1,
    'PREWHERE accepts a column that is not in the SELECT list -- the case the '
  . 'clause exists for';
  is $rs->single->url, '/c', '... and the row is the right one';
}

{
  my $rs = $hits->search(
    { url => '/c' },
    { prewhere => { hits => { '>' => 1000 } }, columns => ['url'] },
  );

  is $rs->count, 0,
    'a PREWHERE that matches nothing returns nothing -- it is applied, not '
  . 'parsed and discarded';
}

{
  my $rs = $hits->search(
    undef,
    { prewhere => { 'me.hits' => { '>=' => 100 } }, columns => ['me.url'] },
  );

  is $rs->count, 4,
    'PREWHERE accepts an alias-qualified column name';
}

# --- LIMIT n BY, alongside the ordinary LIMIT/OFFSET ------------------------
#
# ORDER BY hits DESC gives /f /e /d /c /b /a with snapshots 3 3 2 2 1 1.
# LIMIT 1 BY snapshot keeps the first row of each: /f /d /b.
# LIMIT 2 OFFSET 1 then takes /d /b -- so a wrong clause order, a dropped
# clause or an unbound placeholder all produce a different list, not just a
# different count.

{
  my @rows = $hits->search(undef, {
    order_by => { -desc => 'me.hits' },
    limit_by => { rows => 1, by => 'me.snapshot' },
    rows     => 2,
    offset   => 1
  })->all;

  is_deeply [ map { $_->url } @rows ], [qw(/d /b)],
    'ORDER BY ... LIMIT 1 BY col LIMIT ? OFFSET ? -- two LIMIT clauses in one '
  . 'statement, the first inlined and the second bound';
}

{
  my @rows = $hits->search(undef, {
    order_by => { -desc => 'me.hits' },
    limit_by => { rows => 1, by => 'me.snapshot' }
  })->all;

  is_deeply [ map { $_->url } @rows ], [qw(/f /d /b)],
    'LIMIT n BY on its own is the top-1 per group it claims to be';
}

# --- the complex-prefetch rewrite -------------------------------------------
#
# A has_many prefetch with a row limit makes core build an outer SELECT over a
# subquery. FINAL is not valid on a subquery, so if the storage hook did not
# strip it from the outer half this would be a syntax error rather than a
# wrong result -- which is exactly the failure mode we want.

{
  my @rows = $snapshots->search(undef, {
    prefetch => 'hits',
    order_by => 'me.id',
    rows     => 2,
    final    => 1
  })->all;

  is scalar(@rows), 2,
    'final => 1 survives a complex prefetch: FINAL stayed on the inner query '
  . 'and was stripped from the outer one';
  is $rows[0]->id, 1, '... and the limited set is the ordered one';

  my @prefetched = $rows[0]->hits->all;
  is scalar(@prefetched), 2, '... with the prefetched rows attached';
}

done_testing;
