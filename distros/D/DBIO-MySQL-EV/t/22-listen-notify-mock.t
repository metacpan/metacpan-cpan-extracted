use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr weaken );
use Socket ();
use Time::HiRes ();
use File::Temp ();
use POSIX ();
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeNotifyServer;

# OFFLINE test of the emulated LISTEN/NOTIFY on the ev transport (karr k44;
# core ADR 0056, dbio-mysql ADR 0008, this dist's ADR 0010). Core owns the
# machinery -- registry, dedicated connection, serialised channel operations,
# healing, fork guard -- and it runs FOR REAL here, driven through the public
# listen / unlisten / notify / listen_alive / listen_reconnect, on the real EV
# loop. What this file pins is the half this dist supplies: the dedicated
# EV::MariaDB handle, the mark taken on it before listen resolves, the timer
# poll loop, the one-statement-at-a-time runner, the probe that neither pings
# nor trusts is_connected, the notify INSERT with binds only, the cleanup and
# its error path, and the fork guard.
#
# THE ONE SUBSTITUTION is EV::MariaDB: FakeMDB below stands in for every handle
# (listen and pool alike) and answers statements from t/lib/FakeNotifyServer.pm,
# an in-memory model of the notify table. The fake enforces what the real
# client enforces -- prepare / execute / close_stmt / ping are EXCLUSIVE and
# die while another operation is pending ("another operation is in progress")
# -- and is stricter than it for query: ANY overlap is a recorded violation.
# Its socket is one end of a real socketpair, so the probe's readability check
# runs against a real file descriptor; a killed session closes the other end.

BEGIN {
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
  eval { require Future; 1 } or plan skip_all => 'Future not installed';
}

use DBIO::MySQL::EV::Storage;

plan skip_all => 'the installed DBIO core predates the LISTEN/NOTIFY contract (core k219)'
  unless DBIO::Storage::Async->can('listen_alive');
plan skip_all => 'the installed DBIO core predates _listen_error (core k227)'
  unless DBIO::Storage::Async->can('_listen_error');

our ($SERVER, @VIOLATIONS);

# --- the fake EV::MariaDB -------------------------------------------------------

