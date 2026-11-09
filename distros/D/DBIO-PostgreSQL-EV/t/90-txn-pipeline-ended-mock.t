use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k88 (core k292): the ROLLBACK of a transaction whose
# coderef ended after it ran a pipeline on the transaction ($ctx->pipeline).
#
# The coderef calls $ctx->pipeline(...) and then dies, or returns a failed
# Future, before the pipeline's sync point is answered. Core sends the batch's
# sync, then the transaction's ROLLBACK -- while the connection is still in
# libpq pipeline mode, because pipeline mode is left in the sync's answer.
# A statement sent in pipeline mode after the last sync point is not answered
# by the server until the next one: it sits in the output buffer. Measured
# against PostgreSQL 18.6 / EV::Pg 0.07 (t/91-txn-pipeline-ended-live.t): the
# ROLLBACK never answered, so the transaction Future stayed pending for good,
# the pipeline's exit failed with "cannot exit pipeline mode while busy", and
# the connection was left in pipeline mode with its transaction open -- the
# pool of one was gone.
#
# What this file claims, through the REAL storage, pool and core scaffold over
# a stand-in EV::Pg:
#   1. the coderef dies after $ctx->pipeline: the transaction fails with the
#      coderef's error, the ROLLBACK goes out only once pipeline mode is left
#      (wire: BEGIN, enter, batch, sync, exit, ROLLBACK), and the connection is
#      released once, idle, out of pipeline mode, no transaction open;
#   2. the same when the coderef returns a failed Future;
#   3. the connection is lost while the sync is outstanding: the ROLLBACK that
#      waited fails with the loss instead of hanging, the transaction fails,
#      the connection is retired and the next call runs on a fresh one;
#   4. the pool serves on, nothing warns, no callback dies out of EV::Pg.
#
# THE ONE SUBSTITUTION is EV::Pg itself, as in t/58 (see there for what it
# takes from Pg.xs). The one thing added here is the one that matters: a
# statement sent in pipeline mode is answered only if a sync point was sent
# at or behind it. Without that rule the fake would answer the ROLLBACK and
# the file could never fail.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  my $ID = 0;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      id         => ++$ID,
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      finished   => 0,
      pipeline   => 0,
      queue      => [],
      wire       => [],
      hold       => 0,   # true: nothing is answered until t_release
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

  sub is_connected    { $_[0]{up} ? 1 : 0 }
  sub pending_count   { scalar @{ $_[0]{queue} } }
  sub socket          { -1 }
  sub result_meta     { $_[0]{meta} }
  sub pipeline_status { $_[0]{pipeline} }

  sub _busy {
    my ($self) = @_;
    return scalar grep { !$self->{delivering} || $_ != $self->{delivering} } @{ $self->{queue} };
  }

  sub _check {
    Carp::croak('not connected') unless $_[0]{up};
    return;
  }

  sub _send {
    my ($self, $label, $entry) = @_;
    push @{ $self->{wire} }, $label;
    push @{ $self->{queue} }, $entry;
    $self->_arm;
    return;
  }

  sub enter_pipeline {
    my ($self) = @_;
    $self->_check;
    die "PQenterPipelineMode failed: cannot enter pipeline mode, connection not idle\n"
      if $self->_busy;
    push @{ $self->{wire} }, 'enter_pipeline';
    $self->{pipeline} = 1;
    return;
  }

  sub exit_pipeline {
    my ($self) = @_;
    $self->_check;
    die "PQexitPipelineMode failed: cannot exit pipeline mode while busy\n"
      if $self->{pipeline} && $self->_busy;
    push @{ $self->{wire} }, 'exit_pipeline';
    $self->{pipeline} = 0;
    return;
  }

  sub query_params {
    my ($self, $sql, $bind, $cb) = @_;
    $self->_check;
    die "PQsendQueryParams failed: another command is already in progress\n"
      if !$self->{pipeline} && $self->_busy;
    my ($verb) = $sql =~ /^(\w+)/;
    my $name = $verb =~ /^(?:SELECT|INSERT)\z/ && @$bind ? $bind->[-1] : $verb;
    return $self->_send($name, { sql => $sql, cb => $cb, piped => $self->{pipeline} });
  }

  sub pipeline_sync {
    my ($self, $cb) = @_;
    $self->_check;
    die "PQpipelineSync failed: cannot send pipeline when not in pipeline mode\n"
      unless $self->{pipeline};
    return $self->_send('pipeline_sync', { sync => 1, cb => $cb });
  }

  sub finish {
    my ($self) = @_;
    $self->{finished}++;
    $self->_drop_queued('connection finished');
    $self->{up}       = 0;
    $self->{pipeline} = 0;
    return;
  }

  sub _drop_queued {
    my ($self, $msg) = @_;
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, $msg); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    return;
  }

  sub t_lose {
    my ($self, $msg) = @_;
    my $finished = $self->{finished};
    $self->{up} = 0;
    $self->{on_error}->($msg) if $self->{on_error};
    $self->_drop_queued('connection lost') if $self->{finished} == $finished;
    return;
  }

  sub t_release { $_[0]{hold} = 0; $_[0]->_arm; return }

  # The server answers the head of the queue -- unless it was sent in pipeline
  # mode and no sync point is behind it: that waits in the output buffer.
  sub _answerable {
    my ($self) = @_;
    my $head = $self->{queue}[0] or return 0;
    return 1 unless $head->{piped} || $head->{sync};
    return scalar grep { $_->{sync} } @{ $self->{queue} };
  }

  sub _arm {
    my ($self) = @_;
    return if $self->{hold} || $self->{timer} || !$self->_answerable;
    Scalar::Util::weaken(my $weak = $self);
    $self->{timer} = EV::timer(0.001, 0, sub { $weak->_complete_head if $weak });
    return;
  }

  sub _complete_head {
    my ($self) = @_;
    delete $self->{timer};
    return unless $self->_answerable;
    my $head = $self->{queue}[0];
    my @result;
    # EV::Pg calls the sync's callback with (1) once the sync point is answered
    # (t/58); (undef, 1) was an error result with the message "1", which the
    # pipeline scaffold of core now retires its connection for (core k396).
    if ($head->{sync}) { @result = (1) }
    else {
      my $sql = $head->{sql};
      $self->{intrans} = 1 if $sql eq 'BEGIN';
      $self->{intrans} = 0 if $sql eq 'COMMIT' || $sql eq 'ROLLBACK';
      $self->{meta} = { cmd_status => $sql =~ /^(?:BEGIN|COMMIT|ROLLBACK)\z/ ? $sql : 'SELECT 1' };
      @result = $sql =~ /^SELECT/ ? ([ [ 'row' ] ]) : ('');
    }
    $self->{delivering} = $head;
    eval { $head->{cb}->(@result); 1 } or warn "EV::Pg: exception in callback: $@";
    delete $self->{delivering};
    shift @{ $self->{queue} } if @{ $self->{queue} } && $self->{queue}[0] == $head;
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
use DBIO::PostgreSQL::EV::Pool;

alarm 60;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package T90::Pool;
  our @ISA = ('DBIO::PostgreSQL::EV::Pool');

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{t_released} }, {
      conn      => $conn->{id},
      in_flight => $conn->_busy,
      pipeline  => $conn->{pipeline},
      in_txn    => $conn->{intrans} ? 1 : 0,
    };
    return $self->SUPER::release($conn);
  }

  sub _retire_in_use_connection {
    my ($self, $conn) = @_;
    push @{ $self->{t_retired} }, $conn->{id};
    return $self->SUPER::_retire_in_use_connection($conn);
  }
}

