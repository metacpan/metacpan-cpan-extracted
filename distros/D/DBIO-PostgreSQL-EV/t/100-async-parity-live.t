use strict;
use warnings;
use Test::More;

# LIVE: the one list of ResultSet cases of core (DBIO::Test::AsyncParity,
# core karr k344), driven twice on the same database -- the synchronous
# method, then its *_async twin on { async => 'ev' } -- and compared.
# A deviation the server or this transport forces would be declared in
# parity_deviations of a DBIO::Test::AsyncParity subclass; there is none.

use DBIO::Test;
use DBIO::PostgreSQL::EV::TestHarness;
use DBIO::Test::AsyncParity;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

alarm 600;

# The tables the case table uses, in the test database itself (the cases
# delete and reseed every table they use; no other file of this distribution
# has a table of these names). Written out here and not deployed from
# DBIO::Test::Schema: that schema is core's engine-neutral fixture and
# PostgreSQL refuses its DDL as it stands (the unique constraint 'artist'
# names the index like the table; 'datetime' is no PostgreSQL type). Columns,
# keys and unique constraints are those of the Result classes. Dropped at the
# end; nothing server-wide is touched.
my @TABLE = qw( artist cd track onekey artist_undirected_map cd_artwork
  artwork_to_artist twokeys tags liner_notes lyrics lyric_versions
  cd_to_producer images );

sub drop_tables {
  my $dbh = shift;
  $dbh->do("DROP TABLE IF EXISTS $_ CASCADE") for @TABLE;
}

my $CREATED;
{
  my $dbh = LiveServer->control_dbh(attrs => { PrintWarn => 0 });
  drop_tables($dbh);
  $CREATED = 1;
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

END {
  return unless $CREATED;
  my $dbh = eval { LiveServer->control_dbh(attrs => { PrintWarn => 0 }) } or return;
  drop_tables($dbh);
  $dbh->disconnect;
}

# DBIO::Test::Schema keeps no driver in its class; each use declares one
# (core ADR 0067). Here a clone of it declares the sync PostgreSQL driver: the
# harness connects it, and so does the case table's second, synchronous
# connection (parity_sync_schema).
my $parity_schema = DBIO::Test::Schema->clone;
$parity_schema->storage_type('+DBIO::PostgreSQL::Storage');

my $h = DBIO::PostgreSQL::EV::TestHarness->new(schema_class => $parity_schema);

# No deviation to declare: all 40 cases agree, 41 (populate) is absent in core.
DBIO::Test::AsyncParity->run(
  harness      => $h,
  schema_class => 'DBIO::Test::Schema',
);

$h->disconnect;
done_testing;
