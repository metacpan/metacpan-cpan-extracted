use strict;
use warnings;

use Test::More;

use DBIO::MySQL::Storage;
use DBIO::MySQL::Storage::MariaDB;
use DBIO::MySQL::SQLMaker;

# karr #30 -- the two server-product facts that were still riding on the DBD
# driver name, and the confusion they produced.
#
# FULLY OFFLINE. Same fake-handle harness as t/26-server-version.t: the only
# thing a real server contributes is its version string and the status row, and
# both are handed in here. No DBI, no DSN, no server.
#
# THE POINT OF THIS FILE. Two axes were conflated in
# DBIO::MySQL::Storage::MariaDB:
#
#   * WHICH DBD is in use -- mariadb_insertid, mariadb_auto_reconnect, the async
#     primitives. Really DBD facts. This file used to say they stay in that
#     subclass. For the two sync attributes that was wrong (karr k59): a
#     DBD::MariaDB handle under load_components('MySQL') never reaches the
#     subclass either, so DBIO::MySQL::Storage now names them by the DBD on the
#     handle ($dbh->{Driver}{Name}). The async primitives stayed per class
#     until karr k60 found the same flaw there; they now follow the DBD of the
#     connection too (t/66-future-io-dbd-per-connection.t).
#   * WHICH ENGINE is at the other end -- the SQL dialect. NOT a DBD fact:
#     DBD::MariaDB connects to MySQL servers (that is how this dist's live suite
#     reaches MySQL) and DBD::mysql connects to MariaDB ones, and a MariaDB
#     server under load_components('MySQL') keeps DBIO::MySQL::Storage, because
#     the schema declares its driver, and so does not reach the subclass.
#
# So every case below is asserted for all four DBD/engine combinations, and the
# two that used to be wrong are named as such.

{
  package DialectTest::DBH;

  sub new {
    my ($class, %args) = @_;
    return bless { %args, queries => [] }, $class;
  }

  sub selectrow_array {
    my ($self, $sql) = @_;
    push @{ $self->{queries} }, $sql;
    return () unless defined $self->{version};
    return ($self->{version});
  }

  # The replica-status row, keyed by the statement asked for -- so a test can
  # assert both WHICH statement went out and what the driver made of the answer.
  sub selectrow_hashref {
    my ($self, $sql) = @_;
    push @{ $self->{queries} }, $sql;
    return $self->{status_rows} && $self->{status_rows}{$sql};
  }

  sub get_info { $_[0]->{get_info} }
}

{
  package DialectTest::MySQL;
  use base 'DBIO::MySQL::Storage';
  use mro 'c3';
  sub ensure_connected { 1 }
  sub _get_dbh { $_[0]->{__dbh} }

  package DialectTest::MariaDB;
  use base 'DBIO::MySQL::Storage::MariaDB';
  use mro 'c3';
  sub ensure_connected { 1 }
  sub _get_dbh { $_[0]->{__dbh} }
}

sub storage {
  my ($class, %server) = @_;
  my $storage = $class->new;
  $storage->{__dbh} = DialectTest::DBH->new(%server);
  return $storage;
}

# The statement a resultset would really get, from a dialect the storage
# decided: the maker only renders (DBIO::MySQL::SQLMaker/_lock_dialect).
sub render_lock {
  my ($storage, $spec) = @_;
  my $sm = DBIO::MySQL::SQLMaker->new(quote_char => '`', name_sep => '.');
  $sm->{_lock_dialect} = $storage->_lock_dialect;
  return $sm->_lock_select($spec);
}

my $MARIA = '11.8.8-MariaDB-ubu2404';
my $MYSQL8 = '8.0.46';

# --- 1. the lock clause, over all four DBD/engine combinations --------------

