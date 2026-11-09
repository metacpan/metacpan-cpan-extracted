use strict;
use warnings;
use Test::More;
use Time::HiRes ();

# LIVE half of t/73 (karr k71, point 3; karr k67): an AccessBroker detached
# while the listen connection is up -- on real connections.
#
# WHY IT MATTERS. Every connection of this transport is opened from what the
# attached broker answers, asked anew each time. With the broker detached
# (DBIO::Storage's public clear_access_broker) there is nobody to ask, and a
# connection opened from an earlier answer would run on credentials no broker
# answers for any more -- a revoked lease, the account the broker was put there
# to replace. t/73 pins offline, over a fake DBD that records every
# DBI->connect, that nothing is opened then and that the error says why. This
# file holds the same claims against a server, where "nothing reached
# DBI->connect" reads: no new session of ours appears in the server's process
# list.
#
# What this file claims (t/73's claims 2 and 2b for clear_access_broker, with
# pool and listen connection up):
#   1. the detach itself touches nothing: the listen connection is the same
#      server session afterwards, alive, and goes on delivering -- no
#      reconnect, no error reported. (t/73 states this and does not test it:
#      nothing closes a connection that was opened while the broker answered
#      for it.)
#   2. from then on nothing is opened: a pool spawn fails, _listen_open dies,
#      and listen_reconnect() fails its Future -- each saying that the storage
#      has no AccessBroker attached to ask for connect info; on_listen_error
#      hears it; the rebuild has closed the listen connection that was up and
#      none takes its place; core retries with backoff and every retry is
#      refused the same way; no new session of ours appears on the server;
#   3. healing: a listen connection that DIES after the detach (KILL from
#      another session) is not replaced either -- on_listen_error hears why it
#      was lost, then the same refusal at every retry;
#   4. no report or warning names the password.
#
# The broker answers the connect info of the environment in DBI form. The
# schema loads the driver component that belongs to the DSN's DBD.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Creates and drops a notify table of its own; the session it kills is its own
# listen connection.

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

BEGIN {
  eval {
    require IO::Async::Loop;
    require Future::IO::Impl::IOAsync;
    Future::IO::Impl::IOAsync->import;
    1;
  } or plan skip_all =>
    'Future::IO::Impl::IOAsync + IO::Async required for the live future_io roundtrip';
}

use DBI;
use DBIO::Test;
use DBIO::AccessBroker;
use DBIO::MySQL::NotifyTable;

eval {
  require DBIO::MySQL::Storage::Async;
  require DBIO::MySQL::Storage::MariaDB::Async;
  1;
} or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
plan skip_all => 'the installed dbio-async predates _async_broker_conninfo'
  unless DBIO::Async::Storage->can('_async_broker_conninfo');
plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');
plan skip_all => 'the installed dbio-async predates its Future::IO listen seams (dbio-async k22)'
  unless defined &DBIO::Async::Storage::_listen_drain;

my %API = (
  mysql   => { component => 'MySQL',          thread_id => 'mysql_thread_id' },
  MariaDB => { component => 'MySQL::MariaDB', thread_id => 'mariadb_thread_id' },
);
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;
plan skip_all => 'DBIO_TEST_MYSQL_DSN names neither dbi:mysql: nor dbi:MariaDB:'
  unless defined $dbd && $API{$dbd};
my $api = $API{$dbd};

{
  package K71Live::Schema;
  use base 'DBIO::Test::Schema';

  # One fixed answer, in DBI form.
  package K71Live::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answer) = @_; bless { answer => [@answer] }, $class }
  sub connect_info_for { [ @{ $_[0]{answer} } ] }
}
K71Live::Schema->load_components($api->{component});

my $loop = IO::Async::Loop->new;

sub wait_until {
  my ($cond, $timeout) = @_;
  my $deadline = Time::HiRes::time() + ($timeout // 10);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    $loop->loop_once(0.05);
  }
  return 1;
}

my $T  = "dbio_k71_notify_$$";
my $NT = DBIO::MySQL::NotifyTable->new(table => $T);

