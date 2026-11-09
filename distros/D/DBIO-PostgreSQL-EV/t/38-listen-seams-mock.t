use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr weaken );

# OFFLINE test for the LISTEN/NOTIFY seams of the ev transport (karr k43; core
# ADR 0056). Core owns listen / unlisten / notify / listen_alive /
# listen_reconnect, the hooks, the backoff, the channel registry, the queue
# that runs one LISTEN / UNLISTEN at a time, reconnect and the fork guard --
# and it all runs FOR REAL here, driven through the public methods. What this
# file pins is the EV::Pg half this dist supplies: the dedicated connection
# built by the pool's fork-safe constructor from the storage's (or the
# broker's current) connect info, LISTEN / UNLISTEN with the channel quoted as
# ONE identifier, a refused dispatch as a failed Future instead of a stuck
# queue (the k46 finding), on_notify -> dispatch in contract order,
# notifications held until watching starts, on_error -> a lost connection and
# healing, the probe, the EV backoff timer, pooled pg_notify with binds only.
# Mirrors dbio-postgresql's t/62-future-io-listen.t for the future_io
# transport.
#
# THE ONE SUBSTITUTION is EV::Pg itself: a fake whose handles record what is
# sent and let the test play the server -- complete the connect, answer the
# statement in flight, deliver a notification, lose the connection -- in the
# order EV::Pg calls back: on_error first, then every queued callback with the
# error; and on finish, every queued callback with "connection finished",
# including one still being delivered. The backoff timer is a real EV timer.
# The real fork behaviour of the connection needs real libpq: see
# t/34-pool-fork-guard-mock.t (the constructor this connection shares) and
# t/39-listen-seams-live.t.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our @HANDLES;   # every handle made, in order (weak)

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      args      => { %args },
      queue     => [],
      sql       => [],
      connected => 0,
      finished  => 0,
    }, $class;
    $self->{$_} = $args{$_} for qw( on_connect on_error on_notify );
    push @HANDLES, $self;
    Scalar::Util::weaken($HANDLES[-1]);
    return $self;
  }

  for my $h (qw( on_connect on_error on_notify )) {
    no strict 'refs';
    *{"EV::Pg::$h"} = sub { my $s = shift; $s->{$h} = $_[0] if @_; return $s->{$h} };
  }

  sub is_connected  { $_[0]{connected} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { -1 }

  sub query {
    my ($s, $sql, $cb) = @_;
    Carp::croak('not connected') unless $s->{connected};
    Carp::croak('PQsendQuery failed: another command is already in progress')
      if $s->{refuse};
    push @{ $s->{sql} },   $sql;
    push @{ $s->{queue} }, [ $sql, $cb ];
    return;
  }

  sub finish {
    my ($s) = @_;
    $s->{finished}++;
    $s->{connected} = 0;
    $s->_cancel_pending('connection finished');
    return;
  }

  sub _cancel_pending {
    my ($s, $msg) = @_;
    while (my $e = shift @{ $s->{queue} }) { $e->[1]->(undef, $msg) }
    return;
  }

  # --- the server's side ---

  sub t_connect {
    my ($s) = @_;
    $s->{connected} = 1;
    $s->{on_connect}->() if $s->{on_connect};
    return;
  }

  sub t_connect_fails {
    my ($s, $msg) = @_;
    $s->{on_error}->($msg) if $s->{on_error};
    return;
  }

  # Answer the statement at the head of the queue. Like EV::Pg, the callback
  # stays at the head while it runs.
  sub t_reply {
    my ($s, $err) = @_;
    my $e = $s->{queue}[0] or die "t_reply: nothing in flight\n";
    $e->[1]->(defined $err ? (undef, $err) : ('', undef));
    shift @{ $s->{queue} } if @{ $s->{queue} } && $s->{queue}[0] == $e;
    return;
  }

  # EV::Pg 0.07 discards a notification when no on_notify is set.
  sub t_notify {
    my ($s, @n) = @_;
    $s->{on_notify}->(@n) if $s->{on_notify};
    return;
  }

  # The server hung up: on_error, then -- unless on_error finished the
  # handle -- every queued callback with "connection lost".
  sub t_lose {
    my ($s, $msg) = @_;
    my $finished = $s->{finished};
    $s->{connected} = 0;
    $s->{on_error}->($msg) if $s->{on_error};
    $s->_cancel_pending('connection lost') if $s->{finished} == $finished;
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Storage;

plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');

alarm 60;

# --- the pooled side: only notify() uses it -----------------------------------

{
  package FakePg;
  sub new { bless { sent => [] }, shift }
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    push @{ $self->{sent} }, { sql => $sql, bind => [@$bind] };
    $cb->([ [ '' ] ], undef);
    return;
  }
}

{
  package FakePool;
  sub new      { bless { pg => FakePg->new, acquired => 0, released => 0 }, shift }
  sub acquire  { my $s = shift; $s->{acquired}++; return Future->done($s->{pg}) }
  sub release  { $_[0]{released}++ }
  sub _lease   { 1 }   # the lease of a borrow (core k275, karr k89)
  sub shutdown { }
}

# A broker handing out a new credential generation on every call.
{
  package RotatingBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless { calls => 0 }, shift }
  sub connect_info_for_storage {
    my ($self) = @_;
    $self->{calls}++;
    return [ { host => 'db.example', dbname => 'listen_test', user => "user-$self->{calls}" }, {} ];
  }
}

