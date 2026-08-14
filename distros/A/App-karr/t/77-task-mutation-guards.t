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
use Time::Piece;

use App::karr::Git;
use App::karr::Role::BoardAccess;
use App::karr::Role::TaskMutation;

# Regression for karr board tickets #55, #56 and #73 -- the rules that apply
# when a command changes a task that already exists.
#
# #55 There were two doors into a status change and only one of them was
#     guarded. `karr move 1 in-progress` refused without --claim; `karr edit 1
#     --status in-progress` set the field and exited 0, so require_claim -- the
#     guarantee karr's multi-agent coordination rests on -- was one flag away
#     from optional. edit also skipped the started/completed lifecycle stamps.
#
# #56 move, edit and delete never asked who held the claim, so any agent could
#     take over another agent's in-flight work. handoff and pick got this right
#     (Role::ClaimTimeout was composed only into those two).
#
# #73 `karr delete ID` with stdin not a terminal -- every agent and CI run --
#     printed "Use of uninitialized value $answer" twice, because <STDIN>
#     returns undef at EOF, and then silently skipped the task.
#
# Plus one hole found in a sibling lane while probing #76: an id list that
# contains no ids ("karr move , todo") exited 0 having done nothing at all.
#
# The last subtest pins the mechanism rather than a symptom: the claim check and
# the write have to be the same revision of the task, or the check is decoration
# (the #44/#46 bug class).

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, $stdin, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( my $stdin_fh, my $stdout_fh, $stderr,
        $^X, "-I$ROOT/lib", $BIN, @argv );

    print {$stdin_fh} $stdin if defined $stdin;
    close $stdin_fh;

    my $stdout      = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout      ? $stdout      : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

# Fresh isolated temp repo per subtest, never the developer's real board.
sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0                                     or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0         or die 'git config';

    my $init = _run_karr( $repo, undef, 'init', '--name', 'Guard Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    my $create = _run_karr( $repo, undef, 'create', '--title', 'Task 1', '--status', 'todo' );
    is( $create->{exit}, 0, 'seed task 1 created' ) or diag $create->{stderr};

    return $repo;
}

