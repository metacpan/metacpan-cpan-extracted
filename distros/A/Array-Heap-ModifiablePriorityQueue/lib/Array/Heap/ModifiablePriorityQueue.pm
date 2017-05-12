package Array::Heap::ModifiablePriorityQueue;
use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '1.10';
use Array::Heap qw( adjust_heap_idx make_heap_idx pop_heap_idx push_heap_idx
   splice_heap_idx );

=head1 NAME

Array::Heap::ModifiablePriorityQueue - Modifiable priority queue

=head1 SYNOPSIS

   use Array::Heap::ModifiablePriorityQueue;
   my $pq = Array::Heap::ModifiablePriorityQueue->new();
   $pq->add('fish', 42);
   $pq->add('banana', 27);
   print $pq->peek(), "\n"; # banana
   $pq->remove('banana');
   print $pq->get(), "\n"; # fish

=head1 DESCRIPTION

This module implements a priority queue, which is a data structure that can
efficiently locate the item with the lowest weight at any time. This is useful
for writing cost-minimizing and shortest-path algorithms.

Why another priority queue module? First, unlike many similar modules, this one
allows you to modify the queue. Items can be removed from the queue or have
their weight changed after they are added.

Second, it simple to use. Items in the queue don't have to implement any
specific interface. Just throw them in there along with a weight value and
the module will keep track of everything.

Finally, it has good performance on large datasets. This is because it is
based on a partially-ordered heap data structure. Many other priority
queue modules are based on fully sorted lists (even ones that claim to be
heaps). Keeping the items only partially sorted saves time when there are
are a large number of them (several thousand or so).

This module is a Perl wrapper around L<Array::Heap>, a lightweight and fast
heap management module implemented in XS.

=head1 FUNCTIONS

=over 4

=item Array::Heap::ModifiablePriorityQueue->new()

Create a new, empty priority queue.

=cut

sub new {
   my ($class) = @_;
   return bless { heap => [], items => {} } => $class;
}

=item $pq->add($item, $weight)

Add an item to the priority queue with the given weight. If the item is
already present in the queue, modify its weight. Weight must be numeric.

=cut

sub add {
   my ($self, $item, $weight) = @_;
   if (my $node = $self->{items}{$item}) {
      $node->[0] = $weight;
      adjust_heap_idx @{$self->{heap}}, $node->[1];
   }
   else {
      $node = [ $weight, 0, $item ];
      $self->{items}{$item} = $node;
      push_heap_idx @{$self->{heap}}, $node;
   }
}

=item $pq->peek()

Return the first (numerically lowest weight) item from the queue.
Does not modify the queue. Returns undef if the queue is empty.

=cut

sub peek {
   my ($self) = @_;
   my $node = $self->{heap}[0] or return;
   return $node->[2];
}

=item $pq->get()

Removes the first item from the priority queue and returns it.
Returns undef if the queue is empty. If two items in the queue
have equal weight, this module makes no guarantee as to which
one will be returned first.

=cut

sub get {
   my ($self) = @_;
   my $node = pop_heap_idx @{$self->{heap}} or return;
   my $item = $node->[2];
   delete $self->{items}{$item};
   return $item;
}

=item $pq->remove($item)

Removes the given item from the priority queue. If item is not present
in the queue, does nothing.

=cut

sub remove {
   my ($self, $item) = @_;
   my $node = delete $self->{items}{$item} or return;
   splice_heap_idx @{$self->{heap}}, $node->[1];
}

=item $pq->weight($item)

Returns the weight of the item, or undef if it is not present.

=cut

sub weight {
   my ($self, $item) = @_;
   my $node = $self->{items}{$item} or return;
   return $node->[0];
}

=item $pq->min_weight($item)

Returns the minimum weight from the queue, or undef if empty.

=cut

sub min_weight {
   my ($self) = @_;
   my $node = $self->{heap}[0] or return;
   return $node->[0];
}

=item $pq->size()

Returns the number of items in the priority queue.

=cut

sub size {
   my ($self) = @_;
   return scalar @{$self->{heap}};
}

=item $pq->items()

Returns all items in the heap, in an arbitrary order.

=cut

sub items {
   my ($self) = @_;
   return map { $_->[2] } @{$self->{heap}};
}

=item $pq->sorted_items()

Returns all items in the heap, in weight order.

=cut

sub sorted_items {
   my ($self) = @_;
   return map { $_->[2] } sort { $a->[0] <=> $b->[0] } @{$self->{heap}};
}

=item $pq->add_unordered($item, $weight)

Add an item to the priority queue or change its weight, without updating
the heap structure. If you are adding a bunch of items at once, it may be
more efficient to use add_unordered, then call $pq->restore_order() once
you are done.

=cut

sub add_unordered {
   my ($self, $item, $weight) = @_;
   if (my $node = $self->{items}{$item}) {
      $node->[0] = $weight;
   }
   else {
      my $heap = $self->{heap};
      $node = [ $weight, scalar(@$heap), $item ];
      $self->{items}{$item} = $node;
      push @$heap, $node;
   }
}

=item $pq->remove_unordered($item)

Remove an item from the priority queue without updating the heap structure.
If item is not present in the queue, do nothing.

=cut

sub remove_unordered {
   my ($self, $item) = @_;
   my $node = delete $self->{items}{$item} or return;
   my $heap = $self->{heap};
   my $last = pop @$heap;
   if ($last != $node) {
      $heap->[$node->[1]] = $last;
      $last->[1] = $node->[1];
   }
}

=item $pq->restore_order()

Restore the heap structure after calling add_unordered or remove_unordered.
You need to do this before calling any of the ordered methods (add, remove,
peek, or get).

=cut

sub restore_order {
   my ($self) = @_;
   make_heap_idx @{$self->{heap}};
}

=back

=head1 PERFORMANCE

The peek and weight functions run in constant time, or O(1) in asymptotic
notation. The structure-modifying functions add, get, and remove run in
O(log n) time. The items function is O(n), and sorted_items is O(n log n).
Add_unordered and remove_unordered are O(1), but after a sequence of
unordered operations, you need to call restore_order, which is O(n).

If you don't need the modifiable features of this module, consider using
L<Array::Heap::PriorityQueue::Numeric> instead.

If you feel that you need maximum speed, go ahead and inline these
methods into your own code to avoid an extra method invocation. They
are all quite short and simple.

=head1 LIMITATIONS

Weight values must be numeric. This is a limitation of the underlying
Array::Heap module.

Weights are sorted in increasing order only. If you want it the other way,
use the negative of the weights you have.

Items are distinguished by their stringified values. This works fine if you
are storing scalars or plain references. If your items have a custom
stringifier that returns nonunique strings, or their stringified value can
change, you may need to use Array::Heap directly.

=head1 SEE ALSO

L<Heap> for a different priority queue implementation.

L<Heap::Simple> is easy to use, but doesn't allow weights to be changed.

L<Array::Heap> if you need more direct access to the data structure.

=head1 AUTHOR

Bob Mathews <bobmathews@alumni.calpoly.edu>

=head1 REPOSITORY

L<https://github.com/bobmath/ModifiablePriorityQueue>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1 # end ModifiablePriorityQueue.pm
