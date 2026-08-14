use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestGit qw( require_git_c );
require_git_c();
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use App::karr::Git;
use App::karr::Task;
use Git::Native::Remote;

# Regression tests for the git-CLI transport fallback (#42, #43).
#
#   #42  _cli_transport read `$? >> 8` only. That is 0 for a child killed by a
#        signal just as it is for a clean exit, so a git the OOM killer, a
#        Ctrl-C on the process group or a SIGPIPE took down was reported as a
#        successful transport: "Created task 1", exit 0, empty remote.
#   #43  it slurped stdout to EOF before touching stderr. Past 64 KiB of stderr
#        the child blocks on a full pipe, so it never exits and never closes
#        stdout, while the parent is still blocked reading stdout -- a deadlock
#        with no timeout anywhere. A diverged board reaches that at ~700
#        rejected refs, and it can strike inside bin/karr's END flush, after
#        the command has already printed its result.
#
# Both are driven with a fake `git` on PATH, so they are deterministic and do
# not depend on board size or network conditions.

# Write an executable fake `git` (a Perl script, for portable signal control)
# into its own directory and return that directory.
sub fake_git {
    my ($body) = @_;
    my $bin = tempdir( CLEANUP => 1 );
    my $exe = path( $bin, 'git' );
    $exe->spew_utf8("#!$^X\nuse strict;\nuse warnings;\n$body");
    chmod 0755, "$exe" or die "chmod: $!";
    return $bin;
}

sub repo_with_remote {
    my $work = tempdir( CLEANUP => 1 );
    system( 'git', 'init', '-q', '--bare', "$work/origin.git" );
    system("git clone -q '$work/origin.git' '$work/a' 2>/dev/null");
    system( 'git', '-C', "$work/a", 'config', 'user.email', 'a@karr.test' );
    system( 'git', '-C', "$work/a", 'config', 'user.name',  'agent-a' );
    return ( $work, App::karr::Git->new( dir => "$work/a" ) );
}

# Run $code with a hang-breaker. Returns ( $result, $hung ); $hung stays true
# even when the alarm's die is swallowed further down the stack.
sub without_hanging {
    my ( $seconds, $code ) = @_;
    my $hung = 0;
    my $result;
    eval {
        local $SIG{ALRM} = sub { $hung = 1; die "transport hung\n" };
        alarm $seconds;
        $result = $code->();
        alarm 0;
        1;
    } or alarm 0;
    return ( $result, $hung );
}

subtest '#42: git killed by a signal is a failed transport, not a successful one' => sub {
    my ( $work, $git ) = repo_with_remote();
    $git->save_task_ref(
        App::karr::Task->new(
            id => 1, title => 'Must not be lost silently',
            status => 'todo', priority => 'high', class => 'standard',
        )
    );

    my $bin = fake_git( <<'FAKE' );
$SIG{TERM} = 'DEFAULT';
kill 'TERM', $$;      # die from a signal: exit status 0, signal bits 15
sleep 30;
FAKE

    my $rv = do {
        local $ENV{PATH} = "$bin:$ENV{PATH}";
        $git->_cli_transport( 'push', 'origin', ['+refs/karr/*:refs/karr/*'] );
    };

    ok !$rv, '_cli_transport reports failure when git dies from a signal';
    like $git->last_error, qr/killed by signal 15/,
        'last_error names the signal';

    # The end-to-end claim of the ticket: push() must not answer "yes" while
    # the remote never received anything.
    my $pushed = do {
        no warnings 'redefine';
        local *Git::Native::Remote::push =
            sub { die "forced libgit2 failure\n" };
        local $ENV{PATH} = "$bin:$ENV{PATH}";
        $git->push;
    };
    ok !$pushed, 'push() fails instead of announcing a transport that never happened';

    my @remote = `git -C '$work/origin.git' for-each-ref --format='%(refname)' 'refs/karr/'`;
    is scalar(@remote), 0, 'and the remote really is empty';
};

subtest '#43: more than 64 KiB on stderr does not deadlock the transport' => sub {
    my ( $work, $git ) = repo_with_remote();

    # 256 KiB of stderr -- four times the pipe buffer -- written before
    # anything reaches stdout, then a normal failing exit. The old
    # "slurp stdout, then stderr" order can never get past this.
    my $bin = fake_git( <<'FAKE' );
print STDERR " ! [rejected]        refs/karr/tasks/$_/data -> refs/karr/tasks/$_/data  (non-fast-forward)\n"
  for 1 .. 3000;
print STDOUT "done\n";
exit 1;
FAKE

    my ( $rv, $hung ) = without_hanging( 20, sub {
        local $ENV{PATH} = "$bin:$ENV{PATH}";
        $git->_cli_transport( 'fetch', 'origin', ['+refs/karr/*:refs/karr/*'] );
    } );

    ok !$hung, 'transport returns instead of deadlocking on a full stderr pipe';
    ok !$rv,   'and reports the failure';
    like $git->last_error, qr/non-fast-forward/,
        'the CLI stderr is still what gets reported';
};

subtest '#43: a stalled git is killed instead of hanging an unattended agent' => sub {
    my ( $work, $git ) = repo_with_remote();

    my $bin = fake_git( <<'FAKE' );
$SIG{TERM} = 'DEFAULT';
sleep 300;
FAKE

    my ( $rv, $hung ) = without_hanging( 20, sub {
        local $ENV{PATH}                   = "$bin:$ENV{PATH}";
        local $ENV{KARR_TRANSPORT_TIMEOUT} = 2;
        $git->_cli_transport( 'fetch', 'origin', ['+refs/karr/*:refs/karr/*'] );
    } );

    ok !$hung, 'the timeout fires well before the test-level hang-breaker';
    ok !$rv,   'a timed-out transport is a failed transport';
    like $git->last_error, qr/timed out after 2s/,
        'last_error says the transport was killed on a timeout';
};

subtest 'a well-behaved git is still reported as success' => sub {
    my ( $work, $git ) = repo_with_remote();
    $git->save_task_ref(
        App::karr::Task->new(
            id => 7, title => 'Real transport', status => 'todo',
            priority => 'high', class => 'standard',
        )
    );
    ok $git->_cli_transport(
        'push', 'origin', ['+refs/karr/*:refs/karr/*'], prune => 1,
    ), 'the real git CLI still transports and reports success';

    my @remote = `git -C '$work/origin.git' for-each-ref --format='%(refname)' 'refs/karr/'`;
    chomp @remote;
    is_deeply \@remote, ['refs/karr/tasks/7/data'], 'the ref landed on the remote';
};

done_testing;
