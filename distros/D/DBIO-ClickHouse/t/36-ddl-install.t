use strict;
use warnings;
use Test::More;

# t/36-ddl-install.t — DBIO::ClickHouse::DDL->install_ddl over a small
# hand-built schema. Offline: no DBD, no DSN, no server.
#
# Three things this pins down, all of them ClickHouse-specific intent rather
# than incidental output:
#
#   1. Every table gets an explicit ENGINE and an explicit sorting key. There
#      is no server-side default for either, so a missing clause is not a
#      cosmetic diff — it is a CREATE TABLE that fails.
#   2. No FOREIGN KEY and no UNIQUE reaches the output. The schema declares a
#      belongs_to as no constraint (is_foreign_key_constraint => 0) and no
#      unique constraint: a declared one is refused, not left out
#      (t/36-ddl-refusals.t, karr k43; it supersedes the silent omission of
#      ADR 0004).
#   3. The statement order is deterministic. With no FKs there is no topo sort
#      to impose one, so alphabetical order is the contract the diff layer
#      gets to rely on.

use DBIO::ClickHouse::DDL;

{
  package My::CH::Schema::Artist;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid',    is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', size => 255, is_nullable => 0 },
    bio  => { data_type => 'text',    is_nullable => 1 }
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many('events', 'My::CH::Schema::Event', 'artist_id');
}

{
  package My::CH::Schema::Event;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('ClickHouse::Result');

  __PACKAGE__->table('event');
  __PACKAGE__->add_columns(
    id        => { data_type => 'uuid',     is_auto_increment => 1, is_nullable => 0 },
    artist_id => { data_type => 'uuid',     is_nullable => 0 },
    ts        => { data_type => 'datetime', is_nullable => 0 },
    kind      => { data_type => 'varchar',  is_nullable => 0,
                   extra => { low_cardinality => 1 } },
    payload   => { data_type => 'text',     is_nullable => 1 },
    seq       => { data_type => 'integer',  is_nullable => 0, default_value => 0 }
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to('artist', 'My::CH::Schema::Artist', 'artist_id',
    { is_foreign_key_constraint => 0 });

  __PACKAGE__->clickhouse_table({
    engine       => 'ReplacingMergeTree(ts)',
    order_by     => ['ts', 'id'],
    partition_by => 'toYYYYMM(ts)',
    settings     => { index_granularity => 8192 }
  });
}

{
  package My::CH::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';

  __PACKAGE__->register_class(Artist => 'My::CH::Schema::Artist');
  __PACKAGE__->register_class(Event  => 'My::CH::Schema::Event');
}

my $ddl = DBIO::ClickHouse::DDL->install_ddl('My::CH::Schema');
ok length $ddl, 'DDL generated';

# --- ADR 0004: nothing ClickHouse cannot parse ----------------------------
unlike $ddl, qr/FOREIGN\s+KEY/i, 'no FOREIGN KEY clause (ADR 0004)';
unlike $ddl, qr/REFERENCES/i,    'no REFERENCES clause';
unlike $ddl, qr/\bUNIQUE\b/i,    'no UNIQUE clause — ClickHouse has no unique constraint';
unlike $ddl, qr/AUTO_INCREMENT/i, 'no AUTO_INCREMENT — there is no identity column';
unlike $ddl, qr/\bNOT\s+NULL\b/i,
  'no NOT NULL constraint — nullability is expressed as Nullable(T)';

# --- every table carries an engine and a sorting key ----------------------
my @creates = $ddl =~ /^CREATE TABLE (\S+) \(/mg;
is_deeply \@creates, ['`artist`', '`event`'],
  'both tables created, in deterministic (sorted) order';

my @engines = $ddl =~ /^ENGINE = (.+)$/mg;
is scalar @engines, 2, 'every table has an ENGINE clause';
my @orders = $ddl =~ /^ORDER BY (.+)$/mg;
is scalar @orders, 2, 'every table has an ORDER BY clause';

# --- the default table: MergeTree, ORDER BY = primary key -----------------
my ($artist) = $ddl =~ /(CREATE TABLE `artist` .*?;)/s;
is $artist, <<'SQL' =~ s/\n\z//r, 'artist: default engine, sorting key from the primary key';
CREATE TABLE `artist` (
  `id` UUID DEFAULT generateUUIDv4(),
  `name` String,
  `bio` Nullable(String)
)
ENGINE = MergeTree
ORDER BY (`id`);
SQL

# --- the configured table: clickhouse_table drives every clause -----------
my ($event) = $ddl =~ /(CREATE TABLE `event` .*?;)/s;
is $event, <<'SQL' =~ s/\n\z//r, 'event: engine, partition key, sorting key and settings from clickhouse_table';
CREATE TABLE `event` (
  `id` UUID DEFAULT generateUUIDv4(),
  `artist_id` UUID,
  `ts` DateTime64(3),
  `kind` LowCardinality(String),
  `payload` Nullable(String),
  `seq` Int32 DEFAULT '0'
)
ENGINE = ReplacingMergeTree(ts)
PARTITION BY toYYYYMM(ts)
ORDER BY (`ts`, `id`)
SETTINGS index_granularity = 8192;
SQL

# --- deterministic across runs -------------------------------------------
is(DBIO::ClickHouse::DDL->install_ddl('My::CH::Schema'), $ddl,
  'install_ddl is deterministic');

# --- declared_settings: only tables that declare some (karr k30) -----------
is_deeply(DBIO::ClickHouse::DDL->declared_settings('My::CH::Schema'),
  { event => { index_granularity => 8192 } },
  'declared_settings names the tables that declare settings, and only those');

# --- a result class without the component is untouched --------------------
ok !My::CH::Schema::Artist->can('clickhouse_table'),
  'the table-options API is harmless when the Result component is not loaded';

done_testing;
