use strict;
use warnings;
use Test::More;
use Scalar::Util qw( refaddr );

# OFFLINE test for karr k88 (1): what ends pooled work hands its connection
# back to the pool the connection was acquired from. The transport's half of
# karr dbio-async k46 (core 4aa01dc67, t/test/49_async_completion_same_pool.t
# there), which fixed txn_do_async, pipeline and deploy_async.
#
# WHY: the storage builds its pool lazily, in the slot disconnect empties. The
# pooled paths of this transport -- _query_async, notify, copy_in -- asked the
# storage for its pool twice: to acquire, and again, $self->pool, when the work
# ended: to release the connection, to report it dead, to retire the connection
# of a COPY whose stream stayed open. Work that ends after the slot was emptied
# therefore BUILT A POOL as it ended, on a storage that had just been
# disconnected, and told that pool about a connection it had never held.
#
# When does work end after the disconnect? Not when the disconnect comes from
# outside while a statement is on the server: the shutdown finishes the
# connection, EV::Pg calls the statement's callback from inside finish, and the
# old pool is still in the slot then (measured against PostgreSQL 18, karr
# k88). It does when the disconnect is made INSIDE the delivery -- in a then,
# on_done or failure handler on the Future of a pooled statement, of a notify
# or of a copy_in, or in a copy_in's coderef: the completion is on the call
# stack, EV::Pg does not call the callback it is delivering to again, and the
# release runs once the caller's callbacks have returned -- with the slot
# empty. Measured the same way, the storage then carried a new pool with no
# connection in it, not shut down. A storage that had nothing left to connect
# from by then -- a connect_info in that callback that was refused -- could
# not even build it: the completion died out of EV::Pg's callback ("conninfo
# or conninfo_provider required"), and a copy_in whose coderef had done it
# never settled its Future, because the die came before the settling.
#
# The claim, for every way pooled work ends inside whose delivery the storage
# is disconnected:
#   a. no pool is built as the work ends, and the storage is left without one;
#   b. everything the completion tells a pool -- the release, a dead
#      connection, the retirement of an open COPY stream -- it tells the pool
#      the connection was acquired from, which is shut down and ignores it;
#   c. the work's Future settles as it does without the disconnect, and no
#      callback of this transport dies out of EV::Pg;
#   d. the storage can be used again: the next statement builds a pool then,
#      and completes on a new connection -- or, where a refused connect_info
#      left nothing to connect from, the storage stays without a pool.
# And for the seam itself, _dispatch_query and _dispatch_notify:
#   e. a dispatch EV::Pg refuses releases to the pool it was handed, too -- the
#      branch no path reaches after a disconnect today (a pool that is shut
#      down hands out nothing), held because it is the same rule;
#   f. called without the pool the connection came from, they refuse at once
#      rather than leave a completion that has no pool to release to.
#
# THE ONE SUBSTITUTION is EV::Pg itself, as in t/47: a fake the real pool
# builds through its real constructor. What it assumes of EV::Pg, 0.02 and 0.07
# alike: the connect completes on the loop; a dispatch croaks "not connected"
# on a handle that is not connected; a queued callback counts as pending until
# it has returned and is called under an eval that only warns; COPY fires its
# callback twice; and finish calls every queued callback with "connection
# finished" EXCEPT the one it is delivering to at that moment, which it drops
# -- the assumption this file stands on, measured in
# t/76-completion-same-pool-live.t.
#
# The pool is not substituted. new, release and _mark_connection_dead of the
# real pool class are wrapped to be counted and logged, nothing else.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our %NEXT;        # fail => $err: the next statement to complete ends with
                    # this server error, once
  our $LAST_SENT;   # the number of the handle the last statement was sent on
  my $ID = 0;

  sub new {
    my ($class, %args) = @_;
    my $self = bless {
      on_connect => $args{on_connect},
      on_error   => $args{on_error},
      up         => 0,
      queue      => [],
      rows       => 0,
      id         => ++$ID,   # an address can be taken again, a number cannot
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

  sub _send {
    my ($self, $entry) = @_;
    Carp::croak('not connected') unless $self->{up};
    push @{ $self->{queue} }, $entry;
    $LAST_SENT = $self->{id};
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
    $self->{rows} = 0 if $copy;
    return $self->_send({ sql => $sql, cb => $cb, copy => $copy });
  }

  sub put_copy_data {
    my ($self) = @_;
    Carp::croak('not connected') unless $self->{up};
    $self->{rows}++;
    return 1;
  }

  sub put_copy_end {
    my ($self, $abort) = @_;
    Carp::croak('not connected') unless $self->{up};
    $self->{queue}[0]{ended} = defined $abort ? "ERROR:  COPY from stdin failed: $abort" : '';
    $self->_arm;
    return 1;
  }

  # Every queued callback gets "connection finished", but not the one being
  # delivered to: EV::Pg drops that one.
  sub finish {
    my ($self) = @_;
    while (my $entry = shift @{ $self->{queue} }) {
      next if $self->{delivering} && $entry == $self->{delivering};
      eval { $entry->{cb}->(undef, 'connection finished'); 1 }
        or warn "EV::Pg: exception in callback during cancel: $@";
    }
    $self->{up} = 0;
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
use DBIO::PostgreSQL::EV::Pool;
use DBIO::PostgreSQL::EV::Future;

alarm 120;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

my $EVF    = 'DBIO::PostgreSQL::EV::Future';
my $POOL   = 'DBIO::PostgreSQL::EV::Pool';
my @SELECT = ('thing', [qw( id name )], {});

my $SERVER_ERROR = qq{ERROR:  relation "thing" does not exist\n};

# Every pool that is built, or that someone tried to build, and everything a
# pool is told about a connection: [ what, the pool by address, the connection
# by its number ]. The pool class inherits all three from core's pool.
my $BUILDS = 0;
my @TOLD;
{
  no strict 'refs';
  my $new = $POOL->can('new');
  *{"${POOL}::new"} = sub { $BUILDS++; goto &$new };
  for my $method (qw( release _mark_connection_dead )) {
    my $orig = $POOL->can($method);
    *{"${POOL}::$method"} = sub {
      push @TOLD, [ $method, refaddr($_[0]), $_[1]{id} ];
      goto &$orig;
    };
  }
}

# Run the loop until $f is ready; a Future still pending after 5 seconds fails
# the test that reads it, it does not hang the file.
sub drive {
  my ($f) = @_;
  EV::now_update();
  my $deadline = EV::time() + 5;
  until ($f->is_ready) {
    last if EV::time() > $deadline;
    EV::now_update();
    my $tick = EV::timer(0.01, 0, sub { });
    EV::run(EV::RUN_ONCE());
  }
  return $f;
}

# Run the loop a little, so anything that would fire late has fired.
sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.02, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub outcome {
  my ($f) = @_;
  return 'pending'   unless $f->is_ready;
  return 'cancelled' if $f->is_cancelled;
  return 'failed: ' . ($f->failure)[0] if $f->is_failed;
  return 'done';
}

# A storage with a pool of two, one connection up and idle.
sub warm_storage {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 2 } ]);
  my $warm = drive($storage->select_async(@SELECT));
  die 'warming the pool failed: ' . outcome($warm) unless $warm->is_done;
  settle();
  return $storage;
}

