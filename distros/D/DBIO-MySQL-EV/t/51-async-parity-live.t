use strict;
use warnings;
use Test::More;

# LIVE: the one list of ResultSet cases of core (DBIO::Test::AsyncParity,
# karr k94), driven twice on the same database -- the synchronous method, then
# its *_async twin on { async => 'ev' } -- and compared. Any deviation the
# server or this transport forces is declared in parity_deviations of a
# DBIO::Test::AsyncParity subclass; this file declares none.
#
# The cases delete and reseed the tables of DBIO::Test::Schema, so they run in
# a database of their own, mysql_ev_parity, created here and dropped at the
# end; the database of the DSN is only used to reach the server. Nothing
# server-wide is touched.

use DBI;
use DBIO::Test;
use DBIO::MySQL::EV::TestHarness;
use DBIO::Test::AsyncParity;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

alarm 600;

my $DB   = 'mysql_ev_parity';
my $dsn  = $ENV{DBIO_TEST_MYSQL_DSN};
my $user = $ENV{DBIO_TEST_MYSQL_USER};
my $pass = $ENV{DBIO_TEST_MYSQL_PASS};

(my $own_dsn = $dsn) =~ s/(?<=[:;])(?:database|dbname|db)=[^;]*/database=$DB/
  or plan skip_all => 'DBIO_TEST_MYSQL_DSN names no database';

my $CREATED;
my $control = sub {
  return DBI->connect($dsn, $user, $pass, { RaiseError => 1, PrintError => 0, PrintWarn => 0 });
};

{
  my $dbh = $control->();
  $dbh->do("DROP DATABASE IF EXISTS $DB");
  $dbh->do("CREATE DATABASE $DB");
  $CREATED = 1;
  $dbh->disconnect;
}

END {
  return unless $CREATED;
  my $dbh = eval { $control->() } or return;
  eval { $dbh->do("DROP DATABASE IF EXISTS $DB") };
  $dbh->disconnect;
}

# DBIO::Test::Schema keeps no driver in its class; each use declares one
# (core ADR 0067). A clone declares the sync MySQL driver: the harness
# connects it, and so does the case table's second, synchronous connection.
my $parity_schema = DBIO::Test::Schema->clone;
$parity_schema->storage_type('+DBIO::MySQL::Storage');

# The tables the case table uses, written out here and not deployed from
# DBIO::Test::Schema: that schema is core's engine-neutral fixture and MySQL
# refuses its DDL as it stands (artist_guid has a 'uniqueidentifier' column).
# Columns, keys and unique constraints are those of the Result classes; the
# database holding them is dropped at the end.
{
  my $dbh = DBI->connect($own_dsn, $user, $pass, { RaiseError => 1, PrintError => 0, PrintWarn => 0 });
  $dbh->do($_) for (
    q{CREATE TABLE artist (
        artistid bigint NOT NULL AUTO_INCREMENT,
        name varchar(100),
        `rank` bigint NOT NULL DEFAULT 13,
        charfield char(10),
        PRIMARY KEY (artistid),
        CONSTRAINT artist_name UNIQUE (name),
        CONSTRAINT u_nullable UNIQUE (charfield, `rank`)
      )},
    q{CREATE TABLE cd (
        cdid bigint NOT NULL AUTO_INCREMENT,
        artist bigint NOT NULL,
        title varchar(100) NOT NULL,
        year varchar(100) NOT NULL,
        genreid bigint,
        single_track bigint,
        PRIMARY KEY (cdid),
        CONSTRAINT cd_artist_title UNIQUE (artist, title)
      )},
    q{CREATE TABLE track (
        trackid bigint NOT NULL AUTO_INCREMENT,
        cd bigint NOT NULL,
        `position` int NOT NULL,
        title varchar(100) NOT NULL,
        last_updated_on datetime,
        last_updated_at datetime,
        PRIMARY KEY (trackid),
        CONSTRAINT track_cd_position UNIQUE (cd, `position`),
        CONSTRAINT track_cd_title UNIQUE (cd, title)
      )},
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
        tagid bigint NOT NULL AUTO_INCREMENT,
        cd bigint NOT NULL,
        tag varchar(100) NOT NULL,
        PRIMARY KEY (tagid)
      )},
    q{CREATE TABLE liner_notes (
        liner_id bigint NOT NULL,
        notes varchar(100) NOT NULL,
        PRIMARY KEY (liner_id)
      )},
    q{CREATE TABLE lyrics (
        lyric_id bigint NOT NULL AUTO_INCREMENT,
        track_id bigint NOT NULL,
        PRIMARY KEY (lyric_id)
      )},
    q{CREATE TABLE lyric_versions (
        id bigint NOT NULL AUTO_INCREMENT,
        lyric_id bigint NOT NULL,
        text varchar(100) NOT NULL,
        PRIMARY KEY (id)
      )},
    q{CREATE TABLE cd_to_producer (
        cd bigint NOT NULL,
        producer bigint NOT NULL,
        attribute bigint,
        PRIMARY KEY (cd, producer)
      )},
    q{CREATE TABLE images (
        id bigint NOT NULL AUTO_INCREMENT,
        artwork_id bigint NOT NULL,
        name varchar(100) NOT NULL,
        data blob,
        PRIMARY KEY (id)
      )},
    q{CREATE TABLE onekey (
        id bigint NOT NULL AUTO_INCREMENT,
        artist bigint NOT NULL,
        cd bigint NOT NULL,
        PRIMARY KEY (id)
      )},
  );
  $dbh->disconnect;
}

