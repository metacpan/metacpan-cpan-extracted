use strict;
use warnings;
use Test::More;
use Errno ();
use IPC::Open3 ();
use POSIX qw(WNOHANG);

use DBIO::Forked::Storage;

# OFFLINE test: reaping a query's child leaves the caller's status variables
# alone (karr k19).
#
# WHY: every query is a child process, and every child is reaped with waitpid
# -- which writes the child's status into $?. Two places read $? after us:
#
#   * perl itself, at exit. While a script is going down, $? IS its exit code,
#     and a Future that was never collected is destroyed right then. If its
#     DESTROY lets waitpid's 0 through, a cron job or deploy step that died
#     with a query still pending reports success.
#   * the caller, after its own system() or backticks. Collecting a result in
#     between must not swap the status of that command for the status of a
#     child the caller never saw.
#
# The mirror image is the same defect: once something else has reaped the
# child (the application's own waitpid(-1) loop), waitpid fails, $? becomes -1
# and $! ECHILD -- and a script that ended normally exits 255.
#
# Every block also checks that the child WAS reaped. Not calling waitpid would
# leave $? alone too, and leave a zombie per query.
#
# WHAT RUNS FOR REAL: DBIO::Forked::Storage::_run_forked (fork + pipe +
# Storable) and DBIO::Forked::Future, in this process and in a script of its
# own. THE SUBSTITUTION: the sync storage is a mock; no DBI, no database.

alarm 60;

{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select { shift; return ([ 1, 'Alice' ]) }

  package t::Mock::Schema;
  sub new { my ($class, $storage) = @_; bless { storage => $storage }, $class }
  sub storage { $_[0]->{storage} }
}

my $schema  = t::Mock::Schema->new(t::Mock::Storage->new);   # held: the backend keeps it weakly
my $storage = DBIO::Forked::Storage->new($schema);

# The status an earlier command of the caller left behind: it exited with 3.
my $EARLIER = 3 << 8;

# ---------------------------------------------------------------------------
# 1. The exit code of a script that ends with a query still pending.
# ---------------------------------------------------------------------------

# The same setup as above, as a script: one query fired, its Future kept in a
# package variable and never collected, so it is destroyed only when perl
# shuts down.
my $SCRIPT = <<'PERL';
use strict;
use warnings;
use DBIO::Forked::Storage;
{
  package t::Mock::Storage;
  sub new { bless {}, shift }
  sub select { shift; return ([ 1, 'Alice' ]) }

  package t::Mock::Schema;
  sub new { my ($class, $storage) = @_; bless { storage => $storage }, $class }
  sub storage { $_[0]->{storage} }
}
$| = 1;
alarm 30;
print "lib: $INC{'DBIO/Forked/Future.pm'}\n";
our $schema  = t::Mock::Schema->new(t::Mock::Storage->new);
our $pending = DBIO::Forked::Storage->new($schema)->select_async('artist');
print "pending\n";
PERL

# Run $SCRIPT with $ending appended, in a perl of its own. @INC is handed down
# explicitly: the -I switches of the perl running this file do not reach a
# perl it starts, and the script has to load the very lib under test.
# Returns how it ended ("exit N" / "signal N") and everything it printed.
sub run_script {
  my ($ending) = @_;
  my $pid = IPC::Open3::open3(
    my $in, my $out, undef,
    $^X, (map { "-I$_" } grep { !ref } @INC), '-e', $SCRIPT . $ending,
  );
  close $in;
  my $output = do { local $/; <$out> };
  waitpid($pid, 0);
  my $how = $? & 127 ? 'signal ' . ($? & 127) : 'exit ' . ($? >> 8);
  return ($how, $output);
}

# What the script prints before its ending runs: it loaded the Future this
# file loaded, and the query was fired. Without this an "exit 255" could just
# as well be a script that never got as far as the lib.
my $started = "lib: $INC{'DBIO/Forked/Future.pm'}\npending\n";

