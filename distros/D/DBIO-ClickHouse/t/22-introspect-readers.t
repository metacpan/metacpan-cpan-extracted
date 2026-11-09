use strict;
use warnings;
use Test::More;

# t/22-introspect-readers.t — the system.* readers behind
# DBIO::ClickHouse::Introspect::_build_model, driven by a stub statement handle
# that replays canned catalog rows. No server, no DBD.
#
# Why this file exists at all, when DBIO::DuckDB has no equivalent: DuckDB has
# an embedded mode, so its live introspection test runs unconditionally and
# covers the row-to-model mapping for free. ClickHouse has none — t/20-introspect.t
# skips outright unless someone has a server and sets DBIO_TEST_CLICKHOUSE_DSN.
# Without this file the readers would ship with zero automated coverage of the
# things that are genuinely easy to get wrong: which rows get dropped, how
# ClickHouse's empty strings become undef, and where pk_position comes from
# when the database has no primary-key constraint to ask.
#
# It deliberately does NOT assert the SQL text. Whether system.tables really
# has an `engine_full` column is a question only a live server can answer;
# that is t/20-introspect.t's job.

use DBIO::ClickHouse::Introspect;

# --- stub dbh: hands back canned rows per system.* table -------------------
package StubSth;
sub new { my ($class, $rows) = @_; bless { rows => [@$rows] }, $class }
sub execute { 1 }
sub fetchrow_hashref { shift @{ $_[0]{rows} } }

package StubDbh;
sub new { my ($class, %data) = @_; bless {%data}, $class }
sub prepare {
  my ($self, $sql) = @_;
  return StubSth->new($self->{tables}  || []) if $sql =~ /system\.tables/;
  return StubSth->new($self->{columns} || []) if $sql =~ /system\.columns/;
  die "no such table: system.data_skipping_indices\n"
    unless exists $self->{indices};
  return StubSth->new($self->{indices}) if $sql =~ /system\.data_skipping_indices/;
  die "unexpected query: $sql";
}

package main;

my %CATALOG = (
  tables => [
    { name => 'event', database => 'default', engine => 'ReplacingMergeTree',
      engine_full => 'ReplacingMergeTree(ver) PARTITION BY toYYYYMM(ts) '
                   . 'ORDER BY (ts, id) SETTINGS index_granularity = 8192',
      sorting_key => 'ts, id', primary_key => 'ts', partition_key => 'toYYYYMM(ts)',
      sampling_key => '', comment => 'append-only event log' },
    { name => 'top_event', database => 'default', engine => 'View', engine_full => 'View',
      sorting_key => '', primary_key => '', partition_key => '',
      sampling_key => '', comment => '',
      create_table_query => 'CREATE VIEW default.top_event (`id` UUID) AS SELECT id FROM default.event' },
  ],
  columns => [
    { table => 'event', name => 'ts', type => 'DateTime64(3)', position => 1,
      default_kind => '', default_expression => '', compression_codec => '',
      comment => '', is_in_sorting_key => 1, is_in_partition_key => 1 },
    { table => 'event', name => 'id', type => 'UUID', position => 2,
      default_kind => 'DEFAULT', default_expression => 'generateUUIDv4()',
      compression_codec => '', comment => 'surrogate key',
      is_in_sorting_key => 1, is_in_partition_key => 0 },
    { table => 'event', name => 'name', type => 'LowCardinality(Nullable(String))',
      position => 3, default_kind => '', default_expression => '',
      compression_codec => 'CODEC(ZSTD(1))', comment => '',
      is_in_sorting_key => 0, is_in_partition_key => 0 },
    # A row for a table system.tables did not surface (dropped between the two
    # queries, or filtered by a grant). It must not reach the model.
    { table => 'ghost', name => 'x', type => 'Int8', position => 1,
      default_kind => '', default_expression => '', compression_codec => '',
      comment => '', is_in_sorting_key => 0, is_in_partition_key => 0 },
  ],
  indices => [
    { table => 'event', name => 'event_ver_minmax', type => 'minmax',
      type_full => 'minmax', expr => 'ver', granularity => 4 },
  ],
);

