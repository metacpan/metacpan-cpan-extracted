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

# Regression tests for karr board ticket #13.
#
# BUG: options placed before (or interleaved around) positional arguments
#     break arg parsing, sometimes opaquely: `karr archive --json 1` crashes
#     ($args_ref->[0] is "--json", parse_ids/find_task choke on it), `karr
#     handoff --claim X 1` treats "--claim" itself as the ID. MooX::Cmd
#     echoes parsed option flags AND their consumed values back into argv, so
#     every id-taking command that reads $args_ref->[0]/[1] directly (rather
#     than through an extractor that understands which tokens are option
#     values) is exposed to this.
#
# DESIGN (recorded on ticket #13 after sondation, `karr show 13`): cobra
#     parity instead of reject -- flags may appear before, between, or after
#     positionals. A central extractor (landing in Role::BoardAccess, using
#     MooX::Options' _options_data: format=s options consume the following
#     token as a value unless given as --opt=value; flag-only options consume
#     nothing) yields the real positionals. The seven #11 commands (show,
#     archive, delete, edit, handoff, move, create) read positionals only via
#     that extractor; check_positional_args (also from #11/t43) then counts
#     real positionals instead of the leading dash-free run. Config/SetRefs/
#     GetRefs keep their own arg shapes and are out of scope.
#
# None of this is implemented yet (no lib/ changes accompany this test).
#
# Expected colour map, confirmed by hand against the current tree (VERSION
# 0.304, pre-#13-fix) before writing the assertions below:
#
#   RED  (must turn GREEN once #13 lands):
#     - all five "options-first" subtests in section (a)
#     - the "--opt=value" subtest in section (b) -- `handoff --claim=tester 1`
#       *also* currently dies ("Task --claim=tester not found"): MooX::Cmd
#       echoes the unsplit "--claim=tester" token verbatim, it is never
#       recognised as an option at all today.
#     - two of the four "Bestandsgarantien" bullets named on the ticket are
#       NOT actually green on the current tree, contrary to the ticket text
#       (verified by direct CLI probing, see subtests below for detail):
#         * `show --last 2` dies today ("Task --last not found") -- Show
#           unconditionally reads $args_ref->[0] as the id positional even
#           though there are zero real positionals here.
#         * `archive --json 1 99` does not reject 99 today (no
#           "unexpected extra argument" diagnostic fires at all -- it never
#           reaches check_positional_args' reject path); AND
#           `archive 1 --json 99` actively regresses -- it exits 0 and
#           archives task 1, *silently dropping* the extra "99", because
#           today's leading-dash-free-run count stops at "--json" and never
#           sees the trailing "99". Both are pinned here as the desired
#           post-#13 contract (reject, no side effect), not as already-green.
#     These are reported honestly below rather than soft-pedalled to match
#     the ticket's colour claims; only `move 1 --next --claim tester` and
#     `create --title T` / `create T Extra` were confirmed genuinely green
#     on the current tree.
#
#   GREEN today (must stay green -- true "Bestandspins"):
#     - `edit 1 --append-body "--weird"` (value that looks like a flag)
#     - `move 1 --next --claim tester`
#     - `create --title T` / `create T Extra`
#
# STDERR assertions for the extra-args-rejection subtests use the same
# `qr/\bTOKEN\b|usage/i` shape as t/43 (mentions the offending token, or a
# usage-style message).

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

