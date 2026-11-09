use strict;
use warnings;
use Test::More;

use DBIO::DB2::DDL;
use DBIO::DB2::Deploy;

# OFFLINE (karr k57, conformance case ddl-qualified-source-name; maintainer
# decision: qualify). table('other.t') is the table t in the schema other, not
# one table named "other.t" in the current schema. install_ddl writes
# "other"."t" (Db2 makes the schema when it is missing, implicit schema
# creation); the foreign keys and indexes of such a table name the schema as
# well, and the constraint name keys on the table's own name. The compare deploy
# of the diff reads one schema, so it leaves a qualified table out (it is no
# part of the introspected model, on either side). t/83 is the live counterpart
# (the conformance case; the schema is dropped again by its cleanup).

{
  package Q::Parent; use base 'DBIO::Core';
  __PACKAGE__->table('other.parent');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  package Q::Child; use base 'DBIO::Core';
  __PACKAGE__->table('other.child');
  __PACKAGE__->add_columns(id => { data_type => 'integer' }, parent_id => { data_type => 'integer' },
    a => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'Q::Parent', 'parent_id');
  __PACKAGE__->mk_classdata(db2_indexes => { child_a => { columns => ['a'] } });
  package Q::Plain; use base 'DBIO::Core';
  __PACKAGE__->table('plain');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
  package Q::S; use base 'DBIO::Schema';
  __PACKAGE__->register_class(Parent => 'Q::Parent');
  __PACKAGE__->register_class(Child => 'Q::Child');
  __PACKAGE__->register_class(Plain => 'Q::Plain');
}

my $ddl = DBIO::DB2::DDL->install_ddl('Q::S', 'X');
like $ddl, qr/CREATE TABLE "other"\."parent" \(/, 'a qualified table is created in its schema';
like $ddl, qr/CREATE TABLE "other"\."child" \(/, '... both';
like $ddl, qr/CREATE TABLE "plain" \(/, '... an unqualified one as before';
unlike $ddl, qr/"other\.(?:parent|child)"/, '... and no table is named with a dot';
like $ddl, qr/CONSTRAINT "fk_child_parent_id" FOREIGN KEY \("parent_id"\) REFERENCES "other"\."parent"\("id"\)/,
  'the foreign key names the schema of the table it references; the constraint name keys on the table itself';
like $ddl, qr/CREATE INDEX "other"\."child_a" ON "other"\."child" \("a"\)/, 'an index is made in the schema of its table';
my $parent_at = index $ddl, 'CREATE TABLE "other"."parent"';
my $child_at  = index $ddl, 'CREATE TABLE "other"."child"';
ok $parent_at < $child_at, 'the referenced table first';

# the compare deploy: only the unqualified table is deployed into the compare schema
my @stmts = DBIO::DB2::Deploy->_split_qualify_ddl($ddl, 'DBIO_TEST_1');
my @tables = grep { /^CREATE TABLE/ } @stmts;
is scalar(@tables), 1, 'the compare deploy keeps one table';
like $tables[0], qr/^CREATE TABLE DBIO_TEST_1\."plain"/, '... the unqualified one, in the compare schema';
ok !(grep { /other/ } @stmts), '... nothing of the qualified ones, nor their indexes';

done_testing;
