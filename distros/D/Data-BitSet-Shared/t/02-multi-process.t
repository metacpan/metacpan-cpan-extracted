use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::BitSet::Shared;

my $b = Data::BitSet::Shared->new_memfd("mp", 256);

# Child sets bits, parent verifies
my $pid = fork // die;
if (!$pid) {
    my $b2 = Data::BitSet::Shared->new_from_fd($b->memfd);
    $b2->set($_) for (10, 20, 30, 100, 255);
    _exit(0);
}
waitpid $pid, 0;

ok $b->test($_), "bit $_ set by child" for (10, 20, 30, 100, 255);
ok !$b->test(50), "unrelated bit unchanged";
is $b->count, 5, "count matches";

# Bulk toggle
$b->clear($_) for (10, 20);
is $b->count, 3, "after clear(10,20), count=3";

# Any-bit queries
ok $b->any, "any returns true";

done_testing;
