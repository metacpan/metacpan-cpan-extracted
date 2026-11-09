use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr weaken );
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );
use Fcntl qw( F_GETFL O_NONBLOCK );
use Time::HiRes ();

# OFFLINE test for the PostgreSQL LISTEN/NOTIFY seams of the future_io
# transport (karr k77; core ADR 0056, dbio-async ADR 0005). Core owns the
# machinery -- registry, dedicated connection, healing, fork guard -- and
# dbio-async owns the Future::IO watch loop; both run FOR REAL here, driven
# through the public listen / unlisten / notify / listen_alive /
# listen_reconnect. What this file pins is the PostgreSQL half this dist
# supplies: the dedicated handle, quoted LISTEN / UNLISTEN with a drain after
# each, the pg_notifies drain in contract order and without ever blocking, the
# probe, pg_notify with binds only, and the capability declaration.
#
# THE ONE SUBSTITUTION is DBD::Pg itself: DBI->connect hands out FakePg::DBH
# handles over a real socketpair. The client end is "libpq's socket"
# (pg_socket), so the transport's dup, Future::IO's poll and O_NONBLOCK are all
# real; the server end is the "backend", where the fake writes one
# "channel\tpid\tpayload\n" line per notification. FakePg routes pg_notify()
# from a pool connection to every listening connection whose LISTEN named that
# exact channel -- the way PostgreSQL matches a quoted identifier. The loop is
# Future::IO's built-in implementation: no event-loop dist needed, and it is
# the one that clears O_NONBLOCK while its callbacks run (section 5).

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
  plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
    unless DBIO::Storage::Async->can('listen_alive');
  plan skip_all => 'the installed dbio-async predates its Future::IO listen seams (dbio-async k22)'
    unless defined &DBIO::Async::Storage::_listen_drain
        && defined &DBIO::Async::Storage::_listen_watch;
}

use Future;
use Future::IO qw( POLLIN );

plan skip_all => "Future::IO is bound to $Future::IO::IMPL; this test drives the built-in implementation"
  if defined $Future::IO::IMPL && $Future::IO::IMPL ne 'Future::IO::_DefaultImpl';

sub nonblocking { (fcntl($_[0], F_GETFL, 0) & O_NONBLOCK) ? 1 : 0 }

# --- the fake PostgreSQL --------------------------------------------------------

our (@CONNECTS, @LIVE);
my $next_pid = 4000;