{
  package FakeMDB;

  our (@ALL, $MADE, $REFUSE, $HOLD_NEW);
  my $next_thread = 100;

  sub new {
    my ($class, %args) = @_;
    socketpair(my $client, my $server, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    my $self = bless {
      args       => { map { ($_ => $args{$_}) } grep { !/\Aon_/ } keys %args },
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      thread_id  => ++$next_thread,
      client     => $client,
      server     => $server,
      opener     => $$,
      connected  => 0,
      inflight   => undef,
      stmts      => {},
      next_stmt  => 0,
      pings      => 0,
      finish     => [],
      hold       => $HOLD_NEW ? 1 : 0,
      held       => [],
      timers     => {},
      tick       => 0,
      started    => [],
    }, $class;
    push @ALL, $self;
    Scalar::Util::weaken($ALL[-1]);
    $MADE++;
    my $refuse = $REFUSE;
    $self->_later(sub {
      if ($refuse) { $self->_call($self->{on_error}, "Can't connect to server on 'fakehost' (111)") }
      else         { $self->{connected} = 1; $self->_call($self->{on_connect}) }
    });
    return $self;
  }

  # EV::MariaDB catches a dying handler and warns.
  sub _call {
    my ($self, $cb, @args) = @_;
    return unless $cb;
    local $@;
    eval { $cb->(@args); 1 } or warn "FakeMDB handler died: $@";
    return;
  }

  sub _later {
    my ($self, $cb) = @_;
    my $id = ++$self->{tick};
    $self->{timers}{$id} = EV::timer(0, 0, sub { delete $self->{timers}{$id}; $cb->() });
    return;
  }

  sub _guard {
    my ($self, $what) = @_;
    die "connection not valid after fork\n" if $self->{opener} != $$;
    die "not connected\n" if !$self->{connected} || @{ $self->{finish} };
    if (my $op = $self->{inflight}) {
      my $v = "$what while $op->{what} was in flight (thread $self->{thread_id})";
      push @{ $self->{violations} }, $v;
      push @main::VIOLATIONS, $v;
      die "another operation is in progress\n";
    }
    return;
  }

  # Start an operation; $answer computes the callback arguments when it
  # completes, on a later loop tick (or on release() when held).
  sub _start {
    my ($self, $what, $sql, $cb, $answer) = @_;
    my $op = $self->{inflight} = { what => $what, sql => $sql, cb => $cb };
    push @{ $self->{started} }, { what => $what, sql => $sql, pid => $$ };
    my $run = sub {
      return unless $self->{inflight} && $self->{inflight} == $op;
      undef $self->{inflight};                 # idle again inside the callback
      my @args;
      if ($self->{dead}) {
        @args = (undef, $op->{killed} ? 'Lost connection to server during query' : 'Server has gone away');
        $self->{gone} = 1;
      }
      else {
        @args = $answer->();
      }
      $cb->(@args);
    };
    # hold: 1 holds every result, a regex only those of matching statements
    my $hold = $self->{hold};
    if ($hold && ($what eq 'execute' || $what eq 'query')
        && (!ref $hold || (defined $sql && $sql =~ $hold))) {
      push @{ $self->{held} }, $run;
    }
    else {
      $self->_later($run);
    }
    $self->kill_session if $self->{kill_on} && defined $sql && $sql =~ $self->{kill_on};
    return;
  }

  sub _missing_table {
    my ($self, $sql) = @_;
    return !$main::SERVER->{exists}
        && $sql =~ /`\Q$main::SERVER->{table}\E`/
        && $sql !~ /\A(?:CREATE|DROP)/;
  }

  sub prepare {
    my ($self, $sql, $cb) = @_;
    $self->_guard('prepare');
    $self->_start(prepare => $sql, $cb, sub {
      return (undef, "Table 'fake.$main::SERVER->{table}' doesn't exist")
        if $self->_missing_table($sql);
      my $id = ++$self->{next_stmt};
      $self->{stmts}{$id} = $sql;
      return ($id);
    });
    return;
  }

  sub execute {
    my ($self, $stmt, $bind, $cb) = @_;
    $self->_guard('execute');
    my $sql = $self->{stmts}{$stmt} // die "invalid statement handle\n";
    $self->_start(execute => $sql, $cb, sub { $self->_answer($sql, $bind) });
    return;
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    $self->_guard('query');
    $self->_start(query => $sql, $cb, sub {
      return (undef, "Table 'fake.$main::SERVER->{table}' doesn't exist")
        if $self->_missing_table($sql);
      $self->_answer($sql, []);
    });
    return;
  }

  # COM_RESET_CONNECTION, sent by the pool at the end of every borrow (karr
  # k100, core k398). Exclusive like prepare/execute; the session is clean after.
  sub reset_connection {
    my ($self, $cb) = @_;
    $self->_guard(q{reset_connection});
    $self->_start(reset_connection => undef, $cb, sub { (1, undef) });
    return;
  }

  sub _answer {
    my ($self, $sql, $bind) = @_;
    my $r = eval { $main::SERVER->answer($sql, [ @{ $bind || [] } ], $self->{thread_id}) };
    unless ($r) { chomp(my $e = $@); return (undef, $e) }
    return ([ map { [@$_] } @{ $r->{rows} } ]) if $r->{fields};
    return ($r->{rv} eq '0E0' ? 0 : $r->{rv});
  }

  sub close_stmt {
    my ($self, $stmt, $cb) = @_;
    if ($self->{gone}) {   # invalidated handles are accepted at once
      delete $self->{stmts}{$stmt};
      $cb->(1);
      return;
    }
    $self->_guard('close_stmt');
    $self->_start(close_stmt => undef, $cb, sub { delete $self->{stmts}{$stmt}; return (1) });
    return;
  }

  sub ping {
    my ($self, $cb) = @_;
    $self->_guard('ping');
    $self->{pings}++;
    $self->_start(ping => undef, $cb, sub { return (1) });
    return;
  }

  sub finish {
    my ($self) = @_;
    push @{ $self->{finish} }, { pid => $$, op => ($self->{inflight} ? $self->{inflight}{what} : undef) };
    %{ $self->{timers} } = ();
    @{ $self->{held} } = ();
    if (my $op = delete $self->{inflight}) { $op->{cb}->(undef, 'connection finished') }
    close $self->{client} if $self->{client};
    return;
  }

  # As strict as EV::MariaDB 0.08 (karr k67): a callback is required.
  sub close_async { Carp::croak('Usage: EV::MariaDB::close_async(self, cb)') unless @_ == 2; $_[0]->finish; $_[1]->(1); return }

  sub socket {
    my ($self) = @_;
    return -1 if @{ $self->{finish} } || $self->{gone};
    return fileno $self->{client};
  }

  sub is_connected  { $_[0]{connected} }                 # true after death, as the real one
  sub thread_id     { $_[0]{thread_id} }
  sub pending_count { $_[0]{inflight} ? 1 : 0 }
  sub open_stmts    { scalar keys %{ $_[0]{stmts} } }
  sub finished      { scalar @{ $_[0]{finish} } }

  # The server ends the session (KILL, a restart): the socket reads EOF, a
  # statement in flight fails, every later one finds the server gone.
  sub kill_session {
    my ($self) = @_;
    $self->{dead} = 1;
    $self->{inflight}{killed} = 1 if $self->{inflight};
    close $self->{server} if $self->{server};
    undef $self->{server};
    $self->release;
    return;
  }

  sub release {
    my ($self) = @_;
    $self->{hold} = 0;
    $self->_later($_) for splice @{ $self->{held} };
    return;
  }
}

# The fake IS EV::MariaDB for this process: the real XS module never loads.
BEGIN { $INC{'EV/MariaDB.pm'} = __FILE__ }
{
  no warnings 'once';
  *EV::MariaDB::new = sub { shift; FakeMDB->new(@_) };
}

# A broker handing out storage-native connect info for whatever credential
# generation the test sets.
{
  package RotatingBroker;
  use base 'DBIO::AccessBroker';
  sub connect_info_for_storage {
    my ($self) = @_;
    return [ { host => 'fakehost', database => 'listen_test', user => "user-$self->{gen}",
               password => "pw-$self->{gen}", pool_size => 1 }, {} ];
  }
}

# Every non-fatal error a transport reports goes through core's _listen_error
# (core k227). Record the calls, then let core do its work.
my @LISTEN_ERROR;
{
  no warnings 'redefine';
  my $orig = \&DBIO::Storage::Async::_listen_error;
  *DBIO::Storage::Async::_listen_error = sub { push @LISTEN_ERROR, $_[1]; goto &$orig };
}

# --- helpers --------------------------------------------------------------------

my $TICK = EV::timer(0.002, 0.002, sub {});   # RUN_ONCE never blocks for long

sub drive {
  my ($cond, $max) = @_;
  my $deadline = Time::HiRes::time() + ($max // 3);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    EV::run(EV::RUN_ONCE());
  }
  return 1;
}

sub settle {
  my $deadline = Time::HiRes::time() + ($_[0] // 0.05);
  EV::run(EV::RUN_ONCE()) while Time::HiRes::time() < $deadline;
  return;
}

sub await { my ($f) = @_; drive(sub { $f->is_ready }) or die "timed out awaiting a Future\n"; return $f }

sub fresh {
  my (%args) = @_;
  $SERVER = $args{server} || FakeNotifyServer->new;
  my $s = DBIO::MySQL::EV::Storage->new(undef);
  $s->connect_info($args{info}
    || [ { host => 'fakehost', database => 'listen_test', user => 'u', password => 'pw-listen-k100', pool_size => 1 } ]);
  $s->{spy} = { errors => [], reconnects => 0 };
  $s->on_listen_error(sub { push @{ $_[0]{spy}{errors} }, $_[1] });
  $s->on_listen_reconnect(sub { $_[0]{spy}{reconnects}++ });
  $s->listen_backoff_initial(0.01);
  $s->listen_backoff_max(0.01);
  $s->notify_poll_interval(0.01);
  @FakeMDB::ALL = ();
  $FakeMDB::MADE = 0;
  @LISTEN_ERROR = ();
  return $s;
}

sub listen_conn { $_[0]{_listen} && $_[0]{_listen}{conn} }
sub listen_mdb  { my $c = listen_conn($_[0]); $c && $c->{mdb} }
sub pool_mdbs   { my $p = $_[0]{pool} or return (); @{ $p->{_connections} || [] } }

my $MARK = qr/\ASELECT `id`, NULL, NULL, NULL, NULL FROM/;
my $POLL = qr/\ASELECT `id`, `channel`/;

sub on_thread { my ($re, $mdb) = @_; grep { $_->{pid} == $mdb->{thread_id} } $SERVER->statements($re) }

# The poll loop is running once a poll has run on the listen handle.
sub watching {
  my ($s) = @_;
  my $mdb  = listen_mdb($s) or return 0;
  my $seen = on_thread($POLL, $mdb);
  return drive(sub { on_thread($POLL, $mdb) > $seen });
}

# ---------------------------------------------------------------------------
# 0. The fake is a real check: EV::MariaDB's exclusive operations die while
#    another is pending, and the fake records every such overlap. Every later
#    "no violation" assertion rests on this; if the fake stopped enforcing it
#    they would all pass vacuously.
# ---------------------------------------------------------------------------

{
  fresh();
  my $m = EV::MariaDB->new(host => 'x');
  ok drive(sub { $m->{connected} }), 'control: a fake handle connects on a later tick';
  $m->query('SELECT 1', sub {});
  ok !eval { $m->prepare('SELECT ?', sub {}); 1 }, 'control: prepare while a query is pending dies';
  like $@, qr/another operation is in progress/, '... with EV::MariaDB\'s message';
  is scalar(@VIOLATIONS), 1, '... and is recorded as a violation';
  @VIOLATIONS = ();
  $m->finish;
}

# ---------------------------------------------------------------------------
# 1. The statements, through the storage. notify's channel and payload travel
#    only as binds (core ADR 0017 section 3) -- a hostile channel/payload must
#    reach the server as bind values of a fixed INSERT, never as SQL. An
#    invalid table name is refused before anything connects: the name is
#    interpolated into every statement.
# ---------------------------------------------------------------------------

{
  my $s    = fresh();
  my $evil = q{x'); DROP TABLE t; --};
  my $f    = await($s->notify($evil, $evil));
  ok $f->is_done, 'notify with a hostile channel and payload resolved';
  my ($ins) = $SERVER->statements(qr/\AINSERT/);
  is $ins->{sql}, 'INSERT INTO `dbio_notify` (`channel`, `payload`, `pid`, `created_at`) '
               . 'VALUES (?, ?, CONNECTION_ID(), UTC_TIMESTAMP(6))', '... as the fixed INSERT';
  is_deeply $ins->{bind}, [ $evil, $evil ], '... channel and payload only as binds';

  $s = fresh();
  $s->notify_table('bad name');
  $f = await($s->notify(jobs => 'x'));
  like scalar $f->failure, qr/not a plain identifier/, 'notify with an invalid table name fails, naming it';
  $s->listen(jobs => sub {});
  ok drive(sub { @{ $s->{spy}{errors} } }), 'listen with an invalid table name reports';
  like $s->{spy}{errors}[0], qr/not a plain identifier/, '... why';
  is $FakeMDB::MADE, 0, '... and nothing connected: validated before the handle is made';
  await($s->unlisten('jobs'));
  is_deeply [ $SERVER->statements ], [], 'no statement reached the server';
}

# ---------------------------------------------------------------------------
# 2. Contract order: listen's Future resolves only once the mark statement
#    has ANSWERED on the listen connection. A mark taken lazily (at the first
#    poll) or a Future resolved before the answer would turn the notification
#    sent right after listen resolved into "history" and swallow it -- the
#    one guarantee a caller doing listen->then(notify) relies on.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  my $f;
  {
    local $FakeMDB::HOLD_NEW = 1;      # the listen handle only, not the pool's
    $f = $s->listen(jobs => sub { push @got, $_[1] });
    ok drive(sub { my $m = listen_mdb($s); $m && @{ $m->{held} } }),
      'the mark statement is on the wire, its answer held';
  }
  ok !$f->is_ready, 'listen has NOT resolved while the mark is unanswered';
  $SERVER->insert(jobs => 'before-mark');
  listen_mdb($s)->release;
  await($f);
  ok $f->is_done, 'listen resolved once the mark answered';
  await($s->notify(jobs => 'after-listen'));
  ok drive(sub { @got }), 'a notify sent after listen resolved is delivered';
  settle(0.05);
  is_deeply \@got, ['after-listen'], '... and the one committed before the mark answered is history';
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 3. listen end to end: ONE dedicated EV::MariaDB handle outside the pool,
#    opened from the storage's connect info; the mark taken on it; no
#    history; delivery in contract order with the sender; several channels on
#    the one handle; unlisten stops a channel; the last unlisten closes the
#    handle. Every prepared statement is closed again: a poll per second
#    would otherwise pile up server-side statements until the server's
#    max_prepared_stmt_count refuses everyone.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $SERVER->insert(jobs => "history$_") for 1 .. 3;
  my @got;
  await($s->listen(jobs => sub { push @got, [ jobs => @_ ] }));

  my @handles = grep { defined } @FakeMDB::ALL;
  is $FakeMDB::MADE, 1, 'exactly one handle was made';
  ok !defined $s->{pool}, '... and the pool was never built: the listen handle is not a pool connection';
  my $mdb = listen_mdb($s);
  is refaddr($mdb), refaddr($handles[0]), '... it is the listen connection';
  is_deeply $mdb->{args}, { host => 'fakehost', database => 'listen_test', user => 'u', password => 'pw-listen-k100', found_rows => 1 },
    '... opened from the storage\'s connect info (pool_size stripped), CLIENT_FOUND_ROWS on (karr k80)';

  my @marks = $SERVER->statements($MARK);
  is scalar(@marks), 1, 'one mark was taken';
  is $marks[0]{pid}, $mdb->{thread_id}, '... on the listen connection itself';
  is_deeply $marks[0]{bind}, [ 'jobs', 'jobs' ], '... with the channel bound';

  ok watching($s), 'the listen connection is polled';
  settle(0.05);
  is_deeply \@got, [], 'nothing committed before listen is delivered (no history)';

  $SERVER->insert(jobs => "p$_", pid => 4240 + $_) for 1 .. 3;
  ok drive(sub { @got == 3 }), 'three notifications delivered';
  is_deeply \@got,
    [ [ jobs => 'jobs', 'p1', 4241 ], [ jobs => 'jobs', 'p2', 4242 ], [ jobs => 'jobs', 'p3', 4243 ] ],
    'in order, as ($channel, $payload, $sender_pid)';

  await($s->listen(alerts => sub { push @got, [ alerts => @_ ] }));
  is $FakeMDB::MADE, 1, 'a second channel shares the listen handle';

  @got = ();
  $SERVER->insert(alerts => 'a1', pid => 7);
  $SERVER->insert(jobs   => 'j1', pid => 7);
  $SERVER->insert(alerts => 'a2', pid => 7);
  ok drive(sub { @got == 3 }), 'interleaved notifications on two channels';
  is_deeply \@got,
    [ [ alerts => 'alerts', 'a1', 7 ], [ jobs => 'jobs', 'j1', 7 ], [ alerts => 'alerts', 'a2', 7 ] ],
    'each went to its own channel\'s callback, in order';

  await($s->unlisten('alerts'));
  @got = ();
  $SERVER->insert(alerts => 'late', pid => 7);
  $SERVER->insert(jobs   => 'after', pid => 7);
  ok drive(sub { @got }), 'the remaining channel still delivers';
  settle(0.05);
  is_deeply \@got, [ [ jobs => 'jobs', 'after', 7 ] ], '... and the unlistened channel is not delivered';

  # A poll in flight holds its statement until its close_stmt answered: wait for
  # the state (no statement open), not for the clock.
  ok drive(sub { $mdb->open_stmts == 0 }), 'no prepared statement was left open on the listen connection';
  is $mdb->{pings}, 0, 'nothing ever pinged it';
  is_deeply $s->{spy}{errors}, [], 'no listen errors along the way';

  await($s->unlisten('jobs'));
  is $mdb->finished, 1, 'the last unlisten closed the listen handle';
  is_deeply \@VIOLATIONS, [], 'no operation ever overlapped another on any handle';
}

# ---------------------------------------------------------------------------
# 3b. unlisten in the middle of a poll cycle (karr k89): the poll's execute is
#     held on the wire while a channel is unlistened. The statement of that
#     poll must still be closed once its answer comes -- unlisten takes the
#     channel away, not the statement's close_stmt -- and the loop goes on for
#     the channel that is left.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  await($s->listen(jobs   => sub { push @got, $_[1] }));
  await($s->listen(alerts => sub { push @got, $_[1] }));
  ok watching($s), 'the poll loop runs';
  my $mdb = listen_mdb($s);

  $mdb->{hold} = $POLL;      # hold the next poll's execute
  ok drive(sub { @{ $mdb->{held} } }), 'a poll is in flight, its answer held';
  is $mdb->open_stmts, 1, '... with its prepared statement open';

  await($s->unlisten('alerts'));
  $SERVER->insert(jobs => 'during', pid => 5);
  $mdb->{hold} = 0;
  $mdb->release;
  ok drive(sub { $mdb->open_stmts == 0 }), 'the poll in flight at unlisten closed its statement';
  ok drive(sub { @got }), '... and the loop goes on for the remaining channel';
  is_deeply \@got, ['during'], '... which delivers';
  is_deeply \@VIOLATIONS, [], 'no overlap on the handle';

  # the last channel: the handle is finished while the poll is in flight
  $mdb->{hold} = $POLL;
  ok drive(sub { @{ $mdb->{held} } }), 'again a poll in flight';
  my $f = $s->unlisten('jobs');
  await($f);
  is $mdb->finished, 1, 'the last unlisten finished the handle with the poll in flight';
  $mdb->{hold} = 0;
  settle(0.05);
  is_deeply \@VIOLATIONS, [], '... without an overlapping operation';
  is_deeply $s->{spy}{errors}, [], '... and without a listen error';
}

# ---------------------------------------------------------------------------
# 4. notify() resolves, on a POOLED connection (the listen connection is for
#    listening; a notify on it would queue behind polls). The sender is that
#    session's CONNECTION_ID(); an undef payload arrives as ''; channels are
#    exact and case-sensitive.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  await($s->listen(Jobs => sub { push @got, [@_] }));
  my $f = await($s->notify(Jobs => 'hello'));
  ok $f->is_done, 'notify resolved';
  my ($pool) = pool_mdbs($s);
  ok $pool, '... through the pool';
  isnt refaddr($pool), refaddr(listen_mdb($s)), '... not on the listen handle';
  my ($ins) = $SERVER->statements(qr/\AINSERT/);
  is $ins->{pid}, $pool->{thread_id}, '... the INSERT ran on the pooled handle';

  ok drive(sub { @got }), 'a notify right after listen is delivered';
  is_deeply $got[0], [ 'Jobs', 'hello', $pool->{thread_id} ], '... with the pooled session as the sender';

  @got = ();
  await($s->notify('Jobs'));
  ok drive(sub { @got }), 'notify without a payload';
  is $got[0][1], '', '... arrives with the empty payload';

  @got = ();
  await($s->notify(jobs => 'lower'));
  settle(0.05);
  is_deeply \@got, [], 'a notify on "jobs" does not reach a listen on "Jobs"';
  await($s->unlisten('Jobs'));
}

