use strict;
use warnings;
use Test::More;

# t/38-ddl-if-exists-live.t — does ClickHouse parse IF EXISTS / IF NOT EXISTS,
# in all four places a DBIO diff would want them.
#
# ClickHouse has NO embedded / in-memory mode, so this cannot run unattended:
# it needs a real server and is gated on DBIO_TEST_CLICKHOUSE_DSN. Without it
# the file skips cleanly.
#
# DBIO::ClickHouse::Storage declares core capability F12,
# `__PACKAGE__->_use_supports_if_exists(1)`, which is what
# DBIO::Diff::Op::should_emit_if_exists reads before emitting guarded DDL. That
# declaration is a claim about the ENGINE, and t/17-capabilities.t can only
# assert that the driver makes it -- not that it is true. Nothing offline can:
# the answer lives in the ClickHouse parser.
#
# So this is a probe rather than a regression test. It asks the server the
# question in the exact spellings a diff would emit, and runs each statement
# TWICE. Running once only proves the syntax parses; running twice is what
# proves the guard actually suppresses the error, which is the entire reason to
# emit it. A green run is the evidence behind _use_supports_if_exists(1); a red
# one names the single statement form that has to stay unguarded -- and, since
# the capability is one flag for all of them, means the flag itself is wrong.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;

# no_deploy: this file wants an empty database of its own, not the fixture.
my $schema = DBIO::ClickHouse::Test->init_schema(no_deploy => 1);
my $dbh    = $schema->storage->dbh;

my $table = 'dbio_if_exists';

# Run one statement twice; both must succeed. $@ is reported verbatim, because
# the ClickHouse parser error names the token it choked on.
sub twice {
  my ($what, $sql) = @_;
  for my $pass (1, 2) {
    my $ok = eval { $dbh->do($sql); 1 };
    ok $ok, "$what (pass $pass)" or diag "server said: $@\nstatement: $sql";
    return 0 unless $ok;
  }
  return 1;
}

# --- table ------------------------------------------------------------------

twice 'CREATE TABLE IF NOT EXISTS', sprintf(
  'CREATE TABLE IF NOT EXISTS `%s` (`id` Int32, `name` String) '
. 'ENGINE = MergeTree ORDER BY (`id`)', $table);

# --- column -----------------------------------------------------------------

twice 'ALTER TABLE ... ADD COLUMN IF NOT EXISTS', sprintf(
  'ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS `extra` Nullable(String)', $table);

# --- data-skipping index ----------------------------------------------------
#
# ClickHouse has no CREATE INDEX at all; a skipping index is added and dropped
# through ALTER TABLE, which is the form DBIO::ClickHouse::DDL::Emit already
# renders (alter_table_add_index / alter_table_drop_index).

twice 'ALTER TABLE ... ADD INDEX IF NOT EXISTS', sprintf(
  'ALTER TABLE `%s` ADD INDEX IF NOT EXISTS `%s_name_set` `name` '
. 'TYPE set(100) GRANULARITY 4', $table, $table);

twice 'ALTER TABLE ... DROP INDEX IF EXISTS', sprintf(
  'ALTER TABLE `%s` DROP INDEX IF EXISTS `%s_name_set`', $table, $table);

twice 'ALTER TABLE ... DROP COLUMN IF EXISTS', sprintf(
  'ALTER TABLE `%s` DROP COLUMN IF EXISTS `extra`', $table);

twice 'DROP TABLE IF EXISTS', sprintf('DROP TABLE IF EXISTS `%s`', $table);

# --- database ---------------------------------------------------------------
#
# The one guard this driver already emits: DBIO::ClickHouse::Deploy drops its
# scratch database unconditionally, including on the path where the CREATE was
# the statement that failed.

{
  my $database = 'dbio_if_exists_db_' . $$;

  twice 'CREATE DATABASE IF NOT EXISTS',
    sprintf('CREATE DATABASE IF NOT EXISTS `%s`', $database);

  twice 'DROP DATABASE IF EXISTS',
    sprintf('DROP DATABASE IF EXISTS `%s`', $database);
}

done_testing;
