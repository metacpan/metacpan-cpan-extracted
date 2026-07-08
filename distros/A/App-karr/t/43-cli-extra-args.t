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

# Regression tests for karr board ticket #11.
#
# BUG: overzealous positional args are silently swallowed. `karr archive 4
#     99` archives only 4 (exit 0, no diagnostic about the dropped 99);
#     `karr show 1 2` shows only 1. An agent typing `karr archive 4 5 6`
#     believes all three were archived when only 4 was.
#
# DESIGN (parity check against ../kanban-md, recorded on ticket #11): the
#     Go reference also accepts only one comma-separated batch positional
#     per id-taking command (cobra ExactArgs(1)/RangeArgs(1,2)/
#     MaximumNArgs(1)) and rejects extra positionals loudly, before any
#     work happens (cobra's Args validator runs ahead of RunE). karr's fix
#     must match that: the comma list stays the one-and-only batch syntax;
#     no space-separated batch feature. Arg-count contracts:
#       - show:               0 or 1 positional (0 = --last/--me/--agent)
#       - archive/delete/edit/handoff: exactly 1
#       - move:               1 or 2 (id-list, optional status;
#                              --next/--prev make the status positional
#                              optional but do not raise the max)
#       - create:             at most 1 (title positional or --title)
#     2+ positionals beyond that contract must produce a non-zero exit and
#     a STDERR diagnostic (naming the extra args and/or the expected
#     usage), with NO operation performed at all -- not even against the
#     first/valid id in the list, matching cobra's reject-before-run
#     semantics.
#
# None of this is implemented yet (no lib/ changes accompany this test).
# Every "(RED, ticket #11)" subtest below is therefore expected to FAIL
# until #11 is fixed; every "(GREEN pin)" subtest documents a legitimate
# call shape that must keep working once the guard is added.
#
# STDERR assertions use `qr/\bTOKEN\b|usage/i` (mentions the offending
# extra token, OR a usage-style message) to accommodate either of the two
# acceptable diagnostics named on the ticket, while still being false
# against today's silence. Extra numeric tokens are chosen as "99" (never
# "1"/"2"/"3") to avoid false-positive collisions with the sync-lifecycle
# retry noise ("Pull retry 2 of 3.../Push retry 2 of 3...", ticket #27) that
# can appear on STDERR when a command's sync has to retry.
#
# Also recorded here (not pinned -- follow-up candidates for the
# orchestrator to file, per the ticket's own "proben, ggf. Follow-up"
# scope note):
#   - `karr list foo` / `karr board foo` / `karr context foo`: a stray
#     positional is silently ignored on all three (exit 0), same shape of
#     bug as #11 but explicitly out of scope for this ticket (list/board/
#     context are not id-taking commands).
#   - `karr delete ID --yes` on an EXISTING id is unconditionally broken
#     today, independent of #11: it dies "Can't call method \"remove\" on
#     an undefined value" at lib/App/karr/Cmd/Delete.pm line 75, because
#     find_task() returns ref-backed Task objects that never had
#     file_path set (only App::karr::Task::write / ::from_file set it),
#     so $task->file_path->remove dies on undef. Reproduces even for a
#     single legitimate id on a brand-new board/task -- delete is
#     currently unable to delete anything that actually exists. This is
#     orthogonal to #11 (it also happens with exactly one id) and is
#     surfaced here only as a probing note; it is not fixed or pinned by
#     this file.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3(
        undef,
        my $stdout_fh,
        $stderr,
        $^X,
        "-I$ROOT/lib",
        $BIN,
        @argv,
    );

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

    my $init = _run_karr( $repo, 'init', '--name', 'Extra-Args Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    return $repo;
}

# Seeds tasks 1..$n, titled "Task 1".."Task $n", all in the given status
# (default 'todo').
sub _seed_tasks {
    my ( $repo, $n, %opts ) = @_;
    my $status = $opts{status} // 'todo';
    for my $i ( 1 .. $n ) {
        my $rv = _run_karr( $repo, 'create', '--title', "Task $i", '--status', $status );
        is( $rv->{exit}, 0, "seed task $i created" ) or diag $rv->{stderr};
    }
}

