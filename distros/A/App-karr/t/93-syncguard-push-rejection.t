use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Cwd qw( abs_path getcwd );
use IPC::Open3 qw( open3 );
use Symbol qw( gensym );
use Time::HiRes ();
use App::karr::Git;
use App::karr::SyncGuard;

# Ticket #96: App::karr::SyncGuard has its own push path -- the insurance push,
# drained from bin/karr's END block (#37) -- and it never got #84's treatment.
#
# #84 taught `karr push` to read Git::Native::Remote::Result and fail on a
# non-empty ->rejected, and taught App::karr::Role::SyncLifecycle to stop
# retrying a refusal: the server was reached and gave its answer. The guard
# still made three attempts at a push the far side had already declined, a
# second apart, and then always ended with the same generic advice -- "Local
# refs are intact. Run 'karr sync'..." -- which after a refusal points at a
# command that will be refused identically.
#
# So the one path that runs when a command has already died was the one that
# reported the least. It has to consume the same contract on both transports.

# The rejection contract as App::karr::Git answers it: push returns false and
# push_rejections carries the per-ref outcomes.
{
    package RejectingGit;
    sub new { bless { pushes => 0 }, shift }
    sub pull { 1 }
    sub push { my ($self) = @_; $self->{pushes}++; return 0 }
    sub push_rejections {
        [ { ref => 'refs/karr/tasks/1/data', reason => 'pre-receive hook declined' } ]
    }
    sub last_error {
        "the remote 'origin' rejected all 1 ref:\n"
      . "    refs/karr/tasks/1/data: pre-receive hook declined"
    }
    sub pushes { $_[0]{pushes} }
}

# Reached, but nothing individually refused: a lost connection. Still retried.
{
    package UnreachableGit;
    sub new { bless { pushes => 0 }, shift }
    sub pull { 1 }
    sub push { my ($self) = @_; $self->{pushes}++; return 0 }
    sub push_rejections { [] }
    sub last_error { 'connection reset by peer' }
    sub pushes { $_[0]{pushes} }
}

# A git object from before push_rejections existed, which the guard must not
# blow up on -- the sync tests drive it with duck-typed objects like this.
{
    package OldGit;
    sub new { bless { pushes => 0 }, shift }
    sub pull { 1 }
    sub push { my ($self) = @_; $self->{pushes}++; return 0 }
    sub last_error { 'some old failure' }
    sub pushes { $_[0]{pushes} }
}

sub capture_stderr {
    my ($code) = @_;
    my ( $buf, $err ) = ( '', undef );
    {
        local *STDERR;
        open STDERR, '>', \$buf or die "cannot redirect STDERR: $!";
        $err = do { local $@; eval { $code->(); 1 } ? undef : $@ };
    }
    return ( $buf, $err );
}

subtest 'the insurance push does not retry a refusal' => sub {
    local $App::karr::Git::WRITES = 1;
    my $git = RejectingGit->new;
    # Held in a lexical on purpose: the registry keeps only a weak reference, so
    # a guard created in void context is reaped -- and pushes -- immediately.
    my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );

    my ( $stderr, $err ) =
        capture_stderr( sub { App::karr::SyncGuard->flush_armed } );

    is $err, undef, 'the flush never dies';
    is $git->pushes, 1,
        'the refusal is taken as the answer it is, not attempted three times';
    unlike $stderr, qr/Push retry/, 'and no retry is announced';
};

subtest 'it says what the remote refused instead of advising a retry' => sub {
    local $App::karr::Git::WRITES = 1;
    my $guard = App::karr::SyncGuard->new( git => RejectingGit->new, quiet => 1 );

    my ($stderr) = capture_stderr( sub { App::karr::SyncGuard->flush_armed } );

    like $stderr, qr/Push rejected by the remote/,
        'the failure is named for what it is';
    like $stderr, qr{refs/karr/tasks/1/data: pre-receive hook declined},
        'the per-ref reason reaches the user';
    like $stderr, qr/Local refs are intact/,
        'karr still makes its promise about local state';
    like $stderr, qr/would only be refused again/,
        'and says why retrying is not the answer';
    unlike $stderr, qr/Run 'karr sync' to retry/,
        'so it does not send the user at a command that fails identically';
    unlike $stderr, qr/Push failed after 3 attempts/,
        'and does not claim three attempts it never made';
};

subtest 'an ordinary transport failure is still retried, and still advised' => sub {
    local $App::karr::Git::WRITES = 1;
    my $git = UnreachableGit->new;
    my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );

    my ($stderr) = capture_stderr( sub { App::karr::SyncGuard->flush_armed } );

    is $git->pushes, 3, 'the retry loop is untouched where retrying can work';
    like $stderr, qr/Push failed after 3 attempts/, 'reported as before';
    like $stderr, qr/Run 'karr sync' to retry/,
        'with the advice that is still true here';
    unlike $stderr, qr/Push rejected by the remote/,
        'a lost connection is not dressed up as a refusal';
};

subtest 'a git without push_rejections still behaves as it always did' => sub {
    local $App::karr::Git::WRITES = 1;
    my $git = OldGit->new;
    my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );

    my ( $stderr, $err ) =
        capture_stderr( sub { App::karr::SyncGuard->flush_armed } );

    is $err, undef, 'no exception on an object that cannot answer the question';
    is $git->pushes, 3, 'and it takes the retry path';
    like $stderr, qr/Push failed after 3 attempts/, 'with the generic report';
};

