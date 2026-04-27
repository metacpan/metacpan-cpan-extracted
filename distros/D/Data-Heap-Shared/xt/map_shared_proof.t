use strict;
use warnings;
use Test::More;
use Time::HiRes qw(usleep time);
use POSIX qw(_exit);

use Data::Heap::Shared;

my $h = Data::Heap::Shared->new_memfd("shared", 16);
$h->push(1, 100);

my $pid = fork // die;
if (!$pid) {
    my $h2 = Data::Heap::Shared->new_from_fd($h->memfd);
    my $deadline = time + 3;
    while (time < $deadline) {
        last if ($h2->size // 0) >= 2;
        usleep 1000;
    }
    _exit($h2->size >= 2 ? 0 : 10);
}

usleep 100_000;
$h->push(2, 200);
waitpid $pid, 0;
is $? >> 8, 0, "child sees parent's push (MAP_SHARED)";

done_testing;
