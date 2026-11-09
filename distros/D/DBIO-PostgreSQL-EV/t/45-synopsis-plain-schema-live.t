use strict;
use warnings;
use Test::More;

# LIVE check that the SYNOPSIS of DBIO::PostgreSQL::EV runs as written (karr
# k36).
#
# The claim: a schema that declares its driver with the shortcut alone --
# use DBIO 'Schema', -pg, which pins storage_type to DBIO::PostgreSQL::Storage
# and loads no component -- with a plain DBIO::Core result class, connected
# with a dbi:Pg: DSN and { async => 'ev' }, gets this distribution's
# transport. The declared driver registers the 'ev' mode, and nothing else in
# the schema class takes part. The POD shows exactly that setup and recommends
# no load_components. Should the ev mode ever come to depend on
# load_components('PostgreSQL') -- or on loading this distribution's main
# module -- the SYNOPSIS is wrong and this file is red. A schema that declares
# no driver is refused at connect (core ADR 0067); before that ADR the
# SYNOPSIS declared none and the DSN chose the driver.
#
# Most other live files connect a schema that loads 'PostgreSQL' (the
# TestHarness default schema included), and none of them runs the SYNOPSIS
# step by step.
#
# The steps follow the SYNOPSIS in its order: sync all, create_async ->
# all_async -> get, listen / notify, copy_in, pipeline. Table and channel
# carry a k36_ prefix so they collide with nothing else.
#
# Not covered, on purpose: deploy_async. Over this transport it runs
# DBIO::PostgreSQL::DDL, which calls the PostgreSQL schema component's
# pg_extensions / pg_schemas on the schema, so without the component it dies. The
# SYNOPSIS does not show it; the table is created with plain SQL instead.

use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

# A server that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

use DBIO::Storage::Async ();

plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');

# Every wait below is a Future's get, which runs the EV loop. A hang ends the
# process (SIGALRM, no handler) instead of the run.
alarm 120;

{
  package DBIO::PostgreSQL::EV::SynopsisLive::Artist;
  use base 'DBIO::Core';
  __PACKAGE__->table('k36_synopsis_artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');

  package DBIO::PostgreSQL::EV::SynopsisLive::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->register_class(Artist => 'DBIO::PostgreSQL::EV::SynopsisLive::Artist');
}

my $SCHEMA  = 'DBIO::PostgreSQL::EV::SynopsisLive::Schema';
my $table   = 'k36_synopsis_artist';
my $channel = 'k36_synopsis_artists';

# The premise: the shortcut declares the driver, and nothing else on the
# schema class chooses a driver or a transport.
is($SCHEMA->storage_type, '+DBIO::PostgreSQL::Storage',
  'the shortcut declares the sync driver');
ok !$SCHEMA->isa('DBIO::PostgreSQL'),
  'the schema class does not load the PostgreSQL component';
ok !$SCHEMA->isa('DBIO::PostgreSQL::EV'),
  'the schema class does not load DBIO::PostgreSQL::EV';

# The harness connects exactly as the SYNOPSIS does:
# $SCHEMA->connect($dsn, $user, $pass, { async => 'ev' }).
my $h = DBIO::PostgreSQL::EV::TestHarness->new(schema_class => $SCHEMA);
my $schema = $h->schema;

END {
  return unless $h;
  eval { $schema->storage->dbh->do("DROP TABLE IF EXISTS $table") };
  eval { $h->disconnect };
}

$schema->storage->dbh->do("DROP TABLE IF EXISTS $table");
$schema->storage->dbh->do("CREATE TABLE $table (id serial PRIMARY KEY, name text)");

# Asserted after the storage has been used: an access path is adapted to
# lazily.
isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage',
  'the storage is the declared sync driver';

my $artists = $schema->resultset('Artist');

# --- Sync calls run over DBI / DBD::Pg ----------------------------------------

my @all = $artists->all;
is scalar(@all), 0, 'sync all runs (empty table)';

# --- *_async calls run over EV::Pg and return Futures -------------------------

my @nina = $artists->create_async({ name => 'Nina Simone' })
  ->then(sub { $artists->search({ name => 'Nina Simone' })->all_async })
  ->get;
is scalar(@nina), 1, 'create_async -> all_async -> get finds the created row';
isa_ok $nina[0], 'DBIO::PostgreSQL::EV::SynopsisLive::Artist', 'the row';
is $nina[0]->name, 'Nina Simone', 'with the created name';
like $nina[0]->id, qr/^\d+$/, 'and the id the server gave it';

# --- The transport ------------------------------------------------------------

my $async = $schema->storage->async;
isa_ok $async, 'DBIO::PostgreSQL::EV::Storage',
  '$schema->storage->async -- the ev transport';

# --- LISTEN / NOTIFY ----------------------------------------------------------

my $got = $async->future_class->new;
$async->listen($channel => sub {
  my ($ch, $payload, $sender_pid) = @_;
  $got->done($ch, $payload, $sender_pid) unless $got->is_ready;
})->get;
$async->notify($channel => 'changed')->get;

my ($ch, $payload, $sender_pid) = $got->get;
is $ch, $channel, 'the notification arrived on the listened channel';
is $payload, 'changed', 'with the notified payload';
like $sender_pid, qr/^\d+$/, 'and the sender backend pid';
$async->unlisten($channel)->get;

# --- COPY ---------------------------------------------------------------------

$async->copy_in($table, [qw( name )], sub {
  my ($put) = @_;
  $put->([ $_ ]) for 'Miles Davis', 'John Coltrane';
})->get;
is_deeply [ sort map { $_->name } $artists->search({ name => [ 'Miles Davis', 'John Coltrane' ] })->all ],
  [ 'John Coltrane', 'Miles Davis' ],
  'copy_in loaded both rows (read back over the sync connection)';

# --- Pipeline mode ------------------------------------------------------------

my $source = $schema->source('Artist');
my @rows = $async->pipeline(sub {
  my ($batch) = @_;
  $batch->future_class->needs_all(
    map { $batch->insert_async($source, { name => $_ }) }
      'Billie Holiday', 'Ella Fitzgerald'
  );
})->get;
is scalar(@rows), 2, 'pipeline resolves one result per batched insert';
is_deeply [ sort map { $_->{name} } @rows ], [ 'Billie Holiday', 'Ella Fitzgerald' ],
  'each a returned-columns hashref with the inserted name';
is scalar(grep { !defined $_->{id} } @rows), 0, '... and the id RETURNING read back';

is $artists->count, 5, 'all five rows are in the table';

done_testing;
