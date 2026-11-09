package DBIO::MySQL::EV::QueryExecutor;
# ABSTRACT: Query execution wrapper for DBIO MySQL async storage

use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util ();
use DBIO::Exception ();
use DBIO::Exception::Server ();
use DBIO::MySQL::EV::Future;


# Per connection (refaddr of the handle), the settling of one of its Futures
# that runs right now (_drain) -- the innermost one when they nest:
# { active => 1 } while it runs. What it calls is a then chain or a txn_do
# coderef, which holds the connection's transaction until it returns
# (_waits_for_callback, karr k53). Not EV::MariaDB's callback_depth: those
# callbacks only prepare, execute, close and hand the answer on (karr k51).
my %FRAME;

# Per connection, how often it was forgotten (forget): the settling of a
# statement that was answered before its handle was forgotten leaves the counts
# alone, they belong to the next handle at that address.
my %GEN;

# Per connection (refaddr of the handle), the number of statements dispatched
# on it whose Future has not settled: counted up once EV::MariaDB has taken the
# statement, down where the Future is settled. A count that is never taken
# down -- a handle that goes away without calling back, or a forked child,
# where the callbacks return at once -- reads as work in flight, which errs on
# the side of waiting.
my %IN_FLIGHT;

# Per connection, how many of those are exclusive operations (prepare, execute,
# close_stmt): a statement with bind values or a CALL. While one is in flight
# EV::MariaDB refuses a query (karr k81).
my %EXCL;

# Per connection, the statements that wait for every statement in flight on it
# to settle (execute_when_idle): coderefs, oldest first, each started once the
# count above is back at zero: { future => the Future the caller waits on,
# run => the coderef that starts it }. They hold the handle weakly; forget
# fails the futures.
my %AFTER;

# The executor traces nothing: it is no storage. The statement trace is the
# core's (DBIO::Storage::Async/_debug_query, ADR 0025), called by
# DBIO::MySQL::EV::Storage once per statement.
sub new {
  my ($class, %args) = @_;
  bless {
    future_class => $args{future_class} // 'DBIO::MySQL::EV::Future',
    error_masker => $args{error_masker},
  }, $class;
}



sub execute {
  my ($self, $mdb, $sql, $bind) = @_;
  $bind //= [];

  my $f   = $self->{future_class}->new;
  my $pid = $$;
  my $key = Scalar::Util::refaddr($mdb);
  my $exclusive = (@$bind || _is_call($sql)) ? 1 : 0;
  my $settle = _settle_cb($f, $pid, $key, $exclusive);

  # EV::MariaDB::query($sql, $cb) does NOT accept bind values — passes a
  # bind arrayref to it is silently dropped. When the SQL has placeholders
  # we MUST route through prepare + execute; otherwise the bind values
  # never reach the server and the query fails with a SQL syntax error on
  # the '?' placeholders (or, worse, runs with whatever the previous
  # prepared statement's binds were — silent corruption). Empty binds
  # stay on the cheap query() path.
  #
  # A CALL without bind values goes the same way (karr k84). EV::MariaDB's
  # query() calls back with the first result set and reads the rest of the
  # answer -- the closing OK of the CALL, further result sets -- only after the
  # callback returned, with nothing on the handle that says so; a statement
  # with bind values that follows on the connection is then refused. Prepared
  # and executed, the whole answer is read before the callback runs.
  #
  # An error text is masked (ADR 0075 of the core) by $mask, built here from
  # the bound values and the statement; a dispatch EV::MariaDB refuses dies
  # with its text masked as well.
  my $mask = _error_mask($self->{error_masker}, $bind, $sql);
  {
    local $@;
    my $dispatched = eval {
      if (@$bind || _is_call($sql)) {
        $mdb->prepare($sql, _prepared_cb($mdb, $bind, $settle, $pid, $mask));
      }
      else {
        $mdb->query($sql, _queried_cb($mdb, $settle, $pid, $mask));
      }
      1;
    };
    unless ($dispatched) {
      my $died = $@;
      die _masked($mask, $died);
    }
  }

  # Dispatched -- a croak above never gets here. A handle that called back
  # before it returned has settled the Future already and left the count at
  # -1, so both sides drop the entry at zero.
  delete $IN_FLIGHT{$key} unless ++$IN_FLIGHT{$key};
  delete $EXCL{$key} if $exclusive && !++$EXCL{$key};

  return $f;
}


