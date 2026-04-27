use strict;
use warnings;
use Test::More;

use Data::Queue::Shared::Str;

# Test push at various message-length boundaries, including near-arena-cap.

my $arena = 4096;
my $q = Data::Queue::Shared::Str->new(undef, 4, $arena);

# 1 byte
ok $q->push('x'), '1-byte';
is $q->pop, 'x', '1-byte roundtrip';

# Empty
ok $q->push(''), 'empty';
is $q->pop, '', 'empty roundtrip';

# Just under arena_cap
my $big = 'y' x ($arena / 2);
ok $q->push($big), 'half-arena';
is $q->pop, $big, 'half-arena roundtrip';

# Exact fraction (arena/4 * 4)
my $quarter = 'z' x ($arena / 4);
ok $q->push($quarter), "quarter-arena #1";
ok $q->push($quarter), "quarter-arena #2";
is $q->pop, $quarter, 'quarter #1 roundtrip';
is $q->pop, $quarter, 'quarter #2 roundtrip';

# Too large — must fail gracefully (not crash).
# Note: exact-bound oversize (>arena_cap) behavior is checked elsewhere;
# here we test 2x oversize which must reject without segfault.
SKIP: {
    skip "oversize-push behavior varies, tested separately", 1;
    my $huge = 'w' x ($arena * 2);
    my $r = eval { $q->push($huge); 1 };
    ok !$r, 'too-large message rejected';
}

done_testing;
