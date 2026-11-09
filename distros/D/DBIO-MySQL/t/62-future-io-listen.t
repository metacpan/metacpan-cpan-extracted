use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr weaken );
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
use Time::HiRes ();
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeNotifyServer;

# OFFLINE test of the emulated LISTEN/NOTIFY on the future_io transport (karr
# k54; core ADR 0056, dbio-async ADR 0005, this dist's ADR 0008). Core owns the
# machinery -- registry, dedicated connection, healing, fork guard -- and
# dbio-async owns the Future::IO watch loop in its timer mode; both run FOR REAL
# here, driven through the public listen / unlisten / notify / listen_alive /
# listen_reconnect. What this file pins is the half this dist supplies: the
# dedicated connection, the mark taken on it before listen resolves, the poll
# as a non-blocking query, the serialisation of statements on the one
# connection, the probe that does not ping over a statement in flight, the
# notify INSERT with binds only, the cleanup, and the capability declaration.
#
# THE ONE SUBSTITUTION is the DBD: DBI->connect hands out FakeMy::DBH handles
# over a real socketpair, and their statements are answered by
# t/lib/FakeNotifyServer.pm, an in-memory model of the notify table. The fake
# enforces what both real DBDs enforce (measured against MySQL 8.0.30 with
# DBD::mysql 4.055 and DBD::MariaDB 1.24): a second statement or a ping while an
# asynchronous one is in flight dies with "Calling a synchronous function on an
# asynchronous handle", and releasing an in-flight statement handle on a live
# connection waits for its result. The loop is Future::IO's built-in
# implementation.

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
    unless DBIO::Storage::Async->can('listen_alive');
  plan skip_all => 'the installed DBIO core predates _listen_error for non-fatal listen errors (core k227)'
    unless DBIO::Storage::Async->can('_listen_error');
  plan skip_all => 'the installed dbio-async predates its Future::IO listen seams (dbio-async k22)'
    unless defined &DBIO::Async::Storage::_listen_drain
        && defined &DBIO::Async::Storage::_listen_watch;
}

use Future;
use Future::IO;

plan skip_all => "Future::IO is bound to $Future::IO::IMPL; this test drives the built-in implementation"
  if defined $Future::IO::IMPL && $Future::IO::IMPL ne 'Future::IO::_DefaultImpl';

# --- the fake DBD ---------------------------------------------------------------

our ($SERVER, @CONNECTS);
my $next_thread = 100;

{
  package FakeMy::DBH;

  sub new {
    my ($class, %args) = @_;
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    $client->blocking(0);
    $server->autoflush(1);
    return bless {
      %args,
      client     => $client,
      server     => $server,
      thread_id  => ++$next_thread,
      Active     => 1,
      Warn       => 1,
      pings      => 0,
      in_flight  => undef,
      violations => [],
    }, $class;
  }

  # What both DBDs do to a synchronous call over an asynchronous statement.
  sub _sync_guard {
    my ($self, $what) = @_;
    return unless $self->{in_flight};
    push @{ $self->{violations} }, $what;
    die "DBD::mysql::db $what failed: Calling a synchronous function on an asynchronous handle\n";
  }

  sub prepare {
    my ($self, $sql, $attrs) = @_;
    $self->_sync_guard('prepare');
    die "DBD::mysql::db prepare failed: MySQL server has gone away\n" if $self->{dead};
    die "fake: a statement prepared without the async attribute: $sql\n"
      unless $attrs && ($attrs->{async} || $attrs->{mariadb_async});
    return bless { dbh => $self, sql => $sql }, 'FakeMy::STH';
  }

  sub ping {
    my ($self) = @_;
    $self->_sync_guard('ping');
    return 0 if $self->{dead};
    $self->{pings}++;
    return 1;
  }

  sub do { 1 }   # the session statement of every connection (karr k121)

  sub disconnect {
    my ($self) = @_;
    $self->{disconnected_in_flight}++ if $self->{in_flight};
    $self->{Active} = 0;
    $self->{disconnected}++;
    return 1;
  }

  sub mysql_fd       { fileno $_[0]{client} }
  sub mariadb_sockfd { fileno $_[0]{client} }

  # Every DBI handle answers err, and the transport reads it for each failed
  # statement (_conn_error_is_fatal, karr k65). The failures of this file carry
  # a message and no number, so it finds none and keeps the connection, as
  # before k65; what a number does to a connection is t/68's.
  sub err { $_[0]{err} }

  sub _readable { syswrite $_[0]{server}, 'R'; return }

  # The server ends the connection (KILL, a restart): a statement in flight
  # fails, every later one finds the server gone.
  sub kill {
    my ($self) = @_;
    $self->{dead} = 1;
    $self->{hold} = 0;
    if (my $sth = $self->{in_flight}) {
      $sth->{result} = { error => "Lost connection to MySQL server during query\n" };
      $self->_readable;
    }
    return;
  }

  # Hold the next result on the wire until release().
  sub hold    { $_[0]{hold} = 1; return }
  sub release {
    my ($self) = @_;
    $self->{hold} = 0;
    $self->_readable if delete $self->{held};
    return;
  }
}