my $intro = DBIO::ClickHouse::Introspect->new(dbh => StubDbh->new(%CATALOG));
my $model = $intro->model;

# --- tables ----------------------------------------------------------------
is_deeply [ sort keys %{ $model->{tables} } ], [qw/event top_event/], 'both tables read';

my $event = $model->{tables}{event};
is $event->{kind}, 'table',    'the MergeTree engine makes it a table';
is $model->{tables}{top_event}{kind}, 'view', 'the View engine makes it a view';
is $event->{engine}, 'ReplacingMergeTree', 'bare engine name kept';
is $event->{engine_expression}, 'ReplacingMergeTree(ver)',
  'engine arguments recovered from engine_full — system.tables.engine drops them';
is_deeply $event->{sorting_key_entries}, [qw/ts id/], 'sorting key split';
is_deeply $event->{primary_key_entries}, ['ts'],      'declared PRIMARY KEY prefix kept apart';
is_deeply $event->{primary_key_columns}, ['ts'],      'and reduced to bare column names';
is_deeply $event->{partition_key_entries}, ['toYYYYMM(ts)'], 'partition key split';

# a view carries what it selects, as the server holds it; a table has none
is $model->{tables}{top_event}{definition}, 'SELECT id FROM default.event',
  'a view carries its SELECT, cut out of create_table_query (the diff compares it)';
ok !exists $event->{definition}, '... and a table carries none';

# An engine without a key reports empty strings, not NULL.
is_deeply $model->{tables}{top_event}{primary_key_entries}, [],
  'an empty key string yields an empty entry list';

# --- columns ---------------------------------------------------------------
ok !exists $model->{columns}{ghost},
  'a column whose table system.tables did not surface is dropped';

is_deeply $intro->table_columns('event'), [qw/ts id name/],
  'columns in system.columns position order';

# There is no primary-key constraint to read: pk_position comes from the
# position of the column in the MergeTree key.
is_deeply $intro->table_pk_info('event'), ['ts'],
  'primary key derived from the MergeTree key, not from a constraint';
is $model->{columns}{event}[1]{is_pk}, 0,
  'id sorts but is not in the declared PRIMARY KEY prefix';

is $model->{columns}{event}[0]{not_null}, 1,
  'a bare type is NOT NULL — ClickHouse columns are not nullable by default';
is $model->{columns}{event}[2]{not_null}, 0,
  'Nullable nested inside LowCardinality still makes the column nullable';

# ClickHouse returns '' rather than NULL for "absent" in these String columns.
is $model->{columns}{event}[0]{default_value}, undef, 'empty default folded to undef';
is $model->{columns}{event}[0]{default_kind},  undef, 'empty default_kind folded to undef';
is $model->{columns}{event}[0]{comment},       undef, 'empty comment folded to undef';
is $model->{columns}{event}[2]{compression_codec}, 'CODEC(ZSTD(1))', 'codec kept when set';
is $intro->column_comment('event', 'id'), 'surrogate key', 'column comment reachable';
is $intro->table_comment('top_event'), undef, 'empty table comment folded to undef';

# --- data-skipping indexes -------------------------------------------------
is $model->{data_skipping_indexes}{event}{event_ver_minmax}{granularity}, 4,
  'skipping index read into its own section';
is_deeply $model->{indexes}, {},
  'the canonical indexes section stays empty — a skipping index is not one';
is_deeply $model->{foreign_keys}, {}, 'and there are no foreign keys (ADR 0004)';

# system.data_skipping_indices is missing on pre-20.x servers and can be hidden
# by grants; neither may take the whole introspection down with it.
my %no_indices = %CATALOG;
delete $no_indices{indices};
my $degraded = DBIO::ClickHouse::Introspect->new(dbh => StubDbh->new(%no_indices))->model;
is_deeply $degraded->{data_skipping_indexes}, {},
  'an unavailable system.data_skipping_indices degrades to no indexes, not a die';
ok exists $degraded->{tables}{event}, 'and the rest of the model is still built';

done_testing;
