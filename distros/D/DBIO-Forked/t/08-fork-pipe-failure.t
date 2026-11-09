use strict;
use warnings;
use Test::More;
use POSIX qw(WNOHANG);
use Errno ();
use POSIX ();

# OFFLINE test: fork() or pipe() itself fails (karr k15).
#
# WHY: a process that has run out of processes or file descriptors is exactly
# where a fork-per-query backend gets asked for one more. What the caller is
# told then was written down nowhere and run by nothing. The code answers
# with a croak out of the *_async call -- NOT with a failed Future: there is
# no child and no pipe a Future could stand for. This file pins that, and what
# must hold afterwards: nothing was started, the pipe opened for a fork that
# never happened is closed again, and the backend works once the system call
# does.
#
# The croak on a failed fork carries more than its message. Without it the
# undefined pid reads as "I am the child": the PARENT would run the query
# in-process, close the reading end of its own pipe and write the answer into
# it -- and the calling program is gone, killed by SIGPIPE or, where that is
# ignored, through the child's _exit(0).
#
# WHAT RUNS FOR REAL: DBIO::Forked::Storage::_run_forked, and -- with both
# switches off -- real fork + pipe + Storable.
# THE SUBSTITUTIONS: fork and pipe are overridden through CORE::GLOBAL, which
# only takes effect for code compiled AFTERWARDS -- hence the BEGIN block
# ahead of the first `use DBIO::Forked::Storage`. With its switch off an
# override passes straight through to the builtin.

our ($FORK_FAILS, $PIPE_FAILS, $FORKS);

BEGIN {
  $FORKS = 0;
  no warnings 'once';
  *CORE::GLOBAL::fork = sub () {
    if ($FORK_FAILS) { $! = Errno::EAGAIN; return undef }
    $FORKS++;
    return CORE::fork();
  };
  *CORE::GLOBAL::pipe = sub (**) {
    if ($PIPE_FAILS) { $! = Errno::EMFILE; return 0 }
    return CORE::pipe($_[0], $_[1]);
  };
}

use DBIO::Forked::Storage;

alarm 60;

{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select { shift; return ([ 1, 'Alice' ], [ $$, 'pid' ]) }

  package t::Mock::Schema;
  sub new { my ($class, $storage) = @_; bless { storage => $storage }, $class }
  sub storage { $_[0]->{storage} }
}

my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);   # held: the backend keeps it weakly
my $storage = DBIO::Forked::Storage->new($schema);

# The lowest free file descriptor. An fd left open by the call under test
# moves it up.
sub next_fd {
  open(my $fh, '<', $0) or die "open $0: $!";
  return fileno $fh;
}

my $errno_text = sub { local $! = shift; "$!" };

# ---------------------------------------------------------------------------
# 0. Control: the overrides are in the path, and transparent.
# ---------------------------------------------------------------------------
{
  my @rows = $storage->select_async('artist')->get;
  die 'control: no roundtrip through the overrides'
    unless $rows[0][1] eq 'Alice' && $rows[1][0] != $$;
  is $FORKS, 1, 'control: the backend\'s fork goes through the override';
}

# ---------------------------------------------------------------------------
# 1. fork fails.
# ---------------------------------------------------------------------------
{
  my $fd_before = next_fd();

  my $f = do { local $FORK_FAILS = 1; eval { $storage->select_async('artist') } };
  my $err = $@;

  ok !defined $f, 'fork fails: select_async returns no Future';
  like $err, qr/^DBIO::Forked: fork failed: \Q${\ $errno_text->(Errno::EAGAIN) }\E/,
    'fork fails: it croaks, with the reason the system gave';
  like $err, qr/ at \Q$0\E line \d+/, '... reported at the caller\'s line';
  is next_fd(), $fd_before, 'fork fails: both ends of the pipe it had opened are closed again';
  is waitpid(-1, WNOHANG), -1, 'fork fails: there is no child';
}