# ---------------------------------------------------------------------------
# 5. The out-of-order commit through the whole machinery -- the pitfall the
#    emulation exists for: A takes the lower id, B commits first and is
#    delivered, A commits later and must be delivered too, each exactly once
#    over many polls.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  await($s->listen(jobs => sub { push @got, $_[1] }));
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
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 6. One statement at a time on the listen connection. While a poll is in
#    flight, a watchdog's listen_alive must answer without touching the handle
#    (a ping would die in EV::MariaDB, and core would take that for a death
#    and reconnect), and a listen for a second channel must WAIT for the poll
#    instead of colliding with it -- its mark is taken only after the poll
#    answered. Idle, the probe checks the socket and still never pings.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  await($s->listen(jobs => sub { push @got, [@_] }));
  my $mdb = listen_mdb($s);
  ok watching($s), 'polling';

  $mdb->{hold} = $POLL;
  ok drive(sub { @{ $mdb->{held} } }), 'a poll is in flight, its result held';
  ok $s->listen_alive, 'listen_alive during the poll in flight: alive';

  my $f = $s->listen(alerts => sub { push @got, [@_] });
  settle(0.05);
  ok !$f->is_ready, 'a listen during the poll in flight waits for it';
  is scalar(grep { $_->{bind}[0] eq 'alerts' } on_thread($MARK, $mdb)), 0, '... its mark not yet taken';

  $mdb->release;
  await($f);
  ok $f->is_done, 'released: the listen completes';
  is_deeply \@VIOLATIONS, [], 'nothing ever ran over the statement in flight';
  is $s->{spy}{reconnects}, 0, 'no spurious reconnect';
  is_deeply $s->{spy}{errors}, [], 'no listen error';

  $SERVER->insert(alerts => 'a', pid => 9);
  ok drive(sub { @got }), 'the channel subscribed during the poll delivers';

  ok drive(sub { !$mdb->{inflight} }), 'the handle is idle';
  ok $s->listen_alive, 'listen_alive on the idle handle: alive';
  is $mdb->{pings}, 0, '... answered from the socket, without a ping';
  await($s->unlisten($_)) for qw(jobs alerts);
}