# Fresh isolated temp repo per subtest, never the developer's real board.
sub _setup_repo {
    my $repo = tempdir( CLEANUP => 1 );
    _git_ok( 'git', 'init', '-q', $repo );
    _git_ok( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    _git_ok( 'git', '-C', $repo, 'config', 'user.name', 'Test User' );

    my $init = _run_karr( $repo, 'init', '--name', 'Options-Before-Positionals Board' );
    is( $init->{exit}, 0, 'karr init succeeds' ) or diag $init->{stderr};

    return $repo;
}

# Seeds tasks 1..$n, titled "Task 1".."Task $n", all in the given status
# (default 'todo').
sub _seed_tasks {
    my ( $repo, $n, %opts ) = @_;
    my $status = $opts{status} // 'todo';
    for my $i ( 1 .. $n ) {
        my $rv = _run_karr( $repo, 'create', '--title', "Task $i", '--status', $status );
        is( $rv->{exit}, 0, "seed task $i created" ) or diag $rv->{stderr};
    }
}

sub _show {
    my ( $repo, $id ) = @_;
    return _run_karr( $repo, 'show', $id );
}

sub _status_of {
    my ( $repo, $id ) = @_;
    my $rv = _show( $repo, $id );
    return undef unless $rv->{exit} == 0;
    return $1 if $rv->{stdout} =~ /^Status:\s+(\S+)$/m;
    return undef;
}

sub _title_of {
    my ( $repo, $id ) = @_;
    my $rv = _show( $repo, $id );
    return undef unless $rv->{exit} == 0;
    return $1 if $rv->{stdout} =~ /^Task #\d+: (.+)$/m;
    return undef;
}

sub _claimed_of {
    my ( $repo, $id ) = @_;
    my $rv = _show( $repo, $id );
    return undef unless $rv->{exit} == 0;
    return $1 if $rv->{stdout} =~ /^Claimed:\s+(\S+)$/m;
    return undef;
}

# ---------------------------------------------------- (a) options-first RED:
# every one of these is a legal call under the cobra-parity design and must
# work (exit 0, real side effect) once #13 lands. On the current tree every
# one crashes or misbehaves (see header note) -- confirmed RED below.

subtest 'archive --json 1: archives task 1, valid JSON, exit 0 (RED, ticket #13)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'archive', '--json', 1 );

    is( $rv->{exit}, 0, 'archive --json 1 exits 0' ) or diag $rv->{stderr};

    my $data = eval { decode_json( $rv->{stdout} ) };
    ok( $data, 'stdout is valid JSON' ) or diag "stdout was: $rv->{stdout}";
    if ($data) {
        is( $data->{id}, 1, 'JSON reports id 1' );
        is( $data->{status}, 'archived', 'JSON reports status archived' );
    }

    is( _status_of( $repo, 1 ), 'archived', 'task 1 is actually archived (real side effect)' );
};

subtest 'handoff --claim tester 1: same effect as handoff 1 --claim tester (RED, ticket #13)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'handoff', '--claim', 'tester', 1 );

    is( $rv->{exit}, 0, 'handoff --claim tester 1 exits 0' ) or diag $rv->{stderr};
    is( _status_of( $repo, 1 ), 'review', 'task 1 moved to review' );
    is( _claimed_of( $repo, 1 ), 'tester', 'task 1 claimed by tester' );
};

subtest 'edit --title Neu 1: title changed (RED, ticket #13)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'edit', '--title', 'Neu', 1 );

    is( $rv->{exit}, 0, 'edit --title Neu 1 exits 0' ) or diag $rv->{stderr};
    is( _title_of( $repo, 1 ), 'Neu', 'task 1 title changed to Neu' );
};

subtest 'move --claim tester 1 in-progress: moved and claimed (RED, ticket #13)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );    # starts 'todo'

    my $rv = _run_karr( $repo, 'move', '--claim', 'tester', 1, 'in-progress' );

    is( $rv->{exit}, 0, 'move --claim tester 1 in-progress exits 0' ) or diag $rv->{stderr};
    is( _status_of( $repo, 1 ), 'in-progress', 'task 1 moved to in-progress' );
    is( _claimed_of( $repo, 1 ), 'tester', 'task 1 claimed by tester' );
};

subtest 'delete --yes 1: task deleted (RED, ticket #13)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'delete', '--yes', 1 );

    is( $rv->{exit}, 0, 'delete --yes 1 exits 0' ) or diag $rv->{stderr};

    my $show = _show( $repo, 1 );
    isnt( $show->{exit}, 0, 'task 1 no longer exists after delete' );
};

# ------------------------------------------------ (b) flag-shaped values and
# --opt=value form.

