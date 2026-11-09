# ABSTRACT: The pool's edge paths ask the broker for every connection they open, and survive its refusals
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Config;
use POSIX ();

use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;
use DBIO::Test::Future ();

# OFFLINE (karr k270). An async backend with an AccessBroker hands its pool a
# provider, and the pool calls it for every connection it opens: the broker is
# asked then and there, so rotated credentials reach the next connection. The
# broker tests so far opened those connections through a plain acquire on a
# pool with room (10, 12). The pool opens connections on other paths too -- in
# place of a connection that died, for a caller queued behind one, in a forked
# child -- and has paths that must open none: a caller that gave up, a pool
# shut down. None of them had been run with a broker behind the pool, and the
# broker's answer is the one step of a spawn that can fail on its own.
#
# What this file claims, with a real DBIO::Storage::Async backend, core's own
# connect_info and provider, and a real DBIO::Storage::PoolBase:
#   1. a connection reported dead is replaced, for the caller queued behind it,
#      by one opened with the broker's answer of that moment -- through release
#      and through _retire_in_use_connection; a queued caller asks the broker
#      nothing while it waits; a connection that died idle is replaced the same
#      way at the next acquire;
#   2. when the broker refuses that answer -- answers nothing, or throws -- the
#      queued caller fails with the broker's error, naming no credential; no
#      connection is opened, no slot is taken, and the next acquire asks again
#      and connects;
#   3. with two callers queued, a refusal for the first hands the slot to the
#      second, which gets a connection from the answer after (karr k260); when
#      every answer is refused each caller fails with its own, none waits;
#   4. a connection that does not come up is replaced for the queued caller by
#      one opened with the next answer -- the credentials it failed with are
#      not tried again;
#   5. a broker that fails more often than the pool has slots takes none of
#      them: once it answers, the pool opens connections up to its size;
#   6. a queued caller that cancelled is asked for nothing: no connection is
#      opened for it and the broker is not asked (Future.pm only);
#   7. a pool shut down asks the broker nothing and opens nothing; the pool the
#      storage builds after a disconnect opens its first connection with the
#      broker's answer of then;
#   8. a forked child that uses the inherited pool opens a connection of its
#      own with the next answer of its broker, and closes none of the parent's;
#   9. a broker that comes back into the pool while it answers -- a client that
#      runs the event loop while it fetches -- finds the slot of the spawn it
#      answers for taken (karr k277): an acquire made from inside is queued
#      behind that spawn, asks the broker nothing, and gets the connection once
#      it is released; a pool shut down from inside opens no connection after
#      it, and the acquire the broker answered for fails with the shutdown.
#
# THE SUBSTITUTIONS: a pool whose connections are plain objects, recording the
# connect info each was opened with and each one it closes; a transport
# building each connection's connect info the way dbio-async and dbio-mysql-ev
# do (_normalize_async_connect_info over _current_async_connect_info); brokers
# answering from a script. No database, no event loop.

# A broker answering from a script: one code per call, the last one repeating.
{
  package T::ScriptBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answers) = @_; bless { answers => \@answers, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    my $i = $self->{calls}++;
    $i = $#{ $self->{answers} } if $i > $#{ $self->{answers} };
    return $self->{answers}[$i]->();
  }
  sub calls { $_[0]{calls} }
}

{
  package T::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    push @{ $self->{built} }, $conninfo;
    return bless { id => ++$self->{n}, conninfo => $conninfo, opener => $$ }, 'T::Conn';
  }
  sub _shutdown_connection  { push @{ $_[0]{closed} }, $_[1]{id} }
  sub _idle_connection_alive { !$_[1]{died_idle} }

  # {cold}: a connection is not usable until its {ready} is settled by the test
  sub _connection_ready_future {
    my ($self, $conn) = @_;
    return $self->future_class->done($conn) unless $self->{cold};
    return $conn->{ready} ||= $self->future_class->new;
  }
}

{
  package T::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class { $_[0]{t_future_class} || 'DBIO::Test::Future' }
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    return $conninfo;
  }
  sub pool {
    my $self = shift;
    $self->{pool} ||= T::Pool->new(
      size              => $self->{t_size} || 1,
      future_class      => $self->future_class,
      conninfo_provider => $self->_conninfo_provider,
      on_error          => sub { push @{ $self->{t_errors} }, "@_" },
    );
  }
}

# every value of a broker answer in this file
my $SECRET = qr/k270-(?:user|pw)/;

