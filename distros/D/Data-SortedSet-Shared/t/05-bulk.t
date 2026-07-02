use strict;
use warnings;
use Test::More;
use Data::SortedSet::Shared;

my $z = Data::SortedSet::Shared->new(undef, 10000);
my @rows = map { [ $_, ($_ * 7) % 50 ] } 1 .. 3000;
is $z->add_many(\@rows), 3000, 'add_many returns count of new members';
is $z->count, 3000, 'count after add_many';
ok $z->_validate, 'valid after add_many';
my $ok = 1; for (1 .. 3000) { $ok = 0, last unless $z->score($_) == ($_ * 7) % 50 }
ok $ok, 'scores correct after add_many';

# updates + malformed rows + a NaN-scored row + new
my $a2 = $z->add_many([ [1, 999], [2, 888], "bad", [], [3], [3003, ("NaN" + 0)], [3001, 5], [3002, 6] ]);
is $a2, 2, 'add_many counts only new (updates + malformed + NaN skipped)';
ok !$z->exists(3003), 'NaN-scored row is skipped, not inserted';
is $z->score(1), 999, 'add_many updated an existing score';
is $z->count, 3002, 'count after mixed add_many';
ok $z->_validate, 'valid after mixed add_many';
eval { $z->add_many("nope") }; like $@, qr/arrayref/, 'add_many non-arrayref croaks';

my $f = Data::SortedSet::Shared->new(undef, 3);
is $f->add_many([ [1,1],[2,2],[3,3],[4,4],[5,5] ]), 3, 'add_many stops at max_entries';
is $f->count, 3, 'count capped at max_entries';

my $s = $z->stats;
is $s->{count}, 3002, 'stats: count';
is $s->{max_entries}, 10000, 'stats: max_entries';
cmp_ok $s->{height}, '>=', 1, 'stats: height';
cmp_ok $s->{nodes_used}, '>=', 1, 'stats: nodes_used';
ok $s->{index_load} > 0 && $s->{index_load} < 1, 'stats: index_load';
cmp_ok $s->{mmap_size}, '>', 0, 'stats: mmap_size';
cmp_ok $s->{ops}, '>=', 1, 'stats: ops counter incremented';
cmp_ok $s->{node_capacity}, '>=', $s->{nodes_used}, 'stats: node_capacity >= nodes_used';
cmp_ok $s->{index_slots}, '>', 0, 'stats: index_slots';

done_testing;
