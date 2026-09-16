use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# An insert stores the key, then the value, and only then counts the entry.
# Reclaiming the whole arena because the table is empty is therefore unsafe
# anywhere between those two: the key already holds a block that nothing counts,
# and handing it out again lets the next store write over a live key.  The
# reclaim has to happen before the key is stored, which costs the insert that
# empties the map and heals on the one after it.

my $dir  = tempdir(CLEANUP => 1);
my $path = "$dir/reset.shm";

# 4096-byte arena; 1000-byte values take the 1024 class, 24-byte keys the 32.
my $m = Data::HashMap::Shared::SS->new($path, 64, 64, 0, 0, 4096);
my $K = sub { "K$_[0]" . ('k' x 22) };

$m->put($K->($_), 'v' x 1000) for 0 .. 2;
is $m->size, 3, 'three entries fill the arena bump';
my $spent = $m->arena_used;

$m->remove($K->($_)) for 1, 2;
is $m->size, 1, 'two removed, one left';
is $m->arena_used, $spent, '  ... and the bump does not come back on its own';

# 1500 bytes wants the 2048 class: no free block of it, and no bump left.  The
# single eviction empties the map without making room.
my $KB = 'B' x 24;
my $big = 'w' x 1500;
ok !$m->put($KB, $big), 'the insert that empties the map fails rather than reclaiming under its own key';
is $m->size, 0, '  ... leaving the map empty';

ok $m->put($KB, $big), 'the next insert reclaims the arena first and succeeds';
cmp_ok $m->arena_used, '<', $spent, '  ... which is what reclaiming looks like';
is $m->get($KB), $big, '  ... and stores the value intact';

# Anything the reclaim abandoned would be handed out again here.
my %want = ($KB => $big);
for my $i (1 .. 6) {
    my $k = "F$i" . ('f' x 22);
    last unless $m->put($k, 'g' x 200);
    $want{$k} = 'g' x 200;
}
my @keys = sort $m->keys;
is_deeply \@keys, [sort keys %want], 'every key the map reports is one that was stored';
my @wrong = grep { ($m->get($_) // '') ne $want{$_} } @keys;
is_deeply \@wrong, [], '  ... and still reads back its own value';

done_testing;
