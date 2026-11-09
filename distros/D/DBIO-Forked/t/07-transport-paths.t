use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);
use Storable ();
use Time::HiRes ();

# OFFLINE test: the transport paths the documentation describes and no other
# test runs (karr k15).
#
# WHY: t/01 and t/03 run select_async, insert_async, update_async and
# txn_do_async once each. Everything else this backend documents was claimed
# on paper only: the six blocking wrappers, delete_async and
# select_single_async, the two reads _forked_child_run reshapes for core's
# ResultSet helpers (ADR 0031), a child that dies before it answers, a Future
# nobody collects, a result larger than the pipe buffer (ADR 0003), the async
# API of the base class that has no meaning without a pool or a query seam,
# and the one thing the POD only warns about -- a *_async call inside a
# txn_do_async body. Each of them is a path a caller can take; this file takes
# them.
#
#   1. the six blocking wrappers run the op in a child and return its result;
#   2. delete_async and select_single_async, and the shapes select_async and
#      select_single_async resolve to: a cursor is drained, a single row is
#      one arrayref, no row is nothing;
#   3. a child that dies before it writes: a failed Future saying so, reaped;
#   4. a Future dropped without get: DESTROY ends and reaps the child, also when the
#      child is blocked writing a result nobody will read;
#   5. a result larger than the pipe buffer: complete through get, and
#      complete through repeated is_ready (drained over several calls);
#   6. *_async inside a txn_do_async body: there is no guard, it forks again
#      from within the child;
#   7. pipeline, listen, deploy_async: what the caller is told.
#
# WHAT RUNS FOR REAL: fork + pipe + Storable, DBIO::Forked::Storage and its
# Future; in section 7 also core's DBIO::Schema and DBIO::Storage::DBI as the
# owner, never connected.
# THE SUBSTITUTIONS: no DBI and no database. Sections 1-6 run a mock sync
# storage whose ops answer fixed data or echo their arguments together with
# the pid they ran in -- so a result also says WHERE it was computed.

use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Forked::Storage;
use DBIO::Forked::Future;

alarm 60;

my $BIG_BYTES = 200 * 1024;   # three times a 64 KiB pipe buffer, and then some

{
  # What a real sync select() returns: a cursor, not rows. Blessed, answers all.
  package t::Mock::Cursor;
  sub new { my ($class, @rows) = @_; bless { rows => [ @rows ] }, $class }
  sub all { @{ $_[0]{rows} } }

  package t::Mock::Storage;
  sub new { bless {}, shift }

  # 200 KiB whose every four bytes differ: a lost, repeated or misplaced chunk
  # changes the string, which a run of one character would not show.
  sub big { pack 'N*', 0 .. $BIG_BYTES / 4 - 1 }

  sub select {
    my ($self, $what) = @_;
    return t::Mock::Cursor->new([ 1, 'Alice' ], [ 2, 'Bob' ]) if $what eq 'cursor';
    return t::Mock::Cursor->new                               if $what eq 'empty-cursor';
    return ([ 1, 'Alice' ])                                   if $what eq 'one-row';
    return ([ 1, $self->big ])                                if $what eq 'big';
    return ([ $$ ])                                           if $what eq 'whoami';
    if ($what eq 'slow') { Time::HiRes::sleep(0.3); return ([ 'late' ]) }
    kill KILL => $$                                           if $what eq 'die-unanswered';
    return ([ 1, 'Alice' ], [ 2, 'Bob' ]);
  }

  # Sync select_single returns the column values as a flat list.
  sub select_single {
    my ($self, $what) = @_;
    return $what eq 'miss' ? () : (7, 'Grace');
  }

  sub insert { my $self = shift; return { op => 'insert', pid => $$, args => [ @_ ] } }
  sub update { my $self = shift; return { op => 'update', pid => $$, args => [ @_ ] } }
  sub delete { my $self = shift; return { op => 'delete', pid => $$, args => [ @_ ] } }

  sub txn_do {
    my ($self, $code, @args) = @_;
    return { op => 'txn_do', pid => $$, body => [ $code->(@args) ] };
  }

  package t::Mock::Schema;
  sub new { my ($class, $storage) = @_; bless { storage => $storage }, $class }
  sub storage { $_[0]->{storage} }
}