# die exits with $! if that is set, else with 255. The script has forked and
# printed by now, so it clears $! to end on the 255 a plain die gives.
{
  my ($how, $output) = run_script(q{$! = 0; die "fatal\n";});
  is $how, 'exit 255', 'a script that dies with a query pending exits 255, not 0';
  is $output, $started . "fatal\n", '... and it died of that die, with the lib under test loaded';
}

{
  my ($how, $output) = run_script(q{exit 3;});
  is $how, 'exit 3', 'a script that calls exit 3 with a query pending exits 3, not 0';
  is $output, $started, '... with the lib under test loaded';
}

{
  my ($how, $output) = run_script(q{waitpid(-1, 0); print "reaped elsewhere\n";});
  is $how, 'exit 0',
    'a script that ends normally exits 0 when its own reaper already took the child';
  is $output, $started . "reaped elsewhere\n", '... with the lib under test loaded';
}

# ---------------------------------------------------------------------------
# 2. At run time: the caller's $? survives every path that reaps.
# ---------------------------------------------------------------------------

# get
{
  my $f = $storage->select_async('artist');
  $? = $EARLIER;
  my @rows = $f->get;
  my $status = $?;

  is $status, $EARLIER, 'get: the status of the caller\'s earlier command is still in $?';
  is_deeply \@rows, [ [ 1, 'Alice' ] ], 'get: ... and the rows arrived';
  is waitpid(-1, WNOHANG), -1, 'get: ... and the child was reaped';
}

# is_ready, polled until the child is done -- the last poll reaps
{
  my $f = $storage->select_async('artist');
  $? = $EARLIER;
  my $tries = 0;
  while (!$f->is_ready && $tries++ < 2000) {
    select undef, undef, undef, 0.005;   # 5ms tick, no event loop
  }
  my $status = $?;

  ok $f->is_ready, 'is_ready: became true';
  is $status, $EARLIER, 'is_ready: the status of the caller\'s earlier command is still in $?';
  is waitpid(-1, WNOHANG), -1, 'is_ready: ... and the child was reaped';
}

# A Future that is dropped without ever being collected: DESTROY reaps. A
# destructor runs wherever the last reference happens to go, so it must leave
# all three alone -- $? as above, and the error state ($!, $@) of whatever the
# caller was in the middle of.
{
  my $f = $storage->select_async('artist');
  $@ = "earlier error\n";
  $! = Errno::ENOENT;
  $? = $EARLIER;
  undef $f;
  my ($status, $errno, $eval_error) = ($?, $! + 0, $@);

  is $status, $EARLIER, 'dropped uncollected: the status of the caller\'s earlier command is still in $?';
  is $errno, Errno::ENOENT, 'dropped uncollected: $! is untouched';
  is $eval_error, "earlier error\n", 'dropped uncollected: $@ is untouched';
  is waitpid(-1, WNOHANG), -1, 'dropped uncollected: ... and the child was reaped';
}

# The child is gone before we reap it: the application's own reaper took it.
# waitpid then FAILS, and the failure (-1 in $?, ECHILD in $!) is none of the
# caller's business either -- it asked for rows, not for a wait.
{
  my $f = $storage->select_async('artist');
  isnt waitpid(-1, 0), -1, 'reaped elsewhere: the application\'s reaper took the child';
  $! = Errno::ENOENT;
  $? = $EARLIER;
  undef $f;
  my ($status, $errno) = ($?, $! + 0);

  is $status, $EARLIER, 'reaped elsewhere, dropped: $? is untouched';
  is $errno, Errno::ENOENT, 'reaped elsewhere, dropped: $! is untouched';
}

{
  my $f = $storage->select_async('artist');
  isnt waitpid(-1, 0), -1, 'reaped elsewhere: the application\'s reaper took the child';
  $! = 0;
  $? = $EARLIER;
  my @rows = $f->get;
  my ($status, $errno) = ($?, $! + 0);

  is $status, $EARLIER, 'reaped elsewhere, get: $? is untouched';
  isnt $errno, Errno::ECHILD, 'reaped elsewhere, get: the failed wait does not show in $!';
  is_deeply \@rows, [ [ 1, 'Alice' ] ], 'reaped elsewhere, get: ... and the rows arrived';
}

done_testing;
