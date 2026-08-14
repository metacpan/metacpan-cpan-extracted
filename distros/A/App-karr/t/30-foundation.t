use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );
use YAML::XS ();

use App::karr::Foundation;
use App::karr::Git;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub new_foundation {
  my (%opts) = @_;
  # MooX::Options::new_with_options reads @ARGV — bypass by ->new
  return App::karr::Foundation->new( %opts );
}

sub make_git_repo {
  my $dir = tempdir( CLEANUP => 1 );
  system( 'git', '-C', "$dir", 'init', '-q' ) == 0
    or die "git init failed";
  system( 'git', '-C', "$dir", 'config', 'user.email', 'test@example.invalid' ) == 0
    or die "git config email failed";
  system( 'git', '-C', "$dir", 'config', 'user.name', 'Test' ) == 0
    or die "git config name failed";
  return $dir;
}

sub write_karr_file {
  my ( $dir, %opts ) = @_;
  my $content = "command: " . ( $opts{command} // 'echo hello' ) . "\n";
  $content .= "on_idle: " . ( $opts{on_idle} // 'skip' ) . "\n";
  $content .= "max_runtime: " . ( $opts{max_runtime} // 1800 ) . "\n";
  $dir->child('.karr')->spew_utf8( $content );
}

# Returns ($cfg_dir, $cfg_file) — caller must keep $cfg_dir alive to avoid cleanup
sub write_config {
  my ( $dirs ) = @_;
  my $cfg_dir  = tempdir( CLEANUP => 1 );
  my $cfg_file = $cfg_dir->child('config.yml');
  $cfg_file->spew_utf8( "dirs:\n" . join( '', map { "  - $_\n" } @$dirs ) );
  return ( $cfg_dir, $cfg_file );
}

# karr-init a repo the way `karr init` does: write refs/karr/config, no .karr
# file. Detection must therefore rely on the ref, not a sidecar file.
sub init_karr_board {
  my ( $dir ) = @_;
  App::karr::Git->new( dir => "$dir" )
    ->write_config_ref( { board => { name => 'Test Board' } } );
}

# ---------------------------------------------------------------------------
# Compilation
# ---------------------------------------------------------------------------

subtest 'module loads' => sub {
  use_ok('App::karr::Foundation');
};

# ---------------------------------------------------------------------------
# Config loading
# ---------------------------------------------------------------------------

subtest 'missing config warns and returns empty' => sub {
  # Isolate HOME so the default ~/.config/karr-foundation/config.yml path
  # cannot resolve to a real file on the machine running the tests.
  local $ENV{HOME} = tempdir( CLEANUP => 1 );
  my $f = new_foundation();
  # The warning is the subject of this subtest, so catch it rather than let it
  # through to the harness's STDERR. That handle has no :encoding(UTF-8) layer
  # here -- bin/karr-foundation installs it via enable_std_utf8, an in-process
  # caller does not -- so the em dash in the message (ticket #108) would print
  # wide and warn about it on the way out.
  my @warnings;
  my $cfg = do {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $f->_config_data;
  };
  is ref $cfg, 'HASH', 'returns hashref';
  is scalar keys %$cfg, 0, 'empty when no config';
  is scalar @warnings, 1, 'and says so exactly once';
  like $warnings[0], qr/config not found/, '...naming the missing config';
};

subtest 'config file loaded' => sub {
  my $tmp = tempdir( CLEANUP => 1 );
  my $cfg = $tmp->child('config.yml');
  $cfg->spew_utf8("dirs:\n  - /tmp/fake-repo\n");
  my $f = new_foundation( config => "$cfg" );
  my $data = $f->_config_data;
  is ref $data->{dirs}, 'ARRAY', 'dirs is array';
  is $data->{dirs}[0], '/tmp/fake-repo', 'correct dir';
};

# ---------------------------------------------------------------------------
# Repo discovery
# ---------------------------------------------------------------------------

subtest '_discover_repos: explicit dirs' => sub {
  my $repo1 = make_git_repo();
  my $repo2 = make_git_repo();
  write_karr_file( $repo1 );
  write_karr_file( $repo2 );

  my ( $cfg_dir, $cfg ) = write_config( [ "$repo1", "$repo2" ] );
  my $f   = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 2, 'found 2 repos';
};

subtest '_discover_repos: scan parent dir' => sub {
  my $parent = tempdir( CLEANUP => 1 );
  my $repo1  = $parent->child('proj1');
  my $repo2  = $parent->child('proj2');
  $repo1->mkpath;
  $repo2->mkpath;
  system( 'git', '-C', "$repo1", 'init', '-q' );
  system( 'git', '-C', "$repo2", 'init', '-q' );
  write_karr_file( $repo1 );
  # repo2 has no .karr file — should not be picked up

  my $cfg_dir = tempdir( CLEANUP => 1 );
  my $cfg     = $cfg_dir->child('config.yml');
  $cfg->spew_utf8( "scan:\n  - $parent\n" );

  my $f = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 1, 'only the repo with .karr found';
  like "$repos[0]", qr/proj1/, 'correct repo discovered';
};

# --- Regression: board detection must resolve refs (bug #16) ----------------
# A karr board with no .karr file used to be detected by testing for the loose
# file .git/refs/karr/config. That file disappears after `git gc` / `git
# pack-refs` (the ref is still there, just packed) and never exists at all in a
# worktree (gitdir indirection), so real boards were silently skipped.

subtest '_discover_repos: scan finds a karr repo whose refs are packed (#16)' => sub {
  my $parent = tempdir( CLEANUP => 1 );
  my $repo   = $parent->child('board');
  $repo->mkpath;
  system( 'git', '-C', "$repo", 'init', '-q' ) == 0 or die "git init failed";
  system( 'git', '-C', "$repo", 'config', 'user.email', 'test@example.invalid' );
  system( 'git', '-C', "$repo", 'config', 'user.name',  'Test' );

  # karr-init'd repo, no .karr file — detection must rely on refs/karr/config.
  init_karr_board( $repo );

  # git gc / pack-refs moves the loose ref into packed-refs; the loose file
  # .git/refs/karr/config vanishes although the ref still resolves.
  system( 'git', '-C', "$repo", 'pack-refs', '--all' ) == 0 or die "pack-refs failed";
  ok ! $repo->child('.git/refs/karr/config')->exists,
    'loose ref file gone after pack-refs (old path check would miss the board)';

  my $cfg_dir = tempdir( CLEANUP => 1 );
  my $cfg     = $cfg_dir->child('config.yml');
  $cfg->spew_utf8( "scan:\n  - $parent\n" );

  my $f     = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 1, 'packed-ref karr board still discovered';
  like "$repos[0]", qr/board/, 'correct repo discovered';
};

subtest '_discover_repos: scan finds a karr board inside a git worktree (#16)' => sub {
  my $main = make_git_repo();
  # Worktrees need a commit to branch from.
  $main->child('README')->spew_utf8("x\n");
  system( 'git', '-C', "$main", 'add', 'README' ) == 0 or die "git add failed";
  system( 'git', '-C', "$main", 'commit', '-q', '-m', 'init' ) == 0 or die "git commit failed";

  my $parent = tempdir( CLEANUP => 1 );
  my $wt     = $parent->child('wt');
  system( 'git', '-C', "$main", 'worktree', 'add', '-q', '-b', 'feature', "$wt" ) == 0
    or die "worktree add failed";
  ok -f "$wt/.git", '.git in worktree is a file, not a directory';

  # Init the board from inside the worktree — refs/karr/* are shared refs.
  init_karr_board( $wt );

  my $cfg_dir = tempdir( CLEANUP => 1 );
  my $cfg     = $cfg_dir->child('config.yml');
  $cfg->spew_utf8( "scan:\n  - $parent\n" );

  my $f     = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 1, 'karr board in a worktree is discovered (gitdir indirection)';
  like "$repos[0]", qr/wt/, 'the worktree dir is the discovered board';
};

subtest '_discover_repos: plain dir nested in a karr repo is not a board (walk-up guard)' => sub {
  # The scan dir sits INSIDE a karr repo. libgit2's open_ext walks up to find a
  # .git, so a naive ref check on a plain child would resolve the ANCESTOR's
  # refs/karr/config — a false positive. The board root must be $child itself.
  my $outer = make_git_repo();
  init_karr_board( $outer );

  my $scan = $outer->child('scan');
  $scan->mkpath;
  my $plain = $scan->child('plain');   # not its own repo; ancestor is a karr repo
  $plain->mkpath;

  my $cfg_dir = tempdir( CLEANUP => 1 );
  my $cfg     = $cfg_dir->child('config.yml');
  $cfg->spew_utf8( "scan:\n  - $scan\n" );

  my $f     = new_foundation( config => "$cfg" );
  my @repos = $f->_discover_repos;
  is scalar @repos, 0, 'plain dir nested in a karr repo is not discovered as a board';

  ok ! $f->_is_karr_board_root( $plain ),
    'walk-up guard: resolved repo root is the ancestor, not the child';
  ok $f->_is_karr_board_root( $outer ),
    'the actual karr repo root IS detected as a board root';
};

subtest '_process_repo: packed-ref board is processed, not skipped (#16)' => sub {
  # Exercises the second detection site directly: with the old loose-file check
  # a packed-ref board without a .karr file was skipped as "no karr board", so
  # its agent never ran. The sentinel proves the command executed.
  my $repo = make_git_repo();
  init_karr_board( $repo );
  system( 'git', '-C', "$repo", 'pack-refs', '--all' ) == 0 or die "pack-refs failed";

  my $cfg_dir = tempdir( CLEANUP => 1 );
  my $cfg     = $cfg_dir->child('config.yml');
  $cfg->spew_utf8( "default_command: touch __sentinel__\n" );

  my $f = new_foundation( config => "$cfg", force => 1 );
  $f->_process_repo( $repo );
  ok $repo->child('__sentinel__')->exists,
    'agent command ran — packed-ref board detected by _process_repo';
};

# ---------------------------------------------------------------------------
# Lock file
# ---------------------------------------------------------------------------

subtest 'no lock file → not held' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  my $f   = new_foundation();
  ok ! $f->_lock_held( $dir ), 'no lock when file absent';
};

subtest 'stale lock (dead PID) → not held' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  $dir->child('.karr.lock')->spew_utf8("999999999\n");  # unlikely PID
  my $f   = new_foundation();
  ok ! $f->_lock_held( $dir ), 'stale lock treated as not held';
};

# Ticket #162: the lock's source of truth is flock(2) on an open fd, not the
# pid written in the file. A file that names our pid but has no flock is
# stale and not held — the previous foundation died without releasing, and
# the next probe should be able to take over. Conversely, the live lock is
# the one whose fd we hold; an outside observer sees it via _lock_held.
subtest 'live lock held via flock, not via pid text' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  # File exists and names our pid, but is not flock'd — not held.
  $dir->child('.karr.lock')->spew_utf8("$$\n");
  my $f = new_foundation();
  ok ! $f->_lock_held( $dir ), 'pid alone is no longer proof of life';

  # Now acquire — flock is what counts.
  ok $f->_acquire_lock( $dir ), 'acquire returns true';
  ok  $f->_lock_held( $dir ),  'live flock => held';
  # The file's content is JSON, not bare pid.
  my $content = $f->_read_lock_metadata( $dir );
  is $content->{pid}, $$ // 0, 'recorded pid matches ours'
    or diag 'lock file does not record our foundation pid';
  # _take_lock_fh drops the fd; the lock file may still exist briefly on
  # disk but is no longer held by anyone.
  $f->_take_lock_fh( $dir );
  ok ! $f->_lock_held( $dir ), 'fd closed => not held';
};

