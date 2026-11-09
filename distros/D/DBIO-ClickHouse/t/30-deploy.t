use strict;
use warnings;
use Test::More;

# t/30-deploy.t — DBIO::ClickHouse::Deploy against a live ClickHouse server,
# reached over the MySQL wire protocol.
#
# ClickHouse has NO embedded / in-memory mode, so this cannot run unattended:
# the desired-state model is built by deploying into a scratch DATABASE on the
# same server (see DBIO::ClickHouse::Deploy/THE SCRATCH DATABASE), which means
# a real server and a user holding CREATE DATABASE / DROP DATABASE. Gated on
# DBIO_TEST_CLICKHOUSE_DSN; without it the file skips cleanly. The offline
# counterparts are t/40-diff.t and t/41-diff-index.t, which cover the diff
# logic itself with hand-built models.
#
# What only a server can answer, and what every assertion below is really
# about:
#
#   1. Does the scratch-database dance work at all — CREATE DATABASE, connect
#      with the rewritten DSN, deploy, introspect, DROP DATABASE?
#   2. Does the install DDL that DBIO::ClickHouse::DDL renders round-trip
#      through system.* back into a model that compares EQUAL to the live one?
#      That is the whole test-deploy-and-compare premise: if it does not hold,
#      every upgrade emits a phantom diff forever.
#   3. Is the scratch database really gone afterwards, including when the
#      deploy inside it died?

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;
use DBIO::ClickHouse::DDL;
use DBIO::ClickHouse::Deploy;

my $schema = DBIO::ClickHouse::Test->init_schema(no_populate => 1);
my $dbh    = $schema->storage->dbh;

sub scratch_databases {
  my $rows = $dbh->selectall_arrayref(
    q{SELECT name FROM system.databases WHERE name LIKE 'dbio_deploy_tmp_%'});
  return map { $_->[0] } @$rows;
}

my %pre_existing = map { $_ => 1 } scratch_databases();

my $deploy = DBIO::ClickHouse::Deploy->new(schema => $schema);

# --- 1. the scratch-database round trip -------------------------------------

my $diff = $deploy->diff;
isa_ok $diff, 'DBIO::ClickHouse::Diff', 'diff against the live database';

my @leaked = grep { !$pre_existing{$_} } scratch_databases();
is_deeply \@leaked, [], 'the scratch database was dropped after a successful diff'
  or diag "leaked: @leaked";

# --- 2. the round trip is clean ---------------------------------------------
# init_schema deployed the schema already, so live and desired must agree. A
# non-empty diff here is a round-trip failure in DDL or Introspect, not a
# schema change — dump it, because the SQL names the offending column.

ok !$diff->has_changes, 'a freshly deployed schema has no diff against itself'
  or diag "unexpected diff:\n" . $diff->as_sql;

# ... and it stays clean. Applying nothing must not make it dirty.
ok !$deploy->upgrade, 'upgrade on an up-to-date database reports nothing to do';
ok !$deploy->diff->has_changes, 'and the second diff is still clean';

# --- 3. an added column is seen, applied, and converges ----------------------

my $live_tables = $deploy->_introspect_current->{tables};
# A view has no ALTER TABLE, so pick a real table to drift.
my ($table) = sort grep { ($live_tables->{$_}{kind} // 'table') eq 'table' }
  keys %$live_tables;

SKIP: {
  skip 'no table in the deployed test schema', 4 unless defined $table;

  $dbh->do(sprintf 'ALTER TABLE `%s` DROP COLUMN IF EXISTS `dbio_scratch_probe`', $table);
  $dbh->do(sprintf 'ALTER TABLE `%s` ADD COLUMN `dbio_scratch_probe` Nullable(String)',
    $table);

  my $drifted = $deploy->diff;
  ok $drifted->has_changes, 'a column the schema does not declare shows up as drift';
  like $drifted->as_sql, qr/DROP COLUMN IF EXISTS `dbio_scratch_probe`/,
    'and the diff proposes dropping it, guarded (Deploy hands the diff its storage, karr k29)';

  # the probe column is dropped on purpose: a drop is destructive, so it is released
  $deploy->apply($drifted, allow_destructive => 1);
  ok !$deploy->diff->has_changes, 'applying the diff converges in one pass';

  my @still = grep { !$pre_existing{$_} } scratch_databases();
  is_deeply \@still, [], 'no scratch database leaked across the drift cycle';
}

# --- 4. cleanup happens even when the deploy inside the scratch DB dies ------
# The guarantee that matters: _build_target_model always drops the scratch
# database, and re-raises the ORIGINAL error rather than whatever the cleanup
# did. Forced by handing the deploy DDL that ClickHouse rejects.

{
  package DBIO::ClickHouse::Test::BadDDL;
  sub install_ddl { 'CREATE TABLE `dbio_scratch_bad` (`id` NoSuchType) ENGINE = MergeTree ORDER BY (`id`);' }
}

my $failing = DBIO::ClickHouse::Deploy->new(schema => $schema);
{
  no warnings 'redefine';
  local *DBIO::ClickHouse::Deploy::_ddl_class = sub { 'DBIO::ClickHouse::Test::BadDDL' };

  my $err = do { local $@; eval { $failing->diff }; $@ };
  ok $err, 'a deploy that fails inside the scratch database propagates an error';
  unlike "$err", qr/DROP DATABASE/,
    'and it is the original error, not something the cleanup raised';
}

my @after_failure = grep { !$pre_existing{$_} } scratch_databases();
is_deeply \@after_failure, [],
  'the scratch database is dropped even when the deploy into it died'
  or diag "leaked: @after_failure";

done_testing;
