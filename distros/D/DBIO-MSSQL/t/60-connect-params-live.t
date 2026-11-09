use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();
use Digest::SHA ();
use Encode ();
use DateTime;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::AccessBroker::Static;

# LIVE (karr k37; core k242, ADR 0057; core k301, ADR 0059). The counterpart
# of t/59-connect-params-dsn.t, which pins offline what DSN the seam
# _connect_params_dsn builds from { dbname, host, port } and says of itself:
# "Whether a server ACCEPTS these DSNs is not provable offline and is not
# claimed here." This file is where it is claimed, against a real SQL Server
# over DBD::Sybase.
#
# Two ways to the same database run side by side throughout:
#
#   pinned   a schema that loaded the MSSQL component, connected with
#            connection parameters (DBIO::AccessBroker::Static, or a
#            connect-info hash without a dsn). This is the way karr k37 is
#            about. The component pins the storage to DBIO::MSSQL::Storage --
#            that is how the schema declares its driver -- and at the first
#            use that class adapts itself to the access path
#            (_adapt_to_access_path): over DBD::Sybase it becomes
#            DBIO::MSSQL::Storage::Sybase.
#   dsn      a schema that loaded the MSSQL component as well, connected
#            with the DSN written by hand; it adapts the same way and ends as
#            DBIO::MSSQL::Storage::Sybase too.
#            A schema without a declared driver is refused at connect, and
#            DBIO->driver_for names the Sybase ASE driver for a
#            dbi:Sybase: DSN, not this one (t/62-adapt-access-path.t).
#
# Same server, same DBD, same DSN -- and the same storage class. That was not
# so until the maintainer's decision of 2026-10-06 (core k301, ADR 0059) and
# the hook that followed it here: the pinned storage stayed the
# transport-neutral base on every DSN. This file measured what that meant on
# 2026-10-05 -- what the pinned way WAS as plain tests, what it should be as
# TODO tests. With the hook the TODO tests hold and are plain tests; the
# claims about what the pinned way was are replaced, each by what was measured
# in its place on 2026-10-07, and the comments say what stood there. Four
# parts:
#
#   A. The k37 live criterion. The DSNs the seam builds are accepted, reach
#      the database named, and carry the everyday operations.
#   B. The pinned way is the DBD::Sybase class, and has what that class
#      brings: the server version, DateTime inflation, the NoBindVars class
#      when the connection takes no placeholders, statement caching turned
#      off -- and SET TEXTSIZE, which cuts a long value on the way back where
#      the base class did not.
#   C. The key of a new row with a trigger on the table (karr k39): the
#      DBD::Sybase class read @@identity over FreeTDS, which a trigger
#      overwrites, so create() returned another table's identity as the new
#      row's key. It reads SCOPE_IDENTITY() now, as the base class did, and
#      the test is a plain one on both ways.
#   D. A bind value of more than 4000 bytes arrives whole (karr k40). Bound,
#      it did not: the client library declares every placeholder as
#      varchar(4000) and the server cuts what is longer, without an error --
#      measured here on 2026-10-05 and held as a TODO test of both ways. The
#      DBD::Sybase class now sends such a value in the statement, as a
#      literal, and the TODO tests are plain tests. What it sends is pinned
#      offline, in t/63-long-bind-values.t; what the server then holds, here.
#
# What this file does NOT claim:
#
#   * anything about DBD::ODBC. No connection here goes through it, and the
#     ODBC transport class refuses connection parameters by design (t/59).
#     That a pinned storage adapts to DBIO::MSSQL::Storage::ODBC on a
#     dbi:ODBC: DSN is pinned offline only, in t/62-adapt-access-path.t.
#   * that any of it is the same on another client library. Everything was
#     measured with DBD::Sybase 1.27 built against FreeTDS 1.3.17, SQL Server
#     2022 (16.0.4295.3). The FreeTDS workarounds of the DBD::Sybase class
#     (@@identity, no statement caching) are tied to FreeTDS above 0.82;
#     several assertions below are those workarounds.
#   * that a connection which takes no placeholders was seen (B). This server
#     takes them on every TDS version tried (7.4, 7.0, 4.2); the NoBindVars
#     class is reached here by telling the storage so.
#   * anything about a storage of the base class DBIO::MSSQL::Storage on a
#     DBD::Sybase handle. A schema that declares the driver no longer has one,
#     and a private subclass of the base pinned by hand is refused over
#     DBD::Sybase (karr k42, t/62). What was measured of the base there on
#     2026-10-05 (no server version, no DateTime inflation, a "no
#     placeholders" request ignored, the text size left alone, the key of a
#     new row read with SCOPE_IDENTITY(); a long value cut -- 5000 characters
#     stored as 4000, 2026-10-07) is why.
#   * anything about binary columns, or about a value beyond ASCII that is
#     short enough to be bound. Both were looked at with karr k40 and are
#     defects of their own, in CLAUDE.md.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_MSSQL_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_sybase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_sybase');

# Only "not installed" is a reason to skip. A DBIO::Sybase that is there and
# does not load is a failure, and so is this distribution's own class on top
# of it -- neither may hide behind a skip.
unless (eval { require DBIO::Sybase::Storage; 1 }) {
  die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };

  plan skip_all => 'Test needs DBIO::Sybase (optional, cpanfile recommends): '
    . 'over DBD::Sybase both ways end in a storage class built on it';
}