for my $case (
  # storage class          server version  share clause            label
  [ 'DialectTest::MySQL',   $MYSQL8, 'FOR SHARE',          1, 'MySQL 8 through DBD::mysql'   ],
  [ 'DialectTest::MariaDB', $MYSQL8, 'FOR SHARE',          1, 'MySQL 8 through DBD::MariaDB' ],
  [ 'DialectTest::MySQL',   $MARIA,  'LOCK IN SHARE MODE', 0, 'MariaDB through DBD::mysql'   ],
  [ 'DialectTest::MariaDB', $MARIA,  'LOCK IN SHARE MODE', 0, 'MariaDB through DBD::MariaDB' ],
) {
  my ($class, $version, $share, $has_of, $label) = @$case;

  my $s = storage($class, version => $version);

  is render_lock($s, 'share'), " $share",
    "for => 'share' renders $share ($label)";

  is render_lock($s, { type => 'update' }), ' FOR UPDATE',
    "... and FOR UPDATE is the same everywhere ($label)";

  if ($has_of) {
    is render_lock($s, { type => 'share', of => 'artist', modifier => 'nowait' }),
       " $share OF `artist` NOWAIT",
      "... OF and the modifier ride on it ($label)";
  }
  else {
    # MariaDB's SELECT grammar is
    #   [FOR UPDATE lock_option | LOCK IN SHARE MODE lock_option]
    #   lock_option: [WAIT n | NOWAIT | SKIP LOCKED]
    # -- no OF on either clause, in any version. Refused locally, naming the
    # boundary, rather than sent to the server to be rejected there.
    my $rendered = eval { render_lock($s, { type => 'share', of => 'artist' }) };
    like $@, qr/no OF clause on a locking read/,
      "... but OF is refused, because this server has none ($label)";
    is $rendered, undef, "... and nothing was rendered ($label)";

    is render_lock($s, { type => 'share', modifier => 'skip_locked' }),
       " $share SKIP LOCKED",
      "... while NOWAIT / SKIP LOCKED do attach to it here ($label)";
  }
}

# The two combinations above that used to be wrong, said out loud. Before
# karr #30 the clause came from DBIO::MySQL::Storage::MariaDB's sql_maker_class,
# i.e. from the DBD driver name.
{
  my $maria_via_mysql = storage('DialectTest::MySQL', version => $MARIA);
  is render_lock($maria_via_mysql, 'share'), ' LOCK IN SHARE MODE',
    'a MariaDB reached through dbi:mysql: no longer gets the FOR SHARE it rejects';

  my $mysql_via_mariadb = storage('DialectTest::MariaDB', version => $MYSQL8);
  is render_lock($mysql_via_mariadb, { type => 'update', of => 'artist', modifier => 'nowait' }),
     ' FOR UPDATE OF `artist` NOWAIT',
    'a MySQL 8 reached through DBD::MariaDB gets OF and NOWAIT, which only the '
  . 'FOR-form carries';
}

# --- 2. the MySQL 8.0.1 boundary -------------------------------------------
#
# FOR SHARE, OF tbl_name, NOWAIT and SKIP LOCKED all arrived in 8.0.1 together
# (MySQL 8.0 Reference Manual 17.7.2.4, "Locking Reads": FOR SHARE "is a
# replacement for SELECT ... LOCK IN SHARE MODE" and it, not the legacy
# spelling, is what "supports OF table_name, NOWAIT, and SKIP LOCKED options").

for my $case (
  [ '5.7.44',  'LOCK IN SHARE MODE', 0, 'MySQL 5.7 predates all of it' ],
  [ '8.0.0',   'LOCK IN SHARE MODE', 0, 'MySQL 8.0.0 still does' ],
  [ '8.0.1',   'FOR SHARE',          1, 'MySQL 8.0.1 is where all three arrive' ],
  [ '8.4.0',   'FOR SHARE',          1, 'MySQL 8.4' ],
) {
  my ($version, $share, $modern, $label) = @$case;

  my $s = storage('DialectTest::MySQL', version => $version);
  my $d = $s->_lock_dialect;

  is $d->{share},       $share,  "$label: share renders $share";
  is $d->{of},          $modern, "$label: OF availability";
  # One release for both modifiers -- so on MySQL, and only on MySQL, the two
  # keys are always equal. That is the fact that made a single flag look
  # sufficient (karr #38).
  is $d->{nowait},      $modern, "$label: NOWAIT availability";
  is $d->{skip_locked}, $modern, "$label: SKIP LOCKED availability";
}

