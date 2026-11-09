use strict;
use warnings;
use Test::More;
use File::Temp ();
use IO::Select;
use IO::Socket::UNIX;
use POSIX ();
use Scalar::Util qw( weaken );
use Socket qw( SOCK_STREAM );
use Time::HiRes ();

# OFFLINE regression for karr k45: pooled connections in a forked child.
#
# WHY it matters: a forked child shares the socket of every pooled connection
# with the parent, and EV::Pg knows nothing of fork. Its finish and its
# destructor call libpq's PQfinish, which sends the server a Terminate message
# on that shared socket -- so a child that did nothing but exit ended every
# pooled session of the parent. And a child that resumed the EV loop read the
# parent's replies off the shared sockets, so the parent's statements never
# completed. Both measured against PostgreSQL 18.6 (t/35-pool-fork-live.t).
#
# The fix (DBIO::PostgreSQL::EV::Pool, "Fork safety"): every pooled handle
# remembers the process that opened it, and in any other process its finish
# and its destructor first point its file descriptor at /dev/null; one EV::fork
# watcher closes every inherited handle that way when a child resumes the loop;
# the storage's callbacks return at once outside the process that issued the
# statement.
#
# What this file claims:
#   1. A child that resumes the loop -- with one pooled connection idle, one
#      checked out for a query, one pinned by txn_do_async and one sending a
#      NOTIFY, every statement in flight and its reply already on the wire --
#      reads none of the replies: in the child no Future settles, no callback
#      runs and nothing is released into the pool; in the parent each
#      statement completes with its own result and the transaction commits. The guard that fired does not
#      keep the child's loop running.
#   2. In the parent -- the owner -- the guard does nothing, also when EV runs
#      its fork watchers there.
#   3. A child that just exits sends the server nothing on any of the parent's
#      connections -- no Terminate -- and the parent's pool serves on.
#   4. So does a child that finishes the inherited connections explicitly, or
#      drops one (and it really was destroyed in the child).
#   5. The owner's own close is unchanged: disconnect and drop in the parent
#      send each connection's Terminate (the control that shows 3 and 4 could
#      fail), and the fork guard keeps no connection alive.
#   6. EV::run returns by itself with the fork guard armed: an active EV::fork
#      watcher alone keeps the loop from ever returning.
#
# Real EV::Pg and real libpq, against a stand-in SERVER rather than a stand-in
# client: the defect is what libpq writes to and reads from the socket, which a
# fake EV::Pg could only restate. The server listens on a Unix socket in a
# temporary directory and speaks just enough of the protocol -- startup,
# extended-query replies, Terminate -- and the test drives it synchronously,
# so nothing of it is in the EV loop a child resumes. Every wait is bounded;
# before the fix the claims fail rather than hang.

BEGIN {
  eval { require EV; 1 }     or plan skip_all => 'EV not installed';
  eval { require EV::Pg; 1 } or plan skip_all => 'EV::Pg not installed';
}

use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;

alarm 120;

# --- a PostgreSQL server just good enough for libpq ---------------------------

my $DIR      = File::Temp::tempdir(CLEANUP => 1);
my $LISTENER = IO::Socket::UNIX->new(
  Type   => SOCK_STREAM,
  Local  => "$DIR/.s.PGSQL.5432",
  Listen => 16,
) or plan skip_all => "cannot listen on a Unix socket: $!";

my @BACKENDS;           # one per accepted connection, in accept order
my $NEXT_PID = 4500;
my $HOLD     = qr/k45_held|pg_notify/;
my $HOLDING  = 0;       # true: replies to $HOLD statements wait for release_held

sub msg { my ($type, $body) = @_; return $type . pack('N', 4 + length $body) . $body }

# The reply to one extended-query request: a SELECT yields one text column
# holding the word after SELECT, everything else a command tag.
sub answer {
  my ($b, $sql) = @_;
  my $out = msg('1', '') . msg('2', '');
  if ($sql =~ /\A\s*SELECT\s+(\S+)/i) {
    my $v = $1;
    $out .= msg('T', pack('n', 1) . "v\0" . pack('NnNnNn', 0, 0, 25, 0xFFFF, 0xFFFFFFFF, 0))
          . msg('D', pack('n', 1) . pack('N', length $v) . $v)
          . msg('C', "SELECT 1\0");
  }
  else {
    my ($tag) = map { uc } $sql =~ /\A\s*(\w+)/;
    $b->{in_txn} = 1 if $tag eq 'BEGIN';
    $b->{in_txn} = 0 if $tag eq 'COMMIT' || $tag eq 'ROLLBACK';
    $out .= msg('n', '') . msg('C', "$tag\0");
  }
  return $out . msg('Z', $b->{in_txn} ? 'T' : 'I');
}

