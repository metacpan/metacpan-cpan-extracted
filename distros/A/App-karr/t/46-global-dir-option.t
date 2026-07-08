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

# Regression tests for karr board ticket #14.
#
# BUG: the documented global --dir option is silently ignored by dispatched
#     subcommands. `karr --dir /path/to/B create "X"` (root form) writes into
#     the CWD's board instead of B's, with exit 0 and no diagnostic --
#     App::karr.pm documents "--dir overrides" board discovery and declares
#     `option dir => (...)` on the ROOT class, but MooX::Cmd dispatches to
#     App::karr::Cmd::* objects that never get that attribute, so
#     BoardDiscovery::_build_git_root's `$self->can('has_dir') && $self->has_dir`
#     check is always false on the dispatched Cmd and discovery falls back to
#     cwd. Cmd::Init/Backup/Restore/Destroy additionally hardcode
#     `Git->new(dir => '.')` outright, bypassing BoardDiscovery entirely. This
#     exact shape (root-form --dir silently targeting cwd) caused real
#     accidental writes to the maintainer's dogfood board during ticket #13,
#     remediated from dangling commits.
#
# DESIGN (recorded on ticket #14, `karr show 14`): both call shapes must work
#     or fail LOUDLY -- never silently fall back to cwd:
#       - `karr CMD --dir X`   (Cmd-level option)
#       - `karr --dir X CMD`   (root form; MooX::Cmd passes command_chain to
#          execute(), the Cmd adopts the root's dir)
#     Discovery starts at the given path and still walks up looking for a Git
#     repo (parity note below). Invalid --dir (nonexistent path, or an
#     existing directory that isn't a Git repo) must produce a clean,
#     non-zero-exit error and must NOT operate on the cwd board. init/backup
#     (and by extension restore/destroy) must honour --dir too.
#
# PARITY CHECK (../kanban-md/cmd/root.go, requested on this ticket before
#     writing coverage): kanban-md's --dir is a cobra PersistentFlag bound to
#     a single package-level var, so both "before" and "after" the subcommand
#     name are equivalent to cobra's parser -- there is no root-form/cmd-form
#     distinction there, which is *why* kanban-md never had this bug shape.
#     Its resolveDir() returns flagDir verbatim with NO walk-up when set
#     (internal/config.FindDir's walk-up only applies to the unset/cwd case).
#     karr's already-agreed design deliberately diverges here: --dir is a
#     Git-repo discovery seed, not a literal kanban-directory path, so karr's
#     walk-up applies even when --dir is given (see DESIGN above). This is a
#     recorded, intentional divergence, not an open question.
#
# None of this is implemented yet (no lib/ changes accompany this test).
# Every subtest below was hand-probed against the current tree (VERSION
# 0.304, pre-#14-fix) before writing assertions; the exact current behaviour
# is recorded per subtest. All of them assert the desired post-fix contract,
# so all are expected RED until #14 lands:
#
#   - Cmd-form (`CMD --dir X`) on list/show/backup/init: today MooX::Options
#     doesn't know a `dir` option on the dispatched Cmd class at all, so it
#     dies "Unknown option: dir" (exit 1) before touching any board -- an
#     accidental non-zero exit, but for the wrong reason and with the wrong
#     message, not a validated/clean --dir error.
#   - Root-form (`--dir X CMD`) on list/show/backup: today silently succeeds
#     (exit 0) against the CWD's board, never touching X at all -- the exact
#     incident shape.
#   - Root-form on init: today dies "Board already exists in refs/karr/"
#     (exit 255) because it hardcodes dir => '.' and finds the CWD's
#     pre-existing board -- again non-zero, but for the wrong reason, and it
#     never touches the target repo.
#   - Invalid --dir in root form: today silently succeeds (exit 0) against
#     the CWD board -- the most dangerous shape, explicitly called out in the
#     ticket as "never silently fall back".

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

