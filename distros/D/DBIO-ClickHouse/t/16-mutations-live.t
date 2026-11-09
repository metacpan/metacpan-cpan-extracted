use strict;
use warnings;
use Test::More;

# t/16-mutations-live.t — the UPDATE/DELETE mutation path against a live
# ClickHouse server, reached over the MySQL wire protocol.
#
# ClickHouse has NO embedded / in-memory mode, so this cannot run unattended:
# it needs a real server and is gated on DBIO_TEST_CLICKHOUSE_DSN. Without it
# the file skips cleanly. The offline contract for the same code is
# t/15-mutations.t, which pins the rendered SQL, the bind order and the
# guardrails without a server.
#
# What this file is for is the half t/15 cannot reach. Every assertion here is
# an assumption about the server or the wire, not about our rendering, and each
# one is load-bearing for a decision recorded in
# docs/adr/0005-mutations-sync-by-default.md:
#
#   * the MySQL-wire handler accepts a trailing SETTINGS clause on an
#     ALTER TABLE ... UPDATE/DELETE at all -- if it does not, the whole
#     per-statement route (decision 2) has to become a session-level SET;
#   * mutations_sync = 1 really means read-your-own-writes: a SELECT issued
#     straight after the mutation, on the same connection, sees the new rows.
#     That is the entire justification for waiting by default (decision 1);
#   * the affected-rows count the wire reports for a mutation is useless, which
#     is why update()/delete() return -1 rather than a count (decision 4). This
#     is the ONE assertion here that would reopen an ADR decision if it failed;
#   * a mutation predicate accepts the IN (SELECT ...) subquery core generates
#     for a limited or joined resultset;
#   * WHERE 1 -- what $rs->delete({ all => 1 }) renders -- is accepted and
#     means every row.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::Test::Schema;

# The table under test is the fixture's Hit source -- "the source the insert and
# mutation paths run against" (DBIO::ClickHouse::Test::Schema::Hit) -- rather
# than a result class written here, for the same reason as t/14: one definition
# of that table, the one the rest of the live suite deploys.
#
# init_schema deploys into this process's own database and drops that database
# again in an END block, so nothing here can collide with another file and no
# cleanup is left for a failed assertion to skip. See
# DBIO::ClickHouse::Test/EVERY TEST PROCESS GETS ITS OWN DATABASE.
#
# no_populate, so refill() below is the only thing that ever puts rows in the
# table and every count here is a statement about this file's own mutations.
my $schema = DBIO::ClickHouse::Test->init_schema(no_populate => 1);
my $dbh    = $schema->storage->dbh;

my $rs = $schema->resultset('Hit');

# The raw ALTER further down has to name the table itself; ask the source rather
# than repeating the name, so it cannot drift away from what was deployed.
my $table = $rs->result_source->name;

sub refill {
  $rs->delete({ all => 1 });
  $rs->populate([ map { { url => "/$_", hits => $_ } } 1 .. 5 ]);
}

# --- the statement is accepted, and waiting actually waits -----------------
#
# Both halves matter. If the SETTINGS clause were rejected the first assertion
# fails outright; if it were accepted but ignored, the count below would be a
# race, which is exactly what mutations_sync = 1 is supposed to remove.
{
  refill();

  my $rv = $rs->search({ hits => { '<=' => 2 } })->update({ url => '/touched' });

  is $rs->search({ url => '/touched' })->count, 2,
    'ALTER TABLE ... UPDATE ... SETTINGS mutations_sync = 1 is applied before the statement returns';
  is $rs->search({ url => '/3' })->count, 1,
    '... and left every other row alone';
  is $rv, -1, 'the driver reports -1, never a row count';
}

{
  refill();

  $rs->search({ hits => { '>' => 3 } })->delete;

  is $rs->count, 3,
    'ALTER TABLE ... DELETE is likewise applied before the statement returns';
}

# --- the affected-rows count really is unusable -----------------------------
#
# This is the assumption behind returning -1. If ClickHouse's MySQL-wire
# handler ever reports a real count for a mutation, ADR 0005 decision 4 should
# be revisited -- so assert what we believe rather than skipping it.
{
  refill();

  my $sth = $dbh->prepare(
    qq{ALTER TABLE `$table` DELETE WHERE `hits` > 3 SETTINGS mutations_sync = 1}
  );
  my $rv = $sth->execute;

  ok defined $rv, 'the mutation statement executes cleanly on the wire';
  cmp_ok $rv + 0, '==', 0,
    'the wire reports 0 affected rows for a mutation that removed 2 -- '
  . 'there is no count to return';
  is $rs->count, 3, '... though the rows really are gone';
}

# --- row level: the primary key addresses exactly one row -------------------
{
  refill();

  my $row = $rs->search({ hits => 3 })->single;
  ok $row, 'a row to work with';

  $row->update({ url => '/row-updated' });
  is $rs->find($row->id)->url, '/row-updated',
    'a row update() reached exactly that row';
  is $rs->search({ url => '/row-updated' })->count, 1,
    '... and only that row';

  my $id = $row->id;
  $row->delete;
  ok !$rs->find($id), 'a row delete() removed it';
  is $rs->count, 4, '... and nothing else';
}

# --- the subquery predicate core generates ----------------------------------
#
# A limited or joined resultset becomes WHERE pk IN (SELECT pk FROM ...).
# Nothing offline can prove a mutation predicate may contain a subquery.
{
  refill();

  $rs->search({ hits => { '>' => 1 } }, { rows => 2, order_by => 'hits' })->delete;

  is $rs->count, 3,
    'a mutation predicate accepts the IN (SELECT ...) rewrite core generates';
}

# --- literal SQL in an assignment: the read-modify-write mutations are for ---
{
  refill();

  $rs->search({ hits => 5 })->update({ hits => \'hits + 100' });

  is $rs->search({ hits => 105 })->count, 1,
    'an assignment may read the column it writes';
}

# --- WHERE 1 means every row ------------------------------------------------
{
  refill();

  $rs->delete({ all => 1 });

  is $rs->count, 0,
    '$rs->delete({ all => 1 }) (rendered WHERE 1) empties the table';
}

# --- mutations_sync = 0 is genuinely different ------------------------------
#
# Not a correctness assertion -- an asynchronous mutation MAY have landed by
# the time we look. This exists so that a run where it has not landed is
# visible as a note rather than a mystery, and to prove the connect-time
# override reaches the wire at all.
{
  # The same database init_schema deployed into, not the one the DSN names.
  my $async = DBIO::ClickHouse::Test::Schema->connect(
    DBIO::ClickHouse::Test->test_connect_info(mutations_sync => 0)
  );
  my $ars = $async->resultset('Hit');

  $ars->delete({ all => 1 });
  $ars->populate([ map { { url => "/$_", hits => $_ } } 1 .. 5 ]);

  my $ok = eval { $ars->search({ hits => { '<=' => 2 } })->delete; 1 };
  ok $ok, 'mutations_sync => 0 is accepted by the server' or diag $@;

  note 'rows remaining immediately after an async delete: ' . $ars->count
     . ' (5 means the mutation had not been applied yet, 3 means it had -- '
     . 'both are legal without a sync setting)';

  $async->storage->disconnect;
}

done_testing;
