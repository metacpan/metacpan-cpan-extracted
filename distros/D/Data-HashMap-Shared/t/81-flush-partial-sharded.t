use strict;
use warnings;
use Test::More;
use POSIX ();
use Time::HiRes ();
use File::Temp qw(tempdir);
use Data::HashMap::Shared::II;

# On a sharded map flush_expired_partial reports done once every shard has
# finished a cycle; shards of unequal size must not have to finish theirs on the
# same call.

my $dir = tempdir(CLEANUP => 1);
my $m = Data::HashMap::Shared::II->new_sharded("$dir/s", 2, 100000, 0, 60);
my $s0 = Data::HashMap::Shared::II->new("$dir/s.0", 100000, 0, 60);
$s0->put_ttl($_, $_, 0) for 1 .. 2000;              # permanent: shard 0 stays large
my $cap0 = $s0->capacity;
my $cap1 = $m->capacity - $cap0;
cmp_ok $cap0, '>', 4 * $cap1, "shard 0 ($cap0 slots) is much larger than shard 1 ($cap1)";

my $limit = 7;     # divides neither shard's power-of-two slot count
my $bound = POSIX::ceil($cap0 / $limit);
for my $round (1, 2) {
    my $base = 100000 * $round;
    $m->put_ttl($_, $_, 1) for $base + 1 .. $base + 40;   # expire in both shards
    Time::HiRes::sleep(1.2);
    my ($calls, $flushed, $done) = (0, 0, 0);
    while (!$done && $calls <= 4 * $bound) {
        (my $n, $done) = $m->flush_expired_partial($limit);
        $flushed += $n;
        $calls++;
    }
    ok $done, "round $round: reported done";
    cmp_ok $calls, '<=', $bound, "round $round: within the larger shard's cycle ($calls calls)";
    is $flushed, 40, "round $round: flushed every expired entry of both shards";
}
is $m->size, 2000, 'only the permanent entries remain';

done_testing;
