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

# Ticket #61: move, edit and delete died on the first missing id *inside* the
# loop, so every id after it was silently skipped. `karr move 4,999,5 todo`
# moved 4, reported 999 on STDERR, and never looked at 5 -- and which ids
# survived depended on where the bad one sat in the list, so `move 1,999` and
# `move 999,1` did different things to the same board.
#
# ADR 0002 (docs/adr/0002-exit-code-contract.md) settled the contract this
# pins: "partial success is committed, the exit code reports the failure (1)".
# kanban-md's runBatch (cmd/root.go) does the same -- every id is attempted,
# per-id failures are printed, and the batch still returns 1 if any of them
# failed. `archive` was the only karr command that already behaved that way.
#
# The other half of the contract is that a *usage* error is not a per-id
# failure: `move 1,2,3 bogus-status` is wrong for every id at once, so it
# rejects the whole invocation with exit 2 and touches nothing (ticket #54's
# rule, pinned in t/94). A batch runner that swallowed those would quietly
# demote them to exit 1.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( undef, my $stdout_fh, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
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

# A throwaway board with $n tasks, ids 1..$n. Never the developer's real board.
sub _board {
    my ($n) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0                                  or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0 or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' ) == 0     or die 'git config';
    is( _run_karr( $repo, 'init', '--name', 'Batch Board' )->{exit}, 0,
        'setup: karr init exits 0' );
    for my $i ( 1 .. $n ) {
        is( _run_karr( $repo, 'create', "Task $i" )->{exit}, 0,
            "setup: task $i created" );
    }
    return $repo;
}

sub _status_of {
    my ( $repo, $id ) = @_;
    my $rv = _run_karr( $repo, 'show', $id );
    return 'MISSING' unless $rv->{exit} == 0;
    my ($status) = $rv->{stdout} =~ /^Status:\s+(\S+)/m;
    return defined $status ? $status : 'UNKNOWN';
}

# ---------------------------------------------------------------------------
# the bad id sits in the middle: every good id either side of it is applied
# ---------------------------------------------------------------------------

subtest 'move: a missing id in the middle does not skip the ids after it' => sub {
    my $repo = _board(3);

    my $rv = _run_karr( $repo, 'move', '1,999,3', 'todo' );

    is( $rv->{exit}, 1, 'partial batch failure exits 1 (ADR 0002)' );
    like( $rv->{stderr}, qr/Task 999 not found/, 'STDERR names the missing id' );

    is( _status_of( $repo, 1 ), 'todo', 'the id before the bad one moved' );
    is( _status_of( $repo, 3 ), 'todo', 'the id AFTER the bad one moved too' );
};

subtest 'edit: a missing id in the middle does not skip the ids after it' => sub {
    my $repo = _board(3);

    my $rv = _run_karr( $repo, 'edit', '1,999,3', '--title', 'Renamed' );

    is( $rv->{exit}, 1, 'partial batch failure exits 1' );
    like( $rv->{stderr}, qr/Task 999 not found/, 'STDERR names the missing id' );

    like( _run_karr( $repo, 'show', 1 )->{stdout}, qr/Renamed/,
        'the id before the bad one was edited' );
    like( _run_karr( $repo, 'show', 3 )->{stdout}, qr/Renamed/,
        'the id AFTER the bad one was edited too' );
};

subtest 'delete: a missing id in the middle does not skip the ids after it' => sub {
    my $repo = _board(3);

    my $rv = _run_karr( $repo, 'delete', '1,999,3', '--yes' );

    is( $rv->{exit}, 1, 'partial batch failure exits 1' );
    like( $rv->{stderr}, qr/Task 999 not found/, 'STDERR names the missing id' );

    is( _status_of( $repo, 1 ), 'MISSING', 'the id before the bad one was deleted' );
    is( _status_of( $repo, 3 ), 'MISSING', 'the id AFTER the bad one was deleted too' );
    isnt( _status_of( $repo, 2 ), 'MISSING', 'and an id not in the batch is untouched' );
};

subtest 'archive: keeps the behaviour it already had' => sub {
    my $repo = _board(3);

    my $rv = _run_karr( $repo, 'archive', '1,999,3' );

    is( $rv->{exit}, 1, 'partial batch failure exits 1' );
    like( $rv->{stderr}, qr/Task 999 not found/, 'STDERR names the missing id' );
    is( _status_of( $repo, 1 ), 'archived', 'the id before the bad one archived' );
    is( _status_of( $repo, 3 ), 'archived', 'the id after the bad one archived' );
};