# --- helpers --------------------------------------------------------------------

my $EV_STORAGE = 'DBIO::PostgreSQL::EV::Storage';

sub fresh {
  my (%args) = @_;
  my $s = $EV_STORAGE->new(undef);
  $s->connect_info($args{info}
    || [ { host => 'db.example', dbname => 'listen_test', user => 'u', password => 'tr0ub4dor-pw' } ]);
  $s->{pool} = FakePool->new;
  $s->{t}    = { errors => [], reconnects => 0 };
  $s->on_listen_error(sub { push @{ $_[0]{t}{errors} }, $_[1] });
  $s->on_listen_reconnect(sub { $_[0]{t}{reconnects}++ });
  $s->listen_backoff_initial(0.01);
  $s->listen_backoff_max(0.01);
  @EV::Pg::HANDLES = ();
  return $s;
}

sub handles { grep { defined } @EV::Pg::HANDLES }

sub conninfo_of {
  my ($pg) = @_;
  # connect_timeout=10 is the transport's own default (karr k101, t/111)
  return { map { split /=/, $_, 2 } grep { $_ ne 'connect_timeout=10' } split / /, $pg->{args}{conninfo} };
}

# Run the EV loop until $cond holds, bounded -- never an open-ended wait.
sub drive {
  my ($cond, $max) = @_;
  my $deadline = EV::time() + ($max // 2);
  until ($cond->()) {
    return 0 if EV::time() > $deadline;
    my $tick = EV::timer(0.005, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

# Open the listen connection and answer every LISTEN core sends on it.
sub bring_up {
  my ($s, $pg) = @_;
  $pg->t_connect;
  $pg->t_reply while @{ $pg->{queue} };
  return;
}

# ---------------------------------------------------------------------------
# 0. This dist supplies the EV::Pg seams and nothing else. The public methods,
#    the hooks, the backoff settings and the transport -> core calls are
#    core's: an override here would fork the contract ADR 0056 exists to keep
#    single -- and before k43 this class overrode listen / unlisten / notify
#    and disconnect, which is why its LISTEN connection never healed.
#    Code-ref identity is the only probe that tells inherited from overridden.
# ---------------------------------------------------------------------------

{
  for my $m (qw( listen unlisten notify listen_alive listen_reconnect
                 on_listen_error on_listen_reconnect
                 listen_backoff_initial listen_backoff_max
                 _listen_dispatch _listen_lost _listen_error disconnect )) {
    is refaddr($EV_STORAGE->can($m)), refaddr(DBIO::Storage::Async->can($m)),
      "$m is core's, not overridden by the ev transport";
  }
  for my $m (qw( _listen_open _listen_close _listen_subscribe _listen_unsubscribe
                 _listen_watch _listen_unwatch _listen_probe _listen_delay
                 _notify_send )) {
    isnt refaddr($EV_STORAGE->can($m)), refaddr(DBIO::Storage::Async->can($m)),
      "$m is filled by the ev transport";
  }
  my %caps = map { $_ => 1 } $EV_STORAGE->transport_capabilities;
  ok $caps{listen} && $caps{notify}, "declares 'listen' and 'notify' -- core's gate asks for them";
}

# ---------------------------------------------------------------------------
# 1. The channel is quoted as ONE identifier. A '.' stays in the name (the
#    SQLMaker's _quote, used before k43, split it: "app"."events"). A name over
#    PostgreSQL's 63-byte identifier limit is refused, not truncated: LISTEN
#    would truncate it and pg_notify refuses it, so it could never deliver.
#    The same rules as the future_io transport (dbio-postgresql k77) -- the
#    same code, too: both answer through DBIO::PostgreSQL::Util::quote_channel
#    (dbio-postgresql k82, karr k55), so the two cannot drift apart.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my %quoted = (
    jobs          => '"jobs"',
    'Mixed Case'  => '"Mixed Case"',
    'a"b'         => '"a""b"',
    'app.events'  => '"app.events"',
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

  # Equal answers would also come from a second copy of the rule; the point
  # is that there is none.
  my @seen;
  {
    no warnings 'redefine';
    local *DBIO::PostgreSQL::Util::quote_channel = sub { push @seen, [@_]; '"spy"' };
    is $s->_pg_quote_channel('jobs'), '"spy"',
      '_pg_quote_channel answers through DBIO::PostgreSQL::Util::quote_channel';
  }
  is_deeply \@seen, [ ['jobs'] ], '... handing it the channel alone, unchanged';
}

# ---------------------------------------------------------------------------
# 2. listen end to end: one dedicated connection outside the pool, built by
#    the pool's fork-safe constructor from the storage's connect info; nothing
#    on the wire before the connect completes; quoted LISTEN; the Future
#    resolves when the server answered; delivery in contract order; channels
#    share the connection; unlisten; the last unlisten closes it.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  my $f = $s->listen(jobs => sub { push @got, [ jobs => @_ ] });

  my @h = handles();
  is scalar(@h), 1, 'the first listen opened one connection';
  my $pg = $h[0];
  isa_ok $pg, 'DBIO::PostgreSQL::EV::Pool::_Connection',
    '... built by the pool\'s constructor, so it closes fork-safe (karr k45)';
  is_deeply conninfo_of($pg),
    { host => 'db.example', dbname => 'listen_test', user => 'u', password => 'tr0ub4dor-pw' },
    '... from the storage\'s connect info';
  ok $pg->{args}{keep_alive}, '... with keep_alive, so EV::run keeps running while listening';
  is $s->{pool}{acquired}, 0, '... and not from the pool';
  is_deeply $pg->{sql}, [], 'nothing is sent before the connect completes (EV::Pg would croak "not connected")';
  ok !$f->is_ready, 'listen is pending while the connection opens';
  isa_ok $f, 'DBIO::PostgreSQL::EV::Future', 'the Future handed out -- its get runs the EV loop';

  $pg->t_connect;
  is_deeply $pg->{sql}, [ 'LISTEN "jobs"' ], 'once connected: LISTEN, the channel quoted';
  ok !$f->is_ready, '... listen still pending until the server answers';
  $pg->t_reply;
  ok $f->is_done, 'listen resolved once LISTEN was answered';
  ok $s->listen_alive, 'listen_alive';

  $pg->t_notify(jobs => 'p1', 4242);
  $pg->t_notify(jobs => 'p2', 4243);
  $pg->t_notify(jobs => 'p3', 4244);
  is_deeply \@got,
    [ [ jobs => 'jobs', 'p1', 4242 ], [ jobs => 'jobs', 'p2', 4243 ], [ jobs => 'jobs', 'p3', 4244 ] ],
    'on_notify -> the callback, in arrival order, as ($channel, $payload, $sender_pid)';

  my $f2 = $s->listen(alerts => sub { push @got, [ alerts => @_ ] });
  is scalar(handles()), 1, 'a second channel shares the listen connection';
  is $pg->{sql}[-1], 'LISTEN "alerts"', '... and LISTENs on it';
  $pg->t_reply;
  ok $f2->is_done, '... resolved';

  @got = ();
  $pg->t_notify(alerts => 'a1', 7);
  $pg->t_notify(jobs   => 'j1', 7);
  $pg->t_notify(nobody => 'x',  7);
  is_deeply \@got, [ [ alerts => 'alerts', 'a1', 7 ], [ jobs => 'jobs', 'j1', 7 ] ],
    'each channel to its own callback; an unregistered one is dropped';

  # On the wire: a dotted channel is one identifier; an over-long one is
  # refused on the healthy connection -- nothing sent, nothing reconnected.
  my $dotted = $s->listen('app.events' => sub { push @got, [ dotted => @_ ] });
  is $pg->{sql}[-1], 'LISTEN "app.events"', 'a dotted channel goes out as ONE quoted identifier';
  $pg->t_reply;
  ok $dotted->is_done, '... resolved';
  @got = ();
  $pg->t_notify('app.events' => 'd1', 7);
  is_deeply \@got, [ [ dotted => 'app.events', 'd1', 7 ] ], '... and delivers under its full name';
  $s->unlisten('app.events');
  is $pg->{sql}[-1], 'UNLISTEN "app.events"', '... UNLISTEN likewise';
  $pg->t_reply;

  my $sent = @{ $pg->{sql} };
  my $long = $s->listen(('x' x 64) => sub { });
  ok $long->is_failed, 'listen on a 64-byte channel fails';
  like scalar $long->failure, qr/at most 63 bytes/, '... saying why';
  is scalar(@{ $pg->{sql} }), $sent, '... nothing was sent for it';
  is scalar(handles()), 1, '... and the healthy connection was not rebuilt';
  ok $s->listen_alive, '... listening goes on';
  @{ $s->{t}{errors} } = ();

  my $u = $s->unlisten('alerts');
  is $pg->{sql}[-1], 'UNLISTEN "alerts"', 'unlisten sends a quoted UNLISTEN';
  $pg->t_reply;
  ok $u->is_done, '... and resolves once answered';
  @got = ();
  $pg->t_notify(alerts => 'late', 7);
  is_deeply \@got, [], 'nothing more for the unlistened channel';
  is_deeply $s->{t}{errors}, [], 'no listen errors along the way';

  $s->unlisten('jobs')->get;
  ok $pg->{finished}, 'the last unlisten closed the listen connection';
  ok !defined $pg->on_notify && !defined $pg->on_error,
    '... its handlers cleared, so nothing it reports reaches core';
  ok !$s->listen_alive, 'listen_alive is false once nothing is listened to';
}

# ---------------------------------------------------------------------------
# 3. Notifications that arrive while the connection is set up -- after its
#    first LISTEN, while core subscribes the others one at a time -- are held
#    and delivered when watching starts, before the listen Futures resolve.
#    EV::Pg 0.07 drops a notification when no on_notify is set; one arriving
#    for a channel already LISTENed must not be lost.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my (@got, $fa, $fb);
  $fa = $s->listen(a => sub { push @got, [ @_, $fa->is_ready ? 'resolved' : 'pending' ] });
  $fb = $s->listen(b => sub { push @got, [ @_ ] });
  my ($pg) = handles();

  $pg->t_connect;
  is_deeply $pg->{sql}, [ 'LISTEN "a"' ], 'one LISTEN at a time on the connection (core\'s queue)';
  $pg->t_reply;
  is_deeply $pg->{sql}, [ 'LISTEN "a"', 'LISTEN "b"' ], '... the next once the first is answered';

  $pg->t_notify(a => 'early-1', 11);
  $pg->t_notify(a => 'early-2', 12);
  is_deeply \@got, [], 'a notification during setup is held, not dispatched yet';
  $pg->t_reply;
  is_deeply \@got, [ [ 'a', 'early-1', 11, 'pending' ], [ 'a', 'early-2', 12, 'pending' ] ],
    'held notifications are delivered in order when watching starts, before listen resolves';
  ok $fa->is_done && $fb->is_done, 'both listen Futures resolved';

  # A callback that ends the connection stops the held delivery there.
  my $t = fresh();
  weaken(my $weak_t = $t);
  my @seen;
  $t->listen(a => sub { push @seen, $_[1]; $weak_t->listen_reconnect });
  $t->listen(b => sub { push @seen, $_[1] });
  my ($first) = handles();
  $first->t_connect;
  $first->t_reply;
  $first->t_notify(a => 'held-1', 1);
  $first->t_notify(b => 'held-2', 1);
  $first->t_reply;
  is_deeply \@seen, [ 'held-1' ],
    'a callback that rebuilds the connection stops the delivery of what was held on the old one';
  ok $first->{finished}, '... which was closed';
}

# ---------------------------------------------------------------------------
# 4. A dispatch EV::Pg refuses is a failed Future, never a stuck queue (the k46
#    finding). EV::Pg croaks before it queues the callback: "another command
#    is already in progress" on a busy connection, "not connected" on a lost
#    one. Before k43 the croak left this class's own LISTEN queue marked busy,
#    and every later listen / unlisten waited behind it forever.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $s->listen(jobs => sub { });
  my ($pg) = handles();
  bring_up($s, $pg);
  my $conn = $s->{_listen}{conn};

  $pg->{refuse} = 1;
  my $f;
  ok eval { $f = $s->_listen_subscribe($conn, 'other'); 1 },
    'the seam does not throw when EV::Pg refuses the dispatch';
  ok $f && $f->is_failed, '... it returns a failed Future';
  like scalar $f->failure, qr/another command is already in progress/, '... with EV::Pg\'s own error';

  # Through core: the connection is alive, so the statement was refused -- the
  # channel is dropped, its listen fails, nothing reconnects.
  my $refused = $s->listen(busy => sub { });
  ok $refused->is_failed, 'listen fails when EV::Pg refuses its LISTEN';
  like scalar $refused->failure, qr/LISTEN on channel 'busy' failed: .*another command is already in progress/s,
    '... saying why';
  is scalar(handles()), 1, '... on a live connection nothing reconnects';
  like join("\n", @{ $s->{t}{errors} }), qr/another command is already in progress/,
    '... and on_listen_error heard it';

  $pg->{refuse} = 0;
  my $again = $s->listen(busy => sub { });
  is $pg->{sql}[-1], 'LISTEN "busy"', 'the next listen goes out -- nothing is stuck';
  $pg->t_reply;
  ok $again->is_done, '... and resolves';

  # "not connected": EV::Pg has lost the connection. The probe agrees, so core
  # heals: close, backoff, a new connection with every channel LISTENed again.
  $pg->{connected} = 0;
  my $lost = $s->listen(late => sub { });
  ok $lost->is_failed, 'listen on a lost connection fails';
  like scalar $lost->failure, qr/not connected/, '... with EV::Pg\'s "not connected"';
  ok $pg->{finished}, 'the lost connection was closed';
  ok drive(sub { handles() == 2 }), 'after the backoff a new connection is opened';
  my $new = (handles())[1];
  bring_up($s, $new);
  is_deeply [ sort @{ $new->{sql} } ], [ 'LISTEN "busy"', 'LISTEN "jobs"', 'LISTEN "late"' ],
    '... and every registered channel is LISTENed on it -- the failed one too';
  ok $s->listen_alive, 'listen_alive again';
}