# The other session: sends notifications, kills, and reads the process list.
my $other = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
note sprintf 'server %s, DBD::%s %s', scalar $other->selectrow_array('SELECT VERSION()'),
  $dbd, "DBD::$dbd"->VERSION;

my @storages;
END {
  if ($other) {
    local ($@, $?);
    eval { $_->disconnect } for grep { defined } @storages;
    eval { $other->do($NT->drop_table_sql) };
  }
}

local $SIG{ALRM} = sub { die "t/80 timed out: a Future never settled\n" };
alarm 120;

sub send_notify {
  my ($channel, $payload) = @_;
  my ($sql, $bind) = $NT->notify_sql($channel, $payload);
  $other->do($sql, undef, @$bind);
}
# The server sessions this test's storages opened, as far as the server still
# lists them. Every handle DBI->connect hands out from here on is a storage's
# (the test's own $other exists already), whatever pool or listen slot it ends
# up in, so a connection leaked outside both is counted as well. They are asked
# for by their ids: the process list of the user also holds the sessions of
# whoever else talks to the server at the time, and those are not ours to count.
my @opened;
{
  no warnings 'redefine';
  my $connect = \&DBI::connect;
  *DBI::connect = sub {
    my $dbh = $connect->(@_);
    push @opened, $dbh->{ $api->{thread_id} } if ref $dbh;
    return $dbh;
  };
}
sub our_sessions {
  return () unless @opened;
  return @{ $other->selectcol_arrayref(
    'SELECT ID FROM information_schema.PROCESSLIST WHERE ID IN (' . join(',', ('?') x @opened) . ') ORDER BY ID',
    undef, @opened,
  ) };
}
sub session_gone { my ($id) = @_; !grep { $_ == $id } our_sessions() }

my (@reports, @warnings, $reconnects);
local $SIG{__WARN__} = sub { push @warnings, @_ };

# A storage on the future_io transport whose connect info a broker answers,
# with a pool connection held and the listen connection up and delivering.
sub listening {
  my ($label, $channel, $got) = @_;
  my $schema = K71Live::Schema->connect(
    K71Live::Broker->new($dsn, $user, $pass, {}),
    { async => 'future_io', pool_size => 2 },
  );
  my $async = $schema->storage->async;
  push @storages, $async;
  $async->notify_table($T);
  $async->notify_poll_interval(0.1);
  $async->listen_backoff_initial(0.1);
  $async->listen_backoff_max(0.2);
  $async->on_listen_error(sub { push @reports, "$_[1]" });
  $async->on_listen_reconnect(sub { $reconnects++ });

  ok $async->access_broker && $async->_conninfo_provider, "$label: the broker is attached, with its provider";
  $async->deploy_notify_table->get;
  my $held = $async->pool->acquire->get;   # kept out, so that the next borrow has to spawn
  $async->listen($channel => sub { push @$got, [@_] })->get;

  send_notify($channel, 'before the detach');
  ok wait_until(sub { @$got }), "$label: pool and listen connection are up, and a notification is delivered";
  @$got = ();
  return ($schema, $async, $held);
}

sub listen_dbh { my $l = $_[0]{_listen}; $l && $l->{conn} && $l->{conn}{dbh} }
sub listen_session { my $dbh = listen_dbh($_[0]) or return undef; $dbh->{ $api->{thread_id} } }
sub refusals { my ($re) = @_; scalar grep { $_ =~ $re } @reports }