sub _status_of {
    my ( $repo, $id ) = @_;
    my $rv = _run_karr( $repo, 'show', $id );
    return undef unless $rv->{exit} == 0;
    return $1 if $rv->{stdout} =~ /^Status:\s+(\S+)$/m;
    return undef;
}

sub _title_of {
    my ( $repo, $id ) = @_;
    my $rv = _run_karr( $repo, 'show', $id );
    return undef unless $rv->{exit} == 0;
    return $1 if $rv->{stdout} =~ /^Task #\d+: (.+)$/m;
    return undef;
}

# ---------------------------------------------------------- (a) RED pins:
# too many positionals -> STDERR diagnostic, non-zero exit, no operation
# performed at all (not even on the first/valid id).

subtest 'show 1 2: extra positional rejected, no partial render (RED, ticket #11)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 2 );

    my $rv = _run_karr( $repo, 'show', 1, 2 );

    isnt( $rv->{exit}, 0, 'show 1 2 exits non-zero' );
    like( $rv->{stderr}, qr/\b2\b|usage/i, 'STDERR names the extra arg or the expected usage' );
    unlike( $rv->{stdout}, qr/Task 1\b/, 'STDOUT does not silently render task 1 when rejected' );
};

subtest 'archive 4 99: exact ticket repro -- task 4 must NOT be archived (RED, ticket #11)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 4 );

    my $rv = _run_karr( $repo, 'archive', 4, 99 );

    isnt( $rv->{exit}, 0, 'archive 4 99 exits non-zero' );
    like( $rv->{stderr}, qr/\b99\b|usage/i, 'STDERR names the extra id or the expected usage' );
    isnt( _status_of( $repo, 4 ), 'archived',
        'task 4 was NOT archived -- rejected before any id in the batch ran' );
};

subtest 'archive 4, 5 (shell-split trailing comma): also rejected loudly (RED, ticket #11)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 5 );

    # `karr archive 4, 5` at a real shell becomes two argv tokens: "4," and
    # "5". parse_ids("4,") already drops the trailing empty field, so this
    # is functionally the same silent-drop bug as `archive 4 99`, just
    # reached via a stray space after the comma instead of a stray id.
    my $rv = _run_karr( $repo, 'archive', '4,', '5' );

    isnt( $rv->{exit}, 0, 'archive "4," "5" exits non-zero' );
    like( $rv->{stderr}, qr/\b5\b|usage/i, 'STDERR names the extra arg or the expected usage' );
    isnt( _status_of( $repo, 4 ), 'archived',
        'task 4 was NOT archived -- rejected before any id in the batch ran' );
};

subtest 'delete 4 99: extra id rejected loudly, task 4 untouched (RED, ticket #11)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 4 );

    my $rv = _run_karr( $repo, 'delete', 4, 99, '--yes' );

    # Exit is already non-zero today, but NOT because of an arg-count guard:
    # Cmd::Delete currently dies with an unrelated crash the moment it
    # tries to delete ANY existing task (see file-level note above), which
    # happens to leave this assertion accidentally green already. The
    # meaningful, currently-false assertion is the STDERR one below --
    # today's STDERR is "Can't call method \"remove\" on an undefined
    # value ..." and never mentions the dropped id 99.
    isnt( $rv->{exit}, 0, 'delete 4 99 exits non-zero' );
    like( $rv->{stderr}, qr/\b99\b|usage/i, 'STDERR names the extra id or the expected usage' );

    my $show = _run_karr( $repo, 'show', 4 );
    is( $show->{exit}, 0, 'task 4 still exists (no operation performed)' ) or diag $show->{stderr};
};

subtest 'edit 4 99 --title ...: extra id rejected loudly, title untouched (RED, ticket #11)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 4 );

    my $rv = _run_karr( $repo, 'edit', 4, 99, '--title', 'New Title' );

    isnt( $rv->{exit}, 0, 'edit 4 99 exits non-zero' );
    like( $rv->{stderr}, qr/\b99\b|usage/i, 'STDERR names the extra id or the expected usage' );
    is( _title_of( $repo, 4 ), 'Task 4',
        'task 4 title was NOT changed -- rejected before any id in the batch ran' );
};