sub answer { my $n = shift; { dbname => 'app', user => "k270-user-$n", password => "k270-pw-$n" } }
sub good   { my $n = shift; sub { answer($n) } }
sub nothing { sub { {} } }
sub throws  { my $n = shift; sub { die "k270 vault unreachable ($n)\n" } }

# Answers 1, 2, 3, ... for ever.
sub numbered { my $n = 0; sub { answer(++$n) } }

# A backend over a broker answering @answers; answer 1 goes to connect_info.
sub backend {
  my (%args) = @_;
  my $broker  = T::ScriptBroker->new(@{ $args{answers} });
  my $storage = T::Backend->new(undef);
  $storage->{t_size}         = $args{size} || 1;
  $storage->{t_future_class} = $args{future_class};
  $storage->connect_info([ $broker ]);
  $storage->pool->{cold} = 1 if $args{cold};
  return ($storage, $broker, $storage->pool);
}

sub failure_of {
  my ($f) = @_;
  return '' unless $f->is_ready && $f->is_failed;
  return $f->can('failure') ? '' . $f->failure : "$f->{values}[0]";
}

# The user a Future's connection was opened as; '' while pending, or failed.
sub user_of {
  my ($f) = @_;
  return '' unless $f->is_ready && !$f->is_failed;
  return $f->get->{conninfo}{user};
}

sub built_users { [ map { $_->{user} } @{ $_[0]{built} || [] } ] }

my $NO_ANSWER = qr/AccessBroker T::ScriptBroker answered no connect info \(an empty hashref\)/;

# ---------------------------------------------------------------------------
# 1. A connection that died is replaced with one from the answer of the moment.
# ---------------------------------------------------------------------------
{
  my ($storage, $broker, $pool) = backend(answers => [ numbered() ]);

  my $conn = $pool->acquire->get;
  is $conn->{conninfo}{user}, 'k270-user-2', "the pool's first connection is opened with the answer of that moment";

  my $waiter = $pool->acquire;
  ok !$waiter->is_ready, 'a second caller is queued behind it';
  is $broker->calls, 2, '... and asks the broker nothing while it waits';

  $pool->_mark_connection_dead($conn);
  is $broker->calls, 2, 'the connection reported dead: nothing is asked yet, its holder still has it';

  $pool->release($conn);
  is_deeply $pool->{closed}, [ $conn->{id} ], 'released, the dead connection is closed';
  is user_of($waiter), 'k270-user-3',
    "... and the queued caller gets a connection opened with the broker's next answer";
  isnt $waiter->get, $conn, '... not the dead one';
  is $broker->calls, 3, '... the broker asked once for it';
  is $pool->size, 1, '... and the pool counts that connection only';
}

{
  my ($storage, $broker, $pool) = backend(answers => [ numbered() ]);
  my $conn   = $pool->acquire->get;
  my $waiter = $pool->acquire;

  $pool->_retire_in_use_connection($conn);
  is user_of($waiter), 'k270-user-3',
    'a checked-out connection retired: the queued caller gets one opened with the next answer';
  is_deeply built_users($pool), [ 'k270-user-2', 'k270-user-3' ], '... one connection per answer';
}

{
  my ($storage, $broker, $pool) = backend(answers => [ numbered() ]);
  my $conn = $pool->acquire->get;
  $pool->release($conn);
  $conn->{died_idle} = 1;

  my $next = $pool->acquire;
  is user_of($next), 'k270-user-3', 'a connection that died idle: the next acquire opens one with the next answer';
  is_deeply $pool->{closed}, [ $conn->{id} ], '... and closes the dead one';
  is $broker->calls, 3, '... the broker asked once for it';
}

# ---------------------------------------------------------------------------
# 2. The broker refuses the answer for the replacement.
# ---------------------------------------------------------------------------
for my $case (
  [ 'a broker answering nothing', nothing(), $NO_ANSWER ],
  [ 'a broker that throws',       throws(3), qr/^k270 vault unreachable \(3\)/ ],
) {
  my ($label, $refusal, $error) = @$case;
  my ($storage, $broker, $pool) = backend(answers => [ good(1), good(2), $refusal, good(4) ]);
  my $conn   = $pool->acquire->get;
  my $waiter = $pool->acquire;

  $pool->_mark_connection_dead($conn);
  lives_ok { $pool->release($conn) } "$label for the replacement: the release does not die";

  ok $waiter->is_ready && $waiter->is_failed, "$label: the queued caller fails instead of waiting";
  like failure_of($waiter), $error, "$label: ... with the broker's error";
  unlike failure_of($waiter), $SECRET, "$label: ... naming no credential of an earlier answer";
  is_deeply built_users($pool), [ 'k270-user-2' ], "$label: ... no connection is opened in its place";
  is $pool->size, 0, "$label: ... and the refused spawn takes no slot";

  my $next = $pool->acquire;
  is user_of($next), 'k270-user-4', "$label: the next acquire asks again and connects with that answer";
  is $pool->size, 1, "$label: ... into the slot that was free";
}

