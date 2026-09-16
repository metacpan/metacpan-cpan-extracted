use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# Arena blocks are exact power-of-two classes that are never split or coalesced,
# so freeing any number of 64-byte blocks can never yield a 512-byte one.  A
# cache whose value size drifts into a larger class therefore evicts an entry
# per attempt without ever fitting, and when the last one goes the arena is
# entirely free yet every insert still fails: the free lists hold only the wrong
# class and the bump is spent.  An empty map has no node pointing at any block,
# so the arena is reset whole and the map becomes usable again.
#
# The drift still costs every entry the cache held -- only the permanent dead
# end afterwards is fixed.

my $dir = tempdir(CLEANUP => 1);

# 60-byte values are the 64 class, 300-byte ones the 512 class.
my $m = Data::HashMap::Shared::SS->new("$dir/drift.shm", 100_000, 5_000, 0, 0, 262144);

my $n = 0;
$m->put("k" . $n++, 'x' x 60) for 1 .. 12_000;
cmp_ok $m->size, '>', 1000, 'the cache fills with small values';

my ($fails, $late_fails) = (0, 0);
for my $i (1 .. 20_000) {
    my $ok = $m->put("k" . $n++, 'x' x 300);
    $fails++      unless $ok;
    $late_fails++ if !$ok && $i > 19_900;      # the tail, long after any reset
}
cmp_ok $fails, '>', 0, 'the drift costs inserts while the old class is evicted';
is $late_fails, 0, 'but the map is serving the new size class by the end';
cmp_ok $m->size, '>', 100, '  ... and holds entries again rather than nothing';

ok $m->put("after", 'x' x 300), 'a further insert of the new size succeeds';
is $m->get("after"), 'x' x 300, '  ... storing the value intact';
is $m->get("k0"), undef, 'the small entries the drift evicted are gone';

done_testing;