require DBIO::MSSQL::Storage::Sybase;

# The parameters come out of the DSN, so that both ways provably go to the
# same place. Only the form the seam builds will do -- anything else in the
# DSN is something connection parameters cannot say, and the pinned way would
# silently be a different connection than the one with the DSN written by
# hand.
my %dsn_part = $dsn =~ /\Adbi:Sybase:(.*)\z/s
  ? ( map { /\A([^=]+)=(.*)\z/s ? ($1 => $2) : ($_ => '') } split /;/, $1 )
  : ();
my ($host, $port, $dbname) = @dsn_part{qw(host port database)};

plan skip_all => 'This test checks the DSN form built from connection '
  . 'parameters; $ENV{DBIO_TEST_MSSQL_DSN} must be exactly '
  . 'dbi:Sybase:host=<host>;port=<port>;database=<database> (nothing else, '
  . 'no server=<name>)'
  unless keys %dsn_part == 3
    and 3 == grep { defined && length } $host, $port, $dbname;

my $BUILT = "dbi:Sybase:host=$host;port=$port;database=$dbname";

# The DBD::Sybase class announces its FreeTDS workaround once per process,
# and says there is no way to turn that off. Anything else is not expected --
# a "Driver mismatch" for the pinned way above all: that is what core said of
# every pinned storage at its first use until it adapted to the access path.
my $EXPECTED_WARNING = qr/compiled against buggy FreeTDS version/;
my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0];
  warn $_[0] unless $_[0] =~ $EXPECTED_WARNING;
};

