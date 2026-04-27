use strict;
use warnings;
use Test::More;
use Time::HiRes qw(usleep time);
use POSIX qw(_exit);

use Data::BitSet::Shared;

my $b = Data::BitSet::Shared->new_memfd("shared", 128);
$b->set(0);

my $pid = fork // die;
if (!$pid) {
    my $b2 = Data::BitSet::Shared->new_from_fd($b->memfd);
    my $deadline = time + 3;
    while (time < $deadline) {
        last if $b2->test(5);
        usleep 1000;
    }
    _exit($b2->test(5) ? 0 : 10);
}

usleep 100_000;
$b->set(5);
waitpid $pid, 0;
is $? >> 8, 0, "child sees parent's set (MAP_SHARED)";

# Reverse direction
my $pid2 = fork // die;
if (!$pid2) {
    my $b2 = Data::BitSet::Shared->new_from_fd($b->memfd);
    usleep 100_000;
    $b2->set(7);
    _exit(0);
}
my $deadline = time + 3;
while (time < $deadline) {
    last if $b->test(7);
    usleep 1000;
}
ok $b->test(7), "parent sees child's set (MAP_SHARED bidirectional)";
waitpid $pid2, 0;

done_testing;
