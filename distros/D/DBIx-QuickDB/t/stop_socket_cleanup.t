use strict;
use warnings;

use Test2::V0;

use DBI;
use POSIX ();
use IO::Socket::UNIX;
use File::Temp qw/tempdir/;

use DBIx::QuickDB::Driver;

# A server that was SIGKILLed (because a slow shutdown blew the watcher's grace
# period) never removes its unix socket. stop() must not hang/confess waiting
# for that socket to disappear -- the server process is already gone -- and it
# should clean the stale socket up itself.

# Fake watcher: the real one has already signalled + reaped the server by the
# time stop() inspects it, so stop()/wait() are no-ops here and server_pid
# reports a pid that is already dead.
{
    package Test::FakeWatcher;
    sub new        { my $c = shift; bless {@_}, $c }
    sub stop       { 1 }
    sub wait       { 1 }
    sub server_pid { $_[0]->{server_pid} }
}

# Minimal concrete driver: just enough for stop() to run.
{
    package Test::FakeDriver;
    our @ISA = ('DBIx::QuickDB::Driver');
    sub name   { 'Fake' }
    sub socket { $_[0]->{socket_path} }
}

my $dir = tempdir(CLEANUP => 1);

# A pid that is guaranteed dead: fork a child, let it exit, reap it.
my $dead_pid = fork();
die "fork failed: $!" unless defined $dead_pid;
POSIX::_exit(0) unless $dead_pid;
waitpid($dead_pid, 0);

# A real unix socket file the "dead server" left behind. Keep $srv in scope so
# the socket file persists until stop() unlinks it.
my $socket_path = "$dir/.s.PGSQL.5432";
my $srv = IO::Socket::UNIX->new(Local => $socket_path, Listen => 1)
    or die "Could not create test socket: $!";
ok(-S $socket_path, "test socket exists before stop");

my $db = bless {
    DBIx::QuickDB::Driver::DIR()     => $dir,
    DBIx::QuickDB::Driver::WATCHER() => Test::FakeWatcher->new(server_pid => $dead_pid),
    socket_path                      => $socket_path,
}, 'Test::FakeDriver';

ok(lives { $db->stop }, "stop() returns without timing out on a leaked socket")
    or diag($@);

ok(!-S $socket_path, "stop() removed the stale unix socket");

done_testing;
