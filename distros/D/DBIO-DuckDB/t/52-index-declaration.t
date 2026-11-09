use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::DuckDB::DDL;
use DBIO::DuckDB::Deploy;

# The index declaration is canonical on the result source (ADR 0061 in core,
# karr k41): Cake idx and indices() write it and the DDL reads it. Before,
# only duckdb_indexes was read, and a Cake class got no CREATE INDEX at all
# -- neither in the install DDL nor in the desired model of a diff.

{
  package IdxDdl::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DuckDB');
}
{
  package IdxDdl::Schema::Result::Person;
  use DBIO::Cake;

  table 'person';
  col id    => integer;
  col name  => varchar(100);
  col city  => varchar(100);
  col state => varchar(10);

  primary_key 'id';

  idx name_idx     => ['name'];
  idx name_city_uq => ['name', 'city'], type => 'unique';
  idx 'odd"idx'    => ['state'];

  __PACKAGE__->indices(state_idx => 'state');
}
IdxDdl::Schema->register_class(Person => 'IdxDdl::Schema::Result::Person');

{
  package IdxHand::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DuckDB');
}
{
  package IdxHand::Schema::Result::Person;
  use DBIO::Cake;

  table 'person';
  col id   => integer;
  col name => varchar(100);
  col city => varchar(100);
  primary_key 'id';

  # written by hand, in the own namespace; same_name is also declared
  # canonically below
  __PACKAGE__->mk_classdata(duckdb_indexes => {
    hand_idx  => { columns => ['city'] },
    same_name => { columns => ['city'] },
  });
  idx same_name => ['name'];
}
IdxHand::Schema->register_class(Person => 'IdxHand::Schema::Result::Person');

# A schema whose one table carries the one declaration given, stored straight
# on the source (the layer Cake's idx writes to).
sub schema_with {
  my ($tag, $decl) = @_;
  my $schema = "IdxRef${tag}::Schema";
  my $class  = "${schema}::Result::T";
  eval <<"PERL" or die $@;
    package $schema;  use base 'DBIO::Schema';
    __PACKAGE__->load_components('DuckDB');
    package $class;   use DBIO::Cake;
    table 't'; col id => integer; col a => varchar(10); primary_key 'id';
    1;
PERL
  $class->result_source_instance->add_index_declaration($decl);
  $schema->register_class(T => $class);
  return $schema;
}

# --- install_ddl carries the canonical declarations
{
  my $ddl = DBIO::DuckDB::DDL->install_ddl('IdxDdl::Schema');
  like $ddl, qr/^CREATE INDEX "name_idx" ON "person" \("name"\);$/m, 'idx: simple index';
  like $ddl, qr/^CREATE UNIQUE INDEX "name_city_uq" ON "person" \("name", "city"\);$/m,
    'idx: unique, several columns';
  like $ddl, qr/^CREATE INDEX "state_idx" ON "person" \("state"\);$/m, 'indices(): index';
  like $ddl, qr/^CREATE INDEX "odd""idx" ON "person" \("state"\);$/m,
    'the index name is quoted as an identifier';
}

# --- hand-written stays valid; the same name: canonical wins
{
  my $ddl = DBIO::DuckDB::DDL->install_ddl('IdxHand::Schema');
  like $ddl, qr/^CREATE INDEX "hand_idx" ON "person" \("city"\);$/m, 'hand-written index kept';
  like $ddl, qr/^CREATE INDEX "same_name" ON "person" \("name"\);$/m, 'same name: canonical wins';
  is scalar(() = $ddl =~ /INDEX "same_name" /g), 1, 'the name is created once';
}

# --- the desired model of a diff carries them
{
  my $schema = IdxDdl::Schema->connect('dbi:DuckDB:dbname=:memory:');
  $schema->storage->dbh->do(q{CREATE TABLE person (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(100) NOT NULL, city VARCHAR(100) NOT NULL, state VARCHAR(10) NOT NULL)});
  my $diff = DBIO::DuckDB::Deploy->new(schema => $schema)->diff;
  my $sql = $diff->as_sql;
  like $sql, qr/CREATE INDEX name_idx ON person\("?name"?\)/,
    'diff creates a missing declared index';
  like $sql, qr/CREATE UNIQUE INDEX name_city_uq ON person\("?name"?, "?city"?\)/,
    'diff creates the unique one';
}
{
  my $schema = IdxDdl::Schema->connect('dbi:DuckDB:dbname=:memory:');
  my $deploy = DBIO::DuckDB::Deploy->new(schema => $schema);
  $deploy->install;
  my $names = $schema->storage->dbh->selectcol_arrayref(
    q{SELECT index_name FROM duckdb_indexes() ORDER BY 1});
  is_deeply [ sort @$names ], [ sort 'name_idx', 'name_city_uq', 'state_idx', 'odd"idx' ],
    'deploy creates the declared indexes';
  ok !$deploy->diff->has_changes, 'diff after install is empty'
    or diag $deploy->diff->as_sql;
}