{
  package FakePg;

  # pg_notify: every live connection LISTENing on exactly this channel gets a
  # line on its socket. PostgreSQL has no NULL payload.
  sub route {
    my ($channel, $payload, $sender_pid) = @_;
    for my $dbh (grep { defined && !$_->{dead} && $_->{listening}{$channel} } @main::LIVE) {
      syswrite $dbh->{server}, join("\t", $channel, $sender_pid, $payload // '') . "\n";
    }
  }
}

{
  package FakePg::DBH;

  sub new {
    my ($class, %args) = @_;
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    $client->blocking(0);                  # libpq keeps its socket non-blocking
    $server->autoflush(1);
    return bless {
      %args,
      client     => $client,
      server     => $server,
      pg_socket  => fileno($client),
      pg_pid     => ++$next_pid,
      Active     => 1,
      listening  => {},
      queue      => [],                    # what libpq holds, parsed
      in_flight  => [],                    # arrives during the next round trip
      sql        => [],
      reads      => [],                    # O_NONBLOCK at every socket read
    }, $class;
  }

  sub _check {
    my ($self) = @_;
    die "DBD::Pg::db failed: connection not open\n" if $self->{dead};
    return;
  }

  # A synchronous round trip. What the backend sends meanwhile is read by
  # libpq while it waits for the reply: it lands in the queue, not on the
  # socket, and the socket never becomes readable for it.
  sub _round_trip {
    my ($self) = @_;
    push @{ $self->{queue} }, splice @{ $self->{in_flight} };
    return;
  }

  sub do {
    my ($self, $sql) = @_;
    $self->_check;
    push @{ $self->{sql} }, $sql;
    my ($verb, $ident) = $sql =~ /\A(LISTEN|UNLISTEN) "((?:[^"]|"")+)"\z/
      or die "fake: not a quoted LISTEN/UNLISTEN: $sql\n";
    (my $channel = $ident) =~ s/""/"/g;
    if ($verb eq 'LISTEN') { $self->{listening}{$channel} = 1 }
    else                   { delete $self->{listening}{$channel} }
    $self->_round_trip;
    return '0E0';
  }

  sub ping {
    my ($self) = @_;
    return 0 if $self->{dead};
    $self->{pings}++;
    $self->_round_trip;
    return 1;
  }

  # PQconsumeInput + PQnotifies: read what the socket holds without waiting,
  # then hand out one parsed notification as [ $name, $pid, $payload ]. A
  # socket found blocking is recorded as a violation and NOT read unless
  # select says there is data, so a broken guard fails an assertion instead of
  # hanging the test.
  sub pg_notifies {
    my ($self) = @_;
    $self->_check;
    my $nb = main::nonblocking($self->{client});
    push @{ $self->{reads} }, $nb;

    my $read = 1;
    unless ($nb) {
      my $rin = '';
      vec($rin, fileno $self->{client}, 1) = 1;
      $read = select($rin, undef, undef, 0) > 0;
    }
    if ($read) {
      my $n = sysread $self->{client}, my $buf, 65536;
      if (defined $n && $n == 0) {
        $self->{dead}      = 1;
        $self->{pg_socket} = -1;
        die "DBD::Pg::db pg_notifies failed: server closed the connection unexpectedly\n";
      }
      if (defined $n) {
        push @{ $self->{queue} }, map { [ split /\t/, $_, 3 ] } split /\n/, $buf;
      }
      elsif (!$!{EAGAIN} && !$!{EWOULDBLOCK}) {
        die "fake: reading the socket failed: $!\n";
      }
    }
    return shift @{ $self->{queue} };
  }

  sub err    { undef }
  sub errstr { undef }

  sub disconnect {
    my ($self) = @_;
    $self->{Active} = 0;
    $self->{disconnected}++;
    return 1;
  }

  # --- the pooled side: only notify() uses it --------------------------------

  sub prepare {
    my ($self, $sql, $attrs) = @_;
    $self->_check;
    return bless { dbh => $self, sql => $sql, NUM_OF_FIELDS => 1 }, 'FakePg::STH';
  }

  # The async result "arrives": one byte makes the socket readable, pg_ready
  # consumes it.
  sub pg_ready  { my $self = shift; sysread $self->{client}, my $byte, 1; return 1 }
  sub pg_result { 1 }
  sub state     { q{} }   # SQLSTATE, read after pg_result: none (karr k83)

  # The backend closes the connection (pg_terminate_backend, a restart).
  sub terminate { my $self = shift; close $self->{server}; return }
}

{
  package FakePg::STH;

  sub execute {
    my ($self, @bind) = @_;
    my $dbh = $self->{dbh};
    push @main::WIRE, { sql => $self->{sql}, bind => [@bind], pid => $dbh->{pg_pid} };
    FakePg::route($bind[0], $bind[1], $dbh->{pg_pid})
      if $self->{sql} eq 'SELECT pg_notify($1, $2)';
    syswrite $dbh->{server}, 'R';
    return 1;
  }

  sub fetchall_arrayref { [ [ '' ] ] }
}

our @WIRE;

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn, $user, $password, $attrs) = @_;
    # Which seam opened it. Pool and listen connections are both opened
    # fork-safe (karr k79), so their attributes no longer tell them apart.
    my $listen = 0;
    for (my $i = 1; my @frame = caller $i; $i++) {
      next unless $frame[3] =~ /::_listen_open\z/;
      $listen = 1;
      last;
    }
    my $dbh = FakePg::DBH->new(dsn => $dsn, user => $user, password => $password, attrs => { %$attrs });
    push @CONNECTS, {
      dsn => $dsn, user => $user, password => $password, attrs => { %$attrs },
      listen => $listen,
    };
    push @LIVE, $dbh;
    weaken($LIVE[-1]);
    return $dbh;
  };
}

