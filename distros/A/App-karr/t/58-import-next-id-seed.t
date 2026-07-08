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
use App::karr::Task;

# Ticket #30: `karr import` deliberately does not require an existing board, so
# a kanban-md tasks/ view can bootstrap a fresh repo. serialize_from used to
# leave refs/karr/meta/next-id untouched, so on a boardless repo the ref was
# missing and the next `karr create` re-allocated from 1 -- colliding with the
# just-imported ids. serialize_from now seeds next-id past the highest imported
# id when the stored next-id is missing or stale, while leaving a next-id that
# is already ahead of the imported ids alone.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
  my ( $cwd, $stdin, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );

  print {$in} $stdin if defined $stdin;
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

# Lay down a bare kanban-md tasks/ view (no refs yet) carrying the given ids.
sub _write_view {
  my ( $repo, @ids ) = @_;
  my $tasks = path($repo)->child('tasks');
  $tasks->mkpath;
  for my $id (@ids) {
    App::karr::Task->new(
      id       => $id,
      title    => "Imported task $id",
      status   => 'backlog',
      priority => 'medium',
      class    => 'standard',
    )->save($tasks);
  }
  return $tasks;
}

subtest 'import into a fresh repo seeds next-id past the imported ids' => sub {
  my $repo = _init_repo();
  _write_view( $repo, 1, 2, 3 );

  my $git = App::karr::Git->new( dir => $repo );
  ok( !$git->ref_exists('refs/karr/meta/next-id'), 'fresh repo has no next-id ref' );

  my $imp = _run_karr( $repo, undef, 'import', '--yes' );
  is( $imp->{exit}, 0, 'import --yes into a boardless repo exits 0' );

  my $created = _run_karr( $repo, undef, 'create', 'Fresh task' );
  is( $created->{exit}, 0, 'create after bootstrap import exits 0' );
  like( $created->{stdout}, qr/Created task 4:/,
    'the next create gets id 4, not a duplicate of an imported id' );

  is_deeply( [ $git->list_task_refs ], [ 1, 2, 3, 4 ],
    'no id collision: the imported ids and the new id are all distinct' );
};

subtest 'import does not lower a next-id that is already ahead of the view' => sub {
  my $repo  = _init_repo();
  my $git   = App::karr::Git->new( dir => $repo );
  my $store = App::karr::BoardStore->new( git => $git );

  # A board that burned ids up to 9 (next free = 10) but now only holds tasks
  # 1..3 (ids 4..9 were deleted; ids are never reused). Importing that view
  # must not clobber the healthy next-id back down to 4.
  $store->set_next_id(10);
  _write_view( $repo, 1, 2, 3 );

  $store->serialize_from( path($repo)->stringify );

  is( $store->peek_next_id, 10,
    'a healthy next-id ahead of the imported ids is left untouched' );
};

subtest 'import bumps a stale next-id that would collide with the view' => sub {
  my $repo  = _init_repo();
  my $git   = App::karr::Git->new( dir => $repo );
  my $store = App::karr::BoardStore->new( git => $git );

  # next-id says 2 but the view carries ids up to 5 (e.g. an external edit that
  # added higher-numbered cards). Import must seed next-id past the highest id.
  $store->set_next_id(2);
  _write_view( $repo, 1, 2, 3, 4, 5 );

  $store->serialize_from( path($repo)->stringify );

  is( $store->peek_next_id, 6,
    'a next-id at or below the highest imported id is bumped past it' );
};

done_testing;
