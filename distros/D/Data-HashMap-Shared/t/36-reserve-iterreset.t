use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;

for my $want (100, 1000, 10_000) {
    my $m   = Data::HashMap::Shared::II->new("$dir/r" . $seq++ . ".shm", $want);
    my $max = $m->max_entries;
    ok $m->reserve($max), "reserve(max_entries) accepted for max_entries=$want";
    cmp_ok $m->capacity, '>', 16, "  ... and the table actually grew";

    $m->put($_, $_) for 1 .. $max;
    is $m->size, $max, "  ... and holds all $max entries";

    my $n = Data::HashMap::Shared::II->new("$dir/r" . $seq++ . ".shm", $want);
    ok !$n->reserve($n->max_entries * 4), '  ... while a target past the ceiling is still refused';
}

# sharded: iter_reset must flush each shard, not only the dispatcher handle
for my $case ([plain => 0], [sharded => 1]) {
    my ($label, $sharded) = @$case;
    my $p = "$dir/i" . $seq++;
    my $m = $sharded
        ? Data::HashMap::Shared::II->new_sharded($p, 1, 20_000)
        : Data::HashMap::Shared::II->new("$p.shm", 20_000);

    $m->put($_, $_) for 1 .. 8_000;
    my $grown = $m->capacity;

    my $seen = 0;
    while (my ($k, $v) = $m->each) { $m->remove($k) if ++$seen <= 7_900; last if $seen > 7_900 }
    is $m->capacity, $grown, "$label: shrink is deferred while the iteration is open";

    $m->iter_reset;
    cmp_ok $m->capacity, '<', $grown, "$label: iter_reset applies the deferred shrink";
}

done_testing;