# A broker handing out storage-native connect info (the conninfo hashref this
# transport consumes) for whatever credential generation the test sets.
{
  package RotatingBroker;
  use base 'DBIO::AccessBroker';

  sub connect_info_for_storage {
    my ($self) = @_;
    my $gen = $self->{gen};
    return {
      dsn      => 'dbi:Pg:dbname=listen_test',
      user     => "user-$gen",
      password => "pw-$gen",
      attrs    => { pg_enable_utf8 => 1 },
    };
  }
}

# The one spy: records whether the socket was blocking when a drain STARTED,
# then runs the shipped drain unchanged (section 5).
{
  package SpyAsync;
  use base 'DBIO::PostgreSQL::Storage::Async';

  # The fake wire counts what the pool sends; the reset between borrows
  # (DISCARD ALL, k154) is not what this file is about (t/195, t/196).
  sub _reset_pool_connection { $_[0]->future_class->done }

  sub _listen_drain {
    my ($self, $conn) = @_;
    push @{ $self->{spy}{drain_entry_nb} }, main::nonblocking($self->_conn_poll_fh($conn))
      if $conn->{dbh};
    return $self->SUPER::_listen_drain($conn);
  }
}

# --- helpers --------------------------------------------------------------------

sub fresh {
  my (%args) = @_;
  my $s = SpyAsync->new(undef);
  $s->connect_info($args{info}
    || [ 'dbi:Pg:dbname=listen_test', 'u', 'p', { pg_enable_utf8 => 1, pool_size => 1 } ]);
  $s->{spy} = { errors => [], reconnects => 0 };
  $s->on_listen_error(sub { push @{ $_[0]{spy}{errors} }, $_[1] });
  $s->on_listen_reconnect(sub { $_[0]{spy}{reconnects}++ });
  $s->listen_backoff_initial(0.01);
  $s->listen_backoff_max(0.01);
  @CONNECTS = ();
  @WIRE     = ();
  return $s;
}

sub listen_dbh { $_[0]{_listen} && $_[0]{_listen}{conn} && $_[0]{_listen}{conn}{dbh} }
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

# The watch loop's first drain runs one loop tick after listen() (dbio-async
# ADR 0005); only then is it waiting on the socket. Drains before it are the
# ones after LISTEN, so wait for one more than listen() left behind.
sub watching {
  my ($s) = @_;
  my $seen = @{ $s->{spy}{drain_entry_nb} || [] };
  return drive(sub { @{ $s->{spy}{drain_entry_nb} || [] } > $seen });
}

sub server_says {
  my ($dbh, @n) = @_;
  syswrite $dbh->{server}, join '', map { join("\t", @$_) . "\n" } @n;
}

# ---------------------------------------------------------------------------
# 0. This dist supplies the PostgreSQL seams and nothing else. The public
#    methods and the machinery are core's, the watch loop, timer and pooled
#    notify are dbio-async's: overriding any of them here would fork the
#    contract ADR 0056 exists to keep single. And the test's spy wraps only
#    the drain, so everything else below runs the shipped code. Code-ref
#    identity is the only probe that tells inherited from overridden.
# ---------------------------------------------------------------------------

{
  my $PG = 'DBIO::PostgreSQL::Storage::Async';
  for my $m (qw( listen unlisten notify listen_alive listen_reconnect
                 _listen_dispatch _listen_lost )) {
    is refaddr($PG->can($m)), refaddr(DBIO::Storage::Async->can($m)),
      "$m is core's, not overridden by the PostgreSQL transport";
  }
  for my $m (qw( _listen_watch _listen_unwatch _listen_delay _notify_send
                 _await_readable _conn_poll_fh _listen_poll_interval )) {
    is refaddr($PG->can($m)), refaddr(DBIO::Async::Storage->can($m)),
      "$m is dbio-async's, not overridden by the PostgreSQL transport";
  }
  for my $m (qw( _listen_open _listen_close _listen_subscribe _listen_unsubscribe
                 _listen_drain _listen_probe _notify_sql transport_capabilities )) {
    isnt refaddr($PG->can($m)), refaddr(DBIO::Async::Storage->can($m)),
      "$m is supplied by the PostgreSQL transport";
  }
  for my $m (qw( _listen_open _listen_close _listen_subscribe _listen_unsubscribe
                 _listen_probe _notify_sql transport_capabilities _pg_connect
                 _pg_quote_channel _pg_nonblocking _pg_dispatch_buffered
                 _pg_listen_command _create_pool_connection )) {
    is refaddr(SpyAsync->can($m)), refaddr($PG->can($m)),
      "the spy does not override $m -- the shipped seam runs";
  }
}