{
  # THAT a modifier is refused here is karr #30's doing and was already pinned;
  # what karr #38 adds is that the refusal names the modifier that was asked
  # for, since the two are no longer one question. So the two "nothing was
  # rendered" assertions and the 8.0.1 one below are no-regression pins, and
  # only the two message assertions are new claims.
  my $s = storage('DialectTest::MySQL', version => '5.7.44');
  my $rendered = eval { render_lock($s, { type => 'update', modifier => 'nowait' }) };
  my $err = $@;
  like $err, qr/no NOWAIT on a locking read/,
    'a modifier is refused on a MySQL that predates 8.0.1, by name';
  is $rendered, undef, '... and nothing was rendered (no-regression pin)';

  $rendered = eval { render_lock($s, { type => 'update', modifier => 'skip_locked' }) };
  $err = $@;
  like $err, qr/no SKIP LOCKED on a locking read/,
    '... and so is the other one, which arrived in the same release';
  like $err, qr/8\.0\.1/,
    '... with the message naming that release (no-regression pin)';
  is $rendered, undef, '... and nothing was rendered (no-regression pin)';
}

# --- 2b. the MariaDB boundaries, which are two, not one (karr #38) ----------
#
# MySQL introduced NOWAIT and SKIP LOCKED in one release, so a single
# availability flag described it exactly. MariaDB did not, so that flag
# described every MariaDB as having both, and a MariaDB below the line was
# handed a clause its parser rejects -- the same failure class karr #30 removed
# for the share keyword and for OF, one product older.
#
#   * NOWAIT: MariaDB 10.3. MDEV-11379, "AliSQL: [Feature] Issue#8: SELECT FOR
#     UPDATE WAIT", fix version 10.3.0, resolution Fixed.
#   * SKIP LOCKED: MariaDB 10.6. MDEV-13115, "Implement SELECT [FOR UPDATE|LOCK
#     IN SHARED MODE] SKIP LOCKED", fix version 10.6.0, resolution Fixed.

for my $case (
  [ '10.2.44-MariaDB', 0, 0, 'MariaDB 10.2 has neither modifier' ],
  [ '10.3.0-MariaDB',  1, 0, 'MariaDB 10.3.0, where NOWAIT arrives' ],
  [ '10.5.28-MariaDB', 1, 0, 'MariaDB 10.5, with NOWAIT and no SKIP LOCKED' ],
  [ '10.6.0-MariaDB',  1, 1, 'MariaDB 10.6.0, where SKIP LOCKED arrives' ],
  [ $MARIA,            1, 1, 'MariaDB 11.8, which has both' ],
) {
  my ($version, $nowait, $skip_locked, $label) = @$case;

  # Both storage classes again: which modifiers exist is a server fact, and the
  # DBD binding the connection came in through cannot answer it.
  for my $class ('DialectTest::MySQL', 'DialectTest::MariaDB') {
    my $d = storage($class, version => $version)->_lock_dialect;

    is $d->{nowait},      $nowait,      "$label: NOWAIT availability";
    is $d->{skip_locked}, $skip_locked, "$label: SKIP LOCKED availability";

    # And neither boundary moves the other two keys: MariaDB has FOR SHARE in
    # no version, and OF in none either, at both ends of this table. Both were
    # already true before karr #38 -- they are here as no-regression pins, so
    # that splitting the modifier flag cannot quietly re-open the two parts
    # karr #30 closed.
    is $d->{share}, 'LOCK IN SHARE MODE',
      "$label: share is untouched by them (no-regression pin)";
    is $d->{of}, 0,
      "$label: and OF is still absent (no-regression pin)";
  }
}

