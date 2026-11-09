use strict;
use warnings;

use Test::More;

use DBIO::Test::Conformance ();
use DBIO::Oracle::DDL ();
use DBIO::Oracle::Deploy ();
use DBIO::Oracle::Diff ();
use DBIO::Oracle::Identifier ();
use DBIO::Oracle::Introspect ();
use DBIO::SQL::Util ();

# OFFLINE (karr k58). A source named 'schema.table' is a table in another
# schema -- on Oracle a schema is a user. Claims:
#
#   1. DDL: every statement of the table (CREATE TABLE, SEQUENCE, TRIGGER,
#      INDEX, the foreign keys in both directions) carries the schema,
#      quoted exactly as the table name is: "OWNX"."item". A name with an
#      empty half ('.t', 'x.') is refused, not created with a dot in it.
#   2. declared_objects tells the objects of the other schema apart, so a
#      cleanup can find them.
#   3. install refuses a schema that does not exist, loudly and before the
#      first statement (the driver creates no user); with the users there it
#      runs the statements. diff/upgrade build the desired state in a temporary
#      user for each foreign schema (t/58 section 8) and are not refused.
#   4. Introspect reads the schemas it is told to and names their tables
#      'schema.table'; Diff writes a qualified table, column, index, foreign
#      key and sequence with the schema.
#
# What the server makes of it is t/84-ddl-cross-schema-live.t.

sub schema_of {
  my (@sources) = @_;
  return DBIO::Test::Conformance->_build_schema_class(
    { name => 't85', input => { sources => \@sources } });
}

