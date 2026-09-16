use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# Compaction is priced like a resize, so what triggers it decides whether the
# map is usable.  Two ways that went wrong, both of which returned perfectly
# correct answers and so were invisible to every other test here:
#
#   * arming on a store that then succeeded after one eviction -- the normal
#     state of a full LRU cache -- put a whole table scan on every 65th insert
#     for the rest of the map's life (measured 329x).
#   * retrying at a fixed rate on an arena that is simply too small, where a
#     slide can never gather anything (measured 54x on the dist's own
#     long-string INSERT benchmark, 92x on the fixture below).
#
# Absolute timings are not portable, so this prices each case against a roomy
# map in the same process and bounds the ratio.  A healthy build sits near 1x,
# so 20x separates it from either defect by a wide margin.
#
# The two fixtures reach different code: an LRU cache frees a block of the
# right class on every eviction, so its stores are never refused and only the
# arming defect can fire there.  The back-off only ever runs on a refusal, so
# its fixture is a map that cannot evict and whose arena is entirely live.

plan skip_all => 'author tests' unless $ENV{AUTHOR_TESTING};
my $load = do {
    if (open my $f, '<', '/proc/loadavg') { (split ' ', <$f>)[0] } else { undef }
};
plan skip_all => 'no /proc/loadavg, so a timing ratio cannot be qualified'
    unless defined $load;
plan skip_all => "machine too loaded for a timing ratio (loadavg $load)" if $load > 4;

my $dir = tempdir(CLEANUP => 1);
my $v = 'v' x 180;
my ($entries, $iters) = (15_000, 8_000);

sub us_per_insert {
    my ($label, $arena_cap) = @_;
    my $m = Data::HashMap::Shared::SS->new("$dir/$label.shm",
                                           $entries, $entries, 0, 0, $arena_cap);
    $m->put(sprintf('k%09d', $_), $v) for 1 .. $entries;
    my $t0 = time;
    $m->put(sprintf('k%09d', $entries + $_), $v) for 1 .. $iters;
    return (time - $t0) * 1e6 / $iters;
}

# No eviction, and an arena the fill leaves entirely live: nothing to gather.
sub us_per_refusal {
    my $m = Data::HashMap::Shared::SS->new("$dir/hopeless.shm",
                                           2 * $entries, 0, 0, 0, $entries * 256 + 4096);
    $m->put(sprintf('k%09d', $_), $v) for 1 .. $entries;
    my $accepted = 0;
    my $t0 = time;
    $accepted += $m->put(sprintf('k%09d', $entries + $_), $v) ? 1 : 0 for 1 .. $iters;
    return ((time - $t0) * 1e6 / $iters, $accepted);
}

my $bound = us_per_insert('bound', $entries * 224);
my $roomy = us_per_insert('roomy', $entries * 224 * 4);
note sprintf 'arena-bound %.2f us/insert, roomy %.2f us/insert (loadavg %s)',
    $bound, $roomy, $load;

cmp_ok $roomy, '>', 0, 'the roomy control measured something';
cmp_ok $bound / $roomy, '<', 20,
    'an insert into a full LRU cache is not priced like a table scan'
    or diag sprintf 'ratio %.1fx -- compaction is running on inserts that succeed',
        $bound / $roomy;

my ($refused, $accepted) = us_per_refusal();
note sprintf 'refused insert on an arena with nothing to gather %.2f us', $refused;
is $accepted, 0, 'the hopeless fixture refuses every store';
cmp_ok $refused / $roomy, '<', 20,
    'and a refusal that cannot be helped is not priced like a table scan either'
    or diag sprintf 'ratio %.1fx -- compaction is retried at a fixed rate', $refused / $roomy;

done_testing;
