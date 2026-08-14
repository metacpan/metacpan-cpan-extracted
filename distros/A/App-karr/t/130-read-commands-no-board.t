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

# Ticket #135: board, list, show, log and context called neither sync_before
# nor require_board, so they rendered the code defaults over an empty task list
# and a repository holding no board printed exactly what a board holding no
# cards prints -- down to the byte, once the board is called "Kanban Board".
# `git clone` does not fetch refs/karr/*, so that is the normal state of every
# fresh clone, where the user's tickets are all still on the remote. A user who
# trusted the output concluded the tickets were gone.
#
# The fix keeps the reads offline (no sync round trip in front of every `karr
# show`) and makes them ask what require_board asks after its pull, through
# App::karr::Role::BoardDiscovery::require_local_board:
#
#   nothing under refs/karr/  -> refuse, exit 1, say so, and where there is a
#                                remote lead with `karr sync` rather than
#                                `karr init` -- the board is unfetched, not
#                                absent, and init would start a second one.
#   half-board (#133)         -> read it; the tasks are demonstrably there.
#                                The note that the config ref is missing goes
#                                to STDERR so --json stays parsable.
#   initialized, no tasks     -> unchanged: an empty board is a real answer.
#
# Ticket #136 is the sibling that was deliberately left out of #135: `karr
# config get`/`config show` were in the same position, calling neither
# sync_before nor require_board -- Cmd/Config.pm did both only in the `set`
# branch. They answered from the code defaults instead, which the command
# documented as a deliberate choice. For most keys that really is a useful
# answer; for `board.name` it is not an answer at all, only karr's placeholder,
# and in the fresh clone above the board it belongs to is sitting on the remote
# with a name of its own. Measured before the fix: `karr config get board.name`
# in that clone printed "Kanban Board" at exit 0 and left the clone holding 0
# karr refs; `karr sync` fetched 6 and the same command then said "Remote
# Board". So the two states were byte-identical here as well.
#
# The resolution keeps both answers but stops them sharing one command
# invocation: `show`/`get` answer for this board and refuse like every other
# read, and `--defaults` asks for karr's built-in values on purpose. That makes
# the distinction the ticket asks for -- "the board's value" vs "what karr would
# use if you made one" -- readable from the exit code alone, with no STDERR
# parsing, and it holds for every key rather than for a hand-maintained list of
# keys deemed identity-bearing. See the #136 subtests at the bottom.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

# Every read command in the ticket, in both renderings, plus the bare `karr`
# default summary (lib/App/karr.pm), which wraps Cmd::Board -- and the two
# config reads #136 added to the same contract.
my @READ_ARGV = (
    ['board'], [ 'board', '--json' ],
    ['list'],  [ 'list',  '--json' ],
    ['show'],  [ 'show',  '--json' ],
    ['log'],   [ 'log',   '--json' ],
    ['context'], [ 'context', '--json' ],
    [],
    [ 'config', 'show' ], [ 'config', 'show', '--json' ],
    [ 'config', 'get', 'board.name' ],
    [ 'config', 'get', 'board.name', '--json' ],
);

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

sub _label { my @a = @_; return @a ? "karr @a" : 'karr (bare)' }

sub _repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or BAIL_OUT('git init failed');
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' ) == 0
        or BAIL_OUT('git config failed');
    system( 'git', '-C', $repo, 'config', 'user.name', 'Test User' ) == 0
        or BAIL_OUT('git config failed');
    return $repo;
}

sub _board_repo {
    my ( $name, @titles ) = @_;
    my $repo = _repo();
    _run_karr( $repo, 'init', '--name', $name )->{exit} == 0
        or BAIL_OUT('karr init failed');
    for my $title (@titles) {
        _run_karr( $repo, 'create', $title )->{exit} == 0
            or BAIL_OUT("karr create failed for $title");
    }
    return $repo;
}

subtest 'a repository with no board refuses to answer as if it were empty' => sub {
    my $repo = _repo();

    for my $argv (@READ_ARGV) {
        my $label = _label(@$argv);
        my $rv    = _run_karr( $repo, @$argv );

        is( $rv->{exit}, 1, "$label exits 1 where there is no board" );
        # Nothing on stdout at all: a --json consumer gets no payload to
        # mistake for a board, and a human gets no board-shaped output either.
        is( $rv->{stdout}, '', "$label prints nothing on stdout" );
        like( $rv->{stderr}, qr{nothing is stored under refs/karr/},
            "$label says what was actually looked at" );
        like( $rv->{stderr}, qr{not an empty board},
            "$label denies the reading that cost the tickets" );
        like( $rv->{stderr}, qr{karr init}, "$label says how to get a board" );
        # No remote here, so `karr sync` has nothing to fetch from and must not
        # be offered as the first thing to try.
        unlike( $rv->{stderr}, qr{karr sync},
            "$label does not send a remote-less repository to sync" );
    }
};

