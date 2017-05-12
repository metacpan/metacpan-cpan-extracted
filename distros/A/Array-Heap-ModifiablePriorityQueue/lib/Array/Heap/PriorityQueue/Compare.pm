package Array::Heap::PriorityQueue::Compare;
use strict;
use warnings;
use Carp qw( croak );
use vars qw( $VERSION );
$VERSION = '1.10';
use Array::Heap ( );

=head1 NAME

Array::Heap::PriorityQueue::Compare - Priority queue with custom comparison

=head1 SYNOPSIS

   use Array::Heap::PriorityQueue::Compare;
   my $pq = Array::Heap::PriorityQueue::Compare->new(sub { $b cmp $a });
   $pq->add('banana');
   $pq->add('fish');
   print $pq->get(), "\n"; # fish
   print $pq->peek(), "\n"; # banana

=head1 DESCRIPTION

This module implements a priority queue, which is a data structure that can
efficiently locate the item with the lowest weight at any time. This is useful
for writing cost-minimizing and shortest-path algorithms.

When creating a new queue, you supply a comparison function that is used to
order the items.

This module is a wrapper around the *_heap_cmp methods provided by
L<Array::Heap>.

=head1 FUNCTIONS

=over 4

=item Array::Heap::PriorityQueue::Compare->new(\&compare)

=item Array::Heap::PriorityQueue::Compare->new(sub { ... })

Create a new, empty priority queue. Requires a reference to a comparison
function. The example above sorts items in reverse alphabetical order.
If your items are hashes containing a weight key, use this:

   sub { $a->{weight} <=> $b->{weight} }

If you are storing objects that have their own comparison function:

   sub { $a->cmp($b) }

If the order of the objects changes after they are added to the queue,
you will need to call restore_order to repair the queue data structure.

=cut

my %funcs;

sub new {
   my ($class, $compare) = @_;
   croak "Comparison function required" unless ref($compare) eq 'CODE';

   # This nonsense is necessary so that Array::Heap will put its $a and $b
   # values in the caller's package instead of this module's package.
   my $pkg = caller || 'main';
   my $f = $funcs{$pkg} ||= eval "package $pkg;" . q{[
      sub { &Array::Heap::push_heap_cmp },
      sub { &Array::Heap::pop_heap_cmp  },
      sub { &Array::Heap::make_heap_cmp },
      sub { my ($cmp, $heap) = @_; sort $cmp @$heap },
   ]} or die "Compile failed: $@";
   # If you're writing your own module that uses Array::Heap, and your
   # comparison function is located in the current package, you don't
   # need this trick. Just call the Array::Heap functions directly.

   return bless { cmp => $compare, heap => [ ], push => $f->[0],
      pop => $f->[1], make => $f->[2], sort => $f->[3] } => $class;
}

=item $pq->add($item)

Add an item to the priority queue.

=cut

sub add {
   my ($self, $item) = @_;
   $self->{push}->($self->{cmp}, $self->{heap}, $item);
}

=item $pq->peek()

Return the first (lowest weight) item from the queue.
Does not modify the queue. Returns undef if the queue is empty.

=cut

sub peek {
   my ($self) = @_;
   return $self->{heap}[0];
}

=item $pq->get()

Removes the first item from the priority queue and returns it.
Returns undef if the queue is empty.

If two items in the queue have equal weight, this module makes no guarantee
as to which one will be returned first. If this is a problem for you,
record the order that elements are added to the queue and use that to
break ties.

   my $pq = Array::Heap::PriorityQueue::Compare->new(sub {
      $a->{weight} <=> $b->{weight} || $a->{order} <=> $b->{order} });
   my $order = 0;
   foreach my $item (@items) {
      $item->{order} = ++$order;
      $pq->add_unordered($item);
   }
   $pq->restore_order();

=cut

sub get {
   my ($self) = @_;
   return $self->{pop}->($self->{cmp}, $self->{heap});
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
   return @{$self->{heap}};
}

=item $pq->sorted_items()

Returns all items in the heap, in weight order.

=cut

sub sorted_items {
   my ($self) = @_;
   return $self->{sort}->($self->{cmp}, $self->{heap});
}

=item $pq->add_unordered($item)

Add an item to the priority queue without updating the heap structure.
If you are adding a bunch of items at once, it may be more efficient to
use add_unordered, then call $pq->restore_order() once you are done.

=cut

sub add_unordered {
   my ($self, $item) = @_;
   push @{$self->{heap}}, $item;
}

=item $pq->restore_order()

Restore the heap structure after calling add_unordered. You need to do this
before calling any of the ordered methods (add, peek, or get).

=cut

sub restore_order {
   my ($self) = @_;
   $self->{make}->($self->{cmp}, $self->{heap});
}

=back

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

1 # end Compare.pm
