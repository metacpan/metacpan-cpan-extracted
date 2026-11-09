use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::Core ();
use DBIO::MSSQL::Deploy;
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Introspect;

# LIVE (karr k72). Counterpart of t/111-ddl-cross-schema.t (offline).
#
# A table or view "schema.table" is made in that schema; the schema is created
# when it is missing (a batch of its own: CREATE SCHEMA must be the first
# statement of its batch). Against SQL Server, in a database of its own per
# scenario (dbio_mssql_k72_<pid>_<n>, dropped at the end):
#   A. install into a database without the schema: schema, tables, keys in it,
#      a key across the border both ways, the key named after the bare table;
#      the second diff is empty; the tables work through the SQLMaker
#      ([other].[child]) -- the runtime was always right, the DDL was not;
#   B. upgrade: a database with dbo.base only; the diff adds the schema and the
#      tables, the server accepts the script, the second diff is empty;
#   C. the same table name in dbo and in the schema, the one with an IDENTITY
#      column and the other without: the introspect must not mix them (the
#      second diff is empty), and an upgrade inside the schema works: a column,
#      an index, a unique constraint;
#   D. a schema that exists already is not created again; a table of the schema
#      that the classes no longer declare is dropped and the schema stays;
#   E. two schemas, the same table and constraint names in both (constraint
#      names are per schema);
#   F. a database that ignores case: schema and table spelt in another case
#      than the live ones are no change.

my @paths = grep { $_->[0] && defined $_->[1] } (
  [ @ENV{qw/DBIO_TEST_MSSQL_ODBC_DSN DBIO_TEST_MSSQL_ODBC_USER DBIO_TEST_MSSQL_ODBC_PASS/} ],
  [ @ENV{qw/DBIO_TEST_MSSQL_DSN      DBIO_TEST_MSSQL_USER      DBIO_TEST_MSSQL_PASS/}      ],
);
plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN} (or DBIO_TEST_MSSQL_DSN), _USER and _PASS to run this test'
  unless @paths;

my %conn = (RaiseError => 1, PrintError => 0, PrintWarn => 0, AutoCommit => 1);
my $seq = 0;

# declared: [ [ Name => table, [columns], \%opts ], ... ]; opts: fk => [rel, Target, col],
# index => { name => {columns} }, unique => [[cols]]
sub schema_class {
  my ($tag, $tables) = @_;
  my $sc = "K72Live::${tag}::Schema";
  eval "package $sc; use DBIO 'Schema'; __PACKAGE__->load_components('MSSQL'); 1" or die $@;
  for my $t (@$tables) {
    my ($name, $table, $cols, $o) = @$t;
    $o ||= {};
    my $rc = "$sc\::Result::$name";
    eval "package $rc; use base 'DBIO::Core'; __PACKAGE__->load_components('MSSQL::Result'); 1" or die $@;
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key($cols->[0]);
    $rc->mssql_index($_ => $o->{index}{$_}) for sort keys %{ $o->{index} || {} };
    $rc->add_unique_constraint($_) for @{ $o->{unique} || [] };
  }
  for my $t (@$tables) {
    my ($name, undef, undef, $o) = @$t;
    for my $fk (@{ ($o || {})->{fk} || [] }) {
      "$sc\::Result::$name"->belongs_to($fk->[0], "$sc\::Result::$fk->[1]", $fk->[2]);
    }
  }
  $sc->register_class($_->[0] => "$sc\::Result::$_->[0]") for @$tables;
  return $sc;
}

my $ID = { data_type => 'integer', is_auto_increment => 1 };

