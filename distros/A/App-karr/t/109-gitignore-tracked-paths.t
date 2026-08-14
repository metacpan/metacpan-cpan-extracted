# t/109-gitignore-tracked-paths.t
#
# Ticket #89: `karr init` appended `tasks/` and `config.yml` to .gitignore
# unconditionally. Both are perfectly ordinary names for a project to already
# use at its repository root, and git applies no ignore rule to a file it
# already tracks -- so the entry changed nothing at all while telling every
# later reader that karr owns a path the project owns.
#
# It misled in exactly the place it hurts: since ticket #48 `karr materialize`
# refuses to overwrite tracked files, so such a repo gets a refusal from a
# command whose .gitignore entry says the path is karr's to write.
#
# `tasks/` is a directory, and App::karr::Git::is_tracked answers for files --
# libgit2's status_for_path has nothing to say about a directory -- so init
# answers it by its contents.
#
# Ticket #100: `karr materialize` writes the same two entries after writing the
# view, and went on doing it unconditionally -- putting back the exact claim
# init had just declined to make. Both commands now ask the one question, via
# App::karr::BoardStore::project_owned_view_paths.
#
# Ticket #104: that question used to be answered by walking the working tree
# and asking git one is_tracked per file found -- linear in card count, and
# blind to a path git tracks but that is currently missing from the working
# tree (rm'd, not yet committed), because there is no file there to walk onto.
# project_owned_view_paths now asks the index directly, via
# App::karr::Git::is_tracked_under, which answers both problems in one call.

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

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub run_karr {
  my ( $cwd, @argv ) = @_;
  my $old = getcwd();
  chdir $cwd or die "chdir $cwd: $!";

  my $stderr = gensym;
  my $pid = open3( undef, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );

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

sub repo_with {
  my (@files) = @_;
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
    or BAIL_OUT('git config failed');
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
    or BAIL_OUT('git config failed');

  for my $rel (@files) {
    my $file = path($repo)->child($rel);
    $file->parent->mkpath;
    $file->spew_utf8("project content\n");
    system( 'git', '-C', $repo, 'add', $rel ) == 0 or BAIL_OUT("git add $rel failed");
  }
  if (@files) {
    system( 'git', '-C', $repo, 'commit', '-q', '-m', 'project content' ) == 0
      or BAIL_OUT('git commit failed');
  }
  return $repo;
}

sub gitignore_of {
  my ($repo) = @_;
  my $file = path($repo)->child('.gitignore');
  return $file->exists ? $file->slurp_utf8 : undef;
}

subtest 'a repo that owns neither path still gets both entries' => sub {
  my $repo = repo_with();
  my $rv   = run_karr( $repo, 'init', '--name', 'Clean' );
  is( $rv->{exit}, 0, 'init succeeds' ) or diag( $rv->{stderr} );

  my $ignore = gitignore_of($repo);
  ok( defined $ignore, '.gitignore was written' );
  like( $ignore, qr{^tasks/$}m,    'tasks/ is ignored' );
  like( $ignore, qr{^config\.yml$}m, 'config.yml is ignored' );
  like( $rv->{stdout}, qr/Added \.gitignore entries/, 'and init says so' );
};

subtest 'an untracked file at those paths is not the project owning them' => sub {
  # On disk but never added: git would ignore it, and karr's file view is
  # entitled to replace it. This is the ordinary case and must not change.
  my $repo = repo_with();
  path($repo)->child('tasks')->mkpath;
  path($repo)->child('tasks/scratch.md')->spew_utf8("scratch\n");
  path($repo)->child('config.yml')->spew_utf8("scratch\n");

  my $rv = run_karr( $repo, 'init', '--name', 'Untracked' );
  is( $rv->{exit}, 0, 'init succeeds' ) or diag( $rv->{stderr} );
  like( gitignore_of($repo), qr{^tasks/$}m, 'the entries are still added' );
};

subtest 'a tracked config.yml stops karr claiming the paths' => sub {
  my $repo = repo_with('config.yml');
  my $rv   = run_karr( $repo, 'init', '--name', 'Collide' );

  is( $rv->{exit}, 0, 'init still succeeds -- this is not an error' )
    or diag( $rv->{stderr} );
  is( gitignore_of($repo), undef, 'no .gitignore was invented' );
  like( $rv->{stdout}, qr/Left \.gitignore alone/,
    'and init says what it did not do' )
    or diag( $rv->{stdout} );
  like( $rv->{stdout}, qr/config\.yml/, 'naming the path the project owns' );
};

subtest 'a tracked file anywhere under tasks/ counts' => sub {
  # is_tracked cannot answer for the directory itself, so this is the case
  # that decides whether init looked inside it -- and nested, because project
  # content does not have to sit at the top of the directory.
  my $repo = repo_with('tasks/notes/backlog.md');
  my $rv   = run_karr( $repo, 'init', '--name', 'Collide' );

  is( $rv->{exit}, 0, 'init still succeeds' ) or diag( $rv->{stderr} );
  is( gitignore_of($repo), undef, 'no .gitignore was invented' );
  like( $rv->{stdout}, qr{tasks/}, 'init names tasks/ as the project\'s' )
    or diag( $rv->{stdout} );
};

subtest 'an existing .gitignore is left exactly as it was' => sub {
  my $repo = repo_with('config.yml');
  my $file = path($repo)->child('.gitignore');
  $file->spew_utf8("*.log\nbuild/\n");

  my $rv = run_karr( $repo, 'init', '--name', 'Collide' );
  is( $rv->{exit}, 0, 'init succeeds' ) or diag( $rv->{stderr} );
  is( $file->slurp_utf8, "*.log\nbuild/\n",
    'the project\'s own .gitignore is untouched' );
};

subtest 'no .gitignore rule contradicts what materialize will do' => sub {
  # The pairing the ticket is really about: materialize refuses to write the
  # path (ticket #48), so nothing karr wrote may claim it. Asserted against
  # git's own answer rather than against karr's opinion of it -- git applies no
  # ignore rule to a tracked file, which is what made the entry inert and
  # therefore misleading rather than merely wrong.
  my $repo = repo_with('config.yml');
  run_karr( $repo, 'init', '--name', 'Collide' );

  my $rv = run_karr( $repo, 'materialize' );
  isnt( $rv->{exit}, 0, 'materialize refuses to overwrite the project file' );
  like( $rv->{stderr}, qr/config\.yml/, 'naming it' );

  my $rc = system( 'git', '-C', $repo, 'check-ignore', '-q', 'config.yml' );
  isnt( $rc, 0, 'git ignores nothing at that path' );
  unlike( gitignore_of($repo) // '', qr{^config\.yml$}m,
    'so karr never claimed it in .gitignore either' );
};

# --------------------------------------------------------------- ticket #100

subtest 'materialize does not claim a tasks/ the project tracks' => sub {
  # The project file is not card-shaped, so the #48 refusal has nothing to say
  # about it: materialize runs to completion, which is exactly the path on
  # which it used to append the entries init had refused to write.
  my $repo = repo_with('tasks/deploy-runbook.md');
  is( run_karr( $repo, 'init', '--name', 'Collide' )->{exit}, 0, 'board initialized' );
  is( run_karr( $repo, 'create', 'A task' )->{exit}, 0, 'task created' );
  is( gitignore_of($repo), undef, 'init claimed nothing, as of #89' );

  my $rv = run_karr( $repo, 'materialize' );
  is( $rv->{exit}, 0, 'materialize succeeds' ) or diag( $rv->{stderr} );
  is( gitignore_of($repo), undef, 'and did not claim the path either' );
  like( $rv->{stderr}, qr/Left \.gitignore alone/,
    'materialize says what it did not do' )
    or diag( $rv->{stderr} );
  like( $rv->{stderr}, qr{tasks/}, 'naming the path the project owns' );

  is( path($repo)->child('tasks/deploy-runbook.md')->slurp_utf8, "project content\n",
    "the project's own file is untouched" );
};

subtest 'materialize still writes the entries when the paths are karr\'s' => sub {
  # The ordinary case, and the one an over-eager fix would break. init has
  # already written the entries here, so remove them first: what is under test
  # is materialize's own append, not an idempotent no-op.
  my $repo = repo_with();
  is( run_karr( $repo, 'init', '--name', 'Clean' )->{exit}, 0, 'board initialized' );
  path($repo)->child('.gitignore')->remove;

  my $rv = run_karr( $repo, 'materialize' );
  is( $rv->{exit}, 0, 'materialize succeeds' ) or diag( $rv->{stderr} );
  like( gitignore_of($repo), qr{^tasks/$}m,      'tasks/ is ignored' );
  like( gitignore_of($repo), qr{^config\.yml$}m, 'config.yml is ignored' );
  like( $rv->{stderr}, qr/Added \.gitignore entries/, 'and materialize says so' )
    or diag( $rv->{stderr} );
};

subtest 'a tracked card that --force sweeps away is still the project\'s' => sub {
  # This one pins the ordering. --force deletes the tracked card before
  # .gitignore is touched, so a check made afterwards walks an emptied tasks/
  # and concludes the project owns nothing there -- while git still tracks the
  # path and would still apply no ignore rule to it.
  my $repo = repo_with('tasks/001-legacy-card.md');
  is( run_karr( $repo, 'init', '--name', 'Forced' )->{exit}, 0, 'board initialized' );
  is( run_karr( $repo, 'create', 'A task' )->{exit}, 0, 'task created' );

  my $rv = run_karr( $repo, 'materialize', '--force' );
  is( $rv->{exit}, 0, 'materialize --force goes through' ) or diag( $rv->{stderr} );
  ok( !path($repo)->child('tasks/001-legacy-card.md')->exists,
    'the tracked card was swept, which is what --force asks for' );
  is( gitignore_of($repo), undef, 'and karr still claimed nothing' );
};

# --------------------------------------------------------------- ticket #104

subtest 'a tracked file removed from disk, uncommitted, still stops init claiming tasks/' => sub {
  # The gap the old check documented as known: the project tracks
  # tasks/deploy-runbook.md, but it has been rm'd from the working tree
  # without staging or committing the deletion. A directory walk has no file
  # to find it through -- there is nothing on disk under tasks/ at all -- so
  # the old is_tracked-per-walked-file check saw an empty directory and
  # concluded the project owned nothing there. The index still has the entry.
  my $repo = repo_with('tasks/deploy-runbook.md');
  path($repo)->child('tasks/deploy-runbook.md')->remove;
  ok( !path($repo)->child('tasks/deploy-runbook.md')->exists,
    'the file is gone from the working tree' );
  is( scalar path($repo)->child('tasks')->children, 0,
    'nothing at all is left on disk to walk onto under tasks/' );

  my $rv = run_karr( $repo, 'init', '--name', 'Deleted' );
  is( $rv->{exit}, 0, 'init still succeeds' ) or diag( $rv->{stderr} );
  is( gitignore_of($repo), undef, 'no .gitignore was invented' );
  like( $rv->{stdout}, qr{tasks/},
    'init names tasks/ as the project\'s, despite the missing file' )
    or diag( $rv->{stdout} );
};

subtest 'a tracked config.yml removed from disk, uncommitted, still stops init claiming it' => sub {
  my $repo = repo_with('config.yml');
  path($repo)->child('config.yml')->remove;
  ok( !path($repo)->child('config.yml')->exists, 'nothing is left on disk' );

  my $rv = run_karr( $repo, 'init', '--name', 'DeletedFile' );
  is( $rv->{exit}, 0, 'init still succeeds' ) or diag( $rv->{stderr} );
  is( gitignore_of($repo), undef, 'no .gitignore was invented' );
  like( $rv->{stdout}, qr/config\.yml/, 'naming the path the project owns' );
};

subtest 'materialize does not claim tasks/ when a tracked card was deleted, uncommitted' => sub {
  # Pairs with the plain #100 case above, but the project's file is not just
  # untouched by materialize -- it is not even there for materialize_to's own
  # overwrite guard to see. That guard is unaffected (there is nothing on disk
  # to overwrite), but the .gitignore claim must still be refused, because git
  # still tracks the path.
  my $repo = repo_with('tasks/deploy-runbook.md');
  path($repo)->child('tasks/deploy-runbook.md')->remove;
  is( run_karr( $repo, 'init', '--name', 'Collide' )->{exit}, 0, 'board initialized' );
  is( run_karr( $repo, 'create', 'A task' )->{exit}, 0, 'task created' );
  is( gitignore_of($repo), undef, 'init claimed nothing' );

  my $rv = run_karr( $repo, 'materialize' );
  is( $rv->{exit}, 0, 'materialize succeeds' ) or diag( $rv->{stderr} );
  is( gitignore_of($repo), undef, 'and did not claim the path either' );
  like( $rv->{stderr}, qr/Left \.gitignore alone/,
    'materialize says what it did not do' )
    or diag( $rv->{stderr} );
  like( $rv->{stderr}, qr{tasks/}, 'naming the path the project owns' );
};

done_testing;
