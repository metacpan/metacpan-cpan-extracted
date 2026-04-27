use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep);

# Torn-write detection: producer updates an entry rapidly; concurrent
# reader must observe either the old value or the new value, never a
# half-written state. Seqlock retry on the read path guarantees this.

use Data::HashMap::Shared::SS;

my $m = Data::HashMap::Shared::SS->new_memfd("torn", 1024, 4096);

# Alternating values of different length — torn write would produce a
# truncated or mixed-length result.
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

# Reader: verify every read is one of the two valid values, never torn
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
