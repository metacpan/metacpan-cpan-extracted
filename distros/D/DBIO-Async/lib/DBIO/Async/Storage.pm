package DBIO::Async::Storage;
# ABSTRACT: Future::IO transport backend for DBIO async storage

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::Async';

use Carp 'croak';
use Scalar::Util qw( blessed looks_like_number refaddr reftype weaken );
use Future;
use Future::IO qw( POLLIN );
use DBIO::Storage::DBI ();
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;
use namespace::clean;



sub future_class { 'Future' }


sub transport_capabilities { qw(on_connect_replay) }


sub pool {
  my $self = shift;
  $self->{pool} ||= do {
    my %args = (
      storage  => $self,
      size     => $self->{_pool_size},
      on_error => sub { warn "DBIO::Async pool error: $_[0]\n" },
    );

    if (my $provider = $self->_conninfo_provider) {
      $args{conninfo_provider} = $provider;
    }
    else {
      $args{conninfo} = $self->{_conninfo};
    }

    DBIO::Async::Pool->new(%args);
  };
}


sub _async_broker_conninfo {
  my ($self, $mode) = @_;

  croak sprintf '%s has no AccessBroker attached to ask for connect info',
    ref($self) || $self
    unless $self->access_broker;

  my $info = $self->_broker_answer_connect_info(
    $self->current_access_broker_connect_info($mode)
  );
  my ($conninfo) = $self->_normalize_async_connect_info(
    $self->_normalize_conninfo($info)
  );
  return $conninfo;
}

# A broker's answer as connect info for the driver's _normalize_conninfo: the
# DBI form, or the transport's own shape as it is (see _async_broker_conninfo).
sub _broker_answer_connect_info {
  my ($self, $answer) = @_;

  return $self->_broker_answer_dbi_form($answer)
    if ref $answer eq 'ARRAY'
    && defined $answer->[0] && !ref $answer->[0] && $answer->[0] =~ /^dbi:/i;

  if (ref $answer eq 'HASH' && !exists $answer->{dsn} && exists $answer->{dbname}) {
    return $self->_broker_answer_dbi_form($self->_broker_params_dbi_form($answer));
  }

  my $own = ref $answer eq 'HASH' && exists $answer->{dsn}      ? [ $answer, {} ]
          : ref $answer eq 'ARRAY' && ref $answer->[0] eq 'HASH' ? $answer
          :                                                        undef;
  if ($own) {
    my @beside = sort keys %{ $self->_access_broker_call_attributes };
    croak sprintf
      'The DBD attributes given beside the AccessBroker (%s) cannot be merged '
    . "into what it answered, %s: that is this transport's own connect info, "
    . "whose attributes are the driver's shape. Have the broker answer a "
    . 'DBI-form arrayref or connection parameters, or give the attributes in '
    . "the broker's answer",
      join(', ', @beside), _broker_answer_shape($answer)
      if @beside;
    return $own;
  }

  croak sprintf
    '%s cannot connect from what the AccessBroker answered: %s. It takes a '
  . "DBI-form arrayref [ 'dbi:...', \$user, \$password, \\%%attrs ], a hashref "
  . 'of connection parameters with a dbname (dbname, host, port, user, '
  . 'password, ...), or its own connect info: a hashref with a dsn, or a '
  . '[ \\%%conninfo, \\%%opts ] pair',
    ref($self) || $self, _broker_answer_shape($answer);
}

# A hash of connection parameters (Static) as the DBI form, read the way
# DBIO::Storage::DBI::_normalize_connect_info reads it (core karr k239). Only
# the owning sync storage knows the DBD, so it builds the DSN.
sub _broker_params_dbi_form {
  my ($self, $params) = @_;
  my %attrs = %$params;

  my $dsn;
  if (defined $attrs{dbname} && $attrs{dbname} =~ /^dbi:/i) {
    # No owner is needed for this one, so it is read here -- as core's
    # _dsn_from_connect_params reads it (ADR 0057): host and port are parts of
    # the DSN and never DBD attributes, empty ones are dropped, and a set one
    # cannot be put into a whole DSN -- as an attribute it would be lost.
    $dsn = delete $attrs{dbname};
    my %part;
    @part{qw( host port )} = delete @attrs{qw( host port )};
    my @beside = grep { defined $part{$_} && length $part{$_} } qw( host port );
    croak 'Connection parameter(s) ' . join(', ', map { "'$_'" } @beside)
        . ' given beside a dbname that is a whole DSN: they cannot be put into '
        . 'it. Give them inside the DSN, or give dbname as a database name.'
      if @beside;
  }
  else {
    my $owner = $self->_owner_storage;
    croak sprintf
      'Cannot build a DSN from the connection parameters the AccessBroker '
    . 'answered, %s: which DBD driver they are for is known to the owning sync '
    . 'storage, and this %s backend has none. Connect through the schema -- '
    . "MyApp::Schema->connect(\$broker, { async => 'future_io' }) -- or use a "
    . 'broker that answers a DSN',
      _broker_answer_shape($params), ref($self) || $self
      unless $owner && $owner->can('_dsn_from_connect_params');
    $dsn = $owner->_dsn_from_connect_params(\%attrs);
  }

  my ($user, $password) = delete @attrs{qw( user password )};
  return [ $dsn, $user, $password, \%attrs ];
}

# A DBI-form answer ready for the driver: DBIO-private attributes stripped,
# the attribute hashes merged, pool_size out, the settings beside the broker in.
sub _broker_answer_dbi_form {
  my ($self, $info) = @_;

  my @info = do {
    # Core's strip also records the storage options it pulls out. That record
    # belongs to connect_info, not to one answer asked for per connection.
    local $self->{_storage_options};
    @{ $self->_strip_private_connect_attrs($info) };
  };

  my %attrs = map { %$_ } grep { ref $_ eq 'HASH' } @info[3, 4];
  delete $attrs{pool_size};

  return [
    @info[0 .. 2],
    $self->_merge_access_broker_settings(\%attrs, $self->_access_broker_call_attributes),
  ];
}

# A plain function: the shape of a broker's answer for an error message --
# types and hash keys, never values, which carry the password.
sub _broker_answer_shape {
  my ($value) = @_;
  return 'nothing (undef)' unless defined $value;
  return 'a plain string' unless ref $value;
  return sprintf 'a hashref with keys (%s)', join ', ', sort keys %$value
    if ref $value eq 'HASH';
  return sprintf 'an arrayref of (%s)', join ', ',
    map { !defined $_ ? 'undef' : ref $_ ? ref($_) . ' ref' : 'string' } @$value
    if ref $value eq 'ARRAY';
  return 'a ' . ref($value) . ' ref';
}

# --- Future::IO transport ---
# Concrete overrides of the DBIO::Storage::Async transport seams. The inherited
# Model-B orchestration (_run_crud & friends) calls these; they route through
# the Future::IO watcher seam below.


sub _query_async {
  my ($self, $sql, $bind, $bind_attrs) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  my $end = $self->_debug_query($sql, $bind, $bind_attrs);

  my $pool = $self->pool;
  my $held = $pool->acquire->then(sub {
    my $conn = shift;
    # The lease of this borrow, taken before anything can go on with the
    # connection; the release hands it back (karr k50, core k275).
    my $lease = $pool->_lease($conn);
    my $f = $self->_seam_future(_await_query_result => $conn, $sql, $bind);
    my $caller = $self->_flight_register($f, undef, $conn, $pool);
    $f->on_cancel($self->_abandon_on_cancel($conn, $pool));
    $f->on_fail($self->_mark_dead_on_fail($conn, $pool));
    $f->on_ready($self->_release_on_ready($conn, $pool, $caller, $lease));
    return $caller;
  });

  # The wait for the pool is held as the flight is: a caller that lets go of
  # its Future while still queued must not take the chain with it -- the
  # release would hand the connection to a waiter with nothing behind it
  # (karr k46). As core's txn_do_async holds its own sequence.
  $held->retain if $held->can('retain');
  # query_end of the trace, as the statement settles: done, failed or
  # cancelled. The coderef of core holds no bind (ADR 0044).
  $held->on_ready($end) if $end;
  return $held;
}


sub _abandon_on_cancel {
  my ($self, $conn, $pool) = @_;
  return sub { $self->_report_abandoned($conn, $pool) };
}

# Report a connection whose statement was cancelled in flight dead to $pool,
# the pool the statement was dispatched with; its hand-back then retires it.
# Without a pool there is nobody to tell. Never dies (see _abandon_on_cancel).
sub _report_abandoned {
  my ($self, $conn, $pool) = @_;
  return unless $pool;
  local $@;
  eval { $pool->_mark_connection_dead($conn); 1 }
    or warn "DBIO::Async: reporting an abandoned connection to the pool failed: $@";
  return;
}


sub _release_on_ready {
  my ($self, $conn, $pool, $caller, $lease) = @_;
  return sub { $self->_release_and_settle($conn, $pool, $caller, $_[0], $lease) };
}

# The body of the callback _release_on_ready builds: the connection goes back
# to the pool it was acquired from, then the caller's Future takes the
# statement's outcome. A release that dies still dies into whoever settled the
# statement, as it did when the caller held that Future itself -- but only
# once the caller has its outcome.
sub _release_and_settle {
  my ($self, $conn, $pool, $caller, $flight, $lease) = @_;
  my $died;
  {
    local $@;
    # With the borrow's lease when there is one: a release that comes after
    # the connection went on is then no release of this statement's holder
    # and the pool does not take it (karr k50, core k275). No lease -- a
    # caller of _release_on_ready that took none -- releases as ever.
    eval {
      defined $lease ? $pool->release($conn, $lease) : $pool->release($conn);
      1;
    } or $died = $@ || 'release died';
  }
  _settle_caller($caller, $flight);
  die $died if defined $died;
  return;
}


sub _mark_dead_on_fail {
  my ($self, $conn, $pool) = @_;
  return sub { $self->_mark_if_fatal($conn, $pool, @_) };
}

# The body of the callback _mark_dead_on_fail builds: ask the seam with the
# query's failure, report the connection to $pool -- the pool the statement
# was dispatched with -- when it is dead. Without a pool there is nobody to
# tell, which is no failed report. Nothing leaves here (see
# _mark_dead_on_fail).
sub _mark_if_fatal {
  my ($self, $conn, $pool, @failure) = @_;
  local $@;

  my $fatal;
  my $asked  = eval { $fatal = $self->_conn_error_is_fatal($conn, @failure); 1 };
  my $broken = $asked ? undef : ($@ || 'it died without a message');
  return unless $fatal || defined $broken;

  if (defined $broken) {
    chomp(my $why = "$broken");
    $self->_pool_report($pool, '_conn_error_is_fatal died, so the connection '
      . "is treated as dead: $why");
  }
  return unless $pool;

  eval { $pool->_mark_connection_dead($conn); 1 }
    or warn "DBIO::Async: reporting a dead connection to the pool failed: $@";
  return;
}

# Something went wrong where nothing may be thrown: tell $pool's on_error.
# Warned instead when there is no pool, or when its on_error dies in turn.
sub _pool_report {
  my ($self, $pool, $report) = @_;
  local $@;
  return if $pool && eval { $pool->{on_error}->($report); 1 };
  warn "DBIO::Async pool error: $report\n";
  return;
}


sub _query_async_pinned {
  my ($self, $conn, $sql, $bind, $bind_attrs) = @_;
  $bind //= [];
  $sql = $self->_transform_sql($sql);

  my $end = $self->_debug_query($sql, $bind, $bind_attrs);

  # Whichever way the statement goes, the Future the caller gets carries
  # query_end (the pinned path has three returns).
  my $f = $self->_pinned_send($conn, $sql, $bind);
  $f->on_ready($end) if $end;
  return $f;
}

