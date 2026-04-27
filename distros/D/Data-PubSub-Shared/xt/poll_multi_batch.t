use strict;
use warnings;
use Test::More;

# poll_multi batch semantics:
#   - returns at most N items
#   - no duplicates
#   - preserves publish order
#   - never skips available items

use Data::PubSub::Shared::Int;

my $p = Data::PubSub::Shared::Int->new_memfd("pmb", 64);

# Publish 20 distinct values
$p->publish($_) for 1..20;

my $sub = $p->subscribe_all;

# poll_multi(5): up to 5 items
my @batch1 = $sub->poll_multi(5);
cmp_ok scalar(@batch1), '<=', 5, "batch1 <= 5 items";
cmp_ok scalar(@batch1), '>=', 1, "batch1 non-empty";

my @batch2 = $sub->poll_multi(5);
my @batch3 = $sub->poll_multi(100);   # drain

my @all = (@batch1, @batch2, @batch3);

# No duplicates
my %seen;
for (@all) { $seen{$_}++ }
my @dups = grep { $seen{$_} > 1 } keys %seen;
is scalar(@dups), 0, "no duplicates across batches";

# Order preserved
my @sorted = sort { $a <=> $b } @all;
is_deeply \@all, \@sorted, "items in publish order";

# All 20 delivered
is scalar(@all), 20, "all 20 items eventually delivered";

# poll_multi on empty: returns empty list
my @empty = $sub->poll_multi(10);
is scalar(@empty), 0, "poll_multi on drained returns empty";

# poll_multi(0): returns nothing
$p->publish(99);
my @zero = $sub->poll_multi(0);
is scalar(@zero), 0, "poll_multi(0) returns nothing even if items available";

done_testing;
