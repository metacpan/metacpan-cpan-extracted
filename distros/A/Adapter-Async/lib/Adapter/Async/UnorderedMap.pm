package Adapter::Async::UnorderedMap;
$Adapter::Async::UnorderedMap::VERSION = '0.019';
use strict;
use warnings;

use parent qw(Adapter::Async);

=head1 NAME

Adapter::Async::UnorderedMap - API for dealing with key => value maps

=head1 VERSION

version 0.018

=head1 DESCRIPTION

=head2 Accessing data

=over 4

=item * count - resolves with the number of items. If this isn't possible, an estimate may be acceptable.

 say "items: " . $adapter->count->get

=item * get - accepts a list of keys

 $adapter->get(
  items   => [1,2,3],
  on_item => sub { ... }
 )->on_done(sub { warn "all done, full list of items: %{$_[0]}" })

Unlike the L<Adapter::Async::OrderedList/get> method, this resolves to a hashref.

The top-level of the hashref returned is guaranteed not to be modified further, if you want to store it
directly. No such guarantee applies to the values themselves - it is only a shallow clone.

=back

This means we have double-notify on get: a request for (a,b, 34, q) needs to fire events for each of a,b,34,q, and also return the hashref containing those keys on completion (by resolving a L<Future>).

=head2 Modification

=over 4

=item * clear - remove all data

=item * modify - changes a single entry

=item * set - adds a new key

=item * delete - removes an existing key

=back

=head2 Events

All events are shared over a common bus for each data source, in the usual fashion - adapters and views can subscribe to the ones they're interested in, and publish events at any time.

The adapter raises these:

=over 4

=item * item_changed - the given item has been modified. by default only applies to elements that were marked as visible.

=item * splice - changes to the array which remove or add elements

=item * move - an existing element moves to a new key (some adapters may not be able to differentiate between this and splice: if in doubt, use splice instead, don't report as a move unless it's guaranteed to be existing items)

=back

The view raises these:

=over 4

=item * visible - indicates visibility of one or more items. change events will start being sent for these items.

 visible => [1,2,3,4,5,6]

Filters may result in a list with gaps:

 visible => [1,3,4,8,9,10]

Note that "visible" means "the user is able to see this data", so they'd be a single page of data rather than the entire set when no filters are applied. Visibility changes often - scrolling will trigger a visible/hidden pair for example.

Also note that ->get may be called on any element, regardless of visibility - prefetching is one common example here.

=item * hidden - no longer visible.

 hidden => [1,2,4]

=item * selected - this item is now part of an active selection. could be used to block deletes.

 selected => [1,4,5,6]

=item * highlight - mouse over, cursor, etc. 

 highlight => 1

Some views won't raise this - if touch control is involved, for example

=item * activate - some action has been performed.

 activate => [1]
 activate => [1,2,5,6,7,8]

Multi-activate will typically happen when items have been selected rather than just highlighted.

The adapter itself doesn't do much with this.

=back

=cut

=head1 METHODS

=head2 set

Sets the value of a key.

 $adapter->set(xyz => 'abc')

=cut

sub set { ... }

=head2 all

Returns all the items. Shortcut for calling
L</count> then L</get>.

=cut

sub all {
	my ($self, %args) = @_;
	my $f;
	$f = $self->count->then(sub {
		my ($count) = @_;
		return Future->wrap([]) unless $count;
		$self->get(
			%args,
			items => [0..$count-1],
		)
	})->on_ready(sub { undef $f });
	$f
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2013-2015. Licensed under the same terms as Perl itself.
