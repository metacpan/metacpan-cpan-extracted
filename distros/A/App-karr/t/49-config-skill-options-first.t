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

# Regression tests for karr board ticket #17.
#
# BUG: `karr config` and `karr skill` read their action/key/value straight from
#     raw argv ($args_ref->[0]/[1]/[2]). MooX::Options runs with protect_argv,
#     so an option flag keeps its original position in argv; a flag placed
#     before the action makes $args_ref->[0] the flag, not the action:
#         karr config --json show   -> "Unknown action: --json"
#         karr skill  --json check  -> "Unknown action: --json"
#     even though the action-first forms (`config show --json`) work. Same class
#     as the already-fixed #13, whose option-aware extractor now lives in
#     App::karr::Role::CliArgs.
#
# FIX: both commands read positionals through positional_args (option-aware) and
#     enforce arity via check_positional_args. Config keeps action-dependent
#     arity (show=1, get KEY=2, set KEY VALUE=3); skill takes exactly one
#     positional (the action). `skill --agent NAME check` needs the real parser
#     because --agent (format=s) swallows its value -- a naive dash-filter would
#     read the agent value as the action.
#
# These subtests drive the real bin/karr via a subprocess, so they exercise the
# actual MooX::Cmd protect_argv argv echo that causes the bug (same harness as
# the #11/#13 regressions in t/43 and t/45). RED before the fix: every
# "options-first" subtest died with "Unknown action: --<flag>"; the surplus-arg
# subtests did not reject (config) / had no arity guard (skill).
#
# JSON equality is checked against the *decoded* structure, not raw bytes:
# print_json is not canonical, so two separate processes can emit the same
# config with different hash key order.

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

# Fresh isolated temp board per subtest, never the developer's real board.
sub _setup_config_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

    my $init = _run_karr( $repo, 'init', '--name', 'Config-Options Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    return $repo;
}

# ------------------------------------------------------------------ config ---

subtest 'config --json show: flag before action still runs show (RED, #17)' => sub {
    my $repo = _setup_config_repo();

    my $rv = _run_karr( $repo, 'config', '--json', 'show' );

    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    unlike( $rv->{stderr}, qr/Unknown action/, 'no "Unknown action: --json" error' );

    my $data = eval { decode_json( $rv->{stdout} ) };
    ok( $data, 'stdout is valid JSON' )
        or diag "stdout: $rv->{stdout}\nstderr: $rv->{stderr}";
    is( ref $data, 'HASH', 'JSON is the whole-config object' );
    is( $data->{board}{name}, 'Config-Options Board', 'JSON carries the board name' );
};

subtest 'config --json (bare, no action): defaults to show, still JSON (RED, #17)' => sub {
    my $repo = _setup_config_repo();

    my $rv = _run_karr( $repo, 'config', '--json' );

    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    unlike( $rv->{stderr}, qr/Unknown action/, 'no "Unknown action: --json" error' );

    my $data = eval { decode_json( $rv->{stdout} ) };
    ok( $data, 'stdout is valid JSON' ) or diag "stdout: $rv->{stdout}";
    is( $data->{board}{name}, 'Config-Options Board', 'bare --json defaults to the show output' );
};

subtest 'config --json show and config show --json behave identically (#17)' => sub {
    my $repo = _setup_config_repo();

    my $flag_first = _run_karr( $repo, 'config', '--json', 'show' );
    my $flag_last  = _run_karr( $repo, 'config', 'show', '--json' );

    is( $flag_first->{exit}, 0, 'flag-first exits 0' ) or diag $flag_first->{stderr};
    is( $flag_last->{exit},  0, 'flag-last exits 0' )  or diag $flag_last->{stderr};

    my $d1 = eval { decode_json( $flag_first->{stdout} ) };
    my $d2 = eval { decode_json( $flag_last->{stdout} ) };
    is_deeply( $d1, $d2, 'both option positions produce the same config JSON' );
};

subtest 'config --json get claim_timeout: key read from positionals, not argv[1] (RED, #17)' => sub {
    my $repo = _setup_config_repo();

    my $rv = _run_karr( $repo, 'config', '--json', 'get', 'claim_timeout' );

    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    unlike( $rv->{stderr}, qr/Unknown action/, 'action parsed as get, not "--json"' );

    my $data = eval { decode_json( $rv->{stdout} ) };
    ok( $data, 'stdout is valid JSON' ) or diag "stdout: $rv->{stdout}";
    is( $data->{claim_timeout}, '1h',
        'get read the key from the real positionals even with --json first' );
};

subtest 'config get claim_timeout extra: surplus positional rejected (per-action arity) (#17)' => sub {
    my $repo = _setup_config_repo();

    my $rv = _run_karr( $repo, 'config', 'get', 'claim_timeout', 'extra' );

    isnt( $rv->{exit}, 0, 'exits non-zero' );
    like( $rv->{stderr}, qr/\bextra\b|usage/i, 'STDERR names the extra arg or the usage' );
};

# ------------------------------------------------------------------- skill ---
# skill needs no board (composes Output + CliArgs, never touches git/store), so
# a plain temp dir is enough.

subtest 'skill --json check: flag before action parses action=check (RED, #17)' => sub {
    my $dir = tempdir( CLEANUP => 1 );

    my $rv = _run_karr( $dir, 'skill', '--json', 'check' );

    is( $rv->{exit}, 0, 'exit 0 (all agents not installed, nothing outdated)' )
        or diag $rv->{stderr};
    unlike( $rv->{stderr}, qr/Unknown action/, 'no "Unknown action: --json" error' );

    my $data = eval { decode_json( $rv->{stdout} ) };
    ok( $data, 'stdout is valid JSON' )
        or diag "stdout: $rv->{stdout}\nstderr: $rv->{stderr}";
    is( ref $data, 'ARRAY', 'check --json prints a JSON array of agent statuses' );
};

subtest 'skill --agent claude-code check: --agent swallows its value, action=check (RED, #17)' => sub {
    my $dir = tempdir( CLEANUP => 1 );

    my $rv = _run_karr( $dir, 'skill', '--agent', 'claude-code', 'check' );

    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    unlike( $rv->{stderr}, qr/Unknown action/,
        'action parsed as check, not the swallowed value "--agent"' );
    like( $rv->{stdout}, qr/claude-code/,
        'the claude-code agent was checked (its name was consumed as --agent value)' );
    unlike( $rv->{stdout}, qr/\bcodex\b/,
        'only the requested agent was checked -- proof --agent took claude-code, not "check"' );
};

subtest 'skill check --json (action first): stays green (GREEN pin, #17)' => sub {
    my $dir = tempdir( CLEANUP => 1 );

    my $rv = _run_karr( $dir, 'skill', 'check', '--json' );

    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    my $data = eval { decode_json( $rv->{stdout} ) };
    ok( $data, 'stdout is valid JSON' ) or diag "stdout: $rv->{stdout}";
    is( ref $data, 'ARRAY', 'check --json prints a JSON array' );
};

subtest 'skill check extra: surplus positional rejected (arity 1) (#17)' => sub {
    my $dir = tempdir( CLEANUP => 1 );

    my $rv = _run_karr( $dir, 'skill', 'check', 'extra' );

    isnt( $rv->{exit}, 0, 'exits non-zero' );
    like( $rv->{stderr}, qr/\bextra\b|usage/i, 'STDERR names the extra arg or the usage' );
};

done_testing;
