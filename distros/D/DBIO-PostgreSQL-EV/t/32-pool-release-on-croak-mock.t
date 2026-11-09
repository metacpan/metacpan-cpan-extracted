use strict;
use warnings;
use Test::More;

# OFFLINE regression for karr k46: a pooled call whose EV::Pg dispatch croaks
# still gives its connection back to the pool.
#
# WHY: _dispatch_query, _dispatch_notify and copy_in release their pooled
# connection only from the callback they hand to EV::Pg. EV::Pg croaks
# synchronously BEFORE it queues that callback (Pg.xs: REQUIRE_CONN, then
# PQsend*, then push_cb) -- "not connected" on a connection it has lost,
# "PQsendQueryParams failed: another command is already in progress" on a busy
# one -- so the callback never runs and nothing released the connection. The
# call failed, and its connection stayed checked out for good: with a pool of
# N, N such failures and every later call waits forever for a connection
# (measured live at HEAD before the fix, see the card).
#
# COPY has a second way to get there. When EV::Pg loses the connection inside
# put_copy_data (its flush fails), it drops the COPY callback without a second
# firing; the next put croaks "not connected", and so does put_copy_end, from
# inside the first firing -- EV::Pg swallows that die with a warning, and the
# COPY Future never settled.
#
# What this file claims, for each way to die:
#   a. the call fails with the error it died with, unchanged -- releasing does
#      not swallow or replace it (for COPY: the coderef's own error when the
#      coderef died, as t/18 requires);
#   b. the connection is back in the pool at once, and only once: nothing is
#      left checked out, and a pool of one does not list its one handle twice
#      (which would hand it to two callers);
#   c. the next acquire on that pool of one resolves; where the connection is
#      still healthy, the next call completes on it;
#   d. no callback of this transport dies out of EV::Pg.
#
# Since the pool resets a session when a borrow ends (core k398), a connection is
# back in the pool once its reset (DISCARD ALL and the connect actions) has been
# answered, not at the moment of the release: the checks of b and c wait for
# that answer (settle).
#
# Without the fix a, b and c fail: nothing is idle, and the next call waits for
# a connection nobody returns. That wait is bounded -- the EV Future dies when
# nothing left in the loop could settle it (karr k44), and a keepalive(0)
# watchdog fails it should something keep the loop alive -- so the regression
# shows as a failure, not a hang.
#
# CroakPg stands in for EV::Pg 0.07, in the order Pg.xs does things: connect
# completes on an EV timer; query / query_params croak (once, when armed)
# before queueing the callback; each queued callback completes on an EV timer,
# counted as pending until it has returned and called under an eval that only
# warns, as EV::Pg's CALL_SV_GUARDED does; COPY fires its callback twice
# (COPY_IN, then the command tag after put_copy_end); losing the connection
# drops the callback being delivered without firing it and makes every later
# call croak "not connected".

use EV;
use DBIO::PostgreSQL::EV::Storage;
use DBIO::PostgreSQL::EV::Pool;