# ---------------------------------------------------------------------------
# 5. on_error after the connect is a lost connection: core closes it, reports
#    the error, waits the backoff (a real EV timer) and reconnects -- through
#    the broker, so rotated credentials apply -- LISTENs every channel again
#    and fires on_listen_reconnect. The dead handle's handlers are cleared, so
#    nothing it still reports reaches core. listen_reconnect does the same on
#    demand.
# ---------------------------------------------------------------------------

{
  my $broker = RotatingBroker->new;
  my $s = fresh(info => [$broker]);
  my (@jobs, @alerts);
  $s->listen(jobs   => sub { push @jobs,   [@_] });
  $s->listen(alerts => sub { push @alerts, [@_] });
  my ($old) = handles();
  my $old_user = conninfo_of($old)->{user};
  like $old_user, qr/^user-\d+$/, 'the listen connection uses the broker\'s credentials';
  bring_up($s, $old);
  ok $s->listen_alive, 'listening';

  $old->t_lose("server closed the connection unexpectedly\n\tThis probably means the server terminated abnormally\n");
  like join("\n", @{ $s->{t}{errors} }), qr/server closed the connection unexpectedly/,
    'on_listen_error heard why (EV::Pg\'s on_error went to _listen_lost)';
  ok $old->{finished}, 'the dead handle was closed';
  ok !defined $old->on_notify && !defined $old->on_error, '... its handlers cleared';
  ok !$s->listen_alive, 'listen_alive is false while the rebuild is pending';
  is scalar(handles()), 1, 'no reconnect before the backoff -- it is a timer, not a loop';

  ok drive(sub { handles() == 2 }), 'the backoff timer fired: a new connection is opened';
  my $new = (handles())[1];
  isnt conninfo_of($new)->{user}, $old_user, '... with the broker\'s CURRENT credentials, not the old ones';
  bring_up($s, $new);
  is_deeply [ sort @{ $new->{sql} } ], [ 'LISTEN "alerts"', 'LISTEN "jobs"' ],
    'EVERY registered channel was LISTENed again on it';
  is $s->{t}{reconnects}, 1, 'on_listen_reconnect fired';
  ok $s->listen_alive, 'listen_alive is true again';

  $old->t_notify(jobs => 'stale', 1);
  $new->t_notify(jobs => 'fresh', 2);
  $new->t_notify(alerts => 'fresh-a', 2);
  is_deeply [ \@jobs, \@alerts ], [ [ [ 'jobs', 'fresh', 2 ] ], [ [ 'alerts', 'fresh-a', 2 ] ] ],
    'both channels deliver on the new connection, nothing from the old one';

  # A watchdog forces a rebuild.
  my $r = $s->listen_reconnect;
  ok $new->{finished}, 'listen_reconnect closed the current connection';
  is scalar(handles()), 3, '... and opened a new one at once';
  my $third = (handles())[2];
  bring_up($s, $third);
  ok $r->is_done, '... its Future resolved once every channel was LISTENed';
  is $s->{t}{reconnects}, 2, '... and on_listen_reconnect fired again';
}

