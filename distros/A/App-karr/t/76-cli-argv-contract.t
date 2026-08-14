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
use Encode qw( encode_utf8 );

# Regression tests for karr board tickets #71, #72, #74 and part of #76 -- four
# defects at the argv/dispatch boundary (MooX::Cmd + MooX::Options).
#
# #71 bin/karr rewrote the dashed command spellings only at $ARGV[0]:
#       $ARGV[0] = 'getrefs' if $ARGV[0] eq 'get-refs';
#     With the documented root option in front, $ARGV[0] is the option, so
#     `karr --dir PATH get-refs REF` exited 2 with "Unknown command: get-refs",
#     and the cmd form `karr get-refs REF --dir PATH` exited 2 with "Unknown
#     option: dir" because the board-less commands never declared --dir at all.
#     Both shapes were unreachable for exactly the caller they exist for: an
#     orchestrator driving karr from outside the target repository.
#
# #72 A bare "--" was not honoured as the end-of-options separator, so an
#     option-shaped positional could only be passed via a named option:
#     `karr create -- "--json"` died "Title is required" (the separator and the
#     escaped title were both swallowed by positional_args) while
#     `karr create --title "--json"` worked.
#
# #74 `karr get-refs missing/ref` printed one empty line, said "Fetched ..." on
#     stderr and exited 0, so `karr get-refs spec.md > spec.md` silently
#     truncated the file it was meant to fill. A consumer could not tell an
#     absent ref from an empty one.
#
# #76 `karr show --last 0` (and any negative) was clamped to 1 and answered
#     with one task at exit 0, indistinguishable from a correct call. ADR 0002
#     classifies an invalid option value as a usage error (2).
#
# Every subtest below was probed against the pre-fix tree first and asserts the
# post-fix contract. Five of the six are RED without the lib/ + bin/ changes;
# the "left alone" subtest is a GREEN pin that has to survive them, since the
# chosen fix (registering the dashed spellings as command names rather than
# rewriting argv) is precisely the one that cannot mangle a payload.

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

    # Read both edges as bytes: App::karr::Encoding puts a :encoding(UTF-8)
    # layer on the CLI's own STDOUT/STDERR, so what arrives here is octets and
    # the non-ASCII assertion below is allowed to be about octets (t/70's
    # rationale -- decoding what karr encoded is an identity round trip).
    binmode $stdout_fh;
    binmode $stderr;
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

# A git repo with no remote (so nothing in here waits on transport) and no
# board unless the caller asks for one.
sub _git_repo {
    my $repo = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    return $repo;
}

sub _board_repo {
    my ($label) = @_;
    my $repo = _git_repo();
    is( _run_karr( $repo, 'init', '--name', "Board $label" )->{exit},
        0, "setup: karr init succeeds for board $label" );
    return $repo;
}

# Every ref outside refs/karr/*, read with plain git so the assertion never
# depends on the discovery path under test.
sub _helper_refs {
    my ($repo) = @_;
    open( my $fh, '-|', 'git', '-C', $repo, 'for-each-ref', '--format=%(refname)' )
        or die "can't run git for-each-ref: $!";
    my @refs = grep { !m{^refs/karr/} } map { chomp; $_ } <$fh>;
    close $fh;
    return @refs;
}

# --------------------------------------------------------------- ticket #71

subtest '--dir before the subcommand reaches the dashed helper-ref commands' => sub {
    my $A = _board_repo('A');    # cwd for every call: never the target
    my $B = _board_repo('B');

    my $set = _run_karr( $A, '--dir', $B, 'set-refs', 'spec/1234.md', 'payload', 'here' );
    is( $set->{exit}, 0, 'karr --dir B set-refs ... exits 0 (space form)' )
        or diag $set->{stderr};
    like( $set->{stderr}, qr{refs/spec/1234\.md}, 'set-refs names the ref it stored' );

    is_deeply( [ _helper_refs($B) ], ['refs/spec/1234.md'],
        'the helper ref landed in board B, the --dir target' );
    is_deeply( [ _helper_refs($A) ], [],
        'board A -- the process cwd -- got no helper ref at all' );

    my $get = _run_karr( $A, '--dir', $B, 'get-refs', 'spec/1234.md' );
    is( $get->{exit},   0,                 'karr --dir B get-refs REF exits 0' )
        or diag $get->{stderr};
    is( $get->{stdout}, "payload here\n",  'and prints B\'s payload on stdout' );

    my $eq = _run_karr( $A, "--dir=$B", 'get-refs', 'spec/1234.md' );
    is( $eq->{exit},   0,                'the --dir=PATH equals form works too' )
        or diag $eq->{stderr};
    is( $eq->{stdout}, "payload here\n", 'and prints the same payload' );

    my $an = _run_karr( $A, '--dir', $B, 'agent-name' );
    is( $an->{exit}, 0, 'karr --dir B agent-name exits 0' ) or diag $an->{stderr};
    like( $an->{stdout}, qr/\A[a-z]+-[a-z]+\n\z/,
        'and prints a generated name, not "Unknown command"' );
};

subtest '--dir after the subcommand works on the board-less ref commands' => sub {
    my $A = _board_repo('A2');
    my $B = _board_repo('B2');

    my $set = _run_karr( $A, 'set-refs', 'spec/cmd-form.md', 'cmd', 'form', '--dir', $B );
    is( $set->{exit}, 0, 'karr set-refs REF TEXT --dir B exits 0' ) or diag $set->{stderr};

    is_deeply( [ _helper_refs($B) ], ['refs/spec/cmd-form.md'],
        'the ref landed in B' );
    is_deeply( [ _helper_refs($A) ], [], 'and not in the cwd repo' );

    my $get = _run_karr( $A, 'get-refs', 'spec/cmd-form.md', '--dir', $B );
    is( $get->{exit},   0,             'karr get-refs REF --dir B exits 0' )
        or diag $get->{stderr};
    is( $get->{stdout}, "cmd form\n",  'the --dir tokens stayed out of the payload' );
};

