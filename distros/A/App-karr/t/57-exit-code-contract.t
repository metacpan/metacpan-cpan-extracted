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

# Exit-code contract matrix for ticket #22 / ADR 0002
# (docs/adr/0002-exit-code-contract.md).
#
#   0  success (including no-op successes like re-archiving)
#   1  runtime failure: not found, board missing, not a git repo, a Git/sync
#      failure, a destructive command refused for want of --yes
#   2  usage error: unknown command, unknown option, invalid option value,
#      surplus or missing positional argument
#
# This pins the *exact* code, unlike the sibling CLI error tests (t/41, t/43,
# t/44, t/45, t/46) which mostly assert only a non-zero exit. Two mechanisms
# back the contract and both are exercised here:
#   - the central handler in bin/karr classifies uncaught command-body dies
#     into 1 (runtime) vs 2 (usage, by a stable leading marker);
#   - App::karr::Role::ExitCodes (and the root's _print_help) remap
#     MooX::Options option-parse errors from 1 to 2.

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

sub _git_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die "git init failed";
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

# A git repo with an initialized board and one seeded task (id 1).
sub _board_repo {
    my $repo = _git_repo();
    is( _run_karr( $repo, 'init', '--name', 'Contract Board' )->{exit},
        0, 'setup: karr init exits 0' );
    is( _run_karr( $repo, 'create', '--title', 'Sentinel', '--status', 'todo' )->{exit},
        0, 'setup: karr create exits 0' );
    return $repo;
}

# ------------------------------------------------------------------ exit 0

subtest 'success paths exit 0' => sub {
    my $repo = _board_repo();

    is( _run_karr( $repo, 'board' )->{exit},   0, 'board exits 0' );
    is( _run_karr( $repo, 'list' )->{exit},    0, 'list exits 0' );
    is( _run_karr( $repo, 'show', 1 )->{exit}, 0, 'show 1 exits 0' );

    # A no-op success: re-archiving an already-archived task stays 0 (ADR 0002
    # calls this out explicitly).
    is( _run_karr( $repo, 'archive', 1 )->{exit}, 0, 'first archive exits 0' );
    my $again = _run_karr( $repo, 'archive', 1 );
    is( $again->{exit}, 0, 're-archiving an archived task is a no-op success (0)' );
    like( $again->{stdout}, qr/already archived/i, 'and says so on stdout' );
};

subtest 'help requests exit 0 (not a usage error)' => sub {
    my $repo = _board_repo();

    is( _run_karr( $repo, '--help' )->{exit}, 0, 'root --help exits 0' );
    is( _run_karr( $repo, '-h' )->{exit},     0, 'root -h exits 0' );
    is( _run_karr( $repo, 'show', '--help' )->{exit},
        0, 'subcommand --help exits 0' );
};

# ------------------------------------------------------------------ exit 1

subtest 'runtime failures exit 1' => sub {
    my $repo = _board_repo();

    my $nf = _run_karr( $repo, 'show', 99 );
    is( $nf->{exit}, 1, 'not found exits 1' );
    like( $nf->{stderr}, qr/\b99\b/, 'not-found stderr names the id' );

    # Board missing: a git repo with no refs/karr/* board.
    my $empty = _git_repo();
    my $bm = _run_karr( $empty, 'show', 1 );
    is( $bm->{exit}, 1, 'board missing exits 1' );

    # A destructive command refused for want of --yes is a runtime refusal, not
    # a usage error: the invocation was well-formed, karr just declines to act.
    my $imp = _run_karr( $repo, 'import' );
    is( $imp->{exit}, 1, 'import without --yes exits 1 (runtime refusal)' );
    like( $imp->{stderr}, qr/--yes/, 'import refusal stderr mentions --yes' );
};

subtest 'not a git repository exits 1' => sub {
    # A directory that is not inside any git repository. tempdir lives under the
    # system temp dir, whose ancestors are not git repos, so discovery fails.
    my $bare = tempdir( CLEANUP => 1 );
    my $rv = _run_karr( $bare, 'list' );
    is( $rv->{exit}, 1, 'list outside a git repo exits 1' );
    like( $rv->{stderr}, qr/not a git repository/i, 'stderr explains why' );
};

# ------------------------------------------------------------------ exit 2

subtest 'usage errors exit 2' => sub {
    my $repo = _board_repo();

    my $uc = _run_karr( $repo, 'definitely-not-a-command' );
    is( $uc->{exit}, 2, 'unknown command exits 2' );
    like( $uc->{stderr}, qr/\QUnknown command\E/, 'unknown-command stderr' );

    my $surplus = _run_karr( $repo, 'show', 1, 2, 3 );
    is( $surplus->{exit}, 2, 'surplus positional exits 2' );

    # Missing required positional: `move` with no id dies "Usage: karr move ..."
    my $missing = _run_karr( $repo, 'move' );
    is( $missing->{exit}, 2, 'missing required positional exits 2' );
    like( $missing->{stderr}, qr/^Usage:/m, 'missing-positional stderr is a Usage: line' );

    # A "Usage:" die from a board-less command too.
    my $gr = _run_karr( $repo, 'get-refs' );
    is( $gr->{exit}, 2, 'get-refs with no ref exits 2' );
};

subtest 'unknown option exits 2 on every command shape' => sub {
    my $repo = _board_repo();

    # Root option parsing.
    is( _run_karr( $repo, '--totally-bogus' )->{exit},
        2, 'unknown option on the root exits 2' );

    # A subcommand that inherits ExitCodes via BoardDiscovery.
    is( _run_karr( $repo, 'list', '--totally-bogus' )->{exit},
        2, 'unknown option on a board command exits 2' );

    # A board-less command that composes ExitCodes directly.
    is( _run_karr( $repo, 'agent-name', '--totally-bogus' )->{exit},
        2, 'unknown option on agent-name exits 2' );
    is( _run_karr( $repo, 'skill', '--totally-bogus' )->{exit},
        2, 'unknown option on skill exits 2' );
};

done_testing;