sub run {
  my ($dsn, $user, $pass, $label) = @_;
  my ($dbd) = $dsn =~ /^dbi:(\w+)/i;
  my $admin = DBI->connect($dsn, $user, $pass, \%conn);

  my $scenario = sub {
    my ($name, %arg) = @_;
    my $db = sprintf 'dbio_mssql_k72_%d_%d', $$, ++$seq;
    my $dsn_db = $dsn;
    $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
      or $dsn_db .= ($dbd eq 'Sybase' ? ';database=' : ';Database=') . $db;
    $admin->do("CREATE DATABASE [$db]");
    my $ok = eval {
      my $dbh = DBI->connect($dsn_db, $user, $pass, \%conn);
      $dbh->do($_) for @{ $arg{before} || [] };
      my $sc = schema_class("${label}_" . ($name =~ s/\W/_/gr), $arg{declare});
      my $schema = $sc->connect($dsn_db, $user, $pass, { %conn });
      $arg{run}->($dbh, $schema);
      my $again = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
      ok !$again->has_changes, "$label $name: the second diff is empty"
        or diag $again->summary . "\n" . $again->as_sql;
      $schema->storage->disconnect;
      $dbh->disconnect;
      1;
    };
    my $err = $@;
    eval {
      $admin->do("IF DB_ID('$db') IS NOT NULL BEGIN ALTER DATABASE [$db] "
        . "SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$db] END");
      1;
    } or diag "could not drop $db: $@";
    die $err unless $ok;
  };

  my $in_schema = sub {
    my ($dbh, $schema, $table) = @_;
    my ($n) = $dbh->selectrow_array(
      'SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = ? AND table_name = ?',
      undef, $schema, $table);
    return $n;
  };

  # A. install into a database that has no such schema
  $scenario->('install', declare => [
    [ Base   => 'base',         [ id => $ID ] ],
    [ Parent => 'other.parent', [ id => $ID, code => { data_type => 'varchar', size => 20 } ],
      { unique => [ [ 'code' ] ] } ],
    [ Child  => 'other.child',  [ id => $ID, parent_id => { data_type => 'integer' },
                                  base_id => { data_type => 'integer', is_nullable => 1 } ],
      { fk => [ [ parent => 'Parent', 'parent_id' ], [ base => 'Base', 'base_id' ] ],
        index => { child_parent_idx => { columns => ['parent_id'] } } } ],
    [ Back   => 'dbo.back',     [ id => $ID, child_id => { data_type => 'integer' } ],
      { fk => [ [ child => 'Child', 'child_id' ] ] } ],
  ], run => sub {
    my ($dbh, $schema) = @_;
    my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
    my $ok = eval { $deploy->install; 1 };
    ok $ok, "$label A: install runs (CREATE SCHEMA and the tables)" or diag $@;
    ok $in_schema->($dbh, 'other', 'parent'), "$label A: other.parent is in the schema other";
    ok $in_schema->($dbh, 'other', 'child'),  "$label A: other.child too";
    ok $in_schema->($dbh, 'dbo', 'back'),     "$label A: dbo.back is in dbo";
    is $in_schema->($dbh, 'dbo', 'other.parent'), 0, "$label A: no table 'other.parent' in dbo";
    my $fks = $dbh->selectall_arrayref(q{
      SELECT fk.name, SCHEMA_NAME(pt.schema_id) + '.' + pt.name, SCHEMA_NAME(rt.schema_id) + '.' + rt.name
      FROM sys.foreign_keys fk
      JOIN sys.tables pt ON pt.object_id = fk.parent_object_id
      JOIN sys.tables rt ON rt.object_id = fk.referenced_object_id
      ORDER BY fk.name});
    is_deeply $fks, [
      [ 'FK_back_child_id',   'dbo.back',     'other.child'  ],
      [ 'FK_child_base_id',   'other.child',  'dbo.base'     ],
      [ 'FK_child_parent_id', 'other.child',  'other.parent' ],
    ], "$label A: the keys inside the schema and across the border, both ways";
    my ($pk) = $dbh->selectrow_array(q{SELECT name FROM sys.key_constraints
      WHERE type = 'PK' AND parent_object_id = OBJECT_ID('other.parent')});
    is $pk, 'PK_parent', "$label A: the key is named after the bare table";
    my $model = DBIO::MSSQL::Introspect->new(dbh => $dbh, schemas => ['other'])->model;
    is_deeply [ sort keys %{ $model->{tables} } ], [ qw(back base other.child other.parent) ],
      "$label A: the model keys the schema's tables schema.table, dbo bare";
    is_deeply [ sort keys %{ $model->{schemas} || {} } ], [ qw(dbo other) ],
      "$label A: and lists the schemas that exist";
    my ($fk) = grep { $_->{constraint_name} eq 'FK_child_base_id' } @{ $model->{foreign_keys}{'other.child'} };
    is $fk && $fk->{to_table}, 'base', "$label A: a key into dbo says the bare table";
    ($fk) = grep { $_->{constraint_name} eq 'FK_back_child_id' } @{ $model->{foreign_keys}{back} };
    is $fk && $fk->{to_table}, 'other.child', "$label A: a key into the schema says schema.table";
    # the tables work through the SQLMaker
    my $parent = eval { $schema->resultset('Parent')->create({ code => 'p1' }) };
    ok $parent, "$label A: create() into other.parent" or diag $@;
    my $child = eval { $schema->resultset('Child')->create({ parent_id => $parent->id }) };
    ok $child, "$label A: create() into other.child, the key across the schema holds" or diag $@;
    is eval { $schema->resultset('Child')->search({ parent_id => $parent->id })->count }, 1,
      "$label A: and it is read back";
  });

  # B. upgrade: a database with the dbo table only
  $scenario->('upgrade', before => [
    'CREATE TABLE base (id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_base PRIMARY KEY)',
  ], declare => [
    [ Base  => 'base',        [ id => $ID ] ],
    [ Other => 'other.thing', [ id => $ID, base_id => { data_type => 'integer' } ],
      { fk => [ [ base => 'Base', 'base_id' ] ] } ],
  ], run => sub {
    my ($dbh, $schema) = @_;
    my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
    my $diff = $deploy->diff;
    my @sql = grep { length } split /\n(?=\S)/, $diff->as_sql;
    is $sql[0], 'CREATE SCHEMA other;', "$label B: the diff starts with the schema";
    like $diff->summary, qr/^\+ schema: other$/m, "$label B: the summary says so";
    like $sql[1], qr/^CREATE TABLE other\.thing /, "$label B: then the table, in the schema";
    my $ok = eval { $deploy->apply($diff, allow_destructive => 1); 1 };
    ok $ok, "$label B: the server accepts the script" or diag $@ . "\n" . $diff->as_sql;
    ok $in_schema->($dbh, 'other', 'thing'), "$label B: other.thing exists";
  });

  # C. the same name in dbo and in the schema; an upgrade inside the schema
  $scenario->('same name', before => [
    'CREATE TABLE t (id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_t PRIMARY KEY, n bigint NULL)',
    'CREATE SCHEMA other',
    'CREATE TABLE other.t (id bigint NOT NULL CONSTRAINT PK_t PRIMARY KEY)',
  ], declare => [
    [ Dbo   => 't',       [ id => $ID, n => { data_type => 'integer', is_nullable => 1 } ] ],
    [ Other => 'other.t', [ id => { data_type => 'integer' },
                            n  => { data_type => 'integer', is_nullable => 1 },
                            name => { data_type => 'varchar', size => 20, is_nullable => 1 } ],
      { index => { t_n_idx => { columns => ['n'] } }, unique => [ [ 'name' ] ] } ],
  ], run => sub {
    my ($dbh, $schema) = @_;
    my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
    my $model = DBIO::MSSQL::Introspect->new(dbh => $dbh, schemas => ['other'])->model;
    my ($dbo_id)   = grep { $_->{column_name} eq 'id' } @{ $model->{columns}{t} };
    my ($other_id) = grep { $_->{column_name} eq 'id' } @{ $model->{columns}{'other.t'} };
    ok $dbo_id->{is_identity}, "$label C: t.id is an identity column";
    ok !$other_id->{is_identity}, "$label C: other.t.id, same names, is not (the schemas are not mixed)";
    my $diff = $deploy->diff;
    my $sql = $diff->as_sql;
    unlike $sql, qr/CREATE SCHEMA/, "$label C: the schema is there, not created again";
    unlike $sql, qr/DROP TABLE|CREATE TABLE/, "$label C: no table is dropped or made";
    like $sql, qr/ALTER TABLE other\.t ADD n bigint;/, "$label C: the column is added to the table of the schema";
    like $sql, qr/CREATE NONCLUSTERED INDEX t_n_idx ON other\.t \(n\);/, "$label C: the index too";
    like $sql, qr/ALTER TABLE other\.t ADD CONSTRAINT UQ_t_name UNIQUE \(name\);/,
      "$label C: and the unique constraint, named after the bare table";
    my $ok = eval { $deploy->apply($diff, allow_destructive => 1); 1 };
    ok $ok, "$label C: the server accepts it" or diag $@ . "\n" . $sql;
  });

  # D. the schema exists; a table of it is no longer declared
  $scenario->('drop', before => [
    'CREATE SCHEMA other',
    'CREATE TABLE other.keep (id bigint NOT NULL CONSTRAINT PK_keep PRIMARY KEY)',
    'CREATE TABLE other.gone (id bigint NOT NULL CONSTRAINT PK_gone PRIMARY KEY)',
  ], declare => [
    [ Keep => 'other.keep', [ id => { data_type => 'integer' } ] ],
    [ New  => 'other.fresh', [ id => { data_type => 'integer' } ] ],
  ], run => sub {
    my ($dbh, $schema) = @_;
    my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
    my $diff = $deploy->diff;
    unlike $diff->as_sql, qr/CREATE SCHEMA|DROP SCHEMA/, "$label D: the schema is neither created nor dropped";
    like $diff->as_sql, qr/DROP TABLE other\.gone;/, "$label D: the table the classes do not declare is dropped";
    my $ok = eval { $deploy->apply($diff, allow_destructive => 1); 1 };
    ok $ok, "$label D: the server accepts it" or diag $@;
    ok !$in_schema->($dbh, 'other', 'gone'), "$label D: other.gone is gone";
    ok $in_schema->($dbh, 'other', 'fresh'), "$label D: other.fresh is there";
    # and when nothing is declared in the schema any more: the schema stays
    my ($s) = $dbh->selectrow_array(q{SELECT COUNT(*) FROM sys.schemas WHERE name = 'other'});
    is $s, 1, "$label D: the schema stays";
  });

  # E. two schemas, the same names in both
  $scenario->('two schemas', declare => [
    [ A => 'one.t', [ id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 10 } ],
      { unique => [ [ 'name' ] ], index => { t_name_idx => { columns => ['name'] } } } ],
    [ B => 'two.t', [ id => { data_type => 'integer' }, name => { data_type => 'varchar', size => 10 } ],
      { unique => [ [ 'name' ] ], index => { t_name_idx => { columns => ['name'] } } } ],
  ], run => sub {
    my ($dbh, $schema) = @_;
    my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
    my $ok = eval { $deploy->install; 1 };
    ok $ok, "$label E: the same table, constraint and index names in two schemas install" or diag $@;
    ok $in_schema->($dbh, 'one', 't') && $in_schema->($dbh, 'two', 't'), "$label E: one.t and two.t";
  });

  # F. the database ignores case (the server default): the classes spell the
  # schema and the table in another case than the database, no change
  $scenario->('case', before => [
    'CREATE SCHEMA other',
    'CREATE TABLE other.t (id bigint NOT NULL CONSTRAINT PK_t PRIMARY KEY)',
  ], declare => [
    [ Up => 'Other.T', [ id => { data_type => 'integer' } ] ],
  ], run => sub {
    my ($dbh, $schema) = @_;
    my $diff = DBIO::MSSQL::Deploy->new(schema => $schema)->diff;
    ok !$diff->has_changes, "$label F: Other.T is other.t in a case-insensitive database"
      or diag $diff->summary . "\n" . $diff->as_sql;
  });

  $admin->disconnect;
}

for my $p (@paths) {
  my ($dbd) = $p->[0] =~ /^dbi:(\w+)/i;
  run(@$p, $dbd);
}

my @left = do {
  my $admin = DBI->connect(@{ $paths[0] }, \%conn);
  map { $_->[0] } @{ $admin->selectall_arrayref(
    q{SELECT name FROM sys.databases WHERE name LIKE 'dbio[_]mssql[_]k72[_]%'}) };
};
is_deeply \@left, [], 'no database of this test is left behind';

done_testing;
