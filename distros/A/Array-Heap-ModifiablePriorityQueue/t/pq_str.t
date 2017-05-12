# -*- perl -*-
# t/pq_str.t - Check ::PriorityQueue::String

use Test::More tests => 7;

BEGIN { use_ok('Array::Heap::PriorityQueue::String'); }
my $pq = Array::Heap::PriorityQueue::String->new();
isa_ok($pq, 'Array::Heap::PriorityQueue::String');

$pq->add_unordered('a', 'Z');
$pq->add_unordered('b', 'Y');
$pq->add_unordered('c', 'X');
$pq->restore_order();
is($pq->size(), 3, 'size');
is($pq->get(), 'c', 'get');
is($pq->peek(), 'b', 'get');
$pq->add('z', 'W');
is(join(' ', sort $pq->items()), 'a b z', 'items');
is(join(' ', $pq->sorted_items()), 'z b a', 'sorted');

