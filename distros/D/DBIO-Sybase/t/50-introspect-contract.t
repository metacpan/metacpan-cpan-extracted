use strict;
use warnings;
use Test::More;

# Offline contract coverage for DBIO::Sybase::Introspect. No live server:
# a fixture subclass feeds a native-shaped model (the hashref that
# Introspect/{Tables,Columns,Indexes,ForeignKeys} produce) and we assert the
# 7 normalized contract methods + view_definition expose it correctly for
# DBIO::Generate.

use_ok 'DBIO::Sybase::Introspect';

# --- Fixture: a Sybase introspector with a canned native model ----------
{
  package Test::Sybase::Introspect::Fixture;
  use base 'DBIO::Sybase::Introspect';

  sub _build_model {
    my %tables = (
      artist => { table_name => 'artist', kind => 'table',  schema => 'dbo' },
      cd     => { table_name => 'cd',     kind => 'table',  schema => 'dbo' },
      track  => { table_name => 'track',  kind => 'table',  schema => 'dbo' },
      myview => { table_name => 'myview', kind => 'view',   schema => 'dbo' },
    );

    my %columns = (
      artist => [
        { column_name => 'id',   data_type => 'int',     not_null => 1,
          default_value => undef,      is_pk => 1, pk_position => 1,
          is_auto_increment => 1 },
        { column_name => 'name', data_type => 'varchar', not_null => 1,
          default_value => "'Unknown'", is_pk => 0, pk_position => 0 },
      ],
      cd => [
        { column_name => 'id',        data_type => 'int',     not_null => 1,
          default_value => undef, is_pk => 1, pk_position => 1 },
        { column_name => 'artist_id', data_type => 'int',     not_null => 1,
          default_value => undef, is_pk => 0, pk_position => 0 },
        { column_name => 'title',     data_type => 'varchar', not_null => 0,
          default_value => undef, is_pk => 0, pk_position => 0 },
      ],
      # composite PK to exercise pk_position ordering
      track => [
        { column_name => 'cd_id',    data_type => 'int', not_null => 1,
          default_value => undef, is_pk => 1, pk_position => 2 },
        { column_name => 'position', data_type => 'int', not_null => 1,
          default_value => undef, is_pk => 1, pk_position => 1 },
        { column_name => 'title',    data_type => 'varchar', not_null => 0,
          default_value => undef, is_pk => 0, pk_position => 0 },
      ],
      myview => [
        { column_name => 'id', data_type => 'int', not_null => 1,
          default_value => undef, is_pk => 0, pk_position => 0 },
      ],
    );

    my %indexes = (
      artist => {
        # backs the PK -- must be filtered out of table_uniq_info
        artist_pk  => { index_name => 'artist_pk',  is_unique => 1, columns => ['id'],
                        origin => 'pk' },
        artist_uq  => { index_name => 'artist_uq',  is_unique => 1, columns => ['name'] },
      },
      cd => {
        cd_pk        => { index_name => 'cd_pk',        is_unique => 1, columns => ['id'],
                          origin => 'pk' },
        cd_artist_ix => { index_name => 'cd_artist_ix', is_unique => 0, columns => ['artist_id'] },
      },
    );

    my %fks = (
      cd => [
        { from_columns => ['artist_id'],  to_table => 'artist',
          to_columns => ['id'],
          on_update => 'CASCADE',   on_delete => 'RESTRICT' },
      ],
      # composite FK -- single entry, two column pairs
      track => [
        { from_columns => ['cd_id', 'position'], to_table => 'cd',
          to_columns => ['id', 'seq'],
          on_update => 'NO ACTION', on_delete => 'CASCADE' },
      ],
    );

    return {
      tables       => \%tables,
      columns      => \%columns,
      indexes      => \%indexes,
      foreign_keys => \%fks,
    };
  }

  # Stub dbh for view_definition's selectrow_array.
  sub dbh { $_[0]->{dbh} //= bless {}, 'Test::Sybase::MockDBH' }

  package Test::Sybase::MockDBH;
  sub selectrow_array {
    my ($self, $sql, $attr, $schema, $table) = @_;
    return '  SELECT id FROM artist ;  ' if $table eq 'myview';
    return undef;
  }
}

my $fx = Test::Sybase::Introspect::Fixture->new;

# --- contract methods all present ---------------------------------------
my @contract = qw(
  table_keys table_columns table_columns_info table_pk_info
  table_uniq_info table_fk_info table_is_view view_definition
);
ok( DBIO::Sybase::Introspect->can($_), "Introspect can $_" ) for @contract;

# --- table_keys ---------------------------------------------------------
is_deeply $fx->table_keys, [qw/artist cd myview track/],
  'table_keys: sorted, includes view';

# --- table_columns (ordinal order preserved) ----------------------------
is_deeply $fx->table_columns('cd'), [qw/id artist_id title/], 'table_columns order';
is_deeply $fx->table_columns('nope'), [], 'table_columns: unknown table -> []';

# --- table_columns_info -------------------------------------------------
my $ci = $fx->table_columns_info('cd');
is $ci->{id}{data_type},   'int',     'columns_info data_type';
is $ci->{id}{is_nullable}, 0,         'columns_info not-null -> is_nullable 0';
is $ci->{title}{is_nullable}, 1,      'columns_info nullable -> is_nullable 1';
my $ai = $fx->table_columns_info('artist');
is $ai->{name}{default_value}, "'Unknown'", 'columns_info default_value passthrough';
is $ai->{id}{is_auto_increment}, 1, 'identity column -> is_auto_increment';
ok !exists $ai->{name}{is_auto_increment}, 'non-identity column omits is_auto_increment';

# --- table_pk_info ------------------------------------------------------
is_deeply $fx->table_pk_info('cd'), [qw/id/], 'pk single';
is_deeply $fx->table_pk_info('track'), [qw/position cd_id/],
  'pk composite ordered by pk_position';
is_deeply $fx->table_pk_info('myview'), [], 'pk none';

# --- table_uniq_info (PK-backing index excluded) ------------------------
my $artist_uq = $fx->table_uniq_info('artist');
is scalar(@$artist_uq), 1, 'artist: one unique (pk index filtered)';
is $artist_uq->[0][0], 'artist_uq', 'unique constraint name';
is_deeply $artist_uq->[0][1], ['name'], 'unique constraint columns';

my $cd_uq = $fx->table_uniq_info('cd');
is scalar(@$cd_uq), 0, 'cd: no unique (pk filtered, non-unique ignored)';

# --- table_fk_info (per-column rows grouped per constraint) -------------
my $cd_fk = $fx->table_fk_info('cd');
is scalar(@$cd_fk), 1, 'cd: one FK';
is_deeply $cd_fk->[0]{local_columns},  ['artist_id'], 'cd FK local';
is $cd_fk->[0]{remote_table}, 'artist', 'cd FK remote table';
is_deeply $cd_fk->[0]{remote_columns}, ['id'], 'cd FK remote cols';
is $cd_fk->[0]{attrs}{on_delete}, 'RESTRICT', 'cd FK on_delete';
is $cd_fk->[0]{attrs}{on_update}, 'CASCADE',  'cd FK on_update';

my $track_fk = $fx->table_fk_info('track');
is scalar(@$track_fk), 1, 'track: composite FK collapses to one constraint';
is_deeply $track_fk->[0]{local_columns},  [qw/cd_id position/], 'composite FK local cols';
is_deeply $track_fk->[0]{remote_columns}, [qw/id seq/],         'composite FK remote cols';

is_deeply $fx->table_fk_info('artist'), [], 'no FK -> []';

# --- table_is_view ------------------------------------------------------
is $fx->table_is_view('artist'), 0, 'table is not a view';
is $fx->table_is_view('myview'), 1, 'view is a view';

# --- view_definition (trimmed; non-views -> undef) ----------------------
is $fx->view_definition('myview'), 'SELECT id FROM artist',
  'view_definition trimmed of whitespace + trailing semicolon';
is $fx->view_definition('artist'), undef, 'non-view view_definition undef';

# --- optional: generate-via-introspect (only if DBIO::Generate present) -
SKIP: {
  eval { require DBIO::Generate; 1 }
    or skip 'DBIO::Generate not installed', 3;
  require File::Temp;
  my $dir = File::Temp::tempdir(CLEANUP => 1);

  my $gen = DBIO::Generate->new(
    schema_class   => 'TestSybase::Schema',
    dump_directory => $dir,
    style          => 'vanilla',
    use_namespaces => 1,
    generate_pod   => 0,
    quiet          => 1,
  );
  $gen->dump($fx);

  ok -f "$dir/TestSybase/Schema/Result/Artist.pm", 'Artist.pm generated';
  ok -f "$dir/TestSybase/Schema/Result/Cd.pm",     'Cd.pm generated';
  ok -f "$dir/TestSybase/Schema/Result/Myview.pm", 'Myview.pm generated';
}

done_testing;