# ---------------------------------------------------------------------------
# 1. Capabilities. Core gates listen/unlisten/listen_alive/listen_reconnect on
#    'listen' and notify on 'notify' (ADR 0056 section 2) -- without them the
#    public methods refuse. copy and pipeline stay undeclared: DBD::Pg's async
#    binding has no pipeline mode and async COPY is the ev transport's, and a
#    layer requiring either must fail loud at compose time, not load.
# ---------------------------------------------------------------------------

{
  my @caps = DBIO::PostgreSQL::Storage::Async->transport_capabilities;
  my %has  = map { $_ => 1 } @caps;
  ok $has{listen}, "declares 'listen'";
  ok $has{notify}, "declares 'notify'";
  ok $has{on_connect_replay}, "still declares the inherited 'on_connect_replay'";
  ok !$has{copy},     "does not declare 'copy'";
  ok !$has{pipeline}, "does not declare 'pipeline'";
  # broker_connect_options: the connect options beside an AccessBroker
  # (karr k91; its claims are in t/73-future-io-broker-connect-options.t).
  is_deeply [ sort @caps ],
    [ sort DBIO::Async::Storage->transport_capabilities, qw(listen notify broker_connect_options) ],
    'exactly the inherited list plus listen, notify and broker_connect_options';
}

# ---------------------------------------------------------------------------
# 2. The statements. The notify payload and channel travel only as binds; the
#    channel of LISTEN / UNLISTEN is quoted as an identifier. A name longer
#    than PostgreSQL's 63-byte identifier limit is refused, not truncated:
#    LISTEN would truncate it and pg_notify refuses it, so it could never
#    deliver.
# ---------------------------------------------------------------------------

