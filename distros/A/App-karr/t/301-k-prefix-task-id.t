use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use TestKarr qw( run_karr );
use File::Temp qw( tempdir );

use App::karr::Git;
use App::karr::CrossBoard;
use App::karr::Encoding qw( json_decode );

# Board ticket 301: the house `kNNN` spelling is accepted as a local task id
# wherever a bare number was expected -- `karr show k30` names the same card as
# `karr show 30`. Before this change `k30` reached refs/karr/tasks/k30/data and
# failed with "Task k30 not found" (exit 1); reproduced by hand on a temp board
# before the fix. The strip is surgical and only at the CLI-argument rim
# (App::karr::Role::BoardAccess/normalize_task_id, parse_ids, Handoff,
# App::karr::Role::DependencyArgs/parse_dependency_ids, and the id side of a
# cross-board BOARD#ID reference). The ref names built from the result stay
# numeric.
#
# A `k`/`K` is stripped only when it sits immediately in front of a run of
# digits with nothing else around it. Every other token -- a bare number, a
# lone `k`, `k1a`, `kanban`, `abc` -- is left verbatim and fails as before,
# which is what keeps the normalizer from being too greedy.

# In-process runner (t/lib/TestKarr.pm): ($cwd, @argv) in, { exit, stdout,
# stderr } out, dispatched through the shared App::karr::Dispatch path.
sub _run_karr { return run_karr(@_) }

sub _init_repo {
  my $repo = tempdir( CLEANUP => 1 );
  system( 'git', 'init', '-q', $repo );
  system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
  system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );
  return $repo;
}

sub _init_board {
  my ( $name, @titles ) = @_;
  my $repo = _init_repo();
  is( _run_karr( $repo, 'init', '--name', $name )->{exit}, 0, "board '$name' initialized" );
  is( _run_karr( $repo, 'create', $_ )->{exit}, 0, "created: $_" ) for @titles;
  return $repo;
}

sub _task { App::karr::Git->new( dir => $_[0] )->load_task_ref( $_[1] ) }

subtest 'parse_ids: k30 resolves the same card as 30 (show)' => sub {
  my $repo = _init_board( 'Show Board', 'First card', 'Second card' );

  my $bare = _run_karr( $repo, 'show', '1' );
  my $kform = _run_karr( $repo, 'show', 'k1' );
  is( $kform->{exit}, 0, 'show k1 succeeds' ) or diag( $kform->{stderr} );
  is( $kform->{stdout}, $bare->{stdout}, 'show k1 prints exactly what show 1 does' );

  # Case-insensitive.
  my $upper = _run_karr( $repo, 'show', 'K1' );
  is( $upper->{exit}, 0, 'show K1 succeeds' );
  is( $upper->{stdout}, $bare->{stdout}, 'show K1 matches show 1 too' );

  # A mixed batch: k1, 2 and K2 (deduped by the command) all land.
  my $batch = _run_karr( $repo, 'show', 'k1,2' );
  is( $batch->{exit}, 0, 'mixed batch k1,2 succeeds' ) or diag( $batch->{stderr} );
  like( $batch->{stdout}, qr/First card/,  'card 1 shown via k1' );
  like( $batch->{stdout}, qr/Second card/, 'card 2 shown via bare 2' );
};

subtest 'parse_ids: a mutating batch command applies to the k-form id' => sub {
  my $repo = _init_board( 'Move Board', 'Movable' );

  my $rv = _run_karr( $repo, 'move', 'k1', 'in-progress', '--claim', 'agent-a' );
  is( $rv->{exit}, 0, 'move k1 succeeds' ) or diag( $rv->{stderr} );
  is( _task( $repo, 1 )->status, 'in-progress', 'card 1 was moved' );
};

subtest 'Handoff: the direct pos[0] path accepts k-notation' => sub {
  my $repo = _init_board( 'Handoff Board', 'Handoffable' );
  is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'agent-a' )->{exit},
    0, 'card started' );

  my $rv = _run_karr( $repo, 'handoff', 'K1', '--claim', 'agent-a' );
  is( $rv->{exit}, 0, 'handoff K1 succeeds' ) or diag( $rv->{stderr} );
  like( $rv->{stdout}, qr/Handed off task 1/, 'the numeric id is reported' );
};

subtest 'dependency ids: --depends-on / --add-depends-on accept k-notation' => sub {
  my $repo = _init_board( 'Dep Board', 'Dep one', 'Dep two', 'Needs them' );

  my $create = _run_karr( $repo, 'create', 'Needs k1', '--depends-on', 'k1,2' );
  is( $create->{exit}, 0, 'create --depends-on k1,2 succeeds' ) or diag( $create->{stderr} );
  is_deeply( _task( $repo, 4 )->depends_on, [ 1, 2 ],
    'the k-form and the bare id are both stored as numbers' );

  my $edit = _run_karr( $repo, 'edit', '3', '--add-depends-on', 'K1' );
  is( $edit->{exit}, 0, 'edit --add-depends-on K1 succeeds' ) or diag( $edit->{stderr} );
  is_deeply( _task( $repo, 3 )->depends_on, [1], 'the dependency landed as a number' );
};

