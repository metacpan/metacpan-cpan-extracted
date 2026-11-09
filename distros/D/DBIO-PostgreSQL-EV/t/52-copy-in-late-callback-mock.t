use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );

# OFFLINE regression for karr k57: a COPY that copy_in has ended, because
# put_copy_end failed, stays ended when its callback is called again.
#
# WHY: a pooled connection has one holder. copy_in ends a COPY whose
# put_copy_end returns -1 right there, inside the callback's first firing: it
# fails the Future and hands the connection back. EV::Pg, though, does nothing
# about a failing PQputCopyEnd but return its -1 (Pg.xs, 0.02 and 0.07 alike):
# the COPY's callback stays at the head of its queue, to be called again
#   - with ("COPY_IN") the next time the socket is readable, as long as libpq
#     still has the COPY open -- process_results asks PQgetResult, which
#     answers a COPY_IN result for as long as that is so;
#   - with (undef, "connection lost") once it loses the connection, and with
#     (undef, "connection finished") when the connection is finished.
# copy_in took that call for the COPY's second firing, the server's answer:
# it settled the Future again and released the connection again. By then the
# pool has moved on. Released again, a connection is listed idle while its
# next caller holds it -- or listed twice -- and the pool hands one connection
# to two callers. The Future is failed already; Future.pm refuses the second
# settling by dying, and the die goes to EV::Pg, which warns it.
#
# What this file claims, with the coderef returning and with it dying (the two
# ways copy_in comes to put_copy_end), for each of those late calls, with the
# pool's connection idle and with it held by the next caller when the call
# comes:
#   a. the COPY fails, and its connection is retired: it is open, but libpq is
#      still in the COPY and no statement can run on it (karr k65);
#   b. the late call settles nothing: no callback dies out of EV::Pg;
#   c. the late call releases nothing: the retired connection does not come
#      back to the pool, and the connection the pool has now has one holder at
#      a time -- a further caller waits for it and gets it when the holder
#      hands it back.
# And the property the fix has to keep, green before and after:
#   d. the end that turns a late call away is the COPY's, not its Future's: a
#      COPY whose Future the caller cancelled still gives its connection back
#      when the server answers. A cancelled Future is ready, so a callback
#      that asked the Future -- as _pipeline_sync's may, releasing nothing --
#      would return there and keep the connection checked out for good.
#
# karr k65 REPLACED claims a and c rather than preserving them. Until then a
# read: "its connection is back in the pool, once", and c: "a connection that
# is alive has one holder at a time", with the next caller getting the COPY's
# own connection. The file said itself what that left out -- "What this file
# does not claim: that the connection is usable after a failed put_copy_end"
# -- and it is not: libpq refuses every statement on it ("another command is
# already in progress"). The connection is retired now, the next caller gets a
# fresh one, and the late call is held against that.
#
# It also changed what makes the late call. Retiring the connection finishes
# it inside the callback's own delivery, and there Pg.xs drops the callback
# without calling it again (cancel_pending, "Currently being delivered; remove
# without re-firing", 0.02 and 0.07 alike). So neither EV::Pg read here makes
# the late call any more once the pool has retired the connection. The guard
# is held all the same -- for the EV::Pg versions in between, which this
# distribution admits and nobody has read, and for a connection the pool does
# not finish: t_late calls the callback once more, the way EV::Pg calls one it
# still has queued.
#
# THE ONE SUBSTITUTION is EV::Pg itself: a fake the real pool builds through
# its real constructor, so the pool's own on_error hears of a lost connection.
# It follows Pg.xs where this file rests on it: the connect completes on an EV
# timer; the COPY's callback is called with ("COPY_IN") and stays at the head
# of the queue; put_copy_end returns what PQputCopyEnd did and touches
# nothing; finish calls every queued callback but the one being delivered; a
# callback is called under an eval that only warns. t_deliver is a result
# arriving for the head of the queue (deliver_result) -- the server's answer
# to the COPY too, which the test delivers itself.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our $LAST_COPY;     # the handle the last COPY was sent on
  our $END_RC = -1;   # what put_copy_end returns: PQputCopyEnd failed

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      queue      => [],
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
  sub error_message { undef }

  # The COPY command: queued, and the server opens the stream.
  sub query {
    my ($self, $sql, $cb) = @_;
    Carp::croak('not connected') unless $self->{up};
    push @{ $self->{queue} }, { cb => $cb };
    $self->{copy_cb} = $cb;
    $LAST_COPY = $self;
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->t_deliver('COPY_IN') if $weak });
    return;
  }

  sub put_copy_data { 1 }

  # EV::Pg returns what PQputCopyEnd did and nothing else: the callback stays
  # queued, also when that failed.
  sub put_copy_end {
    my ($self) = @_;
    Carp::croak('not connected') unless $self->{up};
    $self->{end_called} = 1;
    return $END_RC;
  }

  sub finish {
    my ($self) = @_;
    $self->{finished}++;
    $self->_cancel_pending('connection finished');
    $self->{up} = 0;
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

  sub t_deliver {
    my ($self, @result) = @_;
    delete $self->{timer};
    my $head = $self->{queue}[0] or return;

    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};

    # A COPY_IN result leaves the callback at the head; any other advances
    # the queue -- unless the callback was dropped meanwhile.
    shift @{ $self->{queue} }
      if @{ $self->{queue} } && $self->{queue}[0] == $head
      && !(defined $result[0] && $result[0] eq 'COPY_IN');
    return;
  }

  # The COPY's callback called once more, as EV::Pg calls one it still has
  # queued. See the header: Pg.xs no longer has it queued by now. The fake lets
  # go of it with this call -- the callback holds the handle.
  sub t_late {
    my ($self, @args) = @_;
    my $cb = delete $self->{copy_cb};
    eval { $cb->(@args); 1 } or warn "EV::Pg: exception in callback: $@";
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

# The two ways copy_in comes to put_copy_end, and what the COPY fails with:
# the coderef's own error where it died.
my @CODEREFS = (
  { label => 'the coderef returns',
    code  => sub { $_[0]->([ 1, 'a' ]) },
    error => qr/^put_copy_end failed/ },
  { label => 'the coderef dies',
    code  => sub { $_[0]->([ 1, 'a' ]); die "coderef died\n" },
    error => qr/^coderef died\n\z/ },
);

# The late calls of a callback EV::Pg still has queued.
my @LATE = (
  { label => 'the stream is reported open once more',
    args  => [ 'COPY_IN' ] },
  { label => 'the connection is lost',
    args  => [ undef, 'connection lost' ] },
  { label => 'the connection is finished',
    args  => [ undef, 'connection finished' ] },
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

# Let the loop run for a moment, so that whatever is due has happened before
# the pool is counted.
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
  is scalar @died, 0, "$label: the late call settles nothing, no callback dies out of EV::Pg"
    or diag @died;
  @warnings = ();
}

for my $c (@CODEREFS) {
  for my $late (@LATE) {
    for my $held (1, 0) {
      my $label = join ', ', $c->{label}, $late->{label},
        $held ? "the pool's connection held by the next caller" : 'no connection in the pool';

      my $storage = storage_of(1);
      my $pool    = $storage->pool;
      @warnings   = ();

      # a. the COPY fails, and its connection is retired
      my ($ok, $error) = wait_for($storage->copy_in('thing', [qw( id name )], $c->{code}));
      ok !$ok, "$label: the COPY fails";
      like $error, $c->{error}, "$label: with the right error";
      my $pg = $EV::Pg::LAST_COPY;
      is $pool->size, 0, "$label: its connection is retired";
      is $pool->available, 0, "$label: not listed idle";
      is $pg->{finished}, 1, "$label: and closed, once";
      is $pg->pending_count, 0, "$label: EV::Pg has dropped the COPY's callback with it";

      my $holder;
      if ($held) {
        (my $got, $holder) = wait_for($pool->acquire);
        ok $got && refaddr($holder) != refaddr($pg), "$label: the next caller gets a fresh connection";
      }

      $pg->t_late(@{ $late->{args} });
      settle();

      # b. the late call settles nothing
      no_callback_died($label);

      # c. the late call releases nothing
      is $pool->size, $held ? 1 : 0, "$label: the retired connection is not back in the pool";
      is $pool->available, 0, "$label: and nothing is listed idle";
      is $pg->{finished}, 1, "$label: nor is it closed a second time";

      unless ($held) {
        (my $got, $holder) = wait_for($pool->acquire);
        ok $got && refaddr($holder) != refaddr($pg), "$label: the next caller gets a fresh connection";
      }
      is $pool->available, 0, "$label: which is not listed idle while that caller holds it";

      my $further = $pool->acquire;
      settle();
      ok !$further->is_ready, "$label: a further caller waits for it";

      $pool->release($holder);
      my ($got, $conn) = wait_for($further);
      ok $got && refaddr($conn) == refaddr($holder),
        "$label: and gets it when the holder hands it back";
      is $pool->size, 1, "$label: the pool has one connection";
    }
  }
}

# --- d: the end is the COPY's, not its Future's ---------------------------------

{
  my $label = 'the Future cancelled before the server answers';
  local $EV::Pg::END_RC    = 1;
  local $EV::Pg::LAST_COPY = undef;

  my $storage = storage_of(1);
  my $pool    = $storage->pool;
  @warnings   = ();

  my $f = $storage->copy_in('thing', [qw( id name )], $CODEREFS[0]{code});
  EV::now_update();
  my $dog = EV::timer(5, 0, sub { });
  EV::run(EV::RUN_ONCE())
    until ($EV::Pg::LAST_COPY && $EV::Pg::LAST_COPY->{end_called}) || !$dog->is_active;
  my $pg = $EV::Pg::LAST_COPY;
  ok $pg && $pg->{end_called}, "$label: the COPY's data is out, its end sent";

  $f->cancel;
  is $pool->available, 0, "$label: the connection is still checked out";

  $pg->t_deliver('1');
  is $pg->pending_count, 0, "$label: the server's answer ends the COPY";
  is $pool->size, 1, "$label: the pool still has its one connection";
  is $pool->available, 1, "$label: which is back in the pool, once";
  is scalar(grep { /exception in callback/ } @warnings), 0,
    "$label: no callback died out of EV::Pg" or diag @warnings;
  delete $pg->{copy_cb};
}

done_testing;