subtest 'acquire and release round-trip' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  my $f   = new_foundation();
  ok $f->_acquire_lock( $dir ), 'acquire returns true';
  ok  $f->_lock_held( $dir ), 'held after acquire';
  $f->_release_lock( $dir );
  ok ! $f->_lock_held( $dir ), 'not held after release';
  ok ! $dir->child('.karr.lock')->exists, 'lock file removed on release';
};

# Two ticks cannot both hold the lock: the second one's LOCK_EX|LOCK_NB
# probe fails with EWOULDBLOCK. The previous design let the second tick
# spew over the first one's pid text and then unlock the file on its way
# out, leaving a third tick to think the board was free while the first
# one was still running (#162).
subtest 'two acquires in sequence: only the second waits' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  my $f1 = new_foundation();
  my $f2 = new_foundation();
  ok $f1->_acquire_lock( $dir ), 'first acquires';
  ok ! $f2->_acquire_lock( $dir ), 'second refuses (EWOULDBLOCK)';
  ok $f1->_lock_held( $dir ),  'first still holds it';
  $f1->_release_lock( $dir );
  ok $f2->_acquire_lock( $dir ), 'second succeeds once first released';
  $f2->_release_lock( $dir );
};

# _release_lock does not touch a lock that a different foundation instance
# holds. Without this, a foundation whose process restart re-acquired
# cleanly would, on its way out, unlock the file its successor already
# owns — the successor's drain would then race the next tick (#162 again,
# different shape: pid-recycled via systemd's restart loop).
subtest 'release refuses to unlock somebody else\'s lock' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  my $f1 = new_foundation();
  my $f2 = new_foundation();
  $f1->_acquire_lock( $dir );
  # Force f2's release attempt on f1's lock. f2 has no fd, so the call is
  # a no-op — the lock stays held by f1.
  $f2->_release_lock( $dir );
  ok $f1->_lock_held( $dir ), 'f1 still holds it after f2\'s release';
  ok -e $dir->child('.karr.lock'), 'lock file still present';
  $f1->_release_lock( $dir );
};