# What takes the pool from under the work, inside its delivery.
my %TAKES_THE_POOL = (
  # the storage is disconnected: its pool is shut down and dropped
  'disconnect' => sub { $_[0]->disconnect },
  # a connect_info this transport refuses: it disconnects, drops the connect
  # info it had, and throws -- the storage has nothing left to connect from
  'refused connect_info' => sub {
    my ($storage) = @_;
    die "connect_info took a coderef\n" if eval { $storage->connect_info([ sub { } ]); 1 };
  },
);

# The ways pooled work ends. begin => sub { ($storage, $inside) }: start the
# work so that $inside runs inside its delivery, return the Future the caller
# holds. ends => how that Future ends, with and without what $inside does.
# told => what the completion tells a pool about the connection, in order.
my @CASES = (
  {
    name  => 'select_async, a then on its Future',
    begin => sub {
      my ($storage, $inside) = @_;
      return $storage->select_async(@SELECT)->then(sub { $inside->(); $EVF->done(@_) });
    },
    ends => qr/\Adone\z/,
    told => [qw( release )],
  },
  {
    name  => 'select_async, an on_done on its Future',
    begin => sub {
      my ($storage, $inside) = @_;
      my $f = $storage->select_async(@SELECT);
      $f->on_done($inside);
      return $f;
    },
    ends => qr/\Adone\z/,
    told => [qw( release )],
  },
  {
    name  => 'select_async the server answers with an error, a failure handler on its Future',
    begin => sub {
      my ($storage, $inside) = @_;
      $EV::Pg::NEXT{fail} = $SERVER_ERROR;
      return $storage->select_async(@SELECT)->else(sub { $inside->(); $EVF->fail(@_) });
    },
    ends => qr/\Afailed: ERROR:  relation "thing" does not exist/,
    # the connection was finished inside the delivery, so the completion finds
    # it not connected and reports it before it releases it (karr k49)
    told => [qw( _mark_connection_dead release )],
  },
  {
    name  => 'notify, a then on its Future',
    begin => sub {
      my ($storage, $inside) = @_;
      return $storage->notify('chan', 'payload')->then(sub { $inside->(); $EVF->done });
    },
    ends => qr/\Adone\z/,
    told => [qw( release )],
  },
  {
    name  => 'copy_in, a then on its Future',
    begin => sub {
      my ($storage, $inside) = @_;
      return $storage->copy_in('thing', [qw( id name )], sub { $_[0]->([ 1, 'a' ]) })
        ->then(sub { $inside->(); $EVF->done(@_) });
    },
    ends => qr/\Adone\z/,
    told => [qw( release )],
  },
  {
    name  => 'copy_in the server refuses, a failure handler on its Future',
    begin => sub {
      my ($storage, $inside) = @_;
      $EV::Pg::NEXT{fail} = $SERVER_ERROR;
      return $storage->copy_in('thing', [qw( id name )], sub { $_[0]->([ 1, 'a' ]) })
        ->else(sub { $inside->(); $EVF->fail(@_) });
    },
    ends => qr/\Afailed: ERROR:  relation "thing" does not exist/,
    told => [qw( _mark_connection_dead release )],
  },
  {
    name  => 'copy_in, in its coderef',
    begin => sub {
      my ($storage, $inside) = @_;
      return $storage->copy_in('thing', [qw( id name )], sub {
        my ($put) = @_;
        $put->([ 1, 'a' ]);
        $inside->();
      });
    },
    # the stream cannot be ended on a connection that was finished under it
    ends => qr/\Afailed: not connected/,
    # the COPY ends with its stream open: its connection is reported dead (karr
    # k65), then again as not connected (karr k49), then released
    told => [qw( _mark_connection_dead _mark_connection_dead release )],
  },
);

