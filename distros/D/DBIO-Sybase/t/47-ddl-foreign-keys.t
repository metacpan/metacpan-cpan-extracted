use strict;
use warnings;
use Test::More;

use DBIO::Sybase::DDL;

# install_ddl emits the foreign keys of the schema (karr k54). Before, it
# emitted none: a database installed through DBIO::Sybase::Deploy had no
# referential integrity at all, and -- because the compare database is
# installed from the same DDL -- no diff ever noticed.
#
# The shapes below are the point of the test, so they are spelled out here
# rather than taken from DBIO::Test::Schema (t/31 installs that one live).
{
  package K54::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->table('parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer' },
    code => { data_type => 'varchar', size => 8 },
    label => { data_type => 'varchar', size => 8 });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(parent_code => ['code']);

  package K54::Pair;
  use base 'DBIO::Core';
  __PACKAGE__->table('pair');
  __PACKAGE__->add_columns(b => { data_type => 'integer' }, a => { data_type => 'integer' });
  __PACKAGE__->set_primary_key(qw/a b/);

  package K54::Child;
  use base 'DBIO::Core';
  __PACKAGE__->table('child');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    parent_id => { data_type => 'integer' },
    parent_code => { data_type => 'varchar', size => 8 },
    parent_label => { data_type => 'varchar', size => 8 },
    pa => { data_type => 'integer' }, pb => { data_type => 'integer' },
    up => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  # plain, and a second relationship over the same columns: one constraint
  __PACKAGE__->belongs_to(parent => 'K54::Parent', 'parent_id');
  __PACKAGE__->belongs_to(parent_again => 'K54::Parent',
    { 'foreign.id' => 'self.parent_id' }, { on_delete => 'NO ACTION' });
  # to a unique constraint rather than the key
  __PACKAGE__->belongs_to(by_code => 'K54::Parent', { 'foreign.code' => 'self.parent_code' });
  # to a column with no unique index: no constraint ASE would accept
  __PACKAGE__->belongs_to(by_label => 'K54::Parent', { 'foreign.label' => 'self.parent_label' });
  # composite, declared out of key order
  __PACKAGE__->belongs_to(pair => 'K54::Pair', { 'foreign.b' => 'self.pb', 'foreign.a' => 'self.pa' });
  # a coderef condition
  __PACKAGE__->belongs_to(opaque => 'K54::Parent', sub { \' 1 = 1 ' });
  # self reference
  __PACKAGE__->belongs_to(up => 'K54::Child', { 'foreign.id' => 'self.up' });
  # explicitly not a constraint
  __PACKAGE__->belongs_to(soft => 'K54::Parent', { 'foreign.id' => 'self.pa' },
    { is_foreign_key_constraint => 0 });

  package K54::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Child  => 'K54::Child');
  __PACKAGE__->register_class(Parent => 'K54::Parent');
  __PACKAGE__->register_class(Pair   => 'K54::Pair');
}

my @stmts = split /\n\n/, DBIO::Sybase::DDL->install_ddl('K54::Schema');
my @fks   = grep { /FOREIGN KEY/ } @stmts;

is_deeply \@fks, [
  'ALTER TABLE child ADD CONSTRAINT fk_child_parent_code FOREIGN KEY (parent_code) REFERENCES parent (code);',
  'ALTER TABLE child ADD CONSTRAINT fk_child_pa_pb FOREIGN KEY (pa, pb) REFERENCES pair (a, b);',
  'ALTER TABLE child ADD CONSTRAINT fk_child_parent_id FOREIGN KEY (parent_id) REFERENCES parent (id);',
  'ALTER TABLE child ADD CONSTRAINT fk_child_up FOREIGN KEY (up) REFERENCES child (id);',
], 'one ALTER TABLE ... ADD CONSTRAINT per referential constraint, by relationship name';

# The set above pins what is left out as well: the duplicate over parent_id,
# the reference to the non-unique label, the coderef, and the relationship
# marked is_foreign_key_constraint => 0.
ok !(grep { /ON (?:DELETE|UPDATE)/ } @fks),
  'no referential action, although parent_again asks for ON DELETE NO ACTION (Msg 156 on ASE)';

my ($last_create) = grep { $stmts[$_] =~ /\ACREATE TABLE/ } reverse 0 .. $#stmts;
my ($first_fk)    = grep { $stmts[$_] =~ /FOREIGN KEY/ } 0 .. $#stmts;
ok $first_fk > $last_create, 'every FK follows every CREATE TABLE (child sorts before its parents)';

# The name is the one Diff::ForeignKey generates for the same tuple, so a
# create from the diff and one from install_ddl agree.
use DBIO::Sybase::Diff::ForeignKey;
is DBIO::Sybase::Diff::ForeignKey::_fk_name('child', { from_columns => [qw/pa pb/] }),
  'fk_child_pa_pb', 'install_ddl and Diff::ForeignKey name an FK alike';

done_testing;
