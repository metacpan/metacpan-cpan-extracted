use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::DDL qw(_quote_table _constraint_name);
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Diff::Schema;

# karr k72 (maintainer's decision 2026-10-25): a table or view name
# "schema.table" is made in that schema, and the schema is created when it is
# missing. Before, install_ddl and the CREATE TABLE of the diff refused a name
# with a dot (t/94 pinned that; it pins the opposite now). Offline half; the
# live half, against a second schema of a real server, is t/112.
#
# WHY, per block:
#  1. Both parts of schema.table are quoted on their own: [my schema].t is one
#     schema and one table, never the table "my schema.t" in dbo.
#  2. install_ddl: CREATE SCHEMA first and as a statement of its own (SQL
#     Server wants it first in its batch), the table, its indexes and keys in
#     the schema, a key across the schema border in both directions, a
#     constraint named after the bare table (constraint names live per schema).
#  3. The diff: a schema the target needs and the live side lacks is created
#     before any table; one that is there is not created again; no DROP SCHEMA.
#  4. Names: a name with two dots is a database-qualified one and refused (the
#     driver cannot create in another database).

# ---- 1. quoting
is _quote_table('t'),            't',                'a plain name is as it was';
is _quote_table('other.t'),      'other.t',          'schema.table, both plain';
is _quote_table('my schema.t'),  '[my schema].t',    'the schema is quoted on its own';
is _quote_table('other.my t'),   'other.[my t]',     'so is the table';
is _quote_table('order.select'), '[order].[select]', 'reserved words in both parts';
is _constraint_name('PK', 'other.t'), 'PK_t', 'a constraint is named after the bare table';
is _constraint_name('FK', 'other.t', 'a', 'b'), 'FK_t_a_b', '... foreign keys as well';

