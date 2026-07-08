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
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;
use App::karr::Task;

# Ticket #21: `karr materialize` writes refs/karr/* out as a disposable,
# gitignored kanban-md file view (config.yml + tasks/*.md) and `karr import`
# reads such a view back into refs. materialize reads only (no sync); import
# mutates refs, so it needs a --yes guard and preserves task timestamps
# verbatim (the serialize_from path pinned by t/39).

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

sub _init_board {
  my ( $name, @tasks ) = @_;
  my $repo = _init_repo();
  is( _run_karr( $repo, undef, 'init', '--name', $name )->{exit}, 0, "board '$name' initialized" );
  for my $t (@tasks) {
    is( _run_karr( $repo, undef, 'create', @$t )->{exit}, 0, "created: $t->[0]" );
  }
  return $repo;
}

subtest 'materialize writes a kanban-md file view that round-trips the refs' => sub {
  my $repo = _init_board( 'View Board',
    [ 'First task', '--priority', 'high' ],
    [ 'Second task' ],
  );

  my $rv = _run_karr( $repo, undef, 'materialize' );
  is( $rv->{exit}, 0, 'materialize exits 0' );
  like( $rv->{stderr}, qr/Materialized 2 task\(s\)/, 'reports the number of tasks written' );

  my $root = path($repo);
  ok( $root->child('config.yml')->exists, 'config.yml written at the board root' );
  like( $root->child('config.yml')->slurp_utf8, qr/View Board/, 'config.yml carries the board name' );

  my @files = sort map { $_->basename } $root->child('tasks')->children(qr/\.md$/);
  is_deeply( \@files, [ '001-first-task.md', '002-second-task.md' ], 'both cards materialized as files' );

  my $t1 = App::karr::Task->from_file( $root->child('tasks')->child('001-first-task.md') );
  is( $t1->id,       1,            'materialized file has the ref id' );
  is( $t1->title,    'First task', 'materialized file round-trips the title from refs' );
  is( $t1->priority, 'high',       'materialized file round-trips the priority from refs' );
};

subtest 'materialize --json always emits a task array' => sub {
  my $repo = _init_board( 'Json Board', [ 'Only task' ] );

  my $rv = _run_karr( $repo, undef, 'materialize', '--json' );
  is( $rv->{exit}, 0, 'materialize --json exits 0' );

  my $data = decode_json( $rv->{stdout} );
  is( ref $data, 'ARRAY', 'a one-task board still yields an array, not a bare object' );
  is( scalar @$data, 1, 'one task in the payload' );
  is( $data->[0]{id},    1,           'task id present in json' );
  is( $data->[0]{title}, 'Only task', 'task title present in json' );
};

subtest 'materialize refuses on a repo without a board' => sub {
  my $repo = _init_repo();
  my $rv = _run_karr( $repo, undef, 'materialize' );
  isnt( $rv->{exit}, 0, 'materialize on an uninitialized repo fails' );
  like( $rv->{stderr}, qr/No karr board found/, 'explains that no board exists' );
};

subtest 'import requires --yes and is a no-op on refs without it' => sub {
  my $repo = _init_board( 'Guard Board', [ 'Keep me' ] );
  is( _run_karr( $repo, undef, 'materialize' )->{exit}, 0, 'view materialized' );

  # Edit the file view so we can prove nothing lands without --yes.
  my $file = ( path($repo)->child('tasks')->children(qr/\.md$/) )[0];
  my $edited = $file->slurp_utf8;
  $edited =~ s/Keep me/Renamed away/;
  $file->spew_utf8($edited);

  my $rv = _run_karr( $repo, undef, 'import' );
  isnt( $rv->{exit}, 0, 'import without --yes fails' );
  like( $rv->{stderr}, qr/--yes/, 'stderr tells the user to re-run with --yes' );

  my $show = _run_karr( $repo, undef, 'show', '1', '--json' );
  my $task = decode_json( $show->{stdout} );
  is( $task->{title}, 'Keep me', 'the refused import did not change the ref' );
};

subtest 'import --yes reads the edited file view back into refs' => sub {
  my $repo = _init_board( 'Import Board', [ 'Before' ] );
  is( _run_karr( $repo, undef, 'materialize' )->{exit}, 0, 'view materialized' );

  my $file = ( path($repo)->child('tasks')->children(qr/\.md$/) )[0];
  my $edited = $file->slurp_utf8;
  $edited =~ s/Before/After/;
  $file->spew_utf8($edited);

  my $rv = _run_karr( $repo, undef, 'import', '--yes' );
  is( $rv->{exit}, 0, 'import --yes exits 0' );
  like( $rv->{stderr}, qr/Imported 1 task\(s\)/, 'reports the number of tasks imported' );

  my $show = _run_karr( $repo, undef, 'show', '1', '--json' );
  my $task = decode_json( $show->{stdout} );
  is( $task->{title}, 'After', 'the edit in the file view landed in refs' );
};

subtest 'import preserves task timestamps verbatim' => sub {
  my $repo = _init_board( 'Stamp Board', [ 'Timeless' ] );
  is( _run_karr( $repo, undef, 'materialize' )->{exit}, 0, 'view materialized' );

  # Backdate the materialized card's `updated` stamp; a faithful import must
  # not bump it (this is the serialize_from contract pinned by t/39).
  my $backdated = '2020-01-01T00:00:00Z';
  my $file = ( path($repo)->child('tasks')->children(qr/\.md$/) )[0];
  my $edited = $file->slurp_utf8;
  $edited =~ s/^updated:.*$/updated: $backdated/m;
  $file->spew_utf8($edited);

  is( _run_karr( $repo, undef, 'import', '--yes' )->{exit}, 0, 'import --yes exits 0' );

  my $show = _run_karr( $repo, undef, 'show', '1', '--json' );
  my $task = decode_json( $show->{stdout} );
  is( $task->{updated}, $backdated, 'import kept the original updated timestamp' );
};

subtest 'import mirrors deletions from the file view' => sub {
  my $repo = _init_board( 'Delete Board',
    [ 'Stays' ],
    [ 'Goes away' ],
  );
  is( _run_karr( $repo, undef, 'materialize' )->{exit}, 0, 'view materialized' );

  # Drop the second card from the view, then import: the matching ref must go.
  path($repo)->child('tasks')->child('002-goes-away.md')->remove;

  is( _run_karr( $repo, undef, 'import', '--yes' )->{exit}, 0, 'import --yes exits 0' );

  my $git = App::karr::Git->new( dir => $repo );
  is_deeply( [ $git->list_task_refs ], [1], 'the removed card is dropped from refs, the kept one stays' );
};

subtest 'import refuses when there is no tasks/ view (never wipes refs)' => sub {
  my $repo = _init_board( 'No View Board', [ 'Survivor' ] );

  # No materialize: there is no tasks/ directory to import from.
  my $rv = _run_karr( $repo, undef, 'import', '--yes' );
  isnt( $rv->{exit}, 0, 'import with no file view fails instead of running' );
  like( $rv->{stderr}, qr/tasks\/ directory/, 'stderr explains the missing view' );

  my $git = App::karr::Git->new( dir => $repo );
  is_deeply( [ $git->list_task_refs ], [1], 'the existing task ref was not wiped by the aborted import' );
};

done_testing;