{
  my $s    = fresh();
  my $evil = q{x'); DROP TABLE t; --};
  my ($sql, $bind) = $s->_notify_sql($evil, $evil);
  is $sql, 'SELECT pg_notify(?, ?)', 'notify SQL is fixed text with two placeholders';
  is_deeply $bind, [ $evil, $evil ], '... channel and payload only as binds';
  is $s->_transform_sql($sql), 'SELECT pg_notify($1, $2)', '... shaped to $N for DBD::Pg';

  my %quoted = (
    jobs          => '"jobs"',
    'Mixed Case'  => '"Mixed Case"',
    'a"b'         => '"a""b"',
    'app.events'  => '"app.events"',   # one identifier, not schema-qualified
    ('x' x 63)    => '"' . ('x' x 63) . '"',
  );
  is $s->_pg_quote_channel($_), $quoted{$_}, "channel '$_' quoted as $quoted{$_}"
    for sort keys %quoted;

  my $e62 = "\x{e9}" x 31;   # 62 bytes in UTF-8
  is $s->_pg_quote_channel($e62), qq{"$e62"}, '31 x U+00E9 (62 UTF-8 bytes) is accepted';

  for my $case (
    [ 'x' x 64,        qr/64 bytes long.*at most 63 bytes/s, '64 ASCII bytes' ],
    [ "\x{e9}" x 32,   qr/64 bytes long/,                    '32 x U+00E9 = 64 UTF-8 bytes' ],
    [ "a\0b",          qr/NUL byte/,                         'a NUL byte' ],
    [ '',              qr/non-empty string/,                 'the empty string' ],
    [ undef,           qr/non-empty string/,                 'undef' ],
    [ [ 'jobs' ],      qr/non-empty string/,                 'a reference' ],
  ) {
    my ($channel, $re, $what) = @$case;
    eval { $s->_pg_quote_channel($channel) };
    like $@, $re, "refused: $what";
  }
}

# ---------------------------------------------------------------------------
# 3. listen end to end: one dedicated connection outside the pool, opened
#    fork-safe from the storage's connect info; quoted LISTEN; delivery in
#    contract order; several channels share the connection.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  my $f = $s->listen(jobs => sub { push @got, [ jobs => @_ ] });
  ok $f->is_done, 'listen resolved (open and LISTEN are synchronous round trips)';

  is scalar(@CONNECTS), 1, 'exactly one connection was opened';
  is scalar(pool_connects()), 0, '... and it is not a pool connection -- the pool was never touched';
  my ($c) = @CONNECTS;
  is $c->{dsn}, 'dbi:Pg:dbname=listen_test', '... on the storage\'s DSN';
  is $c->{user}, 'u', '... with its credentials';
  is $c->{attrs}{AutoInactiveDestroy}, 1,
    '... opened with AutoInactiveDestroy => 1, at connect time (fork safety)';
  is $c->{attrs}{RaiseError}, 1, '... RaiseError => 1 (a dead connection must die in the drain)';
  is $c->{attrs}{AutoCommit}, 1, '... AutoCommit => 1';
  is $c->{attrs}{pg_enable_utf8}, 1, '... the caller\'s DBD attributes passed through';
  ok !exists $c->{attrs}{pool_size}, '... pool_size is not a DBD attribute and is not passed';

  my $dbh = listen_dbh($s);
  is_deeply $dbh->{sql}, [ 'LISTEN "jobs"' ], 'LISTEN with the channel quoted';

  server_says($dbh, [ jobs => 4242, 'p1' ], [ jobs => 4243, 'p2' ], [ jobs => 4244, 'p3' ]);
  ok drive(sub { @got == 3 }), 'three notifications delivered';
  is_deeply \@got,
    [ [ jobs => 'jobs', 'p1', 4242 ], [ jobs => 'jobs', 'p2', 4243 ], [ jobs => 'jobs', 'p3', 4244 ] ],
    'in arrival order, as ($channel, $payload, $sender_pid) -- pg_notifies\' '
    . '[name, pid, payload] reordered';

  $s->listen(alerts => sub { push @got, [ alerts => @_ ] })->get;
  is scalar(@CONNECTS), 1, 'a second channel shares the listen connection';
  is_deeply $dbh->{sql}, [ 'LISTEN "jobs"', 'LISTEN "alerts"' ], '... and LISTENs on it';

  @got = ();
  server_says($dbh, [ alerts => 7, 'a1' ], [ jobs => 7, 'j1' ], [ alerts => 7, 'a2' ]);
  ok drive(sub { @got == 3 }), 'interleaved notifications on two channels';
  is_deeply \@got,
    [ [ alerts => 'alerts', 'a1', 7 ], [ jobs => 'jobs', 'j1', 7 ], [ alerts => 'alerts', 'a2', 7 ] ],
    'each went to its own channel\'s callback, in order';

  # unlisten: UNLISTEN on the wire, and nothing more for that channel -- even
  # a notification already on its way when the UNLISTEN went out.
  $s->unlisten('alerts')->get;
  is $dbh->{sql}[-1], 'UNLISTEN "alerts"', 'unlisten sent a quoted UNLISTEN';
  @got = ();
  server_says($dbh, [ alerts => 7, 'late' ], [ jobs => 7, 'after' ]);
  ok drive(sub { @got }), 'the remaining channel still delivers';
  settle(0.02);
  is_deeply \@got, [ [ jobs => 'jobs', 'after', 7 ] ],
    '... and the unlistened channel\'s notification was not dispatched';
  is_deeply $s->{spy}{errors}, [], 'no listen errors along the way';

  $s->unlisten('jobs')->get;
  ok $dbh->{disconnected}, 'the last unlisten closed the listen connection';
}

