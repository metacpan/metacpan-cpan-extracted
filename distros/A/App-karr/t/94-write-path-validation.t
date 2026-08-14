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
use Path::Tiny;
use JSON::MaybeXS qw( decode_json );
use App::karr::Git;

# The CLI half of tickets #54, #58, #68, #69 and #78: driven through the real
# binary against throwaway git repos, because the exit code is the part of the
# contract an agent actually reads (ADR 0002) and it is only produced by
# bin/karr's error handler.
#
# Before the fix every one of the rejected calls below exited 0 and wrote the
# invalid value to refs/karr/*, which then broke `karr move --next`, `karr
# board`, and the column alignment of `karr list`.

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

sub _board_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or die 'git config';
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or die 'git config';
    is( _run_karr( $repo, 'init', '--name', 'Validation Board' )->{exit},
        0, 'setup: karr init exits 0' );
    return $repo;
}

# The stored document for one task, straight out of the ref -- the assertion
# that matters is what landed on the board, not what was printed.
sub _task_doc {
    my ( $repo, $id ) = @_;
    my $ref = "refs/karr/tasks/$id/data";
    my $out = `git -C $repo cat-file -p \$(git -C $repo rev-parse $ref):data 2>/dev/null`;
    return defined $out ? $out : '';
}

# ---------------------------------------------------------------------------
# #54 -- every write path rejects an unconfigured value with exit 2
# ---------------------------------------------------------------------------

subtest '#54 invalid values are rejected with exit 2 and change nothing' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'First task' )->{exit}, 0, 'setup: a task exists' );

    my @cases = (
        [ 'move to an unknown status',   qr/Usage error: invalid status "totally-invalid"/,
            [ 'move', '1', 'totally-invalid' ] ],
        [ 'create --status',   qr/Usage error: invalid status "bogus"/,   [ 'create', 'x', '--status',   'bogus' ] ],
        [ 'create --priority', qr/Usage error: invalid priority "bogus"/, [ 'create', 'x', '--priority', 'bogus' ] ],
        [ 'create --class',    qr/Usage error: invalid class "bogus"/,    [ 'create', 'x', '--class',    'bogus' ] ],
        [ 'create --due',      qr/Usage error: invalid due date "not-a-date"/,
            [ 'create', 'x', '--due', 'not-a-date' ] ],
        [ 'create --due with an impossible day', qr/Usage error: invalid due date "2026-02-30"/,
            [ 'create', 'x', '--due', '2026-02-30' ] ],
        [ 'edit --status',   qr/Usage error: invalid status "bogus"/,   [ 'edit', '1', '--status',   'bogus' ] ],
        [ 'edit --priority', qr/Usage error: invalid priority "bogus"/, [ 'edit', '1', '--priority', 'bogus' ] ],
        [ 'edit --due',      qr/Usage error: invalid due date "nope"/,  [ 'edit', '1', '--due',      'nope' ] ],
        [ 'pick --move',     qr/Usage error: invalid status "bogus"/,
            [ 'pick', '--claim', 'agent-fox', '--move', 'bogus' ] ],
    );

    for my $case (@cases) {
        my ( $label, $re, $argv ) = @$case;
        my $rv = _run_karr( $repo, @$argv );
        is( $rv->{exit}, 2, "$label: exit 2 (usage error)" );
        like( $rv->{stderr}, $re, "$label: says which value was wrong" );
    }

    # Nothing above touched the board.
    my $doc = _task_doc( $repo, 1 );
    like( $doc, qr/^status: backlog$/m, 'task 1 is still in backlog' );
    unlike( $doc, qr/bogus|totally-invalid|not-a-date/, 'no invalid value stored' );

    my $list = _run_karr( $repo, 'list', '--compact' );
    is( scalar( grep { /^#/ } split /\n/, $list->{stdout} ),
        1, 'and no rejected create left a task behind' );
};

subtest '#54 a rejected create does not burn a task id' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'x', '--priority', 'bogus' )->{exit}, 2,
        'rejected' );
    my $rv = _run_karr( $repo, 'create', 'Real task' );
    is( $rv->{exit}, 0, 'the next create succeeds' );
    like( $rv->{stdout}, qr/Created task 1:/, 'and still gets id 1' );
};

subtest '#54 a batch edit is rejected before any id is touched' => sub {
    my $repo = _board_repo();
    _run_karr( $repo, 'create', "Task $_" ) for 1 .. 3;

    my $rv = _run_karr( $repo, 'edit', '1,2,3', '--status', 'bogus' );
    is( $rv->{exit}, 2, 'exit 2' );
    for my $id ( 1 .. 3 ) {
        like( _task_doc( $repo, $id ), qr/^status: backlog$/m,
            "task $id untouched" );
    }
};

