package Array::Heap::PriorityQueue::String;
use strict;
use warnings;
use vars qw( $VERSION );
$VERSION = '1.10';
use Array::Heap qw( make_heap_lex pop_heap_lex push_heap_lex );

=head1 NAME

Array::Heap::PriorityQueue::String - String-weighted priority queue

=head1 SYNOPSIS

   use Array::Heap::PriorityQueue::String;
   my $pq = Array::Heap::PriorityQueue::String->new();
   $pq->add('fish', 'b');
   $pq->add('banana', 'a');
   print $pq->get(), "\n"; # banana
   print $pq->peek(), "\n"; # fish

=head1 DESCRIPTION

This module implements a priority queue, which is a data structure that can
efficiently locate the item with the lowest weight at any time.

Weights are strings, which are sorted in lexicographic order.

This module is a wrapper around the *_heap_lex methods provided by
L<Array::Heap>.

=head1 FUNCTIONS

=over 4

=item Array::Heap::PriorityQueue::String->new()

Create a new, empty priority queue.

=cut

sub new {
   my ($class) = @_;
   return bless [ ] => $class;
}

=item $pq->add($item, $weight)

Add an item to the priority queue with the given weight. Weights are
compared as strings (lexicographically), and default to item.

=cut

sub add {
   my ($self, $item, $weight) = @_;
   $weight = "$item" unless defined $weight;
   push_heap_lex @$self, [ $weight, $item ];
}

=item $pq->peek()

Return the first (lexicographically lowest weight) item from the queue.
Does not modify the queue. Returns undef if the queue is empty.

=cut

sub peek {
   my ($self) = @_;
   my $node = $self->[0] or return;
   return $node->[1];
}

=item $pq->get()

Removes the first item from the priority queue and returns it.
Returns undef if the queue is empty. If two items in the queue
have equal weight, this module makes no guarantee as to which
one will be returned first.

=cut

sub get {
   my ($self) = @_;
   my $node = pop_heap_lex @$self or return;
   return $node->[1];
}

=item $pq->min_weight()

Returns the weight of the lowest item in the queue, or undef if empty.

=cut

sub min_weight {
   my ($self) = @_;
   my $node = $self->[0] or return;
   return $node->[0];
}

=item $pq->size()

Returns the number of items in the priority queue.

=cut

sub size {
   my ($self) = @_;
   return scalar @$self;
}

=item $pq->items()

Returns all items in the heap, in an arbitrary order.

=cut

sub items {
   my ($self) = @_;
   return map { $_->[1] } @$self;
}

=item $pq->sorted_items()

Returns all items in the heap, in weight order.

=cut

sub sorted_items {
   my ($self) = @_;
   return map { $_->[1] } sort { $a->[0] cmp $b->[0] } @$self;
}

=item $pq->add_unordered($item, $weight)

Add an item to the priority queue or change its weight, without updating
the heap structure. If you are adding a bunch of items at once, it may be
more efficient to use add_unordered, then call $pq->restore_order() once
you are done. Weight defaults to item.

=cut

sub add_unordered {
   my ($self, $item, $weight) = @_;
   $weight = "$item" unless defined $weight;
   push @$self, [ $weight, $item ];
}

=item $pq->restore_order()

Restore the heap structure after calling add_unordered. You need to do this
before calling any of the ordered methods (add, peek, or get).

=cut

sub restore_order {
   my ($self) = @_;
   make_heap_lex @$self;
}

=back

=head1 LIMITATIONS

Strings are sorted in alphabetical order. If you want reverse order, use
L<Array::Heap::PriorityQueue::Compare>.

=head1 SEE ALSO

L<Array::Heap::ModifiablePriorityQueue>

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

1 # end String.pm