# ---------------------------------------------------------------------------
# 4. Buffered during a synchronous statement. A notification that arrives
#    while LISTEN / UNLISTEN or the ping waits for its reply is read into
#    libpq's buffer; the socket never becomes readable for it. It must be
#    delivered right after the statement -- here, before the loop runs at all.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  $s->listen(jobs => sub { push @got, [@_] })->get;
  my $dbh = listen_dbh($s);
  ok watching($s), q{the watch loop is running};

  push @{ $dbh->{in_flight} }, [ jobs => 11, 'during-listen' ];
  $s->listen(other => sub { push @got, [@_] })->get;
  is_deeply \@got, [ [ 'jobs', 'during-listen', 11 ] ],
    'a notification buffered during LISTEN was delivered on return, without the loop';

  my $rin = '';
  vec($rin, $dbh->{pg_socket}, 1) = 1;
  is select($rin, undef, undef, 0), 0,
    'control: the socket is not readable -- the watch loop could never have found it';

  @got = ();
  push @{ $dbh->{in_flight} }, [ jobs => 12, 'during-unlisten' ];
  $s->unlisten('other')->get;
  is_deeply \@got, [ [ 'jobs', 'during-unlisten', 12 ] ], '... and during UNLISTEN';

  @got = ();
  push @{ $dbh->{in_flight} }, [ jobs => 13, 'during-ping' ];
  ok $s->listen_alive, 'listen_alive: the ping answered';
  ok $dbh->{pings}, '... it was a ping round trip';
  is_deeply \@got, [ [ 'jobs', 'during-ping', 13 ] ], '... and what arrived during it was delivered';
}

# ---------------------------------------------------------------------------
# 5. Never blocking. Future::IO's built-in implementation does not select
#    while it has only read pollers and no timer: it presumes every poll ready
#    and CLEARS O_NONBLOCK on the polled handle while the callbacks run. The
#    watch loop polls a dup of libpq's socket, and O_NONBLOCK lives on the open
#    file description the two share -- so the drain starts on a blocking
#    socket, where libpq's read-until-dry (and its second read past 32 kB)
#    would wait for the next notification. Every read must see O_NONBLOCK.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  $s->listen(jobs => sub { push @got, [@_] })->get;
  my $dbh = listen_dbh($s);
  ok watching($s), q{the watch loop is running};
  @{ $s->{spy}{drain_entry_nb} } = ();
  @{ $dbh->{reads} } = ();

  server_says($dbh, [ jobs => 21, 'presumed' ]);
  pipe(my $or, my $ow) or die "pipe: $!";
  $ow->autoflush(1);
  syswrite $ow, 'x';
  Future::IO->poll($or, POLLIN)->get;   # one round: two read pollers, no timer

  is_deeply \@got, [ [ 'jobs', 'presumed', 21 ] ], 'the notification was delivered in that round';
  ok scalar(grep { !$_ } @{ $s->{spy}{drain_entry_nb} }),
    'precondition: the drain started with O_NONBLOCK cleared on the shared description';
  ok scalar(@{ $dbh->{reads} }) >= 2, 'the drain read until the socket ran dry';
  is_deeply [ grep { !$_ } @{ $dbh->{reads} } ], [],
    'every read of libpq\'s socket saw O_NONBLOCK set -- the drain cannot block';
  ok nonblocking($dbh->{client}), 'and the socket is non-blocking again after the round';
}

