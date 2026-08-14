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

use App::karr::Git;
use App::karr::SyncGuard;
use App::karr::Role::SyncLifecycle;

# Ticket #37: the SyncGuard insurance push never fired at a usable moment on
# the CLI.
#
# App::karr::Role::SyncLifecycle arms a guard for every writing command and
# stashes it on the command object, so a body that dies after writing refs but
# before sync_after should still push. It never did: bin/karr wraps the run in
# an eval and exits from the handler, MooX::Cmd's command chain keeps the
# command object alive, and the guard was therefore first reaped in global
# destruction -- where #34 (rightly) forbids all libgit2 work, leaving nothing
# but a "run karr sync" notice.
#
# The fix is a process-wide registry of armed guards drained by
# App::karr::SyncGuard->flush_armed, which bin/karr calls from an END block:
# the last point before global destruction, and one that also covers the exit()
# calls inside command bodies. The DESTRUCT branch of DESTROY stays as the last
# resort for embedders that never flush -- that is t/66's subject, not this
# file's.
#
# Observable end to end as: `karr move 1,999 in-progress --claim X` moves task
# 1 (writing refs/karr/tasks/1/data), then dies on the missing 999. Before the
# fix the remote kept the pre-move task; now it carries the write.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub _run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";

    my $stderr = gensym;
    my $pid = open3( my $in, my $out, $stderr, $^X, "-I$ROOT/lib", $BIN, @argv );
    close $in;
    my $stdout_text = do { local $/; <$out> };
    my $stderr_text = do { local $/; <$stderr> };
    waitpid( $pid, 0 );
    my $exit = $? >> 8;

    chdir $old or die "chdir $old: $!";
    return {
        exit   => $exit,
        stdout => defined $stdout_text ? $stdout_text : '',
        stderr => defined $stderr_text ? $stderr_text : '',
    };
}

# A throwaway work repo with a bare origin, both under CLEANUP. Never the
# repository this suite runs in.
sub _board_repo {
    my ( $bare_out, @tasks ) = @_;
    my $repo = tempdir( CLEANUP => 1 );
    my $bare = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', $repo ) == 0        or die 'git init failed';
    system( 'git', 'init', '-q', '--bare', $bare ) == 0 or die 'git init --bare failed';
    system( 'git', '-C', $repo, 'config', 'user.email', 'test@example.com' );
    system( 'git', '-C', $repo, 'config', 'user.name',  'Test User' );
    system( 'git', '-C', $repo, 'commit', '-q', '--allow-empty', '-m', 'init' ) == 0
        or die 'git commit failed';
    system( 'git', '-C', $repo, 'remote', 'add', 'origin', $bare ) == 0
        or die 'git remote add failed';

    # init first: a write command in a repository without a board is refused
    # (#62), so `create` alone no longer conjures one.
    is _run_karr( $repo, 'init', '--name', 'Flush Board' )->{exit}, 0,
        'setup: karr init exits 0';

    for my $title (@tasks) {
        is _run_karr( $repo, 'create', $title )->{exit}, 0,
            "setup: karr create '$title' exits 0";
    }

    $$bare_out = $bare;
    return $repo;
}

# The task document as the *remote* has it. Empty string when the ref is absent.
sub _remote_task {
    my ( $bare, $id ) = @_;
    my $oid = `git --git-dir='$bare' rev-parse -q --verify refs/karr/tasks/$id/data 2>/dev/null`;
    chomp $oid;
    return '' unless length $oid;
    return scalar `git --git-dir='$bare' cat-file -p '$oid:data' 2>/dev/null`;
}

