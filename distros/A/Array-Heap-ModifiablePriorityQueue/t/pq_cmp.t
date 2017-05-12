# -*- perl -*-
# t/pq_cmp.t - Check ::PriorityQueue::Compare

use Test::More tests => 7;

BEGIN { use_ok('Array::Heap::PriorityQueue::Compare'); }
my $pq = Array::Heap::PriorityQueue::Compare->new(sub { $b cmp $a });
isa_ok($pq, 'Array::Heap::PriorityQueue::Compare');

$pq->add_unordered('a');
$pq->add_unordered('b');
$pq->add_unordered('c');
$pq->restore_order();
is($pq->size(), 3, 'size');
is($pq->get(), 'c', 'get');
is($pq->peek(), 'b', 'get');
$pq->add('z');
is(join(' ', sort $pq->items()), 'a b z', 'items');
is(join(' ', $pq->sorted_items()), 'z b a', 'sorted items');