sub reset_connection {
  my ($self, $mdb) = @_;

  my $f   = $self->{future_class}->new;
  my $pid = $$;
  my $key = Scalar::Util::refaddr($mdb);
  my $settle = _settle_cb($f, $pid, $key, 1);

  my $mask = _error_mask($self->{error_masker}, [], undef);
  $mdb->reset_connection(_reset_cb($settle, $mask));

  delete $IN_FLIGHT{$key} unless ++$IN_FLIGHT{$key};
  delete $EXCL{$key} if !++$EXCL{$key};

  return $f;
}


sub execute_when_idle {
  my ($self, $mdb, $sql, $bind, $timeout) = @_;

  my $key = Scalar::Util::refaddr($mdb);
  return $self->execute($mdb, $sql, $bind) unless $IN_FLIGHT{$key};
  return $self->_enqueue($mdb, $sql, $bind, $timeout);
}


sub execute_after_exclusive {
  my ($self, $mdb, $sql, $bind) = @_;
  my $key = Scalar::Util::refaddr($mdb);
  return $self->execute($mdb, $sql, $bind) unless $EXCL{$key} || ($AFTER{$key} && $IN_FLIGHT{$key});
  return $self->_enqueue($mdb, $sql, $bind);
}

# Queue a statement behind the ones in flight on $mdb. With a $timeout (seconds,
# a positive number) its Future fails with a DBIO::Exception naming the wait
# when the statement has not been started by then (karr k81).
sub _enqueue {
  my ($self, $mdb, $sql, $bind, $timeout) = @_;
  my $key = Scalar::Util::refaddr($mdb);

  my $outer = $self->{future_class}->new;
  my $timer;
  if ($timeout && $timeout > 0) {
    Scalar::Util::weaken(my $weak_outer = $outer);
    $timer = EV::timer($timeout, 0, sub {
      undef $timer;
      my $f = $weak_outer or return;
      return if $f->is_ready;
      local $@;
      eval { DBIO::Exception->throw(
        "statement not sent: the statement in flight on the connection did not answer within ${timeout}s", 0) };
      $f->fail($@);
    });
    $outer->on_ready(sub { undef $timer });
  }
  Scalar::Util::weaken(my $weak_mdb = $mdb);
  push @{ $AFTER{$key} }, { future => $outer, run => sub {
    undef $timer;
    return if $outer->is_ready;
    my $handle = $weak_mdb
      or return $outer->fail('connection is gone before the statement could be sent');
    my $inner;
    {
      local $@;
      unless (eval { $inner = $self->execute($handle, $sql, $bind); 1 }) {
        return $outer->fail($@ || 'statement could not be sent');
      }
    }
    $inner->on_done(sub { $outer->done(@_) unless $outer->is_ready });
    $inner->on_fail(sub { $outer->fail(@_) unless $outer->is_ready });
    return;
  } };
  return $outer;
}

# Start the statements that wait on $key, for as long as nothing is in flight
# on it. One that was dispatched is in flight itself, and the one behind it
# starts when that one settles. One that sent nothing -- its Future was
# cancelled while it waited, its handle is gone, EV::MariaDB refused it --
# leaves nothing in flight, and no settling would ever come back here for the
# ones behind it: so the next one is started right away, until one is in flight
# or none is left.
sub _start_next {
  my ($key) = @_;
  until ($IN_FLIGHT{$key}) {
    my $queue = $AFTER{$key} or return;
    my $next = shift @$queue;
    delete $AFTER{$key} unless @$queue;
    $next->{run}->() if $next;
  }
  return;
}