# ---------------------------------------------------------------------------
# 3. Two callers queued behind the dead connection.
# ---------------------------------------------------------------------------
{
  my ($storage, $broker, $pool) = backend(answers => [ good(1), good(2), throws(3), good(4) ]);
  my $conn = $pool->acquire->get;
  my ($first, $second) = map { $pool->acquire } 1 .. 2;

  $pool->_mark_connection_dead($conn);
  $pool->release($conn);

  like failure_of($first), qr/^k270 vault unreachable \(3\)/,
    'two callers queued, the first replacement refused: the first fails with that error';
  is user_of($second), 'k270-user-4', '... and the second gets a connection from the answer after';
  is $broker->calls, 4, '... the broker asked once per attempt';
  is scalar @{ $pool->{_waiters} }, 0, '... nobody is left queued';
  is $pool->size, 1, '... and the pool counts the one connection';
}

{
  my ($storage, $broker, $pool) = backend(answers => [ good(1), good(2), throws(3), throws(4), good(5) ]);
  my $conn = $pool->acquire->get;
  my ($first, $second) = map { $pool->acquire } 1 .. 2;

  $pool->_mark_connection_dead($conn);
  $pool->release($conn);

  like failure_of($first), qr/^k270 vault unreachable \(3\)/, 'every replacement refused: the first caller fails with its error';
  like failure_of($second), qr/^k270 vault unreachable \(4\)/, '... the second with its own, instead of waiting';
  is $pool->size, 0, '... and no slot is taken';
  is user_of($pool->acquire), 'k270-user-5', '... so the acquire after that connects';
}

# ---------------------------------------------------------------------------
# 4. A connection that does not come up.
# ---------------------------------------------------------------------------
{
  my ($storage, $broker, $pool) = backend(answers => [ numbered() ], cold => 1);

  my $first = $pool->acquire;
  ok !$first->is_ready, 'a connection still coming up: its caller waits';
  my $cold = $pool->{_connections}[0];
  is $cold->{conninfo}{user}, 'k270-user-2', '... it was opened with the answer of that moment';

  my $second = $pool->acquire;
  ok !$second->is_ready, 'a second caller is queued behind it';

  $cold->{ready}->fail("k270 authentication failed\n");
  like failure_of($first), qr/^k270 authentication failed/, 'it does not come up: its caller gets that error';
  is_deeply $pool->{closed}, [ $cold->{id} ], '... the connection is closed';

  my $replacement = $pool->{_connections}[0];
  is $replacement && $replacement->{conninfo}{user}, 'k270-user-3',
    '... and one is opened for the queued caller with the next answer, not the credentials that just failed';
  ok !$second->is_ready, '... which waits for that one to come up';

  $replacement->{ready}->done($replacement) if $replacement;
  is user_of($second), 'k270-user-3', 'it comes up: the queued caller gets it';
  is $broker->calls, 3, 'the broker was asked once per connection';
  is_deeply $storage->{t_errors} || [], [], '... and nothing went to on_error';
}

# ---------------------------------------------------------------------------
# 5. More refusals than the pool has slots.
# ---------------------------------------------------------------------------
{
  my ($storage, $broker, $pool) = backend(
    size    => 2,
    answers => [ good(1), (map { throws($_) } 2 .. 6), numbered() ],
  );

  my @failed = map { $pool->acquire } 1 .. 5;
  is_deeply [ map { failure_of($_) } @failed ], [ map { "k270 vault unreachable ($_)\n" } 2 .. 6 ],
    'five acquires on a pool of two while the broker throws: each fails with its error';
  is $pool->size, 0, '... and none of them takes a slot';
  is_deeply built_users($pool), [], '... no connection was opened';

  # numbered() starts at 1 here: the broker's answers 7 and 8
  my @good = map { $pool->acquire } 1 .. 2;
  is_deeply [ map { user_of($_) } @good ], [ 'k270-user-1', 'k270-user-2' ],
    'the broker answering again: the pool opens connections up to its size';
  is $pool->size, 2, '... both counted';

  my $third = $pool->acquire;
  ok !$third->is_ready, '... and a third caller queues: the pool is full of connections that exist';
  my ($released) = map { $_->get } grep { $_->is_ready && !$_->is_failed } @good;
  $pool->release($released) if $released;
  is $third->is_ready && !$third->is_failed && $third->get, $released,
    '... and gets the connection released to it';
  is $broker->calls, 8, 'the broker was asked once per attempt and never for the queued caller';
}

