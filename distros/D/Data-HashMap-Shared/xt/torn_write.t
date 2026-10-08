use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);

use Data::HashMap::Shared::SS;

# A non-zero max_size routes writes through the LRU code (one key, so nothing
# evicts). 2047 keeps it below the table capacity of 2048 slots, avoiding the
# constructor's unreachable-LRU-bound warning.
my $m = Data::HashMap::Shared::SS->new_memfd("torn", 1024, 2047);

# Different lengths, so a torn write shows as a truncated or
# mixed-length result.
my $v1 = "A" x 100;
my $v2 = "B" x 200;

my $pid = fork // die;
if (!$pid) {
    my $m2 = Data::HashMap::Shared::SS->new_from_fd($m->memfd);
    my $end = time + 1.0;
    my $toggle = 0;
    while (time < $end) {
        $m2->put("k", $toggle++ & 1 ? $v1 : $v2);
    }
    _exit(0);
}

my $torn = 0;
my $reads = 0;
my $end = time + 1.0;
while (time < $end) {
    my $v = $m->get("k");
    next unless defined $v;
    $reads++;
    $torn++ if $v ne $v1 && $v ne $v2;
}

waitpid $pid, 0;

diag "reads=$reads torn=$torn";
cmp_ok $reads, '>', 100, "read repeatedly under concurrent writes";
is $torn, 0, "no torn reads (seqlock retry works)";

done_testing;