# The dispatch of _query_async_pinned: unqueued, queued behind the statement
# in flight, or started on an idle connection.
sub _pinned_send {
  my ($self, $conn, $sql, $bind) = @_;

  return $self->_start_unqueued($conn, $sql, $bind)
    unless (reftype($conn) // '') eq 'HASH';

  my $queue = $conn->{_dbio_async_queue} //= { waiting => [] };
  if ($queue->{busy} || @{ $queue->{waiting} }) {
    my $limit = $self->async_option('max_pending_pinned');
    return $self->future_class->fail('not sent: ' . $limit . ' statements '
      . "already wait on this connection (max_pending_pinned)\n")
      if $limit && _queue_pending($queue) >= $limit;
    return $self->_queue_wait($queue, $sql, $bind);
  }
  return $self->_queue_start($conn, $queue, undef, $sql, $bind);
}


# The pinned dispatch itself, unqueued: the query on the wire, a dispatch that
# dies or returns no Future as a failed Future (core's _seam_future), and the
# k26 classification on a failure, reported to $pool.
sub _dispatch_pinned {
  my ($self, $conn, $pool, $sql, $bind) = @_;
  my $f = $self->_seam_future(_await_query_result => $conn, $sql, $bind);
  $f->on_fail($self->_mark_dead_on_fail($conn, $pool));
  return $f;
}

# A pinned statement on a connection that is no hashref: no queue, so it goes
# out at once -- held, and handed to its caller, like every other flight.
sub _start_unqueued {
  my ($self, $conn, $sql, $bind) = @_;
  my $pool   = $self->_built_pool;
  my $flight = $self->_dispatch_pinned($conn, $pool, $sql, $bind);
  my $caller = $self->_flight_register($flight, undef, $conn, $pool);
  $flight->on_ready(_settle_caller_cb($caller));
  return $caller;
}

sub _settle_caller_cb {
  my ($caller) = @_;
  return sub { _settle_caller($caller, $_[0]) };
}

# A statement for a connection that is busy: a pending Future for the caller,
# of the class of the statement in flight so that ->get runs its loop, and an
# entry at the back of the queue.
sub _queue_wait {
  my ($self, $queue, $sql, $bind) = @_;
  my $proto = ref $queue->{busy} ? $queue->{busy} : $queue->{last};
  my $proxy = $proto ? $proto->new : $self->future_class->new;
  my $entry = [ $proxy, $sql, $bind ];
  push @{ $queue->{waiting} }, $entry;
  $proxy->on_cancel(_queue_drop_cb($entry));
  return $proxy;
}

# Cancelled while waiting: empty the entry, so its SQL and binds go now and the
# queue skips it. Holds the entry weakly -- the Future must not keep it.
sub _queue_drop_cb {
  my ($entry) = @_;
  weaken($entry);
  return sub { @$entry = () if $entry };
}

# Put one statement on the wire, or refuse it on a connection a cancelled
# statement left behind, and settle $proxy -- the caller's Future, made here
# when the statement did not wait -- from it (_queue_settled).
sub _queue_start {
  my ($self, $conn, $queue, $proxy, $sql, $bind) = @_;
  $queue->{busy} = 1;   # a statement issued during the dispatch waits
  my $pool   = $self->_built_pool;
  my $refusal = $queue->{abandoned}
    // (_queue_conn_reported_dead($conn, $pool)
      ? 'not sent: this connection was reported dead to the pool '
        . "(_conn_error_is_fatal), so nothing more is sent on it\n"
      : undef);
  my $flight = defined $refusal
    ? $self->future_class->fail($refusal)
    : $self->_dispatch_pinned($conn, $pool, $sql, $bind);
  $queue->{busy} = $queue->{last} = $flight;
  $proxy = $self->_flight_register($flight, $proxy, $conn, $pool);
  $flight->on_ready($self->_queue_settled_cb($conn, $queue, $proxy, $pool));
  return $proxy;
}

sub _queue_settled_cb {
  my ($self, $conn, $queue, $proxy, $pool) = @_;
  return sub { $self->_queue_settled($conn, $queue, $proxy, $pool, $_[0]) };
}

# The statement in flight settled, so the connection is free. Nothing waiting:
# the queue is gone BEFORE the caller's callbacks run, and a statement they
# issue goes out at once -- a synchronous one too, such as every statement of
# a txn_do block, which core runs from the callback of BEGIN's Future (karr
# k34). Statements waiting: they were issued first and go first; the queue
# stays busy through the callbacks, so what those issue queues behind them,
# and advances once they have run. The backlog -- what was waiting when this
# outcome came in, issued before anyone knew it -- is counted before them.
sub _queue_settled {
  my ($self, $conn, $queue, $proxy, $pool, $flight) = @_;
  return $self->_queue_advance($conn, $queue, $pool, $flight)
    if $flight->is_cancelled;

  $queue->{backlog} = scalar @{ $queue->{waiting} };
  $self->_queue_idle($conn, $queue) unless $queue->{backlog};
  _settle_caller($proxy, $flight);
  $self->_queue_advance($conn, $queue, $pool, $flight) if $queue->{backlog};
  return;
}

# The caller's Future takes the outcome of the statement's. A cancelled
# statement was cancelled through that Future, or abandoned with its
# connection (_abandon_flights_on): either way the caller's is settled already.
sub _settle_caller {
  my ($caller, $flight) = @_;
  return if $caller->is_ready || $caller->is_cancelled || $flight->is_cancelled;
  return $caller->fail($flight->failure) if $flight->is_failed;
  return $caller->done($flight->get);
}

# Nothing in flight, nothing waiting: the connection is idle, and carries no
# queue -- unless a cancelled statement left it behind, or the pool closed it:
# then the queue stays, to refuse what comes.
sub _queue_idle {
  my ($self, $conn, $queue) = @_;
  delete $conn->{_dbio_async_queue} unless defined $queue->{abandoned};
  delete @$queue{qw( busy last backlog )};
  return;
}

# After the settled statement's callbacks: dispatch the next one waiting, or
# leave the connection idle. See THE PINNED STATEMENT QUEUE for what a failure
# and a cancel change.
sub _queue_advance {
  my ($self, $conn, $queue, $pool, $flight) = @_;
  $queue->{busy} = 1;   # what the refusals below make callers issue waits

  if ($flight->is_cancelled) {
    $self->_queue_abandon($conn, $queue, $pool);
  }
  elsif ($flight->is_failed && _queue_conn_reported_dead($conn, $pool)) {
    my $why = 'not sent: the statement before it on this connection failed, '
            . 'and the connection was reported dead (_conn_error_is_fatal), '
            . "so what was queued behind it is not put on it\n";
    for my $entry (splice @{ $queue->{waiting} }, 0, $queue->{backlog} // 0) {
      my ($proxy) = splice @$entry;
      $proxy->fail($why) if $proxy && !$proxy->is_ready;
    }
  }
  delete $queue->{backlog};

  while (my $entry = shift @{ $queue->{waiting} }) {
    my ($proxy, $sql, $bind) = splice @$entry;
    next unless $proxy && !$proxy->is_ready;
    $self->_queue_start($conn, $queue, $proxy, $sql, $bind);
    return;
  }

  $self->_queue_idle($conn, $queue);
  return;
}

# The statement in flight was cancelled; its result is still on its way.
# Refuse everything from here on, and have the pool retire the connection. A
# connection closed under its statement (_abandon_flights_on) refuses already,
# and the pool that closed it needs no telling.
sub _queue_abandon {
  my ($self, $conn, $queue, $pool) = @_;
  return if defined $queue->{abandoned};
  $queue->{abandoned} = 'not sent: a statement on this connection was '
    . 'cancelled while in flight, and its result is still unread on the '
    . "connection, so nothing more is sent on it\n";
  $self->_report_abandoned($conn, $pool);
  return;
}

# Has $pool -- the pool the failed statement was dispatched with -- been told
# $conn is dead? Asked once _mark_dead_on_fail has run. A plain function: no
# pool, nobody told.
sub _queue_conn_reported_dead {
  my ($conn, $pool) = @_;
  return 0 unless $pool;
  return $pool->can('_connection_is_dead') && $pool->_connection_is_dead($conn)
    ? 1 : 0;
}


# The storage's pool as it stands -- never built here (see STATEMENTS IN
# FLIGHT). The slot is the one core's disconnect and connected read.
sub _built_pool { $_[0]->{pool} }

# Enter a dispatched statement into the register and return the Future its
# caller gets -- $caller if it has one already (a statement that waited in the
# pinned queue), else a new one of the flight's class, so that ->get on it
# runs the flight's loop. The first thing a settled flight does is leave the
# register; the caller's cancel reaches the flight through _let_go. A
# statement that never took off -- its dispatch died, or it was refused -- is
# settled already and is not entered: there is nothing to hold.
sub _flight_register {
  my ($self, $flight, $caller, $conn, $pool) = @_;
  $caller //= $flight->new;
  return $caller if $flight->is_ready;

  my $key = refaddr $flight;
  my $entry = $self->{_flights}{$key} = {
    flight => $flight,
    caller => $caller,
    conn   => $conn,
    pool   => $pool,
    seq    => ++$self->{_flight_seq},
    pid    => $$,
  };
  $self->_statement_timer_arm($key, $entry);
  $flight->on_ready($self->_flight_landed_cb($key));
  $caller->on_cancel($self->_flight_cancel_cb($flight));
  return $caller;
}

# Named subs, as _release_on_ready is one: each callback closes over what it
# is handed, never over a statement's SQL or bind values (ADR 0044).
sub _flight_landed_cb {
  my ($self, $key) = @_;
  return sub { $self->_flight_forget($key); return };
}

# Take a flight out of the register and stop its statement_timeout timer, if
# it has one. A timer that fired is gone from the entry already.
sub _flight_forget {
  my ($self, $key) = @_;
  my $entry = delete $self->{_flights}{$key} or return undef;
  if (my $timer = delete $entry->{timer}) {
    local $@;
    eval { $self->_let_go($timer); 1 }
      or $self->_pool_report($entry->{pool}, 'Stopping the statement_timeout '
        . "timer of a settled statement died: $@");
  }
  return $entry;
}

# The caller's Future holds the flight weakly: the register is what holds a
# flight, and the flight holds its caller's Future. A strong reference back
# would make the two keep each other, and the register an ornament.
sub _flight_cancel_cb {
  my ($self, $flight) = @_;
  weaken($flight);
  return sub { $self->_let_go($flight) if $flight };
}


