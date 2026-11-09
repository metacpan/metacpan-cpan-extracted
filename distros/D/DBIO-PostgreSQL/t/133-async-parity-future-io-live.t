use strict;
use warnings;
use Test::More;

# LIVE: the future_io transport answers the core's shared case table of
# synchronous against asynchronous ResultSet operations
# (DBIO::Test::AsyncParity, core karr k344).
#
# CLAIM: every case of the table, driven once through the synchronous method
# and once through its *_async twin on the same schema and the same database,
# gives the same rows, counts, left-behind state and exception class -- or is
# a deviation declared below, with its reason, and fails the way it says.
#
# The tables of DBIO::Test::Schema (artist, cd, track, onekey) are installed
# into a database of this file's own: the cases delete and reseed every table
# they use, which is not for the database the other files share.

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

my ($dsn, $user, $pass) = LiveServer->login;

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    require DBIO::PostgreSQL::Storage::Async;
    1;
  } or plan skip_all =>
    'IO::Async, Future::IO::Impl::IOAsync and DBIO::Async required for the live future_io test';
}

use DBIO::Test;
use DBIO::Test::AsyncParity;
use FutureIoParityHarness;

LiveServer->require_server;

my @private = PrivatePgDatabase->create('t133');

# The four tables the case table uses, written out here and not deployed from
# DBIO::Test::Schema: that schema is core's engine-neutral fixture and this
# server refuses its DDL as it stands -- the unique constraint 'artist' on the
# table artist names the index like the table (relation "artist" already
# exists), and 'datetime' is no PostgreSQL type. Columns, keys and unique
# constraints are those of the Result classes; identity as the driver writes
# an auto_increment column.
{
  my $dbh = LiveServer->dbh_or_die(login => \@private);
  $dbh->do($_) for (
    q{CREATE TABLE artist (
        artistid bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
        name character varying(100),
        rank bigint NOT NULL DEFAULT 13,
        charfield character(10),
        PRIMARY KEY (artistid),
        CONSTRAINT artist_name UNIQUE (name),
        CONSTRAINT u_nullable UNIQUE (charfield, rank)
      )},
    q{CREATE TABLE cd (
        cdid bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
        artist bigint NOT NULL,
        title character varying(100) NOT NULL,
        year character varying(100) NOT NULL,
        genreid bigint,
        single_track bigint,
        PRIMARY KEY (cdid),
        CONSTRAINT cd_artist_title UNIQUE (artist, title)
      )},
    q{CREATE TABLE track (
        trackid bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
        cd bigint NOT NULL,
        "position" int NOT NULL,
        title character varying(100) NOT NULL,
        last_updated_on timestamp,
        last_updated_at timestamp,
        PRIMARY KEY (trackid),
        CONSTRAINT track_cd_position UNIQUE (cd, "position"),
        CONSTRAINT track_cd_title UNIQUE (cd, title)
      )},
    # a delete of an artist or a CD cascades along the relationships of
    # DBIO::Test::Schema into these, and a missing table fails the case
    q{CREATE TABLE artist_undirected_map (
        id1 bigint NOT NULL,
        id2 bigint NOT NULL,
        PRIMARY KEY (id1, id2)
      )},
    q{CREATE TABLE cd_artwork (
        cd_id bigint NOT NULL,
        PRIMARY KEY (cd_id)
      )},
    q{CREATE TABLE artwork_to_artist (
        artwork_cd_id bigint NOT NULL,
        artist_id bigint NOT NULL,
        PRIMARY KEY (artwork_cd_id, artist_id)
      )},
    q{CREATE TABLE twokeys (
        artist bigint NOT NULL,
        cd bigint NOT NULL,
        PRIMARY KEY (artist, cd)
      )},
    q{CREATE TABLE tags (
        tagid bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
        cd bigint NOT NULL,
        tag character varying(100) NOT NULL,
        PRIMARY KEY (tagid)
      )},
    q{CREATE TABLE liner_notes (
        liner_id bigint NOT NULL,
        notes character varying(100) NOT NULL,
        PRIMARY KEY (liner_id)
      )},
    q{CREATE TABLE lyrics (
        lyric_id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
        track_id bigint NOT NULL,
        PRIMARY KEY (lyric_id)
      )},
    q{CREATE TABLE lyric_versions (
        id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
        lyric_id bigint NOT NULL,
        text character varying(100) NOT NULL,
        PRIMARY KEY (id)
      )},
    q{CREATE TABLE cd_to_producer (
        cd bigint NOT NULL,
        producer bigint NOT NULL,
        attribute bigint,
        PRIMARY KEY (cd, producer)
      )},
    q{CREATE TABLE images (
        id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
        artwork_id bigint NOT NULL,
        name character varying(100) NOT NULL,
        data bytea,
        PRIMARY KEY (id)
      )},
    q{CREATE TABLE onekey (
        id bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
        artist bigint NOT NULL,
        cd bigint NOT NULL,
        PRIMARY KEY (id)
      )},
  );
  $dbh->disconnect;
}