# ---------------------------------------------------------------------------
# 6. A connect that fails fails the open; core reports it and retries after
#    the backoff. The listen Future fails with the attempt.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my $f = $s->listen(jobs => sub { });
  my ($pg) = handles();
  $pg->t_connect_fails("could not connect to server: Connection refused\n");
  ok $f->is_failed, 'listen fails when the connect fails';
  like join("\n", @{ $s->{t}{errors} }),
    qr/connecting the listen connection failed: could not connect to server/,
    'on_listen_error heard why';
  ok drive(sub { handles() == 2 }), 'after the backoff the connect is tried again';
  bring_up($s, (handles())[1]);
  ok $s->listen_alive, '... and the channel is listened to';

  my $none = $EV_STORAGE->new(undef);
  eval { $none->_listen_open };
  like $@, qr/no connect info/, '_listen_open refuses without connect info';
}

# ---------------------------------------------------------------------------
# 7. The probe is EV::Pg's is_connected: no round trip. A false probe is a
#    death report to core -- listen_alive starts healing. A watch on a handle
#    that is not connected throws, which core counts as a dead connection.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $s->listen(jobs => sub { });
  my ($pg) = handles();
  bring_up($s, $pg);
  my $conn = $s->{_listen}{conn};
  is $s->_listen_probe($conn), 1, 'probe: connected';
  is scalar(@{ $pg->{sql} }), 1, '... and it sent nothing (no ping)';

  $pg->{connected} = 0;   # EV::Pg's own view: the connection is gone
  is $s->_listen_probe($conn), 0, 'probe: not connected';
  ok !$s->listen_alive, 'listen_alive is false';
  ok $pg->{finished}, '... and the failed probe started healing: the connection was closed';
  ok drive(sub { handles() == 2 }), '... and a new one opened after the backoff';

  my $x = { pg => $pg, state => 'open', held => [] };
  eval { $s->_listen_watch($x) };
  like $@, qr/not connected/, '_listen_watch throws on a handle that is not connected';
}