subtest 'a command that dies after writing refs pushes them before exit' => sub {
    my $bare;
    my $repo = _board_repo( \$bare, 'task one' );

    like _remote_task( $bare, 1 ), qr/^status: backlog$/m,
        'setup: the remote starts with task 1 in backlog';

    my $r = _run_karr( $repo, 'move', '1,999', 'in-progress', '--claim', 'flush-agent' );

    is $r->{exit}, 1, 'the command still fails (exit code contract intact)';
    like $r->{stderr}, qr/Task 999 not found/,
        'the real error is still what reaches STDERR';
    like $r->{stdout}, qr/Moved task 1: backlog -> in-progress/,
        'task 1 was written before the die';

    my $remote = _remote_task( $bare, 1 );
    like $remote, qr/^status: in-progress$/m,
        'the write the dying command made reached the remote';
    like $remote, qr/^claimed_by: flush-agent$/m,
        'the whole task document was pushed, not a partial ref';

    unlike $r->{stderr}, qr/Push skipped/,
        'no "run karr sync" notice: the push actually happened';
    unlike $r->{stderr}, qr/Push failed/, 'and it did not fail';
};

subtest 'a command that dies before writing anything pushes nothing' => sub {
    my $bare;
    my $repo = _board_repo( \$bare, 'task one' );

    # require_claim is checked before the first save_task, so this dies with
    # $App::karr::Git::WRITES still at 0. The flush must be a complete no-op:
    # no push, no retry chatter, no sync advice.
    my $r = _run_karr( $repo, 'move', '1', 'in-progress' );

    is $r->{exit}, 1, 'exits 1';
    like $r->{stderr}, qr/requires --claim/, 'the validation error surfaces';
    unlike $r->{stderr}, qr/Push (?:skipped|retry|failed)/,
        'an unwritten board produces no push output at all';
    like _remote_task( $bare, 1 ), qr/^status: backlog$/m,
        'the remote is untouched';
};

subtest 'a failing insurance push warns and leaves the exit code alone' => sub {
    my $bare;
    my $repo = _board_repo( \$bare, 'task one' );

    # Fetch stays healthy, push cannot work: sync_before succeeds and arms the
    # guard, the body writes and dies, and the END flush then fails. A die
    # escaping END would abort perl's END queue and replace the contract's 1.
    system( 'git', '-C', $repo, 'remote', 'set-url', '--push', 'origin',
        '/nonexistent/karr-bogus.git' ) == 0
        or die 'git remote set-url --push failed';

    my $r = _run_karr( $repo, 'move', '1,999', 'in-progress', '--claim', 'flush-agent' );

    is $r->{exit}, 1, 'still exit 1 -- a failed flush does not rewrite the exit code';
    like $r->{stderr}, qr/Task 999 not found/, 'the original error is preserved';
    like $r->{stderr}, qr/Push failed after 3 attempts/,
        'the failed insurance push is reported';
    like $r->{stderr}, qr/Run 'karr sync' to retry/,
        'and it says how to finish the push by hand';
    unlike $r->{stderr}, qr/END failed/,
        'the failure was warned, not thrown out of the END block';
};

# ---- flush_armed itself -----------------------------------------------------

{
  package CountingGit;
  sub new  { bless { pushes => 0, ok => defined $_[1] ? $_[1] : 1 }, $_[0] }
  sub pull { 1 }
  sub push { my ($self) = @_; $self->{pushes}++; return $self->{ok} }
  sub last_error { 'SIMULATED-FAILURE' }
  sub pushes { $_[0]{pushes} }
}

{
  package ExplodingGit;
  sub new  { bless {}, shift }
  sub push { die "libgit2 went sideways\n" }
  sub last_error { undef }
}

{
  package FlushBoard;
  use Moo;
  use MooX::Options;
  with 'App::karr::Role::SyncLifecycle';
  has git => ( is => 'ro', required => 1 );
}

sub capture_stderr {
    my ($code) = @_;
    my $buf = '';
    my $err;
    {
        local *STDERR;
        open STDERR, '>', \$buf or die "cannot redirect STDERR: $!";
        $err = do { local $@; eval { $code->(); 1 } ? undef : $@ };
    }
    return ( $buf, $err );
}

