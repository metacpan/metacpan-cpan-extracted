use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Time::HiRes ();
use App::karr::Git;
use App::karr::Task;
use App::karr::Role::SyncLifecycle;
use Git::Native::Remote;
use Git::Native::Remote::Result;

# Ticket #84: a push whose refs the server refused was reported as a completed
# sync. libgit2 returns 0 from git_remote_push even when every single ref was
# rejected -- a pre-receive hook, a protected ref, a non-ff on a non-forced
# refspec -- so the per-ref status exists only in the
# Git::Native::Remote::Result 0.004 hands back, and karr threw that away. The
# board then diverged from the remote with no signal at all.
#
# Note on how this is tested: libgit2's *local* transport (a file-path remote)
# bypasses a bare repo's pre-receive hook entirely -- verified while writing
# this: the hook exits 1 and the refs land on the remote anyway. So a file-path
# remote cannot produce a native server rejection, and the native half is
# covered two ways instead: with the Result handed back directly (deterministic,
# always runs), and end to end over `git daemon`, which does run receive-pack
# and its hooks (skipped where no daemon can be started). The CLI fallback runs
# the real git binary against a file-path remote, where the hook does fire.

my $DAEMON_PID;
END { kill 'TERM', $DAEMON_PID if $DAEMON_PID }

sub task {
    my ( $id, $title ) = @_;
    return App::karr::Task->new(
        id => $id, title => $title, status => 'todo',
        priority => 'high', class => 'standard', body => '',
    );
}

# A bare origin whose pre-receive hook declines everything, plus a clone with a
# board written into refs/karr/* and nothing pushed yet.
sub protected_remote {
    my (%opt) = @_;
    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    if ( $opt{hook} ) {
        my $hook = path("$work/origin.git/hooks/pre-receive");
        $hook->spew("#!/bin/sh\necho 'board is protected' >&2\nexit 1\n");
        chmod 0755, "$hook";
    }
    system("git clone -q '$work/origin.git' '$work/a' 2>/dev/null");
    system( 'git', '-C', "$work/a", 'config', 'user.email', 'a@karr.test' );
    system( 'git', '-C', "$work/a", 'config', 'user.name',  'agent-a' );

    my $git = App::karr::Git->new( dir => "$work/a" );
    $git->write_ref( 'refs/karr/config', "board:\n  name: demo\n" );
    $git->save_task_ref( task( 1, 'One' ) );
    return ( $work, $git );
}

sub origin_refs {
    my ($work) = @_;
    my @refs =
      `git -C '$work/origin.git' for-each-ref --format='%(refname)' 'refs/karr/'`;
    chomp @refs;
    return [ sort @refs ];
}

# ---------------------------------------------------------------------
# The native contract, taken straight off the Result: libgit2 said "fine"
# (no exception, rc 0) and the Result says two refs were refused.
# ---------------------------------------------------------------------
subtest 'native: a Result with rejections fails the push and names every ref' => sub {
    my ( $work, $git ) = protected_remote();

    my $rv = do {
        no warnings 'redefine';
        local *Git::Native::Remote::push = sub {
            return Git::Native::Remote::Result->new(
                updated  => [],
                rejected => [
                    { ref => 'refs/karr/config', reason => 'pre-receive hook declined' },
                    { ref => 'refs/karr/tasks/1/data', reason => 'protected ref' },
                ],
            );
        };
        $git->push;
    };

    ok !$rv, 'push reports failure instead of announcing a sync that never happened';
    like $git->last_error, qr/rejected all 2 refs/,
        'last_error says how many refs the remote refused';
    like $git->last_error, qr{refs/karr/config: pre-receive hook declined},
        'and names the first ref with the reason the server gave';
    like $git->last_error, qr{refs/karr/tasks/1/data: protected ref},
        'and the second one with its own reason, not a shared generic one';
    is_deeply [ map { $_->{ref} } @{ $git->push_rejections } ],
        [ 'refs/karr/config', 'refs/karr/tasks/1/data' ],
        'push_rejections carries the per-ref outcomes to the caller';

    # A rejection is the server's answer, not a broken connection, so it must
    # not be retried through the CLI fallback. The origin here is a perfectly
    # working bare repo without a hook: had the fallback run, the refs would
    # have landed.
    is_deeply origin_refs($work), [],
        'no CLI fallback after a rejection -- the far side already answered';
};