{
  package FakeMy::STH;

  sub execute {
    my ($self, @bind) = @_;
    my $dbh = $self->{dbh};
    die "DBD::mysql::st execute failed: MySQL server has gone away\n" if $dbh->{dead};
    my $r = eval { $main::SERVER->answer($self->{sql}, \@bind, $dbh->{thread_id}) };
    $self->{result}           = $r || { error => $@ };
    $self->{NUM_OF_FIELDS}    = $self->{result}{fields} // 0;
    $self->{mysql_insertid}   = $self->{result}{insertid} // 0;
    $self->{mariadb_insertid} = $self->{mysql_insertid};
    # Weak: the DBD tracks its in-flight statement in C, not as a Perl
    # reference, so releasing the last Perl reference really releases it.
    $dbh->{in_flight} = $self;
    Scalar::Util::weaken($dbh->{in_flight});
    if ($dbh->{hold}) { $dbh->{held} = 1 } else { $dbh->_readable }
    return '0E0';
  }

  sub _ready {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    return 0 if $dbh->{held};
    my $rin = '';
    vec($rin, fileno $dbh->{client}, 1) = 1;
    return 0 unless select($rin, undef, undef, 0) > 0;
    sysread $dbh->{client}, my $byte, 1;
    return 1;
  }

  sub _result {
    my ($self) = @_;
    my $dbh = $self->{dbh};
    undef $dbh->{in_flight} if $dbh->{in_flight} && $dbh->{in_flight} == $self;
    my $r = $self->{result};
    die "DBD::mysql::st execute failed: $r->{error}" if defined $r->{error};
    return $r->{rv} // '0E0';
  }

  sub mysql_async_ready    { $_[0]->_ready }
  sub mariadb_async_ready  { $_[0]->_ready }
  sub more_results { 0 }   # one result set (karr k73)
  sub mysql_async_result   { $_[0]->_result }
  sub mariadb_async_result { $_[0]->_result }

  sub fetchall_arrayref { [ map { [@$_] } @{ $_[0]{result}{rows} || [] } ] }

  # Releasing an in-flight statement handle on a live connection blocks in
  # the real DBDs until the result arrives -- record it as a violation.
  sub DESTROY {
    my ($self) = @_;
    my $dbh = $self->{dbh} or return;
    push @{ $dbh->{violations} }, 'an in-flight statement handle released on a live connection'
      if $dbh->{in_flight} && $dbh->{in_flight} == $self && $dbh->{Active};
    return;
  }
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    # Which seam opened it. Pool and listen connections are both opened
    # fork-safe (karr k55), so their attributes no longer tell them apart.
    my $listen = 0;
    for (my $i = 1; my @frame = caller $i; $i++) {
      next unless $frame[3] =~ /::_listen_open\z/;
      $listen = 1;
      last;
    }
    # The handle belongs to the DBD the DSN names, and says so as a DBI handle
    # does: the transport picks the async binding by it (karr k60).
    my ($driver) = $dsn =~ /^dbi:(\w*)/i;
    my $dbh = FakeMy::DBH->new(
      dsn => $dsn, user => $user, password => $password, attrs => { %$attrs },
      Driver => { Name => $driver },
    );
    push @CONNECTS, {
      dsn => $dsn, user => $user, password => $password, attrs => { %$attrs }, dbh => $dbh,
      listen => $listen, thread_id => $dbh->{thread_id},
    };
    weaken($CONNECTS[-1]{dbh});
    return $dbh;
  };
}