subtest 'a token that is not k+digits is left verbatim and still fails' => sub {
  my $repo = _init_board( 'Reject Board', 'Only card' );

  # `kanban` and `k1a` are not the kNNN shape: unchanged, and still not found.
  my $word = _run_karr( $repo, 'show', 'kanban' );
  isnt( $word->{exit}, 0, 'show kanban fails' );
  like( $word->{stderr}, qr/Task kanban not found/, 'the token is echoed verbatim' );

  my $tail = _run_karr( $repo, 'show', 'k1a' );
  isnt( $tail->{exit}, 0, 'show k1a fails' );
  like( $tail->{stderr}, qr/Task k1a not found/, 'a trailing non-digit is not stripped' );

  # A bad dependency id keeps its usage error, and names the value as typed.
  my $dep = _run_karr( $repo, 'edit', '1', '--add-depends-on', 'k1a' );
  is( $dep->{exit}, 2, 'edit --add-depends-on k1a is a usage error' );
  like( $dep->{stderr}, qr/invalid --add-depends-on id "k1a"/,
    'the offending value is named as the caller typed it' );
};

subtest 'CrossBoard: the id side of BOARD#ID accepts k-notation' => sub {
  my $bare  = App::karr::CrossBoard->parse_ref( '--needs', 'other-repo#7' );
  my $kform = App::karr::CrossBoard->parse_ref( '--needs', 'other-repo#k7' );
  is_deeply( $kform, $bare, 'other-repo#k7 parses identically to other-repo#7' );
  is( $kform->{id}, 7, 'the id is the bare number' );

  # A single k only, and still nothing but digits after it.
  eval { App::karr::CrossBoard->parse_ref( '--needs', 'other-repo#kk7' ) };
  like( $@, qr/invalid --needs reference/, 'other-repo#kk7 is still refused' );
  eval { App::karr::CrossBoard->parse_ref( '--needs', 'other-repo#k' ) };
  like( $@, qr/invalid --needs reference/, 'other-repo#k with no digits is refused' );
};

