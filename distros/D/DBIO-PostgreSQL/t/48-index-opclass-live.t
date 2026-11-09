use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require DBI; 1 }
      or plan skip_all => 'DBI not installed';
}

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
    unless $dsn;

use lib 'lib';
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k39 -- the live half of the operator-class round-trip. Offline coverage
# (t/47-index-opclass.t) proves what DBIO renders and reconstructs; only a real
# server can prove the two claims that matter here:
#
#   1. PostgreSQL ACCEPTS the DDL we now emit for hnsw/ivfflat. The bug was
#      that pg_index could not name an operator class, which hnsw requires,
#      and no amount of string matching can establish that a statement is
#      legal.
#   2. pg_get_indexdef prints the operator class back in a form our parser
#      recovers, so introspect -> generate -> deploy closes.
#
# pg_get_indexdef prints an operator class only when it is NOT the access
# method's default for the column type. hnsw has no default for vector, but
# ivfflat has one: vector_l2_ops (pg_opclass.opcdefault). So the ivfflat
# recovery claim is made with a non-default class, and the default one gets
# its own claim: nothing is reported, and nothing is lost, because a redeploy
# without it gets the same default back (karr k81).
#
# Requires pgvector on the server (CREATE EXTENSION vector). The extension
# prelude is declarative now (karr k41): the schema below declares
# pg_extensions('vector') and install_ddl emits the CREATE EXTENSION as its
# first statement. We only probe availability here to decide the skip; the
# deploy path owns the actual CREATE EXTENSION.

my $TABLE = 'dbio_test_opclass_items';

my $dbh = LiveServer->control_dbh;

my ($has_vector) = $dbh->selectrow_array(
  q{SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'vector'}
);
unless ($has_vector) {
  $dbh->disconnect;
  plan skip_all => 'pgvector (CREATE EXTENSION vector) not available in the test database';
}

$dbh->do("DROP TABLE IF EXISTS $TABLE CASCADE");

END {
  return unless $dsn;
  my $h = eval { LiveServer->dbh_or_die(attrs => { RaiseError => 0 }) };
  return unless $h;
  eval { $h->do("DROP TABLE IF EXISTS $TABLE CASCADE") };
  $h->disconnect;
}

{
  package LiveOpclass::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('vector');
}

{
  package LiveOpclass::Schema::Result::Item;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id        => { data_type => 'integer',   is_nullable => 0, is_auto_increment => 1 },
    embedding => { data_type => 'vector(3)', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->pg_index("${TABLE}_hnsw_idx" => {
    using     => 'hnsw',
    columns   => ['embedding'],
    opclasses => { embedding => 'vector_cosine_ops' },
    with      => { m => 16, ef_construction => 64 },
  });
  __PACKAGE__->pg_index("${TABLE}_ivf_idx" => {
    using     => 'ivfflat',
    columns   => ['embedding'],
    opclasses => { embedding => 'vector_cosine_ops' },
    with      => { lists => 100 },
  });
  __PACKAGE__->pg_index("${TABLE}_ivf_l2_idx" => {
    using     => 'ivfflat',
    columns   => ['embedding'],
    opclasses => { embedding => 'vector_l2_ops' },
    with      => { lists => 100 },
  });
}

LiveOpclass::Schema->register_class(Item => 'LiveOpclass::Schema::Result::Item');

my $ddl = DBIO::PostgreSQL::DDL->install_ddl('LiveOpclass::Schema');

like($ddl, qr/CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;/,
  'install_ddl emits the pgvector prelude from the declarative pg_extensions');

my $deployed = eval {
  for my $stmt (split /;\s*\n/, $ddl) {
    $stmt =~ s/^\s+|\s+$//g;
    next unless $stmt;
    $dbh->do($stmt);
  }
  1;
};
ok($deployed, 'PostgreSQL accepts the generated hnsw and ivfflat CREATE INDEX statements')
  or do { diag($@); diag($ddl); done_testing; exit 1 };

my $intro = DBIO::PostgreSQL::Introspect->new(
  dbh           => $dbh,
  schema_filter => ['public'],
);

my $indexes = $intro->model->{indexes}{"public.$TABLE"} || {};

is_deeply(
  $indexes->{"${TABLE}_hnsw_idx"}{opclasses},
  { embedding => 'public.vector_cosine_ops' },
  'hnsw operator class recovered from pg_get_indexdef',
);
is_deeply(
  $indexes->{"${TABLE}_ivf_idx"}{opclasses},
  { embedding => 'public.vector_cosine_ops' },
  'ivfflat operator class recovered from pg_get_indexdef',
);
is_deeply(
  $indexes->{"${TABLE}_ivf_l2_idx"}{opclasses},
  {},
  'the default ivfflat operator class is not in pg_get_indexdef, so none is reported',
);

my ($l2_is_default) = $dbh->selectrow_array(q{
  SELECT oc.opcdefault
  FROM pg_catalog.pg_opclass oc
  JOIN pg_catalog.pg_am am ON am.oid = oc.opcmethod
  WHERE am.amname = 'ivfflat'
    AND oc.opcname = 'vector_l2_ops'
    AND oc.opcintype = 'vector'::pg_catalog.regtype
});
ok($l2_is_default,
  'vector_l2_ops is the ivfflat default for vector: a redeploy without it gets it back');

my %reconstructed = map { $_->[1] => $_->[2] }
  grep { $_->[0] eq 'pg_index' }
  $intro->result_class_extra_statements("public.$TABLE");

is(
  $reconstructed{"${TABLE}_hnsw_idx"}{opclasses}{embedding},
  'public.vector_cosine_ops',
  'generate path keeps the operator class for the hnsw index',
);
is(
  $reconstructed{"${TABLE}_ivf_idx"}{opclasses}{embedding},
  'public.vector_cosine_ops',
  'generate path keeps the operator class for the ivfflat index',
);
ok(
  !exists $reconstructed{"${TABLE}_ivf_l2_idx"}{opclasses},
  'generate path names no operator class where the default applies',
);

$dbh->disconnect;

done_testing;
