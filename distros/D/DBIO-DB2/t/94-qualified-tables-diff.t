use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::DB2::DDL;
use DBIO::DB2::Deploy;
use DBIO::DB2::Diff;

# OFFLINE (karr k57, maintainer decision: a table named schema.table is compared
# and altered by diff and upgrade, pattern of dbio-mysql k122). The model of a
# diff keys such a table "schema.table" next to the tables of the current schema:
# the introspection reads the schemas of the declared sources (their declared
# tables only: a table of that schema the declaration does not name is never in
# the model, so never dropped), the target is built per schema in the compare
# schema, and every operation writes the table in its schema. A foreign key
# across schemas cannot be compared (the compare schema holds one schema's
# tables) and is refused, naming both tables, before the first statement.
# t/95 is the live counterpart.

{
  package QD::Parent; use base 'DBIO::Core';
  __PACKAGE__->table('other.parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  package QD::Child; use base 'DBIO::Core';
  __PACKAGE__->table('other.child');
  __PACKAGE__->add_columns(id => { data_type => 'integer' }, parent_id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'QD::Parent', 'parent_id');
  package QD::Plain; use base 'DBIO::Core';
  __PACKAGE__->table('plain');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  package QD::Cross; use base 'DBIO::Core';
  __PACKAGE__->table('cross');
  __PACKAGE__->add_columns(id => { data_type => 'integer' }, parent_id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'QD::Parent', 'parent_id');
  package QD::S; use base 'DBIO::Schema';
  __PACKAGE__->register_class(Parent => 'QD::Parent');
  __PACKAGE__->register_class(Child => 'QD::Child');
  __PACKAGE__->register_class(Plain => 'QD::Plain');
  package QD::S2; use base 'DBIO::Schema';
  __PACKAGE__->register_class(Parent => 'QD::Parent');
  __PACKAGE__->register_class(Cross => 'QD::Cross');
}

# --- the DDL per schema ------------------------------------------------------------
is_deeply [ map { "$_->[0]|$_->[1]" } DBIO::DB2::DDL->qualified_tables('QD::S') ],
  ['other.child|other', 'other.parent|other'], 'the qualified tables of a schema, with their schemas, sorted';

my $local = DBIO::DB2::DDL->install_ddl('QD::S', 'X', { local_only => 1 });
like $local, qr/CREATE TABLE "plain"/, 'local_only: the unqualified table';
unlike $local, qr/other/, '... and nothing of the qualified ones';

my $only = DBIO::DB2::DDL->install_ddl('QD::S', 'X', { only_schema => 'other' });
like $only, qr/CREATE TABLE "parent"/, 'only_schema: the tables of that schema, under their own names';
like $only, qr/REFERENCES "parent"\("id"\)/, '... a key between them names the bare table';
unlike $only, qr/"plain"|"other"/, '... and no other table, no qualifier';

# --- the operations write the table in its schema ----------------------------------
sub col { { column_name => $_[0], catalog_type => 'INTEGER', catalog_size => 4, not_null => 0, @_[1 .. $#_] } }
sub model {
  my (%t) = @_;       # table => [columns]
  return { tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %t },
    columns => { map { my $c = $t{$_}; ($_ => [ map { col($_) } @$c ]) } keys %t },
    indexes => {}, foreign_keys => {}, unique_constraints => {} };
}
sub diff_sql { DBIO::DB2::Diff->new(source => $_[0], target => $_[1])->as_sql }

my $sql = diff_sql(model('other.t' => ['id']), model('other.t' => ['id', 'n']));
like $sql, qr/ALTER TABLE "other"\."t" ADD COLUMN "n" INTEGER;/, 'a column is added in the schema of its table';

$sql = diff_sql(model(), model('other.t' => ['id']));
like $sql, qr/CREATE TABLE "other"\."t" \(/, 'a new table is created in its schema';
$sql = diff_sql(model('other.t' => ['id']), model());
like $sql, qr/DROP TABLE "other"\."t";/, 'a table the declaration dropped is dropped from its schema';

{
  my $s = model('other.t' => ['id', 'a']);
  my $t = model('other.t' => ['id', 'a']);
  $t->{indexes}{'other.t'} = { ix => { columns => ['a'], is_unique => 0 } };
  like diff_sql($s, $t), qr/CREATE INDEX "other"\."ix" ON "other"\."t" \("a"\);/, 'an index is made in the schema of its table';
  like diff_sql($t, $s), qr/DROP INDEX "other"\."ix";/, '... and dropped from it';
  $s->{unique_constraints}{'other.t'} = [ [ uq => ['a'] ] ];
  like diff_sql($s, model('other.t' => ['id', 'a'])), qr/ALTER TABLE "other"\."t" DROP UNIQUE "uq";/, 'a UNIQUE constraint: the table in its schema';
}
$sql = diff_sql(model('other.t' => ['id', 'a']), model('other.t' => ['id']));
like $sql, qr/ALTER TABLE "other"\."t" DROP COLUMN "a";/, 'DROP COLUMN in the schema';
like $sql, qr/REORG TABLE "other"\."t"/, '... and the REORG of that table, too';

# --- the model: merged under "schema.table" ----------------------------------------
{
  my $other = { tables => { t => { table_name => 't', kind => 'table' }, foreign => { table_name => 'foreign', kind => 'table' },
                            v => { table_name => 'v', kind => 'view' } },
    columns => { t => [ { column_name => 'id' } ], foreign => [ { column_name => 'id' } ] },
    indexes => { t => { ix => { columns => ['id'] } } },
    foreign_keys => { t => [ { constraint_name => 'fk', from_columns => ['id'], to_table => 't2', to_columns => ['id'] } ] },
    unique_constraints => { t => [ [ uq => ['id'] ] ] } };
  my $main = { tables => { plain => { table_name => 'plain', kind => 'table' } }, columns => { plain => [] },
    indexes => {}, foreign_keys => {}, unique_constraints => {} };
  DBIO::DB2::Deploy->_merge_schema_model($main, $other, 'other', { t => 1, t2 => 1 });
  is_deeply [ sort keys %{ $main->{tables} } ], ['other.t', 'plain'],
    'only the declared tables of the schema are merged: not a foreign table of it, not a view';
  is $main->{tables}{'other.t'}{table_name}, 'other.t', '... under the name schema.table';
  ok $main->{columns}{'other.t'} && $main->{indexes}{'other.t'}{ix} && $main->{unique_constraints}{'other.t'},
    '... with its columns, indexes and constraints';
  is $main->{foreign_keys}{'other.t'}[0]{to_table}, 'other.t2', '... a key to a table of the schema names it so';
}

# --- a key across schemas is refused --------------------------------------------------
throws_ok { DBIO::DB2::Deploy->_refuse_cross_schema_keys('QD::S2') }
  qr/refus.*"cross".*"other\.parent"|refus.*cross.*other\.parent/s,
  'a foreign key from a table of the current schema to one of another is refused, naming both';
isa_ok $@, 'DBIO::Exception', '... the refusal';
lives_ok { DBIO::DB2::Deploy->_refuse_cross_schema_keys('QD::S') } 'a key inside one schema is fine';

done_testing;
