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

# Ticket #32: `karr disable [--reason]` / `karr enable`, and the same state
# through `karr config get|set|show foundation.enabled|foundation.reason`.
# Driven through the real CLI binary (like t/43, t/57) against throwaway git
# repos -- never the developer's real board.

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

sub _git_ok {
    my (@cmd) = @_;
    my $rc = system(@cmd);
    is( $rc, 0, "@cmd" );
}

sub _board_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    is( _run_karr( $repo, 'init', '--name', 'Disable Board' )->{exit},
        0, 'setup: karr init exits 0' );
    return $repo;
}

# ---------------------------------------------------------------------------
# karr disable / karr enable
# ---------------------------------------------------------------------------

subtest 'karr disable: text output, no reason given' => sub {
    my $repo = _board_repo();
    my $rv   = _run_karr( $repo, 'disable' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Board disabled for automated agent runs/,
        'confirms disable' );
    unlike( $rv->{stdout}, qr/Reason:/, 'no Reason: line when none given' );

    my $get = _run_karr( $repo, 'config', 'get', 'foundation.enabled' );
    is( $get->{exit}, 0, 'config get exits 0' );
    like( $get->{stdout}, qr/^0\s*$/, 'foundation.enabled is 0' );
};

subtest 'karr disable --reason: text output carries the reason' => sub {
    my $repo = _board_repo();
    my $rv   = _run_karr( $repo, 'disable', '--reason', 'abandoned driver' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Board disabled for automated agent runs/, 'confirms disable' );
    like( $rv->{stdout}, qr/Reason:\s+abandoned driver/, 'reason echoed' );
};

subtest 'karr disable --json: enabled=>0, reason present only when given' => sub {
    my $repo = _board_repo();

    my $bare = _run_karr( $repo, 'disable', '--json' );
    is( $bare->{exit}, 0, 'exit 0' ) or diag $bare->{stderr};
    my $data = eval { decode_json( $bare->{stdout} ) };
    is_deeply( $data, { foundation => { enabled => 0 } } ),
      'no reason key when none was given'
      or diag $bare->{stdout};

    my $repo2  = _board_repo();
    my $reason = _run_karr( $repo2, 'disable', '--reason', 'parked', '--json' );
    is( $reason->{exit}, 0, 'exit 0' ) or diag $reason->{stderr};
    my $data2 = eval { decode_json( $reason->{stdout} ) };
    is_deeply( $data2, { foundation => { enabled => 0, reason => 'parked' } },
        'reason key present and correct' )
      or diag $reason->{stdout};
};

subtest 'karr enable: text output and --json, harmless no-op on a never-disabled board' => sub {
    my $repo = _board_repo();
    my $rv   = _run_karr( $repo, 'enable' );
    is( $rv->{exit}, 0, 'exit 0 even though the board was already enabled' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Board enabled for automated agent runs/, 'confirms enable' );

    my $repo2 = _board_repo();
    my $json  = _run_karr( $repo2, 'enable', '--json' );
    is( $json->{exit}, 0, 'exit 0' ) or diag $json->{stderr};
    my $data = eval { decode_json( $json->{stdout} ) };
    is_deeply( $data, { foundation => { enabled => 1 } }, 'enable --json payload' )
      or diag $json->{stdout};
};