sub _abandon_flights_on {
  my ($self, $conn) = @_;
  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
  return unless ref $conn;

  # Finished, whether or not anything is on it: from here on the queue exists
  # to refuse (_queue_start), and stays (_queue_idle). Inside an eval -- a
  # hash that will not take the key must not cost the close.
  if ((reftype($conn) // '') eq 'HASH') {
    local $@;
    eval {
      my $queue = $conn->{_dbio_async_queue} //= { waiting => [] };
      $queue->{abandoned} //= 'not sent: this connection was closed -- the '
        . 'storage was disconnected, its pool shut down, or the connection '
        . "retired -- so nothing more is sent on it\n";
      1;
    };
    $self->_ready_let_go($conn);
  }

  my $addr    = refaddr $conn;
  my @flights = sort { $a->{seq} <=> $b->{seq} }
    grep { ref $_->{conn} && refaddr($_->{conn}) == $addr }
    values %{ $self->{_flights} || {} };
  $self->_flight_abandon($_) for @flights;
  return;
}

# End one flight whose connection is being closed: off the register, the
# caller told, the poll let go of. The caller is failed first, so it hears
# what happened rather than seeing a cancel; letting go of the flight then
# runs the transport's own callbacks on it, which find the caller settled and
# a pool that no longer takes the connection. A callback that dies on either
# way is reported, not thrown (see _abandon_flights_on).
sub _flight_abandon {
  my ($self, $entry) = @_;
  my ($flight, $caller) = @$entry{qw( flight caller )};
  $self->_flight_forget(refaddr $flight);

  my @died;
  {
    local $@;
    eval {
      $caller->fail('Statement abandoned in flight: its connection was '
        . 'closed under it -- the storage was disconnected, its pool shut '
        . 'down, or the connection retired -- so its answer is not read, and '
        . "whether it took effect is unknown\n") unless $caller->is_ready;
      1;
    } or push @died, $@ || 'unknown error';
    eval { $self->_let_go($flight); 1 } or push @died, $@ || 'unknown error';
  }
  for my $death (@died) {
    chomp(my $why = "$death");
    $self->_pool_report($entry->{pool}, 'A callback died as a statement in '
      . "flight was failed with the close of its connection: $why");
  }
  return;
}


sub async_option_names { qw( statement_timeout max_pending_pinned ) }

# The values of this transport's own options (core checks its own). The
# messages name the option and the form, never the value.
sub _assert_async_option {
  my ($self, $name, $value) = @_;

  if ($name eq 'statement_timeout') {
    my $number = defined $value && !ref $value && looks_like_number($value)
      && $value == $value && abs($value) != 9**9**9;
    DBIO::Exception->throw("Connect option 'statement_timeout' takes a number "
      . 'of seconds, 0 or more (0 turns the timeout off)')
      unless $number && $value >= 0;
    return;
  }
  if ($name eq 'max_pending_pinned') {
    DBIO::Exception->throw("Connect option 'max_pending_pinned' takes a "
      . 'positive integer')
      unless defined $value && !ref $value && $value =~ /\A[1-9][0-9]*\z/;
    return;
  }
  return $self->SUPER::_assert_async_option($name, $value);
}

# Arm the statement_timeout timer of a statement just put on the wire, and keep
# it on the register entry; _flight_forget stops it when the statement settles.
# A named sub chain, as everywhere: the timer's callback closes over the key
# and a weak storage, never the SQL or the binds (ADR 0044).
sub _statement_timer_arm {
  my ($self, $key, $entry) = @_;
  my $seconds = $self->async_option('statement_timeout') or return;

  my $timer;
  local $@;
  my $armed = eval { $timer = $self->_delay($seconds); 1 };
  unless ($armed && blessed($timer) && $timer->can('on_done') && $timer->can('cancel')) {
    $self->_pool_report($entry->{pool}, 'statement_timeout could not be armed, '
      . 'so the statement runs without a time limit: '
      . ($armed ? '_delay returned no Future' : ($@ || '_delay died')));
    return;
  }
  $entry->{timeout} = $seconds;
  $entry->{timer}   = $timer;
  $timer->on_done(_statement_timeout_cb($self, $key));
  return;
}

sub _statement_timeout_cb {
  my ($self, $key) = @_;
  weaken($self);
  return sub { $self->_statement_timed_out($key) if $self; return };
}

# The time of a statement on the wire is up: its connection is reported dead
# first (so what its caller does next finds it so), the caller hears why, and
# the flight is let go of -- which cancels it, runs the transport's callbacks
# (pooled: the retiring release; pinned: the queue's refusal of what waits) and
# finds the caller settled. A flight inherited across a fork does nothing in
# the child. Nothing leaves here: a callback that dies goes to the pool's
# on_error.
sub _statement_timed_out {
  my ($self, $key) = @_;
  my $entry = $self->{_flights}{$key} or return;
  return unless $entry->{pid} == $$;
  delete $entry->{timer};   # it fired

  my ($flight, $caller) = @$entry{qw( flight caller )};
  $self->_report_abandoned($entry->{conn}, $entry->{pool});

  my @died;
  {
    local $@;
    eval {
      $caller->fail("statement timed out after $entry->{timeout} seconds "
        . '(statement_timeout): the statement was cancelled and its '
        . "connection retired, and whether it took effect is unknown\n")
        unless $caller->is_ready;
      1;
    } or push @died, $@ || 'unknown error';
    eval { $self->_let_go($flight); 1 } or push @died, $@ || 'unknown error';
  }
  for my $death (@died) {
    chomp(my $why = "$death");
    $self->_pool_report($entry->{pool}, 'A callback died as a statement was '
      . "failed with its statement_timeout: $why");
  }
  return;
}

# How many statements wait in the queue of a pinned connection. A waiting
# statement whose caller cancelled it is an emptied entry and does not count.
sub _queue_pending {
  my ($queue) = @_;
  return scalar grep { @$_ } @{ $queue->{waiting} };
}


# --- Future::IO Watcher Seam ---
#
# These methods isolate the Future::IO dependency. A driver that uses its
# own event-loop integration overrides _query_async / _query_async_pinned
# entirely and never calls these.



sub _await_readable {
  my ($self, $conn) = @_;
  return Future::IO->poll($self->_conn_poll_fh($conn), POLLIN)
    ->then(_in_this_process_cb($$));
}

# What every poll continues with: its result, in the process that made the
# poll -- and in any other a Future that never settles, so that nothing chained
# onto the poll ever runs there. A plain function, and a named one: the
# callback closes over a pid and nothing else (ADR 0044).
sub _in_this_process_cb {
  my ($pid) = @_;
  return sub { return $$ == $pid ? Future->done(@_) : Future->new };
}


sub _let_go {
  my ($self, $f) = @_;
  $f->cancel if $f->can('cancel') && !$f->is_ready;
  return;
}


sub _conn_poll_fh {
  my ($self, $conn) = @_;
  return $conn->{_dbio_async_poll_fh} ||= do {
    my $fd = $self->_conn_fileno($conn);
    open my $fh, '+<&', $fd
      or croak 'Cannot dup async connection fd '
             . (defined $fd ? $fd : 'undef') . " for Future::IO poll: $!";
    $fh;
  };
}


sub _await_conn_ready {
  my ($self, $conn, $watch) = @_;
  return $self->future_class->done($conn) if $self->_conn_ready($conn);

  my $first = !$watch;
  $watch = $self->_ready_watch($conn) if $first;

  my $ready = $self->future_class->call(sub {
    my $poll = $self->_await_readable($conn);
    if ($watch) {
      $watch->{poll} = $poll;
      weaken($watch->{poll});
    }
    return $poll->then($self->_ready_next_cb($conn, $watch));
  });

  if ($first and $watch) {
    $watch->{ready} = $ready;
    weaken($watch->{ready});
    $ready->on_ready(_ready_settled_cb($conn, $watch));
  }
  return $ready;
}

# One connection's wait for readiness, kept on the connection hashref; none
# for a connection that is no hashref (or will not take the key).
sub _ready_watch {
  my ($self, $conn) = @_;
  return unless ref $conn and (reftype($conn) // '') eq 'HASH';
  my $watch = {};
  local $@;
  eval { $conn->{_dbio_async_ready} = $watch; 1 } or return;
  return $watch;
}

# Named subs, as _release_on_ready is one: they close over the connection and
# the bookkeeping, never over a caller's data (ADR 0044).
sub _ready_next_cb {
  my ($self, $conn, $watch) = @_;
  return sub { return $self->_await_conn_ready($conn, $watch) };
}

sub _ready_settled_cb {
  my ($conn, $watch) = @_;
  return sub {
    my $mine = $conn->{_dbio_async_ready};
    delete $conn->{_dbio_async_ready} if $mine and $mine == $watch;
    return;
  };
}

# The pool is closing $conn (_abandon_flights_on): the poll its readiness wait
# is on is let go of, the one place a poll is given up. Letting go of the poll
# alone settles nothing -- the Future above it stays pending -- so the wait is
# ended in a second step, _ready_end, which the pool takes once its own
# bookkeeping of the close is done. Never dies.
sub _ready_let_go {
  my ($self, $conn) = @_;
  my $watch = $conn->{_dbio_async_ready} or return;
  my $poll  = $watch->{poll} or return;

  local $@;
  eval { $self->_let_go($poll); 1 } or do {
    chomp(my $why = $@ || 'unknown error');
    $self->_pool_report($self->_built_pool, 'A callback died as the readiness '
      . "poll of a connection was let go of with its close: $why");
  };
  return;
}

# The second step (DBIO::Async::Pool::_retire_connection): the Future the pool
# waits on for a connection that was retired while it was coming up FAILS. The
# pool's chain on it is what offers the slot to the next caller (core k260 /
# k261), which a cancel would not. It comes after the pool parked that chain
# (core k261), so the caller hears the pool's own reason, not this one. Never
# dies.
sub _ready_end {
  my ($self, $conn) = @_;
  return unless ref $conn and (reftype($conn) // '') eq 'HASH';
  my $watch = delete $conn->{_dbio_async_ready} or return;
  my $ready = $watch->{ready} or return;

  local $@;
  eval {
    $ready->fail('Connection closed while it was coming up -- the connection '
      . "was retired\n") unless $ready->is_ready;
    1;
  } or do {
    chomp(my $why = $@ || 'unknown error');
    $self->_pool_report($self->_built_pool, 'A callback died as the readiness '
      . "wait of a connection was failed with its retirement: $why");
  };
  return;
}


sub _await_query_result {
  my ($self, $conn, $sql, $bind) = @_;

  return $self->future_class->call(sub {
    $self->_submit_query($conn, $sql, $bind);
    return $self->_await_readable($conn)->then($self->_collect_on_readable($conn));
  });
}


sub _collect_on_readable {
  my ($self, $conn) = @_;
  return sub { $self->_collect_result($conn) };
}

# --- LISTEN / NOTIFY over Future::IO (core ADR 0056, ADR 0005, karr k22) ---
#
# The Future::IO-generic listen seams, once for every future_io driver: the
# timer, the watch loop, the pooled notify. The machinery that calls them is
# core's; the DB-specific halves (_listen_drain, _notify_sql and core's
# croaking _listen_open/_close/_subscribe/_unsubscribe/_probe) are the driver's.



sub _listen_delay {
  my ($self, $seconds) = @_;
  return Future::IO->sleep($seconds);
}


sub _listen_poll_interval { return undef }


sub _listen_watch {
  my ($self, $conn) = @_;
  my $interval = $self->_listen_poll_interval;
  croak '_listen_poll_interval must be undef (socket-driven) or a positive '
      . "number of seconds (timer-driven), got '$interval'"
    if defined $interval && !(looks_like_number($interval) && $interval > 0);

  $self->_conn_poll_fh($conn) unless defined $interval;

  $self->_watch_stop($conn);
  my $first = $self->_listen_delay($interval // 0);
  my $watch = $conn->{_dbio_async_listen_watch} = {
    pid      => $$,
    interval => $interval,
  };
  $self->_watch_await($conn, $watch, $first, '_watch_elapsed');
  return;
}


sub _listen_unwatch {
  my ($self, $conn) = @_;
  $self->_watch_stop($conn);
  return;
}


sub _notify_send {
  my ($self, $channel, $payload) = @_;
  my ($sql, $bind) = $self->_notify_sql($channel, $payload);
  return $self->_query_async($sql, $bind);
}

# --- the watch loop's private steps ---
#
# Named subs, not nested closures, for the reason _release_on_ready gives: a
# callback built here closes over exactly what it is handed.

sub _watch_stop {
  my ($self, $conn) = @_;
  return unless ref $conn;
  # Off the connection FIRST: cancelling runs the pending Future's on_ready
  # callback synchronously, and that callback must find the watch gone.
  my $watch   = delete $conn->{_dbio_async_listen_watch} or return;
  my $pending = delete $watch->{pending} or return;
  $self->_let_go($pending);
  return;
}

sub _watch_live {
  my ($self, $conn, $watch) = @_;
  my $current = $conn->{_dbio_async_listen_watch};
  return $current
      && refaddr($current) == refaddr($watch)
      && $watch->{pid} == $$;
}

sub _watch_await {
  my ($self, $conn, $watch, $f, $step) = @_;
  $watch->{pending} = $f;
  $f->on_ready($self->_watch_callback($conn, $watch, $step));
  return;
}

sub _watch_callback {
  my ($self, $conn, $watch, $step) = @_;
  weaken(my $weak_self  = $self);
  weaken(my $weak_conn  = $conn);
  weaken(my $weak_watch = $watch);
  return sub {
    my ($f) = @_;
    my ($self, $conn, $watch) = ($weak_self, $weak_conn, $weak_watch);
    return unless $self && $conn && $watch && $self->_watch_live($conn, $watch);
    delete $watch->{pending};
    $self->_watch_run($conn, $watch, $step, $f);
    return;
  };
}

# Every step runs from a Future callback, inside the event loop: an error
# escaping here would surface in whatever unrelated ->get drove the loop.
sub _watch_run {
  my ($self, $conn, $watch, $step, @args) = @_;
  my $err;
  {
    local $@;
    eval { $self->$step($conn, $watch, @args); 1 }
      or $err = $@ || 'the listen watch died without a message';
  }
  $self->_watch_lost($conn, $watch, $err) if defined $err;
  return;
}

sub _watch_lost {
  my ($self, $conn, $watch, $err) = @_;
  return unless $self->_watch_live($conn, $watch);
  $self->_watch_stop($conn);
  local $@;
  eval { $self->_listen_lost($conn, $err); 1 }
    or warn "DBIO LISTEN error: reporting a lost listen connection failed: $@";
  return;
}

# A timer elapsed: the first tick after the watch started, or an interval.
sub _watch_elapsed {
  my ($self, $conn, $watch, $f) = @_;
  _watch_check($f, 'the listen watch timer');
  return $self->_watch_drain($conn, $watch);
}

sub _watch_polled {
  my ($self, $conn, $watch, $f) = @_;
  _watch_check($f, 'polling the listen connection');
  return $self->_watch_arm($conn, $watch)
    unless $self->_watch_readable_now($conn);
  return $self->_watch_drain($conn, $watch);
}

sub _watch_drain {
  my ($self, $conn, $watch) = @_;
  my $drained = $self->_listen_drain($conn);
  return $self->_watch_await($conn, $watch, $drained, '_watch_drained')
    if blessed($drained) && $drained->can('then');
  return $self->_watch_deliver($conn, $watch, $drained);
}

sub _watch_drained {
  my ($self, $conn, $watch, $f) = @_;
  _watch_check($f, '_listen_drain');
  my ($notifications) = $f->get;
  return $self->_watch_deliver($conn, $watch, $notifications);
}

sub _watch_deliver {
  my ($self, $conn, $watch, $notifications) = @_;
  die '_listen_drain must return an arrayref of [$channel, $payload, '
    . "\$sender_pid] tuples, or a Future of one\n"
    unless ref $notifications eq 'ARRAY';

  for my $n (@$notifications) {
    return unless $self->_watch_live($conn, $watch);
    die '_listen_drain returned a notification that is not an arrayref '
      . "[\$channel, \$payload, \$sender_pid]\n"
      unless ref $n eq 'ARRAY';
    $self->_listen_dispatch(@{$n}[0 .. 2]);
  }

  return unless $self->_watch_live($conn, $watch);
  return $self->_watch_arm($conn, $watch);
}

sub _watch_arm {
  my ($self, $conn, $watch) = @_;
  return $self->_watch_await($conn, $watch,
    $self->_listen_delay($watch->{interval}), '_watch_elapsed')
    if defined $watch->{interval};
  return $self->_watch_await($conn, $watch,
    $self->_await_readable($conn), '_watch_polled');
}

# Is the socket readable right now? Asked after every poll, because the
# built-in Future::IO implementation may report a poll ready without having
# selected (see THE LISTEN WATCH LOOP). A select error counts as readable: the
# drain is what finds out whether the connection is dead.
sub _watch_readable_now {
  my ($self, $conn) = @_;
  my $rin = '';
  vec($rin, fileno($self->_conn_poll_fh($conn)), 1) = 1;
  return select($rin, undef, undef, 0) != 0;
}

# A plain function: die when a Future the loop awaited did not complete.
sub _watch_check {
  my ($f, $what) = @_;
  die "$what was cancelled\n" if $f->is_cancelled;
  my $err = $f->failure;
  return unless defined $err;
  chomp($err = "$err");
  die "$what failed: $err\n";
}

# --- Transaction context ---
#
# NOT seam hooks: this transport ships its own TransactionContext, so it can
# answer both of these itself instead of re-croaking over core's concrete
# defaults (karr k13). An adapter overrides them only for a different context
# class or constructor key.


sub _txn_context_class { 'DBIO::Async::TransactionContext' }


sub _txn_conn_accessor { 'txn_conn' }

# --- DB-specific seam hooks ---
#
# Filled in by a concrete DBD subclass; each croaks until provided. The
# SQL-shaping and pipeline seams are inherited as croaking seams from
# DBIO::Storage::Async. These are the ones specific to the Future::IO transport,
# plus _normalize_conninfo, whose inherited identity default does not fit an
# abstract transport -- a concrete backend must name its own conninfo shape.
# _conn_error_is_fatal and _idle_connection_alive are the ones with a default:
# false and true, so a driver that fills neither keeps the behaviour from
# before them (karr k26, k28).


sub _submit_query {
  croak 'Subclass must override _submit_query($conn, $sql, $bind)';
}


sub _collect_result {
  croak 'Subclass must override _collect_result($conn)';
}


sub _normalize_conninfo {
  croak 'Subclass must override _normalize_conninfo($info)';
}


sub _create_pool_connection {
  croak 'Subclass must override _create_pool_connection($conninfo)';
}


sub _shutdown_pool_connection {
  croak 'Subclass must override _shutdown_pool_connection($conn)';
}


sub _conn_ready {
  croak 'Subclass must override _conn_ready($conn)';
}


sub _conn_fileno {
  croak 'Subclass must override _conn_fileno($conn)';
}


sub _conn_error_is_fatal { 0 }


sub _idle_connection_alive { 1 }


sub _listen_drain {
  croak 'Subclass must override _listen_drain($conn)';
}


sub _notify_sql {
  croak 'Subclass must override _notify_sql($channel, $payload)';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Async::Storage - Future::IO transport backend for DBIO async storage

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The C<future_io> async backend (ADR 0030): one loop-agnostic transport that
drives a driver's own non-blocking DBD binding through L<Future::IO>. The
event loop is chosen by loading a C<Future::IO::Impl::*> adapter (see
L</FUTURE::IO IMPLEMENTATIONS>), not by picking a distribution.

The B<Model-B orchestration> -- connect-info normalisation, the CRUD runner
(L<DBIO::Storage::Async/_run_crud> with its pooled and pinned runners), INSERT
returned-columns mapping, L<DBIO::Storage::Async/txn_do_async> bracketing
through the generic L<DBIO::Storage::Async::TransactionContext>, and the
L<DBIO::Storage::Async/pipeline> scaffold -- is inherited concretely from
L<DBIO::Storage::Async> (ADR 0030 §4). This class supplies only the
B<transport>: the L<Future::IO> query execution (L</_query_async> /
L</_query_async_pinned> over L</_await_query_result>), the L<Future>
implementation (L</future_class>) and the connection pool (L</pool>), plus the
DB-specific seam hooks a concrete DBD subclass fills in.

=head1 METHODS

=head2 future_class

Returns C<'Future'> -- this backend uses L<Future> from CPAN.

=head2 transport_capabilities

  my @caps = DBIO::Async::Storage->transport_capabilities;   # ('on_connect_replay')

Class method (see L<DBIO::Storage::Async/transport_capabilities>). Declares the
named transport capabilities this C<future_io> transport provides, so
L<DBIO::Storage::DBI/_async_storage> lets an async extension layer that declares
a matching C<required_transport_capabilities> compose onto it (and croaks on a
shortfall rather than silently dropping the feature).

This transport declares C<on_connect_replay>: its pool
(L<DBIO::Async::Pool>, a L<DBIO::Storage::PoolBase>) drives core's
L<DBIO::Storage::Async/_setup_pool_connection> on every freshly-spawned
connection, and the C<< { dbh => $dbh } >> connection shape is handled by the
base C<_run_pool_connect_statement> -- so each pooled async connection replays
the owning sync storage's C<on_connect_do>/C<on_connect_call> (and the
C<on_disconnect_*> actions at shutdown) end to end. A concrete
DBD subclass inherits this obligation for free.

=head2 pool

Returns the L<DBIO::Async::Pool> connection pool, created lazily on first
access. Fed the per-spawn C<conninfo_provider> when an AccessBroker is attached
(see L<DBIO::Storage::Async/_conninfo_provider>), otherwise the static
conninfo.

Building it is for whatever starts work -- a query, a transaction. What ends
work does not call this: a statement that settles talks to the pool it was
dispatched with (L</STATEMENTS IN FLIGHT>), so a storage that was
disconnected is not given a new pool by something that merely finished.

=head2 _async_broker_conninfo

  my $conninfo = $storage->_async_broker_conninfo($mode);

AccessBroker seam (see L<DBIO::Storage::Async/ACCESSBROKER CONSUMPTION>),
called through L<DBIO::Storage::Async/_conninfo_provider> for every new
connection -- each pool spawn, and a driver's listen connection: ask the
attached broker for its current connect info -- anew each time, so rotated
credentials reach the next connection -- and return one storage-native
conninfo built from it. The broker's answer may come in any of these shapes:

=over 4

=item * B<A DBI-form arrayref> C<< [ 'dbi:...', $user, $password, \%attrs ] >>,
as L<DBIO::AccessBroker::Vault> answers, and L<DBIO::AccessBroker::HostBound>
over it. The DBIO-private attributes -- C<async>, C<quote_names>, the storage
options and the rest -- are stripped the way core strips them from a direct
connect (L<DBIO::Storage::Async/connect_info>): a Vault broker selects this
transport with C<< dbi_attrs => { async => 'future_io' } >>, and C<async> is
no DBD attribute. A fifth element C<\%extra_attributes> joins C<\%attrs>, the
later winning, as on the sync storage. C<pool_size> is dropped: the pool was
sized from the answer when the broker was attached, and it is no DBD
attribute either.

=item * B<A hashref of connection parameters> -- C<dbname>, C<host>,
C<port>, C<user>, C<password> -- as L<DBIO::AccessBroker::Static> answers, and
L<DBIO::AccessBroker::HostBound> over it. Read the way the sync storage reads
it: C<dbname>, C<host> and C<port> become the DSN,
C<user> and C<password> the user and password, every other key a DBD
attribute; then as a DBI-form answer. C<dbname>, C<host> and C<port> are never
DBD attributes, and an empty one -- C<undef>, as Static answers a part not
given, or the empty string -- is as none given. A C<dbname> that starts with
C<dbi:> is the DSN, with or without an owner; a C<host> or C<port> set beside
it cannot be put into it and croaks, naming the keys (core ADR 0057). Otherwise only the owning sync storage
(L<DBIO::Storage::Async/_owner_storage>) knows which DBD driver the parameters
are for, so the DSN is built by its C<_dsn_from_connect_params>
(L<DBIO::Storage::DBI>). A backend without an owner -- constructed directly
rather than reached through a schema connected with
C<< { async => 'future_io' } >> -- croaks here, saying so.

=item * B<This transport's own connect info>: a hashref with a C<dsn>, or a
C<< [ \%conninfo, \%opts ] >> pair -- what a broker written for one transport
answers from C<connect_info_for_storage>. Taken as it is, as
L<DBIO::Storage::Async/connect_info> takes it.

=back

The result goes through the driver's C<_normalize_conninfo> -- for the first
two shapes as the DBI form C<< [ $dsn, $user, $password, \%attrs ] >>, exactly
what a direct connect with a DSN hands it -- and core's C<pool_size> split.
This base knows no DBD; what the driver's connect receives is the driver's
shape.

Connection settings given beside the broker (C<< connect($broker, \%options)
>>) reach every connection built from a DBI-form or connection-parameter
answer: the DBD attributes among them
(L<DBIO::Storage::Async/_access_broker_call_attributes>) are merged into
C<\%attrs> by C<_merge_access_broker_settings> -- a setting given in both
places must have the same value, or this throws naming it. Core keeps them
empty unless the transport declares C<broker_connect_options>, which this base
does not; a driver that declares it gets the merge from here. They cannot be
merged into a transport's own connect info, whose attributes are the driver's
shape: that combination croaks rather than drop them.

Any other answer croaks, naming its shape -- types and hash keys, never the
values, which carry the password.

Without a broker attached it croaks saying so. The provider
outlives a broker detached through L<DBIO::Storage/clear_access_broker> -- on
the storage, and in a pool built with it -- and nothing is answered then,
which is no broker's answer and is not reported as one. Core's provider
refuses with the same words before it asks (L<DBIO::Storage::Async/_conninfo_provider>);
this check is the seam's own, for a call that does not come through the
provider.

=head2 _query_async

  my $future = $storage->_query_async($sql, $bind, $bind_attrs);

Transport override: execute a query on a freshly-acquired pooled connection,
releasing it once the statement has settled. C<$bind_attrs> is optional and
for the trace alone (L</TRACE>); the wire gets the bare C<$bind>.

The Future it returns is the B<caller's own>. The statement's Future -- the
flight: the L<Future::IO> poll and the collect chained onto it -- is held by
the storage until it settles, and so is the wait for the pool before it (see
L</STATEMENTS IN FLIGHT>). A caller may keep the returned Future,
chain on it, C<< ->get >> it -- it is of the flight's class and runs its loop
-- or let go of it: the statement is collected and its connection handed back
either way. The connection is back in the pool B<before> the caller's
callbacks run, so a query issued from one finds it.

Receives SQL in the C<sql_maker> C<?>-placeholder dialect (the contract of the
core seam) and shapes it into the driver's own dialect B<internally>, up
front, through L<DBIO::Storage::Async/_transform_sql> before the query reaches
the wire. Callers do not pre-shape: the ADR 0032 §6 sequencing is finished
and core's orchestration has no C<_transform_sql> call site left.

A C<?>-E<gt>C<$N>-style rewrite must nonetheless be idempotent --
already-shaped SQL (no bare C<?> left to touch) passes through unchanged, and
a C<?> inside a quoted literal is never touched. That is a standing property
of a seam that runs on every single query, not a leftover of the transition
window that motivated it.

The dispatch goes through core's L<DBIO::Storage::Async/_seam_future>, and a
die there becomes a failed Future, the pattern core documents. The release
hangs off the query Future, and that Future exists only once
L</_await_query_result> has returned. A dispatch that croaks synchronously --
I<another operation is in progress>, I<not connected> -- never gets that far,
so without the guard the connection would stay checked out, and a pool of N
would be wedged for good after N such calls. The base L</_await_query_result>
wraps its own dispatch in C<< Future->call >>, but a driver may override that
seam and owes no such wrapper, so the guarantee lives here. As a failed Future
the die takes the same release as every other outcome, and the caller sees the
dispatch's own error. A driver's seam that returns no Future at all --
C<undef>, a plain value -- fails the same way, with an error naming the
backend class and the seam.

A query that fails -- whether its dispatch died or the Future failed later --
asks the driver whether it took its connection with it
(L</_conn_error_is_fatal>), B<before> the release runs: the callback
L</_mark_dead_on_fail> builds is registered ahead of the one
L</_release_on_ready> builds, and a L<Future> runs its callbacks in the order
they were registered. A connection the driver answers dead for is reported to
the pool (L<DBIO::Storage::PoolBase/_mark_connection_dead>), so the release
retires it instead of putting it back on the idle list. The caller still sees
the query's own error.

A query B<cancelled> while in flight retires its connection too.
The cancel -- on the returned Future, or on any Future chained on it, which
passes the cancel down -- reaches the flight (L</_let_go>) and drops the
L<Future::IO> poll, but the statement is on the server and its result on its
way, unread. Handed back as it was, the
connection would go to the next borrower, whose query the DBD then refuses
(DBD::Pg: I<another command is already in progress>). The base cannot read
that result without the driver, nor cancel the statement on the server, so the
callback L</_abandon_on_cancel> builds reports the connection dead to the pool
before the release runs -- a L<Future> runs its C<on_cancel> callbacks before
any C<on_ready> one -- and the release retires it; a caller queued for the slot
gets a fresh connection. That is what L</_query_async_pinned> does with a
cancelled statement (L</THE PINNED STATEMENT QUEUE>).
L</_conn_error_is_fatal> is not asked: a cancel is no failure, and says nothing
about the session. A cancel that comes while the caller still waits for the
pool dispatched nothing and retires nothing.

A statement that outlasts the connect option C<statement_timeout> is cancelled
in flight the same way, and its caller's Future fails with the timeout
(L</TIMEOUTS AND LIMITS>).

Draining instead -- keep the connection, await L</_collect_result> and throw
the result away -- is not done. How far the cancel reached into the driver's
collect is unknowable here, a result can take as long as the query the caller
just gave up on, and the pool slot would be held for all of it.

A query whose connection is B<closed under it> -- the storage disconnected,
the pool shut down -- fails where that happens; see L</STATEMENTS IN FLIGHT>.

The callbacks below are handed the pool the connection was acquired from, and
talk to that one. None of them asks L</pool>, which would build a pool for a
statement that ends after its storage was disconnected.

=head2 _abandon_on_cancel

  my $cb = $storage->_abandon_on_cancel($conn, $pool);
  $query_future->on_cancel($cb);

Build the callback a pooled query Future runs when it is cancelled in flight:
report C<$conn> dead to C<$pool>, the pool it was acquired from
(L<DBIO::Storage::PoolBase/_mark_connection_dead>), so the release that follows
retires it rather than idling it with an unread result on it (see
L</_query_async>). A named sub for the reason L</_release_on_ready> is one: it
closes over the connection and its pool, not over the SQL and the caller's
bind arrayref (ADR 0044).

The callback never dies. A L<Future> runs its C<on_cancel> callbacks from
inside C<cancel>, with no C<eval> of its own: a die would escape into the
caller's C<cancel> and leave the Future unmarked, the release never run. A
failing report is warned about instead.

=head2 _release_on_ready

  my $cb = $storage->_release_on_ready($conn, $pool, $caller, $lease);

Build the pool-release callback for a query Future: C<$conn> goes back to
C<$pool>, the pool it was acquired from, and then C<$caller> -- the Future
L</_query_async> handed its caller -- takes the statement's outcome. In that
order: the connection is in the pool again when the caller's callbacks run.

C<$lease> is the lease of the borrow (L<DBIO::Storage::PoolBase/_lease>, asked
for right after the acquire resolved) and is handed to the pool's C<release>
as its second argument. A statement that completes after its connection went
on -- handed to a queued caller, borrowed again from the idle list -- then
releases a borrow that is over, and the pool takes nothing from it: silently,
so the one session is never on two callers' hands. Optional: without a lease
the release is made without one and is taken as the current holder's.

A named sub, deliberately B<not> a closure inside the C<< ->then(sub {...}) >>
acquire chain (ADR 0044): the callback is created HERE, in a sub whose pad
dies when this sub returns, so the bind arrayref lives only until dispatch,
not for the whole flight of the query. A callback created inside the C<<
->then >> closure would be retained by the query Future for the flight
(L</_await_query_result> and its L<Future::IO> watcher hold it while the
connection socket is polled) and would pin that closure's pad -- and C<$bind>
-- alive via CvOUTSIDE.

=head2 _mark_dead_on_fail

  my $cb = $storage->_mark_dead_on_fail($conn, $pool);
  $query_future->on_fail($cb);

Build the callback a failed query Future runs to ask L</_conn_error_is_fatal>
about C<$conn>, and to report the connection to C<$pool>
(L<DBIO::Storage::PoolBase/_mark_connection_dead>) when the answer is true.
C<$pool> is the pool the statement was dispatched with: the one a pooled query
acquired from, and for a pinned statement the pool the storage had when it
went out -- none, for a storage that never built one, and then there is nobody
to tell. A named sub for the reason L</_release_on_ready> is one: built here,
the callback closes over the connection and its pool, not over the SQL and the
caller's bind arrayref (ADR 0044).

L</_query_async> registers it B<before> the release callback, so the pool is
told before the connection comes back and the release retires it rather than
idling it. L</_query_async_pinned> registers it on its own; the pinned
connection's one hand-back is its holder's.

The callback never dies. It runs inside the completion of the query Future,
where a die would escape into whatever completed that Future and skip every
callback registered after it -- the release among them. So the seam is called
inside an C<eval>: a throw counts as dead, and goes to the pool's C<on_error>
(a C<warn> should that die too, or with no pool to tell). A failing report to
the pool is warned about as well. Nothing of either reaches the query Future, which keeps its own error.

=head2 _query_async_pinned

Transport override: like L</_query_async> but runs on the supplied pinned
connection and does B<not> release it -- used for queries inside a pinned
transaction. Shapes the incoming C<?>-dialect SQL internally through
L<DBIO::Storage::Async/_transform_sql> exactly as L</_query_async> does.

Statements on one connection are serialised: a statement is dispatched only
once the one before it on the same connection has settled, so a caller may
issue several without awaiting each. The returned Future is the
caller's; see L</THE PINNED STATEMENT QUEUE>. The statement's own Future is
held by the storage for the flight, as a pooled query's is, so a statement
whose Future nobody keeps is still collected, and one whose connection is
closed under it fails there (L</STATEMENTS IN FLIGHT>).

A failed query asks L</_conn_error_is_fatal> about the pinned connection, as in
L</_query_async>. A true answer reports it to the pool, and the
connection's one hand-back then retires it: for a transaction that is core's
finalizer, whose release comes after the C<ROLLBACK>
(L<DBIO::Storage::Async/txn_do_async>). So a transaction whose connection died
under it fails as before, and the connection is not handed out again. The
dispatch goes through L<DBIO::Storage::Async/_seam_future> here too, so a
driver's own L</_await_query_result> that dies, or returns no Future, is asked
about as well: it comes back as a failed Future, like every other failure of
this seam.

=head2 _abandon_flights_on

  $storage->_abandon_flights_on($conn);

The pool is about to close C<$conn>: end what is still in flight on it (see
L</STATEMENTS IN FLIGHT>). Called by L<DBIO::Async::Pool/_shutdown_connection>
for every connection core's pool closes, before the driver's
L</_shutdown_pool_connection>; a driver that brings a pool of its own calls it
from the same place.

Each statement in flight on C<$conn> has its caller's Future failed and its
poll let go of, in the order they were dispatched. And a hashref connection is
marked as finished, whether or not anything is on it: it gets a pinned
statement queue that only refuses, or the one it has is set to. What waits in
it fails unsent as the flight is let go of, and whatever is issued on the
connection later fails unsent as well -- nothing more is handed to
L</_submit_query> for it. A connection that is no hashref has no place for the
mark and is left as it is.

Does nothing at all in global destruction. Never dies: it runs inside the pool's teardown, where a
die would skip the close of the connection.

=head2 async_option_names

  sub async_option_names { ($_[0]->SUPER::async_option_names, qw( my_option )) }

The options this transport adds to core's: C<statement_timeout> and
C<max_pending_pinned>. A driver adapter that declares options of its own
extends this list through C<SUPER::>, so these two stay declared.

=head2 _await_readable

  my $future = $storage->_await_readable($conn);

Returns a Future that becomes ready once the connection's socket is readable
-- in the process that asked. A C<fork> copies the event loop's watch list
with everything else, and the socket is as readable in the child as in the
parent, so the child's loop resolves the parent's poll if it turns. There the
returned Future stays pending for good, and nothing chained onto it runs: no
L</_collect_result>, which would read the parent's answer off the shared
socket and leave the parent waiting for it, no release, no settled Future, no
callback of the parent's. That holds for every poll made here --
the first one of a statement, the one a driver makes to wait for the rest of
a result, a connection still coming up -- because all of them are made here.
The listen watch loop refuses a poll from another process on its own
(L</THE LISTEN WATCH LOOP>).

The single seam through which this transport touches L<Future::IO>: a concrete
driver's L</_collect_result> that must wait for more of a result also calls this
rather than re-implementing the fd wrapping. The filehandle C<poll> needs is
supplied by L</_conn_poll_fh>. Its counterpart is L</_let_go>, the single
place where the transport gives a poll up. When a poll resolves, and what a
callback run from it may do, is the L<Future::IO> implementation's; see
L</FUTURE::IO IMPLEMENTATIONS> for what the built-in one and the IO::Async one
do that a caller meets.

A driver that re-polls this way recurses as C<< $self->_collect_result($conn) >>
-- the seam takes the connection and nothing else (ADR 0044). Carrying
the SQL and the bind arrayref into the re-poll callback would pin the caller's
binds for as long as the result keeps arriving, which is precisely the lifetime
ADR 0044 ends at dispatch.

=head2 _let_go

  $storage->_let_go($future);

Stop waiting for C<$future>: cancel it, unless it has settled already. The
single place where this transport gives up on something it awaits, as
L</_await_readable> is the single place where it starts to: a statement in
flight whose caller cancelled it or whose connection is being closed
(L</STATEMENTS IN FLIGHT>), and whatever the listen watch loop awaited when
it is stopped (L</_listen_unwatch>) -- a poll, a timer or a drain query.
L<Future> carries the cancel down the chain to the L<Future::IO> poll or
timer at its head, and what the implementation then does with its watch is
the implementation's: the built-in one drops it in the cancel, and its round
dies when that cancel came from the callback of a poll in front of this one;
L<Future::IO::Impl::IOAsync> keeps the watch until the socket next turns
readable (L</FUTURE::IO IMPLEMENTATIONS>).

A Future that cannot be cancelled is left alone.

=head2 _conn_poll_fh

  my $fh = $storage->_conn_poll_fh($conn);

The stable poll filehandle for C<$conn>, created lazily on first use and cached
on the connection for its whole life. L<Future::IO-E<gt>poll> requires a real
filehandle, but a driver's L</_conn_fileno> hands back the raw integer socket fd
(e.g. DBD::Pg's C<pg_socket>). The C<< '+<&' >> open mode dups that fd (via
C<dup(2)>) into an independent filehandle, so closing this handle never touches
the driver's own socket.

The dup is cached B<per connection> for a correctness reason, not merely for
speed. L<Future::IO> watches the filehandle and, once the poll resolves,
unwatches it B<by its fileno> -- but its impls mark the Future done I<before>
they unwatch. A fresh-dup-per-poll handle closed the moment its poll resolved
would already be gone when the loop unwatches: C<< $fh->fileno >> returns
C<undef>, the loop's watch table is corrupted, and the freed fd -- reused by the
next dup -- collides with the stale watch (observed as
C<pg_ready: No asynchronous query is running> on the following query). Reusing
one stable handle for every poll on a connection keeps the fileno valid across
the whole watch/unwatch cycle. The dup fd dies with the connection it mirrors,
when C<$conn> is torn down.

Cached on the connection hashref under the reserved key C<_dbio_async_poll_fh>;
a driver whose connection is not a hashref must supply its own caching.

=head2 _await_conn_ready

  my $future = $storage->_await_conn_ready($conn);

Returns a Future that resolves to C<$conn> once the connection is ready for
queries. Uses L</_conn_ready> to check readiness and L</_await_readable> to
wait on the fd from L</_conn_fileno> when not yet ready.

While it waits, a hashref connection carries what the wait consists of under
the reserved key C<_dbio_async_ready> (next to C<_dbio_async_poll_fh>): the
Future returned here and the poll it is currently waiting on, both held
weakly, and gone as soon as the Future settles. That is what lets
L</_abandon_flights_on> end the wait when the pool closes the connection
before it came up -- a retirement while it is coming up: the poll
is let go of (L</_let_go>), so the loop does not go on watching the dup of a
closed connection's socket and nobody asks the closed connection whether it is
ready, and L<DBIO::Async::Pool/_retire_connection> then fails the returned
Future, which is how the pool learns to hand the slot on. A connection that is no hashref has no place for it; its wait is left to the
pool's own cancel, as before. The optional third argument is the wait's own
bookkeeping, passed on by the rounds after the first.

=head2 _await_query_result

  my $future = $storage->_await_query_result($conn, $sql, $bind);

Submits the query via L</_submit_query>, waits for the connection socket to
become readable via L</_await_readable>, and collects the result via
L</_collect_result>. Returns a Future resolving to the result rows.

C<$sql> and C<$bind> are consumed by the dispatch (L</_submit_query>) and by
nothing after it: the collect callback is built by L</_collect_on_readable>,
which forwards only C<$conn>. That is what keeps the bind arrayref's life inside
the dispatch (ADR 0044) even though the readable-Future holds a
callback for the whole flight -- see L</_collect_on_readable> for the mechanism.
The C<< Future->call >> wrapper itself retains nothing: L<Future> invokes the
code and returns the Future it produced without keeping the code reference, so
once no surviving callback pins this closure through C<CvOUTSIDE>, its pad --
and with it C<$sql> and C<$bind> -- is freed as soon as the dispatch returns.

=head2 _collect_on_readable

  my $cb = $storage->_collect_on_readable($conn);

Build the result-collecting callback for a dispatched query. A named sub,
deliberately B<not> a closure inside the C<< Future->call(sub {...}) >> dispatch
block (ADR 0044), for the same reason L</_release_on_ready> is one:
the callback is created HERE, in a sub whose pad dies when this sub returns, so
it closes over C<$conn> alone.

A callback created inline in the dispatch block instead would be retained by the
pending L</_await_readable> Future for the whole flight of the query -- until the
connection socket becomes readable -- and would pin that block's pad through
C<CvOUTSIDE>, keeping C<$sql> and the caller's C<$bind> arrayref alive with it.
That is the half of ADR 0044 one level below L</_release_on_ready>: the binds are
serialised onto the wire by L</_submit_query> and no callback needs them again,
so no callback may hold them.

=head2 _listen_delay

  my $f = $storage->_listen_delay($seconds);

Core listen seam (L<DBIO::Storage::Async/_listen_delay>): the reconnect
backoff timer, and the pacing timer of the watch loop. Returns
C<< Future::IO->sleep($seconds) >> as it is -- pending on return, resolved by
whichever loop drives L<Future::IO>, and cancellable: C<cancel> drops the
timer (the built-in implementation removes it from its alarm list), which is
what core relies on when it cuts a backoff short.

The Future is not re-wrapped into L</future_class>. For this transport's
C<'Future'> it already is one -- every L<Future::IO> implementation returns a
L<Future> subclass -- and a wrapper would only stand between core's C<cancel>
and the timer. A subclass naming a different L</future_class> gets a
L<Future>-API object here, as it already does from L</_await_readable>.

=head2 _listen_poll_interval

  my $seconds = $storage->_listen_poll_interval;   # undef: socket-driven

The watch mode switch (see L</THE LISTEN WATCH LOOP>), asked once each time
L</_listen_watch> starts. C<undef>, the default, selects socket-driven
watching; a positive number of seconds selects timer-driven watching at that
interval. Anything else fails the watch, which core reports and heals from
like any other failed arm -- loudly, on every attempt -- instead of a zero
interval spinning the loop. A driver may back it with an accessor of its own; a
change applies from the next watch, that is the next listen connection.

=head2 _listen_watch

  $storage->_listen_watch($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_watch>), implemented once for
every L<Future::IO> transport: start the watch loop described in
L</THE LISTEN WATCH LOOP> on the listen connection C<$conn>, which must be a
hashref. Returns at once; the loop runs from the event loop. In socket mode the
poll handle is dup'd here, so a connection without a usable socket fails the
arm itself -- core reports it and heals. A watch already running on C<$conn>
is stopped first.

=head2 _listen_unwatch

  $storage->_listen_unwatch($conn);

Core listen seam (L<DBIO::Storage::Async/_listen_unwatch>): stop the watch loop
on C<$conn>. The watch state is taken off the connection first, then the poll,
timer or drain Future it awaited is let go of (L</_let_go>); anything that
still resolves afterwards is ignored. Once this returns, the loop dispatches nothing and
reports nothing for C<$conn>, and holds nothing that keeps C<$conn> alive. A
connection that is not being watched is left alone.

=head2 _notify_send

  my $f = $storage->_notify_send($channel, $payload);

Core listen seam (L<DBIO::Storage::Async/_notify_send>): send one notification
on a pooled connection. Runs the SQL and bind values from L</_notify_sql>
through L</_query_async>, which shapes the C<?> placeholders into the driver
dialect (L<DBIO::Storage::Async/_transform_sql>) and releases the connection
afterwards. Resolves
with whatever that query resolves with.

=head2 _txn_context_class

  my $class = $storage->_txn_context_class;   # DBIO::Async::TransactionContext

The pinned-connection context L<DBIO::Storage::Async/txn_do_async> hands to its
coderef. Narrows core's generic
L<DBIO::Storage::Async::TransactionContext> default to this dist's
L<DBIO::Async::TransactionContext>, so every C<future_io> adapter gets the
future_io context without naming it.

=head2 _txn_conn_accessor

  my $key = $storage->_txn_conn_accessor;     # 'txn_conn'

The constructor key L<DBIO::Storage::Async/txn_do_async> passes the pinned
connection under when building the L</_txn_context_class>. Stated next to the
class it belongs to, so a context that ever changed its key would change both
halves in one place.

=head2 _submit_query

  $storage->_submit_query($conn, $sql, $bind);

Driver seam: send one query on the connection C<$conn> without waiting for its
result. Called by L</_await_query_result> for every query of L</_query_async>
and L</_query_async_pinned>, with C<$sql> already shaped into the driver's
dialect by L<DBIO::Storage::Async/_transform_sql> and C<$bind> an arrayref of
bind values (empty when there are none). The return value is ignored: once
this returns, the base waits for the connection's socket to become readable
(L</_await_readable>) and then asks L</_collect_result> for the result.

L</_collect_result> is handed C<$conn> alone, so whatever it needs of the query
in flight -- a statement handle, say -- the dispatch leaves on C<$conn>, never
the SQL or the bind arrayref: those end with the dispatch (ADR 0044;
see L</_collect_on_readable>).

A die here fails the query's Future with that error, which then takes the path
of any failed query: L</_conn_error_is_fatal> is asked about C<$conn>, and a
pooled connection is released.

The base croaks until a driver provides it.

=head2 _collect_result

  my $future = $storage->_collect_result($conn);

Driver seam: read the result of the query L</_submit_query> sent on C<$conn>.
Called once the connection's socket has become readable after the dispatch,
through the callback L</_collect_on_readable> builds, with the connection and
nothing else (ADR 0044). Returns a Future of the query's result, in
the shape L<DBIO::Storage::Async/_query_async> promises its caller: the raw
rows of a statement that returns rows, the affected-row count of one that does
not.

A readable socket does not mean the whole result has arrived. When it has not,
the driver waits for more with L</_await_readable> and calls itself again as
C<< $self->_collect_result($conn) >>, rather than blocking on the rest.

A failed statement dies here or fails the returned Future; either way the
query's Future fails, and L</_conn_error_is_fatal> is asked about C<$conn>.

It is not called for every statement L</_submit_query> sent: one cancelled in
flight, or whose connection was closed under it, is never collected. Leave
nothing on C<$conn> that only a later call here would clear.

The base croaks until a driver provides it.

=head2 _normalize_conninfo

  my $info = $storage->_normalize_conninfo($info);

Driver seam: turn connect info into this transport's own shape. Core's
L<DBIO::Storage::Async/connect_info> calls it with the connect info the schema
was connected with, the DBIO-private attributes already stripped -- for a DSN
connect, typically the DBI form C<< [ $dsn, $user, $password, \%attrs ] >>.
L</_async_broker_conninfo> calls it with each answer of an AccessBroker, in
that DBI form or as a C<< [ \%conninfo, \%opts ] >> pair already in the
transport's own shape.

It returns C<< [ $conninfo, \%opts ] >>: core takes a C<pool_size> key out of
a hashref C<$conninfo> to size the pool, and the pool hands C<$conninfo> to
L</_create_pool_connection>. Connect info already in that shape, and the
broker form C<< [ $broker ] >> / C<< [ $broker, \%options ] >>, come back
unchanged: core looks for the broker only after this seam has run.

Where core's default passes everything through as it is, this base croaks
until a driver provides the seam: an abstract transport has no connection
shape of its own to pass anything through to.

=head2 _create_pool_connection

  my $conn = $storage->_create_pool_connection($conninfo);

Driver seam: open one connection for the pool from C<$conninfo>, and return
it. Called through L<DBIO::Async::Pool/_create_connection> whenever the pool
spawns a connection. C<$conninfo> is the first half of what
L</_normalize_conninfo> returned, its C<pool_size> taken out by core; with an
AccessBroker attached, a fresh one from L</_async_broker_conninfo> for every
spawn, so rotated credentials reach the new connection.

The pool counts the connection and hands it out; do not register it anywhere
yourself. Right after this returns, the pool replays the owning storage's
C<on_connect_do> / C<on_connect_call> on it (see L</transport_capabilities>):
core's C<_run_pool_connect_statement> runs them on a C<< { dbh => $dbh } >>
hashref, which is also what the base keeps its per-connection state on
(L</_conn_poll_fh>). The pool hands the connection out only once
L</_conn_ready> answers true.

A die fails the caller's borrow with that error.

The base croaks until a driver provides it.

=head2 _shutdown_pool_connection

  $storage->_shutdown_pool_connection($conn);

Driver seam: close one connection the pool is done with -- when it shuts down
(the storage's C<disconnect>), and whenever it retires one: a connection
reported dead (L</_conn_error_is_fatal>), an idle one
L</_idle_connection_alive> did not vouch for, one whose readiness or connect
actions failed. Called through L<DBIO::Async::Pool/_shutdown_connection>, once
per connection. The connection may already be dead; a die here is swallowed by
the pool.

A statement may be on the connection's wire when this is called -- one in
flight when the storage was disconnected. The base has ended it by then: its
caller's Future has failed and nothing waits for the socket any more
(L</_abandon_flights_on>). The driver closes the handle as it would
an idle one; it is not asked to cancel the statement on the server. Nothing
is handed to L</_submit_query> for a hashref connection afterwards.

The base croaks until a driver provides it.

=head2 _conn_ready

  my $ready = $storage->_conn_ready($conn);

Driver seam: is C<$conn> ready for queries? A boolean, asked by
L</_await_conn_ready> each time the pool is about to hand the connection out
(L<DBIO::Async::Pool/_connection_ready_future>) -- freshly spawned, idle, or
passed to a queued caller. While it answers false, the base waits for the
socket to become readable (L</_await_readable>, on the fd from
L</_conn_fileno>) and asks again; the caller gets the connection once it
answers true. A die fails the borrow, and the pool retires the connection.

A driver that connects blocking, as C<< DBI->connect >> does, answers true for
any live handle.

The base croaks until a driver provides it.

=head2 _conn_fileno

  my $fd = $storage->_conn_fileno($conn);

Driver seam: the connection's socket as a raw integer file descriptor -- for
DBD::Pg, C<< $dbh->{pg_socket} >>. Asked by L</_conn_poll_fh> the first time
the base has to wait on C<$conn>, and not again: the base dups the fd into a
filehandle of its own, cached on the connection, and polls that, never the
driver's socket itself. An fd that cannot be dup'd -- C<undef>, or closed --
fails the query, borrow or listen watch that needed it.

The base croaks until a driver provides it.

=head2 _conn_error_is_fatal

  sub _conn_error_is_fatal {
    my ($self, $conn, $error) = @_;
    ...   # the handle's local state, or the error itself -- no round trip
    return $dead;
  }

Driver seam: did the query that just failed on C<$conn>
with C<$error> leave the connection dead -- its server session gone, its socket
closed, the protocol out of step? Asked by L</_query_async> and
L</_query_async_pinned> for every query Future that fails, with the connection
it ran on and the Future's failure: C<$error> is the message, and any category
and details the Future failed with follow it as further arguments. Never asked
about a query that succeeded, or that was cancelled.

A true answer reports C<$conn> to the pool
(L<DBIO::Storage::PoolBase/_mark_connection_dead>) before the connection is
handed back, so the release retires it instead of putting it back on the idle
list, and a caller queued for its slot gets a freshly spawned connection. A
transaction's connection is covered alike: core hands it back through the same
release once the transaction has ended. Without the report the pool cannot
tell -- it would hand the dead connection to the next caller, whose query then
fails the same way. The failed query itself is not retried; its caller sees its
own error.

The default answers false: nothing is reported, and a connection goes back to
the idle list whatever its query failed with -- the behaviour from before the
seam. Only the driver can tell a connection-level error from a statement error
the session survives, and the DBDs disagree on how it shows (core ADR 0047,
addendum 2026-09-27: report, not probe). So a driver answers from what is
already there, the handle's local state or the error itself: for DBD::Pg,
libpq has given up the socket (C<pg_socket> is C<-1>); for DBD::mysql and
DBD::MariaDB, the error code on the handle is a lost connection (2006, I<server
has gone away>; 2013, I<lost connection during query>). It runs in the failure
path of a query, from inside the event loop, so it must never block and never
send anything to the server: no ping, no round trip.

A throw counts as dead -- the rule core applies to a throwing
L<DBIO::Storage::PoolBase/_idle_connection_alive> -- and goes
to the pool's C<on_error>, so a broken classification is not silent. It goes
nowhere else: the query keeps its own error, and the connection is still
handed back exactly once (see L</_mark_dead_on_fail>).

The listen connection is asked about too, when a drain query on it fails (an
emulation's L</_listen_drain> runs through L</_query_async_pinned>). The pool
does not hold that connection, so a true answer changes nothing there; core's
listen machinery heals a dead listen connection on its own.

=head2 _idle_connection_alive

  sub _idle_connection_alive {
    my ($self, $conn) = @_;
    ...   # local state, or what the server already sent -- no round trip
    return $alive;
  }

Driver seam: is the server session behind the idle pool
connection C<$conn> still there? Core's pool asks it each time
L<DBIO::Storage::PoolBase/acquire> is about to hand out an idle connection --
on every borrow of one, before the caller's first statement is sent -- through
L<DBIO::Async::Pool/_idle_connection_alive>, which delegates here. Same name,
same contract as core's L<DBIO::Storage::PoolBase/_idle_connection_alive>: this
is where a C<future_io> driver answers it, since it writes a storage adapter
and never a pool of its own.

A false answer, or a throw, has the pool retire C<$conn> -- closed once through
C<_shutdown_pool_connection>, no longer counted against the pool size, never
handed out -- and try the next idle connection, then spawn a fresh one, or
queue the caller when the pool is full. A throw also goes to the pool's
C<on_error>, so a broken check is not silent; core catches it, the pool passes
it through untouched. Not asked about a connection the pool has just spawned,
nor about one released straight to a caller queued for it: neither sat idle.

The default answers true without looking: no check, no cost, and an idle
connection is handed out as it was before the seam. Fill it only if the driver
can answer B<without a round trip> -- from the handle's local state, or from a
non-blocking read of what the server has already sent. It runs inside acquire
on every borrow of an idle connection, so it must never block and never send
anything to the server: no ping, no C<SELECT 1>.

It is the borrow-time sibling of L</_conn_error_is_fatal>. That one reports a
dead connection B<after> a query on it failed; this one narrows the window
B<before> a query is sent on a connection that died while it sat idle -- a
server restart, an idle timeout, an administrator's kill. Without it such a
connection costs one caller a failed query first, and after a server restart
one caller per idle connection. Neither closes the window alone: a connection
can still die between this check and its first statement, or without the
server saying so (a network partition); that statement fails, and
L</_conn_error_is_fatal> reports it as before. A driver filling one will
usually fill both, from the same state.

What a driver can read, for example: whether its client library has already
given up the socket -- for DBD::Pg, C<pg_socket> below zero, the state a
PostgreSQL driver reads for L</_conn_error_is_fatal> too. And whether the
socket is readable, by a check with a zero timeout: an idle connection has no
query in flight, so a readable socket means the server sent something unasked
-- which is what a server does when it ends an idle session (an error message,
then end of file).
Whether readable means B<dead> depends on the engine. A MySQL server writes to
an idle connection only as it closes it; a PostgreSQL server may also send a
live idle session a notice, a parameter status or a notification, so there the
driver has to let its client library consume what arrived, without blocking,
and then look at the handle's state again.

This base makes the same zero-timeout readability check for its own listen
watch loop (see L</THE LISTEN WATCH LOOP>), as a private step of that loop. It
does not offer it as a helper for this seam: what a readable idle socket means
is the driver's to decide, and a helper would be shaped before a driver has
used it.

=head2 _listen_drain

  my $notifications = $storage->_listen_drain($conn);
  # [ [ $channel, $payload, $sender_pid ], ... ]  -- or a Future of that

Driver seam of the listen watch loop (see L</THE LISTEN WATCH LOOP>): take
every notification pending on the listen connection C<$conn> and return them
as an arrayref of C<[$channel, $payload, $sender_pid]> tuples, in arrival
order; an empty arrayref when nothing is pending. C<$payload> and
C<$sender_pid> may be C<undef>. The loop hands each tuple to
L<DBIO::Storage::Async/_listen_dispatch> in that order.

It may instead return a Future resolving to such an arrayref. An emulating
transport must, since draining a notify table is a query, and on this
transport a query is a Future -- run it on the listen connection with
C<< $self->_query_async_pinned($conn, $sql, \@bind) >>. The loop holds that
Future until it resolves and cancels it on L</_listen_unwatch>.

It dies, or its Future fails, when the connection is dead; the loop reports
that to core through L<DBIO::Storage::Async/_listen_lost>. In socket mode that
includes end of file: the loop drains only when the socket is readable, and a
readable socket that yields no data because the server closed it B<must> die
here -- a drain that answers C<[]> instead leaves the loop polling a closed
socket that stays readable, spinning hot and never healing.

In socket mode it is also called once right after the watch starts, whether
or not the socket is readable, to pick up what the client library buffered
during the subscribe round trip. It must therefore never block: read what is
there and return.

=head2 _notify_sql

  my ($sql, $bind) = $storage->_notify_sql($channel, $payload);

Driver seam of L</_notify_send>: the statement that sends one notification,
as SQL in the C<sql_maker> C<?>-placeholder dialect plus an arrayref of bind
values -- L</_query_async> shapes the placeholders. The payload travels B<only>
in C<$bind>, never in C<$sql> (ADR 0017 §3, restated by core ADR 0056); bind
the channel too wherever the engine allows it. C<$payload> may be C<undef>.

=head1 SEAM HOOKS

Overridden by a concrete DBD subclass; each croaks until provided.

=head2 Query execution / connection lifecycle

=over 4

=item * L</_submit_query> -- send query bytes to the wire (non-blocking)

=item * L</_collect_result> -- read the result from the wire

=item * L</_conn_ready> -- is the connection ready for queries?

=item * L</_conn_fileno> -- socket fd for the L<Future::IO> watcher seam

=item * L</_create_pool_connection> / L</_shutdown_pool_connection> -- pool
connection lifecycle

=back

Two more seams belong here, optional: until a driver fills them, their
defaults leave everything as it was -- the pool is never told a connection
died.

=over 4

=item * L</_conn_error_is_fatal> -- did a failed query take its connection
with it? A true answer has the pool retire the connection instead of handing it
out again

=item * L</_idle_connection_alive> -- is an idle connection's session still
there? Asked before the pool hands it out; a false answer has the pool retire
it and take the next idle connection or a fresh one

=back

=head2 SQL / connect-info shaping

The SQL-shaping seams (C<sql_maker_class>, C<_transform_sql>,
C<_post_insert_sql>) and the pipeline seams
(C<_pipeline_enter>/C<_pipeline_sync>/C<_pipeline_exit>) are inherited as
croaking seams from L<DBIO::Storage::Async>. This transport additionally
requires:

=over 4

=item * L</_normalize_conninfo> -- DB-specific connect-info conversion

=back

The transaction-context seams are B<not> among them: L</_txn_context_class>
and L</_txn_conn_accessor> answer with this transport's own defaults, so an
adapter names them only when it needs a different context class or constructor
key.

=head2 LISTEN / NOTIFY

Core L<DBIO::Storage::Async> owns the LISTEN/NOTIFY contract and its machinery
-- registry, dedicated listen connection, serialised channel operations,
self-healing, fork guard (core ADR 0056). Of its listen seams, the ones that
are the same for every L<Future::IO> transport are implemented here, once (ADR
0005): the backoff timer L</_listen_delay>, the watch loop L</_listen_watch> /
L</_listen_unwatch> (see L</THE LISTEN WATCH LOOP>) and the pooled
L</_notify_send>. A driver offering LISTEN/NOTIFY supplies the rest:

=over 4

=item * L</_listen_drain> -- the notifications pending on the listen
connection, in arrival order

=item * L</_notify_sql> -- the SQL and bind values that send one notification

=item * C<_listen_open>, C<_listen_close>, C<_listen_subscribe>,
C<_listen_unsubscribe>, C<_listen_probe> -- inherited as croaking seams from
L<DBIO::Storage::Async> (see L<DBIO::Storage::Async/Listen seams>)

=item * optionally L</_listen_poll_interval> -- the watch mode:
socket-driven by default, timer-driven when it answers a number of seconds

=back

It then declares C<listen> and C<notify> in its own
L</transport_capabilities>. This base declares neither: it cannot drain
anything.

=head1 THE PINNED STATEMENT QUEUE

A connection runs one statement at a time, and this transport's own cycle has
room for exactly one: L</_submit_query> leaves the statement on the connection,
L</_collect_result> reads I<the> result off it. A pooled connection is safe by
construction -- between acquire and release it has one borrower, whose
L</_query_async> holds it for exactly one statement. A pinned one is not: a
transaction context hands its connection to every statement the block issues,
and a block that does not await one statement before issuing the next put the
second on the wire while the first still ran. DBD::Pg then cleared the first
statement's handle, the first never resolved, and the transaction's C<COMMIT>
-- which waits for every statement of the context -- waited
forever.

So L</_query_async_pinned> queues statements per connection, as the C<ev>
transports do: a statement is dispatched only once the one before it on that
connection has settled -- done or failed. The caller gets a Future at once,
and statements go out in the order they were issued. A statement that was
waiting goes out once the caller's callbacks of the one before it have run:
one those callbacks issue queues behind it, and one they cancel is never sent.
A statement on an idle connection goes out at once, as before. This covers
everything pinned: a transaction context, a pipeline context, core's
C<BEGIN>/C<COMMIT>/C<ROLLBACK>, an emulated L</_listen_drain>.

A connection is idle as soon as its statement has settled with nothing
waiting behind it -- B<before> that statement's callbacks run, so a statement
they issue goes out at once, a synchronous one (C<< $ctx->select >>, which is
C<< select_async(...)->get >>) included. That is the everyday case:
core runs a transaction's block from the callback of C<BEGIN>'s Future, so
every synchronous statement of a C<txn_do> block is issued from inside one.
Were the connection still counted busy there, the statement would wait for a
queue that advances only once the block has returned, while its C<< ->get >>
waits for the statement -- nothing on the wire, the built-in L<Future::IO>
implementation dies (I<Cowardly refusing to sit idle>), any other loop hangs.
The queue is not all such a statement depends on, though: on
L<Future::IO::Impl::IOAsync> it goes out and then dies in its C<< ->get >>,
of that implementation's own read handler -- see
L</FUTURE::IO IMPLEMENTATIONS>.

One case still cannot complete: a B<synchronous> statement issued from a
callback while statements issued before it still wait. Issue order puts it
behind them, and they go out only once that callback has returned. Chain it
(C<< ->then >>) instead of blocking, or await the waiting statements first.

How the queue treats what goes wrong:

=over 4

=item * B<A statement fails.> The queue advances: the next statement is
dispatched as it would have been had its caller chained it. A transaction
fails with the first failure anyway.

=item * B<A statement fails and the driver says its connection died>
(L</_conn_error_is_fatal>). The statements that were already waiting behind
it -- issued before anyone knew -- are failed without being sent: they would
only go onto a dead handle. So is every statement issued afterwards, from the
failed statement's callbacks or later: it fails with C<not sent: this
connection was reported dead ...> and never reaches the driver -- core's
C<ROLLBACK> is one, and the transaction's error names it. The queue asks the
pool (C<_connection_is_dead>) at the one place it dispatches, so a refused
statement is no query for L</_conn_error_is_fatal> to classify a second time.
Same rule as after a cancel in flight: nothing more is sent.

=item * B<A waiting statement's Future is cancelled.> It is skipped and never
sent; its SQL and bind values are dropped at the cancel.

=item * B<The statement in flight is cancelled.> Its Future::IO poll is
dropped, as before, but its result is still on its way, and the base can
neither read it nor cancel it on the server. Nothing more is sent on that
connection: the statements waiting behind it and every later one fail without
being sent, and the connection is reported dead to the pool
(L<DBIO::Storage::PoolBase/_mark_connection_dead>), so its hand-back retires it
instead of passing the unread result to the next borrower. In a transaction
that makes the C<ROLLBACK> fail, and the transaction fails saying so; the
server ends the transaction when the retired connection is closed. A pooled
query cancelled in flight retires its connection the same way (L</_query_async>).

=item * B<The connection is closed> -- the storage disconnected, its pool
shut down, the connection retired. A statement in flight fails saying so, and
the queue refuses as it does after a cancel, with a reason of its own: the
statements waiting fail without being sent, in the order they were issued,
and so does every later one. An idle connection, which carries no queue, is
given one at the close that only refuses. Nothing is reported to the pool,
which closed the connection itself (L</STATEMENTS IN FLIGHT>).

=back

The queue lives on the connection hashref under the reserved key
C<_dbio_async_queue>, next to C<_dbio_async_poll_fh> (L</_conn_poll_fh>): the
statement in flight and the ones waiting. It is removed as soon as the
connection falls idle, so a connection goes back to the pool without it; only
a connection a cancelled statement left behind, or one the pool closed, keeps
it, to refuse what comes next -- the first is retired, the second is closed
already. A connection that is not a hashref gets
no queue: its statements are dispatched at once, as before, and a driver with
such a connection serialises them itself. They are held for the flight like
any other (L</STATEMENTS IN FLIGHT>).

The number of statements waiting on one connection can be bounded with the
connect option C<max_pending_pinned>, and the time one statement may take on
the wire with C<statement_timeout> (L</TIMEOUTS AND LIMITS>).

A waiting statement holds its SQL and bind values until it is dispatched --
it cannot do otherwise -- and nothing holds them afterwards: the queue drops
them as the statement goes out, and every callback it builds is made by a named
sub that closes over the connection and Futures only (ADR 0044).

The queue serialises; it does not batch. A transport that pipelines on this
base -- neither C<future_io> adapter does; C<pipeline()> refuses without
L<DBIO::Storage::Async/_pipeline_enter> -- has to put several
statements on one connection before the first is answered, which this cycle
cannot do anyway, and dispatches its batched statements through a
L</_query_async_pinned> of its own.

=head1 STATEMENTS IN FLIGHT

A statement on the wire -- a I<flight> -- is this transport's: a
L<Future::IO> poll on the connection's socket, with the collect chained onto
it. L<Future> holds a Future derived with C<then> only weakly, so such a chain
lives exactly as long as somebody holds its end. That somebody is the storage
(ADR 0007): every statement L</_query_async> and
L</_query_async_pinned> put on the wire is entered into a register on the
storage as it is dispatched, with its connection and the pool it was dispatched
with, and taken out when its Future settles. The caller gets a Future B<of its
own>, settled from the flight's, never the flight itself. Two things follow.

B<A Future the caller lets go of is carried through.> Fire-and-forget -- a
C<create_async> in void context, a notification nobody waits for -- no longer
takes the chain with it: the answer is collected, a failure asks
L</_conn_error_is_fatal> as every failure does, and a pooled connection is
handed back exactly once, or retired. Nothing announces the failure of a
statement nobody waits for. The same holds one step earlier: a pooled query
whose caller lets go of it while it still waits for the pool is dispatched
when its turn comes. Before this, the poll resolved into nothing (L<Future>
warns I<lost a sequence Future>), the result stayed unread and the connection
checked out -- in a pool of one, for good.

Cancelling is not letting go, and does what it did: the caller's cancel
reaches the flight, and a flight cancelled on the wire retires its connection.

B<A connection closed under its statement ends the flight.> The pool closes a
connection at its C<shutdown> -- which is what
L<DBIO::Storage::Async/disconnect> runs, and C<DESTROY> -- and when it retires
one. For every connection it closes, L<DBIO::Async::Pool/_shutdown_connection>
first calls L</_abandon_flights_on>, and a statement in flight on it ends
there:

=over 4

=item * its caller's Future B<fails>, at the close, saying the connection was
closed under the statement and that whether it took effect is unknown -- it
may have reached the server;

=item * the poll is let go of (L</_let_go>): the loop watches the connection's
socket no longer -- at once on the built-in L<Future::IO> implementation,
with the next event on that socket on L<Future::IO::Impl::IOAsync>
(L</FUTURE::IO IMPLEMENTATIONS>) -- nothing is read off the closed
connection, and an answer that still arrives changes nothing;

=item * on a pinned connection, the statements waiting behind it
(L</THE PINNED STATEMENT QUEUE>) fail without being sent -- the rule for a
statement cancelled in flight, with a reason of its own;

=item * a callback on the caller's Future that dies there does not stop the
teardown: the flight is still let go of, the connection still closed, and the
death goes to the pool's C<on_error>.

=back

Before this the Future stayed pending and the loop went on watching the dup
of a socket whose connection was closed; a late answer ran L</_collect_result>
on that connection.

Where the pool closes nothing, nothing is ended. A forked child that tears
down the storage it inherited closes none of the parent's connections
(L<DBIO::Storage::PoolBase/_verify_pid>), so it settles none of the parent's
statements, and none of the parent's callbacks runs there. Nor does a child
whose own loop turns do anything with a flight it inherited: a poll made in
another process continues into nothing (L</_await_readable>), so the child
never collects, and the parent's answer stays on the socket for the parent.
The inherited flights stay in the child's copy of the register, inert. In global
destruction nothing is settled either, as core's pool settles none of its own
Futures there. And a storage that is merely I<dropped> with a
statement in flight is not torn down under it: the flight holds the storage,
completes, and the storage is freed after it.

B<A connection the pool closed gets nothing more sent>, whether or not a
statement was on it. A closed connection is finished: what is issued on it
afterwards -- the next statement of a transaction that was between two
statements at the teardown, core's C<ROLLBACK> for it, anything a holder
still sends -- fails saying the connection was closed, and never reaches
L</_submit_query>. The transport refuses rather than the driver, because not
every client library refuses a handle it closed: one that took the statement
would leave a poll on a dead socket and a Future that never settles. With no
statement in flight nothing fails I<at> the close; the holder learns of it
from its next statement. The mark is the pinned statement queue's, on the
connection hashref; a connection that is no hashref has no place for it, and
there the driver's handle is what refuses. A connection handed back to the
pool open never carries it.

No completion builds a pool. What a settled statement has to tell a pool --
that its connection died, was abandoned, or comes back -- it tells the pool it
was dispatched with: the one L</_query_async> acquired from, and for a pinned
statement the pool the storage had when the statement went out, if it had
one. L</pool> builds lazily, which is for a dispatch to trigger; asked from a
completion it put a new, empty pool on a storage that had just been
disconnected. With no pool there is nobody to tell, and that is not an error.

=head1 TIMEOUTS AND LIMITS

A statement, a wait and a queue each have a bound, set as connect options
(core's C<async_option>, L<DBIO::Storage::Async/ASYNC OPTIONS>), for example

  MyApp::Schema->connect($dsn, $user, $pass, {
    async              => 'future_io',
    statement_timeout  => 30,
    max_pending_pinned => 100,
    acquire_timeout    => 10,
  });

Every option left out is off, except C<acquire_timeout>, which is 30 seconds
in core. A value that does not fit the option's form is refused when the
connect info is set; the message names the option and the form it takes,
never the value.

=over 4

=item * C<statement_timeout> -- seconds a statement may take on the wire,
a number of seconds, C<0> or more; C<0> turns it off. The time runs from the
moment the statement is sent to the server until its answer is read. When it
is up, the statement is cancelled like any statement cancelled in flight
(L</_query_async>, L</THE PINNED STATEMENT QUEUE>): the poll is let go of and
its connection is reported dead to the pool, which retires it, so the next
borrower gets a fresh connection. The caller's Future fails with
C<statement timed out after N seconds (statement_timeout)> -- the option and
the seconds, never the SQL or the bind values -- and whether the statement
took effect on the server is unknown. It applies to pooled and pinned
statements alike. A pinned statement waiting in the queue is not on the wire
and its time has not started; the statements waiting behind a statement that
timed out fail unsent, as they do behind any cancelled one. The timer is the
transport's L<DBIO::Storage::Async/_delay>, here L</_listen_delay> over
L<Future::IO>; it stops when the statement settles. Where the owning storage
cannot make a timer, the statement runs without a time limit and the pool's
C<on_error> is told.

=item * C<max_pending_pinned> -- the number of statements that may wait for
the statement in flight on one pinned connection, a positive integer. A
statement issued when that many already wait fails at once, without being
queued: C<not sent: ... max_pending_pinned>, naming the option and the number,
never the SQL or the bind values. The statements already waiting, and their
order, are as they were. A connection that is not a hashref has no queue and
no limit here.

=item * C<acquire_timeout>, C<max_waiters>, C<txn_timeout>, C<reset_timeout>
-- the core's options, read by core: how long and how many callers may wait
for a pool connection (the pool takes them from this storage,
L<DBIO::Async::Pool/new>), how long a C<txn_do_async> may take and how long
the reset of a released connection may take. Their forms and defaults are in
L<DBIO::Storage::Async/ASYNC OPTIONS> and L<DBIO::Storage::PoolBase/new>. Their
timer is the same L<DBIO::Storage::Async/_delay>.

=back

=head1 TRACE

The transport carries no trace of its own. L</_query_async> and
L</_query_async_pinned> hand each statement to
L<DBIO::Storage::Async/_debug_query> -- the SQL, the bind values and the
optional C<$bind_attrs> -- and run the coderef it returns, which calls
C<query_end>, when the statement has settled: done, failed or cancelled. What
is traced at which C<DBIO_TRACE> level, how the C<redact_bind_value> hook is
asked and where the output goes is that method's rule (ADR 0009, core ADR
0025). A statement without attributes -- C<BEGIN>, C<COMMIT>, a ping, a reset,
C<_notify_send> -- gives the hook C<undef> for column name and attributes.

=head1 FUTURE::IO IMPLEMENTATIONS

Every wait this transport starts is a L<Future::IO> poll on the dup of a
connection's socket (L</_await_readable>), and every one it gives up is a
cancel of that poll (L</_let_go>). What becomes of a poll in between is the
implementation's, and some of what the two implementations this dist is
tested on do with one reaches a caller. What follows describes
L<Future::IO> 0.23 and L<Future::IO::Impl::IOAsync> 0.805, the newest
releases when it was written. The transport does nothing about any of it.
The three behaviours that keep a caller from what it is owed are held as they
stand, as C<TODO> on what is owed, by C<t/33-future-io-limits-builtin.t> and
C<t/34-future-io-limits-io-async.t>. All three are defects
of the implementations, reported upstream with patches and tests; with those
applied, every one of these C<TODO>s passes. The other
implementations -- AnyEvent, Mojo, UV, Glib -- have not been looked at.

=head2 The built-in implementation

What L<Future::IO> runs on when no C<Future::IO::Impl::*> is loaded: no event
loop, C<< ->get >> on a Future turns a loop of its own. It is there for a
script that has no event loop.

=over 4

=item * B<A poll cancelled from inside another poll's callback can kill the
round.> One round of that loop walks its list of polls with the list's length
taken up front, and resolves the ready ones from inside the walk. A poll
cancelled by a callback that runs there leaves the list at once. When it stood
I<behind> the poll being resolved, the walk runs off the end of the list and
the round dies -- C<Can't call method "fh" on an undefined value at
Future/IO.pm line 890> -- out of whatever drove the loop: a C<< ->get >>, on
a Future that is done by then.

A statement in flight is a poll, the polls stand in the order the statements
went out, and letting go of a statement is a cancel. So this is met by
C<< Future->wait_any >> over two pooled queries when the one issued first
wins, since the loser is cancelled from the winner's callback; and by a
C<disconnect>, a pool shutdown or a C<cancel> made in a query's callback while
a statement issued after that query is in flight. The transport has done its
part by then: the winner's rows are on its Future and its connection is back
in the pool, the loser's connection is retired, a statement the teardown ended
has failed saying so, and the loop is left with nothing stale on its list.
What is lost is the return of that one C<< ->get >>. Catch its death and ask
the Future again -- it is done, and hands out its result; or cancel, and tear
down, outside of a callback; or run on an event loop's implementation.

=item * B<With read polls only, it does not wait for a socket.> While it
holds no timer, this implementation does not C<select>: it presumes every poll
ready, resolves them in the order they were made, and clears C<O_NONBLOCK> on
each handle while that poll's callbacks run. The driver's L</_collect_result>
then waits on its connection until the answer is there. So statements in
flight at once on several pooled connections are answered one after the
other, in the order they were issued, each waited for in turn -- not as their
answers come in. Measured against a PostgreSQL server: a C<pg_sleep(1.5)>
issued first and a C<SELECT 1> issued second, raced with
C<< Future->wait_any >>, are decided after 1.5 s, by the first; on IO::Async
after 0.15 s, by the second. A timer pending in the loop --
C<< Future::IO->sleep >>, a listen backoff, a timer-driven listen watch --
makes it C<select> for as long as that timer is pending. This is the
implementation as it is meant to be, and the reason the listen watch loop
confirms readability for itself (L</THE LISTEN WATCH LOOP>). A program whose
queries are to overlap runs on an event loop.

=back

=head2 Future::IO::Impl::IOAsync

=over 4

=item * B<A cancelled poll keeps its watch>. The implementation
does nothing when a poll is cancelled: the loop goes on watching the handle,
and holding it, until that handle next turns readable, and only then drops
both. Here the handle is the dup of a connection's socket (L</_conn_poll_fh>),
and every statement let go of in flight leaves one behind -- a query cancelled
in flight, a statement whose connection was closed under it, a listen watch
that was stopped. The transport's part does not wait for it: the caller has
its outcome at the cancel or at the close, the connection is retired or closed
there, and an answer that still arrives is not read (L</STATEMENTS IN
FLIGHT>). What stays is the loop's watch and the dup's file descriptor, which
holds the socket open on this side, until the next event on that socket: the
abandoned statement's answer, or the server closing its end, as it does once
the driver has closed the connection. There is nothing to do about it; a
program that counts the loop's watches or its own file descriptors sees them
go one event late.

=item * B<A blocking call in a poll's callback dies when the socket turns
readable again.> The read handler resolves the first poll waiting on a handle
and takes it off its list only afterwards. A callback that runs from that
resolve and turns the loop itself -- a C<< ->get >> -- while the same handle
turns readable again has that event delivered to the poll that is already
done, and the death comes out of its C<< ->get >>:
C<< IO::Async::Future=HASH(...) is already done and cannot be ->done at
Future/IO/Impl/IOAsync.pm line 88 >>.

On this transport that is, first, a B<synchronous statement issued from the
callback of a statement on the same connection>: its own answer is the
event. A pinned connection is always the same one; a pooled query's
connection is back in the pool before its callbacks run (L</_query_async>),
so a synchronous query issued from one is handed that very connection
whenever it is the idle one. And core runs a transaction's block from the
callback of C<BEGIN>'s Future (L</THE PINNED STATEMENT QUEUE>), so B<every
synchronous statement of a C<txn_do> block> is such a statement:
C<< $ctx->select(...) >> in the block dies with the message above and the
transaction is rolled back. Second, it is a B<channel callback of C<listen>
that blocks> on anything while the next notification arrives on the listen
socket; uncaught, core reports the callback's death through
L<DBIO::Storage::Async/on_listen_error>, and delivery goes on.

In each case the statement was sent, and the transport still collects its
answer and hands its connection back; what is lost is the caller's
C<< ->get >>, and with it a transaction whose block dies of it. On this
implementation, chain the statements of a block instead of blocking
on them -- C<< $ctx->select_async(...)->then(...) >> under
L<DBIO::Storage::Async/txn_do_async> commits -- and do not block in a
callback. The built-in implementation runs the blocking form.

=back

=head1 THE LISTEN WATCH LOOP

L</_listen_watch> starts, and L</_listen_unwatch> stops, one generic loop per
listen connection. It has two modes, chosen by L</_listen_poll_interval> when
the watch starts:

=over 4

=item * B<socket-driven> (the default, C<undef>) -- wait until the
connection's socket is readable (L</_await_readable>, on the cached dup from
L</_conn_poll_fh>), drain, dispatch, wait again. The first drain runs B<one
loop tick after> the watch starts, before the first poll: a client library may
already hold notifications it read off the socket during the subscribe round
trip (libpq does), and those will never make the socket readable again. That
first drain is deliberately not run inside L</_listen_watch> itself. When the
seams resolve synchronously, as a blocking DBI connect does, core calls
L</_listen_watch> from inside L<DBIO::Storage::Async/listen> and
L<DBIO::Storage::Async/listen_reconnect>, and fires
L<DBIO::Storage::Async/on_listen_reconnect> only once it has returned. A drain
inside it would run a channel callback before that call returned -- and only
when something happened to be buffered -- and, on a rebuilt connection, before
the hook that tells the consumer the stream broke.

After every poll the loop confirms readability with a zero-timeout C<select>
on the dup before it drains, and simply polls again when the socket is quiet.
L<Future::IO>'s built-in implementation does not C<select> at all while it has
only read pollers and no timer: it presumes each poll ready and clears
C<O_NONBLOCK> on the handle while the callback runs. A drain called then on a
quiet socket would block in C<recv> -- and with it the query the program was
actually waiting for -- until the next notification arrived.

=item * B<timer-driven> (a positive number of seconds) -- wait that long
(L</_listen_delay>), drain, dispatch, wait again. For an engine with no server
push, emulating notifications with a notify table: latency is the poll
interval, and a notification becomes visible when the transaction that wrote
it commits. A driver that declares C<listen> in this mode B<must> state both in
its POD (core ADR 0056 §6). In this mode the loop itself never touches the
socket: it calls neither L</_conn_fileno> nor L</_conn_poll_fh> (a drain that
runs its query through L</_query_async_pinned> polls the socket for that query,
as any query does).

=back

Each tuple L</_listen_drain> returns goes to
C<< $self->_listen_dispatch($channel, $payload, $sender_pid) >>, in the order
drained. Any error -- the poll or the timer failing, the drain dying or its
Future failing, a malformed drain result, a throw anywhere in the iteration --
goes to C<< $self->_listen_lost($conn, $error) >> and ends the loop; core heals
by opening a new connection and watching that.

The loop keeps its state on the connection hashref under the reserved key
C<_dbio_async_listen_watch> (next to C<_dbio_async_poll_fh>, see
L</_conn_poll_fh>): the watching process's pid, the mode, and the Future the
loop currently awaits. The callbacks the loop registers hold the storage, the
connection and that state only B<weakly>, so the one strong path is
connection -E<gt> state -E<gt> pending Future and nothing points back. The
state also holds a driver's pending drain Future strongly -- nothing else may:
a L<Future> holds the Futures derived from it only weakly.

The state is the watch's identity. Every iteration checks, before each
dispatch and before re-arming, that it is still the state on the connection;
L</_listen_unwatch> removes it. So a channel callback that unlistens the last
channel, or calls C<listen_reconnect>, in the middle of a batch ends the loop
right there: the rest of that batch is not dispatched and nothing is re-armed.
The recorded pid does the same across C<fork>: a poll inherited by a child
whose own loop fires it does nothing, so the child never reads the parent's
socket.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