# A broker handing out storage-native connect info for whatever credential
# generation the test sets.
{
  package RotatingBroker;
  use base 'DBIO::AccessBroker';

  sub connect_info_for_storage {
    my ($self) = @_;
    my $gen = $self->{gen};
    return {
      dsn      => 'dbi:mysql:database=listen_test',
      user     => "user-$gen",
      password => "pw-$gen",
      attrs    => { mysql_enable_utf8mb4 => 1 },
    };
  }
}

# --- helpers --------------------------------------------------------------------

sub fresh {
  my (%args) = @_;
  $SERVER = $args{server} || FakeNotifyServer->new;
  my $class = $args{class} || 'DBIO::MySQL::Storage::Async';
  my $s = $class->new(undef);
  $s->connect_info($args{info}
    || [ 'dbi:mysql:database=listen_test', 'u', 'secret-listen-pw', { mysql_enable_utf8mb4 => 1, pool_size => 1 } ]);
  $s->{spy} = { errors => [], reconnects => 0 };
  $s->on_listen_error(sub { push @{ $_[0]{spy}{errors} }, $_[1] });
  $s->on_listen_reconnect(sub { $_[0]{spy}{reconnects}++ });
  $s->listen_backoff_initial(0.01);
  $s->listen_backoff_max(0.01);
  $s->notify_poll_interval(0.01);
  @CONNECTS = ();
  return $s;
}

sub listen_conn     { $_[0]{_listen} && $_[0]{_listen}{conn} }
sub listen_dbh      { my $c = listen_conn($_[0]); $c && $c->{dbh} }
sub listen_connects { grep { $_->{listen} } @CONNECTS }
sub pool_connects   { grep { !$_->{listen} } @CONNECTS }

# Run the loop until $cond holds, bounded -- never an open-ended wait.
sub drive {
  my ($cond, $max) = @_;
  my $deadline = Time::HiRes::time() + ($max // 3);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    Future::IO->sleep(0.002)->get;
  }
  return 1;
}