subtest 'native: a partial rejection is still a failed push' => sub {
    my ( $work, $git ) = protected_remote();

    my $rv = do {
        no warnings 'redefine';
        local *Git::Native::Remote::push = sub {
            return Git::Native::Remote::Result->new(
                updated  => [ { ref => 'refs/karr/config', reason => '' } ],
                rejected => [ { ref => 'refs/karr/tasks/1/data', reason => 'non-fast-forward' } ],
            );
        };
        $git->push;
    };

    ok !$rv, 'one refused ref out of two is a failure, not a partial success';
    like $git->last_error, qr/rejected 1 of 2 refs/,
        'the message says how much of the push got through';
};

subtest 'native: a clean Result still succeeds, and clears earlier rejections' => sub {
    my ( $work, $git ) = protected_remote();

    my $rejected = do {
        no warnings 'redefine';
        local *Git::Native::Remote::push = sub {
            return Git::Native::Remote::Result->new( updated => [],
                rejected => [ { ref => 'refs/karr/config', reason => 'nope' } ] );
        };
        $git->push;
    };
    ok !$rejected, 'the rejected push failed';
    ok @{ $git->push_rejections }, 'and left its rejections behind';

    ok $git->push, 'the next push, which the remote accepts, succeeds';
    is_deeply $git->push_rejections, [],
        'push_rejections is per-push state, not sticky';
    is_deeply origin_refs($work),
        [ 'refs/karr/config', 'refs/karr/tasks/1/data' ],
        'and the refs really reached the remote';
};

subtest 'native: a rejected push does not update the tracking mirror' => sub {
    my ( $work, $git ) = protected_remote();

    do {
        no warnings 'redefine';
        local *Git::Native::Remote::push = sub {
            return Git::Native::Remote::Result->new( updated => [],
                rejected => [ { ref => 'refs/karr/config', reason => 'nope' } ] );
        };
        $git->push;
    };

    is_deeply [ $git->list_refs('refs/karr-remote/') ], [],
        'the mirror still says the remote never saw this board';
};

# ---------------------------------------------------------------------
# The fallback transport, end to end against a real pre-receive hook. The
# CLI already exited non-zero here before the fix; what it did not do was
# report which ref was refused and why in karr's own words.
# ---------------------------------------------------------------------
subtest 'CLI fallback: a real pre-receive rejection fails with per-ref reasons' => sub {
    my ( $work, $git ) = protected_remote( hook => 1 );

    my $rv = do {
        no warnings 'redefine';
        local *Git::Native::Remote::push =
            sub { die "forced libgit2 push failure\n" };
        $git->push;
    };

    ok !$rv, 'the CLI fallback reports the failure';
    like $git->last_error, qr/rejected all 2 refs/,
        'with the same wording the native transport uses';
    like $git->last_error, qr{refs/karr/config: pre-receive hook declined},
        'naming the ref and the reason the server gave';
    like $git->last_error, qr{refs/karr/tasks/1/data: pre-receive hook declined},
        'for every rejected ref';
    is_deeply [ map { $_->{ref} } @{ $git->push_rejections } ],
        [ 'refs/karr/config', 'refs/karr/tasks/1/data' ],
        'push_rejections is filled on this transport too';
    is_deeply origin_refs($work), [], 'and the remote really is empty';
};

subtest 'CLI fallback: a transport failure is still reported as one' => sub {
    my ( $work, $git ) = protected_remote();
    system( 'git', '-C', "$work/a", 'remote', 'set-url', '--push', 'origin',
        '/nonexistent-karr-remote.git' );

    my $rv = do {
        no warnings 'redefine';
        local *Git::Native::Remote::push =
            sub { die "forced libgit2 push failure\n" };
        $git->push;
    };

    ok !$rv, 'a broken remote fails';
    like $git->last_error, qr/CLI fallback\) failed/,
        'and is not dressed up as a per-ref rejection';
    is_deeply $git->push_rejections, [],
        'push_rejections stays empty when no ref was individually refused';
};

# ---------------------------------------------------------------------
# sync_after: a refusal is final, so it is not retried three times.
# ---------------------------------------------------------------------
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

{
    package FlakyGit;
    sub new { bless { pushes => 0 }, shift }
    sub pull { 1 }
    sub push { my ($self) = @_; return ++$self->{pushes} >= 3 ? 1 : 0 }
    sub push_rejections { [] }
    sub last_error { 'connection reset' }
    sub pushes { $_[0]{pushes} }
}

