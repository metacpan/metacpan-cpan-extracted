use strict;
use warnings;
use Test::More;

use Data::HashMap::Shared::SS;

# The large free-list first-fit walk must skip a smaller block rather than
# abandon the list at it: with the 1 MiB block at the list head, the exact 2 MiB
# block behind it must still be found.

sub refill_order {
    my @order = @_;
    my $m = Data::HashMap::Shared::SS->new(undef, 8, 0, 0, 0, 3 * 2**20 + 48);
    $m->put('a-small-live-block-key-padddd', 'v');   # a live block, so the empty-map reset never fires
    $m->put(a => 'A' x 2**21);
    $m->put(b => 'B' x 2**20);
    $m->remove($_) for @order;                        # free order sets the list head
    my $ok = $m->put(e => 'E' x 2**21);
    return ($ok, $ok ? length($m->get('e') // '') : 0);
}

for my $order (['a', 'b'], ['b', 'a']) {
    my ($ok, $len) = refill_order(@$order);
    my $head = "@$order";
    ok $ok, "a 2 MiB store finds the free 2 MiB block (freed $head)";
    is $len, 2**21, "  ... and stores it whole (freed $head)";
}

done_testing;