sub wait_for {
  my ($f) = @_;
  EV::now_update();
  my $dog = EV::timer(3, 0, sub { $f->fail("watchdog: still pending after 3s\n") unless $f->is_ready });
  $dog->keepalive(0);
  my @r;
  return (1, @r) if eval { @r = $f->get; 1 };
  return (0, $@);
}

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.05, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub fresh {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 }, {} ]);
  bless $storage->pool, 'T90::Pool';
  my ($ok, @r) = wait_for($storage->select_async('thing', ['tag'], { name => 'warm' }));
  die "warming the pool failed: @r" unless $ok;
  settle();
  my $conn = $storage->pool->{_connections}[0];
  @{ $conn->{wire} } = ();
  @{ $storage->pool->{t_released} } = ();
  @warnings = ();
  return ($storage, $conn);
}

sub wire { [ @{ $_[0]{wire} } ] }

# --- 1. + 2. the coderef ends after $ctx->pipeline --------------------------------

for my $how (qw( dies fails )) {
  my ($storage, $conn) = fresh();
  my $label = "the coderef $how after \$ctx->pipeline";

  my $pipe;
  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $pipe = $ctx->pipeline(sub {
      my ($batch) = @_;
      $batch->_query_async('SELECT 1', ['one']);
      return 1;
    });
    die "gave up\n" if $how eq 'dies';
    return $storage->future_class->fail("gave up\n");
  });

  my ($ok, $err) = wait_for($txn);
  ok !$ok, "$label: the transaction fails";
  is $err, "gave up\n", "$label: with the coderef's error, not a watchdog";
  settle();

  is_deeply wire($conn),
    [ 'BEGIN', 'enter_pipeline', 'one', 'pipeline_sync', 'exit_pipeline', 'ROLLBACK' ],
    "$label: the ROLLBACK goes out once pipeline mode is left";
  is_deeply [ @{ $storage->pool->{t_released} } ],
    [ { conn => $conn->{id}, in_flight => 0, pipeline => 0, in_txn => 0 } ],
    "$label: the connection is released once, idle, out of pipeline mode, no transaction open";
  is $conn->{finished}, 0, "$label: and not closed";

  my ($next) = wait_for($storage->select_async('thing', ['tag'], { name => 'next' }));
  ok $next, "$label: the next pooled call completes";
  settle();
  is_deeply \@warnings, [], "$label: nothing warned, no callback died out of EV::Pg";
  $storage->disconnect;
}

# --- 3. the connection is lost with the sync outstanding -----------------------------

{
  my ($storage, $conn) = fresh();
  my $label = 'the connection is lost while the sync is outstanding';
  $conn->{hold} = 1;   # nothing is answered: the sync is outstanding

  my $txn = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->pipeline(sub { $_[0]->_query_async('SELECT 1', ['one']); 1 });
    die "gave up\n";
  });
  settle();
  ok !$txn->is_ready, "$label: the transaction waits for its ROLLBACK";

  $conn->t_lose("server closed the connection unexpectedly\n");
  my ($ok, $err) = wait_for($txn);
  ok !$ok, "$label: the transaction fails";
  unlike $err, qr/watchdog/, "$label: it does not hang";
  settle();
  is_deeply $storage->pool->{t_retired}, [ $conn->{id} ], "$label: the connection is retired";
  is $conn->{finished}, 1, "$label: it is closed, once";
  ok !grep({ $_ == $conn } @{ $storage->pool->{_connections} }), "$label: the pool no longer holds it";

  my ($next) = wait_for($storage->select_async('thing', ['tag'], { name => 'next' }));
  ok $next, "$label: the next call runs on a fresh connection";
  $storage->disconnect;
}

done_testing;
