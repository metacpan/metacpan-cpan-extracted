use strict;
use warnings;
use Test::More;

# Distinguish "nothing new" (poll returns undef, cursor == write_pos)
# from "ring overflowed" (poll returns undef, subscriber lost messages).

use Data::PubSub::Shared::Int;

my $p = Data::PubSub::Shared::Int->new_memfd("ovfl", 16);   # small ring

my $sub = $p->subscribe;     # cursor = write_pos (nothing old)

# Case 1: empty ring, poll returns undef; overflow flag NOT set
my $v = $sub->poll;
is $v, undef, "poll on empty returns undef";
ok !$sub->has_overflow, "has_overflow is false (simple empty)";

# Publish less than ring size — subscriber reads all
$p->publish($_) for 1..5;
my @got;
while (defined(my $x = $sub->poll)) { push @got, $x }
is_deeply \@got, [1..5], "caught up on 5 items";
ok !$sub->has_overflow, "no overflow after catch-up";

# Now publish MORE than ring capacity — subscriber falls behind and overflows
$p->publish($_) for 6..30;

ok $sub->has_overflow, "has_overflow is true after ring wrap-around";

# After reset_oldest, we should be able to read again without overflow
$sub->reset_oldest;
ok !$sub->has_overflow, "has_overflow cleared after reset_oldest";

my @caught;
while (defined(my $x = $sub->poll)) { push @caught, $x }
cmp_ok scalar(@caught), '>', 0, "reset_oldest lets subscriber re-catch up";
cmp_ok scalar(@caught), '<=', 16, "caught at most ring size (16 items)";

done_testing;
