package Algorithm::SpatialIndex::Bucket;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use Class::XSAccessor {
  constructor => 'new',
  accessors => [qw(
    node_id
    items
  )],
};

sub add_items {
  my $self = shift;
  my $items = $self->{items};
  push @$items, @_;
}

sub nitems {
  my $self = shift;
  return scalar @{$self->{items} };
}


1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Bucket - A container for items

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'QuadTree', # or others
  );

=head1 DESCRIPTION

This document describes the minimum API that needs to be
implemented for classes that can be used as buckets
(more or less: leaf nodes) in the spatial index.
See the main documentation in L<Algorithm::SpatialIndex>
for an explanation of how alternative bucket implementations
can be used.

=head1 METHODS

=head2 new

Constructor

=head2 node_id

Read/write accessor for the id of the node that this bucket
corresponds to.

=head2 items

Read/write accessor for the array ref (or undef if not
initialized) of items in this bucket.
An item is defined to be an unblessed array references
containing the item id followed by the item coordinates.
The type and number of coordinates may depend on the
chosen index C<Strategy>. Cf. the strategy's
C<item_coord_types> method.

=head2 nitems

Returns the number of items in the bucket.

=head2 add_items

Given a list of items (array refs with id and coordinates),
adds these items to the bucket.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
