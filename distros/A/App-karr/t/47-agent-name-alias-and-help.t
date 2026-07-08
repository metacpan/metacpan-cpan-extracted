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

# Regression tests for karr board ticket #19 (two user-visible CLI drifts).
#
# (a) `karr agent-name` -- the dashed, kanban-md-parity spelling used
#     throughout the docs -- did NOT dispatch to App::karr::Cmd::AgentName.
#     bin/karr aliases the dashed spellings of set-refs/get-refs to their
#     MooX::Cmd command names but had no `agent-name` -> `agentname` alias, so
#     the dashed form fell through App::karr::execute. NOTE: the brief for #19
#     described the fall-through as "silently prints the board summary"; the
#     current tree actually errors with "Unknown command: agent-name"
#     (exit != 0) because the ticket #5 unknown-command guard (added later,
#     see t/41-cli-error-exits.t) now intercepts the leftover token before it
#     reaches the board fallback. Either way the defect is the same: the
#     dashed form never reaches AgentName. This test asserts the desired
#     POSITIVE outcome (a generated name is printed) so it is robust to which
#     stale symptom the pre-fix tree exhibits: RED before the bin alias
#     (exit != 0, "Unknown command"), GREEN after.
#
# (b) `karr --help` did not list the `log` command at all (its @COMMANDS
#     display entry in lib/App/karr.pm was simply missing, even though
#     App::karr::Cmd::Log is complete), and listed AgentName under the
#     internal `agentname` key rather than the canonical dashed `agent-name`.
#     @COMMANDS is display-only (consumed solely by _print_help), so this is a
#     pure help-text fix. RED before the two @COMMANDS edits, GREEN after.

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

# Fresh isolated repo + board seeded with one distinctively-titled task, so a
# board-summary leak (the shape the ticket describes) is trivially detectable
# by title, and never the developer's real board.
sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

    my $init = _run_karr( $repo, 'init', '--name', 'Ticket19 Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    my $create = _run_karr( $repo, 'create', 'Distinctive Seed Task' );
    is( $create->{exit}, 0, 'seed task created' ) or diag $create->{stderr};

    return $repo;
}

# A generated agent name is exactly one lowercase hyphenated word pair and
# nothing else (App::karr::Cmd::AgentName prints "$word-$word\n").
my $NAME_RE = qr/\A[a-z]+-[a-z]+\s*\z/;

# ------------------------------------------------------------------ (a) alias

subtest 'karr agent-name (dashed) dispatches to AgentName, prints a name (RED, ticket #19)' => sub {
    my $repo = _setup_repo();
    my $rv   = _run_karr( $repo, 'agent-name' );

    is( $rv->{exit}, 0, 'karr agent-name exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, $NAME_RE,
        'stdout is a single generated name, nothing else' );
    unlike( $rv->{stdout}, qr/Distinctive Seed Task/,
        'stdout is NOT the board summary (no seeded task title leaked)' );
    unlike( $rv->{stdout}, qr/^\d+ tasks\b/m,
        'stdout has no board task-count footer' );
    unlike( $rv->{stderr}, qr/Unknown command/,
        'stderr does not report an unknown command' );
};

subtest 'karr agentname (internal, undashed) still dispatches to AgentName (GREEN pin)' => sub {
    my $repo = _setup_repo();
    my $rv   = _run_karr( $repo, 'agentname' );

    is( $rv->{exit}, 0, 'karr agentname exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, $NAME_RE,
        'the undashed command name keeps producing a generated name' );
};

# --------------------------------------------------------------- (b) --help

subtest 'karr --help lists both log and agent-name (RED, ticket #19)' => sub {
    my $repo = _setup_repo();
    my $rv   = _run_karr( $repo, '--help' );

    is( $rv->{exit}, 0, 'karr --help exits 0' ) or diag $rv->{stderr};

    # Strip ANSI colour codes so command-name matches don't trip over the
    # cyan escapes _print_help wraps each command in.
    ( my $plain = $rv->{stdout} ) =~ s/\x1b\[[0-9;]*m//g;

    like( $plain, qr/^\s*log\b/m,
        'help lists the log command' );
    like( $plain, qr/Show activity log/,
        'help shows the log command description' );
    like( $plain, qr/^\s*agent-name\b/m,
        'help lists the AgentName command under its canonical dashed spelling' );
    unlike( $plain, qr/^\s*agentname\b/m,
        'help no longer lists the internal undashed agentname key' );
};

done_testing;
