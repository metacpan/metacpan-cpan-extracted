# t/113-native-index-tracked-under.t
#
# Ticket #107: App::karr::Git::is_tracked_under answers "does the project
# already own content at or under this path" -- the question `karr init` and
# `karr materialize` ask before claiming tasks/ and config.yml in .gitignore
# (#89, #100, #104). It used to be answered by `git ls-files` unconditionally,
# because the Git::Native of the day exposed no index at all: not a fallback
# from a native attempt, but the only route there was.
#
# CLAUDE.md describes the Git layer as local operations native via libgit2 with
# a git-CLI fallback for remote transport, and the CLI-only route broke that in
# a way with a visible symptom: with no `git` on PATH the run failed, the answer
# came back "not tracked", ownership degraded to unowned and `karr init` wrote
# .gitignore entries over paths the project owns -- undoing #89 in that
# configuration. Git::Native::Index (Git::Native 0.005, Git::Libgit2 0.006)
# answers the same question through libgit2, so the native route needs no `git`
# binary and the CLI is the fallback it was documented to be.
#
# What is asserted here is therefore both halves: that the native route answers
# alone (no CLI run at all, and correctly with PATH emptied), and that the CLI
# still answers when libgit2 declines.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use Config;
use Cwd qw( abs_path getcwd );
use File::Temp qw( tempdir );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Path::Tiny qw( path );

use App::karr::Git;
use Git::Native;

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";
my $PERL = ( $^X =~ m{/} && -x $^X ) ? $^X : $Config{perlpath};

# A repository tracking @files, each committed with a line of project content.
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

# Every _run_git this records is a git-CLI run that the native route was
# supposed to make unnecessary. Returns the shape _run_git promises, with the
# 'start' failure a missing binary produces, so is_tracked_under carries on
# down its own fallback path instead of dying inside the stub.
sub trap_cli {
  my ($seen) = @_;
  return sub {
    my ( $self, @args ) = @_;
    push @$seen, join( ' ', @args );
    return { ok => 0, failure => 'start', status => 0,
             out => '', err => 'stubbed away', timeout => 0 };
  };
}

subtest 'the index answers the path question, with no git CLI run at all' => sub {
  my $repo = repo_with( 'tasks/notes/backlog.md', 'README.md' );
  my $git  = App::karr::Git->new( dir => $repo );

  my @cli;
  no warnings 'redefine';
  local *App::karr::Git::_run_git = trap_cli( \@cli );

  is( $git->is_tracked_under("$repo/README.md"), 1, 'a tracked file answers for itself' );
  is( $git->is_tracked_under("$repo/tasks"), 1,
    'a directory answers for a file nested under it' );
  is( $git->is_tracked_under("$repo/tasks/notes/backlog.md"), 1,
    'as does the nested file itself' );
  is( $git->is_tracked_under("$repo/config.yml"), 0, 'an untracked path answers false' );
  is( $git->is_tracked_under("$repo/nowhere/at/all"), 0,
    'and so does one nothing was ever at' );

  is_deeply( \@cli, [], 'the git CLI was never reached' )
    or diag( "ran: " . join( ' | ', @cli ) );
};

subtest 'a directory is a path question, not a string prefix' => sub {
  # The trap the native route has to avoid: the index is a sorted list of
  # strings, and 'tasksfoo.txt' begins with 'tasks'. `git ls-files -- tasks`
  # never matched it, so the answer must not start doing so now.
  my $repo = repo_with('tasksfoo.txt');
  my $git  = App::karr::Git->new( dir => $repo );

  my @cli;
  no warnings 'redefine';
  local *App::karr::Git::_run_git = trap_cli( \@cli );

  is( $git->is_tracked_under("$repo/tasksfoo.txt"), 1, 'the tracked file answers' );
  is( $git->is_tracked_under("$repo/tasks"), 0,
    'but it does not make tasks/ the project\'s' );
  is_deeply( \@cli, [], 'still no git CLI run' );
};

subtest 'a tracked file gone from the working tree still answers true' => sub {
  # The #104 property, now native: the index still carries the entry for a
  # path rm'd without staging the deletion, and that is what makes the answer
  # an index question rather than a working-tree one (is_tracked, which is a
  # working-tree comparison, cannot see it).
  my $repo = repo_with('tasks/deploy-runbook.md');
  path($repo)->child('tasks/deploy-runbook.md')->remove;
  is( scalar path($repo)->child('tasks')->children, 0,
    'nothing is left on disk under tasks/' );

  my $git = App::karr::Git->new( dir => $repo );
  my @cli;
  no warnings 'redefine';
  local *App::karr::Git::_run_git = trap_cli( \@cli );

  is( $git->is_tracked_under("$repo/tasks"), 1, 'the index still owns tasks/' );
  is( $git->is_tracked_under("$repo/tasks/deploy-runbook.md"), 1,
    'and the missing file itself' );
  is( $git->is_tracked_under("$repo/tasks/never-existed.md"), 0,
    'without answering for a path it never had' );
  is_deeply( \@cli, [], 'no git CLI run' );
};

