use strict;
use warnings;
use Test::More;

use Data::Stack::Shared;

my $cap = 128;
my $s = Data::Stack::Shared::Int->new(undef, $cap);

for my $i (1..$cap) { ok $s->push($i), "push $i" }
ok !$s->push(999), 'push at full returns false';
is $s->size, $cap, 'size == capacity';

# LIFO order
for my $i (reverse 1..$cap) { is $s->pop, $i, "pop $i" }
ok !defined $s->pop, 'pop on empty';

done_testing;