subtest 'a payload or title that merely spells a command alias is left alone' => sub {
    my $repo = _board_repo('Literal');

    # The fix registers the dashed spellings as command names instead of
    # rewriting argv, so nothing downstream of the dispatched command can be
    # mangled into its internal spelling.
    is( _run_karr( $repo, 'set-refs', 'lit/ref', 'set-refs' )->{exit},
        0, 'set-refs can store the literal text "set-refs"' );
    is( _run_karr( $repo, 'get-refs', 'lit/ref' )->{stdout},
        "set-refs\n", 'the payload round-trips verbatim, not as "setrefs"' );

    my $create = _run_karr( $repo, 'create', '--title', 'agent-name' );
    is( $create->{exit}, 0, 'a task may be titled "agent-name"' )
        or diag $create->{stderr};
    like( $create->{stdout}, qr/\bagent-name\b/,
        'and keeps the dashed spelling in its title' );
};

# --------------------------------------------------------------- ticket #72

subtest '-- ends option processing, so an option-shaped positional survives' => sub {
    my $repo = _board_repo('Separator');

    my $create = _run_karr( $repo, 'create', '--', '--json' );
    is( $create->{exit}, 0, 'karr create -- --json exits 0' ) or diag $create->{stderr};
    like( $create->{stdout}, qr/\Q--json\E/, 'the title is the escaped token itself' );

    my $flagish = _run_karr( $repo, 'create', '--', '--dir makes set-refs unreachable' );
    is( $flagish->{exit}, 0, 'an option-shaped sentence survives the separator' )
        or diag $flagish->{stderr};

    my $list = _run_karr( $repo, 'list', '--compact' );
    like( $list->{stdout}, qr/^\S+\s+\S+\s+\Q--json\E$/m,
        'the "--json" task is on the board with its literal title' );
    like( $list->{stdout}, qr/\Q--dir makes set-refs unreachable\E/,
        'and so is the option-shaped sentence' );

    # The separator must not become a positional itself: `show -- 1` is a
    # one-positional call, not two, so it must not trip the surplus-args guard.
    my $show = _run_karr( $repo, 'show', '--', '1' );
    is( $show->{exit}, 0, 'karr show -- 1 exits 0' ) or diag $show->{stderr};
    like( $show->{stdout}, qr/^Task #1:/m, 'and shows task 1' );

    # The separator sits downstream of App::karr::Encoding's decode_argv, so an
    # escaped positional is a character string by the time positional_args sees
    # it. Pinned on bytes: a title that is both option-shaped AND non-ASCII must
    # come back single-encoded, not mojibake and not dropped.
    my $utf8_title = "--json \x{c4}rger \x{2014} gr\x{f6}\x{df}er";
    my $u = _run_karr( $repo, 'create', '--', $utf8_title );
    is( $u->{exit}, 0, 'an option-shaped non-ASCII title survives the separator' )
        or diag $u->{stderr};
    like( $u->{stdout}, qr/\Q@{[ encode_utf8($utf8_title) ]}\E/,
        'and is echoed back as single-encoded UTF-8' );
};

# --------------------------------------------------------------- ticket #74

subtest 'get-refs distinguishes an absent ref from an empty one' => sub {
    my $repo = _board_repo('Refs');

    my $missing = _run_karr( $repo, 'get-refs', 'does/not/exist.md' );
    is( $missing->{exit}, 1, 'a ref that does not exist is a runtime failure (1)' );
    is( $missing->{stdout}, '',
        'and emits NOTHING on stdout -- `karr get-refs X > X` must not truncate' );
    like( $missing->{stderr}, qr/not found/i, 'stderr says the ref was not found' );
    unlike( $missing->{stderr}, qr/^Fetched /m,
        'and does not claim to have fetched it' );

    # A ref that exists but carries an empty payload is a success: the point of
    # the fix is telling the two apart, not rejecting empty content.
    my $rc = system( $^X, "-I$ROOT/lib", '-e',
        'use App::karr::Git; App::karr::Git->new(dir => $ARGV[0])'
            . '->write_ref("refs/empty/payload", "") or die "write_ref failed"',
        $repo );
    is( $rc, 0, 'setup: wrote an existing-but-empty helper ref' );

    my $empty = _run_karr( $repo, 'get-refs', 'empty/payload' );
    is( $empty->{exit}, 0, 'an existing ref with an empty payload still exits 0' )
        or diag $empty->{stderr};
    like( $empty->{stderr}, qr/^Fetched /m, 'and reports the fetch' );
};

# --------------------------------------------------------------- ticket #76

subtest 'show --last rejects a non-positive count with the usage exit code' => sub {
    my $repo = _board_repo('Last');
    is( _run_karr( $repo, 'create', '--title', 'Only Task' )->{exit},
        0, 'setup: one task on the board' );

    for my $bad ( 0, -1 ) {
        my $rv = _run_karr( $repo, 'show', '--last', $bad );
        is( $rv->{exit}, 2, "show --last $bad is a usage error (2), not a clamped success" );
        is( $rv->{stdout}, '', "show --last $bad prints no task" );
        like( $rv->{stderr}, qr/--last/, "show --last $bad names the offending option" );
    }

    my $ok = _run_karr( $repo, 'show', '--last', 1 );
    is( $ok->{exit}, 0, 'show --last 1 still works' ) or diag $ok->{stderr};
    like( $ok->{stdout}, qr/^Task #1: Only Task$/m, 'and shows the task' );
};

done_testing;
