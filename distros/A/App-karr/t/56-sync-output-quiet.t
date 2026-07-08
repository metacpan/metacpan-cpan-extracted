use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );

use App::karr::Role::SyncLifecycle;
use App::karr::SyncGuard;

# Ticket #27: sync output is retry-only.
#   * Attempt 1 is silent (the common case prints nothing at all).
#   * From attempt 2 on, the retry is announced ("Pull retry 2 of 3...").
#   * Errors ALWAYS reach STDERR, and --quiet never suppresses them.
#   * --quiet additionally silences the retry announcements.
#   * There is no --verbose.
# The same convention applies to the SyncGuard insurance push (DESTROY) and to
# the explicit `karr sync` progress lines (which move from STDOUT to STDERR).

# A git double driven by a queue of pull/push results, exposing a distinctive
# last_error() we can look for on STDERR. An empty queue defaults to success.
{
  package SeqGit;
  sub new {
    my ($class, %args) = @_;
    return bless {
      pull => $args{pull} || [],
      push => $args{push} || [],
      err  => defined $args{err} ? $args{err} : 'SIMULATED-FAILURE',
    }, $class;
  }
  sub pull { my ($self) = @_; my $r = shift @{ $self->{pull} }; return defined $r ? $r : 1 }
  sub push { my ($self) = @_; my $r = shift @{ $self->{push} }; return defined $r ? $r : 1 }
  sub last_error { $_[0]{err} }
}

# Minimal consumer of the sync lifecycle role; --quiet is an option the role
# provides, so QuietBoard->new( quiet => 1 ) exercises the quiet path.
{
  package QuietBoard;
  use Moo;
  use MooX::Options;
  with 'App::karr::Role::SyncLifecycle';
  has git => ( is => 'ro', required => 1 );
}

# Run $code with STDERR captured to an in-memory buffer, including any DESTROY
# that fires while the block unwinds. Returns ( $stderr_text, $exception ).
sub capture_stderr {
  my ($code) = @_;
  my $buf = '';
  my $err;
  {
    local *STDERR;
    open STDERR, '>', \$buf or die "cannot redirect STDERR: $!";
    $err = do {
      local $@;
      eval { $code->(); 1 } ? undef : $@;
    };
  }
  return ( $buf, $err );
}

subtest 'sync_before: a first-attempt pull success is completely silent' => sub {
  my ( $stderr, $err ) = capture_stderr( sub {
    my $board = QuietBoard->new( git => SeqGit->new( pull => [1] ) );
    my $guard = $board->sync_before;
    $guard->done;    # neutralise teardown push
  } );
  is $err, undef, 'no exception on a clean pull';
  is $stderr, '', 'attempt 1 prints nothing (retry-only default)';
};

subtest 'sync_before: speaks from retry 2, and the error is always shown' => sub {
  my ( $stderr, $err ) = capture_stderr( sub {
    my $board = QuietBoard->new( git => SeqGit->new( pull => [ 0, 1 ], err => 'NET-DOWN' ) );
    my $guard = $board->sync_before;
    $guard->done;
  } );
  is $err, undef, 'pull recovers on the retry';
  like   $stderr, qr/Pull retry 2 of 3/, 'announces the retry starting at attempt 2';
  unlike $stderr, qr/attempt 1/i,        'attempt 1 is never announced';
  unlike $stderr, qr/retry 1 of 3/,      'attempt 1 is never labelled a retry';
  like   $stderr, qr/NET-DOWN/,          'the failing-attempt error is always shown';
};

subtest 'sync_before --quiet: retry announcement gone, error still shown' => sub {
  my ( $stderr, $err ) = capture_stderr( sub {
    my $board = QuietBoard->new(
      git   => SeqGit->new( pull => [ 0, 1 ], err => 'NET-DOWN' ),
      quiet => 1,
    );
    my $guard = $board->sync_before;
    $guard->done;
  } );
  is $err, undef, 'pull still recovers under --quiet';
  unlike $stderr, qr/Pull retry/, '--quiet suppresses the retry announcement';
  like   $stderr, qr/NET-DOWN/,   '--quiet never suppresses errors';
};

