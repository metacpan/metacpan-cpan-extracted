#!/usr/bin/env perl
# t/21-introspect-contract.t — the normalized DBIO::Introspect::Base contract
# implemented by DBIO::DuckDB::Introspect. Offline: the model is injected
# directly, no live DuckDB needed.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Introspect;

package DBIO::DuckDB::Introspect::Mock;
use base 'DBIO::DuckDB::Introspect';
sub new {
  my ($class, %args) = @_;
  my $self = bless { %args }, $class;
  $self->{model} = $args{model};
  return $self;
}
sub _build_model { die "should not be called" }

package main;

my $MODEL = {
  tables => {
    artist => { table_name => 'artist', kind => 'table', schema => 'main' },
    cd     => { table_name => 'cd',     kind => 'table', schema => 'main' },
    top_cd => { table_name => 'top_cd', kind => 'view',  schema => 'main' },
  },
  columns => {
    artist => [
      { column_name => 'artistid', data_type => 'INTEGER', not_null => 1,
        default_value => q{nextval('artist_artistid_seq')}, is_pk => 1, pk_position => 1 },
      { column_name => 'name', data_type => 'VARCHAR(100)', not_null => 0,
        default_value => undef, is_pk => 0, pk_position => 0 },
      { column_name => 'rank', data_type => 'INTEGER', not_null => 1,
        default_value => '0', is_pk => 0, pk_position => 0 },
      { column_name => 'score', data_type => 'DECIMAL(10,2)', not_null => 0,
        default_value => undef, is_pk => 0, pk_position => 0 },
      { column_name => 'created', data_type => 'TIMESTAMP', not_null => 0,
        default_value => 'CURRENT_TIMESTAMP', is_pk => 0, pk_position => 0 },
    ],
    cd => [
      { column_name => 'cdid', data_type => 'INTEGER', not_null => 1,
        default_value => undef, is_pk => 1, pk_position => 1 },
      { column_name => 'artistid', data_type => 'INTEGER', not_null => 1,
        default_value => undef, is_pk => 0, pk_position => 0 },
      { column_name => 'title', data_type => 'VARCHAR', not_null => 1,
        default_value => q{'untitled'}, is_pk => 0, pk_position => 0 },
    ],
  },
  indexes => {
    cd => {
      cd_title_uniq => { index_name => 'cd_title_uniq', is_unique => 1,
        columns => ['title'], partial => 0 },
      cd_artist_idx => { index_name => 'cd_artist_idx', is_unique => 0,
        columns => ['artistid'], partial => 0 },
      cd_partial_uniq => { index_name => 'cd_partial_uniq', is_unique => 1,
        columns => ['title'], partial => 1 },
    },
  },
  foreign_keys => {
    cd => [
      { fk_id => 'cd_artistid_fkey', from_columns => ['artistid'],
        to_table => 'artist', to_columns => ['artistid'],
        on_update => 'NO ACTION', on_delete => 'CASCADE', match => 'NONE' },
    ],
  },
};

my $intro = DBIO::DuckDB::Introspect::Mock->new(model => $MODEL);

# table_keys
is_deeply $intro->table_keys, [qw/artist cd top_cd/], 'table_keys sorted';

# table_columns
is_deeply $intro->table_columns('artist'),
  [qw/artistid name rank score created/], 'table_columns ordered';

# table_pk_info
is_deeply $intro->table_pk_info('artist'), ['artistid'], 'artist pk';
is_deeply $intro->table_pk_info('cd'),     ['cdid'],     'cd pk';

# table_is_view
ok !$intro->table_is_view('artist'), 'artist is not a view';
ok  $intro->table_is_view('top_cd'), 'top_cd is a view';

# table_columns_info
my $info = $intro->table_columns_info('artist');

is $info->{artistid}{data_type}, 'integer', 'artistid type normalized';
is $info->{artistid}{is_nullable}, 0,        'artistid not nullable';
ok $info->{artistid}{is_auto_increment},     'artistid auto-increment from nextval';
is $info->{artistid}{sequence}, 'artist_artistid_seq', 'sequence captured';
ok $info->{artistid}{retrieve_on_insert},    'auto-increment pk retrieved on insert';

is $info->{name}{data_type}, 'varchar', 'name type';
is $info->{name}{size}, 100,            'name size parsed';
is $info->{name}{is_nullable}, 1,       'name nullable';

is $info->{rank}{default_value}, '0',   'numeric default kept';

is $info->{score}{data_type}, 'decimal', 'decimal type';
is_deeply $info->{score}{size}, [10, 2], 'decimal precision/scale';

is ref $info->{created}{default_value}, 'SCALAR', 'function default is literal ref';
is ${ $info->{created}{default_value} }, 'CURRENT_TIMESTAMP', 'CURRENT_TIMESTAMP literal';

my $cd_info = $intro->table_columns_info('cd');
is $cd_info->{title}{default_value}, 'untitled', 'string default unquoted';
ok !$cd_info->{cdid}{retrieve_on_insert}, 'pk without default not flagged retrieve_on_insert';

# table_uniq_info — partial unique excluded
is_deeply $intro->table_uniq_info('cd'),
  [ [ cd_title_uniq => ['title'] ] ], 'uniq excludes partial + non-unique';

# table_fk_info
my $fks = $intro->table_fk_info('cd');
is scalar @$fks, 1, 'one fk on cd';
is_deeply $fks->[0]{local_columns},  ['artistid'], 'fk local cols';
is $fks->[0]{remote_table}, 'artist',              'fk remote table';
is_deeply $fks->[0]{remote_columns}, ['artistid'], 'fk remote cols';
is $fks->[0]{remote_schema}, undef,                'fk remote schema undef';
is $fks->[0]{attrs}{on_delete}, 'CASCADE',         'fk on_delete';

done_testing;