for my $how (sort keys %TAKES_THE_POOL) {
  for my $case (@CASES) {
    my $label = "$case->{name}: $how";

    my $storage = warm_storage();
    my $began   = $storage->pool;   # the pool the work begins on
    my $builds  = $BUILDS;
    @TOLD     = ();
    @warnings = ();

    my $ran = 0;
    my $f   = drive($case->{begin}->($storage, sub { $ran++; $TAKES_THE_POOL{$how}->($storage) }));
    my $pg  = $EV::Pg::LAST_SENT;   # the connection the work ran on, by number
    settle();

    is $ran, 1, "$label: the storage lost its pool inside the delivery";
    ok $began->{_shutdown}, "$label: the pool the work began on is shut down";

    # a.
    is $BUILDS - $builds, 0, "$label: no pool is built as the work ends";
    ok !defined $storage->{pool}, "$label: the storage is left without a pool";
    ok !$storage->connected, "$label: and does not call itself connected";

    # b.
    my @elsewhere = grep { $_->[1] != refaddr($began) } @TOLD;
    is scalar @elsewhere, 0, "$label: no other pool is told anything";
    is_deeply [ map { $_->[0] } grep { $_->[1] == refaddr($began) && $_->[2] == $pg } @TOLD ], $case->{told},
      "$label: the pool it began on is told of the connection: @{ $case->{told} }";

    # c.
    like outcome($f), $case->{ends}, "$label: the Future ends as it does without it";
    is scalar(grep { /exception in callback/ } @warnings), 0, "$label: no callback died out of EV::Pg"
      or diag @warnings;

    # d.
    if ($how eq 'disconnect') {
      my $next = drive($storage->select_async(@SELECT));
      is outcome($next), 'done', "$label: the next statement completes";
      is $BUILDS - $builds, 1, "$label: on a pool built for it";
      isnt $EV::Pg::LAST_SENT, $pg, "$label: and on a new connection";
      $storage->disconnect;
    }
    else {
      settle();
      ok !defined $storage->{pool}, "$label: the storage still has no pool";
    }
  }
}

