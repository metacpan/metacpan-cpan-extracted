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
use JSON::MaybeXS qw( decode_json );

use App::karr::Git;

# Regression for karr board ticket #12.
#
# BUG: `karr delete ID --yes` crashes on EVERY ref-backed task (the normal
#     case -- tasks live in refs/karr/tasks/*, not as files on disk):
#         Can't call method "remove" on an undefined value
#     at Cmd/Delete.pm line 75, because it calls `$task->file_path->remove`
#     and file_path is never set on tasks loaded via find_task (only
#     Task::write / ::from_file set it -- same family as ticket #4, where
#     Archive called `$task->save`).
#
# Even if file_path were set, the operation itself would be wrong: it would
# only unlink the materialized view file, never the canonical ref
# refs/karr/tasks/ID/data -- the task would reappear on the next
# materialize/find_task. Correct persistence is BoardStore::delete_task($id)
# (BoardStore.pm, deletes the ref; already used by serialize_from), exposed
# on the BoardAccess role as $self->delete_task($id).
#
# Found by karr-test-writer while probing for ticket #11 (see t/43's
# file-level note).

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, $stdin, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3(
        my $stdin_fh,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

    if ( defined $stdin ) {
        print {$stdin_fh} $stdin;
    }
    close $stdin_fh;

    my $stdout = do { local $/; <$stdout_fh> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";

    return {
        exit   => $exit,
        stdout => defined $stdout ? $stdout : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is( $rc, 0, "@cmd" );
}

# Fresh isolated temp repo per subtest, never the developer's real board.
sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

    my $init = _run_karr( $repo, undef, 'init', '--name', 'Delete Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    return $repo;
}

# Seeds tasks 1..$n, titled "Task 1".."Task $n".
sub _seed_tasks {
    my ( $repo, $n ) = @_;
    for my $i ( 1 .. $n ) {
        my $rv = _run_karr( $repo, undef, 'create', '--title', "Task $i", '--status', 'todo' );
        is( $rv->{exit}, 0, "seed task $i created" ) or diag $rv->{stderr};
    }
}

sub _task_ref_exists {
    my ( $repo, $id ) = @_;
    my $git = App::karr::Git->new( dir => $repo );
    return $git->ref_exists("refs/karr/tasks/$id/data");
}

subtest 'delete a ref-backed task: does not crash, deletes the canonical ref (RED today, ticket #12)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 2 );

    ok( _task_ref_exists( $repo, 1 ), 'preflight: task 1 ref exists before delete' );

    my $rv = _run_karr( $repo, undef, 'delete', 1, '--yes' );

    is( $rv->{exit}, 0, 'delete 1 --yes exits 0 (does not die)' ) or diag $rv->{stderr};
    unlike( $rv->{stderr}, qr/Can't call method/, 'stderr has no crash trace' );
    like( $rv->{stdout}, qr/Deleted task 1: Task 1/, 'stdout reports the deletion' );

    ok( !_task_ref_exists( $repo, 1 ), 'the canonical ref refs/karr/tasks/1/data is gone' );

    my $show_deleted = _run_karr( $repo, undef, 'show', 1 );
    isnt( $show_deleted->{exit}, 0, 'show 1 fails afterwards: find_task(1) is undef' );

    my $show_other = _run_karr( $repo, undef, 'show', 2 );
    is( $show_other->{exit}, 0, 'the other task (2) is untouched' ) or diag $show_other->{stderr};
    like( $show_other->{stdout}, qr/Task 2/, 'task 2 still has its content' );
};

subtest 'comma batch delete 1,2 --yes: both tasks gone (RED today, ticket #12)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 2 );

    my $rv = _run_karr( $repo, undef, 'delete', '1,2', '--yes' );

    is( $rv->{exit}, 0, 'delete 1,2 --yes exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Deleted task 1: Task 1/, 'stdout reports task 1 deleted' );
    like( $rv->{stdout}, qr/Deleted task 2: Task 2/, 'stdout reports task 2 deleted' );

    ok( !_task_ref_exists( $repo, 1 ), 'ref for task 1 is gone' );
    ok( !_task_ref_exists( $repo, 2 ), 'ref for task 2 is gone' );
};

subtest 'interactive delete without --yes, answering "n": task survives, reports Skipped, exits 0 (GREEN pin, unaffected by #12)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, "n\n", 'delete', 1 );

    is( $rv->{exit}, 0, 'delete 1 (declined) exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Skipped task 1: Task 1/, 'stdout reports the task was skipped' );

    ok( _task_ref_exists( $repo, 1 ), 'the ref for task 1 still exists' );
    my $show = _run_karr( $repo, undef, 'show', 1 );
    is( $show->{exit}, 0, 'task 1 is still findable' ) or diag $show->{stderr};
};

subtest '--json variant: deleted flag reported, no crash (RED today, ticket #12)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, undef, 'delete', 1, '--yes', '--json' );

    is( $rv->{exit}, 0, 'delete 1 --yes --json exits 0' ) or diag $rv->{stderr};
    unlike( $rv->{stderr}, qr/Can't call method/, 'stderr has no crash trace' );

    my $data = eval { decode_json( $rv->{stdout} ) };
    ok( !$@, 'stdout is valid JSON' ) or diag "stdout was: $rv->{stdout}\nerror: $@";
    is( $data->{id}, 1, 'json result names task id 1' );
    ok( $data->{deleted}, 'json result has a truthy deleted flag' );

    ok( !_task_ref_exists( $repo, 1 ), 'the ref for task 1 is gone' );
};

# ------------------------------------------------ non-regression, re-pinned

subtest 'delete 99 --yes: not-found message and exit 1 (GREEN pin, per t/41)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, undef, 'delete', 99, '--yes' );

    # Not found is a runtime failure under the exit-code contract (ADR 0002):
    # exit 1, not the accidental 255 an uncaught die used to leak.
    is( $rv->{exit}, 1, 'delete 99 --yes exits 1 (runtime failure)' );
    like( $rv->{stderr}, qr/Task 99 not found/, 'stderr names the missing id' );

    ok( _task_ref_exists( $repo, 1 ), 'the existing task (1) is untouched' );
};

subtest 'delete 1 2 --yes: extra positional rejected before any work (GREEN pin, per t/43)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 2 );

    my $rv = _run_karr( $repo, undef, 'delete', 1, 2, '--yes' );

    isnt( $rv->{exit}, 0, 'delete 1 2 --yes exits non-zero' );
    like( $rv->{stderr}, qr/\b2\b|usage/i, 'stderr names the extra arg or expected usage' );

    ok( _task_ref_exists( $repo, 1 ), 'task 1 was NOT deleted -- rejected before any id in the batch ran' );
    ok( _task_ref_exists( $repo, 2 ), 'task 2 was NOT deleted either' );
};

done_testing;
