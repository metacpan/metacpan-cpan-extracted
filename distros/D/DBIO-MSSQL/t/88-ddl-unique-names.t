use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Diff::Index;

# karr k71 (ADR 0060 cases ddl-unique-constraint, ddl-unique-not-null-without-pk,
# ddl-index-on-unique-columns).
#
# WHY: an unnamed UNIQUE (cols) gets a random name (UQ__t__<hash>) from the
# server in every database it is installed into; the live database and the
# temp database of the diff then hold two different indexes and the diff
# between them is never empty. And an index declared over the columns of a
# unique constraint is a second index for the same lookups.

{
  package UqDdl::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');

  package UqDdl::Schema::Result::Pair;
  use base 'DBIO::Core';
  __PACKAGE__->table('pair');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    a  => { data_type => 'integer' },
    b  => { data_type => 'integer' },
    c  => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(pair_ab => [qw(a b)]);
  # undeclared name: core's <table>_<columns>
  __PACKAGE__->add_unique_constraint([qw(c)]);
  my $src = __PACKAGE__->result_source_instance;
  $src->add_index_declaration({ name => 'dup_plain',   columns => [qw(a b)] });
  $src->add_index_declaration({ name => 'dup_unique',  columns => [qw(a b)], unique => 1 });
  $src->add_index_declaration({ name => 'dup_pk',      columns => ['id'] });
  $src->add_index_declaration({ name => 'rev_order',   columns => [qw(b a)] });
  $src->add_index_declaration({ name => 'part',        columns => ['a'] });

  package UqDdl::Schema::Result::Loose;
  use base 'DBIO::Core';
  __PACKAGE__->table('loose');
  __PACKAGE__->add_columns(code => { data_type => 'varchar', size => 20 });
  __PACKAGE__->add_unique_constraint(loose_ux => ['code']);
  # on the table without a primary key: with one, the key is the clustered
  # index already and the declaration is refused (Msg 1902; t/96)
  __PACKAGE__->result_source_instance->add_index_declaration({
    name => 'clust_on_uq', columns => ['code'], unique => 1,
    driver => { mssql => { kind => 'clustered' } } });
}
UqDdl::Schema->register_class(Pair  => 'UqDdl::Schema::Result::Pair');
UqDdl::Schema->register_class(Loose => 'UqDdl::Schema::Result::Loose');

my $ddl = DBIO::MSSQL::DDL->install_ddl('UqDdl::Schema');

like $ddl, qr/CONSTRAINT pair_ab UNIQUE \(a, b\)/, 'the declared name is the constraint name';
like $ddl, qr/CONSTRAINT UQ_pair_c UNIQUE \(c\)/,
  'an undeclared name, core\'s <table>_<columns>, gets the prefix UQ_ (t/94: a table can have that name), deterministic';
like $ddl, qr/CONSTRAINT loose_ux UNIQUE \(code\)/, 'a table without primary key too';
unlike $ddl, qr/^\s+UNIQUE \(/m, 'no unnamed UNIQUE is written';

my %idx = map { /INDEX (\S+) ON/ ? ($1 => $_) : () } split /\n+/, $ddl;
ok !exists $idx{dup_plain},  'a plain index over the columns of a unique constraint is not written';
ok !exists $idx{dup_unique}, 'nor is a unique one';
ok !exists $idx{dup_pk},     'nor one over the primary key';
ok exists $idx{rev_order},   'other column order is another index';
ok exists $idx{part},        'a prefix of the columns is another index';
like $idx{clust_on_uq}, qr/CREATE UNIQUE CLUSTERED INDEX clust_on_uq ON loose \(code\)/,
  'a clustered one is another object (physical order) and is written';

# the diff of two databases that both hold the named constraint is empty:
# the index the server keeps for it is read by name, with is_unique
my $model = sub { { pair => { pair_ab => { is_unique => 1, kind => 'nonclustered', columns => [qw(a b)] } } } };
is scalar(() = DBIO::MSSQL::Diff::Index->diff($model->(), $model->())), 0,
  'same name on both sides: no CREATE INDEX / DROP INDEX';
my @ops = DBIO::MSSQL::Diff::Index->diff(
  { pair => { 'UQ__pair__A1' => { is_unique => 1, kind => 'nonclustered', columns => [qw(a b)] } } },
  $model->());
is scalar(@ops), 2, 'the random server names (the old defect) would diff';

# SQL Server holds constraint names once per schema
{
  package UqDdl2::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');
  package UqDdl2::Schema::Result::One;
  use base 'DBIO::Core';
  __PACKAGE__->table('one');
  __PACKAGE__->add_columns(a => { data_type => 'integer' });
  __PACKAGE__->add_unique_constraint(same => ['a']);
  package UqDdl2::Schema::Result::Two;
  use base 'DBIO::Core';
  __PACKAGE__->table('two');
  __PACKAGE__->add_columns(a => { data_type => 'integer' });
  __PACKAGE__->add_unique_constraint(same => ['a']);
}
UqDdl2::Schema->register_class(One => 'UqDdl2::Schema::Result::One');
UqDdl2::Schema->register_class(Two => 'UqDdl2::Schema::Result::Two');
eval { DBIO::MSSQL::DDL->install_ddl('UqDdl2::Schema') };
like $@, qr/unique constraint 'same'.*another table/, 'the same constraint name on two tables is refused';

done_testing;