sub armed_count {
    return scalar grep { defined } values %App::karr::SyncGuard::ARMED;
}

subtest 'flush_armed only pushes when a ref was actually written' => sub {
    local $App::karr::Git::WRITES = 0;

    my $git   = CountingGit->new;
    my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );

    is( App::karr::SyncGuard->flush_armed, 0, 'nothing written -> nothing flushed' );
    is( $git->pushes, 0, 'and no push attempted' );

    $guard->done;
};

subtest 'flush_armed pushes an armed guard exactly once' => sub {
    local $App::karr::Git::WRITES = 1;

    my $git   = CountingGit->new;
    my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );

    is( App::karr::SyncGuard->flush_armed, 1, 'the armed guard is flushed' );
    is( $git->pushes, 1, 'exactly one push' );

    # A second flush, and the guard's own DESTROY afterwards, must both stay
    # quiet: the insurance fires once per guard, never twice.
    is( App::karr::SyncGuard->flush_armed, 0, 'a second flush finds nothing' );
    undef $guard;
    is( $git->pushes, 1, 'DESTROY does not repeat the flushed push' );
};

subtest 'a guard released by sync_after is never flushed again' => sub {
    local $App::karr::Git::WRITES = 1;

    my $git = CountingGit->new;
    my ( $stderr, $err ) = capture_stderr( sub {
        my $board = FlushBoard->new( git => $git );
        $board->sync_before;
        $board->sync_after;
        is( App::karr::SyncGuard->flush_armed, 0,
            'sync_after deregistered the guard, so the flush finds nothing' );
    } );
    is( $err, undef, 'clean lifecycle' );
    is( $git->pushes, 1, 'exactly one push across the whole lifecycle' );
};

subtest 'a sync_after that failed all 3 attempts disarms the guard' => sub {
    local $App::karr::Git::WRITES = 1;

    # sync_after has already spent the three attempts and croaked with the
    # "run karr sync" guidance; re-running them from the flush would double the
    # delay and the noise on a command that is already failing.
    my $git = CountingGit->new(0);
    my $croak;
    my ( $stderr, $err ) = capture_stderr( sub {
        my $board = FlushBoard->new( git => $git );
        $board->sync_before;
        $croak = eval { $board->sync_after; 1 } ? undef : $@;
        is( App::karr::SyncGuard->flush_armed, 0,
            'the spent guard is not flushed again' );
    } );
    like( $croak, qr/Push failed after 3 attempts/,
        'sync_after still croaks -- disarming does not swallow the failure' );
    is( $git->pushes, 3, 'three attempts total, not six' );
};

subtest 'flush_armed never dies, even on a guard whose git blows up' => sub {
    local $App::karr::Git::WRITES = 1;

    my $guard = App::karr::SyncGuard->new( git => ExplodingGit->new, quiet => 1 );
    my ( $stderr, $err ) = capture_stderr(
        sub { App::karr::SyncGuard->flush_armed } );

    is( $err, undef, 'the exception is caught, not rethrown at the caller' );
    like( $stderr, qr/libgit2 went sideways/, 'and it is warned about' );
};

subtest 'the registry holds no strong reference and leaks no keys' => sub {
    is( armed_count(), 0, 'registry starts clean' );

    my $git = CountingGit->new;
    {
        my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );
        is( armed_count(), 1, 'an armed guard registers itself' );
        $guard->done;
        is( armed_count(), 0, 'done() deregisters immediately' );
    }

    {
        local $App::karr::Git::WRITES = 0;
        my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );
        is( armed_count(), 1, 'a second guard registers' );
    }
    is( armed_count(), 0,
        'scope exit frees the guard: the registry never kept it alive' );
    is( scalar( keys %App::karr::SyncGuard::ARMED ), 0,
        'and DESTROY removed the key too, so the registry does not grow' );
};

done_testing;
