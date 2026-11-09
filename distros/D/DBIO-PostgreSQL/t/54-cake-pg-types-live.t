use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
    eval { require DBI; 1 }
      or plan skip_all => 'DBI not installed';
}

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
    unless $dsn;

BEGIN {
  eval { require Moo; 1 }
    or plan skip_all => 'Moo not installed';
}

use lib 'lib';
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k34 -- the live half of the Cake PG-types coverage. core
# t/cake_comprehensive.t verifies the Cake DSL only at column_info metadata
# level (data_type eq "tsvector"/"vector"/"text[]" etc.); nothing in this dist
# deployed the Cake SYNOPSIS's "PostgreSQL-specific example" (uuid, enum,
# jsonb, vector(1536), array(text), tsvector, idx using => gin) against a real
# PG and round-tripped values. This test does exactly that:
#
#   1. deploy the SYNOPSIS-shaped schema via install_ddl;
#   2. insert/select round-trip (array + jsonb at minimum, plus uuid, enum,
#      vector and tsvector);
#   3. verify the GIN index materializes via pg_catalog introspection.
#
# Requires pgvector on the server (CREATE EXTENSION vector). The extension
# prelude is declarative: the schema declares pg_extensions('vector') and
# install_ddl emits the CREATE EXTENSION as its first statement. We only probe
# availability here to decide the skip; the deploy path owns the actual CREATE
# EXTENSION.
#
# NOTE on the index spelling: a PostgreSQL-specific option of a Cake index is
# written under the `pg` key of the declaration -- `pg => { using => 'gin' }`,
# which is what this test uses. install_ddl reads that block through
# DBIO::ResultSource::index_declarations_for('pg', ...), and refuses what the
# PostgreSQL driver would not write: `options`, a `type` other than unique,
# a key its pg block does not know (karr k129).
#
# NOTE on the vector size: the SYNOPSIS declares `col embedding => vector(1536)`
# (data_type => 'vector', size => 1536). install_ddl used to drop the size and
# deploy plain `vector`, and this file pinned that bug; karr k56 fixed the DDL,
# so the column deploys as vector(1536) and introspection reports exactly that
# -- the declared type, compared as the PostgreSQL string (karr k81).
#
# NOTE on tsvector: loading PostgreSQL::Result also loads
# InflateColumn::TSVector (karr k65, "declaring the column is the whole
# opt-in"), so the accessor returns the lexeme hashref. The raw column value
# is what round-trips as text; both are checked.

my $TABLE = 'dbio_test_cake_pg_types';

my $dbh = LiveServer->control_dbh;

my ($has_vector) = $dbh->selectrow_array(
  q{SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'vector'}
);
unless ($has_vector) {
  $dbh->disconnect;
  plan skip_all => 'pgvector (CREATE EXTENSION vector) not available in the test database';
}

$dbh->do("DROP TABLE IF EXISTS $TABLE CASCADE");
$dbh->do("DROP TYPE IF EXISTS ${TABLE}_role_enum CASCADE");

END {
  return unless $dsn;
  my $h = eval { LiveServer->dbh_or_die(attrs => { RaiseError => 0 }) };
  return unless $h;
  eval {
    $h->do("DROP TABLE IF EXISTS $TABLE CASCADE");
    $h->do("DROP TYPE IF EXISTS ${TABLE}_role_enum CASCADE");
  };
  $h->disconnect;
}

{
  package LiveCakePG::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('vector');
}

{
  package LiveCakePG::Schema::Result::User;
  use DBIO::Moo;
  use DBIO::Cake '-Pg';
  __PACKAGE__->load_components('PostgreSQL::Result');

  table 'dbio_test_cake_pg_types';

  col id         => uuid;
  col name       => varchar(100);
  col role       => enum(qw(admin moderator user guest)), null;
  col metadata   => jsonb, null;
  col embedding  => vector(1536);
  col tags       => array(text), null;
  col tsv        => tsvector null;

  primary_key 'id';
  idx user_tags => ['tags'], pg => { using => 'gin' };
}

LiveCakePG::Schema->register_class(User => 'LiveCakePG::Schema::Result::User');

# -----------------------------------------------------------------------
# DDL structure before deploying
# -----------------------------------------------------------------------

my $ddl = DBIO::PostgreSQL::DDL->install_ddl('LiveCakePG::Schema');

like($ddl, qr/CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;/,
  'install_ddl emits the pgvector prelude from the declarative pg_extensions');