# Raw dump of every ref under refs/karr/* for a repo, read directly via git
# (never through karr itself), so "board A is untouched" assertions don't
# depend on the very discovery/read path this ticket is about fixing.
sub _refs_dump {
    my ($repo) = @_;
    my @cmd = ( 'git', '-C', $repo, 'for-each-ref',
        '--format=%(refname) %(objectname)', 'refs/karr' );
    open( my $fh, '-|', @cmd ) or die "can't run @cmd: $!";
    local $/;
    my $out = <$fh>;
    close $fh;
    return defined $out ? $out : '';
}

# Fresh isolated git repo + karr board, deliberately WITHOUT a remote (so
# sync_before/sync_after retry loops can't interfere with or slow down these
# assertions), seeded with one task whose title embeds $label so board A's
# and board B's output are trivially distinguishable from each other no
# matter which board a given command actually landed on.
sub _setup_board {
    my ($label) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

    my @remotes = `git -C '$repo' remote`;
    is( scalar(@remotes), 0, "board $label repo has no remote configured" );

    my $init = _run_karr( $repo, 'init', '--name', "Board $label" );
    is( $init->{exit}, 0, "karr init succeeds for board $label" ) or diag $init->{stderr};

    my $create = _run_karr( $repo, 'create', "$label-Only Seed Task" );
    is( $create->{exit}, 0, "seed task created for board $label" ) or diag $create->{stderr};

    return $repo;
}

# ----------------------------------------------------------------- Setup: two
# independent boards, A and B, never sharing a repo. Every _run_karr() call
# below uses cwd => $A unless a subtest explicitly says otherwise, matching
# the ticket's "Prozess-cwd ist immer A" requirement. State on A accumulates
# across subtests further down (including the deliberate incident repro in
# subtest 3) -- this mirrors the real dogfood incident, and every assertion
# below distinguishes boards by title/content, never by task count, so
# accumulation doesn't invalidate later checks. Board B is asserted never to
# change except in the one subtest that legitimately targets it.

my $A = _setup_board('A');
my $B = _setup_board('B');

# ------------------------------------------------------------- (1) Cmd-form:
# `karr list --dir B --compact` from cwd A.

subtest 'list --dir B --compact (cmd-form) shows B tasks, not A (RED, ticket #14)' => sub {
    my $rv = _run_karr( $A, 'list', '--dir', $B, '--compact' );

    # Probed today: dies "Unknown option: dir" (exit 1) -- MooX::Options
    # doesn't know a Cmd-level `dir` option yet, so this never reaches any
    # board at all.
    is( $rv->{exit}, 0, 'list --dir B --compact exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/B-Only Seed Task/, 'stdout shows B\'s seed task' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'stdout does NOT show A\'s seed task' );
};

# ------------------------------------------------------- (2) Root-form: this
# IS the incident shape.

subtest '--dir B list --compact (root-form) shows B tasks, not A (RED, ticket #14 -- the incident shape)' => sub {
    my $rv = _run_karr( $A, '--dir', $B, 'list', '--compact' );

    # Probed today: exit 0, silently prints A's own list ("#1 backlog
    # A-Only Seed Task") -- --dir is parsed at the root but never reaches
    # the dispatched Cmd::List object, so discovery falls back to cwd.
    is( $rv->{exit}, 0, '--dir B list --compact exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/B-Only Seed Task/, 'stdout shows B\'s seed task' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'stdout does NOT show A\'s seed task' );
};

# ---------------------------------------------- (3) The exact incident case:
# `karr --dir B create "..."` from cwd A must create in B and leave A's refs
# byte-for-byte unchanged.