subtest 'an initialized board with no tasks still reads as an empty board' => sub {
    # The other half of the distinction, and the assertion that fails if anyone
    # ever "fixes" #135 by refusing whenever the task list comes back empty.
    my $repo = _board_repo('Empty Board');

    my $board = _run_karr( $repo, 'board' );
    is( $board->{exit}, 0, 'karr board still renders an empty board' );
    like( $board->{stdout}, qr{# Empty Board}, 'with the board name it was given' );
    like( $board->{stdout}, qr{^0 tasks}m, 'and its honest zero' );

    my $json = _run_karr( $repo, 'board', '--json' );
    is( $json->{exit}, 0, 'karr board --json too' );
    my $data = eval { decode_json( $json->{stdout} ) };
    is( $data->{total}, 0, 'reporting a total of 0' ) or diag $json->{stderr};
    is( $data->{name}, 'Empty Board', 'under the real board name' );

    is( _run_karr( $repo, 'list' )->{exit},    0, 'karr list works' );
    is( _run_karr( $repo, 'list', '--json' )->{stdout}, "[]\n", 'and answers []' );
    like( _run_karr( $repo, 'show' )->{stdout}, qr{No tasks found}, 'karr show works' );
    like( _run_karr( $repo, 'log' )->{stdout},  qr{No log entries}, 'karr log works' );
    like( _run_karr( $repo, 'context' )->{stdout}, qr{BEGIN kanban-md context},
        'karr context works' );

    # #136: a board with no tasks still has a config, and it is the board's.
    my $name = _run_karr( $repo, 'config', 'get', 'board.name' );
    is( $name->{exit},   0,               'karr config get works' );
    is( $name->{stdout}, "Empty Board\n", 'and answers the board its own name' );
    is( _run_karr( $repo, 'config', 'show' )->{exit}, 0, 'karr config show works' );
};

subtest 'a fresh clone is told the board is unfetched, not missing' => sub {
    my $work   = tempdir( CLEANUP => 1 );
    my $origin = "$work/origin.git";
    system( 'git', 'init', '-q', '--bare', $origin ) == 0
        or BAIL_OUT('git init --bare failed');

    my $source = _board_repo( 'Remote Board', 'a ticket that exists' );
    system( 'git', '-C', $source, 'remote', 'add', 'origin', $origin ) == 0
        or BAIL_OUT('git remote add failed');
    is( _run_karr( $source, 'sync' )->{exit}, 0, 'setup: the board reaches the remote' );

    my $clone = "$work/clone";
    system("git clone -q '$origin' '$clone' 2>/dev/null");
    system( 'git', '-C', $clone, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $clone, 'config', 'user.name',  'Test User' );

    my @refs = `git -C '$clone' for-each-ref --format='%(refname)' 'refs/karr/'`;
    is( scalar @refs, 0, 'setup: git clone fetched none of refs/karr/*' );

    for my $argv (@READ_ARGV) {
        my $label = _label(@$argv);
        my $rv    = _run_karr( $clone, @$argv );

        is( $rv->{exit}, 1, "$label refuses in a fresh clone" );
        is( $rv->{stdout}, '', "$label prints nothing on stdout" );
        like( $rv->{stderr}, qr{git clone.*does not fetch}s,
            "$label explains why a clone starts out board-less" );
        like( $rv->{stderr}, qr{karr sync}, "$label offers the fetch first" );
        # init stays in the message, but after sync: it is the answer for a
        # repository that never had a board, not for one whose board is on the
        # remote -- running it here would start a second, empty board.
        like( $rv->{stderr}, qr{karr sync.*karr init}s,
            "$label puts sync before init, not the other way round" );
    }

    # #136's measurement, in the state it was measured in: before the sync the
    # clone must not answer the placeholder name for a board that has one.
    my $before = _run_karr( $clone, 'config', 'get', 'board.name' );
    unlike( $before->{stdout}, qr{Kanban Board},
        'config get board.name does not answer the placeholder in a fresh clone' );

    is( _run_karr( $clone, 'sync' )->{exit}, 0, 'the advice runs' );
    my $after = _run_karr( $clone, 'board' );
    is( $after->{exit}, 0, 'and the board reads afterwards' ) or diag $after->{stderr};
    like( $after->{stdout}, qr{# Remote Board}, 'as the board it always was' );
    like( $after->{stdout}, qr{a ticket that exists}, 'with the ticket that was never gone' );

    my $name = _run_karr( $clone, 'config', 'get', 'board.name' );
    is( $name->{exit},   0,                'config get board.name works after the sync' );
    is( $name->{stdout}, "Remote Board\n", 'and answers the name the board really has' );
};

subtest 'a half-board is read, not refused' => sub {
    # #133's state: task refs present, refs/karr/config gone. require_board
    # refuses a write here; a read must not, because refusing would hide tasks
    # that are demonstrably there -- the exact mistake that ticket was about.
    my $repo = _board_repo( 'Doomed', 'seeded 1', 'seeded 2' );
    system( 'git', '-C', $repo, 'update-ref', '-d', 'refs/karr/config' ) == 0
        or BAIL_OUT('update-ref -d failed');
    system( 'git', '-C', $repo, 'update-ref', '-d', 'refs/karr/meta/encoding' ) == 0
        or BAIL_OUT('update-ref -d failed');

    my $list = _run_karr( $repo, 'list' );
    is( $list->{exit}, 0, 'karr list still reads a half-board' ) or diag $list->{stderr};
    like( $list->{stdout}, qr{seeded 1}, 'and shows the tasks that are there' );
    like( $list->{stdout}, qr{seeded 2}, 'both of them' );
    like( $list->{stderr}, qr{half-initialized}, 'while naming the state on STDERR' );
    like( $list->{stderr}, qr{refs/karr/config is missing}, 'and which ref is gone' );
    like( $list->{stderr}, qr{karr init}, 'and how to complete it' );

    my $json = _run_karr( $repo, 'board', '--json' );
    is( $json->{exit}, 0, 'karr board --json too' );
    # The note is on STDERR precisely so this still decodes.
    my $data = eval { decode_json( $json->{stdout} ) };
    is( $data->{total}, 2, 'stdout stays parsable JSON, with both tasks in it' )
        or diag $json->{stdout};
    like( $json->{stderr}, qr{half-initialized}, 'and the note reaches STDERR under --json' );

    # #136: config lands here too, and this is the one state where the note's
    # own words -- "the name, statuses and defaults shown are karr's own, not
    # the board's" -- describe the whole of what the command prints. There is no
    # refs/karr/config to read, so every value is a default; refusing would
    # still be wrong, because two task refs say a board is here.
    my $show = _run_karr( $repo, 'config', 'show' );
    is( $show->{exit}, 0, 'karr config show reads a half-board' ) or diag $show->{stderr};
    like( $show->{stdout}, qr{^claim_timeout\s+1h$}m, 'printing what karr would use' );
    like( $show->{stderr}, qr{name, statuses and defaults shown are},
        'while STDERR says whose values those are' );

    my $cjson = _run_karr( $repo, 'config', 'show', '--json' );
    is( $cjson->{exit}, 0, 'karr config show --json too' );
    is( eval { decode_json( $cjson->{stdout} ) }->{board}{name},
        'Kanban Board', 'stdout stays parsable JSON' ) or diag $cjson->{stdout};
    like( $cjson->{stderr}, qr{half-initialized}, 'with the note on STDERR' );
};

subtest 'reads stay offline: an unreachable remote does not stop them' => sub {
    # The other constraint #135 has to respect. Refusing to render a board that
    # is not there must not turn into pulling before every read: `karr show` is
    # on the hot path for agents, and a stale read is recoverable where a stale
    # write is not. A remote that cannot be reached is the cheapest proof that
    # no read command touches the network.
    my $work = tempdir( CLEANUP => 1 );
    my $repo = _board_repo( 'Offline Board', 'local only' );
    system( 'git', '-C', $repo, 'remote', 'add', 'origin', "$work/nowhere.git" ) == 0
        or BAIL_OUT('git remote add failed');

    for my $argv (
        ['board'], ['list'], ['show'], ['log'], ['context'], [],
        # #136 explicitly kept this constraint: the config read path may not
        # gain a sync_before either. An unreachable remote is the proof.
        [ 'config', 'show' ], [ 'config', 'get', 'board.name' ],
        )
    {
        my $rv = _run_karr( $repo, @$argv );
        is( $rv->{exit}, 0, _label(@$argv) . ' reads without reaching the remote' )
            or diag $rv->{stderr};
    }
    like( _run_karr( $repo, 'list' )->{stdout}, qr{local only},
        'and answers from the local refs' );
    is( _run_karr( $repo, 'config', 'get', 'board.name' )->{stdout},
        "Offline Board\n", 'config included' );
};

subtest 'config refuses like the other reads, and names --defaults (#136)' => sub {
    my $repo = _repo();

    for my $argv (
        [ 'config', 'show' ], [ 'config', 'show', '--json' ],
        [ 'config', 'get', 'board.name' ], [ 'config', 'get', 'claim_timeout' ],
        [ 'config', 'get', 'statuses', '--json' ],
        )
    {
        my $label = _label(@$argv);
        my $rv    = _run_karr( $repo, @$argv );

        is( $rv->{exit}, 1, "$label exits 1 where there is no board" );
        is( $rv->{stdout}, '', "$label prints nothing on stdout" );
        # The whole of #136: the value that used to stand here was karr's, and
        # nothing said so. Neither the placeholder name nor the defaults it was
        # printed alongside may reach a caller as this board's config.
        unlike( $rv->{stdout}, qr{Kanban Board|backlog|1h},
            "$label leaks no default value as if it were the board's" );
        like( $rv->{stderr}, qr{nothing is stored under refs/karr/},
            "$label says what was actually looked at" );
        like( $rv->{stderr}, qr{karr config show --defaults},
            "$label points at where those defaults are still available" );
    }
};

subtest '--defaults answers the other question, in every state (#136)' => sub {
    # The defaults were a real answer to "what would a board created here look
    # like?" -- they were just answering it in place of a question about this
    # board. Asked on purpose they are true by construction, so they must hold
    # in all three states and outside a repository entirely.
    my $none = _repo();
    my $real = _board_repo('Echtes Board');
    my $bare = tempdir( CLEANUP => 1 );   # not a git repository at all

    for my $spec ( [ 'no board', $none ], [ 'a real board', $real ],
        [ 'no repository', $bare ] )
    {
        my ( $what, $dir ) = @$spec;

        my $show = _run_karr( $dir, 'config', 'show', '--defaults' );
        is( $show->{exit}, 0, "--defaults answers with $what" ) or diag $show->{stderr};
        like( $show->{stdout}, qr{^board\.name\s+Kanban Board$}m,
            "and says so with karr's placeholder name ($what)" );
        like( $show->{stdout}, qr{^claim_timeout\s+1h$}m, "and karr's timeout ($what)" );
        is( $show->{stderr}, '', "no note is needed: nothing was implied ($what)" );

        my $json = _run_karr( $dir, 'config', 'show', '--defaults', '--json' );
        is( eval { decode_json( $json->{stdout} ) }->{board}{name},
            'Kanban Board', "--defaults --json is machine-usable ($what)" )
            or diag $json->{stdout};

        my $get = _run_karr( $dir, 'config', 'get', 'claim_timeout', '--defaults' );
        is( $get->{exit},   0,     "get --defaults answers with $what" );
        is( $get->{stdout}, "1h\n", "with the built-in value ($what)" );
    }

    # The distinction the ticket asked for, stated as one comparison: on a real
    # board the two forms disagree about board.name, and each is right about the
    # question it was asked. Before the fix a board-less repository could not
    # produce this disagreement at all -- both forms were the same call.
    my $board = _run_karr( $real, 'config', 'get', 'board.name' );
    is( $board->{stdout}, "Echtes Board\n", "config get board.name is the board's" );
    is( _run_karr( $real, 'config', 'get', 'board.name', '--defaults' )->{stdout},
        "Kanban Board\n", 'config get board.name --defaults is karr\'s' );

    # --defaults has nothing to write to, and saying so is a usage error (2),
    # not a runtime failure (1) -- ADR 0002.
    my $set = _run_karr( $real, 'config', 'set', 'board.name', 'X', '--defaults' );
    is( $set->{exit}, 2, 'config set --defaults is a usage error' );
    like( $set->{stderr}, qr{nothing to set}, 'and says why' );
    is( _run_karr( $real, 'config', 'get', 'board.name' )->{stdout},
        "Echtes Board\n", 'and wrote nothing' );

    # The board check must not swallow a plain misuse: `karr config bogus` in a
    # board-less repository still gets the answer that is about the typo.
    my $bogus = _run_karr( $none, 'config', 'bogus' );
    like( $bogus->{stderr}, qr{Unknown action: bogus},
        'an unknown action is still reported as one, board or no board' );
};

done_testing;