# ---------------------------------------------------------------------------
# 6. A dead connection heals: the drain dies at end of file, core closes the
#    connection and reconnects -- through the same broker path the pool uses,
#    so rotated credentials apply -- and LISTENs EVERY registered channel
#    again. listen_reconnect does the same on demand.
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
  is $l[0]{dsn}, 'dbi:Pg:dbname=listen_test', '... on the broker\'s DSN';
  my $old = listen_dbh($s);
  ok watching($s), q{the watch loop is running};

  $broker->{gen} = 'B';                  # credentials rotate
  $old->terminate;                       # pg_terminate_backend / server restart
  ok drive(sub { $s->{spy}{reconnects} }), 'the dead connection was rebuilt';

  like join("\n", @{ $s->{spy}{errors} }), qr/server closed the connection unexpectedly/,
    'on_listen_error heard why: the drain died at end of file';
  ok $old->{disconnected}, 'the dead handle was closed';
  @l = listen_connects();
  is scalar(@l), 2, 'a second listen connection was opened';
  is $l[1]{user}, 'user-B', '... with the ROTATED credentials -- the broker was asked again';
  is $l[1]{attrs}{AutoInactiveDestroy}, 1, '... fork-safe again';

  my $new = listen_dbh($s);
  isnt refaddr($new), refaddr($old), 'the storage now holds the new handle';
  is_deeply [ sort @{ $new->{sql} } ], [ 'LISTEN "alerts"', 'LISTEN "jobs"' ],
    'EVERY registered channel was LISTENed again on it';
  ok $s->listen_alive, 'listen_alive is true again';

  server_says($new, [ jobs => 31, 'j' ], [ alerts => 32, 'a' ]);
  ok drive(sub { @jobs && @alerts }), 'both channels deliver on the new connection';
  is_deeply [ $jobs[-1], $alerts[-1] ], [ [ 'jobs', 'j', 31 ], [ 'alerts', 'a', 32 ] ],
    '... each to its own callback';

  # A watchdog forces a rebuild.
  $broker->{gen} = 'C';
  $s->listen_reconnect->get;
  is $s->{spy}{reconnects}, 2, 'listen_reconnect rebuilt the connection and fired the hook';
  ok $new->{disconnected}, '... closing the one it replaced';
  my $third = listen_dbh($s);
  is $third->{user}, 'user-C', '... reconnecting with the credentials current now';
  is_deeply [ sort @{ $third->{sql} } ], [ 'LISTEN "alerts"', 'LISTEN "jobs"' ],
    '... and LISTENing every channel again';
}

# ---------------------------------------------------------------------------
# 7. A refused channel on a live connection is the statement's fault, not the
#    connection's: listen fails its Future, core drops the channel, nothing
#    reconnects, and the other channels keep delivering.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  $s->listen(jobs => sub { push @got, [@_] })->get;
  my $dbh = listen_dbh($s);

  my $f = $s->listen(('x' x 64) => sub { push @got, [@_] });
  ok $f->is_failed, 'listen on a 64-byte channel fails';
  like scalar $f->failure, qr/at most 63 bytes/, '... saying why';
  is_deeply $dbh->{sql}, [ 'LISTEN "jobs"' ], '... nothing was sent for it';
  is $s->{spy}{reconnects}, 0, '... and the healthy connection was not rebuilt';
  is scalar(@CONNECTS), 1, '... nor a new one opened';
  ok $s->listen_alive, 'listening is still alive';

  server_says($dbh, [ jobs => 41, 'still' ]);
  ok drive(sub { @got }), 'the other channel still delivers';
}

# ---------------------------------------------------------------------------
# 8. notify goes over a pooled connection with binds only, and a listener on
#    the exact channel hears it -- quoted LISTEN and pg_notify meet on the same
#    case-sensitive name. An undef payload arrives as '' (PostgreSQL has no
#    NULL payload).
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  $s->listen(Jobs => sub { push @got, [@_] })->get;
  my $listen_pid = listen_dbh($s)->{pg_pid};

  my $f = $s->notify(Jobs => 'hello');
  ok drive(sub { $f->is_ready }), 'notify resolved';
  ok $f->is_done, '... successfully';
  is scalar(pool_connects()), 1, '... on a pool connection, not the listen one';
  is_deeply $WIRE[-1]{sql}, 'SELECT pg_notify($1, $2)', '... as SELECT pg_notify($1, $2)';
  is_deeply $WIRE[-1]{bind}, [ 'Jobs', 'hello' ], '... channel and payload bound';

  ok drive(sub { @got }), 'the listener heard it';
  is $got[0][0], 'Jobs', '... on the exact, case-sensitive channel';
  is $got[0][1], 'hello', '... with the payload';
  isnt $got[0][2], $listen_pid, '... sent by another backend (the pooled one)';

  @got = ();
  $s->notify('Jobs')->get;
  ok drive(sub { @got }), 'notify without a payload';
  is $got[0][1], '', '... arrives with the empty payload';

  @got = ();
  $s->notify(jobs => 'lower')->get;
  settle(0.02);
  is_deeply \@got, [], 'a notify on "jobs" does not reach a LISTEN on "Jobs"';
}

done_testing;