like($ddl, qr/CREATE TYPE\s+dbio_test_cake_pg_types_role_enum\s+AS ENUM/s,
  'DDL contains CREATE TYPE for the Cake enum');
like($ddl, qr/tags\s+text\[\]/s,
  'DDL uses text[] for the array column');
like($ddl, qr/tsv\s+tsvector/s,
  'DDL uses tsvector for the full-text column');
like($ddl, qr/CREATE INDEX user_tags ON dbio_test_cake_pg_types USING gin \(tags\);/s,
  'DDL emits the GIN index (pg => { using => "gin" } form)');

# -----------------------------------------------------------------------
# Deploy
# -----------------------------------------------------------------------

my $deployed = eval {
  for my $stmt (split /;\s*\n/, $ddl) {
    $stmt =~ s/^\s+|\s+$//g;
    next unless $stmt;
    $dbh->do($stmt);
  }
  1;
};
ok($deployed, 'PostgreSQL accepts the generated DDL')
  or do { diag($@); diag($ddl); done_testing; exit 1 };

# -----------------------------------------------------------------------
# CRUD round-trip via DBIO with the Cake result class
# -----------------------------------------------------------------------

my $schema = LiveCakePG::Schema->connect($dsn, $user, $pass);
my $rs = $schema->resultset('User');

my $uuid = '00000000-0000-0000-0000-000000000001';
my $embedding = [ map { 0.25 } 1 .. 1536 ];

subtest 'insert/select round-trip of the SYNOPSIS types' => sub {
  my $row = $rs->create({
    id        => $uuid,
    name      => 'Ada Lovelace',
    role      => 'admin',
    metadata  => { theme => 'dark', flags => [ 1, 2, 3 ] },
    embedding => $embedding,
    tags      => [qw(perl postgresql)],
    tsv       => "'a':1 'cat':2",
  });
  ok($row->id, 'row created');

  my $fetched = $rs->find($uuid);
  is($fetched->name, 'Ada Lovelace', 'varchar round-trips');
  is($fetched->role, 'admin', 'enum round-trips');
  is_deeply($fetched->metadata, { theme => 'dark', flags => [ 1, 2, 3 ] },
    'jsonb round-trips as a hashref');
  is_deeply($fetched->tags, [qw(perl postgresql)],
    'text[] round-trips as an arrayref');
  is(scalar @{ $fetched->embedding }, 1536, 'vector round-trips with 1536 dims');
  is($fetched->embedding->[0], 0.25, 'vector first element');
  is($fetched->embedding->[-1], 0.25, 'vector last element');
  is($fetched->get_column('tsv'), "'a':1 'cat':2", 'tsvector round-trips as text');
  is_deeply($fetched->tsv, { a => ['1'], cat => ['2'] },
    'tsvector accessor inflates to the lexeme hashref');
};

# -----------------------------------------------------------------------
# Introspect: verify the deployed column types and the GIN index
# -----------------------------------------------------------------------

subtest 'introspection sees the deployed types and the GIN index' => sub {
  my $model = DBIO::PostgreSQL::Introspect->new(
    dbh           => $dbh,
    schema_filter => ['public'],
  )->model;

  my $tables = $model->{tables};
  my $table = $tables->{"public.$TABLE"};
  ok($table, "table $TABLE found in introspection");

  # Columns live in $model->{columns}{$table_key}, not inside the table hash.
  my $columns = $model->{columns}{"public.$TABLE"};
  if ($table && $columns) {
    my %by_name = map { $_->{column_name} => $_ } @$columns;
    is($by_name{id}->{data_type}, 'uuid',
      'id column is uuid');
    is($by_name{role}->{data_type}, 'public.dbio_test_cake_pg_types_role_enum',
      'role column is the generated enum type');
    is($by_name{role}->{type_category}, 'e',
      'role type_category is e (enum)');
    is($by_name{metadata}->{data_type}, 'jsonb',
      'metadata column is jsonb');
    is($by_name{embedding}->{data_type}, 'public.vector(1536)',
      'embedding column is vector(1536) of public, as declared');
    is($by_name{tags}->{data_type}, 'text[]',
      'tags column is text[]');
    is($by_name{tsv}->{data_type}, 'tsvector',
      'tsv column is tsvector');
  }

  my $indexes = $model->{indexes}{"public.$TABLE"} || {};
  is($indexes->{user_tags}{access_method}, 'gin',
    'GIN index materializes via introspection');
};

$dbh->disconnect;

done_testing;
