#!/usr/bin/perl
# Regression: rdx_insert_has_room guaranteed only 2 free nodes from the
# high-water mark ("a split makes a mid node + a leaf node"), but the
# copy-on-write edge split transiently allocates THREE nodes (mid + ch2 +
# leaf) before the displaced child is recycled.  At exactly 2 nodes of
# high-water headroom with an empty free list, the third allocation failed
# mid-split and rdx_insert_locked returned 0 -- which insert() reports to
# the caller as "key already existed, value updated".  The key was never
# inserted, no exception fired, and lookup of the key returned undef.
#
# The pre-check must require the real worst case (3 nodes), counting the
# free list as well as the high-water mark, so the failure surfaces as the
# documented "capacity exhausted" croak BEFORE anything is mutated.
use strict;
use warnings;
use Test::More;
use Data::RadixTree::Shared;

# --- Scenario 1: 2 nodes of headroom, empty free list -> must croak --------
# node_cap=6: NIL(0) + root(1) + 4 more.  "aa" takes node 2, "b" node 3,
# so node_used=4 and the high-water headroom is exactly 2.
my $t = Data::RadixTree::Shared->new(undef, 6, 4096);
is $t->insert("aa", 1), 1, 'insert aa (takes node 2)';
is $t->insert("b", 2),  1, 'insert b (takes node 3)';
is $t->stats->{nodes_used}, 4, 'precondition: high-water mark at 4 of 6';

# "ab" splits the "aa" edge at 1 byte and the key continues past the split:
# the split needs mid + ch2 + leaf = 3 nodes, only 2 are available.
my $ret = eval { $t->insert("ab", 3) };
my $err = $@;
ok !defined($ret), 'split insert with 2 nodes of headroom is refused, not accepted';
like $err, qr/capacity exhausted/,
    'refusal is the visible capacity croak (was: silent 0 == "updated")';
is $t->lookup("ab"), undef, 'refused key was not inserted';
is $t->lookup("aa"), 1, 'split source edge still intact';
is $t->lookup("b"),  2, 'unrelated key still intact';
is $t->count, 2, 'key count unchanged by the refused insert';
is $t->stats->{nodes_used}, 4, 'high-water mark unchanged by the refused insert';

# A retry must be refused the same way, and the tree must stay usable.
$ret = eval { $t->insert("ab", 3); 1 };
$err = $@;
ok !$ret && $err =~ /capacity exhausted/, 'retry is refused identically (tree not wedged)';
# 2 free nodes is below the 3-node worst case, so the pre-check refuses any
# further insert here (path-agnostic, as documented for updates on a full
# tree) -- but non-allocating operations keep working.
$ret = eval { $t->insert("c", 5); 1 };
ok !$ret && $@ =~ /capacity exhausted/, 'non-splitting insert is refused too (worst-case pre-check)';
is $t->delete("b"), 1, 'delete still works on the insert-full tree';
is $t->lookup("b"), undef, '... and the deleted key is gone';
is $t->count, 1, 'count reflects the delete';

# --- Scenario 2: 3 nodes of headroom -> the same split must succeed --------
# Proves the pre-check demands exactly the real worst case, not more.
my $t2 = Data::RadixTree::Shared->new(undef, 7, 4096);
$t2->insert("aa", 1);
$t2->insert("b", 2);
is $t2->insert("ab", 3), 1, 'same split succeeds with 3 nodes of headroom';
is $t2->lookup("ab"), 3, 'split key found';
is $t2->lookup("aa"), 1, 'split-away key still found';
is $t2->stats->{nodes_used}, 7, 'split consumed mid+ch2+leaf from the high-water mark';

# --- Scenario 3: free-list nodes count toward headroom ---------------------
# After the scenario-2 split the displaced child was recycled (free list has
# 1 node, high-water mark is exhausted at 7/7).  With node_cap=9 the same
# shape has headroom 2 high-water + 1 recycled; a leaf-only insert draws on
# the recycled node and must not be refused.
my $t3 = Data::RadixTree::Shared->new(undef, 9, 4096);
$t3->insert("aa", 1);
$t3->insert("b", 2);
$t3->insert("ab", 3);                          # split; recycles the displaced child
is $t3->stats->{nodes_used}, 7, 'precondition: high-water at 7 of 9, free list has 1 node';
is $t3->insert("ac", 4), 1, 'leaf insert succeeds on 2 high-water + 1 recycled node';
is $t3->lookup("ac"), 4, '... and its key is found';
is $t3->stats->{nodes_used}, 7, 'recycled node was reused (high-water mark not bumped)';

# ---------------------------------------------------------------------------
# clear() must also drop the node recycle list.
#
# rdx_clear_locked resets node_used to the high-water base, but the free list
# names nodes ABOVE that base. Leaving free_head set handed the same node out
# twice -- once popped from the stale list, once from the bump path -- and the
# keys stored under the losing insert vanished while count still counted them.
# ---------------------------------------------------------------------------
{
    my $t = Data::RadixTree::Shared->new(undef, 64, 65536);
    $t->insert("abc", "1");
    $t->insert("abd", "2");      # partial-label match -> edge split -> recycles a node
    $t->clear;
    $t->insert("k$_", 100 + $_) for 0 .. 5;

    my @missing = grep { !defined $t->get("k$_") } 0 .. 5;
    is scalar(@missing), 0, "clear() then insert: no key lost to a stale free list"
        or diag "missing after clear: @missing";
    is $t->count, 6, "count matches the number of retrievable keys after clear()";
}

done_testing;