sub settle { Future::IO->sleep($_[0] // 0.05)->get; return }

sub polls_on {
  my ($dbh) = @_;
  return scalar $SERVER->statements(qr/\ASELECT `id`, `channel`/) unless $dbh;
  return scalar grep { $_->{pid} == $dbh->{thread_id} } $SERVER->statements(qr/\ASELECT `id`, `channel`/);
}

# The watch loop is running once a poll has run on the listen connection.
sub watching {
  my ($s) = @_;
  my $seen = polls_on(listen_dbh($s));
  return drive(sub { polls_on(listen_dbh($s)) > $seen });
}

my $SNAPSHOT = qr/\ASELECT `id`, NULL, NULL, NULL, NULL FROM/;

# ---------------------------------------------------------------------------
# 0. This dist supplies the MySQL seams and nothing else. The public methods
#    and the machinery are core's; the watch loop, timer and pooled notify are
#    dbio-async's -- overriding any of them here would fork the contract ADR
#    0056 exists to keep single. And the MariaDB convention class inherits the
#    whole emulation: which DBD's names a connection is driven with is that
#    connection's matter, not the class's (karr k60). Code-ref identity is the
#    only probe that tells inherited from overridden.
# ---------------------------------------------------------------------------

{
  my $MY = 'DBIO::MySQL::Storage::Async';
  my $MA = 'DBIO::MySQL::Storage::MariaDB::Async';
  for my $m (qw( listen unlisten notify listen_alive listen_reconnect
                 _listen_dispatch _listen_lost _listen_error )) {
    is refaddr($MY->can($m)), refaddr(DBIO::Storage::Async->can($m)),
      "$m is core's, not overridden by the MySQL transport";
  }
  for my $m (qw( _listen_watch _listen_unwatch _listen_delay _notify_send
                 _query_async _query_async_pinned )) {
    is refaddr($MY->can($m)), refaddr(DBIO::Async::Storage->can($m)),
      "$m is dbio-async's, not overridden by the MySQL transport";
  }
  for my $m (qw( _listen_open _listen_close _listen_subscribe _listen_unsubscribe
                 _listen_drain _listen_probe _listen_poll_interval _notify_sql
                 transport_capabilities )) {
    isnt refaddr($MY->can($m)), refaddr(DBIO::Async::Storage->can($m)),
      "$m is supplied by the MySQL transport";
    is refaddr($MA->can($m)), refaddr($MY->can($m)), "... and inherited unchanged by the MariaDB one";
  }
}

# ---------------------------------------------------------------------------
# 1. Capabilities. Core gates listen/unlisten/listen_alive/listen_reconnect on
#    'listen' and notify on 'notify' (ADR 0056 section 2), and allows an
#    emulation to declare them (section 6). copy and pipeline stay undeclared.
#    The one DBD-specific piece of the emulation is the auto-reconnect
#    attribute the listen connection switches off. It is named for the DBD of
#    the DSN being connected, on either class: until karr k60 each class
#    answered one fixed name, which was the wrong one whenever the schema
#    component had pinned the class for the other DBD's DSN.
# ---------------------------------------------------------------------------

for my $class (qw( DBIO::MySQL::Storage::Async DBIO::MySQL::Storage::MariaDB::Async )) {
  my @caps = $class->transport_capabilities;
  # broker_connect_options: the connect options beside an AccessBroker reach
  # every connection of this transport (karr k64, t/67-*.t proves the promise).
  is_deeply [ sort @caps ],
    [ sort DBIO::Async::Storage->transport_capabilities, qw(listen notify broker_connect_options) ],
    "$class: exactly the inherited list plus listen, notify and broker_connect_options";
  ok !(grep { $_ eq 'copy' || $_ eq 'pipeline' } @caps), '... not copy, not pipeline';

  is($class->_mysql_auto_reconnect_attr('dbi:mysql:database=listen_test'), 'mysql_auto_reconnect',
    "$class: a dbi:mysql: DSN is given DBD::mysql's mysql_auto_reconnect");
  is($class->_mysql_auto_reconnect_attr('dbi:MariaDB:database=listen_test'), 'mariadb_auto_reconnect',
    "$class: a dbi:MariaDB: DSN is given DBD::MariaDB's mariadb_auto_reconnect");
}

# ---------------------------------------------------------------------------
# 2. The statements, through the storage. Channel and payload only as binds;
#    an invalid table name or channel is refused before anything reaches the
#    server.
# ---------------------------------------------------------------------------

{
  my $s    = fresh();
  my $evil = q{x'); DROP TABLE t; --};
  my ($sql, $bind) = $s->_notify_sql($evil, $evil);
  is $sql, 'INSERT INTO `dbio_notify` (`channel`, `payload`, `pid`, `created_at`) '
         . 'VALUES (?, ?, CONNECTION_ID(), UTC_TIMESTAMP(6))', 'notify SQL is a fixed INSERT';
  is_deeply $bind, [ $evil, $evil ], '... channel and payload only as binds';
  is $s->_transform_sql($sql), $sql, '... sent with its ? placeholders unchanged';

  $s->notify_table('bad name');
  my $f = $s->notify(jobs => 'x');
  ok drive(sub { $f->is_ready }), 'notify with an invalid table name settles';
  like scalar $f->failure, qr/not a plain identifier/, '... failed, naming the table name';
  $f = $s->listen(jobs => sub {});
  ok drive(sub { @{ $s->{spy}{errors} } }), 'listen with an invalid table name reports';
  like $s->{spy}{errors}[0], qr/not a plain identifier/, '... why';
  is scalar(@CONNECTS), 0, '... and nothing connected: validated before the connection opens';
  $s->unlisten('jobs')->get;
  is_deeply [ $SERVER->statements ], [], 'no statement reached the server';
}

# ---------------------------------------------------------------------------
# 3. listen end to end: one dedicated connection outside the pool, opened
#    fork-safe with auto-reconnect off; the mark taken ON it before listen
#    resolves; no history; delivery in contract order; several channels on the
#    one connection; unlisten; the last unlisten closes it.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $SERVER->insert(jobs => "history$_") for 1 .. 3;
  my @got;
  my $f = $s->listen(jobs => sub { push @got, [ jobs => @_ ] });
  $f->get;
  ok $f->is_done, 'listen resolved';

  is scalar(@CONNECTS), 1, 'exactly one connection was opened';
  is scalar(pool_connects()), 0, '... and it is not a pool connection -- the pool was never touched';
  my ($c) = @CONNECTS;
  is $c->{dsn}, 'dbi:mysql:database=listen_test', '... on the storage\'s DSN';
  is $c->{user}, 'u', '... with its credentials';
  is $c->{attrs}{AutoInactiveDestroy}, 1, '... AutoInactiveDestroy => 1 at connect time (fork safety)';
  is $c->{attrs}{mysql_auto_reconnect}, 0,
    '... mysql_auto_reconnect => 0 (DBD::mysql turns it on under mod_perl/CGI)';
  is $c->{attrs}{RaiseError}, 1, '... RaiseError => 1 (a dead connection must fail the poll)';
  is $c->{attrs}{AutoCommit}, 1, '... AutoCommit => 1 (every poll sees what committed since)';
  is $c->{attrs}{mysql_enable_utf8mb4}, 1, '... the caller\'s DBD attributes passed through';
  ok !exists $c->{attrs}{pool_size}, '... pool_size is not a DBD attribute and is not passed';

  my $dbh = listen_dbh($s);
  my @snap = $SERVER->statements($SNAPSHOT);
  is scalar(@snap), 1, 'one mark was taken';
  is $snap[0]{pid}, $dbh->{thread_id}, '... on the listen connection itself';
  is_deeply $snap[0]{bind}, [ 'jobs', 'jobs' ], '... with the channel bound';

  ok watching($s), 'the listen connection is polled';
  settle(0.05);
  is_deeply \@got, [], 'nothing committed before listen is delivered (no history)';

  $SERVER->insert(jobs => "p$_", pid => 4240 + $_) for 1 .. 3;
  ok drive(sub { @got == 3 }), 'three notifications delivered';
  is_deeply \@got,
    [ [ jobs => 'jobs', 'p1', 4241 ], [ jobs => 'jobs', 'p2', 4242 ], [ jobs => 'jobs', 'p3', 4243 ] ],
    'in order, as ($channel, $payload, $sender_pid)';

  $s->listen(alerts => sub { push @got, [ alerts => @_ ] })->get;
  is scalar(@CONNECTS), 1, 'a second channel shares the listen connection';

  @got = ();
  $SERVER->insert(alerts => 'a1', pid => 7);
  $SERVER->insert(jobs   => 'j1', pid => 7);
  $SERVER->insert(alerts => 'a2', pid => 7);
  ok drive(sub { @got == 3 }), 'interleaved notifications on two channels';
  is_deeply \@got,
    [ [ alerts => 'alerts', 'a1', 7 ], [ jobs => 'jobs', 'j1', 7 ], [ alerts => 'alerts', 'a2', 7 ] ],
    'each went to its own channel\'s callback, in order';

  $s->unlisten('alerts')->get;
  @got = ();
  $SERVER->insert(alerts => 'late', pid => 7);
  $SERVER->insert(jobs   => 'after', pid => 7);
  ok drive(sub { @got }), 'the remaining channel still delivers';
  settle(0.05);
  is_deeply \@got, [ [ jobs => 'jobs', 'after', 7 ] ], '... and the unlistened channel is not delivered';
  is_deeply $s->{spy}{errors}, [], 'no listen errors along the way';
  is_deeply $dbh->{violations}, [], 'no statement ever collided with one in flight';

  $s->unlisten('jobs')->get;
  ok $dbh->{disconnected}, 'the last unlisten closed the listen connection';
}

# ---------------------------------------------------------------------------
# 4. The mark is in effect when listen's Future resolves: listen(...)->get;
#    notify(...)->get must deliver -- a mark taken lazily at the next poll
#    would swallow that notification as history. notify runs on a pooled
#    connection; an undef payload arrives as ''; channels are exact.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  $s->listen(Jobs => sub { push @got, [@_] })->get;
  my $f = $s->notify(Jobs => 'hello');
  $f->get;
  ok $f->is_done, 'notify resolved';
  is scalar(pool_connects()), 1, '... on a pool connection, not the listen one';
  my ($ins) = $SERVER->statements(qr/\AINSERT/);
  is_deeply $ins->{bind}, [ 'Jobs', 'hello' ], '... channel and payload bound';

  ok drive(sub { @got }), 'a notify right after listen resolved is delivered';
  is_deeply $got[0], [ 'Jobs', 'hello', (pool_connects())[0]{thread_id} ],
    '... with the pooled session\'s CONNECTION_ID() as the sender';

  @got = ();
  $s->notify('Jobs')->get;
  ok drive(sub { @got }), 'notify without a payload';
  is $got[0][1], '', '... arrives with the empty payload';

  @got = ();
  $s->notify(jobs => 'lower')->get;
  settle(0.05);
  is_deeply \@got, [], 'a notify on "jobs" does not reach a listen on "Jobs"';
  $s->unlisten('Jobs')->get;
}

# ---------------------------------------------------------------------------
# 5. The out-of-order commit through the whole machinery: A takes the lower
#    id, B commits first and is delivered, A commits later -- A is delivered,
#    each exactly once.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  $s->listen(jobs => sub { push @got, $_[1] })->get;
  ok watching($s), 'polling';

  my $id_a = $SERVER->insert(jobs => 'A', visible => 0);
  my $id_b = $SERVER->insert(jobs => 'B', visible => 0);
  $SERVER->commit($id_b);
  ok drive(sub { @got }), 'B, committed first, is delivered';
  $SERVER->advance(2);
  $SERVER->commit($id_a);
  ok drive(sub { @got == 2 }), 'A, the lower id, is delivered when it commits';
  settle(0.1);
  is_deeply \@got, [ 'B', 'A' ], 'each exactly once, over many polls';
  $s->unlisten('jobs')->get;
}

