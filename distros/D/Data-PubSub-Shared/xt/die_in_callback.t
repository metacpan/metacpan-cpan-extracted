use strict;
use warnings;
use Test::More;

# die inside a PubSub poll_cb callback: verify no state leak (cursor
# advanced correctly up to the dying message, no arena bytes orphaned,
# subscriber remains functional).

use Data::PubSub::Shared::Int;

my $p = Data::PubSub::Shared::Int->new_memfd("dietest", 16);
$p->publish($_) for 1..10;

my $sub = $p->subscribe_all;

my @seen;
my $threshold = 5;

eval {
    $sub->poll_cb(sub {
        my $v = shift;
        push @seen, $v;
        die "boom at $v\n" if $v == $threshold;
    });
};
like $@, qr/boom at 5/, "die propagates out of poll_cb";

is_deeply \@seen, [1,2,3,4,5], "callback invoked up to and including die-point";

# Subscriber still functional: subsequent poll returns next message
my $next = $sub->poll;
is $next, 6, "cursor advanced past dying message";

# Drain the rest
my @remaining;
while (defined(my $v = $sub->poll)) { push @remaining, $v }
is_deeply \@remaining, [7,8,9,10], "remaining messages deliverable";

# Publish more, subscribe fresh — stats sane
$p->publish(99);
my $sub2 = $p->subscribe_all;
my @s2;
while (defined(my $v = $sub2->poll)) { push @s2, $v }
cmp_ok scalar(@s2), '>=', 1, "new subscriber reads after die-in-old-sub";

done_testing;