# ---------------------------------------------------------------------------
# State file
# ---------------------------------------------------------------------------

subtest 'state get/set round-trip' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  my $f   = new_foundation();

  is $f->_state_get( $dir, 'hash' ), undef, 'undef before any state written';

  $f->_state_set( $dir, hash => 'abc123', last_exit => 0 );
  is $f->_state_get( $dir, 'hash' ),      'abc123', 'hash persisted';
  is $f->_state_get( $dir, 'last_exit' ), 0,        'last_exit persisted';

  $f->_state_set( $dir, hash => 'def456' );
  is $f->_state_get( $dir, 'hash' ),      'def456', 'hash updated';
  is $f->_state_get( $dir, 'last_exit' ), 0,        'last_exit preserved on partial update';
};

# ---------------------------------------------------------------------------
# .karr file parsing
# ---------------------------------------------------------------------------

subtest '_load_karr: missing file → empty hash' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  my $f   = new_foundation();
  my $k   = $f->_load_karr( $dir );
  is ref $k, 'HASH', 'returns hashref';
  is scalar keys %$k, 0, 'empty when no .karr';
};

subtest '_load_karr: parses correctly' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  write_karr_file( $dir, command => 'echo hello', max_runtime => 900 );
  my $f = new_foundation();
  my $k = $f->_load_karr( $dir );
  is $k->{command},     'echo hello', 'command parsed';
  is $k->{max_runtime}, 900,          'max_runtime parsed';
};

# ---------------------------------------------------------------------------
# Dry-run end-to-end
# ---------------------------------------------------------------------------

subtest 'run with --dry-run: does not execute' => sub {
  my $repo = make_git_repo();
  write_karr_file( $repo, command => 'touch __sentinel__', on_idle => 'always-run' );

  my ( $cfg_dir, $cfg ) = write_config( ["$repo"] );
  my $f   = new_foundation( config => "$cfg", dry_run => 1, force => 1 );
  # dry_run => 1 short-circuits sync, lock, command execution, state write
  $f->run;
  ok ! $repo->child('__sentinel__')->exists,
    'sentinel not created — dry-run did not execute';
};

done_testing;