# ---------------------------------------------------------------------------
# the outcome no longer depends on where the bad id sits
# ---------------------------------------------------------------------------

subtest 'the surviving ids do not depend on the order of the list' => sub {
    # `move 1,999` moved 1 and `move 999,1` moved nothing -- same board, same
    # ids, different result, which is the sharpest form of the bug.
    for my $order ( '1,999', '999,1' ) {
        my $repo = _board(1);
        my $rv   = _run_karr( $repo, 'move', $order, 'todo' );

        is( $rv->{exit}, 1, "move $order exits 1" );
        is( _status_of( $repo, 1 ), 'todo',
            "move $order applied the good id regardless of its position" );
    }
};

# ---------------------------------------------------------------------------
# exit code: a reported failure is never exit 0
# ---------------------------------------------------------------------------

subtest 'a batch that reported a failure never exits 0' => sub {
    my $repo = _board(2);

    for my $case (
        [ 'move',    [ 'move',    '1,999,2', 'todo' ] ],
        [ 'edit',    [ 'edit',    '1,999,2', '-a', 'note' ] ],
        [ 'archive', [ 'archive', '1,999,2' ] ],
        [ 'delete',  [ 'delete',  '1,999,2', '--yes' ] ],
      )
    {
        my ( $name, $argv ) = @$case;
        my $rv = _run_karr( $repo, @$argv );
        is( $rv->{exit}, 1, "$name with one bad id exits 1, not 0" );
        like( $rv->{stderr}, qr/1 of 3 ids failed/,
            "$name says how much of the batch failed" );
    }
};

subtest 'an all-good batch still exits 0 and says nothing on STDERR' => sub {
    my $repo = _board(3);

    my $rv = _run_karr( $repo, 'move', '1,2,3', 'todo' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    is( $rv->{stderr}, '', 'nothing on STDERR' );
    is( _status_of( $repo, $_ ), 'todo', "task $_ moved" ) for 1 .. 3;
};

# ---------------------------------------------------------------------------
# --json: the results array is produced even when part of the batch failed
# ---------------------------------------------------------------------------

subtest '--json still emits parseable results for a partly failed batch' => sub {
    my $repo = _board(2);

    my $rv = _run_karr( $repo, 'move', '1,999,2', 'todo', '--json' );
    is( $rv->{exit}, 1, 'exit 1' );

    my $data = eval { decode_json( $rv->{stdout} ) };
    is( ref $data, 'ARRAY', 'STDOUT is a JSON array' )
        or diag "stdout was: $rv->{stdout}";
    return unless ref $data eq 'ARRAY';

    is( scalar @$data, 3, 'one entry per id in the batch' );
    is( $data->[0]{id}, 1, 'first entry is the first id' );
    is( $data->[1]{id}, 999, 'the failed id is reported as a number, not a string' );
    like( $data->[1]{error}, qr/not found/, 'and carries the reason' );
    ok( !exists $data->[2]{error}, 'the id after the bad one succeeded' );
};

# ---------------------------------------------------------------------------
# usage errors are still usage errors: whole invocation rejected, exit 2
# ---------------------------------------------------------------------------

subtest 'an invalid status rejects the whole batch with exit 2 and writes nothing' => sub {
    my $repo = _board(3);

    for my $case (
        [ 'move', [ 'move', '1,2,3', 'totally-invalid' ] ],
        [ 'edit', [ 'edit', '1,2,3', '--status', 'totally-invalid' ] ],
      )
    {
        my ( $name, $argv ) = @$case;
        my $rv = _run_karr( $repo, @$argv );
        is( $rv->{exit}, 2, "$name with a bad status is a usage error (2), not 1" );
        like( $rv->{stderr}, qr/Usage error: invalid status/,
            "$name says which value was wrong, once" );
        unlike( $rv->{stderr}, qr/ids failed/,
            "$name does not report it as a per-id batch failure" );
    }

    is( _status_of( $repo, $_ ), 'backlog', "task $_ untouched" ) for 1 .. 3;
};

done_testing;