subtest 'a path outside the work tree, and a repository that is not one' => sub {
  my $repo    = repo_with('README.md');
  my $git     = App::karr::Git->new( dir => $repo );
  my $outside = tempdir( CLEANUP => 1 );
  path($outside)->child('README.md')->spew_utf8("someone else's\n");
  is( $git->is_tracked_under("$outside/README.md"), 0,
    'a path outside the work tree answers false' );

  my $plain = tempdir( CLEANUP => 1 );
  path($plain)->child('README.md')->spew_utf8("not a repo\n");
  my $nogit = App::karr::Git->new( dir => $plain );

  my @cli;
  no warnings 'redefine';
  local *App::karr::Git::_run_git = trap_cli( \@cli );
  is( $nogit->is_tracked_under("$plain/README.md"), 0,
    'a repository that cannot be opened answers false, as is_tracked does' );
  is_deeply( \@cli, [], 'and asks no CLI about it either' );
};

subtest 'no git binary on PATH: the index answers anyway' => sub {
  my $repo = repo_with( 'tasks/notes/backlog.md', 'config.yml' );
  my $git  = App::karr::Git->new( dir => $repo );

  local $ENV{PATH} = '';
  is( $git->is_tracked_under("$repo/tasks"), 1, 'tasks/ is still the project\'s' );
  is( $git->is_tracked_under("$repo/config.yml"), 1, 'and so is config.yml' );
  is( $git->is_tracked_under("$repo/elsewhere"), 0, 'an untracked path still answers false' );
};

subtest 'no git binary on PATH: init still leaves the project\'s .gitignore alone' => sub {
  # The user-visible regression the CLI-only route caused. `git ls-files` could
  # not run, is_tracked_under answered "not tracked", ownership degraded to
  # unowned, and init wrote the entries for paths git already tracks -- exactly
  # the misleading claim #89 removed.
  plan skip_all => "no usable perl path to run bin/karr with an empty PATH"
    unless defined $PERL && -x $PERL;

  my $repo = repo_with('tasks/deploy-runbook.md');
  my $old  = getcwd();
  chdir $repo or die "chdir $repo: $!";

  my ( $stdout, $exit );
  {
    local $ENV{PATH} = '';
    my $stderr = gensym;
    my $pid = open3( undef, my $out, $stderr, $PERL, "-I$ROOT/lib", $BIN,
      'init', '--name', 'NoPath' );
    $stdout = do { local $/; <$out> };
    my $errtext = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    $exit = $? >> 8;
    diag($errtext) if $exit && defined $errtext;
  }
  chdir $old or die "chdir $old: $!";

  is( $exit, 0, 'init succeeds without a git binary in sight' );
  ok( !path($repo)->child('.gitignore')->exists,
    'and claimed nothing in .gitignore' );
  like( $stdout // '', qr{Left \.gitignore alone},
    'naming what it did not do' ) or diag( $stdout // '' );
};

subtest 'the git CLI answers when libgit2 declines the index' => sub {
  # The fallback, exercised the only way it can be reached: with the native
  # read failing. A Git::Native too old to have ->index at all fails the same
  # way, as a method that is not there.
  my $repo = repo_with( 'tasks/notes/backlog.md', 'config.yml' );
  my $git  = App::karr::Git->new( dir => $repo );

  my $trap     = repo_with('tasksfoo.txt');
  my $trap_git = App::karr::Git->new( dir => $trap );

  no warnings 'redefine';
  local *Git::Native::Repository::index = sub { die "index unreadable\n" };

  is( $git->is_tracked_under("$repo/tasks"), 1, 'tasks/ answers through the CLI' );
  is( $git->is_tracked_under("$repo/config.yml"), 1, 'as does the tracked file' );
  is( $git->is_tracked_under("$repo/elsewhere"), 0, 'an untracked path answers false' );
  is( $trap_git->is_tracked_under("$trap/tasks"), 0,
    'and the CLI walks into no prefix trap either' );
  like( $git->last_error, qr/index unreadable/,
    'with last_error carrying why the native read was abandoned' );
};

subtest 'neither route available answers false rather than dying' => sub {
  my $repo = repo_with('tasks/notes/backlog.md');
  my $git  = App::karr::Git->new( dir => $repo );

  no warnings 'redefine';
  local *Git::Native::Repository::index = sub { die "index unreadable\n" };
  local $ENV{PATH} = '';

  is( $git->is_tracked_under("$repo/tasks"), 0,
    'not-tracked-as-far-as-we-can-tell, the same answer an unopenable repo gets' );
};

done_testing;