my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);
my $storage = DBIO::Forked::Storage->new($schema);

# Nothing left to wait for: no child of this process, running or dead. The
# stricter reading of "no zombies" -- a 0 here would be a child still alive.
sub no_children_ok {
  my ($name) = @_;
  my $found = waitpid(-1, WNOHANG);
  is $found, -1, $name;
}

# Computed in another process: a pid, and not ours.
sub in_child_ok {
  my ($pid, $name) = @_;
  ok defined $pid && $pid =~ /^\d+\z/ && $pid != $$, $name;
}

# ---------------------------------------------------------------------------
# 1. The six blocking wrappers.
# ---------------------------------------------------------------------------
{
  is_deeply [ $storage->select('rows') ], [ [ 1, 'Alice' ], [ 2, 'Bob' ] ],
    'select: blocks and returns the rows';

  # The wrappers answer in the shapes of the *_async methods they block on, not
  # in those of the sync storage: rows where that returns a cursor, one row
  # arrayref where that returns the column values as a list.
  is_deeply [ $storage->select_single('hit') ], [ [ 7, 'Grace' ] ],
    'select_single: blocks and returns the one row';

  for my $op (qw( insert update delete )) {
    my $got = $storage->$op('artist', { name => 'Carol' }, { id => 3 });
    is $got->{op}, $op, "$op: blocks and returns what the sync $op answered";
    is_deeply $got->{args}, [ 'artist', { name => 'Carol' }, { id => 3 } ],
      "$op: with the arguments as given";
    in_child_ok($got->{pid}, "$op: computed in a child, not in this process");
  }

  my $got = $storage->txn_do(sub { return [ reverse @_ ] }, 'x', 'y');
  is $got->{op}, 'txn_do', 'txn_do: blocks and returns what the sync txn_do answered';
  is_deeply $got->{body}, [ [ 'y', 'x' ] ], 'txn_do: the body ran with its arguments';
  in_child_ok($got->{pid}, 'txn_do: computed in a child, not in this process');

  no_children_ok('the wrappers reaped every child they forked');
}

# ---------------------------------------------------------------------------
# 2. delete_async, select_single_async, and the two reshaped reads.
# ---------------------------------------------------------------------------
{
  my $got = $storage->delete_async('artist', { id => 3 })->get;
  is $got->{op}, 'delete', 'delete_async: ran the sync delete';
  is_deeply $got->{args}, [ 'artist', { id => 3 } ], '... with the arguments as given';
  in_child_ok($got->{pid}, '... in a child');

  # ADR 0031: single_async / count_async read ONE row, so the flat list the
  # sync select_single returns has to arrive as one arrayref.
  is_deeply [ $storage->select_single_async('hit')->get ], [ [ 7, 'Grace' ] ],
    'select_single_async: the column values arrive as ONE row arrayref';
  is_deeply [ $storage->select_single_async('miss')->get ], [],
    'select_single_async: no row is nothing, not an empty row';

  # ADR 0031: a real driver's select() returns an unexecuted cursor. The child
  # has to drain it -- the parent can do nothing with a cursor whose handle
  # lives in a process that is gone.
  is_deeply [ $storage->select_async('cursor')->get ], [ [ 1, 'Alice' ], [ 2, 'Bob' ] ],
    'select_async: a cursor is drained in the child, its rows arrive';
  is_deeply [ $storage->select_async('empty-cursor')->get ], [],
    'select_async: an empty cursor is no rows (not the cursor itself)';
  is_deeply [ eval { $storage->select_async('one-row')->get } ], [ [ 1, 'Alice' ] ],
    'select_async: a single already-materialized row is passed through, not taken for a cursor';
}

# ---------------------------------------------------------------------------
# 3. The child dies before it writes anything.
# ---------------------------------------------------------------------------
{
  my $f = $storage->select_async('die-unanswered');   # SIGKILL: no blob, no exit code path
  eval { $f->get };
  like $@, qr/DBIO::Forked::Future: child killed by signal 9 before sending a result/,
    'a child that dies unanswered: get throws, naming the signal (karr k20)';;
  ok $f->is_failed, '... the Future is failed';

  # $f is still alive here: the reaping is get's, not DESTROY's.
  no_children_ok('... and the dead child was reaped by get');

  eval { $f->get };
  like $@, qr/killed by signal 9/, 'get stays failed when asked again';
}