sub msg { (my $t = "$_[0]") =~ s/ at \S+ line \d+.*\z//s; $t }

my $id = sub { +{ data_type => 'integer', is_nullable => 0 } };
my $auto = sub { +{ data_type => 'integer', is_nullable => 0, is_auto_increment => 1 } };

my @sources = (
  { name => 'Parent', table => 'OWNX.parent',
    columns => [ id => $auto->(), name => { data_type => 'varchar', size => 20, is_nullable => 1 } ],
    primary_key => ['id'],
  },
  { name => 'Item', table => 'OWNX.item',
    columns => [ id => $id->(), parent_id => $id->(), code => { data_type => 'varchar', size => 10 } ],
    primary_key => ['id'],
    unique => [ [ item_code => ['code'] ] ],
    indexes => [ { name => 'item_parent_idx', columns => ['parent_id'] } ],
    relationships => [ { type => 'belongs_to', name => 'parent', source => 'Parent', cond => 'parent_id' } ],
  },
  { name => 'Plain', table => 'plain',
    columns => [ id => $id->(), item_id => $id->() ],
    primary_key => ['id'],
    relationships => [ { type => 'belongs_to', name => 'item', source => 'Item', cond => 'item_id' } ],
  },
);

my $solo = { name => "Solo", table => "solo", columns => [ id => $id->() ], primary_key => ["id"] };

# --- 1. the DDL ---------------------------------------------------------

my $ddl = eval { DBIO::Oracle::DDL->install_ddl(schema_of(@sources)) };
ok defined $ddl, 'a schema-qualified source is installed, not refused' or diag "got: $@";
$ddl //= '';

like $ddl, qr/CREATE TABLE "OWNX"\."parent" \(/, 'CREATE TABLE carries the schema, quoted';
like $ddl, qr/CREATE TABLE "OWNX"\."item" \(/,   '... for every table of it';
like $ddl, qr/CREATE TABLE "plain" \(/,         '... and a table without one stays in the own schema';
unlike $ddl, qr/"OWNX\.parent"|"OWNX\.item"/,    'the dot is never part of one quoted name';
like $ddl, qr/CREATE SEQUENCE "OWNX"\."parent_id_seq";/, 'the sequence is made in the schema of the table';
like $ddl, qr/CREATE OR REPLACE TRIGGER "OWNX"\."parent_id_trg"\nBEFORE INSERT ON "OWNX"\."parent" FOR EACH ROW/,
  'the trigger and its table both carry the schema';
like $ddl, qr/SELECT "OWNX"\."parent_id_seq"\.NEXTVAL INTO :new\."id"/, '... and the sequence it reads';
like $ddl, qr/CREATE INDEX "OWNX"\."item_parent_idx" ON "OWNX"\."item" \("parent_id"\);/,
  'an index is made in the schema of its table';
like $ddl, qr/ALTER TABLE "OWNX"\."item" ADD CONSTRAINT "fk_item_parent_id_parent" FOREIGN KEY \("parent_id"\) REFERENCES "OWNX"\."parent" \("id"\)/,
  'a foreign key between tables of the other schema';
like $ddl, qr/ALTER TABLE "plain" ADD CONSTRAINT "fk_plain_item_id_item" FOREIGN KEY \("item_id"\) REFERENCES "OWNX"\."item" \("id"\)/,
  'a foreign key from the own schema to a table of the other one';
like $ddl, qr/CONSTRAINT "item_code" UNIQUE \("code"\)/, 'a unique constraint is named in the table, unqualified';

for my $bad ('.t', 'x.') {
  my $err = eval { DBIO::Oracle::DDL->install_ddl(schema_of({
    name => 'Bad', table => $bad, columns => [ id => $id->() ], primary_key => ['id'] })); 1 } ? undef : $@;
  ok $err, "'$bad' is refused";
  like msg($err), qr/refus/i, '... the text says refus';
  like "$err", qr/\Q$bad\E/,  '... it names the table';
}

# --- 2. the declared objects ---------------------------------------------

{
  my $o = DBIO::Oracle::DDL->declared_objects(schema_of(@sources));
  is_deeply $o->{table}, ['plain'], 'declared_objects: table lists the own schema only';
  my $x = $o->{schema}{OWNX};
  is_deeply [ sort @{ $x->{table} } ], [qw(item parent)], '... the other schema has its tables';
  is_deeply $x->{sequence}, ['parent_id_seq'], '... its sequence';
  is_deeply $x->{trigger},  ['parent_id_trg'], '... its trigger';
  ok +(grep { $_->[0] eq 'item_parent_idx' && $_->[1] eq 'item' } @{ $x->{index} }),
    '... its index with the table it is on';
  is_deeply [ DBIO::Oracle::DDL->foreign_schemas(schema_of(@sources)) ], ['OWNX'],
    'foreign_schemas names the schemas the install writes to';
  is_deeply [ DBIO::Oracle::DDL->foreign_schemas(schema_of($solo)) ], [],
    '... none for a schema without a qualified table';
}

# --- 3. install and the user that must exist ------------------------------

{
  package T::Dbh;
  sub new { bless { users => $_[1], log => [] }, $_[0] }
  sub selectcol_arrayref {
    my ($s, $sql, $attr, @bind) = @_;
    push @{ $s->{log} }, $sql;
    return [ grep { my $u = $_; grep { $_ eq $u } @{ $s->{users} } } @bind ] if $sql =~ /all_users/i;
    return [];
  }
  sub do { push @{ $_[0]{log} }, $_[1]; 1 }
}
{
  package T::Deploy;
  our @ISA = ('DBIO::Oracle::Deploy');
  sub _dbh { $_[0]{dbh} }
  sub _introspect_current { {} }
  sub _execute_ddl { my ($s, $dbh, $sql) = @_; $s->{ran} = $sql; return }
}

{
  my $schema = schema_of(@sources);
  my $dbh = T::Dbh->new([ 'SOMEONE' ]);
  my $deploy = T::Deploy->new(schema => $schema);
  $deploy->{dbh} = $dbh;
  my $err = eval { $deploy->install; 1 } ? undef : $@;
  ok $err, 'install of a schema whose user does not exist is refused';
  isa_ok $err, 'DBIO::Exception';
  isnt ref $err, 'DBIO::Exception::Server', '... by the driver, not by the server';
  like msg($err), qr/refus/i,     '... the text says refus';
  like "$err", qr/OWNX/,          '... it names the user';
  like "$err", qr/OWNX\.item|OWNX\.parent/, '... and a table that wants it';
  ok !defined $deploy->{ran}, '... before any statement was run';
  ok !(grep { /CREATE|ALTER/ } @{ $dbh->{log} }), '... nothing was sent to the handle';
}
{
  my $schema = schema_of(@sources);
  my $deploy = T::Deploy->new(schema => $schema);
  $deploy->{dbh} = T::Dbh->new([ 'OWNX' ]);
  ok eval { $deploy->install; 1 }, 'with the user there, install runs' or diag $@;
  like $deploy->{ran} // '', qr/CREATE TABLE "OWNX"\."item"/, '... the qualified statements';
}
{
  my $deploy = T::Deploy->new(schema => schema_of($solo));
  $deploy->{dbh} = T::Dbh->new([]);
  ok eval { $deploy->install; 1 }, 'a schema without a qualified table asks no user' or diag $@;
}
{
  # diff and upgrade are no longer refused for a qualified table (a temp
  # user per foreign schema, t/58 section 8): this schema has no storage, so
  # they stop at the missing connection, not at a refusal
  my $deploy = T::Deploy->new(schema => schema_of(@sources));
  $deploy->{dbh} = T::Dbh->new(['OWNX']);
  for my $m (qw(diff upgrade)) {
    my $err = eval { $deploy->$m; 1 } ? undef : $@;
    ok $err, "$m of a schema with a qualified table goes on to build its desired state (no connection here)";
    unlike msg($err // ''), qr/refus|cannot hold/i, '... it is not refused';
  }
}

# --- 4. Introspect reads other schemas -----------------------------------

{
  my %data = (
    ME => {
      tables  => { mine => { table_name => 'mine', kind => 'table', schema => 'ME' } },
      columns => { mine => [ { column_name => 'id' } ] },
      indexes => { mine => {} },
      fks     => { mine => [ { constraint_name => 'fk_x', from_table => 'mine', from_columns => ['x'],
                               to_table => 'OWNX.item', to_columns => ['id'], on_delete => 'NO ACTION' } ] },
      keys    => { primary => { mine => ['id'] }, unique => { mine => [] } },
    },
    OWNX => {
      tables  => { item => { table_name => 'item', kind => 'table', schema => 'OWNX' } },
      columns => { item => [ { column_name => 'id', sequence => 'OWNX.item_id_seq' }, { column_name => 'pid' } ] },
      indexes => { item => { ix => { index_name => 'ix', columns => ['pid'], is_unique => 0 } } },
      fks     => { item => [
        { constraint_name => 'fk_item', from_table => 'item', from_columns => ['pid'],
          to_table => 'item', to_columns => ['id'], on_delete => 'NO ACTION' },
        { constraint_name => 'fk_me', from_table => 'item', from_columns => ['m'],
          to_table => 'ME.mine', to_columns => ['id'], on_delete => 'NO ACTION' },
      ] },
      keys    => { primary => { item => ['id'] }, unique => { item => [ [ item_uq => ['pid'] ] ] } },
    },
  );
  no warnings 'redefine';
  local *DBIO::Oracle::Introspect::Tables::fetch      = sub { $data{ $_[2] }{tables} };
  local *DBIO::Oracle::Introspect::Columns::fetch     = sub { $data{ $_[2] }{columns} };
  local *DBIO::Oracle::Introspect::Indexes::fetch     = sub { $data{ $_[2] }{indexes} };
  local *DBIO::Oracle::Introspect::ForeignKeys::fetch = sub { $data{ $_[2] }{fks} };
  local *DBIO::Oracle::Introspect::Keys::fetch        = sub { $data{ $_[2] }{keys} };

  my $plain = DBIO::Oracle::Introspect->new(dbh => 'x', schema => 'ME')->model;
  is_deeply [ sort keys %{ $plain->{tables} } ], ['mine'], 'without the attribute only the own schema is read';

  my $m = DBIO::Oracle::Introspect->new(dbh => 'x', schema => 'ME', schemas => ['OWNX'])->model;
  is_deeply [ sort keys %{ $m->{tables} } ], [ 'OWNX.item', 'mine' ], 'schemas: the tables of the other schema are named schema.table';
  is $m->{tables}{'OWNX.item'}{schema}, 'OWNX', '... the entry knows its schema';
  is $m->{tables}{'OWNX.item'}{table_name}, 'item', '... and its bare name';
  is_deeply [ map { $_->{column_name} } @{ $m->{columns}{'OWNX.item'} } ], [qw(id pid)], 'columns follow the key';
  ok $m->{columns}{'OWNX.item'}[0]{is_pk}, '... the primary key is marked on them';
  is_deeply [ keys %{ $m->{indexes}{'OWNX.item'} } ], ['ix'], 'indexes follow the key';
  is_deeply $m->{primary_keys}{'OWNX.item'}, ['id'], 'primary keys follow the key';
  is $m->{unique_constraints}{'OWNX.item'}[0][0], 'item_uq', 'unique constraints follow the key';
  my %fk = map { $_->{constraint_name} => $_ } @{ $m->{foreign_keys}{'OWNX.item'} };
  is $fk{fk_item}{to_table}, 'OWNX.item', 'a key to a table of the same schema names it with the schema';
  is $fk{fk_item}{from_table}, 'OWNX.item', '... and starts at the qualified table';
  is $fk{fk_me}{to_table}, 'mine', 'a key to the own schema is the bare key of that table';
  is $m->{foreign_keys}{mine}[0]{to_table}, 'OWNX.item', 'the own schema\'s key to the other schema keeps the schema';
}

# --- 4b. Diff writes the qualified table ----------------------------------

sub statements { [ DBIO::SQL::Util::_split_statements($_[0]->as_sql) ] }

{
  my $empty = { tables => {}, columns => {}, indexes => {}, foreign_keys => {},
                primary_keys => {}, unique_constraints => {} };
  my $x = {
    tables => {
      'OWNX.t' => { table_name => 't', kind => 'table', schema => 'OWNX' },
      'OWNX.u' => { table_name => 'u', kind => 'table', schema => 'OWNX' },
    },
    columns => {
      'OWNX.t' => [
        { column_name => 'id', data_type => 'numeric', not_null => 1, is_pk => 1, pk_position => 1,
          is_auto_increment => 1, sequence => 'OWNX.t_id_seq' },
        { column_name => 'u_id', data_type => 'numeric', not_null => 0 },
      ],
      'OWNX.u' => [ { column_name => 'id', data_type => 'numeric', not_null => 1, is_pk => 1, pk_position => 1 } ],
    },
    indexes => { 'OWNX.t' => { t_idx => { index_name => 't_idx', is_unique => 0, columns => ['u_id'] } }, 'OWNX.u' => {} },
    foreign_keys => { 'OWNX.t' => [ { constraint_name => 'fk_t_u', from_columns => ['u_id'],
      to_table => 'OWNX.u', to_columns => ['id'], on_delete => 'NO ACTION' } ], 'OWNX.u' => [] },
    primary_keys => { 'OWNX.t' => ['id'], 'OWNX.u' => ['id'] },
    unique_constraints => { 'OWNX.t' => [], 'OWNX.u' => [] },
  };

  my $create = DBIO::Oracle::Diff->new(source => $empty, target => $x);
  my $sql = $create->as_sql;
  like $sql, qr/CREATE TABLE "OWNX"\."t" \(/, 'diff: CREATE TABLE of a qualified table carries the schema';
  like $sql, qr/CREATE SEQUENCE "OWNX"\."t_id_seq";/, '... the sequence';
  like $sql, qr/CREATE OR REPLACE TRIGGER "OWNX"\."t_id_trg"\nBEFORE INSERT ON "OWNX"\."t" FOR EACH ROW/, '... the trigger and its table';
  like $sql, qr/SELECT "OWNX"\."t_id_seq"\.NEXTVAL INTO :new\."id"/, '... the sequence in its body';
  like $sql, qr/CREATE INDEX "OWNX"\."t_idx" ON "OWNX"\."t" \("u_id"\);/, '... the index';
  like $sql, qr/ALTER TABLE "OWNX"\."t" ADD CONSTRAINT "fk_t_u" FOREIGN KEY \("u_id"\) REFERENCES "OWNX"\."u" \("id"\)/, '... the foreign key';
  unlike $sql, qr/"OWNX\.[tu]"/, '... the dot is never inside one quoted name';

  my $drop = DBIO::Oracle::Diff->new(source => $x, target => $empty)->as_sql;
  like $drop, qr/DROP TABLE "OWNX"\."t" CASCADE CONSTRAINTS;/, 'diff: DROP TABLE carries the schema';
  like $drop, qr/DROP SEQUENCE "OWNX"\."t_id_seq";/, '... and the sequence of the table';

  # a column and an index of a table both models have
  my %more = %$x;
  $more{columns} = { %{ $x->{columns} },
    'OWNX.u' => [ @{ $x->{columns}{'OWNX.u'} }, { column_name => 'extra', data_type => 'varchar2', size => 5, not_null => 0 } ] };
  $more{indexes} = { 'OWNX.t' => {}, 'OWNX.u' => {} };
  my $alter = DBIO::Oracle::Diff->new(source => $x, target => \%more)->as_sql;
  like $alter, qr/ALTER TABLE "OWNX"\."u" ADD \("extra" VARCHAR2\(5\)\);/, 'diff: a column is added to the qualified table';
  like $alter, qr/DROP INDEX "OWNX"\."t_idx";/, '... an index is dropped in the schema of its table';
}

done_testing;
