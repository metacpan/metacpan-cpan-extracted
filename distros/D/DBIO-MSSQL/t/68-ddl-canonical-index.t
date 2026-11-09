use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::DDL;

# karr k66 (core k333, ADR 0061): idx and indices write the index declaration
# canonically onto the result source. install_ddl used to read only
# mssql_indexes, so a Cake class with idx got its CREATE TABLE and no index,
# silently. Deploy builds the target model of the diff through install_ddl
# (DBIO::MSSQL::Deploy::_ddl_class), so the statements asserted here are the
# ones an upgrade creates.

sub index_stmts {
  my ($schema) = @_;
  my $ddl = DBIO::MSSQL::DDL->install_ddl($schema);
  my %by_name;
  for my $stmt (split /\n\n/, $ddl) {
    next unless $stmt =~ /^CREATE\b.*?\bINDEX\s+(\S+)\s/;
    (my $n = $1) =~ s/^\W+|\W+$//g;
    $by_name{$n} = $stmt;
  }
  return \%by_name;
}

{
  package CanonIdx::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');
}
{
  package CanonIdx::Schema::Result::Doc;
  use DBIO::Cake;
  __PACKAGE__->load_components('MSSQL::Result');

  table 'docs';
  col id   => integer auto_inc;
  col name => varchar(64);
  col slug => varchar(64);
  primary_key 'id';

  idx idx_name   => ['name'];
  idx idx_slug_u => ['slug'], type => 'unique';
  idx idx_nonc   => ['slug', 'name'], mssql => {};
  __PACKAGE__->indices(idx_ind => ['slug']);

  # Hand-declared, no canonical twin: stays valid.
  __PACKAGE__->mssql_index(idx_hand => { columns => ['slug'] });
  # Hand-declared and canonical under one name: canonical wins.
  __PACKAGE__->mssql_index(idx_both => { columns => ['slug'], unique => 1 });
  idx idx_both => ['name'];
}
{
  # A clustered index goes on a table without a primary key: the key is
  # CLUSTERED itself and the server allows one per table (karr k71, Msg 1902;
  # t/96, t/98). Was on Doc, which has a primary key.
  package CanonIdx::Schema::Result::Heap;
  use DBIO::Cake;
  __PACKAGE__->load_components('MSSQL::Result');

  table 'heap';
  col name => varchar(64);
  col slug => varchar(64);
  # Cake's idx does not yet list 'kind' as a key of the mssql block (core
  # %IDX_DRIVER_KEYS has no mssql entry), so the clustered one goes through
  # the declaration the helper reads, as idx would write it.
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'idx_clust', columns => ['name', 'slug'],
    driver => { mssql => { kind => 'clustered' } },
  });
}
CanonIdx::Schema->register_class(Doc => 'CanonIdx::Schema::Result::Doc');
CanonIdx::Schema->register_class(Heap => 'CanonIdx::Schema::Result::Heap');

my $i = index_stmts('CanonIdx::Schema');

like $i->{idx_name}, qr/^CREATE INDEX \W*idx_name\W* ON \W*docs\W* \(\W*name\W*\);$/,
  'idx without options produces a CREATE INDEX in install_ddl';
like $i->{idx_slug_u}, qr/^CREATE UNIQUE INDEX \W*idx_slug_u\W* ON \W*docs\W* \(\W*slug\W*\);$/,
  "type => 'unique' renders CREATE UNIQUE INDEX";
like $i->{idx_clust}, qr/^CREATE CLUSTERED INDEX \W*idx_clust\W* ON \W*heap\W* \(\W*name\W*, \W*slug\W*\);$/,
  "mssql => { kind => 'clustered' } renders CLUSTERED";
like $i->{idx_nonc}, qr/^CREATE INDEX \W*idx_nonc\W* ON \W*docs\W* \(/,
  'an empty mssql block is the plain index';
like $i->{idx_ind}, qr/^CREATE INDEX \W*idx_ind\W* ON/, 'indices produces a CREATE INDEX too';
like $i->{idx_hand}, qr/^CREATE INDEX \W*idx_hand\W* ON/,
  'a hand-declared mssql_index stays valid';
unlike $i->{idx_both}, qr/UNIQUE/, 'on the same name the canonical declaration wins';
like $i->{idx_both}, qr/\(\W*name\W*\)/, 'the canonical columns are written';

sub refused {
  my ($tag, $decl) = @_;
  my $schema = "CanonRef::$tag";
  eval qq{
    package $schema; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL');
    package ${schema}::Result::Doc; use DBIO 'Core';
    __PACKAGE__->table('docs');
    __PACKAGE__->add_columns(id => { data_type => 'integer' },
      name => { data_type => 'varchar', size => 64 });
    __PACKAGE__->set_primary_key('id');
    1;
  } or die $@;
  "${schema}::Result::Doc"->result_source_instance->add_index_declaration($decl);
  $schema->register_class(Doc => "${schema}::Result::Doc");
  eval { DBIO::MSSQL::DDL->install_ddl($schema) };
  return $@;
}

like refused(Unknown => { name => 'bad_key', columns => ['name'],
    driver => { mssql => { include => ['slug'] } } }),
  qr/bad_key.*include/s, 'an unknown key (include) in the own block is refused, naming index and key';

like refused(Foreign => { name => 'only_pg', columns => ['name'],
    driver => { pg => { where => 'name is not null' } } }),
  qr/only_pg.*'pg'.*none for 'mssql'/s, 'an entry with only a foreign driver block is refused';

like refused(BadKind => { name => 'bad_kind', columns => ['name'],
    driver => { mssql => { kind => 'columnstore' } } }),
  qr/bad_kind.*invalid kind 'columnstore'/s, 'an invalid kind is refused';

# ADR 0061: type (other than unique) and options have no counterpart here;
# they were dropped silently and a plainer index written.
like refused(TypeFt => { name => 'ft_idx', columns => ['name'], type => 'fulltext' }),
  qr/ft_idx.*type 'fulltext'/s, 'an index type other than unique is refused, naming index and type';

like refused(Opts => { name => 'opt_idx', columns => ['name'], options => { fillfactor => 70 } }),
  qr/opt_idx.*options/s, 'index options are refused, naming the index';

is refused(TypeUniq => { name => 'u_idx', columns => ['name'], type => 'unique', unique => 1 }),
  '', 'type unique stays valid';

done_testing;