# ---------------------------------------------------------------------------
# 4. A Future nobody collects.
# ---------------------------------------------------------------------------
{
  # The child is still at work when the Future goes: DESTROY has to end and
  # reap it, or it is left behind (alive now, a zombie later).
  my $f = $storage->select_async('slow');
  undef $f;
  no_children_ok('a Future dropped without get: DESTROY reaped its child');

  # The child of a large result is blocked in its write until somebody reads
  # (ADR 0003). Nobody will: DESTROY must close the read end before it waits,
  # or it waits for a child that waits for it.
  $f = $storage->select_async('big');
  Time::HiRes::sleep(0.2);
  undef $f;
  no_children_ok('a dropped Future over a result larger than the pipe buffer: no deadlock, child reaped');
}

# ---------------------------------------------------------------------------
# 5. A result larger than the pipe buffer.
# ---------------------------------------------------------------------------
{
  my $expected = t::Mock::Storage->big;
  die 'fixture: the big row is not 200 KiB' unless length $expected == $BIG_BYTES;

  # through get
  {
    my $f = $storage->select_async('big');

    # ADR 0003, the documented ceiling: the child cannot finish on its own.
    Time::HiRes::sleep(0.2);
    is waitpid(-1, WNOHANG), 0,
      'before anybody reads, the child of a 200 KiB result is still alive (blocked in its write)';

    my @rows = eval { $f->get };
    is $@, '', 'get: does not fail';
    is scalar @rows, 1, 'get: one row';
    is length($rows[0][1] // ''), $BIG_BYTES, 'get: all 200 KiB of it';
    ok @rows && $rows[0][1] eq $expected, 'get: byte for byte what the child computed';
    no_children_ok('get reaped the child');
  }

  # through is_ready alone, never blocking
  {
    my $f = $storage->select_async('big');
    my $polls = 0;
    until ($f->is_ready) {
      last if ++$polls > 1000;
      Time::HiRes::sleep(0.005);
    }
    ok $f->is_ready, "is_ready: true after draining the pipe without blocking ($polls polls)";
    ok !$f->is_failed, 'is_ready: the drained blob thawed';
    my @rows = eval { $f->get };
    ok @rows == 1 && $rows[0][1] eq $expected,
      'is_ready: the row it collected is complete, byte for byte';
    no_children_ok('is_ready reaped the child at EOF');
  }

  # The same, with the writer in our hands, so that every step is certain: a
  # valid blob arriving in four pieces is ready only after the last one, and
  # what was read on the earlier calls is kept. (With a real child the second
  # is_ready usually finds the whole blob: it reads as fast as the child
  # refills the pipe.)
  {
    my $blob  = Storable::freeze({ rows => [ [ 1, $expected ] ] });
    my $size  = int(length($blob) / 4) + 1;
    my @piece = unpack "(a$size)*", $blob;
    die 'fixture: four pieces, each fitting an empty pipe buffer'
      unless @piece == 4 && $size < 4096 * 15;

    pipe(my $rh, my $wh) or die "pipe: $!";
    my $f = DBIO::Forked::Future->new(read_fh => $rh);

    ok !$f->is_ready, 'fed by hand: not ready before anything was written';
    for my $n (0 .. 3) {
      my $written = syswrite($wh, $piece[$n]);
      die "short write: $!" unless defined $written && $written == length $piece[$n];
      ok !$f->is_ready, 'fed by hand: not ready after piece ' . ($n + 1) . ' of 4, the write end still open';
    }
    close $wh;
    ok $f->is_ready, 'fed by hand: ready at EOF';
    ok !$f->is_failed, 'fed by hand: the blob thawed';
    my @rows = eval { $f->get };
    ok @rows == 1 && $rows[0][1] eq $expected,
      'fed by hand: the four pieces were put together in order';
  }
}

# ---------------------------------------------------------------------------
# 6. *_async inside a txn_do_async body.
#
# The POD says the body must be sync-only, because a *_async call "would fork
# again from within the child". Nothing enforces it. This is what happens --
# recorded, not endorsed: over a real driver the nested query runs on a
# connection of its own, outside the transaction (t/09-broker-in-child.t,
# section 4).
# ---------------------------------------------------------------------------
{
  my $got = eval {
    $storage->txn_do_async(sub {
      my ($row) = $storage->select_async('whoami')->get;
      return { nested_pid => $row->[0] };
    })->get;
  };
  is $@, '', 'a *_async call in the body is not refused';

  my $child  = $got->{pid};
  my $nested = $got->{body}[0]{nested_pid};

  in_child_ok($child,  'the body ran in a child');
  in_child_ok($nested, 'the nested query ran in a child, too');
  isnt $nested, $child, '... a third process, not the one the body runs in';
  no_children_ok('... and this process is left with nothing to reap');

  # Forgetting the ->get hands the pending Future to Storable.
  my $f = $storage->txn_do_async(sub { return $storage->select_async('rows') });
  eval { $f->get };
  like $@, qr/txn_do_async body must return Storable-serializable data/,
    'a body returning the pending Future of a nested *_async fails as any other unserializable return value';
}

# ---------------------------------------------------------------------------
# 7. pipeline, listen, deploy_async -- the async API of the base class that
#    needs a pool or a query seam. Reached the way a caller reaches it:
#    $schema->storage->async.
# ---------------------------------------------------------------------------
{
  {
    package T::Paths::Storage;
    use base 'DBIO::Storage::DBI';
    DBIO::Storage::DBI->register_driver(ForkedPaths => __PACKAGE__);

    package T::Paths::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->storage_type('+T::Paths::Storage');
  }

  my $real  = T::Paths::Schema->connect('dbi:ForkedPaths:dbname=app', 'u', 'p', { async => 'forked' });
  my $async = $real->storage->async;

  # pipeline: a failed Future.
  SKIP: {
    skip 'the installed DBIO core predates the pipeline refusal (core k218)', 5
      unless DBIO::Storage::Async->can('_pipeline_refusal');

    my $f = eval { $async->pipeline(sub { 1 }) };
    is $@, '', 'pipeline: does not throw (and never asks for the pool there is not)';
    isa_ok $f, 'DBIO::Forked::Future', 'pipeline: answers';
    ok $f && $f->is_failed, '... a failed one';
    eval { $f->get };
    like $@, qr/DBIO::Forked::Storage does not support pipeline\(\)/,
      '... whose get throws, naming this backend and the method';
    like $@, qr/Issue the statements individually/, '... and what to do instead';
  }

  # listen: thrown at the call.
  SKIP: {
    skip 'the installed DBIO core predates the capability gate on listen and notify (core ADR 0056)', 2
      unless DBIO::Storage::Async->can('_listen_refusal');

    eval { $async->listen(jobs => sub { 1 }) };
    like $@, qr/LISTEN\/NOTIFY not supported by this storage driver/,
      'listen: throws, saying LISTEN/NOTIFY is not supported';
    eval { $async->notify(jobs => 'payload') };
    like $@, qr/LISTEN\/NOTIFY not supported by this storage driver/,
      'notify: the same refusal';
  }

  # deploy_async: refused, at the call, before anything runs -- by a refusal
  # of this backend's own (karr k16), as pool() has one, not by the base
  # class's note to transport authors.
  eval { $async->deploy_async($real) };
  my $refusal = $@;
  like $refusal, qr/deploy_async/, 'deploy_async: throws at the call, naming the method';
  unlike $refusal, qr/no connection pool/, '... before it ever asks for a pool';
  like $refusal, qr/DBIO::Forked/, 'deploy_async: the refusal names this backend';
  unlike $refusal, qr/Subclass must override/,
    '... and is not the base class instruction to transport authors';
  like $refusal, qr/\$schema->deploy/, '... and says what to call instead';

  # The inherited sync deploy runs through deploy_async->get: same refusal.
  eval { $async->deploy($real) };
  like $@, qr/DBIO::Forked/, 'deploy: the inherited sync deploy gives the same refusal';
  unlike $@, qr/Subclass must override/, '... not the base class instruction';
}

# ---------------------------------------------------------------------------
# No zombies left behind.
# ---------------------------------------------------------------------------
no_children_ok('no unreaped child processes left');

done_testing;