# ---- 2. install_ddl
{
  package K72::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');

  package K72::Schema::Result::Parent;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('MSSQL::Result');
  __PACKAGE__->table('other.parent');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    code => { data_type => 'varchar', size => 20 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(parent_code => ['code']);

  package K72::Schema::Result::Plain;
  use base 'DBIO::Core';
  __PACKAGE__->table('plain');
  __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
  __PACKAGE__->set_primary_key('id');

  package K72::Schema::Result::Child;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('MSSQL::Result');
  __PACKAGE__->table('other.child');
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer', is_auto_increment => 1 },
    parent_id => { data_type => 'integer' },
    dbo_id    => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(parent => 'K72::Schema::Result::Parent', 'parent_id');
  # across the border, into dbo
  __PACKAGE__->belongs_to(plain => 'K72::Schema::Result::Plain', 'dbo_id');
  __PACKAGE__->mssql_index(child_parent_idx => { columns => ['parent_id'] });

  # and out of dbo into the schema; dbo.back is the table back of dbo
  package K72::Schema::Result::Back;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbo.back');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    child_id => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(child => 'K72::Schema::Result::Child', 'child_id');
}
K72::Schema->register_class($_ => "K72::Schema::Result::$_") for qw(Parent Child Plain Back);

my $ddl = DBIO::MSSQL::DDL->install_ddl('K72::Schema');
my @stmts = grep { length } split /;\n/, $ddl;

like $ddl, qr/^CREATE SCHEMA other;/m, 'the schema is created';
is scalar(() = $ddl =~ /CREATE SCHEMA/g), 1, '... once, for two tables in it';
ok index($ddl, 'CREATE SCHEMA') < index($ddl, 'CREATE TABLE'),
  'before the first CREATE TABLE';
is scalar(grep { /CREATE SCHEMA/ && /CREATE TABLE/ } @stmts), 0,
  'a statement of its own (it has to be the first of its batch)';
like $ddl, qr/CREATE TABLE other\.parent \(/, 'the table is made in the schema';
like $ddl, qr/CREATE TABLE other\.child \(/, '... both';
like $ddl, qr/CREATE TABLE plain \(/, 'a table without schema stays as it was';
like $ddl, qr/CREATE TABLE back \(/, 'dbo.back is the table back of dbo';
unlike $ddl, qr/CREATE SCHEMA dbo/, 'dbo is never created';
like $ddl, qr/CONSTRAINT PK_parent PRIMARY KEY \(id\)/, 'the key is named after the bare table';
like $ddl, qr/CONSTRAINT UQ_parent_code UNIQUE \(code\)/, 'the unique constraint is named after the bare table';
like $ddl,
  qr/ALTER TABLE other\.child ADD CONSTRAINT FK_child_parent_id FOREIGN KEY \(parent_id\) REFERENCES other\.parent \(id\);/,
  'a key inside the schema';
like $ddl,
  qr/ALTER TABLE other\.child ADD CONSTRAINT FK_child_dbo_id FOREIGN KEY \(dbo_id\) REFERENCES plain \(id\);/,
  'a key from the schema into dbo';
like $ddl,
  qr/ALTER TABLE back ADD CONSTRAINT FK_back_child_id FOREIGN KEY \(child_id\) REFERENCES other\.child \(id\);/,
  'a key from dbo into the schema';
like $ddl, qr/CREATE INDEX child_parent_idx ON other\.child \(parent_id\);/,
  'an index of a table in the schema';

# the same table name in two schemas: constraint names are per schema, so the
# same bare name is no clash
{
  package K72b::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('MSSQL');
  for my $s (qw(one two)) {
    my $c = "K72b::Schema::Result::\u$s";
    no strict 'refs';
    @{"${c}::ISA"} = ('DBIO::Core');
    $c->table("$s.t");
    $c->add_columns(id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 10 });
    $c->set_primary_key('id');
    $c->add_unique_constraint(['name']);
    K72b::Schema->register_class(ucfirst($s) => $c);
  }
}
my $ddl2 = eval { DBIO::MSSQL::DDL->install_ddl('K72b::Schema') };
ok defined $ddl2, 'the same table name in two schemas installs' or diag $@;
is scalar(() = ($ddl2 // '') =~ /CREATE SCHEMA/g), 2, '... both schemas are created';
like $ddl2, qr/CREATE TABLE one\.t /, 'one.t';
like $ddl2, qr/CREATE TABLE two\.t /, 'two.t';

# ---- 3. the diff
sub col {
  my ($n, %x) = @_;
  return +{ column_name => $n, data_type => 'int', not_null => 0, is_pk => 0, pk_position => 0, %x };
}
sub model {
  my (%m) = @_;
  return { tables => { map { $_ => { table_name => $_, kind => 'table' } } keys %{ $m{columns} } },
           indexes => {}, foreign_keys => {}, %m };
}
sub ops_sql {
  my ($src, $tgt) = @_;
  my $d = DBIO::MSSQL::Diff->new(source => $src, target => $tgt);
  return map { $_->as_sql } @{ $d->operations };
}

my $live = model(columns => { plain => [ col('id', is_pk => 1, pk_position => 1, not_null => 1) ] },
                 schemas => { dbo => 1 });
my $want = model(
  columns => {
    plain     => [ col('id', is_pk => 1, pk_position => 1, not_null => 1) ],
    'other.t' => [ col('id', is_pk => 1, pk_position => 1, not_null => 1), col('plain_id') ],
  },
  foreign_keys => { 'other.t' => [ { constraint_name => 'FK_t_plain_id', from_columns => ['plain_id'],
    to_table => 'plain', to_columns => ['id'], on_delete => 'NO ACTION', on_update => 'NO ACTION' } ] },
  schemas => { dbo => 1, other => 1 });
my @sql = ops_sql($live, $want);
is $sql[0], 'CREATE SCHEMA other;', 'the first operation creates the schema';
like $sql[1], qr/^CREATE TABLE other\.t \(/, 'then the table, in the schema';
like $sql[-1],
  qr/^ALTER TABLE other\.t ADD CONSTRAINT FK_t_plain_id FOREIGN KEY \(plain_id\) REFERENCES plain\(id\);/,
  'the key across the border is added last';

my $diff = DBIO::MSSQL::Diff->new(source => $live, target => $want);
like $diff->summary, qr/^\+ schema: other$/m, 'the summary names the schema';

# a schema that is there is not created again
my $live2 = model(columns => { plain => $live->{columns}{plain} }, schemas => { dbo => 1, other => 1 });
is_deeply [ grep { /CREATE SCHEMA/ } ops_sql($live2, $want) ], [],
  'no CREATE SCHEMA for a schema the live side has';
# a model without the schemas key (hand-written): taken from the table names
my $live3 = model(columns => { plain => $live->{columns}{plain}, 'other.x' => [ col('id') ] });
is_deeply [ grep { /CREATE SCHEMA/ } ops_sql($live3, $want) ], [],
  '... and the schemas of the live tables count when the model lists none';

is_deeply [ ops_sql($want, $want) ], [], 'the same model is no change';

# a table of the schema that is not wanted any more is dropped, the schema stays
my @drop = ops_sql($want, $live2);
ok scalar(grep { $_ eq 'DROP TABLE other.t;' } @drop),
  'a table of the schema is dropped schema-qualified' or diag join "\n", @drop;
is_deeply [ grep { /DROP SCHEMA/ } @drop ], [], 'the schema itself is never dropped';

# a column and an index of a table in the schema
{
  my $pk = sub { col('id', is_pk => 1, pk_position => 1, not_null => 1, pk_constraint_name => 'PK_t') };
  my $w2 = model(
    columns => { 'other.t' => [ $pk->(), col('n') ] },
    indexes => { 'other.t' => { ix_n => { index_name => 'ix_n', columns => ['n'],
                                          is_unique => 0, kind => 'nonclustered' } } },
    schemas => { dbo => 1, other => 1 });
  my $l2 = model(columns => { 'other.t' => [ $pk->() ] }, schemas => { dbo => 1, other => 1 });
  my @s = ops_sql($l2, $w2);
  is $s[0], 'ALTER TABLE other.t ADD n int;', 'ADD COLUMN in the schema';
  like $s[1], qr/^CREATE NONCLUSTERED INDEX ix_n ON other\.t \(n\);/,
    'CREATE INDEX on a table of the schema';
}

# ---- 4. names
my $n = 0;
for my $bad ('a.b.c', '.t', 's.') {
  my $class = "K72c::S" . ++$n;
  eval "package $class; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); package $class\::Result::T; use base 'DBIO::Core'; __PACKAGE__->table('$bad'); __PACKAGE__->add_columns(id => { data_type => 'integer' }); __PACKAGE__->set_primary_key('id'); 1" or die $@;
  $class->register_class(T => "$class\::Result::T");
  eval { DBIO::MSSQL::DDL->install_ddl($class) };
  like $@, qr/table '\Q$bad\E' is refused/, "the name '$bad' is refused, naming it";
}

done_testing;