# ---------------------------------------------------------------------------
# 6. A queued caller that cancelled (Future.pm; DBIO::Test::Future has no cancel).
# ---------------------------------------------------------------------------
SKIP: {
  skip 'Future.pm is not installed', 10 unless eval { require Future; 1 };

  {
    my ($storage, $broker, $pool) = backend(answers => [ numbered() ], future_class => 'Future');
    my $conn   = $pool->acquire->get;
    my $waiter = $pool->acquire;
    $waiter->cancel;

    $pool->release($conn);
    is $pool->available, 1, 'a queued caller cancelled, the connection released: it goes back to idle';
    is $broker->calls, 2, '... and the broker is not asked';
    is_deeply built_users($pool), [ 'k270-user-2' ], '... no connection is opened for the caller that gave up';

    my $next = $pool->acquire;
    is $next->is_ready && $next->get, $conn, 'the next acquire gets the idle connection';
    is $broker->calls, 2, '... without asking the broker';
  }

  {
    my ($storage, $broker, $pool) = backend(answers => [ numbered() ], future_class => 'Future');
    my $conn   = $pool->acquire->get;
    my $waiter = $pool->acquire;
    $waiter->cancel;

    $pool->_mark_connection_dead($conn);
    $pool->release($conn);
    is_deeply $pool->{closed}, [ $conn->{id} ], 'a queued caller cancelled, the connection dead: it is closed';
    is $broker->calls, 2, '... and the broker is not asked: nobody waits for a replacement';
    is $pool->size, 0, '... none is opened';

    my $next = $pool->acquire;
    is user_of($next), 'k270-user-3', 'the next acquire opens one with the answer of then';
    is $broker->calls, 3, '... the broker asked once for it';
  }
}

# ---------------------------------------------------------------------------
# 7. A pool shut down, and the pool after it.
# ---------------------------------------------------------------------------
{
  my ($storage, $broker, $pool) = backend(answers => [ numbered() ]);
  my $conn   = $pool->acquire->get;
  my $waiter = $pool->acquire;

  $pool->shutdown;
  like failure_of($waiter), qr/Connection pool has been shut down/, 'the pool shut down: its queued caller fails with that';
  like failure_of($pool->acquire), qr/Connection pool has been shut down/, '... and so does a later acquire';
  $pool->_mark_connection_dead($conn);
  $pool->release($conn);
  is $broker->calls, 2, '... the broker is asked nothing';
  is_deeply built_users($pool), [ 'k270-user-2' ], '... and no connection is opened';
}

{
  my ($storage, $broker, $old) = backend(answers => [ numbered() ]);
  my $conn = $old->acquire->get;

  $storage->disconnect;
  is_deeply $old->{closed}, [ $conn->{id} ], "the storage disconnected: its pool's connection is closed";
  is $broker->calls, 2, '... and the broker is not asked';

  my $pool = $storage->pool;
  isnt $pool, $old, 'the storage builds a new pool';
  is user_of($pool->acquire), 'k270-user-3', "... whose first connection is opened with the broker's answer of then";
  is_deeply built_users($old), [ 'k270-user-2' ], '... while the old pool opened nothing more';
}