subtest '--dir B create "Neu" (root-form) from cwd A creates in B, A left untouched (RED, ticket #14 -- exact incident repro)' => sub {
    my $before_A = _refs_dump($A);

    my $rv = _run_karr( $A, '--dir', $B, 'create', 'Neu In B' );

    # Probed today: exit 0, "Created task 2: Neu In B" -- but the task lands
    # in A (board A now has an extra task #2), not B. This is the exact
    # accidental-write shape that polluted the real dogfood board.
    is( $rv->{exit}, 0, '--dir B create "Neu In B" exits 0' ) or diag $rv->{stderr};

    my $after_A = _refs_dump($A);
    is( $after_A, $before_A, "board A's refs/karr/* are byte-identical before/after -- no accidental write" );

    my $list_B = _run_karr( $B, 'list', '--compact' );
    is( $list_B->{exit}, 0, 'list on B exits 0' ) or diag $list_B->{stderr};
    like( $list_B->{stdout}, qr/Neu In B/, 'the new task actually landed in board B' );

    my $list_A = _run_karr( $A, 'list', '--compact' );
    is( $list_A->{exit}, 0, 'list on A exits 0' ) or diag $list_A->{stderr};
    unlike( $list_A->{stdout}, qr/Neu In B/, 'board A does NOT contain the task meant for B' );
};

# --------------------------------------------------------------- (4) Show
# with a title that is unmistakably B's, not A's.

subtest 'show --dir B 1 (cmd-form) shows B\'s task 1, not A\'s (RED, ticket #14)' => sub {
    my $rv = _run_karr( $A, 'show', '--dir', $B, 1 );

    # Probed today: dies "Unknown option: dir" (exit 1), same as list.
    is( $rv->{exit}, 0, 'show --dir B 1 exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^Task #1: B-Only Seed Task$/m, 'shows B\'s task 1 by its distinguishing title' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'does NOT show A\'s task' );
};

subtest '--dir B show 1 (root-form) shows B\'s task 1, not A\'s (RED, ticket #14)' => sub {
    my $rv = _run_karr( $A, '--dir', $B, 'show', 1 );

    # Probed today: exit 0, silently shows A's own task #1
    # ("Task #1: A-Only Seed Task").
    is( $rv->{exit}, 0, '--dir B show 1 exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^Task #1: B-Only Seed Task$/m, 'shows B\'s task 1 by its distinguishing title' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'does NOT show A\'s task' );
};

# --------------------------------------------------------------- (5) Init on
# a fresh, boardless repo via --dir, in both call shapes. A already has a
# board (from setup), so a correct fix must neither touch A nor complain
# about A's pre-existing board.

subtest 'init --dir C (cmd-form) creates the board in C, not A (RED, ticket #14)' => sub {
    my $C = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $C );
    _git_ok( 'git', '-C', $C, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $C, 'config', 'user.name', 'Test User' );

    my $before_A = _refs_dump($A);

    my $rv = _run_karr( $A, 'init', '--dir', $C, '--name', 'Board C' );

    # Probed today: dies "Unknown option: dir" (exit 1) -- Cmd::Init has no
    # `dir` option and never touches C at all.
    is( $rv->{exit}, 0, 'init --dir C exits 0' ) or diag $rv->{stderr};

    is( _refs_dump($A), $before_A, "board A's refs are unchanged by init --dir C" );

    my $c_refs = _refs_dump($C);
    like( $c_refs, qr{refs/karr/config}, 'refs/karr/config now exists in C' );
};

subtest '--dir C2 init (root-form) creates the board in C2, not A (RED, ticket #14)' => sub {
    my $C2 = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $C2 );
    _git_ok( 'git', '-C', $C2, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $C2, 'config', 'user.name', 'Test User' );

    my $before_A = _refs_dump($A);

    my $rv = _run_karr( $A, '--dir', $C2, 'init', '--name', 'Board C2' );

    # Probed today: dies "Board already exists in refs/karr/\n" (exit 255)
    # -- Cmd::Init hardcodes Git->new(dir => '.'), which resolves to A (the
    # CWD), which already has a board from setup. C2 is never touched.
    is( $rv->{exit}, 0, '--dir C2 init exits 0' ) or diag $rv->{stderr};

    is( _refs_dump($A), $before_A, "board A's refs are unchanged by --dir C2 init" );

    my $c2_refs = _refs_dump($C2);
    like( $c2_refs, qr{refs/karr/config}, 'refs/karr/config now exists in C2' );
};