{
    package RejectBoard;
    use Moo;
    use MooX::Options;
    with 'App::karr::Role::SyncLifecycle';
    has git => ( is => 'ro', required => 1 );
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

subtest 'sync_after: a rejected push is reported once, not retried three times' => sub {
    my $git = RejectingGit->new;
    my ( $stderr, $err ) = capture_stderr( sub {
        my $board = RejectBoard->new( git => $git );
        $board->sync_before;
        $board->sync_after;
    } );

    is $git->pushes, 1, 'the refusal is taken as the answer it is';
    like $err, qr/Push rejected by the remote/, 'and the command fails loudly';
    like $err, qr/Local refs are intact/,
        'with the promise karr makes about local state';
    like $stderr, qr{refs/karr/tasks/1/data: pre-receive hook declined},
        'the per-ref reason reaches the user, not just a generic failure';
    unlike $stderr, qr/Push retry/, 'no pointless retry announcements';
};

subtest 'sync_after: an ordinary transport failure is still retried' => sub {
    my $git = FlakyGit->new;
    my ( $stderr, $err ) = capture_stderr( sub {
        my $board = RejectBoard->new( git => $git );
        $board->sync_before;
        $board->sync_after;
    } );

    is $err, undef, 'the third attempt succeeds';
    is $git->pushes, 3, 'the retry loop is untouched for non-rejection failures';
};

# A rejection message is one line per refused ref, so printing it once per
# attempt buries the thing worth reading. Repeats of the identical error are
# dropped; a different one on a later attempt is not.
{
    package RepeatingGit;
    sub new { bless {}, shift }
    sub pull { 0 }
    sub push { 0 }
    sub push_rejections { [] }
    sub last_error {
        "the remote 'origin' rejected all 1 ref:\n"
      . "    refs/karr/tasks/1/data: DISTINCTIVE-REASON"
    }
}

{
    package ChangingGit;
    sub new { bless { n => 0 }, shift }
    sub pull { 0 }
    sub push { 0 }
    sub push_rejections { [] }
    sub last_error { my ($self) = @_; 'ERROR-NUMBER-' . ++$self->{n} }
}

sub count_of {
    my ( $text, $needle ) = @_;
    my $n = 0;
    $n++ while $text =~ /\Q$needle\E/g;
    return $n;
}

subtest 'the same failure three times over is reported once, not three times' => sub {
    my ( $stderr, $err ) = capture_stderr( sub {
        my $board = RejectBoard->new( git => RepeatingGit->new );
        $board->sync_before;
    } );

    like $err, qr/Pull failed after 3 attempts/, 'the pull still fails loudly';
    is count_of( $stderr, 'DISTINCTIVE-REASON' ), 1,
        'the per-ref reason is on STDERR exactly once, not once per attempt';
    like $stderr, qr/Pull retry 2 of 3/,
        'the retries are still announced, so the wait is not unexplained';
};

subtest 'a failure that changes between attempts is reported each time' => sub {
    my ( $stderr, $err ) = capture_stderr( sub {
        my $board = RejectBoard->new( git => ChangingGit->new );
        $board->sync_before;
    } );

    like $stderr, qr/ERROR-NUMBER-1/, 'the first cause is shown';
    like $stderr, qr/ERROR-NUMBER-2/, 'and so is a different one after it';
    like $stderr, qr/ERROR-NUMBER-3/, 'deduplication never hides new information';
};

# ---------------------------------------------------------------------
# The native transport end to end, against a server that really runs
# receive-pack. This is the only setup that produces a genuine libgit2
# push rejection; it needs a `git daemon` on a loopback port.
# ---------------------------------------------------------------------
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

subtest 'native, end to end: a real receive-pack rejection fails the push' => sub {
    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    my $hook = path("$work/origin.git/hooks/pre-receive");
    $hook->spew("#!/bin/sh\necho 'board is protected' >&2\nexit 1\n");
    chmod 0755, "$hook";
    path("$work/origin.git/git-daemon-export-ok")->spew('');

    my ( $pid, $port ) = start_daemon($work);
    plan skip_all => 'no git daemon on a loopback port here' unless $pid;
    $DAEMON_PID = $pid;

    system("git clone -q 'git://127.0.0.1:$port/origin.git' '$work/a' 2>/dev/null");
    system( 'git', '-C', "$work/a", 'config', 'user.email', 'a@karr.test' );
    system( 'git', '-C', "$work/a", 'config', 'user.name',  'agent-a' );

    my $git = App::karr::Git->new( dir => "$work/a" );
    $git->save_task_ref( task( 1, 'One' ) );

    # Native only: no fallback may paper over what libgit2 reports.
    my $rv = do {
        local $ENV{KARR_NO_CLI_FALLBACK} = 1;
        $git->push;
    };

    ok !$rv, 'libgit2 returned 0, the server said no, and karr reports the no';
    like $git->last_error, qr{refs/karr/tasks/1/data: pre-receive hook declined},
        'with the reason receive-pack sent back';
    is_deeply origin_refs($work), [], 'and nothing reached the remote';

    kill 'TERM', $pid;
    waitpid $pid, 0;
    undef $DAEMON_PID;
};

done_testing;