# ---------------------------------------------------------------------------
# 8. EV::Pg calls a statement's callback again, with "connection finished",
#    when the connection is closed from inside that callback -- here a
#    callback on the listen Future unlistens the last channel, and core closes
#    the connection while the LISTEN's callback still runs. The second call
#    must not touch the settled Future.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my $f = $s->listen(only => sub { });
  $f->on_done(sub { $s->unlisten('only') });
  my ($pg) = handles();
  $pg->t_connect;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  ok eval { $pg->t_reply; 1 }, 'closing from inside the LISTEN callback does not die'
    or diag $@;
  ok $f->is_done, 'listen resolved';
  ok $pg->{finished}, 'the connection was closed from inside its callback';
  is_deeply \@warnings, [], 'no warnings';
  is_deeply $s->{t}{errors}, [], 'no listen errors';
}

# ---------------------------------------------------------------------------
# 9. The backoff timer resolves from the EV loop, never synchronously -- a
#    synchronous delay would turn an outage into unbounded recursion -- and a
#    cancel stops it.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my $d = $s->_listen_delay(0.02);
  isa_ok $d, 'DBIO::PostgreSQL::EV::Future', 'the delay';
  ok !$d->is_ready, 'pending on return';
  ok drive(sub { $d->is_ready }), 'resolved by the EV loop';
  ok $d->is_done, '... done';

  my $c = $s->_listen_delay(0.01);
  $c->cancel;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  my $until = EV::time() + 0.05;
  drive(sub { EV::time() > $until });
  ok $c->is_cancelled, 'a cancelled delay stays cancelled';
  is_deeply \@warnings, [], '... its timer did not fire into it';

  ok eval { $s->_listen_delay(0.01)->get; 1 }, 'get on a delay runs the EV loop until it fires';
}

