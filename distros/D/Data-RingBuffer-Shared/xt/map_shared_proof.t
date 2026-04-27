use strict;
use warnings;
use Test::More;
use Time::HiRes qw(usleep time);
use POSIX qw(_exit);

use Data::RingBuffer::Shared;

my $r = Data::RingBuffer::Shared::Int->new_memfd("shared", 16);
$r->write(100);

my $pid = fork // die;
if (!$pid) {
    my $r2 = Data::RingBuffer::Shared::Int->new_from_fd($r->memfd);
    my $deadline = time + 3;
    while (time < $deadline) {
        last if ($r2->latest // 0) == 200;
        usleep 1000;
    }
    _exit(($r2->latest // 0) == 200 ? 0 : 10);
}

usleep 100_000;
$r->write(200);
waitpid $pid, 0;
is $? >> 8, 0, "child sees parent's write (MAP_SHARED)";

done_testing;
