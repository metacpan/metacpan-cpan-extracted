use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use App::karr::Git;
use App::karr::Task;

# TDD red step for Bug B (ticket #31): App::karr::Git does every remote op
# (push/pull/push_ref/pull_ref/fetch) purely natively via Git::Native/libgit2,
# which cannot honour ssh_config/ProxyCommand. The fix (not yet implemented)
# adds a private helper:
#
#   $self->_cli_transport($verb, $remote, $refspecs, %opt)
#
# which shells out to `git -C <dir> <verb> [--prune] <remote> @refspecs`,
# returns 1 on exit 0 (0 + last_error set to the CLI stderr otherwise), and
# is disabled unconditionally when $ENV{KARR_NO_CLI_FALLBACK} is set. It is
# meant to be called from the catch block of the five transport methods.
#
# None of this exists yet, so every subtest below is expected to fail with
# "Can't locate object method \"_cli_transport\" via package \"App::karr::Git\"".

# ---------------------------------------------------------------------
# Helper: bare "remote" repo + a working-copy repo with `origin` pointed at
# it, following the setup in t/19-git-push-fetch.t:11-27.
# ---------------------------------------------------------------------
sub _make_bare_and_repo {
  my $bare = tempdir( CLEANUP => 1 );
  system("git init --bare '$bare' 2>/dev/null");

  my $repo = tempdir( CLEANUP => 1 );
  system("git init '$repo' 2>/dev/null");
  system("git -C '$repo' config user.email 'cli-fallback\@test.com'");
  system("git -C '$repo' config user.name 'CLI Fallback Test'");
  system("git -C '$repo' remote add origin '$bare'");
  # Need at least one commit for the default-branch push below to work.
  system("git -C '$repo' commit --allow-empty -m 'init' 2>/dev/null");
  my $branch = `git -C '$repo' rev-parse --abbrev-ref HEAD 2>/dev/null`;
  chomp $branch;
  system("git -C '$repo' push origin $branch 2>/dev/null");

  return ( $bare, $repo );
}

# ---------------------------------------------------------------------
# Subtest 1 (PRIMARY): _cli_transport, called directly, actually moves a
# refs/karr/* ref through a real bare remote (push from A, fetch into B).
# This is the deterministic proof that the CLI path really transports data,
# not just that it returns a truthy value.
# ---------------------------------------------------------------------
subtest 'PRIMARY: _cli_transport pushes and fetches refs/karr/* via a real bare remote' => sub {
  my ( $bare, $repo_a ) = _make_bare_and_repo();
  my $git_a = App::karr::Git->new( dir => $repo_a );

  my $task = App::karr::Task->new(
    id => 1, title => 'CLI push test', status => 'todo',
    priority => 'high', class => 'standard', body => 'Test body',
  );
  $git_a->save_task_ref($task);

  ok $git_a->_cli_transport(
    'push', 'origin', ['+refs/karr/*:refs/karr/*'], prune => 1,
  ), 'CLI push returns true';

  # Second working copy cloned from the same bare remote — proves the ref
  # really landed on the bare repo, not just that the call "succeeded".
  my $repo_b = tempdir( CLEANUP => 1 );
  system("git clone '$bare' '$repo_b' 2>/dev/null");
  system("git -C '$repo_b' config user.email 'b\@test.com'");
  system("git -C '$repo_b' config user.name 'Agent B'");
  my $git_b = App::karr::Git->new( dir => $repo_b );

  ok $git_b->_cli_transport(
    'fetch', 'origin', ['refs/karr/*:refs/karr/*'],
  ), 'CLI fetch returns true';

  my $fetched = $git_b->load_task_ref(1);
  ok $fetched, 'agent B can load the task ref transported by the CLI fallback';
  SKIP: {
    skip 'task ref did not transfer', 1 unless $fetched;
    is $fetched->title, 'CLI push test', 'fetched task has correct title';
  }
};

# ---------------------------------------------------------------------
# Subtest 2: broken remote -> _cli_transport must fail cleanly and record
# an error naming the CLI fallback (mirrors t/35-sync-error.t's shape).
# ---------------------------------------------------------------------
subtest 'negative: _cli_transport fails on a broken remote and records last_error' => sub {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'remote', 'add', 'origin', '/nonexistent/karr-bogus.git' );
  my $git = App::karr::Git->new( dir => $repo );

  ok !$git->_cli_transport(
    'push', 'origin', ['+refs/karr/*:refs/karr/*'], prune => 1,
  ), 'CLI push returns false on broken remote';

  like $git->last_error, qr/CLI fallback/, 'last_error names the CLI fallback';
};

# ---------------------------------------------------------------------
# Subtest 3: KARR_NO_CLI_FALLBACK is a hard kill-switch, even against a
# perfectly working remote.
# ---------------------------------------------------------------------
subtest 'opt-out: KARR_NO_CLI_FALLBACK disables the fallback even with a working remote' => sub {
  my ( $bare, $repo ) = _make_bare_and_repo();
  my $git = App::karr::Git->new( dir => $repo );

  local $ENV{KARR_NO_CLI_FALLBACK} = 1;

  ok !$git->_cli_transport(
    'push', 'origin', ['+refs/karr/*:refs/karr/*'], prune => 1,
  ), 'kill-switch disables the fallback (returns 0)';
};

# ---------------------------------------------------------------------
# Subtest 4 (SECONDARY, end-to-end catch-wiring): proves that
# App::karr::Git->push falls back to the CLI automatically when the native
# libgit2 transport throws, and that the fallback's ref really lands on the
# bare remote.
#
# Seam check performed before writing this: Git::Native::Remote (installed
# at .../perl5/Git/Native/Remote.pm, Git::Native 0.004) is a plain Moo
# class. `push` and `fetch` are ordinary named Perl subs in that package
# (they call out to Git::Libgit2::FFI internally, but the sub bodies
# themselves are regular Perl, not XS) and `Repository::remote()` blesses
# directly into Git::Native::Remote with no subclassing. That makes
# `local *Git::Native::Remote::push = sub { die ... }` a safe, standard
# glob-local override for the lifetime of this subtest — Perl restores the
# original sub on scope exit. So the seam is stable and this subtest is
# included.
# ---------------------------------------------------------------------
subtest 'SECONDARY: push() falls back to the CLI automatically when libgit2 throws' => sub {
  my ( $bare, $repo_a ) = _make_bare_and_repo();
  my $git_a = App::karr::Git->new( dir => $repo_a );

  my $task = App::karr::Task->new(
    id => 2, title => 'End to end fallback', status => 'todo',
    priority => 'high', class => 'standard', body => 'e2e body',
  );
  $git_a->save_task_ref($task);

  no warnings 'redefine';
  local *Git::Native::Remote::push = sub { die "forced libgit2 failure\n" };

  ok $git_a->push, 'push succeeds via CLI fallback after native transport throws';

  my $repo_b = tempdir( CLEANUP => 1 );
  system("git clone '$bare' '$repo_b' 2>/dev/null");
  my $git_b = App::karr::Git->new( dir => $repo_b );

  ok $git_b->pull, 'agent B pulls the ref that only the CLI fallback could have pushed';
  my $fetched = $git_b->load_task_ref(2);
  ok $fetched, 'ref landed on the bare remote via the CLI fallback path';
  SKIP: {
    skip 'task ref did not transfer', 1 unless $fetched;
    is $fetched->title, 'End to end fallback', 'fetched task title matches';
  }
};

done_testing;