subtest 'karr disable (no --reason) after a prior disable --reason clears the stored reason' => sub {
    my $repo = _board_repo();
    is( _run_karr( $repo, 'disable', '--reason', 'first reason' )->{exit}, 0,
        'setup: disable with a reason' );

    my $get_before = _run_karr( $repo, 'config', 'get', 'foundation.reason' );
    is( $get_before->{exit}, 0, 'reason readable while set' );
    like( $get_before->{stdout}, qr/first reason/, 'reason is what we set' );

    my $rv = _run_karr( $repo, 'disable' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    unlike( $rv->{stdout}, qr/Reason:/, 'no Reason: line reported this time' );

    # Still disabled -- only the reason was cleared.
    my $enabled = _run_karr( $repo, 'config', 'get', 'foundation.enabled' );
    like( $enabled->{stdout}, qr/^0\s*$/, 'still disabled' );

    my $get_after = _run_karr( $repo, 'config', 'get', 'foundation.reason' );
    isnt( $get_after->{exit}, 0, 'foundation.reason now unresolvable -- Unknown key' );
    like( $get_after->{stderr}, qr/Unknown key/, 'stderr says Unknown key' );
};

subtest 'karr disable / karr enable: surplus positional is a usage error (exit 2, ADR 0002)' => sub {
    my $repo = _board_repo();

    my $d = _run_karr( $repo, 'disable', 'extra' );
    is( $d->{exit}, 2, 'karr disable extra exits 2' );
    like( $d->{stderr}, qr/unexpected extra argument/, 'stderr names the extra positional' );

    my $e = _run_karr( $repo, 'enable', 'extra' );
    is( $e->{exit}, 2, 'karr enable extra exits 2' );
    like( $e->{stderr}, qr/unexpected extra argument/, 'stderr names the extra positional' );
};

# ---------------------------------------------------------------------------
# karr config get|set|show foundation.enabled / foundation.reason
# ---------------------------------------------------------------------------

subtest 'karr config get foundation.enabled: default true on a fresh board' => sub {
    my $repo = _board_repo();
    my $rv   = _run_karr( $repo, 'config', 'get', 'foundation.enabled' );
    is( $rv->{exit}, 0, 'exit 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/^1\s*$/, 'defaults to 1' );

    my $json = _run_karr( $repo, 'config', 'get', 'foundation.enabled', '--json' );
    is( $json->{exit}, 0, 'exit 0' ) or diag $json->{stderr};
    is_deeply( eval { decode_json( $json->{stdout} ) }, { 'foundation.enabled' => 1 },
        '--json payload' )
      or diag $json->{stdout};
};

subtest "karr config set foundation.enabled false: stores 0, the real footgun case" => sub {
    my $repo = _board_repo();
    my $set  = _run_karr( $repo, 'config', 'set', 'foundation.enabled', 'false' );
    is( $set->{exit}, 0, 'exit 0' ) or diag $set->{stderr};

    my $get = _run_karr( $repo, 'config', 'get', 'foundation.enabled' );
    is( $get->{exit}, 0, 'exit 0' ) or diag $get->{stderr};
    like( $get->{stdout}, qr/^0\s*$/,
        q{stored value is the number 0, not Perl's truthy string "false"} );
};

subtest 'karr config set foundation.enabled bogus: dies, does not silently coerce truthy' => sub {
    my $repo = _board_repo();
    my $rv   = _run_karr( $repo, 'config', 'set', 'foundation.enabled', 'bogus' );
    isnt( $rv->{exit}, 0, 'non-zero exit' );
    like( $rv->{stderr}, qr/Invalid boolean/, 'stderr explains why' );

    my $get = _run_karr( $repo, 'config', 'get', 'foundation.enabled' );
    like( $get->{stdout}, qr/^1\s*$/, 'value unchanged -- still the default' );
};

subtest 'karr config set/get foundation.reason: free-text round trip' => sub {
    my $repo = _board_repo();
    my $set  = _run_karr( $repo, 'config', 'set', 'foundation.reason', 'parked backlog' );
    is( $set->{exit}, 0, 'exit 0' ) or diag $set->{stderr};

    my $get = _run_karr( $repo, 'config', 'get', 'foundation.reason' );
    is( $get->{exit}, 0, 'exit 0' ) or diag $get->{stderr};
    like( $get->{stdout}, qr/parked backlog/, 'round trips' );
};

subtest 'karr config get foundation.reason: unset -> Unknown key, exit 1' => sub {
    my $repo = _board_repo();
    my $rv   = _run_karr( $repo, 'config', 'get', 'foundation.reason' );
    is( $rv->{exit}, 1, 'exit 1 (runtime failure, not a usage error)' );
    like( $rv->{stderr}, qr/Unknown key/, 'stderr says Unknown key' );
};

subtest 'karr config show: foundation.enabled always listed, foundation.reason only when set' => sub {
    my $repo = _board_repo();
    my $fresh = _run_karr( $repo, 'config', 'show' );
    is( $fresh->{exit}, 0, 'exit 0' ) or diag $fresh->{stderr};
    like( $fresh->{stdout}, qr/^foundation\.enabled\s+1\s*$/m,
        'foundation.enabled listed on a never-touched board' );
    unlike( $fresh->{stdout}, qr/^foundation\.reason/m,
        'foundation.reason not listed while unset' );

    is( _run_karr( $repo, 'disable', '--reason', 'abandoned driver' )->{exit}, 0,
        'setup: disable with a reason' );

    my $after = _run_karr( $repo, 'config', 'show' );
    is( $after->{exit}, 0, 'exit 0' ) or diag $after->{stderr};
    like( $after->{stdout}, qr/^foundation\.enabled\s+0\s*$/m, 'now shows 0' );
    like( $after->{stdout}, qr/^foundation\.reason\s+abandoned driver\s*$/m,
        'foundation.reason now listed' );
};

done_testing;