{
  package T::K37::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k37_live_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  # k37_live_trig has an AFTER INSERT trigger writing to k37_live_audit.
  package T::K37::Result::Trig;
  use base 'DBIO::Core';
  __PACKAGE__->table('k37_live_trig');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K37::Result::Money;
  use base 'DBIO::Core';
  __PACKAGE__->table('k37_live_money');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    amount => { data_type => 'money', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K37::Result::DT;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('InflateColumn::DateTime');
  __PACKAGE__->table('k37_live_dt');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    dt       => { data_type => 'datetime', is_nullable => 1 },
    small_dt => { data_type => 'smalldatetime', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K37::Result::Long;
  use base 'DBIO::Core';
  __PACKAGE__->table('k37_live_long');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    body  => { data_type => 'varchar', is_nullable => 1 },
    nbody => { data_type => 'nvarchar', is_nullable => 1 },
    note  => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K37::Pinned;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
}

{
  # The same declaration, for the DSN written by hand: a schema always
  # declares its driver (core ADR 0067).
  package T::K37::ByDSN;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
}

for my $schema_class (qw(T::K37::Pinned T::K37::ByDSN)) {
  $schema_class->register_class($_ => "T::K37::Result::$_")
    for qw(Item Trig Money DT Long);
}

sub broker {
  return DBIO::AccessBroker::Static->new(
    username => $user,
    password => $pass,
    @_,
  );
}

# Options (on_connect_call, ...) go beside the broker, not into it.
my %CONNECT = (
  pinned => sub {
    T::K37::Pinned->connect(
      broker(host => $host, port => $port, dbname => $dbname), @_,
    );
  },
  dsn    => sub { T::K37::ByDSN->connect($dsn, $user, $pass, @_) },
);

# A third connection, plain DBI, for setup and for looking at what the
# server really holds: from another session, and through neither storage
# under test. The lock timeout turns a write the other session did not
# commit into an error here instead of a hang.
my $admin;
sub admin {
  return $admin ||= do {
    my $dbh = DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('SET LOCK_TIMEOUT 10000');
    $dbh;
  };
}

sub server_value { ( admin()->selectrow_array(@_) )[0] }
sub server_rows  { admin()->selectall_arrayref(@_) }

my @TABLES = map { "k37_live_$_" } qw(item trig audit money dt long);

sub drop_tables {
  my $dbh = admin();
  $dbh->do(
    "IF OBJECT_ID('k37_live_trig_ai', 'TR') IS NOT NULL "
  . 'DROP TRIGGER k37_live_trig_ai'
  );
  $dbh->do("IF OBJECT_ID('$_', 'U') IS NOT NULL DROP TABLE $_") for @TABLES;
}

# Every section starts from empty tables with identities at their seed, so
# the ids asserted below are the same on both ways.
sub fresh_tables {
  my $dbh = admin();
  drop_tables();
  $dbh->do($_) for (
    'CREATE TABLE k37_live_item ('
  . ' id INT IDENTITY PRIMARY KEY, name VARCHAR(100) NULL)',
    'CREATE TABLE k37_live_trig ('
  . ' id INT IDENTITY PRIMARY KEY, name VARCHAR(100) NULL)',
    # a second identity, far from the first, so the two cannot be confused
    'CREATE TABLE k37_live_audit ('
  . ' id INT IDENTITY(1000,1) PRIMARY KEY, trig_id INT)',
    'CREATE TRIGGER k37_live_trig_ai ON k37_live_trig AFTER INSERT AS'
  . ' INSERT INTO k37_live_audit (trig_id) SELECT id FROM inserted',
    'CREATE TABLE k37_live_money ('
  . ' id INT IDENTITY PRIMARY KEY, amount MONEY NULL)',
    'CREATE TABLE k37_live_dt ('
  . ' id INT IDENTITY PRIMARY KEY, dt DATETIME NULL,'
  . ' small_dt SMALLDATETIME NULL)',
    'CREATE TABLE k37_live_long ('
  . ' id INT IDENTITY PRIMARY KEY, body VARCHAR(MAX) NULL,'
  . ' nbody NVARCHAR(MAX) NULL, note VARCHAR(100) NULL)',
  );
}

# The statements a storage sends while $code runs, as its own trace gives
# them: "<sql>: <bind values>".
sub traced {
  my ($storage, $code) = @_;
  my @statements;
  $storage->debugcb(sub { push @statements, $_[1] });
  $storage->debug(1);
  my $ok  = eval { $code->(); 1 };
  my $err = $@;
  $storage->debug(0);
  $storage->debugcb(undef);
  die $err unless $ok;
  return @statements;
}

my $live = 1;   # past every skip_all: from here on there is something to drop

drop_tables();  # what a run that died before its END block may have left

# ===================================================================== A
# The k37 live criterion: what the seam builds is accepted and works.

# ------------------------------------------ A1. the DSN connects, and where

{
  my $storage = $CONNECT{pinned}->()->storage;

  is $storage->_dbi_connect_info->[0], $BUILT,
    'pinned: host, port and dbname from a Static broker are the DSN '
  . 'dbi:Sybase:host=..;port=..;database=.. -- what t/59 pins, here on the '
  . 'storage that is about to connect with it';

  my $dbh;
  lives_ok { $dbh = $storage->dbh }
    'pinned: the server accepts that DSN -- the thing t/59 could not show';

  is $dbh->{Driver}{Name}, 'Sybase',
    'pinned: the connection runs on DBD::Sybase, the DBD the DSN names; the '
  . 'registered name MSSQL names none';

  is +( $dbh->selectrow_array('SELECT DB_NAME()') )[0], $dbname,
    'pinned: the session is in the database the parameters name -- with '
  . 'dbname= for database=, as core\'s default form has it, the connect '
  . 'succeeds all the same and lands in the login\'s default database';
}

{
  my $storage = T::K37::Pinned->connect({
    host => $host, port => $port, dbname => $dbname,
    user => $user, password => $pass,
  })->storage;

  is $storage->_dbi_connect_info->[0], $BUILT,
    'pinned: a connect-info hash without a dsn builds the same DSN';

  is +( $storage->dbh->selectrow_array('SELECT DB_NAME()') )[0], $dbname,
    'pinned: ... and connects into the same database -- the broker is not '
  . 'the only way to the seam';
}

# host and port without dbname. Without this the database= assertion above
# proves little on its own: it needs a login whose default database is some
# other one, and this is where that is looked at.
{
  my $default_db = server_value(
    'SELECT default_database_name FROM sys.server_principals '
  . 'WHERE sid = SUSER_SID()'
  );

  diag 'The login\'s default database is the test database: this run '
     . 'cannot tell a database= that is honoured from one that is ignored'
    if $default_db eq $dbname;

  my $storage
    = T::K37::Pinned->connect(broker(host => $host, port => $port))->storage;

  is +( $storage->dbh->selectrow_array('SELECT DB_NAME()') )[0], $default_db,
    'pinned: host and port without dbname connect too, into the login\'s '
  . 'default database -- no database= in the DSN means none is made up';
}

# ---------------------------- A2. everyday operations, the same on both ways
#
# The pinned storage is the one a broker user gets. It ends in the class the
# dsn way ends in (B), and it gets there another way: its DSN is built from
# parameters. So each of these is asked of both -- identity
# retrieval and transaction statements, which are the DBD::Sybase class's,
# and the SQL only this driver writes (MONEY cast, ROW_NUMBER limit,
# IDENTITY_INSERT bracket).

for my $way (qw(pinned dsn)) {
  fresh_tables();

  my $schema  = $CONNECT{$way}->();
  my $storage = $schema->storage;
  my $rs      = $schema->resultset('Item');

  # IDENTITY: the key of a new row
  my @ids = map { $rs->create({ name => "row $_" })->id } 1, 2;

  is_deeply \@ids, [ 1, 2 ],
    "$way: create() returns the IDENTITY value of the row it inserted";

  is $storage->last_insert_id, 2,
    "$way: last_insert_id is the last of them";

  is_deeply server_rows('SELECT id, name FROM k37_live_item ORDER BY id'),
    [ [ 1, 'row 1' ], [ 2, 'row 2' ] ],
    "$way: ... and those are the ids the server gave these rows -- a key "
  . 'that merely looks plausible would send every later update and delete '
  . 'to the wrong row';

  # transactions, looked at from the other session: only a real COMMIT or
  # ROLLBACK is visible there
  $schema->txn_do(sub { $rs->create({ name => 'committed' }) });

  is server_value(
       q{SELECT COUNT(*) FROM k37_live_item WHERE name = 'committed'}
     ), 1,
    "$way: txn_do commits -- another session sees the row";

  throws_ok {
    $schema->txn_do(sub {
      $rs->create({ name => 'rolled back' });
      die "k37 rollback\n";
    });
  } qr/k37 rollback/, "$way: an exception inside txn_do comes out of it";

  is server_value(
       q{SELECT COUNT(*) FROM k37_live_item WHERE name = 'rolled back'}
     ), 0,
    "$way: ... and the row is gone: no half transaction left on the server";

  $schema->txn_do(sub {
    $rs->create({ name => 'before savepoint' });
    $schema->svp_begin('k37_sp');
    $rs->create({ name => 'after savepoint' });
    $schema->svp_rollback('k37_sp');
  });

  is_deeply
    server_rows(
      q{SELECT name FROM k37_live_item WHERE name LIKE '%savepoint'}
    ),
    [ [ 'before savepoint' ] ],
    "$way: a savepoint rollback undoes what came after it and keeps the "
  . 'transaction around it';

  # void context: the bulk path, no identity retrieval
  $rs->populate([ map { { name => "bulk $_" } } 1 .. 3 ]);

  is server_value(
       q{SELECT COUNT(*) FROM k37_live_item WHERE name LIKE 'bulk %'}
     ), 3,
    "$way: populate in void context inserts every row";

  is $rs->create({ id => 500, name => 'explicit' })->id, 500,
    "$way: an explicit value for the IDENTITY column is taken -- the server "
  . 'refuses it without SET IDENTITY_INSERT ON around the statement';

  is $rs->create({ name => 'after explicit' })->id, 501,
    "$way: ... and the bracket is closed again: the next row gets its key "
  . 'from the server, continuing after the explicit one';

  my $money = $schema->resultset('Money');
  my $paid  = $money->create({ amount => '1234567.8912' });

  is $money->find($paid->id)->amount, '1234567.8912',
    "$way: a MONEY value comes back with all four decimals, through a "
  . 'bind value (CAST(? AS MONEY))';

  my @all_ids
    = map { $_->[0] } @{ server_rows('SELECT id FROM k37_live_item ORDER BY id') };

  cmp_ok scalar @all_ids, '>', 3,
    "$way: (there are rows beyond the window asked for next)";

  is_deeply
    [ map { $_->id }
        $rs->search({}, { order_by => 'id', rows => 2, offset => 1 })->all ],
    [ @all_ids[ 1, 2 ] ],
    "$way: rows => 2, offset => 1 is the second and third row -- the "
  . 'ROW_NUMBER() window with its bounds as bind values';

  # ---- a second active statement, on the host=..;port=.. form
  #
  # DBD::Sybase has no second statement on one connection: it opens a child
  # connection. Measured (karr k41, k44): on this DSN that connection IS made
  # -- `use <db>` is answered on it -- but the client library leaves its
  # message 44 ("Server name not found in configuration files") on the
  # handle, which $dbh->do clears at its execute and core's own prepare
  # reports as an error. The DSN built from host and port names no server
  # (the seam's POD: "It names no server"); this is what that comes to,
  # observed -- and that the failure is a clean exception, not a broken
  # connection.
  my $cursor = $rs->search({}, { order_by => 'id' });

  is $cursor->next->id, 1,
    "$way: a cursor is open, one row fetched, more pending";

  throws_ok { $rs->find(2) }
    qr/Server name not found in configuration files/,
    "$way: a second statement while it is open is refused -- the "
  . 'host=..;port=.. DSN names no server, so the client message 44 stays on '
  . 'the handle and core\'s prepare reports it';

  is $cursor->next->id, 2,
    "$way: the open cursor goes on where it was: the refusal did not cost "
  . 'the connection';

  $cursor->reset;

  is $rs->find(2)->name, 'row 2',
    "$way: ... and with the cursor closed the same statement runs";
}

# --------------------------------- A3. dbname alone: the server by its name
#
# { dbname } builds dbi:Sybase:database=.., and which server that reaches is
# the client library's to say: $DSQUERY, resolved against freetds.conf. Both
# variables are read at every connect, so setting them here -- with other
# connections of this process already open -- is enough (tried: a local
# %ENV change before the connect is honoured).
#
# A named server is also the form on which a second active statement works
# without that message: the child connection has a name to resolve.

{
  my $named = 'k37_live_named';

  my $conf = File::Temp->new(SUFFIX => '.conf');
  print {$conf} "[$named]\n\thost = $host\n\tport = $port\n"
              . "\ttds version = 7.4\n";
  close $conf or die "Cannot write the temporary freetds.conf: $!";

  local $ENV{FREETDSCONF} = "$conf";

  {
    local $ENV{DSQUERY} = 'k37_live_no_such_server';

    throws_ok {
      T::K37::Pinned->connect(broker(dbname => $dbname))->storage->dbh;
    } qr/Server name not found in configuration files/,
      'pinned: dbname alone, with $DSQUERY naming a server no configuration '
    . 'knows, does not connect -- the DSN carries no address, and nothing '
    . 'falls back to localhost or 1433';
  }

  local $ENV{DSQUERY} = $named;

  my %connect_named = (
    pinned  => sub { T::K37::Pinned->connect(broker(dbname => $dbname)) },
    dsn     => sub {
      T::K37::ByDSN->connect("dbi:Sybase:database=$dbname", $user, $pass);
    },
  );

  for my $way (qw(pinned dsn)) {
    fresh_tables();
    admin()->do(
      q{INSERT INTO k37_live_item (name) VALUES ('a'), ('b'), ('c')}
    );

    my $schema  = $connect_named{$way}->();
    my $storage = $schema->storage;

    is $storage->_dbi_connect_info->[0], "dbi:Sybase:database=$dbname",
      "$way, named server: the DSN names a database and no server";

    is +( $storage->dbh->selectrow_array('SELECT DB_NAME()') )[0], $dbname,
      "$way, named server: the same DSN connects once \$DSQUERY names a "
    . 'server freetds.conf knows, and into the database= it carries';

    my $rs     = $schema->resultset('Item');
    my $cursor = $rs->search({}, { order_by => 'id' });

    is $cursor->next->name, 'a',
      "$way, named server: a cursor is open, one row fetched";

    lives_and { is $rs->find(2)->name, 'b' }
      "$way, named server: a second statement while it is open runs -- the "
    . 'child connection finds the server by its name. This is what the '
    . 'host=..;port=.. form cannot do';

    is $cursor->next->name, 'b',
      "$way, named server: ... and the first cursor is undisturbed";

    $cursor->reset;
  }
}

# ===================================================================== B
# The pinned way is the DBD::Sybase class (karr k37; core k301, ADR 0059).
#
# Until the storage adapted itself to the access path, the pinned storage was
# DBIO::MSSQL::Storage on this DBD too, and every block below was a
# difference between the two ways: what the pinned way WAS stood here as a
# plain test (2026-10-05), what it should be as a TODO test. Both ways are
# asked the same thing now, and each comment says what the pinned way
# answered before.

# ---------------------------------------- B1. the class, and what hangs on it
#
# Driver resolution is lazy: it runs at the first use that needs the driver,
# not at connect. So a storage is connected before its class is looked at.

{
  fresh_tables();
  admin()->do(
    q{INSERT INTO k37_live_long (body) }
  . q{VALUES (REPLICATE(CAST('x' AS VARCHAR(MAX)), 100000))}
  );

  my $server_version
    = server_value(q{SELECT CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(40))});
  my $plain_textsize = server_value('SELECT @@TEXTSIZE');
  my $plain_length   = length server_value('SELECT body FROM k37_live_long');

  {
    my $storage = $CONNECT{pinned}->()->storage;

    is ref $storage, 'DBIO::MSSQL::Storage',
      'pinned: the schema connected, the storage is the class the component '
    . 'pinned -- nothing is decided before the first use';

    ok !$storage->_driver_determined,
      'pinned: ... and its driver is not determined yet';
  }

  for my $way (qw(pinned dsn)) {
    my $schema  = $CONNECT{$way}->();
    my $storage = $schema->storage;
    my $dbh     = $storage->dbh;

    # Was, pinned: DBIO::MSSQL::Storage, with nothing of DBIO::Sybase::Storage
    # in it.
    is ref $storage, 'DBIO::MSSQL::Storage::Sybase::FreeTDS',
      "$way: connected over DBD::Sybase, the storage is the DBD::Sybase "
    . 'transport class, FreeTDS adaptations mixed in';

    ok $storage->isa($_), "$way: ... which is a $_"
      for qw(DBIO::MSSQL::Storage DBIO::Sybase::Storage);

    is $storage->_declared_storage_class, 'DBIO::MSSQL::Storage',
      "$way: ... adapted from the class the schema declared, which is still "
    . 'on record as that';

    # Was, pinned: undef -- DBD::Sybase answers no get_info, and the way that
    # works (xp_msver) is the DBD::Sybase class's. Nothing in this driver
    # branches on the version (LIMIT is always ROW_NUMBER); t/10 opens by
    # asking for it.
    is $storage->_server_info->{dbms_version}, $server_version,
      "$way: the server version is the one the server reports";

    # Was, pinned: not turned off -- and no harm seen, DBD::Sybase 1.27 kept
    # no statement of a prepare_cached.
    is $storage->disable_sth_caching, 1,
      "$way: statement caching is off -- the workaround for FreeTDS above "
    . '0.82';

    # Text size. The FreeTDS class applies LongReadLen as SET TEXTSIZE at
    # connect (DBIO::Sybase::Storage::FreeTDS, set_textsize). Was, pinned:
    # the protocol's default, unlimited on TDS 7.4, so the pinned way read
    # the whole value -- this is the one place where the class it adapts to
    # gives it less than it had: a value longer than LongReadLen is cut on
    # the way back, without an error, unless LongReadLen is raised in the
    # connect info. On a protocol version with a small default (4096 on TDS
    # 4.2) the base class would have read less, and no LongReadLen helped it.
    # (Karr k47: that is the RAW handle, which is read below. A column read
    # through the storage's select is behind a check the server runs, and a
    # value over the TEXTSIZE is refused there: t/77-long-values-live.t.)
    is +( $dbh->selectrow_array('SELECT @@TEXTSIZE') )[0], $dbh->{LongReadLen},
      "$way: \@\@TEXTSIZE is LongReadLen -- set at connect";

    isnt $dbh->{LongReadLen}, $plain_textsize,
      "$way: ... which is not what a plain DBI connection has";

    cmp_ok $plain_length, '>', $dbh->{LongReadLen},
      "$way: (a plain DBI connection reads a value longer than that whole)";

    is length +( $dbh->selectrow_array('SELECT body FROM k37_live_long') )[0],
      $dbh->{LongReadLen},
      "$way: through the storage's handle the same value is cut to "
    . 'LongReadLen on the way back';
  }
}

# ------------------------------------------------- B2. DateTime inflation
#
# on_connect_call => 'datetime_setup' is how a DBIO::MSSQL user gets
# DateTime columns over DBD::Sybase: DBIO::MSSQL::Storage::Sybase sets the
# handle to ISO_strict and brings the parser that reads it.
#
# Was, pinned: the option resolved to core's no-op, silently; the value
# arrived in the client library's display format, without seconds, and
# reading a DateTime column threw ("does not match your pattern"). Writing
# was not affected.

{
  fresh_tables();

  my $dt = DateTime->new(
    year => 2026, month  => 10, day    => 5,
    hour => 13,   minute => 14, second => 15, nanosecond => 123_000_000,
  );
  my $small_dt = DateTime->new(
    year => 2026, month => 10, day => 5, hour => 13, minute => 14,
  );
  my $fmt = '%Y-%m-%dT%H:%M:%S.%3N';

  for my $way (qw(pinned dsn)) {
    my $schema  = $CONNECT{$way}->({ on_connect_call => 'datetime_setup' });
    my $storage = $schema->storage;
    my $rs      = $schema->resultset('DT');

    my $id = $rs->create({ dt => $dt, small_dt => $small_dt })->id;

    is_deeply
      server_rows(
        'SELECT CONVERT(VARCHAR(30), dt, 121), '
      . 'CONVERT(VARCHAR(30), small_dt, 121) FROM k37_live_dt WHERE id = ?',
        undef, $id,
      ),
      [ [ '2026-10-05 13:14:15.123', '2026-10-05 13:14:00.000' ] ],
      "$way: a DateTime is written as the instant it is, milliseconds "
    . 'included';

    is $storage->datetime_parser_type,
      'DBIO::MSSQL::Storage::Sybase::DateTime::Format',
      "$way: the parser is the one for DBD::Sybase";

    my $row = $rs->find($id);

    is $row->get_column('dt'), '2026-10-05T13:14:15.123Z',
      "$way: datetime_setup set the handle to ISO_strict -- the value "
    . 'arrives complete';

    is $row->dt->strftime($fmt), '2026-10-05T13:14:15.123',
      "$way: a datetime column inflates, milliseconds included";

    is $row->small_dt->strftime($fmt), '2026-10-05T13:14:00.000',
      "$way: a smalldatetime column inflates";
  }
}

# ---------------------------------------------- B3. "no placeholders" is heard
#
# _use_typeless_placeholders(0) before the first use is how t/10 forces the
# NoBindVars class, and it stands for what detection says on a setup whose
# TDS protocol cannot bind. The storage then interpolates the values into the
# SQL.
#
# Was, pinned: the storage stayed DBIO::MSSQL::Storage and went on sending
# "?" -- the base has no such class to become. Nothing failed because of it:
# this server binds.

{
  local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;

  for my $way (qw(pinned dsn)) {
    fresh_tables();

    my $schema  = $CONNECT{$way}->();
    my $storage = $schema->storage;

    # Set, not read: reading the capability would connect to detect it, and
    # the class is decided at that first connect.
    $storage->_use_typeless_placeholders(0);
    $storage->dbh;

    is ref $storage, 'DBIO::MSSQL::Storage::Sybase::NoBindVars::FreeTDS',
      "$way: told not to use placeholders, the storage becomes the "
    . 'NoBindVars class';

    my ($insert) = traced($storage, sub {
      $schema->resultset('Item')->create({ name => q{o'brien} });
    });

    like $insert, qr/VALUES \('o''brien'\)/,
      "$way: the value is in the SQL, quoted -- no placeholder on the wire";

    is server_value('SELECT name FROM k37_live_item'), q{o'brien},
      "$way: ... and arrives, quote and all";
  }
}

# ===================================================================== C
# The key of a new row, with a trigger on its table (karr k39).
#
# Was: for FreeTDS above 0.82 the DBD::Sybase class sent the INSERT alone and
# asked SELECT @@identity afterwards -- the last identity of the SESSION, and
# a trigger that inserts into another IDENTITY table is part of the session.
# create() then handed back the other table's identity as this row's primary
# key: an existing row of the wrong number, so nothing failed until the next
# update or delete hit it (1000 for the row 1 here). The base class appends
# SELECT SCOPE_IDENTITY() to the INSERT -- the identity of that statement's
# scope, which a trigger is not part of -- and was right; SCOPE_IDENTITY()
# works over FreeTDS 1.3.17 (measured 2026-10-17), so the workaround is gone.
#
# Mutation check, done by hand: turning the appended statement back into
# @@IDENTITY (the workaround) makes "the key is the row's own" fail with 1000.

for my $way (qw(pinned dsn)) {
  fresh_tables();

  my $schema  = $CONNECT{$way}->();
  my $storage = $schema->storage;
  my $row_id;

  my ($insert) = traced($storage, sub {
    $row_id
      = $schema->resultset('Trig')->create({ name => 'with trigger' })->id;
  });

  is_deeply
    [
      server_rows('SELECT id FROM k37_live_trig'),
      server_rows('SELECT id, trig_id FROM k37_live_audit'),
    ],
    [ [ [ 1 ] ], [ [ 1000, 1 ] ] ],
    "$way: (the row is id 1, and the trigger fired: its audit row is "
  . 'id 1000 -- two different identities in one session)';

  like $insert, qr/SELECT SCOPE_IDENTITY\(\)/,
    "$way: the INSERT asks for the identity of its own scope";

  ok !$storage->_no_scope_identity_query,
    "$way: ... the scoped query is not turned off";

  ok !$storage->_identity_method,
    "$way: ... and there is no session-wide fallback to fall into";

  is $row_id, 1,
    "$way: create() on a table with a trigger returns the row's own "
  . 'primary key, not the identity of the trigger\'s row in another table';

  my $row = $schema->resultset('Trig')->create({ name => 'second' });
  is $row->id, 2, "$way: ... the next one as well";
  is server_value('SELECT name FROM k37_live_trig WHERE id = ?', undef, $row->id),
    'second', "$way: ... and the key finds the row";
}

# ===================================================================== D
# Bind values of more than 4000 bytes (karr k40).
#
# Plain DBI over DBD::Sybase stores 4000 characters of a longer bind value,
# with no error and no warning, into whatever column: FreeTDS declares every
# placeholder as varchar(4000) when it prepares the statement, and the server
# cuts the value to that. The column takes more (VARCHAR(MAX)) and so does
# the wire: the same connection carries 100000 characters when they are a
# literal in the statement. Until 2026-10-07 both storages bound such a value
# and lost the rest of it -- what is the SHOULD test below was a TODO test.
#
# DBIO::MSSQL::Storage::Sybase now sends a value over the line as a literal
# in the statement. Everything here is asked of the server afterwards, from
# the other session: how many bytes it holds and their SHA-256, so that a
# value that arrived in full length but changed on the way is seen too.

# [ bytes, SHA-256 ] of what the server holds in a column of one row ...
sub server_holds {
  my ($column, $id) = @_;

  my ($bytes, $sha) = admin()->selectrow_array(
    "SELECT DATALENGTH($column), "
  . "CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', $column), 2) "
  . 'FROM k37_live_long WHERE id = ?',
    undef, $id,
  );

  return [ $bytes, defined $sha ? lc $sha : undef ];
}

# ... and of what was given: the string itself for the VARCHAR column and a
# value of ASCII, its UTF-16 form for the NVARCHAR column.
sub given    { [ length $_[0], Digest::SHA::sha256_hex($_[0]) ] }
sub given_as_utf16 { given(Encode::encode('UTF-16LE', $_[0])) }

for my $way (qw(pinned dsn)) {
  fresh_tables();

  my $schema = $CONNECT{$way}->();
  my $rs     = $schema->resultset('Long');
  my $length = 'SELECT LEN(body) FROM k37_live_long WHERE id = ?';

  is server_value($length, undef, $rs->create({ body => 'x' x 4000 })->id),
    4000,
    "$way: a 4000-character bind value arrives whole";

  my $long    = join '', map { chr( 97 + $_ % 26 ) } 1 .. 5000;
  my $long_id = $rs->create({ body => $long })->id;

  is server_value($length, undef, $long_id), 5000,
    "$way SHOULD: a 5000-character bind value arrives whole, not stored "
  . 'as something else than was given';

  is_deeply server_holds(body => $long_id), given($long),
    "$way: ... and it is the value that was given, not only its length";

  my $huge = join '', map { chr( 65 + $_ % 26 ) } 1 .. 100_000;

  is_deeply server_holds(body => $rs->create({ body => $huge })->id),
    given($huge),
    "$way: a value of 100000 characters arrives whole as well";

  $schema->storage->dbh->do(
    q{INSERT INTO k37_live_long (body) VALUES ('} . ('y' x 100_000) . q{')}
  );

  is server_value(
       q{SELECT LEN(body) FROM k37_live_long WHERE body LIKE 'y%'}
     ), 100_000,
    "$way: 100000 characters as a literal, over the same connection, "
  . 'arrive whole -- neither the column nor the server is the limit, the '
  . 'placeholder is, and that is why the storage uses none for such a value';

  # ---- what a literal must not do to a value
  #
  # A quote, a "?", and the two things the server reads differently in a
  # literal than in a bound value: a backslash before a line break (dropped,
  # with the line break) and a NUL (the end of the statement text).
  my $awkward = join '',
    q{it's a 'quoted' ''thing''; is this a ? or two ??},
    "a backslash \\ alone, one before a line break \\\nand one before \\\r\n",
    "a NUL \0 and a tab \t, then: '); DROP TABLE k37_live_long; --",
    'z' x 5000;

  is_deeply server_holds(body => $rs->create({ body => $awkward })->id),
    given($awkward),
    "$way: a long value with quotes, question marks, a backslash before a "
  . 'line break and a NUL in it arrives as it was given';

  ok defined server_value(q{SELECT OBJECT_ID('k37_live_long', 'U')}),
    "$way: ... and a value that reads like the end of the statement was a "
  . 'value: the table is still there';

  # ---- several values, one of them long
  my $mixed = $rs->create({
    body => $long, nbody => 'short and bound', note => 'a note',
  });

  is_deeply
    [
      server_holds(body => $mixed->id),
      server_rows(
        'SELECT nbody, note FROM k37_live_long WHERE id = ?', undef, $mixed->id,
      ),
    ],
    [ given($long), [ [ 'short and bound', 'a note' ] ] ],
    "$way: of three values in one statement the long one arrives whole and "
  . 'the two short ones in their own columns';

  # ---- a long value that is not ASCII
  #
  # FreeTDS takes the client character set from the locale of the process,
  # and what a character beyond ASCII is on the wire depends on it. The
  # claim below is made for UTF-8 only -- the one it was measured with.
  SKIP: {
    my ($euro) = $schema->storage->dbh->selectrow_array(
      "SELECT UNICODE(N'" . Encode::encode('UTF-8', "\x{20AC}") . "')"
    );

    skip 'The client character set of this process is not UTF-8 (FreeTDS '
       . 'takes it from the locale): characters beyond ASCII are not looked '
       . 'at', 3
      unless $euro == 0x20AC;

    # a-umlaut and the euro sign are in the code page of most databases, the
    # CJK character and the one beyond the BMP are in none
    my $unicode = "\x{E4}\x{20AC}\x{4E2D}\x{1F600}" x 500;   # 6000 bytes of UTF-8

    is_deeply
      server_holds(nbody => $rs->create({ nbody => $unicode })->id),
      given_as_utf16($unicode),
      "$way: a long value of characters beyond ASCII arrives in an NVARCHAR "
    . 'column character for character -- also those the code page of the '
    . 'database does not have';

    is_deeply
      server_holds(
        nbody => $rs->create({ nbody => Encode::encode('UTF-8', $unicode) })->id
      ),
      given_as_utf16($unicode),
      "$way: ... and so does the same value given as the bytes of its UTF-8 "
    . 'form: a byte string means in the statement what it means when bound';

    # 1334 characters, 4002 bytes: the line is drawn in bytes. Bound, this
    # value arrived with every euro sign and 2666 blanks after them.
    my $euros = "\x{20AC}" x 1334;

    is_deeply
      server_holds(nbody => $rs->create({ nbody => $euros })->id),
      given_as_utf16($euros),
      "$way: a value under 4000 characters and over 4000 bytes arrives as "
    . 'it was given';
  }

  # ---- UPDATE, and a long value to find a row by
  #
  # Two rows that agree in their first 5000 characters. Bound, the value in
  # the condition was cut to 4000 characters and compared as that: it matched
  # neither of them.
  admin()->do('DELETE FROM k37_live_long');

  my $common = 'w' x 5000;
  my ($row_a, $row_b)
    = map { $rs->create({ body => $common . $_, note => $_ }) } 'a', 'b';

  is_deeply
    [ $rs->search({ body => $common . 'b' })->get_column('id')->all ],
    [ $row_b->id ],
    "$way: a search by a long value finds the row with that value, and "
  . 'not the one that differs after the first 5000 characters';

  my $replacement = join '', map { chr( 48 + $_ % 10 ) } 1 .. 9000;
  $rs->search({ body => $common . 'a' })->update({ body => $replacement });

  is_deeply
    [ server_holds(body => $row_a->id), server_holds(body => $row_b->id) ],
    [ given($replacement), given($common . 'b') ],
    "$way: an UPDATE by a long value, setting a long value, changes that "
  . 'row to the whole new value and leaves the other row alone';

  $rs->search({ body => $common . 'b' })->delete;

  is_deeply server_rows('SELECT id FROM k37_live_long'), [ [ $row_a->id ] ],
    "$way: a DELETE by a long value deletes the row with that value only";

  # ---- populate in void context
  #
  # The fast path executes one prepared statement once per row; a long value
  # cannot be in it for one row and not for the next.
  admin()->do('DELETE FROM k37_live_long');

  my %populated = (
    first  => 'short',
    second => 'q' x 5000,
    third  => 'r' x 7000,
  );

  $rs->populate([
    map { { note => $_, body => $populated{$_} } } qw(first second third)
  ]);

  is_deeply
    {
      map { $_->[1] => server_holds(body => $_->[0]) }
        @{ server_rows('SELECT id, note FROM k37_live_long') }
    },
    { map { $_ => given($populated{$_}) } keys %populated },
    "$way: populate in void context with long values in some rows: every "
  . 'row arrives with its own value, whole';
}

# ================================================================ the end

drop_tables();

is_deeply
  server_rows(q{SELECT name FROM sys.objects WHERE name LIKE 'k37[_]live%'}),
  [],
  'nothing of this test is left in the database';

is_deeply [ grep { $_ !~ $EXPECTED_WARNING } @warnings ], [],
  'no warning but the DBD::Sybase class\'s own FreeTDS notice -- no driver '
. 'mismatch for the pinned way';

done_testing;

# The tables again, on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    undef $admin;
    eval { drop_tables(); 1 }
      or diag "Could not drop the k37_live_* tables: $@";
  }
}