subtest '#54 valid values still go through' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'Fine',
            '--priority', 'high', '--class', 'expedite', '--due', '2026-03-15'
        )->{exit}, 0, 'create with valid options' );
    is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'agent-fox' )->{exit},
        0, 'move to a configured status' );
    is( _run_karr( $repo, 'move', '1', '--next', '--claim', 'agent-fox' )->{exit},
        0, '--next needs no explicit status' );
};

subtest '#54 a board that is already broken stays repairable' => sub {
    # Validation is on the write path only, exactly like kanban-md: a task that
    # already carries a bad status has to remain loadable or `karr move` could
    # never put it back.
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'Wedged' )->{exit}, 0, 'setup' );

    my $doc = _task_doc( $repo, 1 );
    $doc =~ s/^status: backlog$/status: totally-invalid/m;
    ok( App::karr::Git->new( dir => $repo )
            ->write_ref( 'refs/karr/tasks/1/data', $doc ),
        'forged a ref carrying a status no config has' );

    like( _task_doc( $repo, 1 ), qr/^status: totally-invalid$/m, 'ref is wedged' );

    my $show = _run_karr( $repo, 'show', '1' );
    is( $show->{exit}, 0, 'show still reads it' );

    my $fix = _run_karr( $repo, 'move', '1', 'todo' );
    is( $fix->{exit}, 0, 'and move can put it back' ) or diag $fix->{stderr};
    like( _task_doc( $repo, 1 ), qr/^status: todo$/m, 'repaired' );
};

# ---------------------------------------------------------------------------
# #58 / #69 -- interop with a kanban-md task document
# ---------------------------------------------------------------------------

subtest '#58/#69 a kanban-md task keeps its block_reason and unknown fields'
    => sub {
    my $repo = _board_repo();
    path($repo)->child('tasks')->mkpath;
    path($repo)->child('tasks/002-external.md')->spew_utf8( <<'END' );
---
id: 2
title: External task
status: backlog
priority: medium
class: standard
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
blocked: true
block_reason: upstream outage
custom_field: keep me
---

Body text here.
END
    path($repo)->child('config.yml')
        ->spew_utf8("version: 1\nboard:\n  name: Validation Board\n");

    is( _run_karr( $repo, 'import', '--yes' )->{exit}, 0, 'import succeeds' );

    my $doc = _task_doc( $repo, 2 );
    like( $doc, qr/^blocked: true$/m,                 'blocked stays a boolean' );
    like( $doc, qr/^block_reason: upstream outage$/m, 'block_reason survives' );
    like( $doc, qr/^custom_field: keep me$/m,         'unknown field survives' );

    # And still there after karr writes the task itself.
    is( _run_karr( $repo, 'edit', '2', '--priority', 'high' )->{exit}, 0, 'edit' );
    my $after = _task_doc( $repo, 2 );
    like( $after, qr/^block_reason: upstream outage$/m, 'reason survives a karr write' );
    like( $after, qr/^custom_field: keep me$/m,         'and so does the unknown field' );
    like( $after, qr/^priority: high$/m,                'the edit landed' );

    my $show = _run_karr( $repo, 'show', '2', '--json' );
    my $json = decode_json( $show->{stdout} );
    is( $json->{blocked}, JSON::MaybeXS::true(), '--json reports blocked as true' );
    is( $json->{block_reason}, 'upstream outage', 'and carries the reason' );
    is( $json->{custom_field}, 'keep me',         'and the passthrough field' );
};

subtest '#58 karr edit --block writes the kanban-md shape' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'Blocked task' )->{exit}, 0, 'setup' );
    is( _run_karr( $repo, 'edit', '1', '--block', 'waiting on API' )->{exit},
        0, 'edit --block' );

    my $doc = _task_doc( $repo, 1 );
    like( $doc, qr/^blocked: true$/m, 'blocked: true, not the free text' );
    like( $doc, qr/^block_reason: waiting on API$/m, 'reason in its own field' );

    like( _run_karr( $repo, 'show', '1' )->{stdout},
        qr/^Blocked:\s+waiting on API$/m, 'show still prints the reason' );
    like( _run_karr( $repo, 'board' )->{stdout},
        qr/blocked:waiting on API/, 'board still prints the reason' );

    is( _run_karr( $repo, 'edit', '1', '--unblock' )->{exit}, 0, 'unblock' );
    unlike( _task_doc( $repo, 1 ), qr/^block/m, 'both keys gone' );
};

# ---------------------------------------------------------------------------
# #68 -- lifecycle through the CLI
# ---------------------------------------------------------------------------

subtest '#68 completed does not survive a reopen' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'Lifecycle' )->{exit}, 0, 'setup' );

    is( _run_karr( $repo, 'move', '1', 'done' )->{exit}, 0, 'move to done' );
    like( _task_doc( $repo, 1 ),
        qr/^completed: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/m,
        'completed is a full timestamp' );

    is( _run_karr( $repo, 'move', '1', 'todo' )->{exit}, 0, 'reopen' );
    unlike( _task_doc( $repo, 1 ), qr/^completed:/m,
        'completed cleared -- it used to sit there making the task look done' );
    like( _task_doc( $repo, 1 ), qr/^started:/m, 'started is kept' );
};

