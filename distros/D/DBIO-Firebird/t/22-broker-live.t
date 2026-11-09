use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE (karr k39): what t/60-broker-dbd-attributes.t and
# t/62-connection-actions-once.t claim against stand-in handles, against a
# server.
#
#   1. An ib_ attribute handed over by an AccessBroker -- in its hash answer,
#      or beside it -- does not merely pass the storage's check: the
#      connection is opened, DBD::Firebird applies the attribute to the
#      handle, and a query runs on it. ib_softcommit is the one used because
#      the handle answers it back; a connection without it is the control
#      that the read-back tells the two apart.
#   2. on_connect_do and on_connect_call run once for each connection, on the
#      handle the storage keeps. The native storage reconnects during driver
#      determination to force SQL dialect 3 when the DSN does not carry it, so
#      "on the handle it keeps" is the half only a real handle can show: a
#      use_softcommit that ran on the discarded one would leave the kept one
#      without it.
#
# Skipped unless a DSN is provided (mirrors t/15-introspect-live.t):
#
#   DBIO_TEST_FIREBIRD_DSN  e.g. dbi:Firebird:dbname=localhost/3050:/path/test.fdb
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# It creates nothing: every statement is a SELECT from rdb$database.

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live broker tests'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::AccessBroker;
use DBIO::Schema;

{
  package T::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %answer) = @_; bless { answer => { %answer } }, $class }
  sub connect_info_for { +{ %{ $_[0]{answer} } } }
}

# A schema that declares its driver, as a user's does. A broker's ib_
# attribute needs that: a storage still generic at its first connection asks
# core's prefixes alone.
{
  package T::Declared::Schema;
  use DBIO 'Schema', -fb;
}

# One that keeps no driver in its class, as the shared test schema does: each
# use declares one on a clone (core ADR 0067).
{
  package T::Shared::Schema;
  use base 'DBIO::Schema';
}

my $ONE = 'SELECT 1 FROM rdb$database';

sub select_one {
  my ($storage) = @_;
  return $storage->dbh_do(sub { ( $_[1]->selectrow_array($ONE) )[0] });
}

{
  my $probe = eval { T::Declared::Schema->connect($dsn, $user, $pass) };
  plan skip_all => 'Cannot reach Firebird server: ' . ( $@ || 'no schema' )
    unless $probe && eval { select_one($probe->storage) };
  $probe->storage->disconnect;
}

my %LOGIN = (dsn => $dsn, user => $user, password => $pass);

# ---------------------------------------------------------------------------
# 1. An ib_ attribute from a broker reaches the handle.
# ---------------------------------------------------------------------------
for my $case (
  [ 'ib_softcommit in the hash answer' =>
      sub { T::Declared::Schema->connect(T::Broker->new(%LOGIN, ib_softcommit => 1)) }, 1 ],
  [ 'ib_softcommit beside the broker' =>
      sub { T::Declared::Schema->connect(T::Broker->new(%LOGIN), { ib_softcommit => 1 }) }, 1 ],
  [ 'control: a broker and no attribute' =>
      sub { T::Declared::Schema->connect(T::Broker->new(%LOGIN)) }, 0 ],
) {
  my ($label, $connect, $softcommit) = @$case;

  my $schema  = $connect->();
  my $storage = $schema->storage;

  my $dbh;
  lives_ok { $dbh = $storage->dbh } "$label: the connection is opened"
    or next;
  is ref $storage, 'DBIO::Firebird::Storage', '... by the native storage';
  is select_one($storage), 1, '... and a SELECT runs on it';
  is( ( $storage->dbh->{ib_softcommit} ? 1 : 0 ), $softcommit,
    $softcommit
      ? '... with ib_softcommit set on the handle: the attribute reached DBD::Firebird'
      : '... without ib_softcommit on the handle' );

  $storage->disconnect;
}

# ---------------------------------------------------------------------------
# 1b. SQL dialect 3 reaches the connection a broker's answer opens (karr k43).
# ---------------------------------------------------------------------------
# DBD::Firebird already defaults to dialect 3, so the handle cannot tell the
# difference; what is claimed is the DSN every DBI->connect is handed, and that
# the storage connects once and not twice (the old rewrite of a DSN the broker
# overwrote), with a statement that needs dialect 3 running on the kept handle.
{
  my @dsns;
  my $orig = \&DBI::connect;
  no warnings 'redefine';
  local *DBI::connect = sub { my $c = shift; push @dsns, $_[0]; $orig->($c, @_) };

  my $schema = T::Declared::Schema->connect(T::Broker->new(%LOGIN));
  my $storage = $schema->storage;
  lives_ok { $storage->dbh } 'a broker answering a DSN: the connection is opened';
  is scalar @dsns, 1, '... once';
  like $dsns[0] // '', qr/;ib_dialect=3(?:;ib_charset=UTF8)?\z/, '... with ib_dialect=3 in the DSN';
  is( ( $storage->dbh_do(sub { ( $_[1]->selectrow_array('SELECT 1 AS "one" FROM rdb$database') )[0] }) ), 1,
    '... and a quoted identifier works on the handle (dialect 3)' );
  $storage->disconnect;
}

