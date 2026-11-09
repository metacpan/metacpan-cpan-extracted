use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );

# OFFLINE regression for karr k51: notify and copy_in settle their Future
# before they give the pooled connection back, as select_async does.
#
# WHY: _dispatch_query's completion callback settles the Future first and
# releases the connection after that (karr k44 / k50), so a then callback on
# the Future runs while the connection is still checked out: a call it makes
# gets another connection, never the one whose result EV::Pg is still
# delivering (DBIO::PostgreSQL::EV::Future/await). _dispatch_notify and copy_in
# did it the other way round -- release, then settle. A then callback on their
# Futures found the connection back in the pool, a call it made could get
# exactly that connection, and a blocking wait on that call was refused
# ("Blocking wait refused"): EV::Pg was still delivering the NOTIFY's or the
# COPY's result on it.
#
# What this file claims, for notify and for every way copy_in settles from
# inside an EV::Pg callback -- the COPY done, the server's error at its end, a
# dying coderef, the COPY refused by the server, the connection lost in the
# data phase (the coderef dying of it, or put_copy_end croaking), put_copy_end
# failing (with and without a dying coderef) -- on a warm pool, where the
# Future the call returns is the one the callback settles, and on a cold one,
# where it is the acquire chain's ->then, which follows that one:
#   a. a then callback on the Future runs while the connection is still
#      checked out, and the call settles with its own result or error;
#   b. afterwards the connection is back in the pool once -- or retired, where
#      EV::Pg lost it or the COPY's stream could not be ended (karr k65) --
#      and the next call on the pool of one completes;
#   c. a blocking call in such a then callback gets the other connection, not
#      the one being delivered, and completes instead of being refused;
# and the karr k50 property the order has to keep, green before and after:
#   d. an on_done, on_ready or on_fail on the Future that dies does not skip
#      the release: the call keeps its result or error, the connection is back
#      once (or retired), the die still reaches EV::Pg, once, and the next call
#      on the pool of one completes.
#
# Before the fix a fails on every path -- the connection is already idle, or
# already retired -- and c fails with "Blocking wait refused". The dispatch
# croak, where EV::Pg never queues the callback and nobody can have chained
# on the Future yet, releases and then fails the Future, as _dispatch_query
# does; t/32 covers it.
#
# karr k65 REPLACED two claims here rather than preserving them. A COPY whose
# put_copy_end failed was claimed to give its connection back to the pool, and
# the next call to complete on it. That held only because the fake dropped the
# COPY's callback and left the handle usable. EV::Pg does neither -- Pg.xs
# put_copy_end hands on PQputCopyEnd's -1 and nothing else -- and libpq is
# still in the COPY, so the next statement was refused: "another command is
# already in progress". The fake now follows Pg.xs there, the connection is
# retired, and the next call completes on a fresh one. And such a COPY whose
# coderef had died was claimed to fail with "put_copy_end failed"; it fails
# with the coderef's own error, as copy_in's POD has said all along. What a
# COPY's end does to its connection is claimed in full in t/73.
#
# THE ONE SUBSTITUTION is EV::Pg itself (as in t/41): a fake that the real
# pool builds through its real constructor, so the pool's own on_error retires
# a lost connection. It follows Pg.xs, 0.02 and 0.07 alike: the connect
# completes on an EV timer; a dispatch croaks "not connected" on a handle that
# is not connected; each queued callback completes on an EV timer, counts as
# pending until it has returned, and is called under an eval that only warns;
# COPY fires its callback twice. A lost connection is handle_conn_loss: the
# handle is torn down, on_error is called, then every queued callback but the
# one being delivered gets (undef, "connection lost").

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our %NEXT;            # fail => $err: the next statement to complete ends
                        # with this server error, once
  our $LOSE_AT_PUT;     # n: the n-th put_copy_data of the next COPY loses the
                        # connection, once
  our $END_RC;          # the next put_copy_end returns this, once, and does
                        # no more: PQputCopyEnd failed, the COPY's callback
                        # stays queued and libpq in the COPY (Pg.xs)
  our $LAST_SENT;       # the handle the last statement was sent on (weak)

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      queue      => [],
      rows       => 0,
      puts       => 0,
    }, $class;
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { -1 }
  sub error_message { $_[0]{up} ? $_[0]{errmsg} : undef }

  sub _send {
    my ($self, $entry) = @_;
    Carp::croak('not connected') unless $self->{up};
    # PQsendQuery on a connection libpq still has a COPY open on
    Carp::croak("PQsendQueryParams failed: another command is already in progress\n")
      if $self->{in_copy};
    push @{ $self->{queue} }, $entry;
    Scalar::Util::weaken($LAST_SENT = $self);
    $self->_arm;
    return;
  }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    return $self->_send({ sql => $sql, cb => $cb });
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    my $copy = $sql =~ /^COPY /;
    if ($copy) { $self->{rows} = 0; $self->{puts} = 0 }
    return $self->_send({ sql => $sql, cb => $cb, copy => $copy });
  }

  sub put_copy_data {
    my ($self) = @_;
    Carp::croak('not connected') unless $self->{up};
    $self->{rows}++;
    if (defined $LOSE_AT_PUT && ++$self->{puts} == $LOSE_AT_PUT) {
      undef $LOSE_AT_PUT;
      $self->t_lose("server closed the connection unexpectedly\n");
    }
    return 1;
  }

  sub put_copy_end {
    my ($self, $abort) = @_;
    Carp::croak('not connected') unless $self->{up};
    if (defined(my $rc = $END_RC)) {
      undef $END_RC;
      $self->{errmsg} = "cannot allocate memory for output buffer\n";
      return $rc;
    }
    $self->{in_copy} = 0;
    $self->{queue}[0]{ended} = defined $abort ? "ERROR:  COPY from stdin failed: $abort" : '';
    $self->_arm;
    return 1;
  }

  sub finish {
    my ($self) = @_;
    $self->_cancel_pending('connection finished');
    $self->{up}      = 0;
    $self->{in_copy} = 0;
    return;
  }

  sub _cancel_pending {
    my ($self, $msg) = @_;
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, $msg); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    return;
  }

  # handle_conn_loss: torn down, on_error, then every queued callback with
  # "connection lost".
  sub t_lose {
    my ($self, $msg) = @_;
    $self->{up} = 0;
    $self->{on_error}->($msg) if $self->{on_error};
    $self->_cancel_pending('connection lost');
    return;
  }

  sub _arm {
    my ($self) = @_;
    return if $self->{timer} || !@{ $self->{queue} };
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    my $head = $self->{queue}[0] or return;

    my @result;
    if ($head->{copy} && $head->{started} && !defined $head->{ended}) {
      return;   # the server waits for COPY data
    }
    elsif (defined(my $err = delete $NEXT{fail})) {
      @result = (undef, $err);
    }
    elsif ($head->{copy} && !$head->{started}) {
      $head->{started} = 1;
      $self->{in_copy} = 1;
      @result = ('COPY_IN');
    }
    elsif ($head->{copy}) {
      @result = length $head->{ended} ? (undef, "$head->{ended}\n") : ("$self->{rows}");
    }
    else {
      @result = ([ [ 1, 'one' ] ]);
    }

    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};

    # Advanced only after the callback returned -- unless it was dropped
    # meanwhile, or it is a COPY's first firing, which stays at the head.
    if (@{ $self->{queue} } && $self->{queue}[0] == $head) {
      shift @{ $self->{queue} }
        unless $head->{copy} && defined $result[0] && $result[0] eq 'COPY_IN';
    }
    $self->_arm;
    return;
  }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;
