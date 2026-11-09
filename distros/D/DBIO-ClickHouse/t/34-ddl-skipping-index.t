use strict;
use warnings;
use Test::More;
use Test::Exception;

# t/34-ddl-skipping-index.t -- canonical index declarations (ADR 0061 in core,
# karr k37) reach CREATE TABLE as data-skipping indexes. Offline: no DBD, no
# DSN, no server.
#
# Claims pinned here:
#
#   1. A canonical declaration with a clickhouse => { type, granularity } block
#      is rendered INLINE as `INDEX name expr TYPE t GRANULARITY n` -- there is
#      no CREATE INDEX in ClickHouse -- in the exact shape Emit::index_def
#      gives the diff.
#   2. What ClickHouse cannot say is refused LOUDLY, naming source and index,
#      never degraded to a simpler index: unique, no block, an empty block,
#      another driver's block only, a block without type, an unknown key.
#      A plain index does not exist; the TYPE is not ours to invent.
#   3. The desired side of the diff (install_ddl -> scratch database ->
#      introspect) carries the declared index, so an upgrade against a live
#      table that has it is a no-op instead of a DROP INDEX / ADD INDEX pair.

use DBIO::Schema;
use DBIO::ClickHouse::DDL;
use DBIO::ClickHouse::Diff;

# Compose a Cake class, optionally declaring more by hand through the core API
# (Cake's idx cannot carry clickhouse keys yet: its per-driver key table has no
# clickhouse entry, so only clickhouse => {} is accepted there).
my $n = 0;
sub schema_with {
  my ($declare) = @_;
  my $pkg = 'My::CH::Idx' . ++$n;
  my $code = sprintf <<'PERL', $pkg;
package %s::Result::Event;
use strict; use warnings;
use DBIO::Cake;
table 'event';
col id    => uuid;
col score => integer;
col tag   => varchar(50);
col ts    => datetime;
primary_key 'id';
1;
PERL
  eval $code or die $@;    ## no critic
  my $class = "${pkg}::Result::Event";
  $declare->($class->result_source_instance, $class) if $declare;
  { no strict 'refs'; @{"${pkg}::ISA"} = ('DBIO::Schema'); }
  $pkg->register_class(Event => $class);
  return $pkg;
}

sub ddl_for { DBIO::ClickHouse::DDL->install_ddl(schema_with(@_)) }

# --- 1. rendered inline ------------------------------------------------------
my $ddl = ddl_for(sub {
  my ($src) = @_;
  $src->add_index_declaration({
    name => 'score_idx', columns => ['score'],
    driver => { clickhouse => { type => 'minmax', granularity => 4 } },
  });
  $src->add_index_declaration({
    name => 'tag_set', columns => ['tag'],
    driver => { clickhouse => { type => 'set(100)' } },
  });
  $src->add_index_declaration({
    name => 'lower_tag', columns => ['tag'],
    driver => { clickhouse => {
      type => 'bloom_filter(0.01)', granularity => 2, expression => 'lower(tag)',
    } },
  });
  $src->add_index_declaration({
    name => 'pair', columns => [qw(score tag)],
    driver => { clickhouse => { type => 'minmax', granularity => 1 } },
  });
});

is $ddl, <<'SQL' =~ s/\n\z//r, 'declared indexes are rendered inline, after the columns, by name';
CREATE TABLE `event` (
  `id` UUID,
  `score` Int32,
  `tag` String,
  `ts` DateTime64(3),
  INDEX `lower_tag` lower(tag) TYPE bloom_filter(0.01) GRANULARITY 2,
  INDEX `pair` (`score`, `tag`) TYPE minmax GRANULARITY 1,
  INDEX `score_idx` `score` TYPE minmax GRANULARITY 4,
  INDEX `tag_set` `tag` TYPE set(100)
)
ENGINE = MergeTree
ORDER BY (`id`);
SQL
unlike $ddl, qr/^\s*CREATE\s+(?:UNIQUE\s+)?INDEX/mi, 'no standalone CREATE INDEX';

# The same fragment, character for character, as the diff renders it.
require DBIO::ClickHouse::DDL::Emit;
is DBIO::ClickHouse::DDL::Emit::index_def({
     index_name => 'score_idx', expr => '`score`',
     type_full => 'minmax', granularity => 4 }),
  'INDEX `score_idx` `score` TYPE minmax GRANULARITY 4',
  'inline form is Emit::index_def';