# ---------------------------------------------------------------------------
# 1c. A broker's answer in another dialect than 3 is refused (karr k43).
# ---------------------------------------------------------------------------
# What dialect 1 does to a statement: "RDB$DATABASE" is an identifier in
# dialect 3 and a string literal in dialect 1, where the FROM clause then fails.
# The control is a plain DBI connection in each dialect, so the statement is
# known to tell them apart on this server; the claim is that no spelling of
# ib_dialect=1 in a broker's answer -- DSN in any letter case, or attribute,
# which the DBD would drop without a word -- opens a connection.
{
  my $probe = 'SELECT 1 FROM "RDB$DATABASE"';
  for my $dialect (3, 1) {
    my $dbh = DBI->connect("$dsn;ib_dialect=$dialect", $user, $pass,
      { RaiseError => 0, PrintError => 0 });
    my $lives = $dbh && $dbh->selectrow_arrayref($probe) ? 1 : 0;
    is $lives, $dialect == 3 ? 1 : 0,
      "control: the dialect-3 statement " . ($dialect == 3 ? 'runs' : 'fails')
      . " in dialect $dialect on a plain DBI connection";
    $dbh->disconnect if $dbh;
  }

  for my $case (
    [ 'ib_dialect=1 in the DSN'     => { %LOGIN, dsn => "$dsn;ib_dialect=1" } ],
    [ 'IB_DIALECT=1 in the DSN'     => { %LOGIN, dsn => "$dsn;IB_DIALECT=1" } ],
    [ 'ib_dialect => 1 attribute'   => { %LOGIN, ib_dialect => 1 } ],
  ) {
    my ($label, $answer) = @$case;
    my $storage = T::Declared::Schema->connect(T::Broker->new(%$answer))->storage;
    throws_ok { $storage->dbh } qr/ib_dialect other than 3/, "$label: the connection is refused";
    unlike $@, qr/\Q$pass\E/, '... without the password in the message' if length $pass;
  }

  for my $spelling ('ib_dialect=3', 'IB_DIALECT=3') {
    my $storage = T::Declared::Schema->connect(
      T::Broker->new(%LOGIN, dsn => "$dsn;$spelling"))->storage;
    lives_ok { $storage->dbh } "$spelling in the DSN: connects";
    is( ( $storage->dbh_do(sub { ( $_[1]->selectrow_array($probe) )[0] }) ), 1,
      '... and the dialect-3 statement runs on it' );
    $storage->disconnect;
  }
}

# ---------------------------------------------------------------------------
# 2. Connection actions: once per connection, on the handle that is kept.
# ---------------------------------------------------------------------------
for my $case (
  [ 'driver declared by the schema'   => 'T::Declared::Schema' ],
  [ 'storage class declared on a clone' =>
      T::Shared::Schema->clone(storage_type => '+DBIO::Firebird::Storage') ],
) {
  my ($label, $schema_class) = @$case;

  for my $entry (
    [ 'the handle asked for first' => sub { $_[0]->dbh } ],
    [ 'the driver determined first, then the handle' => sub { $_[0]->_determine_driver; $_[0]->dbh } ],
  ) {
    my ($how, $enter) = @$entry;
    my $t = "$label; $how";

    my ($calls, $dos) = (0, 0);
    my $schema = $schema_class->connect($dsn, $user, $pass, {
      on_connect_call => [ 'use_softcommit', sub { $calls++ } ],
      on_connect_do   => [ sub { $dos++; [ $ONE ] } ],
    });
    my $storage = $schema->storage;

    lives_ok { $enter->($storage) } "$t: connects"
      or next;
    is ref $storage, 'DBIO::Firebird::Storage', '... as the native storage';
    is $calls, 1, '... on_connect_call ran once';
    is $dos,   1, '... on_connect_do ran once';
    ok $storage->dbh->{ib_softcommit},
      '... and use_softcommit is in effect on the handle the storage keeps';
    is select_one($storage), 1, '... which a SELECT runs on';
    is_deeply [ $calls, $dos ], [ 1, 1 ], '... and using the connection runs nothing again';

    $storage->disconnect;
    $storage->dbh;
    is_deeply [ $calls, $dos ], [ 2, 2 ], "$t: a new connection runs them once more";
    ok $storage->dbh->{ib_softcommit}, '... with use_softcommit in effect on it too';

    $storage->disconnect;
  }
}

done_testing;