# ---------------------------------------------------------------------------
# 8. A forked child.
# ---------------------------------------------------------------------------
SKIP: {
  skip 'fork not available on this platform', 11 unless $Config{d_fork};

  my ($storage, $broker, $pool) = backend(answers => [ numbered() ], size => 2);
  my $idle = $pool->acquire->get;
  my $held = $pool->acquire->get;
  $pool->release($idle);

  # The child never touches the TAP stream. It reports over a pipe, one
  # key=value per line, and leaves through POSIX::_exit: no END block, no
  # destructor of the parent's objects runs there.
  pipe my $r, my $w or die "pipe: $!";
  my $pid = fork;
  defined $pid or die "fork failed: $!";
  unless ($pid) {
    close $r;
    my %seen;
    $seen{error} = "$@" unless eval {
      my $f = $pool->acquire;
      $seen{ready}  = $f->is_ready ? 1 : 0;
      $seen{user}   = user_of($f);
      $seen{id}     = $seen{ready} ? $f->get->{id} : '';
      $seen{opener} = $seen{ready} ? $f->get->{opener} : '';
      $seen{calls}  = $broker->calls;
      $seen{size}   = $pool->size;
      $pool->shutdown;
      $seen{closed} = join ',', @{ $pool->{closed} || [] };
      1;
    };
    for my $key (sort keys %seen) {
      (my $value = $seen{$key} // '') =~ s/\n/ /g;
      print {$w} "$key=$value\n";
    }
    close $w;
    POSIX::_exit(0);
  }
  close $w;
  my %seen = map { chomp; split /=/, $_, 2 } <$r>;
  close $r;
  waitpid $pid, 0;

  is $?, 0, 'child: exits cleanly';
  is $seen{error}, undef, 'child: nothing died';
  is $seen{ready}, 1, 'child: acquire on the inherited pool resolves at once';
  is $seen{user}, 'k270-user-4', "child: ... on a connection opened with its broker's next answer";
  is $seen{opener}, $pid, 'child: ... which the child opened itself';
  ok !grep({ $_ == ($seen{id} || 0) } $idle->{id}, $held->{id}), "child: ... not one of the parent's";
  is $seen{size}, 1, "child: its pool counts that connection only";
  is $seen{closed}, $seen{id}, "child: its shutdown closes that connection and none of the parent's";

  is $broker->calls, 3, "parent: its broker was not asked by any of that";
  is_deeply $pool->{closed} || [], [], 'parent: none of its connections is closed';
  is $pool->acquire->get, $idle, 'parent: its next acquire hands out its idle connection';
}

# ---------------------------------------------------------------------------
# 9. A broker that comes back into the pool while it answers.
# ---------------------------------------------------------------------------
{
  my ($storage, $inner);
  my $broker = T::ScriptBroker->new(
    good(1),
    sub { $inner = $storage->pool->acquire; answer(2) },   # the answer for the pool's first connection
    numbered(),
  );
  $storage = T::Backend->new(undef);
  $storage->{t_size} = 1;
  $storage->connect_info([ $broker ]);
  my $pool = $storage->pool;

  my $outer = $pool->acquire;

  is user_of($outer), 'k270-user-2', 'the acquire the broker answers for gets its connection';
  ok !$inner->is_ready, '... and an acquire made while the broker answers is queued behind it';
  cmp_ok $pool->size, '<=', $pool->max_size, 'the pool never counts more connections than its size';
  is_deeply built_users($pool), [ 'k270-user-2' ], '... having opened the one connection';
  is $broker->calls, 2, '... and the queued caller asks the broker nothing while it waits';

  $pool->release($outer->get);
  is user_of($inner), 'k270-user-2', 'the queued caller gets that connection once it is released';
  is $pool->size, 1, '... still the one connection in the pool of one';
}

{
  my $storage;
  my $broker = T::ScriptBroker->new(
    good(1), good(2),
    sub { $storage->disconnect; answer(3) },   # ends the pool while it answers for its second connection
    numbered(),
  );
  $storage = T::Backend->new(undef);
  $storage->{t_size} = 2;
  $storage->connect_info([ $broker ]);
  my $pool  = $storage->pool;
  my $first = $pool->acquire->get;

  my $f = $pool->acquire;

  ok $pool->{_shutdown}, 'a broker that disconnects the storage while it answers: the pool is shut down';
  is_deeply $pool->{closed}, [ $first->{id} ], '... and the connection it held is closed';
  like failure_of($f), qr/Connection pool has been shut down/,
    'an acquire on a pool shut down while the broker answered fails as on any shut-down pool';
  unlike failure_of($f), $SECRET, '... naming nothing of the answer';
  is_deeply built_users($pool), [ 'k270-user-2' ], '... no connection is opened after the shutdown';
  is scalar @{ $pool->{built} }, scalar @{ $pool->{closed} },
    '... and the pool leaves no connection open';
  is $pool->size, 0, '... nor counts one';
}

done_testing;