# ------------------------------------------------------------- (6) Backup on
# B via --dir, in both call shapes.

subtest 'backup --dir B (cmd-form) snapshots B, not A (RED, ticket #14)' => sub {
    my $rv = _run_karr( $A, 'backup', '--dir', $B );

    # Probed today: dies "Unknown option: dir" (exit 1) -- Cmd::Backup has
    # no `dir` option.
    is( $rv->{exit}, 0, 'backup --dir B exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/name: Board B/, 'snapshot contains board B\'s name' );
    like( $rv->{stdout}, qr/B-Only Seed Task/, 'snapshot contains B\'s seed task' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'snapshot does NOT contain A\'s seed task' );
};

subtest '--dir B backup (root-form) snapshots B, not A (RED, ticket #14)' => sub {
    my $rv = _run_karr( $A, '--dir', $B, 'backup' );

    # Probed today: exit 0, silently dumps A's own snapshot (name: Board A,
    # A-Only Seed Task, plus the "Neu In B" task accidentally created there
    # by an earlier probe) -- Cmd::Backup hardcodes dir => '.'.
    is( $rv->{exit}, 0, '--dir B backup exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/name: Board B/, 'snapshot contains board B\'s name' );
    like( $rv->{stdout}, qr/B-Only Seed Task/, 'snapshot contains B\'s seed task' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'snapshot does NOT contain A\'s seed task' );
};

# ------------------------------------------------------------ (7) Invalid
# --dir must fail loudly and cleanly, never silently fall back to A. Uses
# fresh System::TMPDIR-rooted paths (never nested under A/B/the repo) so the
# walk-up-inclusive design (see PARITY CHECK above) can't accidentally climb
# into an unrelated real repository above them.

subtest 'list --dir /nonexistent (cmd-form): clean error, no fallback to A (RED, ticket #14)' => sub {
    my $bogus_parent = tempdir( CLEANUP => 1 );
    my $bogus = "$bogus_parent/does-not-exist";

    my $rv = _run_karr( $A, 'list', '--dir', $bogus, '--compact' );

    # Probed today: dies "Unknown option: dir" (exit 1) -- non-zero, but for
    # the wrong reason (option parsing, not path validation).
    isnt( $rv->{exit}, 0, 'list --dir /nonexistent exits non-zero' );
    like( $rv->{stderr}, qr/not a git repository/i, 'stderr gives a clean "not a git repository" diagnostic' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'stdout shows nothing from board A' );
};

subtest '--dir /nonexistent list (root-form): clean error, no silent fallback to A (RED, ticket #14)' => sub {
    my $bogus_parent = tempdir( CLEANUP => 1 );
    my $bogus = "$bogus_parent/does-not-exist";

    my $rv = _run_karr( $A, '--dir', $bogus, 'list', '--compact' );

    # Probed today: exit 0, silently prints A's own list -- the dangerous
    # silent-fallback shape the ticket explicitly forbids.
    isnt( $rv->{exit}, 0, '--dir /nonexistent list exits non-zero' );
    like( $rv->{stderr}, qr/not a git repository/i, 'stderr gives a clean "not a git repository" diagnostic' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'stdout shows nothing from board A' );
};

subtest '--dir <existing, non-git dir> list (root-form): clean error, no silent fallback to A (RED, ticket #14)' => sub {
    my $no_git = tempdir( CLEANUP => 1 );    # exists, deliberately never git-inited

    my $rv = _run_karr( $A, '--dir', $no_git, 'list', '--compact' );

    # Probed today: exit 0, silently prints A's own list -- same dangerous
    # silent-fallback shape as the nonexistent-path case above.
    isnt( $rv->{exit}, 0, '--dir <non-git dir> list exits non-zero' );
    like( $rv->{stderr}, qr/not a git repository/i, 'stderr gives a clean "not a git repository" diagnostic' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'stdout shows nothing from board A' );
};