use DBIO::PostgreSQL::EV::Future;

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF    = 'DBIO::PostgreSQL::EV::Future';
my @SELECT = ('thing', [qw( id name )], {});

my $SERVER_ERROR = qq{ERROR:  relation "thing" does not exist\n};
my $DATA_ERROR   = qq{ERROR:  invalid input syntax for type integer: "x"\n};

my $two_rows = sub {
  my ($put) = @_;
  $put->([ 1, 'a' ]);
  $put->([ 2, 'b' ]);
};
my $dies = sub {
  my ($put) = @_;
  $put->([ 1, 'a' ]);
  die "coderef died\n";
};

sub notify { $_[0]->notify('chan', 'payload') }

sub copy_in {
  my ($coderef) = @_;
  return sub { $_[0]->copy_in('thing', [qw( id name )], $coderef) };
}

# Each way the call settles from inside an EV::Pg callback: what to arm before
# the call, the call, and what it settles with -- expect (done) or error
# (fail). lost: EV::Pg loses the connection, and the pool retires it. unusable:
# the connection is open but stuck in the COPY, and the pool retires it too.
my @PATHS = (
  { label  => 'notify',
    call   => \&notify,
    expect => [] },
  { label  => 'notify, server error',
    arm    => sub { $EV::Pg::NEXT{fail} = $SERVER_ERROR },
    call   => \&notify,
    error  => qr/^\Q$SERVER_ERROR\E\z/ },
  { label  => 'copy_in',
    call   => copy_in($two_rows),
    expect => [ 2 ] },
  { label  => 'copy_in, the server fails it at the end',
    call   => copy_in(sub { $two_rows->(@_); $EV::Pg::NEXT{fail} = $DATA_ERROR }),
    error  => qr/^\QERROR:  invalid input syntax for type integer: "***"\E\n\z/ },   # the server's text, its value masked
  { label  => 'copy_in, the coderef dies',
    call   => copy_in($dies),
    error  => qr/^coderef died\n\z/ },
  { label  => 'copy_in, the server refuses the COPY',
    arm    => sub { $EV::Pg::NEXT{fail} = $SERVER_ERROR },
    call   => copy_in($two_rows),
    error  => qr/^\Q$SERVER_ERROR\E\z/ },
  { label  => 'copy_in, lost in the data phase, the coderef dies of it',
    arm    => sub { $EV::Pg::LOSE_AT_PUT = 2 },
    call   => copy_in(sub {
      my ($put) = @_;
      $put->([ $_, 'row' ]) for 1 .. 2;
      eval { $put->([ 3, 'row' ]); 1 } or die "coderef gave up: $@";
    }),
    error  => qr/^coderef gave up: not connected\n\z/,
    lost   => 1 },
  { label  => 'copy_in, lost on the last put',
    arm    => sub { $EV::Pg::LOSE_AT_PUT = 2 },
    call   => copy_in($two_rows),
    error  => qr/^not connected\n\z/,
    lost   => 1 },
  { label  => 'copy_in, put_copy_end fails',
    arm    => sub { $EV::Pg::END_RC = -1 },
    call   => copy_in($two_rows),
    error  => qr/^put_copy_end failed/,
    unusable => 1 },
  { label  => 'copy_in, the coderef dies, put_copy_end fails',
    arm    => sub { $EV::Pg::END_RC = -1 },
    call   => copy_in($dies),
    error  => qr/^coderef died\n\z/,
    unusable => 1 },
);

