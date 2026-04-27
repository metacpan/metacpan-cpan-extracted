use strict;
use warnings;
use Test::More;

use Data::Deque::Shared;

# Fill to exact capacity, verify push_back fails gracefully, then drain.
my $cap = 64;
my $d = Data::Deque::Shared::Int->new(undef, $cap);

for my $i (1..$cap) {
    ok $d->push_back($i), "push_back $i";
}
ok !$d->push_back(999), 'push_back at full returns false';
is $d->size, $cap, 'size == capacity';

# Pop all in order
for my $i (1..$cap) {
    is $d->pop_front, $i, "pop_front $i";
}
ok !defined $d->pop_front, 'pop_front on empty';
is $d->size, 0, 'size 0';

# Mixed front/back at capacity
for (1..$cap/2) { $d->push_back($_); $d->push_front(-$_) }
is $d->size, $cap, 'mixed fill to capacity';
ok !$d->push_back(1), 'push_back fails';
ok !$d->push_front(1), 'push_front fails';

done_testing;