# ------------------------------------------------------------- ticket #15:
# bare `karr --dir PATH` (root-form, NO subcommand, space-separated value)
# dies "Unknown command: PATH" (exit 2) instead of rendering that board.
#
# ROOT CAUSE: the unknown-command guard in App::karr::execute (added for
# ticket #5, see t/41-cli-error-exits.t) does a raw
# `grep { !/^-/ } @$args_ref` over the leftover argv MooX::Cmd hands to
# execute() when nothing dispatched. That grep cannot tell a genuine leftover
# bare word (an actual unknown subcommand) apart from the already-parsed
# --dir value MooX::Cmd echoes back as a bare token in space form -- so
# `karr --dir /path/to/B` trips the guard on "/path/to/B" itself, even though
# --dir was successfully parsed and nothing is actually unrecognised.
# `karr --dir=/path/to/B` (equals form) never echoes a bare token, so it
# already works and must not regress.
#
# The fix (not part of this test -- lib/ changes are the karr-worker's job)
# is to run the guard's leftover-argv check through
# $self->positional_args($args_ref) (the same option-aware extractor from
# ticket #13, usable here because ticket #14 registered `dir` with
# `format => 's'` in App::karr's own _options_data via
# Role::BoardDiscovery) instead of the raw grep, so an option's own value
# token is correctly skipped rather than misread as a positional.
#
# Reuses boards A and B from the ticket #14 setup above; cwd is always A,
# per this file's established convention, and boards are told apart by
# their seeded task titles/board names, never by task count (state on both
# accumulates across this whole file).

subtest '--dir B (root-form, no subcommand, space form): renders board B, not "Unknown command" (RED, ticket #15)' => sub {
    my $rv = _run_karr( $A, '--dir', $B );

    # Probed today: exit 2, stderr "Unknown command: $B" -- the space-form
    # --dir value gets misread as an unknown bare subcommand by the guard's
    # raw grep, so the board is never rendered at all.
    is( $rv->{exit}, 0, '--dir B (space form, no subcommand) exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^# Board B$/m, 'stdout renders board B\'s own name/header' );
    like( $rv->{stdout}, qr/B-Only Seed Task/, 'stdout shows B\'s seed task' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'stdout does NOT show A\'s seed task' );
};

subtest '--dir=B (root-form, no subcommand, equals form): renders board B (GREEN pin, must survive the #15 fix)' => sub {
    my $rv = _run_karr( $A, "--dir=$B" );

    is( $rv->{exit}, 0, '--dir=B (equals form, no subcommand) exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^# Board B$/m, 'stdout renders board B\'s own name/header' );
    like( $rv->{stdout}, qr/B-Only Seed Task/, 'stdout shows B\'s seed task' );
    unlike( $rv->{stdout}, qr/A-Only Seed Task/, 'stdout does NOT show A\'s seed task' );
};

subtest '--dir B definitiv-kein-kommando (root-form + a real unknown subcommand): names the unknown command, not the --dir path (RED, ticket #15)' => sub {
    my $rv = _run_karr( $A, '--dir', $B, 'definitiv-kein-kommando' );

    # Probed today: exit 2, stderr "Unknown command: $B" -- the raw grep
    # picks up the --dir value as the "unknown" token (it's the first
    # non-dash word in the leftover argv) before it ever reaches the actual
    # unrecognised subcommand, so the diagnostic misnames the -dir path
    # instead of the real offending word.
    isnt( $rv->{exit}, 0, '--dir B definitiv-kein-kommando exits non-zero' );
    like( $rv->{stderr}, qr/\Qdefinitiv-kein-kommando\E/,
        'stderr names the actual unrecognised subcommand' );
    unlike( $rv->{stderr}, qr/\Q$B\E/,
        'stderr does NOT name the --dir path instead (RED today)' );
};

done_testing;