sub storage_of {
  my ($size) = @_;
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => $size }, {} ]);
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

# Let every timer the fake still has run out, so a callback that would fire
# late -- and release a second time -- has fired before the pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# Spawn the pool's one connection with a first call.
sub warm {
  my ($storage) = @_;
  my ($ok) = wait_for($storage->select_async(@SELECT));
  @warnings = ();
  return $ok;
}

sub no_callback_died {
  my ($label) = @_;
  my @died = grep { /exception in callback/ } @warnings;
  is scalar @died, 0, "$label: no callback died out of EV::Pg"
    or diag @died;
  @warnings = ();
}

sub settles_as {
  my ($label, $f, $p) = @_;
  my ($ok, @r) = wait_for($f);
  if ($p->{error}) {
    ok !$ok, "$label: the call fails";
    like $r[0], $p->{error}, "$label: with its own error";
  }
  else {
    ok $ok, "$label: the call resolves" or diag "it failed: $r[0]";
    is_deeply \@r, $p->{expect}, "$label: with its own result";
  }
}

sub released {
  my ($label, $storage, $p) = @_;
  my $pool = $storage->pool;
  if ($p->{lost} || $p->{unusable}) {
    my $which = $p->{lost} ? 'lost' : 'unusable';
    is $pool->size, 0, "$label: the $which connection is retired";
    is $pool->available, 0, "$label: and not listed idle";
  }
  else {
    is $pool->size, 1, "$label: the pool still has its one connection";
    is $pool->available, 1, "$label: which is back in the pool, once";
  }
}