# ---------------------------------------------------------------------------
# 10. notify goes over a pooled connection, channel and payload as binds only;
#     an undef payload is sent as '' (PostgreSQL has no NULL payload). A
#     missing channel is refused by core before anything is sent.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my $evil = q{x'); DROP TABLE t; --};
  my $f = $s->notify($evil => $evil);
  ok $f->is_done, 'notify resolved';
  is $s->{pool}{acquired}, 1, '... on a pooled connection';
  is $s->{pool}{released}, 1, '... which went back to the pool';
  is_deeply $s->{pool}{pg}{sent}[-1], { sql => 'SELECT pg_notify($1, $2)', bind => [ $evil, $evil ] },
    '... as SELECT pg_notify($1, $2), channel and payload only as binds';
  is scalar(handles()), 0, '... and no listen connection was opened for it';

  $s->notify('jobs')->get;
  is_deeply $s->{pool}{pg}{sent}[-1]{bind}, [ 'jobs', '' ], 'an undef payload is sent as the empty string';

  eval { $s->notify(undef) };
  like $@, qr/requires a channel name/, 'notify without a channel is refused (core)';
  is scalar(@{ $s->{pool}{pg}{sent} }), 2, '... before anything was sent';
}

# ---------------------------------------------------------------------------
# 11. disconnect -- and a connect_info reconfigure, which goes through it --
#     ends listening: the connection is finished once, the state is gone.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $s->listen(jobs => sub { });
  my ($pg) = handles();
  bring_up($s, $pg);
  $s->disconnect;
  is $pg->{finished}, 1, 'disconnect finishes the listen connection once';
  ok !$s->{_listen}, '... and drops the listen state';
  ok !$s->listen_alive, '... listen_alive is false';

  my $t = fresh();
  $t->listen(jobs => sub { });
  my ($pg2) = handles();
  bring_up($t, $pg2);
  $t->connect_info([ { host => 'other.example', dbname => 'listen_test' } ]);
  is $pg2->{finished}, 1, 'a connect_info reconfigure finishes the listen connection';
  ok !$t->{_listen}, '... it was opened with the outgoing connect info';
}

done_testing;
