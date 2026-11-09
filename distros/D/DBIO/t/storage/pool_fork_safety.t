use strict;
use warnings;
use Test::More;
use Config;
use File::Temp ();

use DBIO::Storage::PoolBase;
use DBIO::Test::Future ();

# Regression test for karr core k210: DBIO::Storage::PoolBase had no fork guard
# and no guard against undef connection slots, so a forked EV/async worker that
# inherited the pool ran the pool's DESTROY -> shutdown during its OWN global
# destruction -- over connections the parent still owns -- producing a flood of
# "Use of uninitialized value" warnings and disconnecting the parent's live
# handles, which TAP saw as the test dying (non-zero child exit) before
# done_testing. The fix is classic DBI fork-safety (only the owning process
# tears the connections down) plus undef-slot guards on the refaddr bookkeeping.

{
  package MockConn;
  sub new { bless { id => $_[1], close_count => 0 }, $_[0] }
  sub close { $_[0]->{close_count}++ }
}

{
  package ForkPool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { MockConn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { $_[1]->close }   # the physical teardown a child must NOT run
}

sub new_pool {
  ForkPool->new(conninfo => 'fake', size => 3, future_class => 'DBIO::Test::Future');
}

# --- 1. Owner-process teardown is unchanged (house rule 11) ---------------------
# The property the pre-fix DESTROY asserted -- a live connection is disconnected
# exactly once by its owner, and not again -- must survive the fix.
{
  my $pool = new_pool();
  my $conn = $pool->acquire->get;
  $pool->release($conn);
  is $conn->{close_count}, 0, 'owner: connection not closed before shutdown';

  $pool->shutdown;
  is $conn->{close_count}, 1, 'owner: shutdown disconnects the connection exactly once';

  $pool->shutdown;
  is $conn->{close_count}, 1, 'owner: repeated shutdown does not disconnect twice';
}

# --- 2. Undef connection slots during owner teardown emit no warnings ------------
# Global destruction can reclaim a connection's SV before the pool's, leaving an
# undef in _connections / _idle. Reaching that through refaddr is what produced
# the "uninitialized value" flood; the owner must still close its real
# connection exactly once.
{
  my $pool = new_pool();
  my $conn = $pool->acquire->get;
  $pool->release($conn);
  push @{ $pool->{_connections} }, undef;   # simulate a reclaimed connection SV
  push @{ $pool->{_idle} },        undef;

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  $pool->shutdown;

  is_deeply \@warnings, [],
    'owner: undef connection slots during teardown emit no warnings';
  is $conn->{close_count}, 1,
    'owner: the real connection is still disconnected exactly once';
}

# --- fork-based checks ----------------------------------------------------------
# A child that inherited the pool must tear down its OWN references only, never
# the parent's physical connections. Children never touch the TAP stream: STDOUT
# is redirected away and no Test:: function runs in the child (Test::Builder is
# fork-aware and skips its ending in a child anyway); results come back through
# the child exit status and, for the global-destruction case, a captured STDERR.

SKIP: {
  skip 'fork not available on this platform', 5 unless $Config{d_fork};

  my $pool = new_pool();
  my $conn = $pool->acquire->get;
  $pool->release($conn);
  push @{ $pool->{_connections} }, undef;   # an inherited undef slot, for good measure

  # 3. Child that explicitly shuts the inherited pool down: it must NOT close the
  #    parent's connection and must NOT warn. Any warning exits 91; a stray close
  #    exits 1; a clean run exits 0.
  {
    my $pid = fork;
    defined $pid or die "fork failed: $!";
    unless ($pid) {
      local $SIG{__WARN__} = sub { exit 91 };
      open STDOUT, '>', '/dev/null';
      $pool->shutdown;
      exit($conn->{close_count} == 0 ? 0 : 1);
    }
    waitpid $pid, 0;
    is $?, 0,
      'child: explicit shutdown of inherited pool is silent and skips the parent-owned connection';
  }

  is $conn->{close_count}, 0,
    'owner: the child could not disconnect the parent-owned connection';

  # 4. Child that just exits, letting global destruction run the inherited pool's
  #    DESTROY -> shutdown -- the faithful reproduction of the live symptom.
  {
    my ($efh, $errfile) = File::Temp::tempfile(UNLINK => 1);
    close $efh;
    my $pid = fork;
    defined $pid or die "fork failed: $!";
    unless ($pid) {
      open STDOUT, '>', '/dev/null';
      open STDERR, '>', $errfile;   # capture warnings, incl. during global destruction
      exit 0;                        # -> global destruction runs the inherited DESTROY
    }
    waitpid $pid, 0;
    is $?, 0,
      'child: inherited-pool global destruction exits cleanly (0)';
    my $stderr = do { local $/; open my $r, '<', $errfile or die "open $errfile: $!"; <$r> };
    $stderr = '' unless defined $stderr;
    unlike $stderr, qr/uninitialized value/i,
      'child: inherited-pool global destruction emits no uninitialized-value warnings';
  }

  # 5. Owner teardown is still correct after the children have come and gone.
  $pool->shutdown;
  is $conn->{close_count}, 1,
    'owner: shutdown after fork still disconnects its connection exactly once';
}

done_testing;
