use strict;
use warnings;
use Test::More;

# Detached subscriber: publisher handle destroyed, but an existing
# subscriber keeps the memfd alive and can drain pending messages.

use Data::PubSub::Shared::Int;

my $sub;
{
    my $p = Data::PubSub::Shared::Int->new_memfd("detached", 64);
    $p->publish($_) for 1..10;
    $sub = $p->subscribe_all;
    # $p goes out of scope — its handle is destroyed
}

# $sub must still be usable
my @got;
while (defined(my $v = $sub->poll)) { push @got, $v; last if @got > 20 }
is_deeply \@got, [1..10], "subscriber drained pending messages after publisher destroy";

# A fresh subscriber can still be created if we kept a reference to the fd
# (via $sub's backing memfd). Cannot via $sub alone without extra API,
# so just verify $sub itself remains consistent.
is $sub->poll, undef, "further poll returns undef (drained)";

done_testing;