# The harness reads its login from the environment; this file's database is
# the private one. Its schema is DBIO::Test::Schema on this driver
# (FutureIoParityHarness::Schema), the schema the case table is written for.
my $h = FutureIoParityHarness->new(
  dsn  => $private[0], user => $private[1], pass => $private[2],
);

{
  package ParityFutureIo;
  use base 'DBIO::Test::AsyncParity';

  # What this transport offers beyond what can be read off it (core's cases 47,
  # 50 and 56): a ROLLBACK the server does not confirm, a connection lost
  # mid-transaction, and a connection that cannot be made.
  sub parity_capabilities {
    my ($class, $harness) = @_;
    return ($class->SUPER::parity_capabilities($harness),
      qw( fault:rollback_fails fault:disconnect unreachable_connection ));
  }

  sub parity_fault {
    my ($class, $schema, $harness, $name, @args) = @_;

    if ($name eq 'rollback_fails') {
      # The ROLLBACK a transaction sends is answered with a failure; every
      # other statement goes through, until the guard is gone.
      my $async = $schema->storage->async;
      my $class_name = ref $async;
      my $original   = $class_name->can('_query_async_pinned');
      no strict 'refs';
      no warnings 'redefine';
      *{"${class_name}::_query_async_pinned"} = sub {
        my ($self, $conn, $sql, @rest) = @_;
        return $self->future_class->fail("ROLLBACK not confirmed (parity fault)\n")
          if $sql eq 'ROLLBACK';
        return $self->$original($conn, $sql, @rest);
      };
      return bless { class => $class_name, original => $original }, 'ParityFutureIo::Guard';
    }

    if ($name eq 'disconnect') {
      # The backend of the transaction's connection is ended by another session.
      my ($ctx) = @args;
      my $pid   = $ctx->txn_conn->{dbh}{pg_pid};
      my $admin = LiveServer->dbh_or_die(login => \@private);
      $admin->do('SELECT pg_terminate_backend(?, 5000)', undef, $pid);
      $admin->disconnect;
      return;
    }

    return $class->SUPER::parity_fault($schema, $harness, $name, @args);
  }

  # A schema whose connection is refused (nothing listens on the port), built
  # with the password the case looks for in the error.
  sub parity_unreachable {
    my ($class, $harness, $password) = @_;
    my $schema = FutureIoParityHarness::Schema->connect(
      'dbi:Pg:dbname=dbio_unreachable;host=127.0.0.1;port=1', 'parity_user', $password,
      { async => 'future_io' },
    );
    $harness->{unreachable_schema} = $schema;
    return $schema;
  }

  package ParityFutureIo::Guard;
  sub DESTROY {
    my ($self) = @_;
    no strict 'refs';
    no warnings 'redefine';
    *{"$self->{class}::_query_async_pinned"} = $self->{original};
  }

  package ParityFutureIo;

  sub parity_deviations {{
    # The transport's errors are plain strings, by documented design
    # (DBIO::PostgreSQL::Storage::Async, ERRORS: "An error of the database's
    # ... is a plain string"), where the synchronous storage throws
    # DBIO::Exception::Server with sqlstate and constraint.
    'err-unique' => {
      kind   => 'unsupported',
      reason => qr/exception classes differ: sync DBIO::Exception::Server, async DBIO::Exception\b/,
    },
  }}
}

ParityFutureIo->run(harness => $h, schema_class => 'DBIO::Test::Schema');

$h->disconnect;

done_testing;