# The middle ground the old single flag could not express, rendered.
{
  my $mid = storage('DialectTest::MariaDB', version => '10.4.34-MariaDB');

  # Green before karr #38 as well -- the old flag allowed every modifier on
  # every MariaDB -- so this one is a no-regression pin, and its job is to keep
  # the new gate from over-refusing the half that really is there.
  is render_lock($mid, { type => 'update', modifier => 'nowait' }),
     ' FOR UPDATE NOWAIT',
    'a MariaDB 10.4 gets NOWAIT, which it has had since 10.3 (no-regression pin)';

  my $rendered = eval { render_lock($mid, { type => 'share', modifier => 'skip_locked' }) };
  my $err = $@;
  like $err, qr/no SKIP LOCKED on a locking read/,
    '... and is refused SKIP LOCKED, which it does not get before 10.6';
  is $rendered, undef, '... with nothing rendered';
  like $err, qr/MDEV-13115/,
    '... the refusal naming the MariaDB boundary, not only MySQL 8.0.1';
  like $err, qr/\Q10.4.34\E/,
    '... and the version string of the server that was actually asked';
}

# ... and the version below both of them.
{
  my $old = storage('DialectTest::MySQL', version => '10.2.44-MariaDB');

  my $rendered = eval { render_lock($old, { type => 'update', modifier => 'nowait' }) };
  my $err = $@;
  like $err, qr/no NOWAIT on a locking read/,
    'a MariaDB 10.2 is refused NOWAIT as well';
  like $err, qr/MDEV-11379/, '... naming the release that introduced it';
  is $rendered, undef, '... and nothing was rendered';
}

# NO-REGRESSION PIN -- green before karr #38 too, and it has to stay that way:
# every non-EOL MariaDB is past both boundaries (10.6 LTS is the oldest
# supported), so the split must cost the supported installed base nothing.
{
  my $s = storage('DialectTest::MariaDB', version => $MARIA);

  is render_lock($s, { type => 'update', modifier => 'skip_locked' }),
     ' FOR UPDATE SKIP LOCKED',
    'a current MariaDB still gets SKIP LOCKED (no-regression pin)';
  is render_lock($s, { type => 'share', modifier => 'nowait' }),
     ' LOCK IN SHARE MODE NOWAIT',
    '... and NOWAIT on the legacy share spelling (no-regression pin)';
}

# A modifier name is now resolved before the server is asked about it, so a
# typo reads as a typo even on a server where the real name would have been
# refused anyway -- previously it was reported as an unavailable feature.
{
  my $s = storage('DialectTest::MySQL', version => '5.7.44');

  eval { render_lock($s, { type => 'update', modifier => 'nowaite' }) };
  like $@, qr/Unknown lock modifier 'nowaite'/,
    'an unknown modifier is reported as unknown, not as unavailable';
}

# A maker nobody handed a dialect to assumes a current MySQL -- the polarity
# this driver already uses for the set operations, and byte-for-byte what this
# maker emitted before karr #30.
{
  my $sm = DBIO::MySQL::SQLMaker->new(quote_char => '`', name_sep => '.');
  is $sm->_lock_select('share'), ' FOR SHARE',
    'a standalone maker, with no server to ask, assumes a current MySQL';
  is $sm->_lock_select({ type => 'share', of => 'artist', modifier => 'nowait' }),
     ' FOR SHARE OF `artist` NOWAIT',
    '... including OF and the modifiers';
}

# --- 3. the replica-status statement ---------------------------------------
#
# MySQL renamed it in 8.0.22 and REMOVED the old name in 8.4; MariaDB added the
# new name in 10.5.1 and kept both. Two products, two boundaries, one server
# fact -- so the class the connection landed in cannot answer it.