sub consume {
  my ($b) = @_;
  unless ($b->{up}) {
    return if length $b->{buf} < 4;
    my $len = unpack 'N', $b->{buf};
    return if length $b->{buf} < $len;
    substr($b->{buf}, 0, $len, '');
    syswrite $b->{sock}, msg('R', pack('N', 0)) . msg('K', pack('NN', $b->{pid}, 1)) . msg('Z', 'I');
    $b->{up} = 1;
  }
  while (length $b->{buf} >= 5) {
    my ($type, $len) = unpack 'a N', $b->{buf};
    last if length $b->{buf} < 1 + $len;
    my $body = substr($b->{buf}, 5, $len - 4);
    substr($b->{buf}, 0, 1 + $len, '');
    if    ($type eq 'X') { $b->{terminated}++ }
    elsif ($type eq 'P') { (undef, $b->{sql}) = unpack 'Z* Z*', $body }
    elsif ($type eq 'S') {
      my $reply = answer($b, $b->{sql} // '');
      if ($HOLDING && ($b->{sql} // '') =~ $HOLD) { push @{ $b->{held} }, $reply }
      else                                          { syswrite $b->{sock}, $reply }
    }
  }
  return;
}

# One pass of the server: accept, read, answer. Waits 2ms at most.
sub serve_once {
  my @socks = ($LISTENER, map { $_->{sock} } grep { !$_->{eof} } @BACKENDS);
  for my $s (IO::Select->new(@socks)->can_read(0.002)) {
    if ($s == $LISTENER) {
      my $c = $LISTENER->accept or next;
      push @BACKENDS, { sock => $c, pid => ++$NEXT_PID, buf => '', held => [], terminated => 0 };
      next;
    }
    my ($b) = grep { $_->{sock} == $s } @BACKENDS;
    my $n = sysread $s, my $chunk, 65536;
    if (!$n) { $b->{eof} = 1; next }
    $b->{buf} .= $chunk;
    consume($b);
  }
  return;
}

sub release_held {
  for my $b (@BACKENDS) { syswrite $b->{sock}, $_ for splice @{ $b->{held} } }
  return;
}

sub held { my $n = 0; $n += @{ $_->{held} } for @BACKENDS; return $n }

sub terminated { my $n = 0; $n += $_->{terminated} for @_; return $n }

# --- driving ------------------------------------------------------------------

# Run the client's loop and serve until $cond holds; false after $max seconds.
sub drive {
  my ($cond, $max) = @_;
  my $deadline = Time::HiRes::time() + ($max // 5);
  until ($cond->()) {
    return 0 if Time::HiRes::time() > $deadline;
    EV::run(EV::RUN_NOWAIT());
    serve_once();
  }
  return 1;
}

sub serve_for {
  my ($secs) = @_;
  my $deadline = Time::HiRes::time() + $secs;
  drive(sub { Time::HiRes::time() > $deadline }, $secs + 1);
  return;
}

# In a child: resume the loop for $secs, serving nothing.
sub child_loop {
  my ($secs) = @_;
  my $deadline = Time::HiRes::time() + $secs;
  while (Time::HiRes::time() < $deadline) {
    EV::run(EV::RUN_NOWAIT());
    Time::HiRes::sleep(0.002);
  }
  return;
}

# Run the loop until it returns by itself; true if it did within $max seconds.
# The bound does not keep the loop running itself.
sub loop_returns {
  my ($max) = @_;
  my $stuck;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $bound = EV::timer($max, 0, sub { $stuck = 1; EV::break(EV::BREAK_ALL()) });
  $bound->keepalive(0);
  EV::run();
  return !$stuck;
}

sub report {
  open my $fh, '>', "$DIR/report" or POSIX::_exit(2);
  print {$fh} join("\t", @_), "\n";
  close $fh;
  return;
}

sub read_report {
  open my $fh, '<', "$DIR/report" or return;
  chomp(my $line = <$fh> // '');
  unlink "$DIR/report";
  return split /\t/, $line;
}

sub run_child {
  my ($code) = @_;
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  unless ($pid) {
    alarm 20;
    $code->();
    POSIX::_exit(0);
  }
  waitpid $pid, 0;
  return $? >> 8;
}

# A storage whose pool of $n is warm: $n connections up and back in the pool.
# Returns the storage and the server side of its connections.
sub warm_storage {
  my ($n) = @_;
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { host => $DIR, port => 5432, dbname => 'k45', user => 'k45', pool_size => $n }, {} ]);
  my $first = @BACKENDS;
  my @acquired = map { $storage->pool->acquire } 1 .. $n;
  drive(sub { !grep { !$_->is_ready } @acquired }) or die "pool did not come up\n";
  $storage->pool->release($_->get) for @acquired;
  return ($storage, [ @BACKENDS[ $first .. $#BACKENDS ] ]);
}

sub result_of {
  my ($f) = @_;
  return drive(sub { $f->is_ready }) && $f->is_done ? [ $f->get ] : undef;
}

# --- 1. a child resumes the loop ----------------------------------------------

{
  my ($storage, $backends) = warm_storage(4);
  my $pool = $storage->pool;
  is scalar(@$backends), 4, 'four pooled connections are up';

  $HOLDING = 1;
  my $query = $storage->_query_async('SELECT 42 AS k45_held');
  my $txn   = $storage->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->_query_async('SELECT 7 AS k45_held', []);
  });
  my $notify = $storage->notify('k45', 'payload');
  my ($query_ready, $txn_ready, $notify_ready) = (0, 0, 0);
  $query->on_ready(sub { $query_ready++ });
  $txn->on_ready(sub { $txn_ready++ });
  $notify->on_ready(sub { $notify_ready++ });
  ok drive(sub { held() == 3 }),
    'a pooled query, a pinned transaction and a NOTIFY each have a statement in flight';
  is $pool->available, 1, '... one connection idle, three out';

  # The replies are on the wire before the fork: whichever process reads
  # first gets them.
  release_held();
  $HOLDING = 0;

  is run_child(sub {
    child_loop(0.3);
    my @r = (
      ($query->is_ready ? 1 : 0), $query_ready,
      ($txn->is_ready   ? 1 : 0), $txn_ready,
      ($notify->is_ready ? 1 : 0), $notify_ready,
      $pool->available,
    );
    push @r, loop_returns(2) ? 1 : 0;
    report(@r);
  }), 0, 'the child resumed the loop and exited';

  my @r = read_report();
  is scalar(@r), 8, 'the child reported';
  is "@r[0..1]", '0 0', 'in the child the query\'s Future stayed pending and no callback ran';
  is "@r[2..3]", '0 0', 'in the child the transaction\'s Future stayed pending and no callback ran';
  is "@r[4..5]", '0 0', 'in the child the NOTIFY\'s Future stayed pending and no callback ran';
  is $r[6], 1, 'nothing was released into the child\'s pool';
  is $r[7], 1, 'the child\'s loop returned by itself: the guard that fired does not keep it running';

  is_deeply result_of($query), [ [ 42 ] ], 'in the parent the query completed with its own result';
  is_deeply result_of($txn), [ [ 7 ] ], 'the transaction committed with the result of its own statement';
  ok defined result_of($notify), 'the NOTIFY completed';
  is "$query_ready/$txn_ready/$notify_ready", '1/1/1', 'each Future became ready exactly once';
  is $pool->available, 4, 'every connection is back in the parent\'s pool';

  # --- 2. the owner ---
  EV::default_loop->loop_fork;
  serve_for(0.05);
  my @next = map { $storage->_query_async("SELECT $_") } 1 .. 4;
  is_deeply [ map { result_of($_) } @next ], [ map { [ [ $_ ] ] } 1 .. 4 ],
    'after EV ran its fork watchers in the owner, the pool serves on';
  is terminated(@$backends), 0, '... and no connection was closed';

  $storage->disconnect;
}

# --- 3. a child exits ---------------------------------------------------------

{
  my ($storage, $backends) = warm_storage(2);

  is run_child(sub { exit 0 }), 0, 'a child exited with the parent\'s connections in its pool';
  serve_for(0.3);
  is terminated(@$backends), 0, '... and sent the server no Terminate on any of them';
  is_deeply result_of($storage->_query_async('SELECT 44')), [ [ 44 ] ], '... and the parent\'s pool serves on';

  $storage->disconnect;
}

# --- 4. a child finishes a connection, or drops one --------------------------

{
  my ($storage, $backends) = warm_storage(2);
  my $pool = $storage->pool;

  # A handle as _new_connection builds it, with nothing but this test holding
  # it: dropping it destroys it. (A pooled one is also held by the closures of
  # core's readiness wiring, so in practice it is destroyed at exit -- claim 3.)
  my $first = @BACKENDS;
  my $lone  = DBIO::PostgreSQL::EV::Pool->_new_connection(
    conninfo => "host=$DIR port=5432 dbname=k45 user=k45",
    on_error => sub { },
  );
  ok drive(sub { $lone->is_connected }), 'a connection built by _new_connection alone is up';
  my ($lone_backend) = @BACKENDS[ $first .. $#BACKENDS ];

  is run_child(sub {
    $_->finish for @{ $pool->{_connections} };
    weaken(my $weak = $lone);
    undef $lone;
    report(defined $weak ? 1 : 0);
  }), 0, 'a child finished every inherited pooled connection and dropped the other one';
  is_deeply [ read_report() ], [ 0 ], '... which destroyed it in the child';
  serve_for(0.3);
  is terminated(@$backends, $lone_backend), 0, '... and none of that reached the server';
  is_deeply result_of($storage->_query_async('SELECT 45')), [ [ 45 ] ], '... and the parent\'s pool serves on';
  ok $lone->is_connected, '... and so does the parent\'s other connection';

  # --- 5. the owner's own close ---
  $storage->disconnect;
  weaken(my $weak = $lone);
  undef $lone;
  serve_for(0.3);
  is terminated(@$backends), 2, 'disconnect in the parent sends each pooled connection\'s Terminate';
  is terminated($lone_backend), 1, 'dropping a connection in the parent sends its Terminate';
  ok !defined $weak, '... and the fork guard does not keep it alive';
}

# --- 6. nor the loop -----------------------------------------------------------

{
  my ($storage) = warm_storage(1);
  ok loop_returns(2), 'EV::run returns by itself with an idle pool and the fork guard armed';
  $storage->disconnect;
}

done_testing;