subtest 'sync_after --quiet: retries silent, terminal error always surfaces' => sub {
  my $board = QuietBoard->new(
    git   => SeqGit->new( push => [ 0, 0, 0 ], err => 'PUSH-NAK' ),
    quiet => 1,
  );
  my ( $stderr, $err ) = capture_stderr( sub { $board->sync_after } );
  like   $err,    qr/Push failed after 3 attempts/, 'sync_after croaks after 3 failed pushes';
  unlike $stderr, qr/Push retry/, '--quiet suppresses the push retry announcements';
  like   $stderr, qr/PUSH-NAK/,   'the push error is always shown, even under --quiet';
};

subtest 'SyncGuard DESTROY: a first-attempt push success is silent' => sub {
  my ( $stderr, $err ) = capture_stderr( sub {
    my $guard = App::karr::SyncGuard->new( git => SeqGit->new( push => [1] ) );
    $guard->DESTROY;
    $guard->done;    # neutralise the scope-exit DESTROY
  } );
  is $stderr, '', 'the insurance push says nothing when it succeeds on attempt 1';
};

subtest 'SyncGuard DESTROY: retry announced from attempt 2, error shown' => sub {
  my ( $stderr, $err ) = capture_stderr( sub {
    my $guard = App::karr::SyncGuard->new( git => SeqGit->new( push => [ 0, 1 ], err => 'PUSH-NAK' ) );
    $guard->DESTROY;
    $guard->done;
  } );
  like   $stderr, qr/Push retry 2 of 3/, 'guard announces the retry from attempt 2';
  unlike $stderr, qr/attempt 1/i,        'guard never announces attempt 1';
  like   $stderr, qr/PUSH-NAK/,          'guard always shows the error';
};

subtest 'SyncGuard DESTROY --quiet: retries silent, error + guidance always' => sub {
  my ( $stderr, $err ) = capture_stderr( sub {
    my $guard = App::karr::SyncGuard->new(
      git   => SeqGit->new( push => [ 0, 0, 0 ], err => 'PUSH-NAK' ),
      quiet => 1,
    );
    $guard->DESTROY;
    $guard->done;
  } );
  unlike $stderr, qr/Push retry/, '--quiet guard suppresses retry announcements';
  like   $stderr, qr/PUSH-NAK/,   '--quiet guard still shows errors';
  like   $stderr, qr/Push failed after 3 attempts/,
    '--quiet guard still shows the "refs are intact, run karr sync" guidance';
};

# ---- Cmd::Sync: progress moves from STDOUT to STDERR and honours --quiet -----

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
  my ( $cwd, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
  close $in;
  my $stdout_text = do { local $/; <$out> };
  my $stderr_text = do { local $/; <$stderr> };
  waitpid( $pid, 0 );
  my $exit = $? >> 8;

  chdir $old or die "chdir $old: $!";
  return {
    exit   => $exit,
    stdout => defined $stdout_text ? $stdout_text : '',
    stderr => defined $stderr_text ? $stderr_text : '',
  };
}

subtest 'karr sync: progress on STDERR, suppressed by --quiet' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );

  my $r = _run_karr( $repo, 'sync' );
  is $r->{exit}, 0, 'karr sync exits 0 (no remote configured)';
  like   $r->{stderr}, qr{Pulling refs/karr/}, 'pull progress is written to STDERR';
  like   $r->{stderr}, qr{Pushing refs/karr/}, 'push progress is written to STDERR';
  unlike $r->{stdout}, qr{Pulling refs/karr/}, 'pull progress is not on STDOUT';
  unlike $r->{stdout}, qr{Pushing refs/karr/}, 'push progress is not on STDOUT';

  my $q = _run_karr( $repo, 'sync', '--quiet' );
  is $q->{exit}, 0, 'karr sync --quiet exits 0';
  unlike $q->{stderr}, qr{Pulling refs/karr/}, '--quiet suppresses pull progress';
  unlike $q->{stderr}, qr{Pushing refs/karr/}, '--quiet suppresses push progress';
};

done_testing;