subtest 'edit 1 --append-body "--weird": value is not mistaken for a flag (GREEN pin)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'edit', 1, '--append-body', '--weird' );

    is( $rv->{exit}, 0, 'edit 1 --append-body --weird exits 0' ) or diag $rv->{stderr};

    my $show = _show( $repo, 1 );
    is( $show->{exit}, 0, 'show 1 exits 0' ) or diag $show->{stderr};
    like( $show->{stdout}, qr/--weird/, 'body contains the literal "--weird" text' );
};

subtest 'handoff --claim=tester 1: --opt=value form works (RED, ticket #13)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'handoff', '--claim=tester', 1 );

    is( $rv->{exit}, 0, 'handoff --claim=tester 1 exits 0' ) or diag $rv->{stderr};
    is( _status_of( $repo, 1 ), 'review', 'task 1 moved to review' );
    is( _claimed_of( $repo, 1 ), 'tester', 'task 1 claimed by tester' );
};

# --------------------------------------------------- (c) existing guarantees
# that must not regress. NOTE: per the header comment, two of these four
# bullets (as named on the ticket) turned out to already be broken on the
# current tree when probed directly -- they are pinned here to the correct
# post-#13 contract regardless, and their true current colour is asserted
# via the subtest name/diag rather than assumed.

subtest 'show --last 2: flag with value, 0 positionals (ticket claims GREEN; probed RED today)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 2 );

    my $rv = _run_karr( $repo, 'show', '--last', 2 );

    is( $rv->{exit}, 0, 'show --last 2 exits 0' ) or diag $rv->{stderr};
    like( $rv->{stdout}, qr/Task #2:/, 'shows task 2' );
    like( $rv->{stdout}, qr/Task #1:/, 'shows task 1' );
};

subtest 'move 1 --next --claim tester: id then flags, no status positional (GREEN pin)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1, status => 'todo' );

    my $rv = _run_karr( $repo, 'move', 1, '--next', '--claim', 'tester' );

    is( $rv->{exit}, 0, 'move 1 --next --claim tester exits 0' ) or diag $rv->{stderr};
    is( _status_of( $repo, 1 ), 'in-progress', 'task 1 advanced to in-progress' );
};

subtest 'archive --json 1 99: extra positional still rejected (ticket claims GREEN; probed RED today)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'archive', '--json', 1, 99 );

    isnt( $rv->{exit}, 0, 'archive --json 1 99 exits non-zero' );
    like( $rv->{stderr}, qr/\b99\b|usage/i, 'STDERR names the extra arg or the expected usage' );
    isnt( _status_of( $repo, 1 ), 'archived',
        'task 1 was NOT archived -- rejected before any work happened' );
};

subtest 'archive 1 --json 99: extra positional after the flag also rejected (ticket claims GREEN; probed RED today)' => sub {
    my $repo = _setup_repo();
    _seed_tasks( $repo, 1 );

    my $rv = _run_karr( $repo, 'archive', 1, '--json', 99 );

    isnt( $rv->{exit}, 0, 'archive 1 --json 99 exits non-zero' );
    like( $rv->{stderr}, qr/\b99\b|usage/i, 'STDERR names the extra arg or the expected usage' );
    isnt( _status_of( $repo, 1 ), 'archived',
        'task 1 was NOT archived -- today this silently succeeds and archives it, dropping "99"' );
};

subtest 'create --title T: works; create T Extra: still rejected (GREEN pin)' => sub {
    my $repo = _setup_repo();

    my $rv = _run_karr( $repo, 'create', '--title', 'T' );
    is( $rv->{exit}, 0, 'create --title T exits 0' ) or diag $rv->{stderr};
    is( _title_of( $repo, 1 ), 'T', 'task 1 created with title T' );

    my $rv2 = _run_karr( $repo, 'create', 'T', 'Extra' );
    isnt( $rv2->{exit}, 0, 'create T Extra exits non-zero' );
    like( $rv2->{stderr}, qr/\QExtra\E|usage/i, 'STDERR names the extra arg or the expected usage' );

    my $show2 = _show( $repo, 2 );
    isnt( $show2->{exit}, 0, 'no second task was created' );
};

done_testing;
