use strict;
use warnings;
use Test::More;
use Config;
use File::Temp ();

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# karr k233. DBIO::Storage::PoolBase checked the process id only when it tore
# its connections down (_teardown_belongs_here, karr k210) and never when it
# handed one out. A forked child that queried through an inherited pool was
# given the parent's own connections -- the idle one straight away -- and so
# shared the parent's sessions over the same sockets, where each process can
# read the other's replies.
#
# The claim this file pins is the one the sync storage makes with _verify_pid:
# a pool used in a process that did not open its connections drops what it
# inherited and starts over. Concretely, in a child:
#
#   * acquire and acquire_txn hand out connections the child opened itself --
#     never one of the parent's, idle or checked out;
#   * the inherited connections are dropped, not closed: the child never runs
#     _shutdown_connection on them, not while adopting the pool and not in its
#     own shutdown, which closes the child's connections only;
#   * a parent connection released in the child is not taken in, so it cannot
#     be handed out there later;
#   * a waiter the parent had queued is the parent's caller: the child neither
#     resolves it nor runs its callback -- also when the child's first use of
#     the pool is a release, which checks the process id just as acquire does;
#   * nor does the child fail that waiter when its only use of the pool ends
#     it -- a shutdown, or the DESTROY that runs one (karr k234);
#
# and in the parent, afterwards, nothing has changed: the next acquire hands
# out its idle connection exactly as it would have without the fork.
#
# The children never touch the TAP stream (STDOUT goes to /dev/null, no Test::
# function runs there). A child reports what it saw over a pipe, one
# "key=value" per line, and every close is appended to a shared log as
# "pid:id", so a close the child ran -- also during its global destruction --
# is visible to the parent.

{
  package K233::Conn;
  sub new { bless { id => $_[1], opener => $$ }, $_[0] }
}

{
  package K233::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K233::Conn->new(++$_[0]->{_next_id}) }

  sub _shutdown_connection {
    my ($self, $conn) = @_;
    open my $fh, '>>', $self->{close_log} or die "open $self->{close_log}: $!";
    print {$fh} "$$:$conn->{id}\n";
    close $fh;
  }
}

sub new_pool {
  my ($size) = @_;
  my (undef, $log) = File::Temp::tempfile(UNLINK => 1);
  my $pool = K233::Pool->new(
    conninfo     => 'fake',
    size         => $size,
    future_class => 'DBIO::Test::Future',
  );
  $pool->{close_log} = $log;
  return $pool;
}

# Every close in the log, as [ pid, id ] pairs.
sub closes {
  my ($pool) = @_;
  open my $fh, '<', $pool->{close_log} or die "open $pool->{close_log}: $!";
  my @closes = map { chomp; [ split /:/ ] } <$fh>;
  close $fh;
  return @closes;
}

sub append_line {
  my ($file, $line) = @_;
  open my $fh, '>>', $file or die "open $file: $!";
  print {$fh} "$line\n";
  close $fh;
}

sub read_lines {
  my ($file) = @_;
  open my $fh, '<', $file or die "open $file: $!";
  my @lines = map { chomp; $_ } <$fh>;
  close $fh;
  return @lines;
}

# Run $body in a child with a report sub, and return the child's pid, its exit
# status and its report as a hash. A die in the child is reported as
# error=<message>.
sub in_child {
  my ($body) = @_;
  pipe my $r, my $w or die "pipe: $!";
  my $pid = fork;
  defined $pid or die "fork failed: $!";
  unless ($pid) {
    close $r;
    open STDOUT, '>', '/dev/null';
    my $report = sub {
      my ($key, $value) = @_;
      $value = '' unless defined $value;
      $value =~ s/\n/ /g;
      print {$w} "$key=$value\n";
    };
    $report->(error => $@) unless eval { $body->($report); 1 };
    close $w;
    exit 0;
  }
  close $w;
  my %seen = map { chomp; split /=/, $_, 2 } <$r>;
  close $r;
  waitpid $pid, 0;
  return ($pid, $?, \%seen);
}

