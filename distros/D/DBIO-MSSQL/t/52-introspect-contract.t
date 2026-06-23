use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Introspect;

# Offline test of the DBIO::Introspect::Base normalized contract methods.
# The native model is injected directly (Introspect::Base->model returns a
# pre-set {model} without touching a dbh), so no database is needed.

my $model = {
  tables => {
    artist      => { kind => 'table', schema => 'dbo' },
    cd          => { kind => 'table', schema => 'dbo' },
    artist_list => { kind => 'view',  schema => 'dbo' },
  },
  columns => {
    artist => [
      { column_name => 'artistid', data_type => 'int', not_null => 1,
        default_value => undef, is_pk => 1, pk_position => 1,
        is_identity => 1, is_auto_increment => 1, size => undef },
      { column_name => 'name', data_type => 'nvarchar', not_null => 1,
        default_value => "'Unknown'", is_pk => 0, pk_position => 0,
        is_identity => 0, is_auto_increment => 0, size => 128 },
    ],
    cd => [
      { column_name => 'cdid', data_type => 'int', not_null => 1,
        is_pk => 1, pk_position => 1, is_identity => 1, is_auto_increment => 1, size => undef },
      { column_name => 'artistid', data_type => 'int', not_null => 1,
        is_pk => 0, pk_position => 0, is_identity => 0, is_auto_increment => 0, size => undef },
      { column_name => 'title', data_type => 'nvarchar', not_null => 0,
        is_pk => 0, pk_position => 0, is_identity => 0, is_auto_increment => 0, size => 256 },
    ],
    artist_list => [
      { column_name => 'artistid', data_type => 'int', not_null => 1,
        is_pk => 0, pk_position => 0, is_identity => 0, is_auto_increment => 0, size => undef },
    ],
  },
  indexes => {
    # DBIO::MSSQL::Introspect::Indexes filters out PK-backed indexes
    # (is_primary_key = 0), so the model never carries the PK index and
    # table_uniq_info cannot double-report the primary key.
    artist => {
      uq_artist_name => { is_unique => 1, columns => ['name'], kind => 'nonclustered' },
      ix_artist_name => { is_unique => 0, columns => ['name'], kind => 'nonclustered' },
    },
  },
  foreign_keys => {
    cd => [
      { constraint_name => 'FK_cd_artist', from_columns => ['artistid'],
        to_table => 'artist', to_columns => ['artistid'],
        on_delete => 'CASCADE', on_update => 'NO ACTION' },
    ],
  },
};

my $intro = DBIO::MSSQL::Introspect->new(model => $model);

# --- table_keys ---
is_deeply($intro->table_keys, [qw/artist artist_list cd/], 'table_keys sorted');

# --- table_columns ---
is_deeply($intro->table_columns('artist'), [qw/artistid name/], 'table_columns ordered');
is_deeply($intro->table_columns('nope'), [], 'table_columns unknown key -> []');

# --- table_columns_info ---
my $ci = $intro->table_columns_info('artist');
is_deeply($ci->{artistid}, {
  data_type => 'int', is_nullable => 0,
  default_value => undef, is_auto_increment => 1,
}, 'columns_info: identity column (size omitted when undef)');
is_deeply($ci->{name}, {
  data_type => 'nvarchar', size => 128, is_nullable => 0,
  default_value => "'Unknown'", is_auto_increment => 0,
}, 'columns_info: sized nullable-no column with default');

# --- table_pk_info ---
is_deeply($intro->table_pk_info('artist'), ['artistid'], 'pk_info artist');
is_deeply($intro->table_pk_info('cd'),     ['cdid'],     'pk_info cd');

# --- table_uniq_info (PK-backed index excluded, non-unique excluded) ---
is_deeply(
  $intro->table_uniq_info('artist'),
  [ [ 'uq_artist_name' => ['name'] ] ],
  'uniq_info: the unique index reported, non-unique index excluded',
);
is_deeply($intro->table_uniq_info('cd'), [], 'uniq_info: none for cd');

# --- table_fk_info ---
is_deeply(
  $intro->table_fk_info('cd'),
  [ {
    local_columns  => ['artistid'],
    remote_table   => 'artist',
    remote_schema  => undef,
    remote_columns => ['artistid'],
    attrs          => { on_delete => 'CASCADE', on_update => 'NO ACTION' },
  } ],
  'fk_info: normalized FK shape',
);
is_deeply($intro->table_fk_info('artist'), [], 'fk_info: none for artist');

# --- table_is_view ---
is($intro->table_is_view('artist'),      0, 'base table is not a view');
is($intro->table_is_view('artist_list'), 1, 'view is a view');

done_testing;
