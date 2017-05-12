# -*- perl -*-
# t/pq_num.t - Check ::PriorityQueue::Numeric

use Test::More tests => 7;

BEGIN { use_ok('Array::Heap::PriorityQueue::Numeric'); }
my $pq = Array::Heap::PriorityQueue::Numeric->new();
isa_ok($pq, 'Array::Heap::PriorityQueue::Numeric');

$pq->add_unordered('a', 3);
$pq->add_unordered('b', 2);
$pq->add_unordered('c', 1);
$pq->restore_order();
is($pq->size(), 3, 'size');
is($pq->get(), 'c', 'get');
is($pq->peek(), 'b', 'get');
$pq->add('z', 0);
is(join(' ', sort $pq->items()), 'a b z', 'items');
is(join(' ', $pq->sorted_items()), 'z b a', 'sorted');