# ---------------------------------------------------------------------------
# 6. One statement at a time on the listen connection. Both DBDs die on a
#    ping or a second statement while an asynchronous one is in flight. A
#    watchdog's listen_alive during a poll in flight must not ping -- the DBD
#    would die and core would take that for a death and reconnect -- and a
#    listen for a second channel during it must wait for the poll, not collide
#    with it.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  $s->listen(jobs => sub { push @got, [@_] })->get;
  my $dbh = listen_dbh($s);
  ok watching($s), 'polling';

  $dbh->hold;
  ok drive(sub { $dbh->{held} }), 'a poll is in flight, its result held on the wire';
  my $pings = $dbh->{pings};
  ok $s->listen_alive, 'listen_alive during the poll in flight: alive';
  is $dbh->{pings}, $pings, '... answered without a ping';

  my $f = $s->listen(alerts => sub { push @got, [@_] });
  settle(0.03);
  ok !$f->is_ready, 'a listen during the poll in flight waits for it';
  is scalar(grep { $_->{pid} == $dbh->{thread_id} } $SERVER->statements($SNAPSHOT)), 1,
    '... its mark not yet taken';

  $dbh->release;
  ok drive(sub { $f->is_ready }), 'released: the listen completes';
  ok $f->is_done, '... successfully';
  is_deeply $dbh->{violations}, [], 'nothing ever ran over the statement in flight';
  is $s->{spy}{reconnects}, 0, 'no spurious reconnect';
  is_deeply $s->{spy}{errors}, [], 'no listen error';

  $SERVER->insert(alerts => 'a', pid => 9);
  ok drive(sub { @got }), 'the channel subscribed during the poll delivers';

  ok $s->listen_alive, 'listen_alive with nothing in flight';
  is $dbh->{pings}, $pings + 1, '... pings';
  $s->unlisten($_)->get for qw(jobs alerts);
}

