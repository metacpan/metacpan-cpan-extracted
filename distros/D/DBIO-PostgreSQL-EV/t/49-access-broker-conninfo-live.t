use strict;
use warnings;
use Test::More;

# LIVE: built-in AccessBrokers on the ev transport against a real PostgreSQL
# (karr k54, found in dbio-postgresql k80). The offline half,
# t/48-access-broker-conninfo-mock.t, pins the exact libpq parameters EV::Pg
# is constructed with for every broker shape; this file shows that they reach
# a real server and authenticate:
#
#   a) a Static broker (dbname / host / port taken apart from the test DSN)
#      attached to the transport: select_async runs on a pool connection
#      logged in as the broker's user to the broker's database, with the
#      broker's password; a notify / listen round trip works on a listen
#      connection opened from the broker too; the same broker with a wrong
#      password is refused by the server's password check;
#   b) a Vault broker whose (stub) Vault client first issues a wrong password,
#      through MyApp::Schema->connect($vault) with dbi_attrs { async => 'ev' }:
#      the server refuses the password -- so it reached libpq -- and once the
#      lease rotates to the live password the next pool connection logs in,
#      and a notify / listen round trip works on a listen connection opened
#      from the broker.
#
# Before k54, (b) failed at every connection with libpq refusing the DSN
# string itself ('invalid connection option "dbi:Pg:dbname"'): no password
# check was ever reached. A server that does not ask this user for a password
# cannot tell a wrong one from the right one; the wrong-password claims are
# skipped then, saying so.

use DBIO::PostgreSQL::EV::TestHarness;

DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live;

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_PG_$_" } qw( DSN USER PASS ) };
plan skip_all => 'Set DBIO_TEST_PG_USER and DBIO_TEST_PG_PASS: the broker hands out credentials'
  unless defined $user && length $user && defined $pass && length $pass;

use EV;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::Util ();
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;

plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');

alarm 120;

# A server that is not there fails the file, with a plan. The Static broker
# needs the DSN's parts: the DSN read as the transport reads it, not taken
# apart here (karr k77).
LiveServer->require_server;
my %part = LiveServer->conninfo;
# The DSN is named without a password it may carry (karr k78).
plan skip_all => 'cannot take the test DSN apart into dbname / host / port: '
  . DBIO::Util::mask_connect_secrets($dsn, [ $dsn, $user, $pass ])
  unless defined $part{dbname};

my $WRONG = "$pass-but-wrong";

