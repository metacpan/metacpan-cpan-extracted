use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Time::HiRes qw(usleep);
use Data::Log::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# SIGKILL a process mid-append. Reopen the file. Verify every readable
# entry is intact (50 bytes or "anchor"). After v0.04, abandoned slots
# (writer killed after CAS but before len commit) are reported as
# (undef, $next_off) so readers can skip past them — that's expected,
# not a torn read. Pass abandon_wait_us=0 to skip immediately.

my $path = tmpnam() . '.log';
# Prime: write a known anchor entry
{
    my $log = Data::Log::Shared->new($path, 1024 * 1024);
    $log->append("anchor");
}

my $kills   = 0;
my $clean   = 0;
my $torn    = 0;

for my $trial (1..20) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $log = Data::Log::Shared->new($path, 1024 * 1024);
        while (1) { $log->append("x" x 50) }
        _exit(0);
    }
    usleep(5_000 + int(rand 5_000));   # 5-10 ms in, mid-write most of the time
    kill 'KILL', $pid;
    waitpid($pid, 0);
    $kills++;

    # Parent reopens and walks. Every readable entry must be intact;
    # abandoned slots (undef data) are expected and skipped.
    my $log = Data::Log::Shared->new($path, 1024 * 1024);
    my $off = 0;
    my $walked_ok = 1;
    while (my ($d, $next) = $log->read_entry($off, 0)) {
        if (defined $d && length($d) != 50 && $d ne "anchor") {
            $walked_ok = 0;
            $torn++;
            last;
        }
        $off = $next;
    }
    $clean++ if $walked_ok;
    undef $log;
}

is $kills, 20, 'ran 20 kill/reopen trials';
is $torn, 0, "no torn reads across $kills crashes";
is $clean, 20, 'all reopens walked cleanly';

unlink $path;
done_testing;