SKIP: {
  skip 'fork not available on this platform', 1 unless $Config{d_fork};

  # -------------------------------------------------------------------------
  # The parent holds one idle connection (1) and one checked out (2) when it
  # forks. Asserts, in the child: acquire and acquire_txn both resolve at once,
  # each on a connection the child opened -- neither 1 (the parent's idle one,
  # which acquire used to take) nor 2; releasing the inherited 2 there does not
  # idle it and the pool counts only the child's two; the child's own
  # connection is reused after it is released. In the log: the child closed
  # exactly its own connections, in its shutdown, and never 1 or 2. In the
  # parent: the pool is as the fork left it, and the next acquire hands out
  # connection 1 again.
  # -------------------------------------------------------------------------
  {
    my $pool = new_pool(2);
    my $idle = $pool->acquire->get;
    my $held = $pool->acquire->get;
    $pool->release($idle);
    is_deeply [ map { $_->{id} } $idle, $held ], [ 1, 2 ],
      'parent: connection 1 idle, connection 2 checked out at fork time';

    my ($pid, $status, $seen) = in_child(sub {
      my ($report) = @_;
      my $f = $pool->acquire;
      $report->(acquire_ready => $f->is_ready ? 1 : 0);
      my $conn = $f->is_ready ? $f->get : undef;
      $report->(acquire_id     => $conn && $conn->{id});
      $report->(acquire_opener => $conn && $conn->{opener});

      my $t = $pool->acquire_txn;
      $report->(txn_ready => $t->is_ready ? 1 : 0);
      my $txn = $t->is_ready ? $t->get : undef;
      $report->(txn_id     => $txn && $txn->{id});
      $report->(txn_opener => $txn && $txn->{opener});

      $pool->release($held);
      $report->(available_after_inherited_release => $pool->available);
      $report->(size => $pool->size);

      $pool->release($conn) if $conn;
      my $again = $pool->acquire;
      $report->(reacquire_id => $again->is_ready ? $again->get->{id} : 'pending');

      $report->(closes_before_shutdown => scalar(() = closes($pool)));
      $pool->shutdown;
    });

    is $status, 0, 'child: exits cleanly';
    is $seen->{error}, undef, 'child: nothing died';

    is $seen->{acquire_ready}, 1, 'child: acquire resolves at once';
    ok !grep({ $_ == ($seen->{acquire_id} || 0) } 1, 2),
      "child: acquire hands out a fresh connection, not the parent's (got $seen->{acquire_id})";
    is $seen->{acquire_opener}, $pid, 'child: ... one the child opened itself';

    is $seen->{txn_ready}, 1, 'child: acquire_txn resolves at once';
    ok !grep({ $_ == ($seen->{txn_id} || 0) } 1, 2),
      "child: acquire_txn hands out a fresh connection, not the parent's (got $seen->{txn_id})";
    is $seen->{txn_opener}, $pid, 'child: ... one the child opened itself';

    is $seen->{available_after_inherited_release}, 0,
      "child: releasing the parent's checked-out connection does not idle it";
    is $seen->{size}, 2, "child: the pool counts the child's two connections only";
    is $seen->{reacquire_id}, $seen->{acquire_id},
      "child: the child's own released connection is handed out again";

    is $seen->{closes_before_shutdown}, 0,
      "child: adopting the pool closed none of the parent's connections";
    my @child_closes = sort { $a <=> $b } map { $_->[1] } grep { $_->[0] == $pid } closes($pool);
    is_deeply \@child_closes,
      [ sort { $a <=> $b } grep { length } $seen->{acquire_id}, $seen->{txn_id} ],
      "child: its shutdown closed exactly the connections it opened, never 1 or 2";

    is_deeply [ closes($pool) ], [ map { [ $pid, $_ ] } @child_closes ],
      'parent: no close ran in the parent either';
    is $pool->size, 2, 'parent: the pool still counts both of its connections';
    is $pool->available, 1, 'parent: connection 1 is still idle';
    my $next = $pool->acquire;
    ok $next->is_ready, 'parent: the next acquire resolves';
    is $next->is_ready && $next->get->{id}, 1,
      'parent: ... on its idle connection 1, as without the fork';
    $pool->release($held);
    $pool->release($next->get) if $next->is_ready;
    is $pool->available, 2, 'parent: both connections go back to its idle list';
  }

  # -------------------------------------------------------------------------
  # The parent's pool is full and a caller is queued when it forks. Asserts,
  # in the child: the child's acquire does not queue behind the parent's
  # caller but resolves on a connection of its own, and releasing that
  # connection idles it -- it does not go to the parent's queued caller, whose
  # callback never runs in the child. In the parent, the queued caller still
  # resolves on the parent's next release.
  # -------------------------------------------------------------------------
  {
    my $pool = new_pool(1);
    my $held = $pool->acquire->get;
    my $ran_in;
    my $waiter = $pool->acquire;
    $waiter->then(sub { $ran_in = $$; DBIO::Test::Future->done });
    ok !$waiter->is_ready, 'parent: a caller is queued at fork time';

    my ($pid, $status, $seen) = in_child(sub {
      my ($report) = @_;
      my $f = $pool->acquire;
      $report->(acquire_ready => $f->is_ready ? 1 : 0);
      my $conn = $f->is_ready ? $f->get : undef;
      $report->(acquire_opener => $conn && $conn->{opener});
      $pool->release($conn) if $conn;
      $report->(available => $pool->available);
      $report->(waiter_ready => $waiter->is_ready ? 1 : 0);
      $report->(callback_ran_in => $ran_in);
    });

    is $status, 0, 'queued caller, child: exits cleanly';
    is $seen->{error}, undef, 'queued caller, child: nothing died';
    is $seen->{acquire_ready}, 1,
      "queued caller, child: acquire resolves instead of queueing behind the parent's caller";
    is $seen->{acquire_opener}, $pid,
      'queued caller, child: ... on a connection the child opened';
    is $seen->{available}, 1,
      'queued caller, child: releasing it idles it';
    is $seen->{waiter_ready}, 0,
      "queued caller, child: the parent's queued caller is not resolved in the child";
    is $seen->{callback_ran_in}, '',
      "queued caller, child: its callback never ran in the child";

    $pool->release($held);
    ok $waiter->is_ready, 'queued caller, parent: resolves on the next release';
    is $ran_in, $$, 'queued caller, parent: its callback ran in the parent';
  }

  # -------------------------------------------------------------------------
  # The same fork, but the child's first use of the pool is a release: it hands
  # back the connection the parent had checked out, while the parent's caller
  # is queued for it. release makes the same check acquire does. Asserts, in
  # the child: the parent's queued caller is not resolved with the parent's
  # connection and its callback never runs; the connection is not idled and
  # the pool counts nothing; the child's next acquire resolves on a connection
  # of its own. In the parent, the queued caller still resolves on the
  # parent's next release.
  # -------------------------------------------------------------------------
  {
    my $pool = new_pool(1);
    my $held = $pool->acquire->get;
    my $ran_in;
    my $waiter = $pool->acquire;
    $waiter->then(sub { $ran_in = $$; DBIO::Test::Future->done });
    ok !$waiter->is_ready, 'release first: a caller is queued at fork time';

    my ($pid, $status, $seen) = in_child(sub {
      my ($report) = @_;
      $pool->release($held);
      $report->(waiter_ready    => $waiter->is_ready ? 1 : 0);
      $report->(callback_ran_in => $ran_in);
      $report->(available       => $pool->available);
      $report->(size            => $pool->size);
      my $f = $pool->acquire;
      $report->(acquire_opener => $f->is_ready ? $f->get->{opener} : 'pending');
    });

    is $status, 0, 'release first, child: exits cleanly';
    is $seen->{error}, undef, 'release first, child: nothing died';
    is $seen->{waiter_ready}, 0,
      "release first, child: the parent's queued caller is not handed the parent's connection";
    is $seen->{callback_ran_in}, '',
      'release first, child: its callback never ran in the child';
    is $seen->{available}, 0, "release first, child: the parent's connection is not idled";
    is $seen->{size}, 0, 'release first, child: the pool counts nothing it inherited';
    is $seen->{acquire_opener}, $pid,
      'release first, child: the next acquire resolves on a connection the child opened';

    $pool->release($held);
    ok $waiter->is_ready, 'release first, parent: the queued caller resolves on the next release';
    is $ran_in, $$, 'release first, parent: its callback ran in the parent';
  }

  # -------------------------------------------------------------------------
  # karr k234. The same fork once more, but the child's only use of the pool
  # ends it: an explicit shutdown, or plain exit, whose global destruction runs
  # the pool's DESTROY and with it shutdown. shutdown made no process-id check,
  # so it failed the parent's queued caller in the child: after an explicit
  # shutdown its failure callback ran there, and at exit the attempt either ran
  # it too or died in cleanup, depending on the order global destruction
  # reclaims things in. The pool is not reclaimed any earlier than that: while
  # the caller is queued, its pending Future holds the pool through acquire's
  # continuation.
  #
  # The callbacks log "done:<pid>" / "failed:<pid>" to a file, and the child's
  # STDERR goes to one, so what happens during its global destruction is still
  # visible. Asserts, in the child: none of the queued caller's callbacks runs,
  # nothing is warned or died on the way out, no connection is closed; after
  # the explicit shutdown the caller is still pending and the pool is shut down
  # for the child all the same -- acquire fails with the shutdown diagnostic.
  # In the parent, afterwards: the queued caller resolves on the next release
  # and its callback runs there; the parent acquires again, and its own
  # shutdown closes its one connection exactly once.
  # -------------------------------------------------------------------------
  for my $how ('shutdown', 'exit') {
    my $pool = new_pool(1);
    my $held = $pool->acquire->get;
    my (undef, $callback_log) = File::Temp::tempfile(UNLINK => 1);
    my (undef, $child_stderr) = File::Temp::tempfile(UNLINK => 1);
    my $waiter = $pool->acquire;
    $waiter->then(
      sub { append_line($callback_log, "done:$$");   DBIO::Test::Future->done },
      sub { append_line($callback_log, "failed:$$"); DBIO::Test::Future->done },
    );
    ok !$waiter->is_ready, "$how in child: a caller is queued at fork time";

    my ($pid, $status, $seen) = in_child(sub {
      my ($report) = @_;
      open STDERR, '>', $child_stderr or die "open $child_stderr: $!";
      return unless $how eq 'shutdown';   # exit: in_child's exit does the rest
      $pool->shutdown;
      $report->(waiter_ready => $waiter->is_ready ? 1 : 0);
      my $failure = 'not failed';
      $pool->acquire->catch(sub { $failure = $_[0]; DBIO::Test::Future->done });
      $report->(acquire_failure => $failure);
    });

    is $status, 0, "$how in child: exits cleanly";
    is $seen->{error}, undef, "$how in child: nothing died";
    is_deeply [ grep { /:$pid\z/ } read_lines($callback_log) ], [],
      "$how in child: none of the parent's queued callbacks ran in the child";
    is join('', read_lines($child_stderr)), '',
      "$how in child: nothing was warned or died in the child, global destruction included";
    is_deeply [ closes($pool) ], [], "$how in child: no connection was closed";
    if ($how eq 'shutdown') {
      is $seen->{waiter_ready}, 0,
        "$how in child: the parent's queued caller is neither resolved nor failed there";
      like $seen->{acquire_failure}, qr/Connection pool has been shut down/,
        "$how in child: the pool is shut down for the child all the same";
    }

    ok !$waiter->is_ready, "$how in child, parent: its caller is still queued";
    $pool->release($held);
    ok $waiter->is_ready && !$waiter->is_failed,
      "$how in child, parent: the queued caller resolves on the next release";
    is_deeply [ read_lines($callback_log) ], [ "done:$$" ],
      "$how in child, parent: its callback ran in the parent";

    $pool->release($waiter->get);
    my $again = $pool->acquire;
    is $again->is_ready && $again->get->{id}, 1,
      "$how in child, parent: the next acquire hands out its connection 1";
    $pool->release($again->get) if $again->is_ready;
    $pool->shutdown;
    is_deeply [ closes($pool) ], [ [ $$, 1 ] ],
      "$how in child, parent: its shutdown closes connection 1 exactly once";
  }
}

done_testing;