# ---------------------------------------------------------------------------
# 7. A dead poll heals: the killed connection fails the poll, core closes it
#    and reconnects -- through the broker path a pool spawn uses, so rotated
#    credentials apply -- takes the mark of EVERY registered channel again on
#    the new connection, and fires on_listen_reconnect. listen_reconnect does
#    the same on demand.
# ---------------------------------------------------------------------------

{
  my $broker = RotatingBroker->new;
  $broker->{gen} = 'A';
  my $s = fresh(info => [$broker]);
  my (@jobs, @alerts);
  $s->listen(jobs   => sub { push @jobs,   [@_] })->get;
  $s->listen(alerts => sub { push @alerts, [@_] })->get;

  my @l = listen_connects();
  is scalar(@l), 1, 'one listen connection';
  is $l[0]{user}, 'user-A', '... opened with the broker\'s current credentials';
  my $old = listen_dbh($s);
  ok watching($s), 'polling';

  $broker->{gen} = 'B';
  $old->kill;
  ok drive(sub { $s->{spy}{reconnects} }), 'the dead connection was rebuilt';
  like join("\n", @{ $s->{spy}{errors} }), qr/Lost connection to MySQL server|gone away/,
    'on_listen_error heard why: the poll failed';
  ok $old->{disconnected}, 'the dead handle was closed';
  @l = listen_connects();
  is scalar(@l), 2, 'a second listen connection was opened';
  is $l[1]{user}, 'user-B', '... with the ROTATED credentials';
  is $l[1]{attrs}{AutoInactiveDestroy}, 1, '... fork-safe again';

  my $new = listen_dbh($s);
  is_deeply [ sort map { $_->{bind}[0] } grep { $_->{pid} == $new->{thread_id} } $SERVER->statements($SNAPSHOT) ],
    [ 'alerts', 'jobs' ], 'the mark of EVERY registered channel was taken again on it';
  ok $s->listen_alive, 'listen_alive is true again';

  $SERVER->insert(jobs => 'j', pid => 31);
  $SERVER->insert(alerts => 'a', pid => 32);
  ok drive(sub { @jobs && @alerts }), 'both channels deliver on the new connection';
  is_deeply [ $jobs[-1], $alerts[-1] ], [ [ 'jobs', 'j', 31 ], [ 'alerts', 'a', 32 ] ],
    '... each to its own callback';

  $broker->{gen} = 'C';
  $s->listen_reconnect->get;
  is $s->{spy}{reconnects}, 2, 'listen_reconnect rebuilt the connection and fired the hook';
  ok $new->{disconnected}, '... closing the one it replaced';
  is listen_dbh($s)->{user}, 'user-C', '... reconnecting with the credentials current now';
  $s->unlisten($_)->get for qw(jobs alerts);
}

