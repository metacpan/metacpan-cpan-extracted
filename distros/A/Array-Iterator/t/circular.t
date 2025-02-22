#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;

BEGIN {
    use_ok('Array::Iterator::Circular')
};

can_ok("Array::Iterator::Circular", 'new');

my $i = Array::Iterator::Circular->new(1 .. 5);
isa_ok($i, 'Array::Iterator::Circular');
isa_ok($i, 'Array::Iterator');

can_ok($i, 'getLoopCount');
can_ok($i, 'get_loop_count');
can_ok($i, 'isStart');
can_ok($i, 'is_start');
can_ok($i, 'isEnd');
can_ok($i, 'is_end');
can_ok($i, 'getNext');
can_ok($i, 'get_next');

ok($i->isStart(), '... we are at the start of the array');

my $total_count = 0;
while ($i->getLoopCount() < 5) {
    if ($total_count && (($total_count % 5) == 0)) {
        ok($i->isEnd(), '... we are at the end of the array');
        ok($i->hasNext(), '... we should still get true from hasNext');
    }
    defined($i->getNext()) || fail('... this should never return undef');
    $total_count++;
}

cmp_ok($i->getLoopCount(), '==', 5, '... we have looped 5 times');
# this should be 1 past because of how the loop
# above it structured, it is correct.
cmp_ok($total_count, '==', 26, '... we have looped 5 times');