# ---------------------------------------------------------------------------
# 7. The probe tells a hung-up idle connection from a live one WITHOUT a
#    round trip. EV::MariaDB's is_connected stays true after the server
#    killed the session (the fake mirrors that), so a probe built on it would
#    call a dead connection alive until the next poll. The killed session's
#    socket reads EOF: listen_alive must say false and start healing.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $s->notify_poll_interval(5);   # no poll will find the death first
  my @got;
  await($s->listen(jobs => sub { push @got, $_[1] }));
  my $old = listen_mdb($s);
  $old->kill_session;
  ok $old->is_connected, 'is_connected still says connected after the kill (as EV::MariaDB does)';
  ok !$s->listen_alive, 'listen_alive: false -- the idle socket reads EOF';
  is $old->{pings}, 0, '... decided without a ping';
  ok drive(sub { $s->{spy}{reconnects} }), 'the probe\'s death report healed the connection';
  isnt refaddr(listen_mdb($s)), refaddr($old), '... on a new handle';
  ok $old->finished, '... the dead one closed';
  ok $s->listen_alive, 'listen_alive is true again';
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 8. A killed poll heals: the failed poll goes to _listen_lost, core closes
#    the handle and reconnects -- through the broker path a pool spawn uses,
#    so ROTATED credentials apply -- takes the mark of EVERY registered
#    channel again on the new handle, and fires on_listen_reconnect.
#    listen_reconnect does the same on demand. Without re-marking every
#    channel a rebuilt connection would silently deliver on some channels only.
# ---------------------------------------------------------------------------