# --- what DuckDB cannot do is refused, never a plainer index
{
  my %case = (
    where   => [ { name => 'w', columns => ['a'], driver => { duckdb => { where => 'a > 1' } } },
                 qr/unknown key 'where'/, 'partial index (where) refused' ],
    using   => [ { name => 'u', columns => ['a'], driver => { duckdb => { using => 'art' } } },
                 qr/unknown key 'using'/, 'any other own key refused' ],
    exprwh  => [ { name => 'ew', columns => ['a'], driver => { duckdb => { expression => 'lower(a)', where => 'a > 1' } } },
                 qr/unknown key 'where'/, 'expression plus where refused' ],
    exprempty => [ { name => 'ee', columns => ['a'], driver => { duckdb => { expression => ' ' } } },
                 qr/empty expression/, 'empty expression refused' ],
    type    => [ { name => 't', columns => ['a'], type => 'fulltext' },
                 qr/type 'fulltext'/, 'a type other than unique refused' ],
    options => [ { name => 'o', columns => ['a'], options => { fillfactor => 70 } },
                 qr/with options/, 'options refused' ],
    foreign => [ { name => 'p', columns => ['a'], driver => { pg => { where => 'a > 1' } } },
                 qr/carries only the 'pg' block/, 'a block of another driver only refused' ],
  );
  for my $tag (sort keys %case) {
    my ($decl, $re, $msg) = @{ $case{$tag} };
    my $s = schema_with(ucfirst $tag, $decl);
    throws_ok { DBIO::DuckDB::DDL->install_ddl($s) } $re, $msg;
  }
}

# --- expression indexes (ADR 0008 addendum, karr k44): the expression is
# written, introspected as an expression, and the second diff is empty. Before,
# Introspect read the column inside lower(b) and the index drifted for good.
{
  package IdxExpr::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DuckDB');
}
{
  package IdxExpr::Schema::Result::T;
  use DBIO::Cake;
  table 't'; col id => integer; col a => varchar(10); col b => varchar(10);
  primary_key 'id';
  idx lower_b  => ['b'], duckdb => { expression => 'lower(b)' };
  idx a_lower  => ['a'], type => 'unique',
    duckdb => { expression => 'a, lower(b)' };
}
IdxExpr::Schema->register_class(T => 'IdxExpr::Schema::Result::T');
{
  my $ddl = DBIO::DuckDB::DDL->install_ddl('IdxExpr::Schema');
  like $ddl, qr/^CREATE INDEX "lower_b" ON "t" \(lower\(b\)\);$/m, 'expression written';
  like $ddl, qr/^CREATE UNIQUE INDEX "a_lower" ON "t" \(a, lower\(b\)\);$/m,
    'mixed, unique';

  my $schema = IdxExpr::Schema->connect('dbi:DuckDB:dbname=:memory:');
  my $deploy = DBIO::DuckDB::Deploy->new(schema => $schema);
  $deploy->install;
  my $live = DBIO::DuckDB::Introspect->new(dbh => $schema->storage->dbh)->model;
  is_deeply $live->{indexes}{t}{lower_b}{columns}, ['(lower(b))'],
    'introspect reads the expression, not the column';
  is_deeply $live->{indexes}{t}{a_lower}{columns}, ['a', '(lower(b))'],
    'mixed list: column and expression';
  ok $live->{indexes}{t}{a_lower}{is_unique}, 'unique kept';
  ok !$deploy->diff->has_changes, 'second diff is empty'
    or diag $deploy->diff->as_sql;

  # the declared expression changes: drop and create, then settled again
  $schema->storage->dbh->do('DROP INDEX lower_b');
  $schema->storage->dbh->do('CREATE INDEX lower_b ON t (upper(b))');
  my $sql = $deploy->diff->as_sql;
  like $sql, qr/DROP INDEX .*lower_b/, 'a changed expression is dropped';
  like $sql, qr/CREATE INDEX lower_b ON t\(\(lower\(b\)\)\)/, 'and created again';
}

done_testing;