sub _task { App::karr::Git->new( dir => $_[0] )->load_task_ref( $_[1] // 1 ) }

sub _ref_exists {
    my ( $repo, $id ) = @_;
    return App::karr::Git->new( dir => $repo )->ref_exists("refs/karr/tasks/$id/data");
}

# Rewrite claimed_at directly, so "this claim is two hours old" does not need a
# two hour test run. Goes through save_task_ref rather than the CLI because
# there is no command for backdating a claim -- which is the point.
sub _backdate_claim {
    my ( $repo, $id, $secs_ago ) = @_;
    my $git  = App::karr::Git->new( dir => $repo );
    my $task = $git->load_task_ref($id);
    $task->claimed_at( gmtime( time - $secs_ago )->datetime . 'Z' );
    $git->save_task_ref($task);
    return;
}

subtest 'edit --status obeys the same rules as move (#55)' => sub {
    my $repo = _setup_repo();

    my $move = _run_karr( $repo, undef, 'move', 1, 'in-progress' );
    is( $move->{exit}, 1, 'move 1 in-progress without --claim is refused' );
    like( $move->{stderr}, qr/requires --claim/, '...with the require_claim message' );

    # The bug: the same state change through the other door.
    my $edit = _run_karr( $repo, undef, 'edit', 1, '--status', 'in-progress' );
    is( $edit->{exit}, 1, 'edit 1 --status in-progress without --claim is refused too' )
        or diag $edit->{stdout} . $edit->{stderr};
    like( $edit->{stderr}, qr/requires --claim/, '...with the same message' );
    is( _task($repo)->status, 'todo', 'and the status was not changed' );

    # With a claim it goes through, and it stamps the lifecycle dates that
    # `move` has always stamped and `edit` never did.
    my $ok = _run_karr( $repo, undef, 'edit', 1, '--status', 'in-progress', '--claim', 'alice' );
    is( $ok->{exit}, 0, 'edit --status in-progress --claim alice succeeds' ) or diag $ok->{stderr};

    my $task = _task($repo);
    is( $task->status,     'in-progress', 'status changed' );
    is( $task->claimed_by, 'alice',       'claim recorded' );

    # Parity with `move` is what this subtest is for, so assert it against
    # `move` rather than against a hardcoded expectation. Ticket #68 replaced
    # the old "stamp whenever the new status is literally in-progress" rule
    # with kanban-md's -- `started` on the first move out of the *first
    # configured* status -- so a task seeded in `todo` no longer gets one here.
    # What has to stay true is that both doors do the same thing.
    my $seed2 = _run_karr( $repo, undef, 'create', '--title', 'Task 2', '--status', 'todo' );
    is( $seed2->{exit}, 0, 'seed task 2 created' ) or diag $seed2->{stderr};
    my $via_move = _run_karr( $repo, undef, 'move', 2, 'in-progress', '--claim', 'alice' );
    is( $via_move->{exit}, 0, 'move 2 in-progress --claim alice succeeds' )
        or diag $via_move->{stderr};
    is( ( _task( $repo, 2 )->has_started ? 1 : 0 ), ( $task->has_started ? 1 : 0 ),
        'edit --status and move stamp started identically' );

    my $done = _run_karr( $repo, undef, 'edit', 1, '--status', 'done', '--claim', 'alice' );
    is( $done->{exit}, 0, 'edit --status done succeeds' ) or diag $done->{stderr};
    ok( _task($repo)->has_completed, 'edit --status done stamps completed, like move does' );
};

subtest 'a live claim is not silently taken over (#56)' => sub {
    my $repo = _setup_repo();

    my $claim = _run_karr( $repo, undef, 'move', 1, 'in-progress', '--claim', 'alice' );
    is( $claim->{exit}, 0, 'alice claims task 1' ) or diag $claim->{stderr};

    my $move = _run_karr( $repo, undef, 'move', 1, 'review', '--claim', 'mallory' );
    is( $move->{exit}, 1, 'move by another agent is refused' ) or diag $move->{stdout};
    like( $move->{stderr}, qr/claimed by alice/, '...naming the holder' );

    my $task = _task($repo);
    is( $task->claimed_by, 'alice',       'the claim still belongs to alice' );
    is( $task->status,     'in-progress', 'and the status was not changed' );

    my $edit = _run_karr( $repo, undef, 'edit', 1, '-a', 'mallory was here' );
    is( $edit->{exit}, 1, 'edit by another agent is refused' ) or diag $edit->{stdout};
    like( $edit->{stderr}, qr/claimed by alice/, '...naming the holder' );
    unlike( _task($repo)->body, qr/mallory was here/, 'and the body was not appended to' );

    # The holder is not locked out of her own work.
    my $own = _run_karr( $repo, undef, 'move', 1, 'review', '--claim', 'alice' );
    is( $own->{exit}, 0, 'the claim holder may still move her own task' ) or diag $own->{stderr};
    is( _task($repo)->status, 'review', 'and the move took effect' );

    # Last, because a pre-fix run really does delete the task here.
    my $del = _run_karr( $repo, undef, 'delete', 1, '--yes' );
    is( $del->{exit}, 1, 'delete of a claimed task is refused' ) or diag $del->{stdout};
    like( $del->{stderr}, qr/claimed by alice/, '...naming the holder' );
    ok( _ref_exists( $repo, 1 ), 'and the task still exists' );
};

subtest 'an expired claim blocks nobody (#56/#57)' => sub {
    my $repo = _setup_repo();

    my $claim = _run_karr( $repo, undef, 'move', 1, 'in-progress', '--claim', 'alice' );
    is( $claim->{exit}, 0, 'alice claims task 1' ) or diag $claim->{stderr};

    # Default claim_timeout is 1h; make the claim two hours old.
    _backdate_claim( $repo, 1, 7200 );

    my $move = _run_karr( $repo, undef, 'move', 1, 'review', '--claim', 'mallory' );
    is( $move->{exit}, 0, 'an expired claim does not block another agent' ) or diag $move->{stderr};
    is( _task($repo)->claimed_by, 'mallory', 'and the claim moves on' );
};

subtest 'edit --release still breaks a foreign claim (#56 carve-out)' => sub {
    my $repo = _setup_repo();

    my $claim = _run_karr( $repo, undef, 'move', 1, 'in-progress', '--claim', 'alice' );
    is( $claim->{exit}, 0, 'alice claims task 1' ) or diag $claim->{stderr};

    # karr's only way out of a claim a crashed agent left behind, so it has to
    # keep working on somebody else's claim even after #56.
    my $release = _run_karr( $repo, undef, 'edit', 1, '--release' );
    is( $release->{exit}, 0, 'edit --release is exempt from the claim check' ) or diag $release->{stderr};
    ok( !_task($repo)->has_claimed_by, 'and the claim is gone' );
};

subtest 'delete without --yes and without a terminal (#73)' => sub {
    my $repo = _setup_repo();

    # open3 gives the child a pipe on stdin, closed immediately: not a TTY, and
    # at EOF. Exactly what an agent or a CI job hands karr.
    my $rv = _run_karr( $repo, undef, 'delete', 1 );

    unlike( $rv->{stderr}, qr/uninitialized value/, 'no Perl warnings on stderr' );
    is( $rv->{exit}, 1, 'refused, rather than silently skipped' ) or diag $rv->{stderr};
    like( $rv->{stderr}, qr/not a terminal/, 'and says why' );
    like( $rv->{stderr}, qr/--yes/,          'and says what to do about it' );
    ok( _ref_exists( $repo, 1 ), 'the task is still there' );

    # An answer that is actually there is still honoured, terminal or not --
    # `echo n | karr delete 1` is pinned by t/44 and must not become a refusal.
    my $piped_no = _run_karr( $repo, "n\n", 'delete', 1 );
    is( $piped_no->{exit}, 0, 'a piped "n" is still an answer, not a refusal' )
        or diag $piped_no->{stderr};
    like( $piped_no->{stdout}, qr/Skipped task 1/, '...and skips the task' );
    ok( _ref_exists( $repo, 1 ), '...leaving it in place' );

    my $piped_yes = _run_karr( $repo, "y\n", 'delete', 1 );
    is( $piped_yes->{exit}, 0, 'a piped "y" still deletes' ) or diag $piped_yes->{stderr};
    ok( !_ref_exists( $repo, 1 ), '...and the task is gone' );
};

subtest 'an id list that contains no ids is a usage error, not a silent no-op' => sub {
    my $repo = _setup_repo();

    # `karr move , todo` gets past the `or die "Usage: ..."` guard -- "," is
    # truthy -- and then splits to an empty list, so the per-id loop never ran:
    # no output, no die, exit 0. Silence is the one answer the exit-code
    # contract (ADR 0002) cannot express, and on delete it reads as success.
    # Found in a sibling lane while probing ticket #76.
    for my $case (
        [ 'move',   [ ',',  'todo' ] ],
        [ 'move',   [ ',,', 'todo' ] ],
        [ 'edit',   [ ',',  '--title', 'X' ] ],
        [ 'delete', [ ',',  '--yes' ] ],
    ) {
        my ( $cmd, $argv ) = @$case;
        my $rv = _run_karr( $repo, undef, $cmd, @$argv );
        is( $rv->{exit}, 2, "karr $cmd @$argv exits 2" ) or diag $rv->{stdout} . $rv->{stderr};
        like( $rv->{stderr}, qr/^Usage:/m, "...with a usage message" );
    }

    ok( _ref_exists( $repo, 1 ), 'and the seeded task is untouched throughout' );
};

{
    package MutationConsumer;
    use Moo;
    use MooX::Options;
    # App::karr::Role::Output is not decoration here: TaskMutation reads
    # $self->json in run_batch, and App::karr::Role::DependencyCheck requires it
    # since ticket #137, so every real mutation command composes Output too.
    # Leaving it out made this class the one consumer of the mutation path that
    # could not have answered a run_batch failure.
    with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output',
      'App::karr::Role::TaskMutation';
}

subtest 'the mutation and the write are the same revision (#56 mechanism)' => sub {
    my $repo = _setup_repo();
    my $git  = App::karr::Git->new( dir => $repo );

    my $consumer = MutationConsumer->new( dir => $repo );

    # A claim check that reads the task, decides, and then writes without a
    # guard is decoration: the revision it judged is not the revision it
    # overwrites. Simulate the losing race by having another agent write the
    # task from inside the first attempt.
    my $attempts = 0;
    my $written  = $consumer->update_task_guarded( 1, sub {
        my ($task) = @_;
        $attempts++;
        if ( $attempts == 1 ) {
            my $other = $git->load_task_ref(1);
            $other->assignee('other-agent');
            $git->save_task_ref($other);
        }
        $task->title( $task->title . ' [ours]' );
    } );

    is( $attempts, 2, 'the losing attempt is retried against a fresh read' );
    is( $written->assignee, 'other-agent',
        'the concurrent write survives instead of being overwritten' );

    my $stored = $git->load_task_ref(1);
    is( $stored->assignee, 'other-agent', 'and that is what landed in the ref' );

    my $count = () = $stored->title =~ /\Q[ours]\E/g;
    is( $count, 1, 'our own change is applied exactly once, not once per attempt' );
};

done_testing;
