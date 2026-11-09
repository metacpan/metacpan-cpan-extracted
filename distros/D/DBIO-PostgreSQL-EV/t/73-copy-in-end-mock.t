use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );

# OFFLINE regression for karr k65: how a COPY ends, and what becomes of its
# connection.
#
# WHY: copy_in knew one way to end a COPY -- settle the Future, put the
# connection back in the pool -- whatever state the connection was in, and it
# did not look at what its writes answered. Read at Pg.xs (0.02 and 0.07
# alike) and at libpq (fe-exec.c PQputCopyData / PQputCopyEnd, fe-misc.c
# pqSendSome), and measured against PostgreSQL 18.6 (t/74):
#   - put_copy_end answers -1 and nothing else happens: the COPY's callback
#     stays queued, and libpq is still in the COPY when it could not queue the
#     end. The connection went idle like that, and every statement of the next
#     caller was refused: "another command is already in progress";
#   - put_copy_data answers 0 when libpq could not take the row (its output
#     buffer cannot grow), -1 when it failed. The writer looked at neither: the
#     row was missing, and the COPY completed without it;
#   - a connection libpq has lost in such a write is lost to EV::Pg in the
#     flush of the next call -- put_copy_end's own, too. EV::Pg then drops the
#     callback it is delivering to without calling it again, put_copy_end
#     answers 1, and copy_in waited for an answer that could not come, its
#     connection checked out for good;
#   - when the coderef died and put_copy_end failed, the Future failed with
#     "put_copy_end failed" instead of the coderef's error.
#
# What this file claims:
#   1. a COPY whose stream could not be ended -- put_copy_end answered -1, or
#      lost the connection in its flush -- fails, and its connection is retired:
#      closed, not listed idle, no longer counted. The next call gets a fresh
#      connection and completes;
#   2. the Future fails with the coderef's own error when the coderef died,
#      whatever happened to the end of the stream after that;
#   3. a row the writer could not put fails the COPY: the writer dies, the
#      COPY is aborted, and the Future fails with that -- also when the coderef
#      catches the die and goes on;
#   4. no end leaves the Future pending: every wait here is bounded by a
#      watchdog, and alarm is the backstop;
#   5. a writer called outside its COPY dies, and puts nothing into the COPY
#      another caller has open on that connection by then;
#   6. nothing warns but the pool's report of a connection EV::Pg lost, and no
#      callback dies out of EV::Pg;
# and the controls, green before and after -- the fix must not throw healthy
# connections away:
#   7. a COPY that is done, one whose coderef dies, one the server refuses and
#      one the server fails at its end keep their connection: the next call
#      runs on it.
#
# THE ONE SUBSTITUTION is EV::Pg itself: a fake the real pool builds through
# its real constructor. It keeps libpq's state of the connection the way the
# sources read: async is what PQsendQuery, PQputCopyData and PQputCopyEnd ask
# (idle, busy, or in the COPY), ok is PQstatus, conn is whether EV::Pg still
# has the connection. A statement is refused unless libpq is idle; a COPY's
# callback is called with ("COPY_IN") and stays at the head of the queue until
# the server's answer; put_copy_end changes nothing but libpq's state and
# hands on what PQputCopyEnd answered; a flush on a connection libpq has
# dropped is handle_conn_loss -- on_error, the handle torn down, every queued
# callback but the one being delivered called with "connection lost"; finish
# calls every queued callback but that one with "connection finished".

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our @MADE;   # every handle made, in order (weak)
  our %ARM;    # what the next COPY meets, each once:
               #   put  => { n => 0 | -1 | 'lose' }  what its n-th put_copy_data
               #           does: answer 0, answer -1 with the connection dropped
               #           inside libpq, or take the row and lose the connection
               #           in the flush
               #   end  => 'stuck' | 'bad' | 'lost'  what its put_copy_end does:
               #           answer -1 with the COPY still open, answer -1 with
               #           the connection dropped inside libpq, or answer 1 and
               #           lose the connection in the flush
               #   fail => $error  the server's answer to the next statement
               #   errmsg => $text  libpq's reason for a 'stuck' put_copy_end

  my $GONE     = "server closed the connection unexpectedly\n";
  my $NO_MEMORY = "cannot allocate memory for output buffer\n";

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      conn       => 0,
      ok         => 1,
      async      => 'idle',
      queue      => [],
      stream     => [],
      puts       => 0,
      sent       => 0,
      finished   => 0,
    }, $class;
    push @MADE, $self;
    Scalar::Util::weaken($MADE[-1]);
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{conn} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected  { $_[0]{conn} && $_[0]{ok} ? 1 : 0 }
  sub pending_count { scalar @{ $_[0]{queue} } }
  sub socket        { -1 }
  sub error_message { $_[0]{conn} ? $_[0]{errmsg} : undef }

  sub _send {
    my ($self, $call, $entry) = @_;
    Carp::croak('not connected') unless $self->{conn};
    Carp::croak("$call failed: another command is already in progress\n")
      if $self->{async} ne 'idle';
    $self->{async} = 'busy';
    $self->{sent}++;
    push @{ $self->{queue} }, $entry;
    $self->_arm;
    return;
  }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    return $self->_send('PQsendQueryParams', { cb => $cb });
  }

  sub query {
    my ($self, $sql, $cb) = @_;
    my $copy = $sql =~ /^COPY / ? 1 : 0;
    $self->_send('PQsendQuery', { cb => $cb, copy => $copy });
    if ($copy) { $self->{stream} = []; $self->{puts} = 0 }
    return;
  }

  sub put_copy_data {
    my ($self, $data) = @_;
    Carp::croak('not connected') unless $self->{conn};
    my $arm = delete $ARM{put}{ ++$self->{puts} } // '';
    if ($self->{async} ne 'copy_in') {
      $self->{errmsg} = "no COPY in progress\n";
      return -1;
    }
    if ($arm eq '0') {    # pqCheckOutBufferSpace failed, nonblocking
      $self->{errmsg} = $NO_MEMORY;
      return 0;
    }
    if ($arm eq '-1') {   # pqSendSome read the end of the connection
      $self->{ok}     = 0;
      $self->{errmsg} = $GONE;
      return -1;
    }
    push @{ $self->{stream} }, $data;
    # check_flush: PQflush answers -1 on a connection libpq has dropped
    $self->t_lose($GONE) if $arm eq 'lose' || !$self->{ok};
    return 1;
  }

  sub put_copy_end {
    my ($self, $abort) = @_;
    Carp::croak('not connected') unless $self->{conn};
    my $arm = delete $ARM{end} // '';
    if ($self->{async} ne 'copy_in') {
      $self->{errmsg} = "no COPY in progress\n";
      return -1;
    }
    if ($arm eq 'stuck') {   # the end could not be queued: still in the COPY
      $self->{errmsg} = delete $ARM{errmsg} // $NO_MEMORY;
      return -1;
    }
    $self->{queue}[0]{ended} = defined $abort ? "ERROR:  COPY from stdin failed: $abort" : '';
    $self->{async} = 'busy';   # "Return to active duty", then pqFlush
    if ($arm eq 'bad') {       # which reads the end of the connection
      $self->{ok}     = 0;
      $self->{errmsg} = $GONE;
      return -1;
    }
    # check_flush
    if ($arm eq 'lost' || !$self->{ok}) {
      $self->t_lose($GONE);
      return 1;
    }
    $self->_arm;
    return 1;
  }

  sub finish {
    my ($self) = @_;
    $self->{finished}++;
    $self->_cancel_pending('connection finished');
    $self->{conn}  = 0;
    $self->{async} = 'idle';
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

  # handle_conn_loss: on_error, the handle torn down, then every queued
  # callback with "connection lost".
  sub t_lose {
    my ($self, $msg) = @_;
    $self->{on_error}->($msg) if $self->{on_error};
    $self->{conn}  = 0;
    $self->{async} = 'idle';
    $self->_cancel_pending('connection lost');
    return;
  }

  # A result is due only while libpq is busy: in the COPY the server waits.
  sub _arm {
    my ($self) = @_;
    return if $self->{timer} || !@{ $self->{queue} } || $self->{async} ne 'busy';
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    return unless $self->{conn};
    my $head = $self->{queue}[0] or return;

    my @result;
    if (defined(my $err = delete $ARM{fail})) {
      $self->{async} = 'idle';
      @result = (undef, $err);
    }
    elsif ($head->{copy} && !defined $head->{ended}) {
      $self->{async} = 'copy_in';
      @result = ('COPY_IN');
    }
    elsif ($head->{copy}) {
      $self->{async} = 'idle';
      @result = length $head->{ended}
        ? (undef, "$head->{ended}\n")
        : (scalar @{ $self->{stream} });
    }
    else {
      $self->{async} = 'idle';
      @result = ([ [ 1, 'one' ] ]);
    }

    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};

    # Advanced only after the callback returned -- unless it was dropped
    # meanwhile, or it is a COPY's first firing, which stays at the head.
    shift @{ $self->{queue} }
      if @{ $self->{queue} } && $self->{queue}[0] == $head
      && !(defined $result[0] && $result[0] eq 'COPY_IN');
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

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my @SELECT = ('thing', [qw( id name )], {});
my @COPY   = ('thing', [qw( id name )]);

my $SERVER_ERROR = qq{ERROR:  relation "thing" does not exist\n};
my $DATA_ERROR   = qq{ERROR:  invalid input syntax for type integer: "x"\n};
my $GONE         = qr/server closed the connection unexpectedly/;
my $NO_MEMORY    = qr/cannot allocate memory for output buffer/;

my $two_rows = sub {
  my ($put) = @_;
  $put->([ 1, 'a' ]);
  $put->([ 2, 'b' ]);
};
my $three_rows = sub {
  my ($put) = @_;
  $put->([ $_, 'row' ]) for 1 .. 3;
};
my $dies = sub {
  my ($put) = @_;
  $put->([ 1, 'a' ]);
  die "coderef died\n";
};
# The coderef a caller writes who wants to skip what cannot be put.
my $catches = sub {
  my ($put) = @_;
  eval { $put->([ $_, 'row' ]); 1 } for 1 .. 3;
};

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

# Let the loop run for a moment, so that whatever is due has happened before
# the pool is counted.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

# A pool of one whose connection is up: the storage, and the handle.
sub warm {
  my $storage = storage_of(1);
  @EV::Pg::MADE = ();
  my ($ok) = wait_for($storage->select_async(@SELECT));
  settle();
  @warnings = ();
  return ($storage, $ok ? $EV::Pg::MADE[0] : undef);
}

# Nothing warned but the pool's report of the connections EV::Pg lost.
sub warned_only {
  my ($label, $lost) = @_;
  my @report = grep { /^DBIO::PostgreSQL::EV pool error: / } @warnings;
  my @other  = grep { !/^DBIO::PostgreSQL::EV pool error: / } @warnings;
  is scalar @other, 0, "$label: nothing warns, no callback dies out of EV::Pg"
    or diag @other;
  is scalar @report, $lost, $lost
    ? "$label: the pool reports the lost connection, once"
    : "$label: and the pool has no lost connection to report"
    or diag @report;
  @warnings = ();
}

# The next call on the pool of one completes, on the connection the COPY ran
# on ($fresh false) or on a new one.
sub next_call {
  my ($label, $storage, $pg, $fresh) = @_;
  my $sent = $pg->{sent};
  my ($ok, @r) = wait_for($storage->select_async(@SELECT));
  ok $ok, "$label: the next call completes" or diag "it failed: $r[0]";
  settle();
  if ($fresh) {
    is scalar @EV::Pg::MADE, 2, "$label: on a fresh connection";
    is $pg->{sent}, $sent, "$label: nothing more was sent on the retired one";
  }
  else {
    is scalar @EV::Pg::MADE, 1, "$label: no other connection was opened";
    is $pg->{sent}, $sent + 1, "$label: it ran on the COPY's connection";
  }
  is $storage->pool->size, 1, "$label: the pool has its one connection";
  is $storage->pool->available, 1, "$label: idle";
}

# --- 1, 2, 3, 4, 6: every way a COPY ends short of the server's answer ----------
#
# error: what the Future fails with. lost: EV::Pg lost the connection itself
# and told the pool. stream: the rows libpq took. aborted: put_copy_end was
# given the error, so the server throws the COPY away.

my @ENDS = (
  { label  => 'put_copy_end answers -1, libpq still in the COPY',
    arm    => sub { $EV::Pg::ARM{end} = 'stuck' },
    code   => $two_rows,
    error  => qr/^put_copy_end failed: $NO_MEMORY/ },
  { label  => 'the coderef dies, put_copy_end answers -1, libpq still in the COPY',
    arm    => sub { $EV::Pg::ARM{end} = 'stuck' },
    code   => $dies,
    error  => qr/^coderef died\n\z/ },
  { label  => 'put_copy_end answers -1, libpq has lost the connection',
    arm    => sub { $EV::Pg::ARM{end} = 'bad' },
    code   => $two_rows,
    error  => qr/^put_copy_end failed: $GONE/ },
  { label  => 'the coderef dies, put_copy_end answers -1, libpq has lost the connection',
    arm    => sub { $EV::Pg::ARM{end} = 'bad' },
    code   => $dies,
    error  => qr/^coderef died\n\z/ },
  { label  => 'put_copy_end answers 1 and loses the connection in its flush',
    arm    => sub { $EV::Pg::ARM{end} = 'lost' },
    code   => $two_rows,
    error  => qr/^connection lost/,
    lost   => 1 },
  { label  => 'the coderef dies, put_copy_end answers 1 and loses the connection in its flush',
    arm    => sub { $EV::Pg::ARM{end} = 'lost' },
    code   => $dies,
    error  => qr/^coderef died\n\z/,
    lost   => 1 },
  { label  => 'put_copy_data answers -1, libpq has lost the connection',
    arm    => sub { $EV::Pg::ARM{put}{2} = -1 },
    code   => $two_rows,
    error  => qr/^put_copy_data failed: $GONE.* at \Q$0\E line \d+/s,
    stream => 1,
    lost   => 1 },
  { label  => 'put_copy_data answers -1, the coderef catches the die and goes on',
    arm    => sub { $EV::Pg::ARM{put}{2} = -1 },
    code   => $catches,
    error  => qr/^put_copy_data failed: $GONE/,
    stream => 1,
    lost   => 1 },
  # Green before and after: EV::Pg loses the connection in the flush of a put
  # and croaks at the next call, whatever the coderef does about that.
  { label  => 'a put loses the connection in its flush, the next one croaks',
    arm    => sub { $EV::Pg::ARM{put}{2} = 'lose' },
    code   => $three_rows,
    error  => qr/^not connected\n\z/,
    stream => 2,
    lost   => 1 },
  { label  => 'a put loses the connection in its flush, the coderef catches the croak',
    arm    => sub { $EV::Pg::ARM{put}{2} = 'lose' },
    code   => $catches,
    error  => qr/^not connected\n\z/,
    stream => 2,
    lost   => 1 },
);

for my $c (@ENDS) {
  my $label = $c->{label};
  my ($storage, $pg) = warm();
  ok $pg, "$label: the connection is up" or next;
  my $pool = $storage->pool;

  local %EV::Pg::ARM = ();
  $c->{arm}->();

  my ($ok, @r) = wait_for($storage->copy_in(@COPY, $c->{code}));
  ok !$ok, "$label: the COPY fails";
  unlike $r[0], qr/watchdog|nothing left that could complete/,
    "$label: and does not stay pending";
  like $r[0], $c->{error}, "$label: with the right error";
  is scalar @{ $pg->{stream} }, $c->{stream}, "$label: libpq took $c->{stream} row(s)"
    if defined $c->{stream};

  settle();
  is $pool->available, 0, "$label: its connection is not listed idle";
  is $pool->size, 0, "$label: nor counted any more";
  is $pg->{finished}, 1, "$label: it is closed, once";
  is $pg->pending_count, 0, "$label: with no callback left queued";
  warned_only($label, $c->{lost} ? 1 : 0);

  next_call($label, $storage, $pg, 1);
  warned_only("$label, the next call", 0);
}

# libpq's reason is passed on the way every text of libpq's is: with no
# password in it (karr k78).
{
  my $label = "libpq's reason for a failing put_copy_end";
  my ($storage, $pg) = warm();
  ok $pg, "$label: the connection is up";
  local %EV::Pg::ARM = (end => 'stuck', errmsg => "no room: password=hunter2 host=db\n");
  my ($ok, @r) = wait_for($storage->copy_in(@COPY, $two_rows));
  like $r[0], qr/^put_copy_end failed: no room: password=\*\*\* host=db at /,
    "$label: is in the error, without its newline";
  unlike $r[0], qr/hunter2/, "$label: with the password masked";
  settle();
  @warnings = ();
}

# --- 3: a row the writer could not put fails the COPY, the connection stays -----
#
# put_copy_data answering 0 leaves the connection as it was -- libpq could not
# grow its output buffer for this one row. The writer dies, the COPY is aborted
# through put_copy_end, the server answers that, and the connection is good for
# the next call.

for my $c (
  { label  => 'put_copy_data answers 0',
    code   => $three_rows,
    error  => qr/^put_copy_data failed: $NO_MEMORY at \Q$0\E line \d+/,
    stream => 1 },
  { label  => 'put_copy_data answers 0, the coderef catches the die and goes on',
    code   => $catches,
    error  => qr/^put_copy_data failed: $NO_MEMORY/,
    stream => 1 },
) {
  my $label = $c->{label};
  my ($storage, $pg) = warm();
  ok $pg, "$label: the connection is up" or next;

  local %EV::Pg::ARM = (put => { 2 => 0 });
  my $ended;
  no warnings 'redefine';
  my $put_copy_end = \&EV::Pg::put_copy_end;
  local *EV::Pg::put_copy_end = sub { $ended = $_[1]; goto &$put_copy_end };

  my ($ok, @r) = wait_for($storage->copy_in(@COPY, $c->{code}));
  ok !$ok, "$label: the COPY fails" or diag "it loaded $r[0] row(s)";
  like $r[0], $c->{error}, "$label: with the writer's error";
  is scalar @{ $pg->{stream} }, $c->{stream}, "$label: libpq took $c->{stream} of the 3 rows";
  like $ended // '', qr/^put_copy_data failed: /,
    "$label: and the COPY is aborted with that, not completed without the row";

  settle();
  is $pg->{finished}, 0, "$label: the connection is not closed";
  warned_only($label, 0);
  next_call($label, $storage, $pg, 0);
  warned_only("$label, the next call", 0);
}

# --- 5: a writer called outside its COPY ----------------------------------------
#
# A caller that keeps the writer has it for a connection that is the pool's
# again, and soon another caller's. Called while that caller's COPY is open on
# it, it would put its row into that COPY.

{
  my $label = 'the writer of a COPY that has ended';
  my ($storage, $pg) = warm();
  ok $pg, "$label: the connection is up";

  my $kept;
  my ($ok, @r) = wait_for($storage->copy_in(@COPY, sub { $kept = $_[0]; $kept->([ 1, 'a' ]) }));
  ok $ok && $r[0] == 1, "$label: its COPY is done" or diag "it failed: $r[0]";
  settle();

  # A refusal of the transport's own: a DBIO::Exception naming the writer and
  # the caller's line (karr k88, maintainer's decision 2026-10-16). Until then
  # this held a croaked string, "copy_in: the writer ... at $0 line N".
  my $line = __LINE__; my $died = eval { $kept->([ 98, 'between' ]); 1 } ? undef : $@;
  isa_ok $died, 'DBIO::Exception', "$label: the refusal when no COPY is open";
  like $died // '', qr/^DBIO::PostgreSQL::EV::Storage::copy_in_writer\(\): copy_in: the writer was called outside its COPY at \Q$0\E line $line\n\z/,
    "$label: dies when no COPY is open, at the caller's line";

  my $inside;
  ($ok, @r) = wait_for($storage->copy_in(@COPY, sub {
    my ($put) = @_;
    $put->([ 2, 'b' ]);
    $line = __LINE__; $inside = eval { $kept->([ 99, 'stale' ]); 1 } ? 'it put its row' : $@;
    $put->([ 3, 'c' ]);
  }));
  isa_ok $inside, 'DBIO::Exception', "$label: the refusal while another COPY is open";
  like $inside // '', qr/^DBIO::PostgreSQL::EV::Storage::copy_in_writer\(\): copy_in: the writer was called outside its COPY at \Q$0\E line $line\n\z/,
    "$label: dies while another COPY is open on its connection, at the caller's line";
  ok $ok, "$label: that COPY is done" or diag "it failed: $r[0]";
  is_deeply $pg->{stream}, [ "2\tb\n", "3\tc\n" ], "$label: with its own rows and no other";
  is scalar @EV::Pg::MADE, 1, "$label: all of it on the one connection";
  warned_only($label, 0);
}

# --- 7: the controls -- a COPY the server answered keeps its connection ---------

for my $c (
  { label  => 'the COPY is done',
    code   => $two_rows,
    expect => 2 },
  { label  => 'the coderef dies',
    code   => $dies,
    error  => qr/^coderef died\n\z/ },
  { label  => 'the server refuses the COPY',
    arm    => sub { $EV::Pg::ARM{fail} = $SERVER_ERROR },
    code   => $two_rows,
    error  => qr/^\Q$SERVER_ERROR\E\z/ },
  { label  => 'the server fails the COPY at its end',
    code   => sub { $two_rows->(@_); $EV::Pg::ARM{fail} = $DATA_ERROR },
    error  => qr/^\QERROR:  invalid input syntax for type integer: "***"\E\n\z/ },   # the server's text, its value masked
) {
  my $label = "control, $c->{label}";
  my ($storage, $pg) = warm();
  ok $pg, "$label: the connection is up" or next;

  local %EV::Pg::ARM = ();
  $c->{arm}->() if $c->{arm};

  my ($ok, @r) = wait_for($storage->copy_in(@COPY, $c->{code}));
  if ($c->{error}) {
    ok !$ok, "$label: the COPY fails";
    like $r[0], $c->{error}, "$label: with its own error";
  }
  else {
    ok $ok, "$label: the COPY resolves" or diag "it failed: $r[0]";
    is $r[0], $c->{expect}, "$label: with the server's count";
  }

  settle();
  is $pg->{finished}, 0, "$label: its connection is not closed";
  is $storage->pool->available, 1, "$label: but back in the pool";
  warned_only($label, 0);
  next_call($label, $storage, $pg, 0);
  warned_only("$label, the next call", 0);
}

done_testing;