# Board ticket 310: `karr log --task` was left out of k301. Its option was
# declared `format => 'i'`, so Getopt::Long refused `k5` before karr ever saw it
# ("Value "k5" invalid for option task (number expected)", exit 2) -- while the
# Changes entry promised the k spelling works anywhere a bare number does.
# Reproduced against the pre-fix code: both k-form checks below failed there.
subtest 'log --task: k5 and K5 filter exactly like 5' => sub {
  my $repo = _init_board( 'Log Board', map {"Card $_"} 1 .. 5 );
  # A second entry each for 5 and for 1, so the filter has something to drop
  # and something to keep beyond the create entries.
  is( _run_karr( $repo, 'move', '5', 'todo' )->{exit}, 0, 'card 5 moved' );
  is( _run_karr( $repo, 'move', '1', 'todo' )->{exit}, 0, 'card 1 moved' );

  my $bare = _run_karr( $repo, 'log', '--task', '5' );
  is( $bare->{exit}, 0, 'log --task 5 succeeds' ) or diag( $bare->{stderr} );

  my @lines = split /\n/, $bare->{stdout};
  is( scalar @lines, 2, 'task 5 has its create and its move entry' );
  is( scalar( grep { !/ task#5 / } @lines ), 0, 'and only task 5 entries are shown' );

  for my $spelling (qw( k5 K5 )) {
    my $rv = _run_karr( $repo, 'log', '--task', $spelling );
    is( $rv->{exit}, 0, "log --task $spelling succeeds" ) or diag( $rv->{stderr} );
    is( $rv->{stdout}, $bare->{stdout}, "log --task $spelling prints exactly what --task 5 does" );
  }

  my $json = _run_karr( $repo, 'log', '--json', '--task', 'k5' );
  is( $json->{exit}, 0, 'log --json --task k5 succeeds' ) or diag( $json->{stderr} );
  my $entries = eval { json_decode( $json->{stdout} ) } || [];
  is_deeply( [ map { $_->{task_id} } @$entries ], [ 5, 5 ],
    'the JSON payload holds the two task 5 entries' );
};

subtest 'log --task: a token that is not an id is still a usage error' => sub {
  my $repo = _init_board( 'Log Reject Board', 'Only card' );

  # What held before the fix and has to hold after it: exit 2, the value named
  # as typed, and no log line printed in its place.
  for my $token (qw( abc k kk5 k5x )) {
    my $rv = _run_karr( $repo, 'log', '--task', $token );
    is( $rv->{exit}, 2, "log --task $token exits 2" );
    like( $rv->{stderr}, qr/"\Q$token\E"/, "the value $token is named verbatim" );
    unlike( $rv->{stdout}, qr/task#/, 'no log entry is printed' );
  }

  # Validated before the board is looked up, like --since and --action: a
  # repository with no board still answers a bad --task with exit 2.
  my $bare_repo = _init_repo();
  my $rv = _run_karr( $bare_repo, 'log', '--task', 'abc' );
  is( $rv->{exit}, 2, 'log --task abc exits 2 on a repository with no board' );
};

# Board ticket 312: after k310, --task filtered only when the id was truthy, so
# `--task 0` and `--task k0` applied no filter and printed the whole log, while
# `--task 00` (a true string) filtered for task 0 and printed none -- two
# answers for one value, and neither says the value is wrong. Task ids start
# at 1, so 0 in any spelling is a usage error like every other value that
# names no task. Reproduced against the pre-fix code: 0 and k0 exited 0 with
# both create entries on STDOUT, 00 and K00 exited 0 with "No log entries.".
subtest 'log --task: 0 in any spelling is a usage error, not "no filter"' => sub {
  my $repo = _init_board( 'Log Zero Board', 'Card one', 'Card two' );

  for my $token (qw( 0 k0 K0 00 k00 )) {
    my $rv = _run_karr( $repo, 'log', '--task', $token );
    is( $rv->{exit}, 2, "log --task $token exits 2" );
    like( $rv->{stderr}, qr/invalid --task id "\Q$token\E" \(ids start at 1\)/,
      "the value $token is named verbatim, with the reason" );
    is( $rv->{stdout}, '', 'nothing is printed on STDOUT' );
  }

  # Validated before the board is looked up, like the other --task checks.
  my $bare_repo = _init_repo();
  my $rv = _run_karr( $bare_repo, 'log', '--task', '0' );
  is( $rv->{exit}, 2, 'log --task 0 exits 2 on a repository with no board' );

  # A leading zero on a real id still names that id: 01 is card 1.
  my $one  = _run_karr( $repo, 'log', '--task', '1' );
  my $zero = _run_karr( $repo, 'log', '--task', '01' );
  is( $zero->{exit}, 0, 'log --task 01 succeeds' ) or diag( $zero->{stderr} );
  is( $zero->{stdout}, $one->{stdout}, 'log --task 01 prints exactly what --task 1 does' );
};

# The check k312 asked for: dependency ids do not share the log hole. 0 on the
# adding side is already refused before anything is written, through
# assert_dependencies_exist (no card 0 exists); on the removing side it is the
# same no-op as any id the card does not carry -- deliberately legal, because
# removing an absent id is how a stale dependency is cleaned up. Pinned so the
# adding side cannot start storing a 0.
subtest 'dependency ids: 0 is never added as a dependency' => sub {
  my $repo = _init_board( 'Dep Zero Board', 'Only card' );

  for my $token (qw( 0 k0 00 )) {
    my $create = _run_karr( $repo, 'create', 'Needs zero', '--depends-on', $token );
    is( $create->{exit}, 2, "create --depends-on $token is a usage error" );
    like( $create->{stderr}, qr/dependency task 0 does not exist/, 'the reason is given' );

    my $edit = _run_karr( $repo, 'edit', '1', '--add-depends-on', $token );
    is( $edit->{exit}, 2, "edit --add-depends-on $token is a usage error" );
  }
  is_deeply( _task( $repo, 1 )->depends_on, [], 'card 1 carries no dependency' );
  ok( !App::karr::Git->new( dir => $repo )->load_task_ref(2), 'and no card was created' );
};

subtest 'dependency ids: --remove-depends-on accepts k-notation' => sub {
  my $repo = _init_board( 'Remove Dep Board', 'Dep one', 'Dep two', 'Needs them' );
  is( _run_karr( $repo, 'edit', '3', '--add-depends-on', '1,2' )->{exit},
    0, 'card 3 depends on 1 and 2' );

  my $lower = _run_karr( $repo, 'edit', '3', '--remove-depends-on', 'k1' );
  is( $lower->{exit}, 0, 'edit --remove-depends-on k1 succeeds' ) or diag( $lower->{stderr} );
  is_deeply( _task( $repo, 3 )->depends_on, [2], 'k1 removed dependency 1' );

  my $upper = _run_karr( $repo, 'edit', '3', '--remove-depends-on', 'K2' );
  is( $upper->{exit}, 0, 'edit --remove-depends-on K2 succeeds' ) or diag( $upper->{stderr} );
  is_deeply( _task( $repo, 3 )->depends_on, [], 'K2 removed dependency 2' );
};

subtest 'dependency ids: the usage error names the kNNN spelling' => sub {
  my $repo = _init_board( 'Dep Message Board', 'Only card' );

  my $rv = _run_karr( $repo, 'edit', '1', '--add-depends-on', 'abc' );
  is( $rv->{exit}, 2, 'edit --add-depends-on abc is a usage error' );
  like( $rv->{stderr},
    qr/invalid --add-depends-on id "abc" \(ids are comma-separated numbers or kNNN\)/,
    'the message says the k spelling is accepted too' );
};

done_testing;
