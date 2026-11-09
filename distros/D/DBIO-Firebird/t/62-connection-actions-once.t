use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k39, checking core k309 against this driver).
#
# WHY: on_connect_do and on_connect_call are how a caller configures every
# connection -- and on this engine they are not optional: without
# on_connect_call => 'use_softcommit' the native drivers answer "no statement
# executing", and 'datetime_setup' is what makes TIMESTAMPs parseable. They
# have to run once for each connection the storage keeps: not at all leaves it
# unconfigured, twice repeats statements a caller wrote to run once.
#
# Two things in this driver sit exactly where core decides that:
#
#   * the native storages force SQL dialect 3 from _init by rewriting the DSN
#     and, when already connected, RECONNECTING -- in the middle of driver
#     determination. The actions must end up on the handle that survives, not
#     on the one thrown away, and not on both.
#   * the ODBC storage overrides _run_connection_actions to switch off array
#     operations for the OdbcFb driver before the caller's actions run. What
#     core does to that method's callers it does to this workaround.
#
# What this file claims, for every way into the first connection (the handle
# asked for first, or the driver determined first) and for a reconnect:
#   - each on_connect_do statement and each on_connect_call runs once per
#     connection, on the handle the storage is left holding;
#   - over ODBC the OdbcFb workaround is applied once per connection, and
#     before the caller's actions.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a sub handing out stand-in
# handles that record the statements done on them; the ODBC one answers
# get_info as the Firebird ODBC driver does (SQL_DBMS_NAME Firebird,
# SQL_DRIVER_NAME OdbcFb); _disable_odbc_array_ops, which needs DBD::ODBC to
# pick an attribute name, is replaced by a recorder. No DBD is asked to
# connect and no server is involved -- for the ODBC transport none was
# available, so that half is core's and this driver's code against a stand-in
# and nothing more. The native half against a server: t/22-broker-live.t.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

my $ON_CONNECT_DO = 'K39 ON CONNECT DO';

# what happened, in order: [ what, handle serial ]
our @LOG;

{
  package T::Handle;

  my $serial = 0;
  my %INFO = (
    17 => 'Firebird',   # SQL_DBMS_NAME
    6  => 'OdbcFb',     # SQL_DRIVER_NAME
  );

  sub new {
    my ($class, $dbd) = @_;
    return bless {
      Active => 1, AutoCommit => 1, RaiseError => 1,
      Driver => { Name => $dbd }, serial => ++$serial,
    }, $class;
  }
  sub FETCH      { $_[0]{ $_[1] } }
  sub ping       { $_[0]{Active} }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub rollback   { 1 }
  sub commit     { 1 }
  sub get_info   { $_[0]{Driver}{Name} eq 'ODBC' ? $INFO{ $_[1] } : undef }
  sub do {
    my ($self, $sql) = @_;
    push @main::LOG, [ do => $self->{serial} ] if $sql eq $ON_CONNECT_DO;
    return '0E0';
  }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub {
    my (undef, $dsn) = @_;
    my ($dbd) = $dsn =~ /^dbi:(\w+)/;
    push @CONNECTS, $dsn;
    return T::Handle->new($dbd);
  };

  *DBIO::Storage::DBI::ODBC::_disable_odbc_array_ops = sub {
    push @LOG, [ array_ops_off => $_[0]->_dbh->{serial} ];
  };
}

# A schema that declares the native driver, as a user's does ...
{
  package T::Native::Schema;
  use DBIO 'Schema', -fb;
}

# ... one that pins the ODBC storage by name -- the one declared way to it
# until the driver adapts to an ODBC DSN by itself (karr k40) ...
{
  package T::PinnedODBC::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Firebird::Storage::ODBC');
}

# ... and one that keeps no driver in its class, as the shared test schema
# does: each use declares one on a clone (core ADR 0067). Connected as it is,
# it is refused.
{
  package T::Shared::Schema;
  use base 'DBIO::Schema';
}

sub connect_schema {
  my ($schema_class, $dsn) = @_;
  return $schema_class->connect($dsn, 'k39-user', 'k39-secret', {
    on_connect_do   => [ $ON_CONNECT_DO ],
    on_connect_call => [ sub { push @LOG, [ call => $_[0]->_dbh->{serial} ] } ],
  });
}