for my $case (
  [ '5.7.44',                  'SHOW SLAVE STATUS',   'MySQL 5.7' ],
  [ '8.0.21',                  'SHOW SLAVE STATUS',   'MySQL 8.0.21, before the rename' ],
  [ '8.0.22',                  'SHOW REPLICA STATUS', 'MySQL 8.0.22, where it was renamed' ],
  [ '8.4.0',                   'SHOW REPLICA STATUS', 'MySQL 8.4, which REMOVED the old name' ],
  [ '10.4.34-MariaDB',         'SHOW SLAVE STATUS',   'MariaDB 10.4' ],
  [ '10.5.0-MariaDB',          'SHOW SLAVE STATUS',   'MariaDB 10.5.0, one release early' ],
  [ '10.5.1-MariaDB',          'SHOW REPLICA STATUS', 'MariaDB 10.5.1, where the alias arrived' ],
  [ $MARIA,                    'SHOW REPLICA STATUS', 'MariaDB 11.8' ],
) {
  my ($version, $statement, $label) = @$case;

  # Both storage classes, because the answer must not depend on which one the
  # connection landed in -- that is the whole ticket.
  for my $class ('DialectTest::MySQL', 'DialectTest::MariaDB') {
    my $s = storage($class, version => $version);
    is $s->_replication_status_statement, $statement,
      "$label asks $statement (" . ($class =~ /MariaDB/ ? 'DBD::MariaDB' : 'DBD::mysql') . ')';
  }
}

# --- 4. and the columns that come back with it ------------------------------
#
# MySQL renamed the OUTPUT with the statement -- "only the terminology used for
# the statement and its output has changed" (Reference Manual 15.7.7.36) -- so
# SHOW REPLICA STATUS answers Replica_IO_Running / Seconds_Behind_Source there.
# MariaDB's alias keeps the Slave_ / Seconds_Behind_Master names. Picking the
# statement is therefore only half the job: this is the half that used to turn a
# successful statement into a silently wrong answer.

{
  # MySQL 8.0.22+: the renamed statement AND the renamed columns.
  my $s = storage('DialectTest::MariaDB',
    version     => '8.0.36',
    status_rows => {
      'SHOW REPLICA STATUS' => {
        Replica_IO_Running    => 'Yes',
        Replica_SQL_Running   => 'Yes',
        Seconds_Behind_Source => 42,
      },
    },
  );

  ok $s->is_replicating,
    'a MySQL 8.0.22+ replica through DBD::MariaDB reports as replicating';
  is $s->lag_behind_master, 42, '... and its lag is read off Seconds_Behind_Source';
  is_deeply $s->{__dbh}{queries},
    [ 'SELECT VERSION()', 'SHOW REPLICA STATUS', 'SHOW REPLICA STATUS' ],
    '... having asked the modern statement, and only that one';
}

{
  # The same server, not replicating: both threads have to be running.
  my $s = storage('DialectTest::MariaDB',
    version     => '8.0.36',
    status_rows => {
      'SHOW REPLICA STATUS' => {
        Replica_IO_Running    => 'No',
        Replica_SQL_Running   => 'Yes',
        Seconds_Behind_Source => undef,
      },
    },
  );

  ok !$s->is_replicating, 'a stopped IO thread means not replicating';
}

{
  # MariaDB: modern statement, legacy column names.
  my $s = storage('DialectTest::MySQL',
    version     => $MARIA,
    status_rows => {
      'SHOW REPLICA STATUS' => {
        Slave_IO_Running      => 'Yes',
        Slave_SQL_Running     => 'Yes',
        Seconds_Behind_Master => 7,
      },
    },
  );

  ok $s->is_replicating,
    'a MariaDB replica reached through dbi:mysql: reports as replicating';
  is $s->lag_behind_master, 7,
    '... with its lag under the name MariaDB kept, Seconds_Behind_Master';
}