# Run the EV loop until $cond holds or $timeout passes. Never open-ended.
sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = EV::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if EV::time() > $deadline;
    my $tick = EV::timer(0.02, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

# get, bounded: a Future that does not settle fails instead of hanging. Dies
# with the Future's failure.
sub settle {
  my ($f, $what) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(15, 0, sub { $f->fail("watchdog: $what still pending after 15s\n") unless $f->is_ready });
  $dog->keepalive(0);
  return $f->get;
}

# Who and where the pool connection that runs it is logged in.
sub whoami {
  my ($async) = @_;
  my ($row) = settle($async->select_async(
    'pg_catalog.pg_stat_activity', [ 'usename', 'datname' ],
    { pid => \'= pg_backend_pid()' },
  ), 'whoami');
  return $row;
}

# The error of a whoami that must fail; the pool's warning about it is kept
# out of the test output.
sub whoami_error {
  my ($async) = @_;
  local $SIG{__WARN__} = sub { };
  return eval { whoami($async); 1 } ? undef : "$@";
}

# Does the server check this user's password? Asked of a connection that
# logged in with it; EV::Pg without connection_used_password cannot say.
sub used_password {
  my ($pg) = @_;
  return undef unless $pg->can('connection_used_password');
  return $pg->connection_used_password ? 1 : 0;
}

# A notify / listen round trip; returns who and where the listen connection
# is logged in, read before the last unlisten closes it.
sub round_trip {
  my ($async, $channel) = @_;
  my @got;
  settle($async->listen($channel => sub { push @got, [ @_[0, 1] ] }), "listen $channel");
  my $listen_pg = $async->{_listen}{conn}{pg};
  my @login = ($listen_pg->user, $listen_pg->db);
  settle($async->notify($channel => 'from the broker'), "notify $channel");
  ok wait_until(sub { @got }), "$channel: the notification sent on a pool connection arrived";
  is_deeply \@got, [ [ $channel, 'from the broker' ] ], '... on its channel, with its payload';
  settle($async->unlisten($channel), "unlisten $channel");
  return \@login;
}

my $checks_password;

subtest 'a) Static broker: select_async, notify / listen, a wrong password' => sub {
  my %where = (
    dbname => $part{dbname},
    (defined $part{host} ? (host => $part{host}) : ()),
    (defined $part{port} ? (port => $part{port}) : ()),
  );
  my $async = DBIO::PostgreSQL::EV::Storage->new(undef);
  $async->connect_info([ DBIO::AccessBroker::Static->new(%where, username => $user, password => $pass) ]);

  is_deeply whoami($async), [ $user, $part{dbname} ],
    'select_async ran on a pool connection opened from the broker: its user, its database';

  my $pg = settle($async->pool->acquire, 'acquire');
  $checks_password = used_password($pg);
  $async->pool->release($pg);
  if (defined $checks_password) {
    note $checks_password
      ? 'the server asked for the password -- the broker\'s reached it'
      : 'the server did not ask this user for a password';
  }

  is_deeply round_trip($async, "dbio_k54_${$}_static"), [ $user, $part{dbname} ],
    'the listen connection was opened from the broker too';
  $async->disconnect;

  my $wrong = DBIO::PostgreSQL::EV::Storage->new(undef);
  $wrong->connect_info([ DBIO::AccessBroker::Static->new(%where, username => $user, password => $WRONG) ]);
  my $err = whoami_error($wrong);
  $wrong->disconnect;
  SKIP: {
    skip 'the server does not ask this user for a password: a wrong one cannot be told from the right one', 2
      if defined $checks_password ? !$checks_password : !defined $err;
    ok defined $err, 'the same broker with a wrong password: the pool connection is refused';
    like $err // '', qr/password authentication failed/,
      '... by the server\'s password check -- the broker\'s password reached libpq';
  }
};

{
  package LiveVaultClient;
  sub new { my ($class, %creds) = @_; bless { creds => \%creds, reads => 0 }, $class }
  sub read_secret { my ($self) = @_; $self->{reads}++; return { %{ $self->{creds} } } }
}

{
  package BrokerSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}

subtest 'b) Vault broker through MyApp::Schema->connect: a wrong password, rotation, notify / listen' => sub {
  my $client = LiveVaultClient->new(username => $user, password => $WRONG);
  my $vault  = DBIO::AccessBroker::Vault->new(
    vault     => $client,
    dsn       => $dsn,
    cred_path => 'database/creds/dbio_test',
    dbi_attrs => { async => 'ev' },
  );
  my $schema = BrokerSchema->connect($vault);
  my $async  = $schema->storage->async;
  isa_ok $async, 'DBIO::PostgreSQL::EV::Storage', 'the ev backend, selected by the broker\'s dbi_attrs';

  my $err = whoami_error($async);
  unlike $err // '', qr/invalid connection option/,
    'the pool connection is not refused by libpq for its conninfo (the pre-k54 failure)';
  SKIP: {
    skip 'the server does not ask this user for a password: a wrong one cannot be told from the right one', 2
      if defined $checks_password ? !$checks_password : !defined $err;
    ok defined $err, 'the password Vault issued first is wrong: the pool connection is refused';
    like $err // '', qr/password authentication failed/,
      '... by the server\'s password check -- the Vault password reached libpq';
  }

  $client->{creds}{password} = $pass;
  $vault->_expires_at(0);   # the lease is up
  my $reads = $client->{reads};
  is_deeply whoami($async), [ $user, $part{dbname} ],
    'after the lease rotated to the live password, the next pool connection logs in as the Vault user';
  cmp_ok $client->{reads}, '>', $reads, '... with credentials Vault issued anew';

  is_deeply round_trip($async, "dbio_k54_${$}_vault"), [ $user, $part{dbname} ],
    'the listen connection was opened from the Vault broker';

  $async->disconnect;
};

done_testing;