# ---------------------------------------------------------------------------
# 1 + 2. The detach, and every way a connection would be opened after it.
# ---------------------------------------------------------------------------
{
  my @got;
  my ($schema, $async, $held) = listening('detach', "k71_${$}_a", \@got);
  my $NO_BROKER = qr/\Q${\ ref $async }\E has no AccessBroker attached to ask for connect info/;

  my $listen = listen_session($async);
  my %before = map { $_ => 1 } our_sessions();
  ok $listen && $before{$listen}, 'detach: the listen connection is a session the server lists';

  @reports = @warnings = ();
  $reconnects = 0;
  $async->clear_access_broker;
  ok !$async->access_broker, 'detach: the broker is detached';

  # 1. nothing happens to what is up
  send_notify("k71_${$}_a", 'after the detach');
  ok wait_until(sub { @got }), 'detach: the listen connection goes on delivering';
  is $got[0] && $got[0][1], 'after the detach', '... the notification sent after the detach';
  is listen_session($async), $listen, '... on the same server session as before';
  ok $async->listen_alive, '... which listen_alive confirms';
  is $reconnects, 0, '... without a reconnect';
  is_deeply \@reports, [], '... and without an error reported';
  is_deeply [ our_sessions() ], [ sort { $a <=> $b } keys %before ], '... the sessions on the server are the ones from before';

  # 2. nothing is opened any more
  my $spawn = $async->pool->acquire;
  wait_until(sub { $spawn->is_ready }, 5);
  ok $spawn->is_ready && $spawn->is_failed, 'detach: a pool spawn fails';
  like scalar($spawn->failure), $NO_BROKER, '... saying that no broker is attached';

  ok !eval { $async->_listen_open; 1 }, 'detach: _listen_open dies';
  like "$@", $NO_BROKER, '... saying the same';
  is listen_session($async), $listen, '... and the listen connection that is up is still the same';

  my $rebuild = $async->listen_reconnect;
  wait_until(sub { $rebuild->is_ready }, 5);
  ok $rebuild->is_ready && $rebuild->is_failed, 'detach: listen_reconnect() fails its Future';
  like scalar($rebuild->failure), qr/opening the listen connection failed: .*$NO_BROKER/s,
    '... the open having been refused for want of a broker';
  ok refusals($NO_BROKER), '... which on_listen_error is told as well';
  ok wait_until(sub { session_gone($listen) }, 5), '... the listen connection that was up is closed by the rebuild';
  ok !$async->listen_alive, '... and none has taken its place';

  my $told = refusals($NO_BROKER);
  ok wait_until(sub { refusals($NO_BROKER) >= $told + 3 }, 10),
    'detach: core retries the open with backoff, and each retry is refused the same way';
  is_deeply [ grep { !$before{$_} } our_sessions() ], [],
    '... no session of ours has appeared on the server: nothing was opened';
  ok !$async->listen_alive, '... and there is still no listen connection';

  $async->pool->release($held);
  $async->disconnect;
}

# ---------------------------------------------------------------------------
# 3. Healing: the listen connection dies after the detach.
# ---------------------------------------------------------------------------
{
  my @got;
  my ($schema, $async, $held) = listening('healing', "k71_${$}_b", \@got);
  my $NO_BROKER = qr/\Q${\ ref $async }\E has no AccessBroker attached to ask for connect info/;

  my $listen = listen_session($async);
  @reports = @warnings = ();
  $reconnects = 0;
  $async->clear_access_broker;
  my %before = map { $_ => 1 } our_sessions();

  $other->do('KILL ' . int $listen);
  ok wait_until(sub { refusals($NO_BROKER) >= 3 }, 10),
    'healing: with the broker detached and the listen connection killed, on_listen_error '
    . 'hears that no broker is attached -- at every retry';
  unlike $reports[0], $NO_BROKER, '... after hearing why the connection was lost'
    or diag "first report: $reports[0]";
  ok session_gone($listen), '... the killed session is gone';
  is_deeply [ grep { !$before{$_} } our_sessions() ], [], '... and none is opened in its place';
  ok !$async->listen_alive, '... listen_alive says so';
  is $reconnects, 0, '... and on_listen_reconnect never fired';

  $async->pool->release($held);
  $async->disconnect;
}

# 4. A password too short to search for, or one that is part of the DSN or the
#    user name, says nothing either way.
SKIP: {
  skip 'the test account\'s password is too short, or part of the DSN or user name, to be looked for', 1
    unless defined $pass && length $pass >= 6 && index("$dsn $user", $pass) < 0;
  unlike join(' ', @reports, @warnings), qr/\Q$pass\E/, 'no report or warning names the password';
}
is_deeply [ grep { !/AccessBroker attached/ } @warnings ], [], 'nothing was warned beside the refusals'
  or diag join '', @warnings;

alarm 0;
$other->do($NT->drop_table_sql);
$other->disconnect;
undef $other;

done_testing;
