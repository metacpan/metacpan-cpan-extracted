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

use App::karr::Git;
use App::karr::ActivityLog;

# Ticket #153: the truthiness guards around option values in Cmd/Edit,
# Cmd/Create and Cmd/Handoff silently dropped "0" -- writing the task, bumping
# `updated`, appending to the activity log, and printing success. The #78 rule
# (`defined && length`) is what --body was changed to; this ticket extends it
# to the siblings that did not get the conversion.
#
# The fix lands "0" as a real value rather than rejecting it: a literal "0" is
# one character long and is a meaningful title/block-reason/tag/assignee/estimate
# -- exactly the same argument ticket #78 made for --body "0". Two characters
# ("00") have always been truthy; the bug was that one was not.

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
    system( 'git', 'init', '-q', $repo )                                     == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' )         == 0 or die 'git config';

    my $init = _run_karr( $repo, undef, 'init', '--name', 'Falsy Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    my $create = _run_karr( $repo, undef, 'create',
        '--title', 'original title', '--status', 'todo' );
    is( $create->{exit}, 0, 'seed task created' ) or diag $create->{stderr};

    return $repo;
}

sub _task {
    my ( $repo, $id ) = @_;
    return App::karr::Git->new( dir => $repo )
        ->load_task_ref( $id // 1 );
}

# Count edit entries in the activity log for this repo. The seeded task's
# creation is the only entry before any test command runs, so any extra one is
# a write that landed.
sub _edit_count {
    my ($repo) = @_;
    my $log = App::karr::ActivityLog->new(
        git => App::karr::Git->new( dir => $repo ),
        role => 'user',
    );
    return scalar grep { $_->{action} eq 'edit' } $log->entries;
}

subtest 'edit --title 0 lands as the literal title "0" (#153)' => sub {
    my $repo = _setup_repo();
    my $before_logs = _edit_count($repo);

    # The bug: this used to print "Updated task 1: original title" and exit 0
    # with the title still "original title" -- a silent write that bumped
    # `updated` and appended to the activity log for a change that never
    # happened. The fix lands "0" as the title (ticket #78's rule applied to
    # --title's siblings).
    my $rv = _run_karr( $repo, undef, 'edit', 1, '--title', '0' );
    is( $rv->{exit}, 0, 'edit --title 0 succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stdout}, qr/Updated task 1: 0/,
        '...and stdout reports the new title "0", not the old one' );

    my $after = _task($repo);
    is( $after->title, '0',
        'and the literal "0" landed as the new title' );
    is( _edit_count($repo), $before_logs + 1,
        'and exactly one activity-log entry was appended (a real write)' );
};

subtest 'edit --block 0 records block reason "0" (#153 sharp edge)' => sub {
    my $repo = _setup_repo();

    # The ticket's sharp edge: the card was reported updated but was NOT
    # blocked, and pick would hand it straight out. The fix lands "0" as a
    # block reason rather than silently dropping it.
    my $rv = _run_karr( $repo, undef, 'edit', 1, '--block', '0' );
    is( $rv->{exit}, 0, 'edit --block 0 succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};

    my $task = _task($repo);
    ok( $task->has_blocked,
        'and the card IS blocked (not silently left unblocked)' );
    is( $task->block_reason, '0',
        'and the literal "0" is the recorded block reason' );
};

subtest 'edit --title 00 still works: truthiness, not numeric validation' => sub {
    # The giveaway for the bug: --title 00 (two characters, truthy) has always
    # worked. The fix has to keep it working -- and the difference between "0"
    # and "00" being meaningful is the proof that the fix is definedness, not
    # numeric validation.
    my $repo = _setup_repo();

    my $rv = _run_karr( $repo, undef, 'edit', 1, '--title', '00' );
    is( $rv->{exit}, 0, 'edit --title 00 succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};
    like( $rv->{stdout}, qr/Updated task 1: 00/,
        '...and reports the new title' );
    is( _task($repo)->title, '00',
        '...and the new title landed in the ref' );
};

subtest 'edit --append-body 0 appends, never replaces (#153 self-contradicting guard)' => sub {
    # The comment immediately inside the guard reads:
    #     "length, not truth: appending to a body of "0" must not replace it
    #     (ticket #78)"
    # The guard was `if ($self->append_body)`, which is truth, not length --
    # and the body it appended to was set by --body, the place where #78 was
    # actually fixed. So `karr edit 1 -a 0` against a task whose body is "0"
    # used to silently do nothing while still claiming to have updated the
    # task. The fix makes --append_body honour the same comment.
    my $repo = _setup_repo();

    # Seed a body of "0" by writing through the board directly; --body "0"
    # already lands thanks to ticket #78.
    my $seed = _run_karr( $repo, undef, 'edit', 1, '--body', '0' );
    is( $seed->{exit}, 0, 'seed: --body 0 lands as the literal "0"' )
        or diag $seed->{stderr};
    is( _task($repo)->body, '0', 'and the body is now "0"' );

    my $rv = _run_karr( $repo, undef, 'edit', 1, '-a', 'appended' );
    is( $rv->{exit}, 0, 'edit -a appended succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};

    # "appending to a body of "0" must not replace it" -- #78.
    is( _task($repo)->body, "0\nappended",
        'and the existing body of "0" was preserved and the new text appended' )
        or diag "got: " . _task($repo)->body;
};

subtest 'create with --tags 0 --assignee 0 --estimate 0 lands all three (#153)' => sub {
    my $repo = _setup_repo();

    # The bug used to create the task and silently drop all three options.
    # --tags is comma-split, so "0" splits to ['0']; --assignee and
    # --estimate are scalar. With the #78 rule (`defined && length`) applied
    # to the siblings, all three land instead of being silently dropped.
    my $rv = _run_karr( $repo, undef, 'create',
        '--title', 'all-three',
        '--tags', '0', '--assignee', '0', '--estimate', '0' );
    is( $rv->{exit}, 0, 'create ... --tags 0 --assignee 0 --estimate 0 succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};

    my $task = _task( $repo, 2 );
    is_deeply( $task->tags, ['0'],
        'and --tags 0 landed as the literal tag "0" (one comma-split element)' );
    is( $task->assignee, '0',
        'and --assignee 0 landed as the literal "0"' );
    is( $task->estimate, '0',
        'and --estimate 0 landed as the literal "0"' );
};

subtest 'handoff --block 0 records block reason "0" (#153)' => sub {
    my $repo = _setup_repo();

    # Move the task into a require_claim column so handoff has somewhere to
    # land it and --claim has something to satisfy.
    my $move = _run_karr( $repo, undef, 'move', 1, 'in-progress',
        '--claim', 'alice' );
    is( $move->{exit}, 0, 'seed task moved into in-progress' )
        or diag $move->{stderr};

    # --block 0 lands as a block reason rather than being silently dropped.
    my $rv = _run_karr( $repo, undef, 'handoff', 1,
        '--claim', 'alice', '--block', '0' );
    is( $rv->{exit}, 0, 'handoff --block 0 succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};

    my $task = _task($repo);
    ok( $task->has_blocked,
        'and the card is blocked' );
    is( $task->block_reason, '0',
        'and the literal "0" is the recorded block reason' );
};

subtest 'handoff --note 0 appends the literal "0" to the body (#153)' => sub {
    my $repo = _setup_repo();

    my $move = _run_karr( $repo, undef, 'move', 1, 'in-progress',
        '--claim', 'alice' );
    is( $move->{exit}, 0, 'seed task moved into in-progress' )
        or diag $move->{stderr};

    # --note 0 is the same kind of truthiness guard as --append_body: it
    # appends text to the body, and "0" is meaningful text.
    my $rv = _run_karr( $repo, undef, 'handoff', 1,
        '--claim', 'alice', '--note', '0' );
    is( $rv->{exit}, 0, 'handoff --note 0 succeeds' )
        or diag $rv->{stdout} . $rv->{stderr};

    is( _task($repo)->body, '0',
        'and the literal "0" was appended to the body' );
};

done_testing;
