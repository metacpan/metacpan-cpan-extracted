use strict;
use warnings;
use Test::More;

use Data::HashMap::Shared::SS;

# The large free-list first-fit walk must skip a valid block smaller than the
# request rather than abandon the list at it.  Fill the arena with a 2 MiB and
# a 1 MiB value (plus one small live block so the empty-map reset never fires),
# free both, then ask for a 2 MiB block.  When the 1 MiB block is at the list
# head -- near the arena top, so it is smaller than the request and sits in its
# last 2 MiB -- the walk used to break there and never reach the exact 2 MiB
# block behind it, refusing the store though a block of its class was free.

sub refill_order {
    my @order = @_;
    my $m = Data::HashMap::Shared::SS->new(undef, 8, 0, 0, 0, 3 * 2**20 + 48);
    $m->put('a-small-live-block-key-padddd', 'v');   # keep one live block
    $m->put(a => 'A' x 2**21);                        # 2 MiB
    $m->put(b => 'B' x 2**20);                        # 1 MiB, arena now full
    $m->remove($_) for @order;                        # free order sets the list head
    my $ok = $m->put(e => 'E' x 2**21);               # wants a 2 MiB block; A is one
    return ($ok, $ok ? length($m->get('e') // '') : 0);
}

for my $order (['a', 'b'], ['b', 'a']) {
    my ($ok, $len) = refill_order(@$order);
    my $head = "@$order";
    ok $ok, "a 2 MiB store finds the free 2 MiB block (freed $head)";
    is $len, 2**21, "  ... and stores it whole (freed $head)";
}

done_testing;
