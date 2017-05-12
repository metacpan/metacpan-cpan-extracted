use strict;
use warnings;

use Test::Most;
use Test::Exit;
use Test::Warn;

use App::Base::Daemon;
use File::Flock::Tiny;

package Test::Daemon;
use Time::HiRes;

use Moose;
with 'App::Base::Daemon';

sub daemon_run {
    while (1) {
        Time::HiRes::usleep(1e3);
    }
}

sub documentation {
    return 'This is a test daemon.';
}

sub handle_shutdown {
    print "# I am shutting down.\n";
}

no Moose;
__PACKAGE__->meta->make_immutable;

package Test::Daemon::Exiting;

use Moose;
with 'App::Base::Daemon';

sub daemon_run {
    return 0;
}

sub documentation {
    return 'This is a test daemon.';
}

sub handle_shutdown {
    return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

package Test::Daemon::Suicidal;
use Time::HiRes;
use POSIX qw(SIGTERM);

use Moose;
with 'App::Base::Daemon';

sub daemon_run {

    # This will never actually loop, but I want to guarantee that the
    # daemon does not exit by reaching return()
    while (1) {
        Time::HiRes::usleep(1e6);
        POSIX::raise(SIGTERM);
    }
    return 0;    # This won't get reached :-/
}

sub documentation {
    return 'This is a test daemon that exits after a second.';
}

sub handle_shutdown {
}

no Moose;
__PACKAGE__->meta->make_immutable;

package main;
use POSIX qw(SIGTERM);
use Path::Tiny;
use File::Slurp;

warnings_like {
    exits_ok(sub { Test::Daemon->new->error("This is an error message") }, "error() forces exit");
}
[qr/This is an error message/], "Expected warning";

my $pdir    = Path::Tiny->tempdir;
my $pidfile = $pdir->child('Test::Daemon.pid');

FORK:
{
    local $ENV{APP_BASE_DAEMON_PIDDIR} = $pdir;
    ok(File::Flock::Tiny->trylock($pidfile), "Pidfile is not locked");
    is(Test::Daemon->new->run, 0, 'Test daemon spawns detached child process');
    wait_file($pidfile);
    ok(-f $pidfile, "Pid file exists");
    chomp(my $pid = read_file($pidfile));
    ok $pid, "Have read daemon PID";
    BAIL_OUT("No PID file, can't continue") unless $pid;
    ok !File::Flock::Tiny->trylock($pidfile), "Pidfile is locked";
    ok kill(0 => $pid), "Grandchild process is running";
    throws_ok { Test::Daemon->new->run } qr/another copy of this daemon already running/, "Can not start second copy";
    ok kill(INT => $pid), "Able to send SIGINT signal to process";

    #wait pid to exit at most 5 seconds
    for (my $i = 0; $i <= 10; $i++) {
        last unless kill(0 => $pid);
        Time::HiRes::usleep(5e5);
    }
    ok !kill(0 => $pid), "Grandchild process has shut down";
}

NO_FORK:
{
    local @ARGV = ('--no-fork', '--no-pid-file');
    is(0, Test::Daemon::Exiting->new->run, '--no-fork runs and returns 0');
}

LE_ROI_SE_MEURT:
{
    my $pidfile = $pdir->child('Test::Daemon::Suicidal.pid');
    local $ENV{APP_BASE_DAEMON_PIDDIR} = $pdir;
    is(Test::Daemon::Suicidal->new->run, 0, 'Test::Suicidal daemon spawns detached child process');
    wait_file($pidfile);
    ok(-f $pidfile, "Suicidal pid file exists");
    chomp(my $pid = read_file($pidfile));
    my $count = 50;
    while (kill(ZERO => $pid) and $count--) {
        Time::HiRes::usleep(50_000);
    }
    ok(!kill(ZERO => $pid), "Suicidal grandchild process has gone");
}

if ($> == 0) {
    local $ENV{APP_BASE_DAEMON_PIDDIR} = $pdir;
    unlink $pidfile;
    is(
        Test::Daemon->new({
                user  => 'nobody',
                group => 'nogroup',
            },
            )->run,
        0,
        "Test daemon spawns detached child process"
    );
    wait_file($pidfile);
    ok -f $pidfile, "Pid file exists";
    chomp(my $pid = read_file($pidfile));
    ok $pid, "Have read daemon PID";
    chomp(my $ps = `ps hp$pid -ouser,group`);
    my ($user, $group) = split /\s+/, $ps;
    is $user,  'nobody',  "user is nobody";
    is $group, 'nogroup', "group is nogroup";
    kill TERM => $pid;
}

sub wait_file {
    my ($file, $timeout) = @_;
    $timeout //= 1;
    while ($timeout > 0 and not -f $file) {
        Time::HiRes::usleep(2e4);
        $timeout -= 2e4;
    }
}

done_testing;
