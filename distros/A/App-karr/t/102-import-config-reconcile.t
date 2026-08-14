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
use Path::Tiny qw( path );

use App::karr::Git;
use App::karr::BoardStore;

# `karr import` used to replace refs/karr/config with whatever the file view
# held. The file view cannot hold everything the board does, so two things went
# wrong on an ordinary interop round trip -- karr disable, karr materialize,
# kanban list, karr import --yes:
#
#   #87  kanban-md rewrites config.yml the moment it loads one (it migrates the
#        version and re-serializes from its Go structs), and karr's
#        `foundation` key is not in that schema, so it vanishes. Import then
#        read the board as never having been disabled and turned it back ON --
#        karr-foundation resumed running agents on a board the maintainer had
#        switched off, with nothing warning at any step.
#   #88  the same round trip recorded kanban-md's migrated defaults -- version
#        10, its fully-expanded statuses, its whole tui block -- as deliberate
#        per-board overrides, because diffing them against karr's defaults sees
#        them as changed. The board then carried a frozen copy of another
#        tool's defaults and stopped following karr's own.
#
# The fixture below is not a guess at what kanban-md writes: it is the verbatim
# config.yml a kanban-md binary built from the reference implementation left
# behind after `kanban-md list` on a karr-materialized view, board name and
# next_id aside.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
  my ( $cwd, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
  close $in;

  my $stdout      = do { local $/; <$out> };
  my $stderr_text = do { local $/; <$stderr> };
  waitpid( $pid, 0 );
  my $exit = $? >> 8;

  chdir $old or die "chdir $old: $!";
  return {
    exit   => $exit,
    stdout => ( defined $stdout      ? $stdout      : '' ),
    stderr => ( defined $stderr_text ? $stderr_text : '' ),
  };
}

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

# A board with one card, materialized, ready for the other tool to chew on.
sub _materialized_board {
  my (@karr_setup) = @_;
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', 'Round Trip' )->{exit}, 0, 'board initialized' );
  is( _run_karr( $repo, 'create', 'A card' )->{exit},             0, 'card created' );
  is( _run_karr( $repo, @$_ )->{exit}, 0, "karr @$_" ) for @karr_setup;
  is( _run_karr( $repo, 'materialize' )->{exit}, 0, 'materialized' );
  return $repo;
}

# What kanban-md leaves in config.yml after loading a karr-materialized view.
sub _kanban_md_rewrote {
  my ($repo) = @_;
  path($repo)->child('config.yml')->spew_utf8( <<'END' );
version: 10
board:
    name: Round Trip
tasks_dir: tasks
statuses:
    - name: backlog
      show_duration: false
    - name: todo
    - name: in-progress
      require_claim: true
    - name: review
      require_claim: true
    - name: done
      show_duration: false
    - name: archived
      show_duration: false
priorities:
    - low
    - medium
    - high
    - critical
defaults:
    status: backlog
    priority: medium
    class: standard
claim_timeout: 1h
classes:
    - name: expedite
      wip_limit: 1
      bypass_column_wip: true
    - name: fixed-date
    - name: standard
    - name: intangible
tui:
    title_lines: 2
    age_thresholds:
        - after: 0s
          color: "242"
        - after: 1h
          color: "34"
        - after: 24h
          color: "226"
        - after: 72h
          color: "208"
        - after: 168h
          color: "196"
next_id: 2
END
  return $repo;
}

sub _overrides {
  my ($repo) = @_;
  return App::karr::Git->new( dir => $repo )->read_config_ref;
}

# The question karr-foundation actually asks before it runs agents on a board.
# Asserting on the raw override hash is not enough: a missing `foundation` key
# reads as falsy there while meaning the opposite here.
sub _foundation_enabled {
  my ($repo) = @_;
  return App::karr::BoardStore->new( git => App::karr::Git->new( dir => $repo ) )
    ->foundation_enabled;
}

