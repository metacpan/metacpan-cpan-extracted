use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use Data::HashMap::Shared::SI;

# Never-repeating keys on a TTL map at its largest table, with the Cookbook's
# partial flush after every batch: the flush leaves free slots in a window, so
# the "no free slot" reclaim never fires, and expired entries used to stretch
# every insert's probe across the table and every compaction's placement chains
# into seconds under the write lock.  The table takes longer to fill than the
# TTL, as a real flood does.  Priced by how many inserts fit in 30 s.

my $m = Data::HashMap::Shared::SI->new(undef, 1_000_000, 0, 2);
my ($i, $worst, $t0) = (0, 0, time);
while (time - $t0 < 30 && $i < 4_000_000) {
    for (1 .. 4096) {
        my $t = time;
        $m->put("subject-" . $i++, 1);
        my $d = time - $t;
        $worst = $d if $d > $worst;
    }
    $m->flush_expired_partial(16384);
}
my $el = time - $t0;
diag sprintf '%d inserts in %.1f s, worst put %.1f ms, %d slots', $i, $el, $worst * 1e3, $m->capacity;
cmp_ok $i, '>=', 4_000_000, 'four million unique keys go in within 30 s';
cmp_ok $worst, '<', 3, 'and no single insert stalls for seconds';

# Over its load with nothing expired, the flush finds nothing: it must not
# rescan the whole table on every insert.
{
    require Data::HashMap::Shared::II;
    my $m = Data::HashMap::Shared::II->new(undef, 100_000, 0, 3600);
    my $n = int($m->max_entries * 1.02);
    $m->put($_, $_) for 1 .. $n;
    my $t = time;
    $m->put($n + $_, 1) for 1 .. 20_000;
    my $el = time - $t;
    cmp_ok $el, '<', 0.5, sprintf('20k inserts over the load with nothing expired take %.0f ms', $el * 1e3);
}

# A failed overwrite protects its expired value from reclamation. Repeating
# that overwrite still needs only one scan per second: fixing the later insert
# must not turn these failures into a whole-table scan on every call.
{
    require Data::HashMap::Shared::IS;
    my $m = Data::HashMap::Shared::IS->new(undef, 100_000, 0, 3600, 0, 4096);
    $m->reserve(100_000) or die 'reserve';
    my $value = 'v' x 1500;   # one class-2048 block fits; its replacement cannot
    $m->put_ttl(1, $value, 1) or die 'put';
    Time::HiRes::sleep(1.2);
    ok !$m->exists(1), 'the protected overwrite fixture has expired';
    my ($failed, $t) = (0, time);
    $m->put(1, $value) or $failed++ for 1 .. 20_000;
    my $el = time - $t;
    is $failed, 20_000, 'the repeated overwrites still leave the old entry alone';
    cmp_ok $el, '<', 0.5,
        sprintf('20k failed expired overwrites of a large table take %.0f ms', $el * 1e3);
}

done_testing;