{
  my $broker = RotatingBroker->new;
  $broker->{gen} = 'A';
  my $s = fresh(info => [$broker]);
  my (@jobs, @alerts);
  await($s->listen(jobs   => sub { push @jobs,   [@_] }));
  await($s->listen(alerts => sub { push @alerts, [@_] }));

  my $old = listen_mdb($s);
  is $old->{args}{user}, 'user-A', 'the listen handle was opened with the broker\'s current credentials';
  ok watching($s), 'polling';

  $broker->{gen} = 'B';
  $old->{hold} = $POLL;
  ok drive(sub { @{ $old->{held} } }), 'a poll is in flight';
  $old->kill_session;
  ok drive(sub { $s->{spy}{reconnects} }), 'the killed connection was rebuilt';
  like join("\n", @{ $s->{spy}{errors} }), qr/polling the notify table `dbio_notify` failed: Lost connection/,
    'on_listen_error heard why: the poll failed';
  ok $old->finished, 'the dead handle was closed';

  my $new = listen_mdb($s);
  isnt refaddr($new), refaddr($old), 'a new listen handle';
  is $new->{args}{user}, 'user-B', '... opened with the ROTATED credentials';
  is_deeply [ sort map { $_->{bind}[0] } on_thread($MARK, $new) ], [ 'alerts', 'jobs' ],
    'the mark of EVERY registered channel was taken again on it';
  ok $s->listen_alive, 'listen_alive is true again';

  $SERVER->insert(jobs => 'j', pid => 31);
  $SERVER->insert(alerts => 'a', pid => 32);
  ok drive(sub { @jobs && @alerts }), 'both channels deliver on the new handle';
  is_deeply [ $jobs[-1], $alerts[-1] ], [ [ 'jobs', 'j', 31 ], [ 'alerts', 'a', 32 ] ],
    '... each to its own callback';

  $broker->{gen} = 'C';
  await($s->listen_reconnect);
  is $s->{spy}{reconnects}, 2, 'listen_reconnect rebuilt the connection and fired the hook';
  ok $new->finished, '... closing the handle it replaced';
  is listen_mdb($s)->{args}{user}, 'user-C', '... reconnecting with the credentials current now';
  is_deeply \@VIOLATIONS, [], 'no overlap on any handle through the healing';
  await($s->unlisten($_)) for qw(jobs alerts);
}