{
  package CroakPg;
  use Carp ();
  use Scalar::Util ();

  # op => message: the next call of that op croaks with it, once.
  our %CROAK;

  # n: the n-th put_copy_data of the next COPY loses the connection, as
  # EV::Pg's check_flush does when the flush after PQputCopyData fails.
  our $LOSE_AT_PUT;

  sub new {
    my ($class, %args) = @_;
    my $self = bless { %args, up => 0, queue => [], puts => 0, rows => 0 }, $class;
    Scalar::Util::weaken(my $weak = $self);
    _later(sub {
      return unless $weak;
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub _later {
    my ($cb) = @_;
    my $t;
    $t = EV::timer(0.001, 0, sub { undef $t; $cb->() });
    return;
  }

  sub is_connected  { $_[0]{up} }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub finish        { $_[0]{up} = 0; $_[0]{queue} = []; return }

  # EV::Pg's croaks: REQUIRE_CONN first, then the armed PQsend* failure, whose
  # message ends in PQerrorMessage's newline and so carries no location.
  sub _croak_for {
    my ($self, $op) = @_;
    Carp::croak('not connected') unless $self->{up};
    my $msg = delete $CROAK{$op};
    return unless defined $msg;
    die $msg if $msg =~ /\n\z/;
    Carp::croak($msg);
  }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    $self->_croak_for('query_params');
    push @{ $self->{queue} }, { sql => $sql, cb => $cb };
    $self->_arm;
    return;
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    $self->_croak_for('query');
    my $copy = $sql =~ /^COPY /;
    $self->{rows} = 0 if $copy;
    push @{ $self->{queue} }, { sql => $sql, cb => $cb, copy => $copy };
    $self->_arm;
    return;
  }

  sub put_copy_data {
    my ($self, $line) = @_;
    Carp::croak('not connected') unless $self->{up};
    $self->{rows}++;
    $self->_lose if defined $LOSE_AT_PUT && ++$self->{puts} == $LOSE_AT_PUT;
    return 1;
  }

  sub put_copy_end {
    my ($self, $abort) = @_;
    Carp::croak('not connected') unless $self->{up};
    $self->{queue}[0]{ended} = defined $abort ? "ERROR:  COPY from stdin failed: $abort" : '';
    $self->_arm;
    return 1;
  }

  # handle_conn_loss: on_error, the connection is gone, and cancel_pending
  # drops the callback being delivered without firing it.
  sub _lose {
    my $self = shift;
    $self->{up} = 0;
    $self->{on_error}->("server closed the connection unexpectedly\n") if $self->{on_error};
    my @queue = @{ $self->{queue} };
    $self->{queue} = [];
    for my $entry (@queue) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, 'connection lost'); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    return;
  }

  sub _arm {
    my $self = shift;
    return if $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my $self = shift;
    delete $self->{timer};
    my $head = $self->{queue}[0] or return;

    my @result;
    if ($head->{copy} && !$head->{started}) {
      $head->{started} = 1;
      @result = ('COPY_IN');
    }
    elsif ($head->{copy}) {
      return unless defined $head->{ended};   # the server waits for COPY data
      @result = length $head->{ended} ? (undef, "$head->{ended}\n") : ("$self->{rows}");
    }
    else {
      @result = $head->{sql} =~ /^SELECT/ ? ([ [ 1, 'one' ] ]) : ('1');
    }

    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};

    # Advanced only after the callback returned -- unless it was dropped
    # meanwhile, or it is a COPY's first firing, which stays at the head.
    if (@{ $self->{queue} } && $self->{queue}[0] == $head) {
      shift @{ $self->{queue} } unless $head->{copy} && $result[0] && $result[0] eq 'COPY_IN';
    }
    $self->_arm;
    return;
  }
}

# The real pool builds its handles through this seam (t/04).
{
  no warnings 'redefine';
  *DBIO::PostgreSQL::EV::Pool::_new_connection = sub { shift; CroakPg->new(@_) };
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# A real storage and pool over CroakPg, with a pool of one.
sub pool_of_one {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 }, {} ]);
  return $storage;
}