sub next_completes {
  my ($label, $storage) = @_;
  my ($ok, @r) = wait_for($storage->select_async(@SELECT));
  ok $ok, "$label: the next call on the pool of one completes"
    or diag "it failed: $r[0]";
  is_deeply \@r, [ [ 1, 'one' ] ], "$label: with its rows";
  settle();
  is $storage->pool->available, 1, "$label: and gives the connection back";
}

# --- a, b: a then callback runs while the connection is still checked out ------

for my $warm (1, 0) {
  for my $p (@PATHS) {
    my $label   = ($warm ? 'warm' : 'cold') . ", $p->{label}";
    my $storage = storage_of(1);
    my $pool    = $storage->pool;
    ok warm($storage), "$label: the connection is up" if $warm;

    local $EV::Pg::NEXT{fail};
    local $EV::Pg::LOSE_AT_PUT;
    local $EV::Pg::END_RC;
    $p->{arm}->() if $p->{arm};

    my $checked_out;
    my $seen  = sub { $checked_out = $pool->size - $pool->available };
    my $chain = $p->{call}->($storage)->then(
      sub { $seen->(); return $EVF->done(@_) },
      sub { $seen->(); return $EVF->fail(@_) },
    );

    settles_as($label, $chain, $p);
    is $checked_out, 1,
      "$label: a then callback on it runs while its connection is still checked out";
    settle();
    released($label, $storage, $p);
    no_callback_died($label);
    next_completes($label, $storage);
    no_callback_died($label);
  }
}

# --- c: a blocking call in the then callback gets the other connection ----------
#
# A pool of two, one connection held by someone else: the call takes the other.
# In a then callback on the call's Future, a blocking select_async(...)->get
# must wait for the held one -- released from a timer while it waits -- rather
# than get the connection whose result EV::Pg is still delivering, which the
# k44 refusal turns down.

for my $p (grep { !$_->{arm} && !$_->{error} } @PATHS) {
  my $label   = "$p->{label}, blocking call in a then callback";
  my $storage = storage_of(2);
  my $pool    = $storage->pool;

  my ($up) = wait_for($EVF->needs_all(map { $storage->select_async(@SELECT) } 1 .. 2));
  ok $up && $pool->size == 2 && $pool->available == 2, "$label: both connections are up";
  my ($held_ok, $held) = wait_for($pool->acquire);
  ok $held_ok, "$label: one of them is held elsewhere";
  @warnings = ();

  my $sent_on;
  my $chain = $p->{call}->($storage)->then(sub {
    my $free = EV::timer(0.01, 0, sub { $pool->release($held) });
    my @rows = $storage->select_async(@SELECT)->get;
    $sent_on = $EV::Pg::LAST_SENT;
    return $EVF->done(\@rows);
  });

  my ($ok, @r) = wait_for($chain);
  ok $ok, "$label: completes" or diag "it failed: $r[0]";
  is_deeply $r[0], [ [ 1, 'one' ] ], "$label: with its rows";
  ok $sent_on && refaddr($sent_on) == refaddr($held),
    "$label: on the other connection, once that was free";
  settle();
  is $pool->available, 2, "$label: both connections are back in the pool";
  no_callback_died($label);
}

# --- d: a dying callback on the Future does not skip the release (karr k50) -----

for my $warm (1, 0) {
  for my $p (@PATHS) {
    for my $method ('on_ready', $p->{error} ? 'on_fail' : 'on_done') {
      my $label   = ($warm ? 'warm' : 'cold') . ", $p->{label}, its $method dies";
      my $storage = storage_of(1);
      ok warm($storage), "$label: the connection is up" if $warm;

      local $EV::Pg::NEXT{fail};
      local $EV::Pg::LOSE_AT_PUT;
      local $EV::Pg::END_RC;
      $p->{arm}->() if $p->{arm};

      my $f = $p->{call}->($storage);
      $f->$method(sub { die "$method died\n" });

      settles_as($label, $f, $p);
      settle();
      released($label, $storage, $p);

      my @died = grep { /exception in callback/ } @warnings;
      is scalar @died, 1, "$label: the die still reaches EV::Pg, once";
      like $died[0] // '', qr/: \Q$method\E died$/, "$label: unchanged";
      @warnings = ();

      next_completes($label, $storage);
      no_callback_died($label);
    }
  }
}

done_testing;