# ---------------------------------------------------------------------------
# 9. No table, no silent DDL. A listen against a missing table fails its
#    Future with a message naming the table and deploy_notify_table -- a
#    refusal on a live connection, so core drops the channel instead of
#    reconnecting in a loop. deploy_notify_table creates it on a POOLED
#    connection, and then listen works.
# ---------------------------------------------------------------------------

{
  my $s = fresh(server => FakeNotifyServer->new(exists => 0));
  my $f = await($s->listen(jobs => sub {}));
  like scalar $f->failure, qr/the notify table `dbio_notify` does not exist.*deploy_notify_table/s,
    'listen against a missing table fails, naming the table and deploy_notify_table';
  is $s->{spy}{reconnects}, 0, '... without reconnecting';
  is $FakeMDB::MADE, 1, '... on the one handle it opened';
  ok !listen_conn($s), '... which is closed again: no channel is left';
  is_deeply [ $SERVER->statements(qr/\ACREATE/) ], [], 'nothing created the table';

  await($s->deploy_notify_table);
  my ($ddl) = $SERVER->statements(qr/\ACREATE TABLE IF NOT EXISTS `dbio_notify`/);
  ok $ddl, 'deploy_notify_table ran CREATE TABLE IF NOT EXISTS';
  ok scalar(grep { $_->{thread_id} == $ddl->{pid} } pool_mdbs($s)), '... on a pooled connection';

  my @got;
  await($s->listen(jobs => sub { push @got, $_[1] }));
  $SERVER->insert(jobs => 'now');
  ok drive(sub { @got }), 'after deploy, listen works';
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 10. Retention. The listen connection deletes old rows after a poll, bounded
#     by LIMIT. A cleanup the account may not run is NON-fatal: it goes
#     through core's _listen_error seam (core k227) to on_listen_error, the
#     connection stays and listening goes on, and it is not retried on every
#     poll. Treating it as a death would reconnect a healthy connection in a
#     loop; dropping it would hide a table that grows forever.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $SERVER->insert(old => $_, at => $SERVER->now - 7200) for 1 .. 3;
  await($s->listen(jobs => sub {}));
  my $mdb = listen_mdb($s);
  ok drive(sub { $SERVER->statements(qr/\ADELETE/) }), 'a cleanup ran';
  my ($del) = $SERVER->statements(qr/\ADELETE/);
  is $del->{sql},
    'DELETE FROM `dbio_notify` WHERE `created_at` < UTC_TIMESTAMP(6) - INTERVAL 3600000000 MICROSECOND LIMIT 1000',
    '... rows older than the one-hour retention, 1000 at most';
  is $del->{pid}, $mdb->{thread_id}, '... on the listen connection';
  ok drive(sub { !grep { $_->{channel} eq 'old' } @{ $SERVER->{rows} } }), 'the old rows are gone';
  await($s->unlisten('jobs'));

  my $denied = FakeNotifyServer->new;
  $denied->{deny_delete} = 1;
  $s = fresh(server => $denied);
  my @got;
  await($s->listen(jobs => sub { push @got, $_[1] }));
  $mdb = listen_mdb($s);
  ok drive(sub { @{ $s->{spy}{errors} } }), 'a denied cleanup is reported';
  is scalar(@LISTEN_ERROR), 1, '... through core\'s _listen_error seam';
  like $LISTEN_ERROR[0], qr/cleaning up the notify table `dbio_notify` failed: .*DELETE command denied/,
    '... with the server\'s reason';
  is $s->{spy}{errors}[0], $LISTEN_ERROR[0], '... which reached on_listen_error verbatim';
  $SERVER->insert(jobs => 'still');
  ok drive(sub { @got }), 'listening goes on';
  settle(0.1);
  is scalar($SERVER->statements(qr/\ADELETE/)), 1, 'the cleanup is not retried on every poll';
  is $s->{spy}{reconnects}, 0, 'it did not cost the connection';
  is refaddr(listen_mdb($s)), refaddr($mdb), '... the same handle listens';
  ok $s->listen_alive, '... and listen_alive says so';
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 11. A cleanup that fails because the connection DIED is a death, not a
#     housekeeping error: reporting it through _listen_error and polling on
#     would leave listening on a dead handle until the next poll failed. The
#     probe decides, and core heals.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  $SERVER->insert(old => 'x', at => $SERVER->now - 7200);
  my $f = $s->listen(jobs => sub {});
  ok drive(sub { listen_mdb($s) }), 'the listen handle exists';
  listen_mdb($s)->{kill_on} = qr/\ADELETE/;
  await($f);
  ok drive(sub { $s->{spy}{reconnects} }), 'a cleanup killed in flight healed the connection';
  is_deeply \@LISTEN_ERROR, [], '... it was not reported as a non-fatal cleanup error';
  like join("\n", @{ $s->{spy}{errors} }), qr/cleaning up the notify table `dbio_notify` failed: Lost connection/,
    '... on_listen_error heard the death';
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 12. Unlistening the last channel while a poll is in flight stops the watch
#     and closes the handle with the poll still running: its late result must
#     not be delivered, nothing may be sent over it, and no error results.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  await($s->listen(jobs => sub { push @got, $_[1] }));
  my $mdb = listen_mdb($s);
  ok watching($s), 'polling';
  $SERVER->insert(jobs => 'in-flight');
  $mdb->{hold} = $POLL;
  ok drive(sub { @{ $mdb->{held} } }), 'a poll is in flight';
  await($s->unlisten('jobs'));
  is $mdb->finished, 1, 'the last unlisten closed the handle';
  is $mdb->{finish}[0]{op}, 'execute', '... with the poll still in flight';
  settle(0.05);
  is_deeply \@got, [], 'the poll\'s late result was not delivered';
  is_deeply \@VIOLATIONS, [], 'nothing overlapped the poll in flight';
  is_deeply $s->{spy}{errors}, [], 'no listen error';
}

