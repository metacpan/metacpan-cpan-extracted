use strict;
use warnings;
use Test::More;
use Time::HiRes qw(usleep time);
use POSIX qw(_exit);

use Data::Log::Shared;

my $l = Data::Log::Shared->new_memfd("shared", 4096);
$l->append("parent-1");

my $pid = fork // die;
if (!$pid) {
    my $l2 = Data::Log::Shared->new_from_fd($l->memfd);
    my $deadline = time + 3;
    while (time < $deadline) {
        last if $l2->entry_count >= 2;
        usleep 1000;
    }
    _exit($l2->entry_count >= 2 ? 0 : 10);
}

usleep 100_000;
$l->append("parent-2");
waitpid $pid, 0;
is $? >> 8, 0, "child sees parent's append (MAP_SHARED)";

done_testing;