# ---------------------------------------------------------------------------
# 8. No table, no silent DDL. The table is never created implicitly: a listen
#    against a missing table fails its Future with a message that names the
#    table and how to deploy it -- a refusal on a live connection, so core does
#    not reconnect in a loop. deploy_notify_table creates it on a pooled
#    connection, and then listen works.
# ---------------------------------------------------------------------------

{
  my $s = fresh(server => FakeNotifyServer->new(exists => 0));
  my $f = $s->listen(jobs => sub {});
  ok drive(sub { $f->is_ready }), 'listen against a missing table settles';
  like scalar $f->failure, qr/the notify table `dbio_notify` does not exist.*deploy_notify_table/s,
    '... failed, naming the table and deploy_notify_table';
  is $s->{spy}{reconnects}, 0, '... without reconnecting';
  is scalar(listen_connects()), 1, '... on the one connection it opened';
  ok !listen_conn($s), '... which is closed again: no channel is left';
  is_deeply [ $SERVER->statements(qr/\ACREATE/) ], [], 'nothing created the table';

  $s->deploy_notify_table->get;
  my ($ddl) = $SERVER->statements(qr/\ACREATE TABLE IF NOT EXISTS `dbio_notify`/);
  ok $ddl, 'deploy_notify_table ran CREATE TABLE IF NOT EXISTS';
  isnt $ddl->{pid}, undef, '... on a connection';
  ok scalar(grep { $_->{thread_id} == $ddl->{pid} } pool_connects()), '... a pooled one';

  my @got;
  $s->listen(jobs => sub { push @got, $_[1] })->get;
  $SERVER->insert(jobs => 'now');
  ok drive(sub { @got }), 'after deploy, listen works';
  $s->unlisten('jobs')->get;
}