# ---------------------------------------------------------------------------
# 12b. Nothing is dispatched for a connection after it was unwatched -- the
#      _listen_unwatch contract -- not even the rest of a batch already in
#      hand. A callback that forces a rebuild in the middle of a batch ends
#      the old connection's delivery right there; the rest of that batch is
#      NOT delivered from the old connection (the new one takes a new mark,
#      as after any rebuild). Delivering it anyway would run callbacks for a
#      connection core has already closed.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  my $forced;
  await($s->listen(jobs => sub {
    push @got, $_[1];
    $forced ||= $s->listen_reconnect if $_[1] eq 'first';
  }));
  my $old = listen_mdb($s);
  ok watching($s), 'polling';
  $old->{hold} = $POLL;
  ok drive(sub { @{ $old->{held} } }), 'a poll is in flight';
  $SERVER->insert(jobs => $_) for qw(first second third);
  $old->release;
  ok drive(sub { $s->{spy}{reconnects} }), 'the callback forced a rebuild';
  settle(0.05);
  is_deeply \@got, ['first'], 'the rest of the old connection\'s batch was not dispatched after it was unwatched';
  isnt refaddr(listen_mdb($s)), refaddr($old), '... listening goes on on the new connection';
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 13. The fork guard. A forked child that resumes the EV loop shares the
#     parent's socket; with a statement in flight at fork time, the real
#     EV::MariaDB would read the parent's reply in the child (measured, ADR
#     0010). The child's first loop iteration must therefore FINISH its copy
#     of the listen handle -- before its poll timer or anything else runs --
#     and must start nothing on it and deliver nothing. The parent's handle
#     is untouched and goes on delivering. (The fake cannot share a socket;
#     the live test proves the parent's side against a real server.) Nor may
#     the guard, once it fired, keep the child's loop running: an active
#     EV::fork watcher alone keeps EV::run from ever returning (karr k46).
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my @got;
  await($s->listen(jobs => sub { push @got, $_[1] }));
  my $mdb = listen_mdb($s);
  ok watching($s), 'polling';
  $mdb->{hold} = $POLL;
  ok drive(sub { @{ $mdb->{held} } }), 'a poll is in flight at fork time';
  my $started = @{ $mdb->{started} };

  my $report = File::Temp->new;
  my $child  = fork;
  die "fork: $!" unless defined $child;
  if (!$child) {
    my $deadline = Time::HiRes::time() + 0.3;
    EV::run(EV::RUN_ONCE()) while Time::HiRes::time() < $deadline;
    my @mine = grep { $_->{pid} == $$ } @{ $mdb->{started} };
    # Run the loop until it returns by itself, bounded by a timer that does
    # not keep it running: kept alive by something else, it breaks instead.
    undef $TICK;
    my $stuck;
    my $bound = EV::timer(2, 0, sub { $stuck = 1; EV::break(EV::BREAK_ALL()) });
    $bound->keepalive(0);
    EV::run();
    open my $fh, '>', $report->filename or POSIX::_exit(2);
    print {$fh} join("\t",
      scalar(grep { $_->{pid} == $$ } @{ $mdb->{finish} }),
      scalar(@mine),
      scalar(@got),
      scalar(@{ $s->{spy}{errors} }),
      $s->{spy}{reconnects},
      ($stuck ? 0 : 1),
    ), "\n";
    close $fh;
    POSIX::_exit(0);
  }
  waitpid($child, 0);
  is $? >> 8, 0, 'the child resumed the loop and exited';
  open my $fh, '<', $report->filename or die "report: $!";
  chomp(my $line = <$fh> // '');
  my ($finished, $stmts, $delivered, $errors, $reconnects, $returned) = split /\t/, $line;
  is $finished, 1, 'the child finished its copy of the listen handle';
  is $stmts, 0, '... and started no statement on it';
  is $delivered, 0, '... delivered nothing';
  is "$errors/$reconnects", '0/0', '... and fired no listen hook';
  is $returned, 1, '... and its loop returned by itself: the guard that fired does not keep it running';

  is $mdb->finished, 0, 'the parent\'s handle was not finished';
  is scalar(@{ $mdb->{started} }), $started, '... nothing else was started on it';
  $SERVER->insert(jobs => 'after-fork');
  $mdb->release;
  ok drive(sub { @got }), 'the parent still delivers';
  is refaddr(listen_mdb($s)), refaddr($mdb), '... on the same handle';
  is $s->{spy}{reconnects}, 0, '... without a rebuild';
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 14. The backoff timer: core has no loop, so _listen_delay must resolve FROM
#     the EV loop -- a delay resolved synchronously would turn a persistent
#     outage into unbounded recursion -- and core cancels it when a forced
#     reconnect cuts the wait short, which must stop the timer.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  my $f = $s->_listen_delay(0);
  ok !$f->is_ready, '_listen_delay(0) is pending on return';
  ok drive(sub { $f->is_ready }), '... and resolves from the loop';
  ok $f->is_done, '... successfully';

  my $g = $s->_listen_delay(0.01);
  $g->cancel;
  settle(0.05);
  ok $g->is_cancelled, 'a cancelled delay stays cancelled (its timer was stopped)';
}

