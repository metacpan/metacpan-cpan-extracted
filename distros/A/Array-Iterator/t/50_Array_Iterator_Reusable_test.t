#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
    use_ok('Array::Iterator::Reusable')
};

can_ok("Array::Iterator::Reusable", 'new');

my $i = Array::Iterator::Reusable->new(1 .. 5);
isa_ok($i, 'Array::Iterator::Reusable');
isa_ok($i, 'Array::Iterator');

can_ok($i, 'getNext');
can_ok($i, 'get_next');
# exhaust our iterator
1 while $i->getNext();

can_ok($i, 'hasNext');
can_ok($i, 'has_next');
ok(!$i->hasNext(), '... our iterator is exhausted');

can_ok($i, 'reset');
$i->reset();

ok($i->hasNext(), '... our iterator has been reset');

cmp_ok($i->currentIndex(), '==', 0, '... we are back to the begining');