subtest 'handoff 4 99 --claim ...: extra id rejected loudly, status untouched (RED, ticket #11)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 4 );

    my $rv = _run_karr( $repo, 'handoff', 4, 99, '--claim', 'tester' );

    isnt( $rv->{exit}, 0, 'handoff 4 99 exits non-zero' );
    like( $rv->{stderr}, qr/\b99\b|usage/i, 'STDERR names the extra id or the expected usage' );
    isnt( _status_of( $repo, 4 ), 'review',
        'task 4 was NOT moved to review -- rejected before any id in the batch ran' );
};

subtest 'move 1 done extra: 3rd positional rejected, status untouched (RED, ticket #11)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );    # task 1 starts 'todo'

    my $rv = _run_karr( $repo, 'move', 1, 'done', 'extra' );

    isnt( $rv->{exit}, 0, 'move 1 done extra exits non-zero' );
    like( $rv->{stderr}, qr/\bextra\b|usage/i, 'STDERR names the extra arg or the expected usage' );
    is( _status_of( $repo, 1 ), 'todo',
        'task 1 was NOT moved to done -- rejected before it ran' );
};

subtest 'create "Title" "Extra Arg": 2nd positional rejected, nothing created (RED, ticket #11)' => sub {
    my $repo = _setup_repo();

    my $rv = _run_karr( $repo, 'create', 'New Task Title', 'Extra Arg' );

    isnt( $rv->{exit}, 0, 'create with 2 positionals exits non-zero' );
    like( $rv->{stderr}, qr/\QExtra Arg\E|usage/i, 'STDERR names the extra arg or the expected usage' );

    my $show = _run_karr( $repo, 'show', 1 );
    isnt( $show->{exit}, 0, 'no task was created (id 1 does not exist)' );
};

# ------------------------------------------------------- (b) GREEN pins:
# legitimate call shapes must keep working once the guard above lands.

subtest 'archive 4,5 (comma batch, 2 valid ids): stays green (GREEN pin)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 5 );

    my $rv = _run_karr( $repo, 'archive', '4,5' );

    is( $rv->{exit}, 0, 'archive 4,5 exits 0' ) or diag $rv->{stderr};
    is( _status_of( $repo, 4 ), 'archived', 'task 4 archived' );
    is( _status_of( $repo, 5 ), 'archived', 'task 5 archived' );
};

subtest 'move 1 todo (id + explicit status): stays green (GREEN pin)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1, status => 'backlog' );

    my $rv = _run_karr( $repo, 'move', 1, 'todo' );

    is( $rv->{exit}, 0, 'move 1 todo exits 0' ) or diag $rv->{stderr};
    is( _status_of( $repo, 1 ), 'todo', 'task 1 moved to todo' );
};

subtest 'move 1 --next (id + relative flag, no status positional): stays green (GREEN pin)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1, status => 'todo' );

    my $rv = _run_karr( $repo, 'move', 1, '--next', '--claim', 'tester' );

    is( $rv->{exit}, 0, 'move 1 --next exits 0' ) or diag $rv->{stderr};
    is( _status_of( $repo, 1 ), 'in-progress', 'task 1 advanced to in-progress' );
};

subtest 'show with no args (recent-task mode): stays green (GREEN pin)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'show' );

    is( $rv->{exit}, 0, 'bare show exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^Task #1:/m, 'shows the only (most recently updated) task' );
};

subtest 'create "Titel" (single positional title): stays green (GREEN pin)' => sub {
    my $repo = _setup_repo();

    my $rv = _run_karr( $repo, 'create', 'Solo Title' );

    is( $rv->{exit}, 0, 'create with 1 positional exits 0' ) or diag $rv->{stderr};
    is( _title_of( $repo, 1 ), 'Solo Title', 'task 1 created with the positional title' );
};

done_testing;