# Wait for $f on the EV loop: (1, @result) once it is done, (0, $error) once it
# failed. A Future still pending after 5 seconds is failed by the watchdog.
sub wait_for {
  my ($f) = @_;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $dog = EV::timer(5, 0, sub { $f->fail("watchdog: still pending after 5s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

# Let every timer CroakPg still has run out, so a callback that would fire
# late -- and release a second time -- has fired before the pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

# Spawn the pool's one connection and wait until it is up.
sub warm {
  my ($storage) = @_;
  my ($up) = wait_for($storage->select_async('thing', [qw( id name )], {}));
  return $up;
}

sub the_call_fails {
  my ($label, $f, $error) = @_;
  my ($ok, @r) = wait_for($f);
  ok !$ok, "$label: the call fails";
  like $r[0], $error, "$label: with the error it died with";
  settle();
}

# A connection that is still healthy after the croak: it is back once, and the
# next call gets it and completes.
sub released_after_croak {
  my ($label, $storage, $fails, $error, $next, $expect) = @_;

  the_call_fails($label, $fails->(), $error);   # settles: the reset is answered
  is $storage->pool->available, 1, "$label: its connection is back in the pool, once";
  is $storage->pool->size, 1, "$label: the pool still has its one connection";

  my ($ok, @r) = wait_for($next->());
  ok $ok, "$label: the next call on the pool of one gets the connection"
    or diag "it failed: $r[0]";
  is_deeply \@r, $expect, "$label: and completes";
  settle();   # its reset is answered
  is $storage->pool->available, 1, "$label: which it gives back";
  no_callback_died($label);
}

# A connection EV::Pg has lost: nothing is left checked out, and the next
# acquire resolves. (Since karr k49 the lost connection is also retired rather
# than handed out again, and the next acquire spawns a fresh one --
# t/41-pool-retire-dead-mock.t pins that; this file is about the slot.)
sub nothing_checked_out_after_loss {
  my ($label, $storage, $f, $error) = @_;

  the_call_fails($label, $f, $error);
  my $pool = $storage->pool;
  is $pool->available, $pool->size, "$label: nothing is left checked out";
  cmp_ok $pool->available, '<=', 1, "$label: and the connection is not listed twice";

  my ($ok, @r) = wait_for($pool->acquire);
  ok $ok, "$label: the next acquire on the pool of one resolves"
    or diag "it failed: $r[0]";
  $pool->release($r[0]) if $ok;
  no_callback_died($label);
}

my $BUSY_PARAMS = "PQsendQueryParams failed: another command is already in progress\n";
my $BUSY_QUERY  = "PQsendQuery failed: another command is already in progress\n";
my @SELECT      = ('thing', [qw( id name )], {});

# --- _dispatch_query: query_params croaks ---------------------------------------

{
  my $storage = pool_of_one();
  released_after_croak(
    'select_async, query_params croaks',
    $storage,
    sub {
      $CroakPg::CROAK{query_params} = $BUSY_PARAMS;
      $storage->select_async(@SELECT);
    },
    qr/^\Q$BUSY_PARAMS\E\z/,
    sub { $storage->select_async(@SELECT) },
    [ [ 1, 'one' ] ],
  );
}

{
  my $storage = pool_of_one();
  ok warm($storage), 'select_async: the connection is up';
  # Lost while checked out, with a caller queued for the connection. The
  # release no longer hands the handle on as it is: the pool resets it first
  # (core k398), the reset of a lost connection fails, the handle is retired
  # and the queued caller gets a fresh connection. A lost handle never reaches
  # the dispatch of the next borrower. (Lost while idle, the pool does not hand
  # it out at all, karr k72, t/57-idle-liveness-mock.t.)
  my ($held, $pg) = wait_for($storage->pool->acquire);
  die "acquiring the pool's connection failed: $pg" unless $held;
  my $queued = $storage->select_async(@SELECT);
  ok !$queued->is_ready, 'select_async on a lost connection: (the call is queued for the connection)';
  $pg->_lose;
  $storage->pool->release($pg);
  my ($ok, @r) = wait_for($queued);
  ok $ok, 'select_async on a lost connection: the queued call is served by a fresh connection'
    or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 1, 'one' ] ], 'select_async on a lost connection: and completes';
  settle();
  my $pool = $storage->pool;
  is $pool->available, $pool->size, 'select_async on a lost connection: nothing is left checked out';
  cmp_ok $pool->available, '<=', 1, 'select_async on a lost connection: and the connection is not listed twice';
  no_callback_died('select_async on a lost connection');
}

# --- _dispatch_notify: query_params croaks --------------------------------------

{
  my $storage = pool_of_one();
  released_after_croak(
    'notify, query_params croaks',
    $storage,
    sub {
      $CroakPg::CROAK{query_params} = $BUSY_PARAMS;
      $storage->notify('chan', 'payload');
    },
    qr/^\Q$BUSY_PARAMS\E\z/,
    sub { $storage->notify('chan', 'payload') },
    [],
  );
}

# --- copy_in: the COPY query croaks ---------------------------------------------

my $two_rows = sub {
  my ($put) = @_;
  $put->([ 1, 'a' ]);
  $put->([ 2, 'b' ]);
};

{
  my $storage = pool_of_one();
  released_after_croak(
    'copy_in, the COPY query croaks',
    $storage,
    sub {
      $CroakPg::CROAK{query} = $BUSY_QUERY;
      $storage->copy_in('thing', [qw( id name )], $two_rows);
    },
    qr/^\Q$BUSY_QUERY\E\z/,
    sub { $storage->copy_in('thing', [qw( id name )], $two_rows) },
    [ 2 ],
  );
}

# --- copy_in: the connection is lost inside put_copy_data -----------------------
#
# The coderef's next put croaks "not connected"; here the coderef dies with its
# own error, which is what copy_in must fail with. put_copy_end croaks too, from
# inside the COPY_IN firing.

{
  my $storage = pool_of_one();
  ok warm($storage), 'copy_in: the connection is up';
  local $CroakPg::LOSE_AT_PUT = 2;
  nothing_checked_out_after_loss(
    'copy_in, connection lost, the coderef dies',
    $storage,
    $storage->copy_in('thing', [qw( id name )], sub {
      my ($put) = @_;
      $put->([ $_, 'row' ]) for 1 .. 2;
      eval { $put->([ 3, 'row' ]); 1 } or die "coderef gave up: $@";
    }),
    qr/^coderef gave up: not connected\n\z/,
  );
}

# The same, but the loss comes with the coderef's last put: the coderef returns,
# and put_copy_end is the first to croak.

{
  my $storage = pool_of_one();
  ok warm($storage), 'copy_in: the connection is up';
  local $CroakPg::LOSE_AT_PUT = 2;
  nothing_checked_out_after_loss(
    'copy_in, connection lost on the last put',
    $storage,
    $storage->copy_in('thing', [qw( id name )], $two_rows),
    qr/^not connected\n\z/,
  );
}

done_testing;