# The log of one connection: what ran, each on the handle the storage holds.
sub ran_once_on_kept_handle {
  my ($storage, $expected, $label) = @_;
  my $kept = $storage->_dbh->{serial};
  is_deeply [ @LOG ], [ map { [ $_ => $kept ] } @$expected ],
    "$label: " . join(', then ', @$expected) . ' -- each once, on the handle the storage keeps'
    or diag explain { kept => $kept, log => \@LOG, connects => \@CONNECTS };
}

my @ENTRIES = (
  [ 'the handle asked for first' => sub { $_[0]->dbh } ],
  [ 'the driver determined first, then the handle' => sub { $_[0]->_determine_driver; $_[0]->dbh } ],
  [ 'ensure_connected' => sub { $_[0]->ensure_connected } ],
);

my @CASES = (
  # label, schema class, DSN, storage class, what runs per connection
  [ 'native, DSN without ib_dialect (the storage reconnects to force dialect 3)',
    'T::Native::Schema', 'dbi:Firebird:dbname=/k39/app.fdb',
    'DBIO::Firebird::Storage', [ qw( call do ) ] ],
  [ 'native, DSN carrying ib_dialect',
    'T::Native::Schema', 'dbi:Firebird:dbname=/k39/app.fdb;ib_dialect=3',
    'DBIO::Firebird::Storage', [ qw( call do ) ] ],
  [ 'ODBC, storage class pinned',
    'T::PinnedODBC::Schema', 'dbi:ODBC:Driver=Firebird;Dbname=/k39/app.fdb',
    'DBIO::Firebird::Storage::ODBC', [ qw( array_ops_off call do ) ] ],
  [ 'ODBC, storage class declared on a clone',
    T::Shared::Schema->clone(storage_type => '+DBIO::Firebird::Storage::ODBC'),
    'dbi:ODBC:Driver=Firebird;Dbname=/k39/app.fdb',
    'DBIO::Firebird::Storage::ODBC', [ qw( array_ops_off call do ) ] ],
);

for my $case (@CASES) {
  my ($label, $schema_class, $dsn, $storage_class, $expected) = @$case;

  for my $entry (@ENTRIES) {
    my ($how, $enter) = @$entry;
    my $t = "$label; $how";

    local (@LOG, @CONNECTS);
    my $storage = connect_schema($schema_class, $dsn)->storage;

    is scalar @CONNECTS, 0, "$t: connect opens no connection";

    $enter->($storage);
    is ref $storage, $storage_class, "$t: the storage is a $storage_class";
    ran_once_on_kept_handle($storage, $expected, $t);

    like $CONNECTS[-1], qr/ib_dialect=3/, "$t: ... a connection opened with dialect 3"
      if $storage_class eq 'DBIO::Firebird::Storage';

    # the ISO date formats are the default of a native connection (karr k55),
    # set without being logged as one of the caller's actions; ODBC is untouched
    is $storage->_dbh->{ib_time_all},
      ($storage_class eq 'DBIO::Firebird::Storage' ? 'ISO' : undef),
      "$t: ib_time_all is " . ($storage_class eq 'DBIO::Firebird::Storage' ? 'ISO by default' : 'not set');

    # using it runs nothing again
    @LOG = ();
    $storage->dbh for 1 .. 2;
    is_deeply [ @LOG ], [], "$t: the connection in use: nothing runs again";

    # a new connection is configured like the first
    $storage->disconnect;
    @LOG = ();
    my $connects = @CONNECTS;
    $storage->dbh;
    is scalar @CONNECTS, $connects + 1, "$t: after a disconnect, one new connection";
    ran_once_on_kept_handle($storage, $expected, "$t, reconnected");
  }
}

is( T::Shared::Schema->storage_type, '::DBI',
  'the declaration on the clone stayed there: the shared class keeps no driver' );

# A schema that declares nothing never gets as far as a connection, so no
# action can run on one -- not once, not on a handle it would throw away.
SKIP: {
  skip 'core before ADR 0067 still detects a driver from the DSN for a schema '
     . 'that declares none (DBIO->driver_for is the marker of the new rule)', 3
    unless DBIO->can('driver_for');

  local (@LOG, @CONNECTS);
  throws_ok { connect_schema('T::Shared::Schema', 'dbi:ODBC:Driver=Firebird;Dbname=/k39/app.fdb') }
    qr/declares no driver/,
    'ODBC, nothing declared: refused at connect (ADR 0067)';
  is scalar @CONNECTS, 0, '... before any connection is opened';
  is_deeply [ @LOG ], [], '... and before any connection action runs';
}

done_testing;
