use strict;
use warnings;
use Test::More;

use DBIO::Test;
use lib 't/lib';
use K71Fixtures qw(without_artist_constraint);
use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Diff::Table;
use DBIO::MSSQL::Diff::ForeignKey;

# karr k71 (ADR 0060 cases ddl-foreign-key, ddl-fk-actions,
# ddl-fk-two-rels-one-column, ddl-fk-table-order): install_ddl writes the
# FOREIGN KEY of every belongs_to. Deploy and diff build their target through
# install_ddl, so what is asserted here is what an upgrade creates. The diff
# creates a new table without its keys and adds them afterwards (last block;
# order in t/92, live in t/93).

{
  package FkDdl::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');

  package FkDdl::Schema::Result::ZParent;
  use base 'DBIO::Core';
  __PACKAGE__->table('z_parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
  __PACKAGE__->set_primary_key('id');
  # a second parent: two cascading keys from one table to the same parent
  # are what SQL Server refuses with Msg 1785 (t/94, t/95), so the SET NULL
  # key goes to a table of its own
  package FkDdl::Schema::Result::ZOther;
  use base 'DBIO::Core';
  __PACKAGE__->table('z_other');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
  __PACKAGE__->set_primary_key('id');
  package FkDdl::Schema::Result::AChild;
  use base 'DBIO::Core';
  __PACKAGE__->table('a_child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer' },
    other_id  => { data_type => 'integer', is_nullable => 1 },
    free_id   => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'FkDdl::Schema::Result::ZParent', 'parent_id',
    { on_delete => 'cascade', on_update => 'no action' });
  # a second relationship over the same key, same target, same actions
  __PACKAGE__->belongs_to(parent_alt => 'FkDdl::Schema::Result::ZParent', 'parent_id',
    { on_delete => 'cascade', on_update => 'no action' });
  __PACKAGE__->belongs_to(other => 'FkDdl::Schema::Result::ZOther', 'other_id',
    { on_delete => 'set null' });
  __PACKAGE__->belongs_to(free => 'FkDdl::Schema::Result::ZParent', 'free_id',
    { is_foreign_key_constraint => 0 });

}
FkDdl::Schema->register_class(AChild  => 'FkDdl::Schema::Result::AChild');
FkDdl::Schema->register_class(ZParent => 'FkDdl::Schema::Result::ZParent');
FkDdl::Schema->register_class(ZOther  => 'FkDdl::Schema::Result::ZOther');

my $ddl = DBIO::MSSQL::DDL->install_ddl('FkDdl::Schema');
my @fk  = $ddl =~ /^(ALTER TABLE .*? ADD CONSTRAINT .*)$/mg;

is(scalar @fk, 2, 'two constraints: the twin relationship is the same key, is_foreign_key_constraint 0 writes none');
like($ddl,
  qr/ALTER TABLE a_child ADD CONSTRAINT FK_a_child_parent_id FOREIGN KEY \(parent_id\) REFERENCES z_parent \(id\) ON DELETE CASCADE ON UPDATE NO ACTION;/,
  'foreign key with its declared actions, upper-cased');
like($ddl,
  qr/ADD CONSTRAINT FK_a_child_other_id FOREIGN KEY \(other_id\) REFERENCES z_other \(id\) ON DELETE SET NULL;/,
  'only the declared action is a clause');

my $last_create = do { my $p = rindex $ddl, 'CREATE TABLE'; $p };
cmp_ok(index($ddl, 'ALTER TABLE'), '>', $last_create,
  'constraints come after every CREATE TABLE (a_child sorts before z_parent)');
unlike($ddl, qr/CREATE TABLE a_child[^;]*FOREIGN KEY/, 'no inline foreign key in CREATE TABLE');

# the same key twice with other actions: refused, not one of them dropped
{
  package FkDdl2::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');
  package FkDdl2::Schema::Result::P;
  use base 'DBIO::Core';
  __PACKAGE__->table('p');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  package FkDdl2::Schema::Result::C;
  use base 'DBIO::Core';
  __PACKAGE__->table('c');
  __PACKAGE__->add_columns(id => { data_type => 'integer' }, p => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(a => 'FkDdl2::Schema::Result::P', 'p', { on_delete => 'cascade' });
  __PACKAGE__->belongs_to(b => 'FkDdl2::Schema::Result::P', 'p');
}
FkDdl2::Schema->register_class(C => 'FkDdl2::Schema::Result::C');
FkDdl2::Schema->register_class(P => 'FkDdl2::Schema::Result::P');
eval { DBIO::MSSQL::DDL->install_ddl('FkDdl2::Schema') };
like($@, qr/declare the foreign key on \(p\) twice, as constraint FK_c_p/,
  'one name, other actions: refused');

# an action SQL Server does not have
{
  package FkDdl3::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');
  package FkDdl3::Schema::Result::P;
  use base 'DBIO::Core';
  __PACKAGE__->table('p');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  package FkDdl3::Schema::Result::C;
  use base 'DBIO::Core';
  __PACKAGE__->table('c');
  __PACKAGE__->add_columns(id => { data_type => 'integer' }, p => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(a => 'FkDdl3::Schema::Result::P', 'p', { on_delete => 'frobnicate' });
}
FkDdl3::Schema->register_class(C => 'FkDdl3::Schema::Result::C');
FkDdl3::Schema->register_class(P => 'FkDdl3::Schema::Result::P');
eval { DBIO::MSSQL::DDL->install_ddl('FkDdl3::Schema') };
like($@, qr/ON DELETE frobnicate is not an action of SQL Server/, 'an unknown action is refused');

# RESTRICT (core's own test schema declares it) is NO ACTION here
{
  # core's unique constraint 'artist' on the table artist is refused (t/100)
  my $ddl = DBIO::MSSQL::DDL->install_ddl(without_artist_constraint(DBIO::Test->init_schema(
    storage_type => 'DBIO::MSSQL::Storage', no_deploy => 1)));
  like($ddl, qr/ADD CONSTRAINT FK_artist_undirected_map_id1 FOREIGN KEY \(id1\) REFERENCES artist \(artistid\) ON DELETE NO ACTION ON UPDATE CASCADE;/,
    'RESTRICT is written as NO ACTION');
}

# The diff creates a new table WITHOUT its keys and adds them afterwards
# (Diff::ForeignKey, ordered by Diff): the statement is the one of the DDL.
{
  my $fk = { constraint_name => 'FK_book_author_id', from_columns => ['author_id'],
    to_table => 'author', to_columns => ['id'], on_delete => 'CASCADE', on_update => 'NO ACTION' };
  my @ops = DBIO::MSSQL::Diff::ForeignKey->diff({}, { book => [ $fk ] }, {}, { book => {} });
  is(scalar @ops, 1, 'the key of a new table is one standalone op');
  is($ops[0]->as_sql,
    'ALTER TABLE book ADD CONSTRAINT FK_book_author_id FOREIGN KEY (author_id) REFERENCES author(id) ON DELETE CASCADE;',
    'named like the DDL, with its action, NO ACTION left out');
  my $create = DBIO::MSSQL::Diff::Table->new(
    action => 'create', table_name => 'book', table_info => {},
    columns => [ { column_name => 'author_id', data_type => 'int', not_null => 1 } ],
  )->as_sql;
  unlike($create, qr/FOREIGN KEY/, 'CREATE TABLE of the diff carries no inline key');
}

done_testing;