# --- 1b. the Cake idx / indices spelling -------------------------------------
# Cake's idx is the canonical route; with an empty clickhouse block it says
# "the plain index" -- which ClickHouse does not have.
{
  my $pkg = 'My::CH::CakeIdx' . ++$n;
  eval <<"PERL" or die $@;    ## no critic
package ${pkg}::Result::Event;
use strict; use warnings;
use DBIO::Cake;
table 'event';
col id    => uuid;
col score => integer;
primary_key 'id';
idx score_idx => ['score'], clickhouse => {};
1;
PERL
  { no strict 'refs'; @{"${pkg}::ISA"} = ('DBIO::Schema'); }
  $pkg->register_class(Event => "${pkg}::Result::Event");
  throws_ok { DBIO::ClickHouse::DDL->install_ddl($pkg) }
    qr/Event.*index 'score_idx'.*no clickhouse => \{ type/s,
    'Cake idx with an empty clickhouse block is refused (no plain index)';
}

# --- 2. indices: carries no driver block -> a plain index -> refused ---------
{
  my $pkg = 'My::CH::Indices' . ++$n;
  eval <<"PERL" or die $@;    ## no critic
package ${pkg}::Result::Event;
use strict; use warnings;
use base 'DBIO::Core';
__PACKAGE__->table('event');
__PACKAGE__->add_columns(id => { data_type => 'uuid' }, score => { data_type => 'integer' });
__PACKAGE__->set_primary_key('id');
__PACKAGE__->indices({ score_idx => 'score' });
1;
PERL
  { no strict 'refs'; @{"${pkg}::ISA"} = ('DBIO::Schema'); }
  $pkg->register_class(Event => "${pkg}::Result::Event");
  throws_ok { DBIO::ClickHouse::DDL->install_ddl($pkg) }
    qr/index 'score_idx'.*TYPE cannot be invented/s,
    'indices (plain declaration) is refused, not turned into a plain index';
}

# --- 3. refusals -------------------------------------------------------------
sub refused {
  my ($decl, $re, $label) = @_;
  throws_ok {
    ddl_for(sub { $_[0]->add_index_declaration($decl) })
  } $re, $label;
}

refused({ name => 'u', columns => ['score'], unique => 1,
          driver => { clickhouse => { type => 'minmax' } } },
  qr/Event.*index 'u'.*no unique index/s, 'unique is refused');
refused({ name => 'u', columns => ['score'], type => 'unique',
          driver => { clickhouse => { type => 'minmax' } } },
  qr/index 'u'.*no unique index/s, 'type => unique is refused');
refused({ name => 'p', columns => ['score'] },
  qr/Event.*index 'p'.*no clickhouse => \{ type/s, 'no clickhouse block is refused');
refused({ name => 'p', columns => ['score'], driver => { clickhouse => {} } },
  qr/index 'p'.*TYPE cannot be invented/s, 'empty block (the plain index) is refused');
refused({ name => 'p', columns => ['score'], driver => { pg => { using => 'gin' } } },
  qr/index 'p'.*only the 'pg' block and none for 'clickhouse'/s,
  'a foreign block only is refused');
refused({ name => 'p', columns => ['score'], driver => { clickhouse => { granularity => 3 } } },
  qr/index 'p'.*TYPE cannot be invented/s, 'block without type is refused');
refused({ name => 'p', columns => ['score'],
          driver => { clickhouse => { type => 'minmax', using => 'btree' } } },
  qr/index 'p'.*unknown key 'using'/s, 'unknown key is refused');
refused({ name => 'p', columns => ['score'],
          driver => { clickhouse => { type => 'minmax', granularity => 0 } } },
  qr/index 'p'.*granularity must be a positive integer/s, 'granularity 0 is refused');
refused({ name => 'p', columns => ['score'], options => { fillfactor => 70 },
          driver => { clickhouse => { type => 'minmax' } } },
  qr/index 'p'.*options are not expressible/s, 'generic options are refused');
refused({ name => 'p', columns => ['nope'],
          driver => { clickhouse => { type => 'minmax' } } },
  qr/index 'p'.*column 'nope' is not a column/s, 'unknown column is refused');

# --- 4. the desired model of the diff ----------------------------------------
# Test-deploy-and-compare executes install_ddl in a scratch database and
# introspects it (Deploy::Base _build_target_model). Offline that round trip
# is simulated by reading the INDEX lines back into the model shape
# Introspect::Indexes returns (the server prints expr unquoted).
sub model_from_ddl {
  my ($sql) = @_;
  my %idx;
  for my $line (split /\n/, $sql) {
    $line =~ /^\s+INDEX `(\w+)` (.+?) TYPE (\S+?)(?: GRANULARITY (\d+))?,?$/ or next;
    my ($name, $expr, $type_full, $gran) = ($1, $2, $3, $4);
    $expr =~ s/`//g;
    (my $type = $type_full) =~ s/\(.*//;
    $idx{event}{$name} = { index_name => $name, expr => $expr, type => $type,
      type_full => $type_full, granularity => $gran // 1 };
  }
  return {
    tables  => { event => { table_name => 'event', kind => 'table', engine => 'MergeTree',
      engine_expression => 'MergeTree', sorting_key_entries => ['id'],
      primary_key_entries => ['id'], partition_key => '', partition_key_entries => [] } },
    columns => { event => {} },
    data_skipping_indexes => \%idx,
  };
}

my $desired = model_from_ddl($ddl);
is_deeply [ sort keys %{ $desired->{data_skipping_indexes}{event} } ],
  [qw(lower_tag pair score_idx tag_set)],
  'the desired model carries the declared indexes';

my $live_same = model_from_ddl($ddl);
my $same = DBIO::ClickHouse::Diff->new(source => $live_same, target => $desired);
is_deeply [ grep { /INDEX/ } split /\n/, $same->as_sql ], [],
  'live table with the same indexes: no ADD INDEX / DROP INDEX';
ok !$same->has_changes, 'and no change at all';

my $live_old = model_from_ddl($ddl);
$live_old->{data_skipping_indexes}{event}{score_idx}{granularity} = 8;
delete $live_old->{data_skipping_indexes}{event}{tag_set};
my $sql = DBIO::ClickHouse::Diff->new(source => $live_old, target => $desired)->as_sql;
like $sql, qr/DROP INDEX `score_idx`/, 'a changed granularity is drop ...';
like $sql, qr/ADD INDEX `score_idx` score TYPE minmax GRANULARITY 4/,
  '... then add, in the declared shape';
like $sql, qr/ADD INDEX `tag_set` tag TYPE set\(100\)/, 'a missing index is added';

done_testing;
