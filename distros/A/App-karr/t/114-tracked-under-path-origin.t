# t/114-tracked-under-path-origin.t
#
# Tickets #113 and #114: one boundary, one contract. App::karr::Git resolves
# every path it hands git through _relative_to_root, which measures from the
# work tree root -- and is_tracked_under then asks that same string of two
# routes, the index natively and `git ls-files` as a fallback. The contract was
# never written down, so each route read it differently and the answer depended
# on which one happened to run:
#
#   #113  _run_git ran `git -C ->dir`, and a pathspec is resolved against the
#         process cwd. Construct this class on a subdirectory -- BoardDiscovery
#         never does, which is why nothing caught it -- and the fallback asked
#         about `subdir/tasks` while the caller asked about `tasks`. `git
#         ls-files` answers a pathspec that matches nothing with exit 0 and no
#         output, which reads back as "not tracked": a project that owns tasks/
#         would be told it does not, and `karr init` would claim the .gitignore
#         entries #89 stopped it claiming.
#
#   #114  the root itself is `.`, a pathspec git understands but not a path the
#         index can hold -- entries are `tasks/a.md`, never `./tasks/a.md`, so
#         neither the exact path nor the `./` prefix matched and the native
#         route answered 0 for a repository full of tracked files.
#
# Agreement alone is not the assertion. Before the fix the two defects cancelled
# for a Git built on a subdirectory and asked about the root: native said 0
# because `.` misses the index, the CLI said 0 because it listed the (empty)
# subdirectory instead of the root, and they agreed on the wrong answer. So each
# case pins the truthful value too, cross-checked against is_tracked where the
# path is a file -- libgit2's status_for_path takes the same $rel and resolves
# it against the work tree by construction, which is the reference this boundary
# has to match.
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use App::karr::Git;
use Git::Native;

# A repository tracking @files at the root, plus an empty, untracked
# sub/deeper/ to build App::karr::Git on.
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
    system( 'git', '-C', $repo, 'add', $rel ) == 0
      or BAIL_OUT("git add $rel failed");
  }
  if (@files) {
    system( 'git', '-C', $repo, 'commit', '-q', '-m', 'project content' ) == 0
      or BAIL_OUT('git commit failed');
  }
  path($repo)->child('sub/deeper')->mkpath;
  return $repo;
}

# is_tracked_under down each route in turn, from a Git built on $dir. The CLI
# route is only reachable with the native one refusing, which is how #113 hid:
# a wrong answer on a path taken exactly when something else is already wrong.
sub both_routes {
  my ( $dir, $path ) = @_;
  my $native = App::karr::Git->new( dir => $dir )->is_tracked_under($path);
  my $cli;
  {
    no warnings 'redefine';
    local *Git::Native::Repository::index = sub { die "index unreadable\n" };
    $cli = App::karr::Git->new( dir => $dir )->is_tracked_under($path);
  }
  return ( $native, $cli );
}

# $want is the truth about $path, and both routes have to arrive at it.
sub routes_agree {
  my ( $dir, $path, $want, $label ) = @_;
  my ( $native, $cli ) = both_routes( $dir, $path );
  is( $native, $want, "$label: native route" );
  is( $cli,    $want, "$label: CLI fallback" );
}

subtest 'a Git built on a subdirectory still answers about the root (#113)' => sub {
  my $repo = repo_with( 'tasks/notes/backlog.md', 'tasksfoo.txt' );

  for my $dir ( "$repo/sub", "$repo/sub/deeper" ) {
    ( my $where = $dir ) =~ s{\Q$repo\E/}{};

    routes_agree( $dir, "$repo/tasks", 1,
      "from $where, the project owns tasks/" );
    routes_agree( $dir, "$repo/tasks/notes/backlog.md", 1,
      "from $where, and the file nested under it" );
    routes_agree( $dir, "$repo/tasksfoo.txt", 1,
      "from $where, and a tracked file at the root" );

    routes_agree( $dir, "$repo/config.yml", 0,
      "from $where, an untracked path answers false" );

    # The #107 property has to survive the move off ->dir. The index is a
    # sorted list of strings and 'tasksfoo.txt' begins with 'tasksfoo', but
    # only the path question is being asked, from either origin.
    routes_agree( $dir, "$repo/tasksfoo", 0,
      "from $where, a string prefix of a tracked file is not a tracked path" );

    # is_tracked resolves the same $rel through libgit2's work-tree lookup, so
    # it was right from a subdirectory all along -- and is what the other two
    # now agree with.
    my $git = App::karr::Git->new( dir => $dir );
    is( $git->is_tracked("$repo/tasksfoo.txt"), 1,
      "from $where, is_tracked says the same about the tracked file" );
    is( $git->is_tracked("$repo/config.yml"), 0,
      "from $where, and about the untracked one" );
  }

  # A subdirectory that tracks nothing must not answer for the root's content
  # either -- the fix moves the origin, it does not widen the question.
  routes_agree( "$repo/sub", "$repo/sub", 0,
    'an untracked subdirectory answers false' );
};

subtest 'the work tree root itself (#114)' => sub {
  my $repo = repo_with( 'tasks/notes/backlog.md', 'tasksfoo.txt' );

  routes_agree( $repo, $repo, 1,
    'from the root, the root has tracked content under it' );

  # The case where #113 and #114 cancelled into a matching wrong answer.
  routes_agree( "$repo/sub", $repo, 1,
    'from a subdirectory, the root still has tracked content under it' );

  my $empty = repo_with();
  is( Git::Native->open_ext($empty)->index->entrycount, 0,
    'the control repository really has an empty index' );
  routes_agree( $empty, $empty, 0,
    'a repository tracking nothing answers false for its root' );
};

done_testing;
