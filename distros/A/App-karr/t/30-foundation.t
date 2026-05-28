use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path tempdir );
use YAML::XS ();

use App::karr::Foundation;

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
  my $f = new_foundation();
  my $cfg = $f->_config_data;
  is ref $cfg, 'HASH', 'returns hashref';
  is scalar keys %$cfg, 0, 'empty when no config';
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

subtest 'live lock (our own PID) → held' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  $dir->child('.karr.lock')->spew_utf8("$$\n");  # our PID
  my $f   = new_foundation();
  ok $f->_lock_held( $dir ), 'own PID treated as held';
};

subtest 'acquire and release' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  my $f   = new_foundation();
  $f->_acquire_lock( $dir );
  my $pid = $dir->child('.karr.lock')->slurp_utf8;
  chomp $pid;
  is $pid, $$, 'lock file contains our PID';
  $f->_release_lock( $dir );
  ok ! $dir->child('.karr.lock')->exists, 'lock file removed';
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
