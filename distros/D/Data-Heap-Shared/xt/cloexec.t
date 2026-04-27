use strict;
use warnings;
use Test::More;
use Fcntl qw(F_GETFD FD_CLOEXEC);

use Data::Heap::Shared;

my $h = Data::Heap::Shared->new_memfd("t", 16);
my $fd = $h->memfd;

open(my $fh, '<&=', $fd) or die;
my $flags = fcntl($fh, F_GETFD, 0);
ok $flags & FD_CLOEXEC, "FD_CLOEXEC set on memfd";

my $pid = fork // die;
if (!$pid) {
    exec("sh", "-c", "test -e /proc/self/fd/$fd && exit 10; exit 0") or exit 127;
}
waitpid $pid, 0;
is $? >> 8, 0, "fd absent after exec";

done_testing;
