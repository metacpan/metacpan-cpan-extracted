use strict;
use warnings;
use Test::More;

# OFFLINE, karr k87: a txn_do coderef that RETURNS the Future of a call on the
# STORAGE -- `$storage->txn_do(sub { $storage->select_async(...) })` -- with a
# pool of one.
#
# WHY it is its own file: it is the one case DBIO::PostgreSQL::EV::Future's
# blocking-wait refusals (karr k71, k85, k86) cannot see by themselves. The call
# is queued for the connection the transaction holds; the transaction waits for
# the Future of that call before it sends COMMIT. Neither can go first. This is
# no blocking wait for a queued caller inside a callback: the coderef returns,
# and core (DBIO::Storage::Async::txn_do_async) chains the returned Future with
# `->then`. Only core sees the Future the coderef returned; since core k334 it
# asks the driver (_txn_inner_future), and DBIO::PostgreSQL::EV::Storage answers
# by _refuse_queued: the queued call is taken out of the pool's queue and
# failed, so the coderef's Future fails, the transaction rolls back and txn_do
# dies with the refusal.
#
# What this file holds:
#   1. top level, pool of one: txn_do dies with the refusal; the wire holds
#      BEGIN ROLLBACK, the refused call never ran, the pool is idle and the
#      next query runs.
#   2. in a then callback of another connection, pool of two: the same, and
#      the wait does not hang.
#   3. the legitimate case, a call on $ctx returned: untouched, BEGIN .. COMMIT.
#
# THE ONE SUBSTITUTION is EV::Pg itself, the stand-in of t/56.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();
  use Socket ();

  my $ID = 0;

  our $SLOW = 0.1;   # seconds until a statement named slow* is answered

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      id         => ++$ID,
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      queue      => [],   # sent, callback not returned yet (EV::Pg's cb queue)
      busy       => 0,    # libpq has a command in progress
      wire       => [],   # what was sent, in order: a statement's name or verb
    }, $class;
    socketpair($self->{sock}, $self->{server}, Socket::AF_UNIX(), Socket::SOCK_STREAM(), Socket::PF_UNSPEC())
      or die "socketpair: $!";
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{up} = 1;
      # start_reading: active from now on. The server never writes here.
      $weak->{rio} = EV::io(fileno $weak->{sock}, EV::READ(), sub { });
      $weak->_idle_ref;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  # update_idle_ref: the read watcher keeps the loop alive while callbacks are
  # queued, and only then.
  sub _idle_ref {
    my ($self) = @_;
    $self->{rio}->keepalive(@{ $self->{queue} } ? 1 : 0) if $self->{rio};
    return;
  }

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { $_[0]{up} ? fileno $_[0]{sock} : -1 }
  sub result_meta   { $_[0]{meta} }

  # A SELECT is named by its last bind value, anything else by its verb.
  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};   # REQUIRE_CONN
    die "PQsendQueryParams failed: another command is already in progress\n"
      if $self->{busy};
    my ($verb) = $sql =~ /^(\w+)/;
    my $name = $verb eq 'SELECT' && @$bind ? $bind->[-1] : $verb;
    push @{ $self->{wire} }, $name;
    push @{ $self->{queue} }, { verb => $verb, name => $name, cb => $cb };
    $self->{busy} = 1;
    $self->_idle_ref;
    $self->_arm;
    return;
  }

  # cancel_pending, then cleanup_connection: no on_error.
  sub finish {
    my ($self) = @_;
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, 'connection finished'); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    delete $self->{rio};
    $self->{up}   = 0;
    $self->{busy} = 0;
    return;
  }

  sub _arm {
    my ($self) = @_;
    return if $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    my ($next) = grep { !$self->{delivering} || $_ != $self->{delivering} } @{ $self->{queue} };
    my $after  = $next && $next->{name} =~ /^slow/ ? $SLOW : 0.001;
    $self->{timer} = EV::timer($after, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    my $head = $self->{queue}[0] or return;

    my @result = $head->{verb} eq 'SELECT' ? ([ [ 'row-of', $head->{name} ] ]) : ('');
    $self->{meta} = { cmd_status => $head->{verb} };
    $self->{busy} = 0;
    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    # advance_cb_queue: only now is the callback off the queue.
    shift @{ $self->{queue} } if @{ $self->{queue} } && $self->{queue}[0] == $head;
    $self->_idle_ref;
    $self->_arm;
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use Scalar::Util ();
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;

alarm 60;

my $LIMIT = 1;
my $EVF   = 'DBIO::PostgreSQL::EV::Future';

# 3: the refusal, and what it tells the caller to do instead.
my $REFUSED = qr/\ABlocking wait refused: /;
my $ADVICE  = qr/\*_async.*->then.*\$ctx->select_async.*pool_size/s;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my @STORAGES;
sub build_storage {
  my ($size) = @_;
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => $size }, {} ]);
  push @STORAGES, $storage;
  Scalar::Util::weaken($STORAGES[-1]);
  return $storage;
}

