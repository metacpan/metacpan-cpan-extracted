use strict;
use warnings;
use Test::More;
use DBIO::Schema::ModelCompiler ();
use DBIO::PostgreSQL::Adapter ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Diff ();

unless ($ENV{DBIO_TEST_PG_DSN}) {
  plan skip_all => 'DBIO_TEST_PG_DSN not set';
}

# Schema covering all 8 portable base types.
{
  package RT::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('things');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'char',    size => 32 },
    bio  => { data_type => 'text',    is_nullable => 1 },
    ok   => { data_type => 'boolean' },
    amt  => { data_type => 'numeric', size => [10,2] },
    rate => { data_type => 'double' },
    data => { data_type => 'blob',    is_nullable => 1 },
    seen => { data_type => 'timestamp' },
  );
  __PACKAGE__->set_primary_key('id');

  package RT::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Thing => 'RT::Result::Thing');
}

my $schema = RT::Schema->connect(
  $ENV{DBIO_TEST_PG_DSN},
  $ENV{DBIO_TEST_PG_USER},
  $ENV{DBIO_TEST_PG_PASS},
);

# Drop and recreate the table with PG-native types matching the adapter output.
# id uses GENERATED ALWAYS AS IDENTITY (bigint) — the canonical DBIO convention
# for auto-increment integer PKs in PostgreSQL.
$schema->storage->dbh_do(sub {
  my ($s, $dbh) = @_;
  $dbh->do('DROP TABLE IF EXISTS things');
  $dbh->do(q{
    CREATE TABLE things (
      id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
      name character(32)      NOT NULL,
      bio  text,
      ok   boolean            NOT NULL,
      amt  numeric(10,2)      NOT NULL,
      rate double precision   NOT NULL,
      data bytea,
      seen timestamptz        NOT NULL
    )
  });
});

my $compiled = DBIO::Schema::ModelCompiler
  ->new(adapter => DBIO::PostgreSQL::Adapter->new)
  ->compile($schema);

my $source = DBIO::PostgreSQL::Introspect
  ->new(dbh => $schema->storage->dbh)
  ->model;

my $target = DBIO::PostgreSQL::Diff->target_from_compiled($compiled);

my $diff = DBIO::PostgreSQL::Diff->new(source => $source, target => $target);

ok !$diff->has_changes, 'round-trip diff is empty (base-type schema, PG-native deploy)'
  or do {
    diag $diff->summary;
    diag 'SOURCE columns: ' . do {
      require Data::Dumper; local $Data::Dumper::Sortkeys = 1;
      Data::Dumper::Dumper($source->{columns}{'public.things'});
    };
    diag 'TARGET columns: ' . do {
      require Data::Dumper; local $Data::Dumper::Sortkeys = 1;
      Data::Dumper::Dumper($target->{columns}{'public.things'});
    };
  };

# Drop artefacts so they do not leak into later tests' introspect snapshots.
END {
  return unless $ENV{DBIO_TEST_PG_DSN};
  my $h = eval { DBI->connect(
    $ENV{DBIO_TEST_PG_DSN}, $ENV{DBIO_TEST_PG_USER}, $ENV{DBIO_TEST_PG_PASS},
    { RaiseError => 0, PrintError => 0 }
  ) };
  return unless $h;
  eval { $h->do('DROP TABLE IF EXISTS things CASCADE') };
  $h->disconnect;
}

done_testing;