# ---------------------------------------------------------------------------
# 2. pipe fails.
# ---------------------------------------------------------------------------
{
  my $forks = $FORKS;

  my $f = do { local $PIPE_FAILS = 1; eval { $storage->select_async('artist') } };
  my $err = $@;

  ok !defined $f, 'pipe fails: select_async returns no Future';
  like $err, qr/^DBIO::Forked: pipe failed: \Q${\ $errno_text->(Errno::EMFILE) }\E/,
    'pipe fails: it croaks, with the reason the system gave';
  like $err, qr/ at \Q$0\E line \d+/, '... reported at the caller\'s line';
  is $FORKS, $forks, 'pipe fails: nothing was forked without a pipe to answer on';
  is waitpid(-1, WNOHANG), -1, 'pipe fails: there is no child';
}

# ---------------------------------------------------------------------------
# 3. Afterwards: the same backend object works again.
# ---------------------------------------------------------------------------
{
  my @rows = eval { $storage->select_async('artist')->get };
  is $@, '', 'afterwards: select_async works again';
  is_deeply $rows[0], [ 1, 'Alice' ], '... and roundtrips';
  is waitpid(-1, WNOHANG), -1, 'no unreaped child processes left';
}

# ---------------------------------------------------------------------------
# 4. The child ends without an answer (karr k20): the message says how.
#
# CLAIM: an empty blob plus a wait status that is not a clean exit names the
# signal or the exit status; a blob that is present but corrupt stays
# "corrupt"; a clean exit with no blob keeps the plain "empty" message.
# A Future dropped while its child is still working dies of SIGPIPE -- the
# normal fate -- and that is no event anybody sees.
# ---------------------------------------------------------------------------
{
  package t::Mock::Dying;
  our $HOW;
  sub new { bless {}, shift }
  sub select {
    if ($HOW eq 'kill') { kill 'KILL', $$; sleep 5 }
    if ($HOW eq 'exit') { POSIX::_exit(3) }
    if ($HOW eq 'clean') { POSIX::_exit(0) }
    if ($HOW eq 'slow') { sleep 1; return ([ 1 ]) }
    return ([ 1 ]);
  }
}

my $dying_schema = t::Mock::Schema->new(t::Mock::Dying->new);
my $dying        = DBIO::Forked::Storage->new($dying_schema);

sub failure_of {
  my ($how) = @_;
  local $t::Mock::Dying::HOW = $how;
  eval { $dying->select_async('artist')->get };
  return $@;
}

{
  my $err = failure_of('kill');
  like $err, qr/child killed by signal 9\b/, 'child SIGKILLed: the message names signal 9';
  unlike $err, qr/corrupt/, '... and does not call it corrupt';

  $err = failure_of('exit');
  like $err, qr/child exited with status 3\b/, 'child exit(3) without a blob: the message names status 3';

  $err = failure_of('clean');
  like $err, qr/empty result from child/, 'clean exit, no blob: still the plain empty-result message';
  unlike $err, qr/signal|status/, '... with no signal or status in it';

  # A present but corrupt blob: the child writes garbage and exits 0.
  pipe(my $rh, my $wh) or die $!;
  my $pid = fork() // die $!;
  if (!$pid) { close $rh; syswrite $wh, 'not a storable blob'; POSIX::_exit(0) }
  close $wh;
  $err = eval { DBIO::Forked::Future->new(read_fh => $rh, pid => $pid)->get; 1 } ? '' : $@;
  like $err, qr/corrupt or empty result from child/, 'corrupt blob: reported as corrupt';
  unlike $err, qr/killed by signal|exited with status/, '... not as a death';
}

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, @_ };
  local $t::Mock::Dying::HOW = 'slow';
  { my $f = $dying->select_async('artist'); }   # dropped while the child sleeps
  is_deeply \@warn, [], 'dropped Future: its child dying of SIGPIPE raises nothing';
  is waitpid(-1, WNOHANG), -1, '... and the child is reaped';
}

done_testing;
