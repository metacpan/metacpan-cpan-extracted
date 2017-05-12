package Algorithm::SpatialIndex::Strategy::2D;
use 5.008001;
use strict;
use warnings;

use parent 'Algorithm::SpatialIndex::Strategy';

sub no_of_dimensions { 2 }
sub no_of_subnodes { 4 }
sub coord_types { qw(double double double double) }
sub item_coord_types { qw(double double) }

sub filter_items_in_rect {
  my ($self, $xl, $yl, $xu, $yu, @nodes) = @_;
  my $storage = $self->storage;
  if ($storage->bucket_class->can('items_in_rect')) {
    return map { @{ $storage->fetch_bucket($_->id)->items_in_rect($xl, $yl, $xu, $yu) } }
           @nodes
  }
  return grep $_->[1] >= $xl && $_->[1] <= $xu &&
              $_->[2] >= $yl && $_->[2] <= $yu,
         map { @{ $storage->fetch_bucket($_->id)->items } }
         @nodes;
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Strategy::2D - Base class for 2D indexing strategies

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'QuadTree',
  );

=head1 DESCRIPTION

This class acts as a base class for 2D indexing strategy implementations.
It implements part of the strategy interface for two dimensions and
provides some defaults that are useful for 2D indexes:

=over 2

=item *

C<no_of_dimensions> returns 2 (doh).

=item *

C<no_of_subnodes> returns 4.

=item *

C<item_coord_types> defaults to two doubles.

=item *

C<coord_types> defaults to four doubles.

=back

=head1 METHODS

=head2 filter_items_in_rect

This L<Algorithm::SpatialIndex::Strategy> subclass implements
a generic C<filter_items_in_rect> method that assumes only
two dimensions and that items have two coordinates (x, y).

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