sub _waits_for_callback {
  my ($class, $mdb) = @_;
  my $key = Scalar::Util::refaddr($mdb);
  return $FRAME{$key} && !$IN_FLIGHT{$key} ? 1 : 0;
}


sub forget {
  my ($class, $mdb) = @_;
  return unless defined $mdb;
  my $key = Scalar::Util::refaddr($mdb);
  delete $FRAME{$key};
  delete $IN_FLIGHT{$key};
  delete $EXCL{$key};
  $GEN{$key}++;
  $class->_fail_waiting($mdb);
  return;
}


sub _fail_waiting {
  my ($class, $mdb) = @_;
  return unless defined $mdb;
  my $waiting = delete $AFTER{ Scalar::Util::refaddr($mdb) };
  for my $w (@{ $waiting || [] }) {
    my $f = $w->{future};
    next if $f->is_ready;
    local $@;
    eval { DBIO::Exception->throw('connection torn down, statement not sent', 0) };
    $f->fail($@);
  }
  return;
}

# The callbacks below are named subs, not closures inside execute(): each
# closes over exactly what it is handed. The bind arrayref reaches the prepare
# callback, which hands it to execute -- the dispatch where its lifetime ends
# (ADR 0044) -- and no later callback holds it.
#
# Each returns at once outside $pid, the process that called execute(): in a
# forked child they run when the pool's fork guard finishes the child's copy of
# the handle (karr k46), and what they would do next -- close, settle, release,
# the caller's chain -- is the parent's.