subtest 'the same holds when the guard is released by scope exit' => sub {
    local $App::karr::Git::WRITES = 1;
    my $git = RejectingGit->new;

    # Not the END-block flush this time: DESTROY on an ordinary scope exit,
    # which is the embedder's path. Both share _insurance_push, and both have to
    # stop at the refusal.
    my ($stderr) = capture_stderr( sub {
        my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );
        undef $guard;
    } );

    is $git->pushes, 1, 'one attempt from DESTROY too';
    like $stderr, qr/Push rejected by the remote/, 'with the same report';
};

subtest 'a rejection still leaves the guard spent' => sub {
    local $App::karr::Git::WRITES = 1;
    my $git = RejectingGit->new;
    my $guard = App::karr::SyncGuard->new( git => $git, quiet => 1 );

    capture_stderr( sub { App::karr::SyncGuard->flush_armed } );
    capture_stderr( sub { App::karr::SyncGuard->flush_armed } );

    is $git->pushes, 1,
        'the insurance fires once per guard, refusal or not';
};

# --- end to end, against a server that really refuses ------------------------
#
# libgit2's local transport bypasses a bare repo's pre-receive hook entirely, so
# a file-path remote cannot produce a real rejection. `git daemon` runs
# receive-pack and its hooks, which is what makes this a genuine test of the
# whole path: a command that writes refs, dies, and hits the END-block flush
# against a remote that says no.

my $ROOT = abs_path('.');
my $BIN  = "$ROOT/bin/karr";

sub run_karr {
    my ( $cwd, @argv ) = @_;
    my $old = getcwd();
    chdir $cwd or die "chdir $cwd: $!";
    my $eh  = gensym;
    my $pid = open3( my $in, my $out, $eh, $^X, "-I$ROOT/lib", $BIN, @argv );
    close $in;
    my $stdout = do { local $/; <$out> };
    my $stderr = do { local $/; <$eh> };
    waitpid $pid, 0;
    my $exit = $? >> 8;
    chdir $old or die "chdir $old: $!";
    return { exit => $exit, stdout => $stdout // '', stderr => $stderr // '' };
}

my $DAEMON_PID;
END { kill 'TERM', $DAEMON_PID if $DAEMON_PID }

sub start_daemon {
    my ($work) = @_;
    for ( 1 .. 5 ) {
        my $port = 20000 + int rand 20000;
        my $pid  = fork();
        return () unless defined $pid;
        if ( !$pid ) {
            open STDOUT, '>',  "$work/daemon.log";
            open STDERR, '>>', "$work/daemon.log";
            exec( 'git', 'daemon', '--export-all', '--enable=receive-pack',
                "--base-path=$work", "--port=$port", $work );
            exit 1;
        }
        for ( 1 .. 25 ) {
            Time::HiRes::sleep(0.1);
            system("git ls-remote 'git://127.0.0.1:$port/origin.git' >/dev/null 2>&1");
            return ( $pid, $port ) if $? == 0;
        }
        kill 'TERM', $pid;
        waitpid $pid, 0;
    }
    return ();
}

subtest 'end to end: a command that dies into a refused push says so' => sub {
    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    path("$work/origin.git/git-daemon-export-ok")->spew('');

    my ( $pid, $port ) = start_daemon($work);
    plan skip_all => 'no git daemon on a loopback port here' unless $pid;
    $DAEMON_PID = $pid;

    system("git clone -q 'git://127.0.0.1:$port/origin.git' '$work/a' 2>/dev/null");
    system( 'git', '-C', "$work/a", 'config', 'user.email', 'a@karr.test' );
    system( 'git', '-C', "$work/a", 'config', 'user.name',  'agent-a' );

    is run_karr( "$work/a", 'init', '--name', 'Demo' )->{exit}, 0,
        'setup: the board is created and pushed';
    is run_karr( "$work/a", 'create', 'task one' )->{exit}, 0,
        'setup: and carries a task';

    # Only now does the server start refusing.
    my $hook = path("$work/origin.git/hooks/pre-receive");
    $hook->spew("#!/bin/sh\necho 'board is protected' >&2\nexit 1\n");
    chmod 0755, "$hook";

    # Writes task 1, then dies on the missing 999 -- so the push happens from
    # the END-block flush, with no sync_after ever reached.
    my $r = run_karr( "$work/a", 'move', '1,999', 'in-progress',
        '--claim', 'flush-agent' );

    is $r->{exit}, 1, 'the command still fails on its own error';
    like $r->{stderr}, qr/Task 999 not found/,
        'and that error still reaches the user';

    like $r->{stderr}, qr{refs/karr/tasks/1/data: pre-receive hook declined},
        'the insurance push names the ref the server refused';
    like $r->{stderr}, qr/Push rejected by the remote/,
        'and reports it as a refusal';
    unlike $r->{stderr}, qr/Push retry \d of 3/,
        'without retrying an answer that was already given';
    unlike $r->{stderr}, qr/Run 'karr sync' to retry/,
        'and without advising a sync that would be refused identically';

    kill 'TERM', $pid;
    waitpid $pid, 0;
    undef $DAEMON_PID;
};

done_testing;