# ---------------------------------------------------------------------------
# 9. Retention. The listen connection deletes old rows -- due on its first
#    poll, bounded by LIMIT, on its own connection after the poll. A cleanup
#    the account may not run is reported, not fatal: listening goes on, and it
#    is not retried on every poll.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $SERVER->insert(old => $_, at => $SERVER->now - 7200) for 1 .. 3;
  my @got;
  $s->listen(jobs => sub { push @got, $_[1] })->get;
  my $dbh = listen_dbh($s);
  ok drive(sub { $SERVER->statements(qr/\ADELETE/) }), 'a cleanup ran';
  my ($del) = $SERVER->statements(qr/\ADELETE/);
  is $del->{sql},
    'DELETE FROM `dbio_notify` WHERE `created_at` < UTC_TIMESTAMP(6) - INTERVAL 3600000000 MICROSECOND LIMIT 1000',
    '... rows older than the one-hour retention, 1000 at most';
  is $del->{pid}, $dbh->{thread_id}, '... on the listen connection';
  ok drive(sub { !grep { $_->{channel} eq 'old' } @{ $SERVER->{rows} } }), 'the old rows are gone';
  $s->unlisten('jobs')->get;

  # The report goes through core's _listen_error (core k227), the seam for an
  # error that leaves the connection up -- so core's rules for it apply, its
  # fork guard included, not a copy of them kept here.
  my @seam;
  my $core_listen_error = \&DBIO::Storage::Async::_listen_error;
  local *DBIO::Storage::Async::_listen_error = sub { push @seam, $_[1]; goto &$core_listen_error };

  my $denied = FakeNotifyServer->new;
  $denied->{deny_delete} = 1;
  $s = fresh(server => $denied);
  @got = ();
  $s->listen(jobs => sub { push @got, $_[1] })->get;
  $dbh = listen_dbh($s);
  ok drive(sub { @{ $s->{spy}{errors} } }), 'a denied cleanup is reported';
  like $s->{spy}{errors}[0], qr/cleaning up the notify table `dbio_notify` failed: .*DELETE command denied/,
    '... through on_listen_error, with the server\'s reason';
  is scalar(@seam), 1, '... handed to core\'s _listen_error';
  like $seam[0], qr/cleaning up the notify table `dbio_notify` failed/, '... that very error';
  $SERVER->insert(jobs => 'still');
  ok drive(sub { @got }), 'listening goes on';
  settle(0.1);
  is scalar($SERVER->statements(qr/\ADELETE/)), 1, 'the cleanup is not retried on every poll';
  is $s->{spy}{reconnects}, 0, 'and it did not cost the connection';
  is refaddr(listen_dbh($s)), refaddr($dbh), '... which is the one it opened';
  ok $s->listen_alive, '... and alive';
  $s->unlisten('jobs')->get;
}

# ---------------------------------------------------------------------------
# 10. Unlistening the last channel while a poll is in flight stops the watch,
#     which cancels the poll, and closes the connection -- disconnecting BEFORE
#     the abandoned statement handle is released, because releasing it on a
#     live connection would wait for its result.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $s->listen(jobs => sub {})->get;
  my $dbh = listen_dbh($s);
  ok watching($s), 'polling';
  $dbh->hold;
  ok drive(sub { $dbh->{held} }), 'a poll is in flight';
  $s->unlisten('jobs')->get;
  ok $dbh->{disconnected}, 'the last unlisten closed the connection';
  is $dbh->{disconnected_in_flight}, 1, '... with the poll still in flight';
  settle(0.05);
  is_deeply $dbh->{violations}, [], '... and no in-flight statement handle was released on the live connection';
  is_deeply $s->{spy}{errors}, [], 'no listen error';
}

# ---------------------------------------------------------------------------
# 11. A dbi:MariaDB: connection: the same emulation over DBD::MariaDB's
#     mariadb_* binding, with mariadb_auto_reconnect switched off.
# ---------------------------------------------------------------------------

{
  my $s = fresh(
    class => 'DBIO::MySQL::Storage::MariaDB::Async',
    info  => [ 'dbi:MariaDB:database=listen_test', 'u', 'secret-listen-pw', { pool_size => 1 } ],
  );
  my @got;
  $s->listen(jobs => sub { push @got, [@_] })->get;
  my ($c) = listen_connects();
  is $c->{attrs}{mariadb_auto_reconnect}, 0, 'MariaDB: mariadb_auto_reconnect => 0 on the listen connection';
  ok !exists $c->{attrs}{mysql_auto_reconnect}, '... and no DBD::mysql attribute';
  $SERVER->insert(jobs => 'm', pid => 5);
  ok drive(sub { @got }), '... delivers';
  is_deeply \@got, [ [ 'jobs', 'm', 5 ] ], '... in contract order';
  $s->unlisten('jobs')->get;
}

done_testing;
