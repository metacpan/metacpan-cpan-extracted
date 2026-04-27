use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(_exit);
use Time::HiRes qw(usleep);
use Data::Log::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# SIGKILL a process mid-append. Reopen the file. Verify state is either
# "append happened (entry readable)" or "append didn't happen (tail
# advanced but commit word still 0, treated as invalid)". Never half-torn.

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

    # Parent reopens and walks. Every entry read must be intact.
    my $log = Data::Log::Shared->new($path, 1024 * 1024);
    my $off = 0;
    my $walked_ok = 1;
    while (my ($d, $next) = $log->read_entry($off)) {
        if (length($d) != 50 && $d ne "anchor") {
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