subtest '#68 started is a full timestamp, not a bare date' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'Started' )->{exit}, 0, 'setup' );
    is( _run_karr( $repo, 'move', '1', 'in-progress', '--claim', 'agent-fox' )->{exit},
        0, 'move to in-progress' );
    like( _task_doc( $repo, 1 ),
        qr/^started: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/m,
        'started carries a time, which karr metrics will need' );
};

subtest '#68 archive stamps the terminal move too' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'Archived' )->{exit}, 0, 'setup' );
    is( _run_karr( $repo, 'archive', '1' )->{exit}, 0, 'archive' );
    like( _task_doc( $repo, 1 ), qr/^completed:/m,
        'archived is terminal, so completed is set' );
    like( _task_doc( $repo, 1 ), qr/^started:/m, 'and so is started' );
};

# ---------------------------------------------------------------------------
# #78 -- the small ones, through the CLI
# ---------------------------------------------------------------------------

subtest '#78 karr create --body 0 keeps the body' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'create', 'Zero body', '--body', '0' )->{exit}, 0, 'create' );
    like( _task_doc( $repo, 1 ), qr/---\n\n0\n\z/, 'the body reached the ref' );
    like( _run_karr( $repo, 'show', '1' )->{stdout}, qr/\n0\n/, 'show prints it' );
    is( decode_json( _run_karr( $repo, 'show', '1', '--json' )->{stdout} )->{body},
        '0', '--json carries it' );

    # And appending must not replace it.
    is( _run_karr( $repo, 'edit', '1', '-a', 'second line' )->{exit}, 0, 'append' );
    like( _task_doc( $repo, 1 ), qr/\n0\nsecond line\n\z/,
        'the "0" line survives an append' );

    is( _run_karr( $repo, 'create', 'Handoff zero', '--body', '0' )->{exit},
        0, 'a second task with a zero body' );
    is( _run_karr( $repo, 'handoff', '2', '--claim', 'agent-fox',
            '--note', 'a note' )->{exit}, 0, 'handoff --note' );
    like( _task_doc( $repo, 2 ), qr/\n0\na note\n\z/,
        'and it survives a handoff note too' );
};

subtest '#78 import refuses a config that does not validate' => sub {
    my $repo = _board_repo();
    path($repo)->child('tasks')->mkpath;
    # A real card, because import refuses an empty file view outright now --
    # that guard would otherwise mask the config check this is about.
    path($repo)->child('tasks/001-a-card.md')->spew_utf8( <<'END' );
---
id: 1
title: A card
status: backlog
priority: medium
class: standard
created: 2026-01-01T00:00:00Z
updated: 2026-01-01T00:00:00Z
---
END
    path($repo)->child('config.yml')->spew_utf8( <<'END' );
version: 1
board:
  name: Broken
defaults:
  status: nonexistent
  priority: bogus
END
    my $rv = _run_karr( $repo, 'import', '--yes' );
    isnt( $rv->{exit}, 0, 'import fails' );
    like( $rv->{stderr}, qr/Board config is invalid: /, 'and says why' );

    # The board still has its original defaults.
    like( _run_karr( $repo, 'config', 'get', 'defaults.status' )->{stdout},
        qr/^backlog\b/, 'defaults.status untouched' );
};

subtest '#78 karr config set claim_timeout takes a compound duration' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'config', 'set', 'claim_timeout', '1h30m' )->{exit},
        0, '1h30m accepted' );
    like( _run_karr( $repo, 'config', 'get', 'claim_timeout' )->{stdout},
        qr/^1h30m\b/, 'and stored' );

    my $bad = _run_karr( $repo, 'config', 'set', 'claim_timeout', '7d' );
    is( $bad->{exit}, 2, '7d rejected with exit 2 (Go has no day unit either)' );
    like( $bad->{stderr}, qr/Usage error: invalid claim_timeout "7d"/, 'and says why' );
};

subtest '#78 config show survives a board whose schema is broken' => sub {
    my $repo = _board_repo();
    # Forge a config ref that karr itself would now refuse to write.
    ok( App::karr::Git->new( dir => $repo )->write_ref(
            'refs/karr/config', "---\nversion: 1\nboard:\n  name: B\nstatuses: 42\n" ),
        'forged a config ref with a scalar where the status list belongs' );

    my $rv = _run_karr( $repo, 'config', 'show' );
    is( $rv->{exit}, 0, 'config show still exits 0' );
    unlike( $rv->{stderr}, qr/ARRAY ref|strict refs/,
        'no raw Perl dereference error leaks out' );
    like( $rv->{stdout}, qr/^board\.name\s+B$/m, 'and it prints what it can' );
};

done_testing;