my $h = DBIO::MySQL::EV::TestHarness->new(
  schema_class => $parity_schema,
  dsn          => $own_dsn,
);

# One case fails on BOTH ways, the synchronous one too: the case table of core
# does not fit this engine, the transport is not what deviates. Declared, not
# skipped -- it is still driven, has to fail the way stated here, and turns
# red when it passes (the declaration is stale). It belongs to the core case
# table / dbio-mysql, see karr k94.
{
  package MySQLEV::Test::RefusingExecutor;
  use base 'DBIO::MySQL::EV::QueryExecutor';

  # The ROLLBACK of a pinned connection is queued behind the statements in
  # flight (execute_when_idle); this one is not confirmed.
  sub execute_when_idle {
    my ($self, $mdb, $sql, @rest) = @_;
    return $self->{future_class}->fail('parity: the ROLLBACK is not confirmed')
      if $sql =~ /\A\s*ROLLBACK\b/i;
    return $self->SUPER::execute_when_idle($mdb, $sql, @rest);
  }

  package MySQLEV::Test::Fault;
  sub DESTROY { $_[0]{backend}{executor} = $_[0]{original} }

  package MySQLEV::Test::Broker;
  use base q{DBIO::AccessBroker};

  sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new;
    $self->{secret} = $args{secret};
    return $self;
  }

  sub connect_info_for { die "unused\n" }

  sub connect_info_for_storage {
    my ($self, $storage) = @_;
    return { host => q{127.0.0.1}, port => 1, dbname => q{nowhere}, user => q{nobody}, password => $self->{secret} }
      if $storage->isa(q{DBIO::MySQL::EV::Storage});
    return [ @ENV{qw( DBIO_TEST_MYSQL_DSN DBIO_TEST_MYSQL_USER DBIO_TEST_MYSQL_PASS )} ];
  }
}

{
  package MySQLEV::Test::AsyncParity;
  use base 'DBIO::Test::AsyncParity';

  # The cases 47 to 56 of the table need what only a transport knows how to do
  # (DBIO::Test::AsyncParity, "Capabilities"). This transport can do all
  # three: it fails a ROLLBACK, loses the connection of a transaction, and
  # connects to a port nobody listens on. The session of case 54 is left in
  # the default way, a temporary table, which MySQL and MariaDB both have.
  sub parity_capabilities {
    my ($class, $harness) = @_;
    return ($class->SUPER::parity_capabilities($harness),
      'fault:rollback_fails', 'fault:disconnect', 'unreachable_connection');
  }

  # rollback_fails: the executor answers the ROLLBACK of a transaction with a
  # failure, as a server that does not confirm it does. The transport's own
  # path (_mysql_rollback -> _mysql_end_transaction) is what is under test.
  # disconnect: the handle of the transaction's connection is finished, the
  # next statement on it is refused.
  sub parity_fault {
    my ($class, $schema, $harness, $name, @args) = @_;

    if ($name eq 'disconnect') {
      my ($ctx) = @args;
      $ctx->txn_conn->finish;
      return;
    }
    return $class->SUPER::parity_fault($schema, $harness, $name, @args)
      unless $name eq 'rollback_fails';

    my $backend  = $schema->storage->_async_storage;
    my $original = $backend->{executor};
    $backend->{executor} = MySQLEV::Test::RefusingExecutor->new(
      future_class => $backend->future_class,
    );
    return bless { backend => $backend, original => $original }, 'MySQLEV::Test::Fault';
  }

  # A connection the pool cannot make: a port on this machine nobody listens on.
  # The owning sync storage needs a server of its own to build the SQL (its
  # version), so it is told the real DSN and only the pool is told the dead
  # port -- an AccessBroker answers each storage its own.
  sub parity_unreachable {
    my ($class, $harness, $password) = @_;
    my $schema = DBIO::Test::Schema->clone;
    $schema->storage_type(q{+DBIO::MySQL::Storage});
    $harness->{unreachable_schema} = $schema->connect(
      MySQLEV::Test::Broker->new(secret => $password), { async => q{ev}, pool_size => 1 },
    );
    return $harness->{unreachable_schema};
  }

  sub parity_deviations {
    return {
      'upsert' => {
        # Case 34 upserts Artist with key => 'artist_name'; Artist has two more
        # unique keys, and DBIO::MySQL::Storage refuses a conflict target that
        # ON DUPLICATE KEY UPDATE cannot honour (it would be conflict_target
        # => 'any', which the case does not say).
        kind   => 'unsupported',
        reason => qr/cannot honour the requested conflict target/,
      },
    };
  }
}

# Case 55 (listen-notify) needs the notify table; it is created in the database
# of this file, which is dropped at the end.
$h->await($h->async->deploy_notify_table);

MySQLEV::Test::AsyncParity->run(
  harness      => $h,
  schema_class => 'DBIO::Test::Schema',
);

$h->disconnect;
done_testing;
