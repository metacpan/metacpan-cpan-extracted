use strict;
use warnings;
use Test::More;

# Offline test of the DBIO::Introspect::Base normalized contract as implemented
# by DBIO::DB2::Introspect. No real DB2: a native-shaped model is injected
# directly (DBIO::Introspect::Base->new just blesses its args, and ->model
# returns an injected model without calling _build_model).
#
# Needs DBIO core on @INC: prove -I../dbio/lib -l t/40-introspect-contract.t

use_ok 'DBIO::DB2::Introspect';

# Native model shape produced by DBIO::DB2::Introspect::_build_model:
#   tables       => { $name  => { table_name, kind, schema } }
#   columns      => { $table => [ { column_name, data_type, not_null,
#                                   default_value, is_pk, pk_position, size } ] }
#   indexes      => { $table => { $name => { index_name, is_unique, columns } } }
#   foreign_keys => { $table => [ { constraint_name, from_table, from_columns,
#                                   to_table, to_schema, to_columns, on_update, on_delete } ] }
my $MODEL = {
  tables => {
    artist      => { table_name => 'artist',      kind => 'table', schema => 'USER' },
    cd          => { table_name => 'cd',          kind => 'table', schema => 'USER' },
    artist_list => { table_name => 'artist_list', kind => 'view',  schema => 'USER' },
    mtm         => { table_name => 'mtm',         kind => 'table', schema => 'USER' },
  },
  columns => {
    artist => [
      { column_name => 'artistid', data_type => 'INTEGER', not_null => 1, default_value => undef, is_pk => 1, pk_position => 1, size => 10, is_auto_increment => 1 },
      { column_name => 'name',     data_type => 'VARCHAR', not_null => 0, default_value => undef, is_pk => 0, pk_position => 0, size => 255 },
      { column_name => 'rank',     data_type => 'INTEGER', not_null => 0, default_value => '13',  is_pk => 0, pk_position => 0, size => 10 },
    ],
    cd => [
      { column_name => 'cdid',   data_type => 'INTEGER', not_null => 1, is_pk => 1, pk_position => 1, size => 10 },
      { column_name => 'artist', data_type => 'INTEGER', not_null => 1, is_pk => 0, pk_position => 0, size => 10 },
      { column_name => 'title',  data_type => 'VARCHAR', not_null => 0, is_pk => 0, pk_position => 0, size => 100 },
    ],
    artist_list => [
      { column_name => 'artistid', data_type => 'INTEGER', not_null => 1, is_pk => 0, pk_position => 0, size => 10 },
      { column_name => 'name',     data_type => 'VARCHAR', not_null => 0, is_pk => 0, pk_position => 0, size => 255 },
    ],
    # two-column PK inserted in reverse pk_position order, to prove sorting
    mtm => [
      { column_name => 'b', data_type => 'INTEGER', not_null => 1, is_pk => 1, pk_position => 2, size => 10 },
      { column_name => 'a', data_type => 'INTEGER', not_null => 1, is_pk => 1, pk_position => 1, size => 10 },
    ],
  },
  indexes => {
    artist => {
      PK_ARTIST       => { index_name => 'PK_ARTIST',       is_unique => 1, origin => 'pk',   columns => ['artistid'] },
      U_ARTIST_NAME   => { index_name => 'U_ARTIST_NAME',   is_unique => 1, origin => undef,  columns => ['name'] },
      IDX_ARTIST_RANK => { index_name => 'IDX_ARTIST_RANK', is_unique => 0, origin => undef,  columns => ['rank'] },
    },
  },
  foreign_keys => {
    cd => [
      {
        constraint_name => 'FK_CD_ARTIST',
        from_table   => 'cd',
        from_columns => ['artist'],
        to_table     => 'artist',
        to_schema    => 'USER',
        to_columns   => ['artistid'],
        on_update    => 'NO ACTION',
        on_delete    => 'CASCADE',
      },
    ],
  },
};

my $intro = DBIO::DB2::Introspect->new(model => $MODEL);

# --- table_keys ---
is_deeply $intro->table_keys, [qw/artist artist_list cd mtm/],
  'table_keys sorted, bare table names';

# --- table_columns (column order = colno order) ---
is_deeply $intro->table_columns('artist'), [qw/artistid name rank/],
  'table_columns in order';
is_deeply $intro->table_columns('nonesuch'), [],
  'table_columns on unknown table is empty';

# --- table_columns_info (canonical shape from DBIO::Introspect::Base default:
#     default_value always present, size when defined, is_auto_increment when set) ---
is_deeply $intro->table_columns_info('artist'), {
  artistid => { data_type => 'INTEGER', is_nullable => 0, default_value => undef, size => 10, is_auto_increment => 1 },
  name     => { data_type => 'VARCHAR', is_nullable => 1, default_value => undef, size => 255 },
  rank     => { data_type => 'INTEGER', is_nullable => 1, default_value => '13',  size => 10 },
}, 'table_columns_info: nullability, size, default, is_auto_increment';

# --- table_pk_info ---
is_deeply $intro->table_pk_info('artist'), ['artistid'], 'single-column PK';
is_deeply $intro->table_pk_info('mtm'),    ['a', 'b'],   'multi-column PK ordered by pk_position';
is_deeply $intro->table_pk_info('artist_list'), [],      'view has no PK';

# --- table_uniq_info (PK index and non-unique index both excluded) ---
is_deeply $intro->table_uniq_info('artist'),
  [ [ 'U_ARTIST_NAME' => ['name'] ] ],
  'table_uniq_info excludes PK-backing and non-unique indexes';
is_deeply $intro->table_uniq_info('cd'), [], 'no unique constraints -> empty';

# --- table_fk_info ---
is_deeply $intro->table_fk_info('cd'), [
  {
    constraint_name  => 'FK_CD_ARTIST',
    local_columns    => ['artist'],
    remote_columns   => ['artistid'],
    remote_schema    => 'USER',
    remote_table     => 'artist',
    attrs            => { on_delete => 'CASCADE', on_update => 'NO ACTION' },
  },
], 'table_fk_info shape';
is_deeply $intro->table_fk_info('artist'), [], 'no FKs -> empty';

# --- table_is_view ---
is $intro->table_is_view('artist_list'), 1, 'view detected';
is $intro->table_is_view('artist'),      0, 'table is not a view';

done_testing;
