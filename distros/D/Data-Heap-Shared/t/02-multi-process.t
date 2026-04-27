use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(usleep);

use Data::Heap::Shared;

my $h = Data::Heap::Shared->new_memfd("mp", 32);

# Child pushes, parent pops
my $pid = fork // die;
if (!$pid) {
    my $h2 = Data::Heap::Shared->new_from_fd($h->memfd);
    $h2->push($_, $_ * 10) for (5, 2, 8, 1, 3, 7);
    _exit(0);
}
waitpid $pid, 0;

is $h->size, 6, "child pushed 6";

# Pop in min-heap order
my @got;
while ($h->size) {
    my @p = $h->pop;
    push @got, $p[0];
}
is_deeply \@got, [1, 2, 3, 5, 7, 8], "min-heap order preserved across fork";

done_testing;