# Settles $f with an EV::MariaDB result ($rows, $err). Runs at most once: a
# close_stmt that croaked after calling back must not settle twice.
sub _settle_cb {
  my ($f, $pid, $key, $exclusive) = @_;
  my $settled;
  return sub {
    my ($rows, $err) = @_;
    return if $$ != $pid;
    return if $settled++;
    # The Future settles from an idle watcher of the loop, not from inside this
    # callback of the handle (karr k51): what its callbacks run -- a then, the
    # coderef of a txn_do -- is outside every callback of the handle, so a
    # statement it sends goes out at once and a blocking wait for it can end.
    my $gen = $GEN{$key} // 0;
    _defer($pid, $key, sub {
      # Before the Future is settled: what that runs sees the statement answered.
      if (($GEN{$key} // 0) == $gen) {
        delete $IN_FLIGHT{$key} unless --$IN_FLIGHT{$key};
        delete $EXCL{$key} if $exclusive && !--$EXCL{$key};
      }
      if ($err) {
        $f->fail($err);
      } else {
        $f->done(ref $rows eq 'ARRAY' ? @$rows : $rows);
      }
      # What waits for the connection to have nothing in flight starts now
      # (execute_when_idle), after what the settling above ran.
      _start_next($key);
    });
    return;
  };
}

# The settlings the idle watcher has still to run, oldest first:
# [ $pid, $key, $code ]. One watcher for all connections, so Futures settle in
# the order the handles answered.
my @DEFERRED;
my $IDLE;

# Queue $code, to run from the loop's idle watcher. It runs as a callback of
# connection $key (the frame k53 asks about): a transaction's coderef, run by
# the settling of its BEGIN, holds its connection until it returns.
sub _defer {
  my ($pid, $key, $code) = @_;
  push @DEFERRED, [ $pid, $key, $code ];
  $IDLE ||= EV::idle_ns(\&_drain);
  $IDLE->start;
  return;
}

# The idle watcher. Entries taken one at a time and before they run, so a
# blocking wait inside one of them -- a nested EV::run, which runs this watcher
# again -- carries on with the ones behind it and none runs twice. An entry
# that dies is warned about, like EV::MariaDB does for its callbacks, and does
# not stop the ones behind it. Entries of another process (a forked child
# inherits the parent's) are dropped: the parent runs them.
sub _drain {
  while (my $entry = shift @DEFERRED) {
    my ($pid, $key, $code) = @$entry;
    next if $$ != $pid;
    my $frame = {};
    local $frame->{active} = 1;
    local $FRAME{$key} = $frame;
    local $@;
    eval { $code->(); 1 } or warn "DBIO::MySQL::EV: exception in callback: $@";
  }
  $IDLE->stop if $IDLE && !@DEFERRED;
  return;
}

sub _prepared_cb {
  my ($mdb, $bind, $settle, $pid, $mask) = @_;
  return sub {
    my ($stmt, $perr) = @_;
    return if $$ != $pid;
    # No statement id, nothing to close.
    return $settle->(undef, _server_error($mdb, $perr, $mask) || 'prepare failed') if $perr || !defined $stmt;
    local $@;
    eval { $mdb->execute($stmt, $bind, _executed_cb($mdb, $stmt, $settle, $pid, $mask)); 1 }
      or _close_and_settle($mdb, $stmt, $settle, undef, _masked($mask, $@ || 'execute failed'));
    return;
  };
}

sub _executed_cb {
  my ($mdb, $stmt, $settle, $pid, $mask) = @_;
  return sub {
    my ($rows, $err) = @_;
    return if $$ != $pid;
    # Read before the close: it is the execute's error the handle holds now.
    _close_and_settle($mdb, $stmt, $settle, $rows, _server_error($mdb, $err, $mask));
    return;
  };
}

sub _queried_cb {
  my ($mdb, $settle, $pid, $mask) = @_;
  return sub {
    my ($rows, $err) = @_;
    return if $$ != $pid;
    return $settle->($rows, _server_error($mdb, $err, $mask));
  };
}

sub _reset_cb {
  my ($settle, $mask) = @_;
  return sub {
    my ($ok, $err) = @_;
    $settle->($err ? (undef, _masked($mask, $err)) : (1, undef));
  };
}

# The mask of one statement: a coderef text -> text with the values out, or
# undef without a masker. It holds a copy of the bound values that can be found
# in a text (defined, not a reference, four characters or more, as strings) and
# the statement -- never the caller's bind arrayref (ADR 0044).
sub _error_mask {
  my ($masker, $bind, $sql) = @_;
  return unless $masker;
  my @values = map { "$_" } grep { defined && !ref && length >= 4 } @{ $bind || [] };
  return sub { $masker->($_[0], \@values, $sql) };
}

# An error text through the mask; an object, undef and an empty text as they are.
sub _masked {
  my ($mask, $err) = @_;
  return $err unless $mask && defined $err && !ref $err && length $err;
  return $mask->($err);
}


sub _server_error {
  my ($mdb, $err, $mask) = @_;
  return $err if ref $err or not defined $err or not length $err;
  my $state = _server_sqlstate($mdb, $err)
    or return _masked($mask, $err);
  return DBIO::Exception::Server->new(message => _masked($mask, $err), sqlstate => $state);
}

# The SQLSTATE of the handle when $err is a refusal by the server, else undef.
sub _server_sqlstate {
  my ($mdb, $err) = @_;
  return unless Scalar::Util::blessed($mdb)
    && $mdb->can('sqlstate') && $mdb->can('error_number') && $mdb->can('error_message');
  my ($state, $number, $message) = eval { ($mdb->sqlstate, $mdb->error_number, $mdb->error_message) };
  return unless defined $state && $state =~ /\A[0-9A-Z]{5}\z/ && $state ne '00000';
  return unless defined $number && ($number >= 1000 && $number < 2000 || $number >= 3000);
  return unless defined $message && $message eq $err;
  return $state;
}

# Close the statement, then settle with the execute's outcome. The close's own
# result does not change that outcome; a close that croaks settles at once.
sub _close_and_settle {
  my ($mdb, $stmt, $settle, $rows, $err) = @_;
  my $closing;
  {
    local $@;
    $closing = eval { $mdb->close_stmt($stmt, sub { $settle->($rows, $err) }); 1 };
  }
  $settle->($rows, $err) unless $closing;
  return;
}

# True for a statement that begins with CALL, behind leading whitespace and
# comments (-- and # to the end of the line, /* ... */), in any case.
sub _is_call {
  my ($sql) = @_;
  return defined $sql && $sql =~ m{\A(?:\s+|--[ \t][^\n]*(?:\n|\z)|\#[^\n]*(?:\n|\z)|/\*.*?\*/)*CALL\b}is ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::QueryExecutor - Query execution wrapper for DBIO MySQL async storage

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Provides a single C<execute($conn, $sql, $bind)> interface for query
execution. The connection is supplied per call by the caller (the storage
acquires it from the pool, or hands over a pinned one), so the executor holds
no connection state of its own and returns a L<Future> with the result rows.

The Future is of the class passed to C<new> as C<future_class> -- the storage
passes its L<DBIO::MySQL::EV::Storage/future_class> -- and defaults to
L<DBIO::MySQL::EV::Future>. It settles from an idle watcher of the EV loop that
runs after the EV::MariaDB callback of the statement (below), so its C<get> has
to be able to run the EV loop: a plain L<Future> dies there instead.

A query with bind values goes C<prepare> -> C<execute> -> C<close_stmt>
(L<EV::MariaDB/query> takes no binds). The close is not optional: the statement
id L<EV::MariaDB> hands out is a plain integer, so nothing frees the server-side
statement when the Perl side lets go of it -- without C<close_stmt> the server
keeps every one until the connection closes, and a long-lived pool runs into the
server-wide C<max_prepared_stmt_count>, which then refuses prepares for every
client of that server. A query without binds is a plain C<query> --
except a C<CALL>: EV::MariaDB
calls back for a C<query> with the first result set and reads the rest of the
answer only after the callback, and a statement with bind values that follows
on that connection is refused. A statement without bind values that begins with
C<CALL> (leading whitespace and comments allowed) goes through C<prepare> too, so
the whole answer is read when the Future settles (ADR 0010). A
multi-statement text that does not begin with C<CALL> is not recognised.

A Future settles from the loop's idle watcher, not inside the EV::MariaDB
callback that delivered the answer (ADR 0001 addendum). EV::MariaDB
queues a plain C<query> issued while a callback of its handle runs and sends it
only once that callback has returned, so a C<then> or a C<txn_do> coderef run
from inside the callback could not wait for a statement it sent there. Run from
the watcher they are outside every callback of the handle, the statement goes
out at once, and a blocking wait for it ends. Everything of the answer that
concerns the wire stays in the callback -- the C<close_stmt> of a statement
with bind values is issued there, and the Future settles after it has been
answered -- and only the settling is deferred: the count of
statements in flight, the Future's C<done> or C<fail> with the callbacks
hanging off it, and the start of the statements that wait behind it
(L</execute_when_idle>), in that order. Settlings run oldest first, one
watcher for all connections, so Futures settle in the order the handles
answered; one that dies is warned about and does not stop the ones behind it.
A blocking wait inside one of them runs the loop, and with it this watcher, so
the settlings behind it carry on meanwhile.

It also counts, per connection, the statements it has dispatched whose Future
has not settled yet. A connection with one of its settlings running (the C<then> chain of a
statement, the coderef of a C<txn_do>) and no such statement has nothing left
to do before that returns (L</_waits_for_callback>). L<DBIO::MySQL::EV::Pool> asks that of each of its
connections to tell whether a caller queued for one can still be served while
a blocking wait runs (L<DBIO::MySQL::EV::Pool/_mysql_held_by_callbacks>).

Separated from Storage to allow independent testing of query execution
logic from connection pooling and transaction orchestration.

=head1 METHODS

=head2 new

  my $executor = DBIO::MySQL::EV::QueryExecutor->new(
    future_class => 'DBIO::MySQL::EV::Future',
    error_masker => \&mask,
  );

C<error_masker> is optional: a coderef called as C<< $masker->($text, \@values,
$sql) >> that answers the text of an error with the values taken out
(ADR 0075 of the core: an error names keys, columns and options, never a value;
MySQL and MariaDB write the offending value into their text, a bound one
included). Every error text a statement ends in goes through it B<before> the
exception is built -- the server's answer to the C<prepare>, the C<execute> and
the C<query>, the text of an C<execute> that croaks, and the croak of a dispatch
EV::MariaDB refuses (L</execute> rethrows it masked). An exception object is
passed on as it is. C<\@values> are the bound values that can be looked for in a
text -- the defined, non-reference ones of four characters or more, as plain
strings, a copy: the caller's bind arrayref is not held (ADR 0044) -- and
C<$sql> the statement as it was handed over. The SQLSTATE of the server's
refusal stays. Without a masker the text is the engine's own. The storage
passes L<DBIO::MySQL::EV::Storage/_mysql_mask_error>.

=head2 execute

  my $future = $executor->execute($mdb, $sql, $bind);

Execute a query on a given L<EV::MariaDB> connection. Returns a L<Future>
that resolves with the result rows (array or arrayref).

With bind values the prepared statement is closed after C<execute> -- after a
failed C<execute> too, and after one that croaked -- and the Future settles only
once that close has completed. C<close_stmt> is an exclusive operation, so the
handle is not idle before then, and a caller that hands the connection back to
the pool when the Future is ready (L<DBIO::MySQL::EV::Storage/_query_async>)
must not do so earlier. The Future carries the outcome of the C<execute>: a
C<close_stmt> that croaks or reports an error settles it at once with that
outcome and changes nothing about it -- an INSERT that ran is not reported as
failed because its statement could not be closed. It settles exactly once.

The Future settles from the idle watcher, after the callback of the handle has
returned: a statement issued by what its callbacks run -- a C<then>,
the coderef of a C<txn_do> -- is sent at once, with or without bind values, and
a blocking wait for it returns.

Every callback returns at once in a process other than the one that called
C<execute>. A forked child that resumes the EV loop C<finish>es its copies of
the pooled handles (L<DBIO::MySQL::EV::Pool/_create_connection>), and
EV::MariaDB calls back every statement in flight with a "connection finished"
error; the child must not answer that with a C<close_stmt>, a release into the
pool or the caller's callbacks -- all of them belong to the parent. The Future
stays pending in the child (ADR 0010).

=head2 reset_connection

  my $future = $executor->reset_connection($mdb);

Send C<COM_RESET_CONNECTION> on C<$mdb> (L<EV::MariaDB/reset_connection>) and
return a L<Future> that resolves with C<1> once the server answered, or fails
with its error. The server drops the session state of the connection (user and
session variables, temporary tables, prepared statements, locks taken with
C<GET_LOCK>, an open transaction); the client library marks its statement
handles closed. The operation is exclusive in EV::MariaDB, so it is counted like
a statement with bind values: what is issued behind it through
L</execute_after_exclusive> waits for it. A dispatch EV::MariaDB refuses dies,
as L</execute> does. The Future settles from the idle watcher, as every other.

=head2 execute_when_idle

  my $future = $executor->execute_when_idle($mdb, $sql, $bind, $timeout);

Like L</execute>, but behind every statement still in flight on C<$mdb>: the
statement is handed to EV::MariaDB only once the Future of the last of them has
settled -- for a statement with bind values that is after its C<close_stmt> --
and at once when none is in flight. One order per connection: statements queued
this way start in the order they were queued, each after the one before it has
settled.

The reason is EV::MariaDB's own: it refuses a C<query> ("cannot queue query:
exclusive operation in progress") while a C<prepare> or an C<execute> is in
flight, and the ROLLBACK of a failed transaction is a query. The
statement is started from the callback that settles the last statement in
flight, after that Future was settled; a query issued there is taken and sent
once the callback returned (measured live, t/37-txn-rollback-refused-live.t).

The returned Future settles with the outcome of the statement. A dispatch
EV::MariaDB refuses fails it with that error, where L</execute> dies. A handle
that is gone before its turn, or a Future that was cancelled while it waited,
means the statement is never sent; a handle that is torn down while the
statement waits (L</forget>) fails its Future with a L<DBIO::Exception>. With
a positive C<$timeout> (seconds) a statement that has not been started by then
is not sent: its Future fails with a L<DBIO::Exception> naming the wait. A
waiting statement that sends nothing does not hold up the ones behind it: the
next one starts in its place.

=head2 execute_after_exclusive

  my $future = $executor->execute_after_exclusive($mdb, $sql, $bind);

Like L</execute>, but a statement issued while a C<prepare> or an C<execute>
(a statement with bind values, a C<CALL>) is in flight on C<$mdb>, or while
others wait behind a statement in flight, is queued as L</execute_when_idle>
queues it and handed to EV::MariaDB when the Future of the statement in flight
has settled. EV::MariaDB refuses a C<query> while such an operation is in
flight (this holds for every statement of a pinned connection, not only
C<ROLLBACK>). With only plain queries in flight the statement goes out at
once, pipelined behind them as before.

=head2 _waits_for_callback

  my $stalled = DBIO::MySQL::EV::QueryExecutor->_waits_for_callback($mdb);

Class method. True when a settling of a Future of C<$mdb> runs -- the idle
watcher is calling what hangs off a statement's Future: a C<then>, the coderef
of a C<txn_do> -- and no statement dispatched on C<$mdb> is still unsettled:
the connection has nothing in flight that the loop could answer, and whatever
is to happen on it next waits for that to return -- a transaction's C<COMMIT>
or C<ROLLBACK> included, which core sends only after the coderef has returned.
False for a connection none of whose settlings runs, and for one with a
statement in flight, whose answer may be what gives the connection back to the
pool.

=head2 forget

  DBIO::MySQL::EV::QueryExecutor->forget($mdb);

Class method. Drop everything the executor keeps for C<$mdb>: the callback
frame, the count of statements in flight and the statements waiting behind
them (L</execute_when_idle>). Called where a handle goes away -- it is shut
down (L<DBIO::MySQL::EV::Pool/_shutdown_connection>) or a forked child
finishes its copy of it (L<DBIO::MySQL::EV::Pool/_create_connection>). Those
are kept per address of the handle and nothing else removes them: a count left
over for a handle that never called back would be read by a later handle at the
same address as work in flight. A new handle starts from nothing.
Every waiting statement is failed, not run, and not left pending: its Future
fails with a L<DBIO::Exception> saying the connection was torn down and the
statement not sent, oldest first. One whose Future is ready already (cancelled
while it waited) is left alone. The queue is taken out before any Future is
failed, so a callback of a failure may call C<forget> or L</execute_when_idle>
again.

=head2 _fail_waiting

  DBIO::MySQL::EV::QueryExecutor->_fail_waiting($mdb);

Class method. Take the statements waiting behind others on C<$mdb> out of the
queue and fail their Futures (see L</forget>); touches nothing else the executor
keeps. Called by L</forget>, and by
L<DBIO::MySQL::EV::Pool/_shutdown_connection> B<before> C<finish>: C<finish>
calls back the statement in flight, which would start the waiting ones against
the finished handle.

=head2 _server_error

  my $error = DBIO::MySQL::EV::QueryExecutor::_server_error($mdb, $text, $mask);

The error of a statement as its Future fails with it (core ADR 0062):
a L<DBIO::Exception::Server> carrying the C<sqlstate> when the B<server>
refused the statement, the text itself otherwise. It stringifies to C<$text>
with the values taken out by C<$mask> (an optional coderef, see L</new>; the
comparison with the handle's error below is made with the text as the handle
holds it, the masking comes after). Called from the statement's own callback, where the handle still
holds that error.

The line is drawn by the handle and the text: the handle's C<error_message>
is C<$text>, its C<sqlstate> is a real one (not C<00000>), and its
C<error_number> is a server's -- 1000 to 1999, or 3000 and up (MariaDB's own
range) -- and not one of the client library's (2000 to 2999: connection lost,
server gone away, commands out of sync). A client error, an object and
C<undef> pass unchanged. C<table>, C<constraint> and C<detail> are not
reported: the client library names none of them separately.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