# ---------------------------------------------------------------------------
# 15. connect_info with only a listen connection open (karr k65, core k90).
#     The listen connection was opened with the old connect info; the setter
#     closes it like core's does -- also when no pool was ever built -- and the
#     new connect info is what the next listen opens with, a broker change
#     included.
# ---------------------------------------------------------------------------

{
  my $s = fresh();
  await($s->listen(jobs => sub { }));
  my $old = listen_mdb($s);
  ok !defined $s->{pool}, 'a listen connection is open and no pool was built';
  is $old->{args}{user}, 'u', '... opened with the first connect info';

  $s->connect_info([ { host => 'fakehost', database => 'listen_test', user => 'u2', password => 'p2', pool_size => 1 } ]);
  ok $old->finished, 'connect_info closed the old listen connection';
  ok !$s->{_listen}, '... and dropped the listen state';

  await($s->listen(jobs => sub { }));
  is listen_mdb($s)->{args}{user}, 'u2', 'the next listen opens with the new connect info';
  await($s->unlisten('jobs'));

  my $broker = RotatingBroker->new;
  $broker->{gen} = 'X';
  $s->connect_info([$broker]);
  await($s->listen(jobs => sub { }));
  my $static = listen_mdb($s);
  is $static->{args}{user}, 'user-X', 'a broker set on a listening storage is the one asked';
  $s->connect_info([ { host => 'fakehost', database => 'listen_test', user => 'u3', password => 'p3', pool_size => 1 } ]);
  ok $static->finished, 'switching back from the broker closes the listen connection too';
  await($s->listen(jobs => sub { }));
  is listen_mdb($s)->{args}{user}, 'u3', '... and the static connect info applies';
  await($s->unlisten('jobs'));
}

# ---------------------------------------------------------------------------
# 16. Connect info with neither a host nor a user (karr k66): EV::MariaDB would
#     start no connect and call back nothing, the listen Future never settling.
#     Refused at once, naming keys only, and no handle is made.
# ---------------------------------------------------------------------------

{
  my $s = fresh(info => [ { database => 'listen_test', password => 'topsecret', pool_size => 1 } ]);
  my $f = eval { $s->_listen_open };
  ok !$f, '_listen_open refuses connect info without host and user';
  like $@, qr/cannot connect from the connect info.*host or a user/s, '... saying why';
  unlike $@, qr/topsecret/, '... without quoting the password';
  is $FakeMDB::MADE, 0, '... and no handle was made';

  $s->listen(jobs => sub { });
  ok drive(sub { @{ $s->{spy}{errors} } }), 'listen reports it instead of waiting for ever';
  like $s->{spy}{errors}[0], qr/host or a user/, '... the same reason';
  is $FakeMDB::MADE, 0, '... still no handle';
}

is_deeply \@VIOLATIONS, [], 'no operation overlapped another anywhere in this file';

done_testing;