# --- e. the dispatch EV::Pg refuses, called as the acquire chain calls it ------
for my $seam (
  [ _dispatch_query  => sub { $_[0]->_dispatch_query($_[1], 'SELECT 1', [], $_[2]) } ],
  [ _dispatch_notify => sub { $_[0]->_dispatch_notify($_[1], 'chan', 'payload', $_[2]) } ],
) {
  my ($name, $dispatch) = @$seam;
  my $storage = warm_storage();
  my $began   = $storage->pool;
  my $pg      = drive($began->acquire)->get;
  $storage->disconnect;   # finishes $pg: EV::Pg croaks "not connected" at dispatch
  my $builds = $BUILDS;
  @TOLD = ();

  my $f = $dispatch->($storage, $pg, $began);

  like outcome($f), qr/\Afailed: not connected/, "$name refused at dispatch: the Future fails with EV::Pg's error";
  is $BUILDS - $builds, 0, "$name refused at dispatch: no pool is built";
  ok !defined $storage->{pool}, "$name refused at dispatch: the storage is left without a pool";
  is_deeply [ map { [ $_->[0], $_->[1] ] } @TOLD ],
    [ [ _mark_connection_dead => refaddr($began) ], [ release => refaddr($began) ] ],
    "$name refused at dispatch: the dead connection and its release go to the pool handed in";
}

# --- f. no pool handed in ------------------------------------------------------
{
  my $storage = warm_storage();
  my $pg      = drive($storage->pool->acquire)->get;
  for my $seam (
    [ _dispatch_query  => sub { $storage->_dispatch_query($pg, 'SELECT 1', []) } ],
    [ _dispatch_notify => sub { $storage->_dispatch_notify($pg, 'chan', 'payload') } ],
  ) {
    my ($name, $dispatch) = @$seam;
    my $f = eval { $dispatch->() };
    like $@, qr/\Q$name\E needs the pool the connection was acquired from/,
      "$name without a pool: refused at once";
    ok !defined $f, "$name without a pool: no Future is handed out";
  }
  is $pg->pending_count, 0, 'nothing was sent on the connection';
  $storage->pool->release($pg);
  $storage->disconnect;
}

is scalar(grep { /exception in callback/ } @warnings), 0, 'no callback died out of EV::Pg in e and f'
  or diag @warnings;

done_testing;