subtest '#87 a kanban-md round trip cannot re-enable a disabled board' => sub {
  my $repo = _materialized_board( [ 'disable', '--reason', 'abandoned driver' ] );
  _kanban_md_rewrote($repo);

  is( _run_karr( $repo, 'import', '--yes' )->{exit}, 0, 'import --yes exits 0' );

  is( _foundation_enabled($repo), 0,
    'karr-foundation still sees a board it must not touch' )
    or diag explain _overrides($repo);
  is( _overrides($repo)->{foundation}{reason}, 'abandoned driver',
    'and the board still says why it was disabled' );

  my $show = _run_karr( $repo, 'config', 'show' );
  like( $show->{stdout}, qr/^foundation\.enabled\s+0$/m,
    'karr config show agrees the board is off' );
};

subtest '#88 a round trip records no override the user did not make' => sub {
  my $repo   = _materialized_board( [ 'disable', '--reason', 'abandoned driver' ] );
  my $before = _overrides($repo);
  _kanban_md_rewrote($repo);

  is( _run_karr( $repo, 'import', '--yes' )->{exit}, 0, 'import --yes exits 0' );

  is_deeply( _overrides($repo), $before,
    'the sparse overrides come back exactly as they went in' )
    or diag explain _overrides($repo);

  my $after = _overrides($repo);
  ok( !exists $after->{tui},
    "kanban-md's tui block is not adopted as board config" );
  ok( !exists $after->{statuses},
    'the migrated status list is not frozen in as an override' );
  is( $after->{version}, 1,
    "karr keeps its own config version, not kanban-md's" );
};

subtest 'a karr-only override the view cannot carry survives the round trip' => sub {
  # lock_timeout is karr's alone -- kanban-md's schema has no such key, so its
  # rewrite drops it exactly the way it drops foundation. Same bug, same fix.
  my $repo = _materialized_board( [ 'config', 'set', 'lock_timeout', '30m' ] );
  _kanban_md_rewrote($repo);

  is( _run_karr( $repo, 'import', '--yes' )->{exit}, 0, 'import --yes exits 0' );
  is( _overrides($repo)->{lock_timeout}, '30m',
    'the lock_timeout override is not reset to the default' );
};

subtest 'a real edit in the file view still lands' => sub {
  # The reconcile must not turn import into a no-op: whatever the view carries
  # and karr models is still the view's to change.
  my $repo = _materialized_board( [ 'disable', '--reason', 'abandoned driver' ] );
  my $config = path($repo)->child('config.yml');
  my $yaml   = $config->slurp_utf8;
  $yaml =~ s/name: Round Trip/name: Renamed By Hand/
    or die 'fixture no longer carries the board name';
  $yaml =~ s/^  priority: medium$/  priority: high/m
    or die 'fixture no longer carries defaults.priority';
  $config->spew_utf8($yaml);

  is( _run_karr( $repo, 'import', '--yes' )->{exit}, 0, 'import --yes exits 0' );

  my $after = _overrides($repo);
  is( $after->{board}{name}, 'Renamed By Hand', 'the renamed board lands' );
  is( $after->{defaults}{priority}, 'high',     'the changed default lands' );
  is( _foundation_enabled($repo), 0,
    'and the key the view never carried is still preserved' );
};

subtest 'a config.yml that is not a mapping is still refused' => sub {
  # Reading the view as a set of changes must not turn "this file is broken"
  # into "this file said nothing" -- the import still aborts, board untouched.
  my $repo = _materialized_board();
  path($repo)->child('config.yml')->spew_utf8("- not\n- a mapping\n");

  my $rv = _run_karr( $repo, 'import', '--yes' );
  isnt( $rv->{exit}, 0, 'import fails' );
  like( $rv->{stderr}, qr/its config\.yml is not a mapping/,
    'and says what is wrong with the view, not "Not a HASH reference"' );
  unlike( $rv->{stderr}, qr/Not a HASH reference/,
    'no bare dereference error' );
  is( _overrides($repo)->{board}{name}, 'Round Trip',
    'the board config is untouched' );
};

done_testing;