sub conns  { @{ $_[0]->pool->{_connections} } }
sub queued { scalar @{ $_[0]->pool->{_waiters} } }
sub wire   { [ @{ $_[0]{wire} } ] }

my @COLS = qw( tag name );
sub select_named       { $_[0]->select_async('thing', \@COLS, { name => $_[1] }) }
sub select_named_block { $_[0]->select('thing', \@COLS, { name => $_[1] }) }

# Run $code under the watchdog. Answers ok / error / result, and hung: the wait
# was still blocked after $LIMIT seconds, and the watchdog failed every caller
# queued for a connection to get it out.
sub bounded {
  my ($code) = @_;
  my $hung = 0;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer($LIMIT, 0, sub {
    $hung = 1;
    for my $storage (grep { defined } @STORAGES) {
      my $pool = $storage->{pool} or next;
      $_->fail("watchdog: still blocked after ${LIMIT}s\n")
        for grep { !$_->is_ready } splice @{ $pool->{_waiters} };
    }
  });
  $dog->keepalive(0);
  my @r;
  my $ok = eval { @r = $code->(); 1 };
  return { ok => $ok, error => $ok ? '' : "$@", result => \@r, hung => $hung };
}

# Let every timer the fake still has run out.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub nothing_warned {
  my ($label) = @_;
  is_deeply \@warnings, [], "$label: no callback died out of EV::Pg, nothing warned";
  @warnings = ();
}


sub txn_returning_queued_call {
  my ($storage) = @_;
  return sub { $storage->txn_do(sub { select_named($storage, 'inner') }) };
}

# --- 1. top level, pool of one ---------------------------------------------------

{
  my $label   = 'k87, top level, pool of one';
  my $storage = build_storage(1);
  my $r = bounded(txn_returning_queued_call($storage));
  settle();
  my ($conn) = conns($storage);

  ok !$r->{hung}, "$label: it does not hang";
  ok !$r->{ok}, "$label: txn_do dies";
  like $r->{error}, $REFUSED, "$label: with the refusal of the queued call";
  like $r->{error}, $ADVICE, "$label: which names the *_async / \$ctx way out";
  is_deeply wire($conn), [qw( BEGIN ROLLBACK )],
    "$label: the transaction was rolled back, and the refused call never ran";
  is $storage->pool->available, 1, "$label: the pool is idle";
  is queued($storage), 0, "$label: nobody is queued";

  my $next = bounded(sub { select_named_block($storage, 'next') });
  settle();
  ok $next->{ok}, "$label: the next query runs" or diag $next->{error};
  is_deeply wire($conn), [qw( BEGIN ROLLBACK next )], "$label: on the connection that was freed";
  nothing_warned($label);
}

# --- 2. in a then callback of another connection, pool of two ---------------------

{
  my $label   = 'k87, in a then callback of another connection, pool of two';
  my $storage = build_storage(2);
  my %seen;
  my $r = bounded(sub {
    select_named($storage, 'outer')->then(sub {
      my $ok = eval { txn_returning_queued_call($storage)->(); 1 };
      $seen{error} = $ok ? 'it returned' : "$@";
      return $EVF->done('outer');
    })->get;
  });
  settle();

  ok !$r->{hung}, "$label: the wait is refused instead of hanging";
  ok $r->{ok}, "$label: the outer call completes" or diag $r->{error};
  like $seen{error}, $REFUSED, "$label: txn_do dies with the refusal";
  is_deeply [ map { wire($_) } conns($storage) ], [ ['outer'], [qw( BEGIN ROLLBACK )] ],
    "$label: the transaction is rolled back, and the refused call never ran";
  is $storage->pool->available, 2, "$label: the pool is idle";
  is queued($storage), 0, "$label: nobody is queued";
  nothing_warned($label);
}

# --- 3. the legitimate case: the Future of a call on $ctx ------------------------

{
  my $label   = 'k87, the coderef returns a call on $ctx, pool of one';
  my $storage = build_storage(1);
  my $r = bounded(sub {
    $storage->txn_do(sub { $_[0]->select_async('thing', \@COLS, { name => 'ctx' }) });
  });
  settle();
  my ($conn) = conns($storage);

  ok $r->{ok}, "$label: the transaction commits" or diag $r->{error};
  is_deeply wire($conn), [qw( BEGIN ctx COMMIT )], "$label: BEGIN, the statement, COMMIT";
  is $storage->pool->available, 1, "$label: the pool is idle";
  nothing_warned($label);
}

done_testing;