{
  # A pre-8.0.22 MySQL: legacy statement, legacy columns.
  my $s = storage('DialectTest::MySQL',
    version     => '5.7.44',
    status_rows => {
      'SHOW SLAVE STATUS' => {
        Slave_IO_Running      => 'Yes',
        Slave_SQL_Running     => 'Yes',
        Seconds_Behind_Master => 0,
      },
    },
  );

  ok $s->is_replicating, 'a MySQL 5.7 replica still answers the legacy statement';
  is $s->lag_behind_master, 0, '... with a lag of 0, which is not "no answer"';
}

{
  # Not a replica at all: the statement returns no row.
  my $s = storage('DialectTest::MySQL', version => $MYSQL8, status_rows => {});

  is $s->is_replicating, undef, 'a server that is not a replica answers undef';
  is $s->lag_behind_master, undef, '... and has no lag to report';
}

{
  # A row we cannot read is "this driver does not know", not "not replicating":
  # DBIO::Replicated::Pool distinguishes undef from 0, and would otherwise mark
  # a replicant inactive on the strength of a column name.
  my $s = storage('DialectTest::MySQL',
    version     => $MYSQL8,
    status_rows => { 'SHOW SLAVE STATUS' => { Something_Else => 'Yes' } },
  );

  is $s->is_replicating, undef,
    'a status row with neither column spelling answers undef, not false';
}

# --- 5. what stays in the DBD subclass, and what left it --------------------

is( DBIO::MySQL::Storage::MariaDB->sql_maker_class, 'DBIO::MySQL::SQLMaker',
  'the DBD::MariaDB subclass no longer picks its own SQLMaker (karr #30)' );

is( DBIO::MySQL::Storage::MariaDB->can('_replication_status_row'),
    DBIO::MySQL::Storage->can('_replication_status_row'),
  '... and no longer overrides the replica-status statement' );

is( DBIO::MySQL::Storage::MariaDB->can('lag_behind_master'),
    DBIO::MySQL::Storage->can('lag_behind_master'),
  '... nor duplicates lag_behind_master' );

is( DBIO::MySQL::Storage::MariaDB->can('_lock_dialect'),
    DBIO::MySQL::Storage->can('_lock_dialect'),
  '... and takes the shared, server-keyed lock dialect' );

# The two sync DBD facts left this subclass too (karr k59). They are DBD facts,
# not engine facts, but the storage class does not tell you the DBD any more
# than it tells you the engine: load_components('MySQL') pins
# DBIO::MySQL::Storage over a dbi:MariaDB: DSN, and a mariadb_insertid bound
# here never ran there. The parent reads both off the handle's DBD
# (t/64-dbd-attributes.t).
is( DBIO::MySQL::Storage::MariaDB->can('_dbh_last_insert_id'),
    DBIO::MySQL::Storage->can('_dbh_last_insert_id'),
  'the insertid attribute is chosen by the DBD on the handle, not by this subclass' );

is( DBIO::MySQL::Storage::MariaDB->can('_run_connection_actions'),
    DBIO::MySQL::Storage->can('_run_connection_actions'),
  '... and so is the auto-reconnect reset, which no longer bypasses the parent' );

# The old SQLMaker subclass survives as an empty alias, so a configuration that
# still names it gets the server-keyed behaviour rather than the fixed one.
{
  require DBIO::MySQL::SQLMaker::MariaDB;
  ok( DBIO::MySQL::SQLMaker::MariaDB->isa('DBIO::MySQL::SQLMaker'),
    'DBIO::MySQL::SQLMaker::MariaDB is still loadable' );
  is( DBIO::MySQL::SQLMaker::MariaDB->can('_lock_select'),
      DBIO::MySQL::SQLMaker->can('_lock_select'),
    '... and overrides nothing -- naming it no longer pins a dialect' );
}

done_testing;
