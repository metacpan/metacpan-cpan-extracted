use strict;
use warnings;
use Test::More;
use DBIO::Schema::ModelCompiler ();
use DBIO::PostgreSQL::Adapter ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Diff ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

unless ($ENV{DBIO_TEST_PG_DSN}) {
  plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test';
}

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

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
  use DBIO 'Schema', -pg;
  __PACKAGE__->register_class(Thing => 'RT::Result::Thing');
}

# The diff below compares the WHOLE introspected database with the compiled
# target, so it runs in a database of its own: anything else installed in the
# shared one -- pgvector, left there by t/48 and t/54 -- is a difference too.
# Dropping that database at the end also replaces the table cleanup this file
# used to do in the shared one (karr k81).
my $schema = RT::Schema->connect(PrivatePgDatabase->create('t28'));

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

done_testing;
