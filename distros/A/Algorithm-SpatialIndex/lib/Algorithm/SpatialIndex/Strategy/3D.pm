package Algorithm::SpatialIndex::Strategy::3D;
use 5.008001;
use strict;
use warnings;

use parent 'Algorithm::SpatialIndex::Strategy';

sub no_of_dimensions { 3 }
sub no_of_subnodes { 8 }
sub coord_types { qw(double double double double double double) }
sub item_coord_types { qw(double double double) }

sub filter_items_in_rect {
  my ($self, $xl, $yl, $zl, $xu, $yu, $zu, @nodes) = @_;
  my $storage = $self->storage;
  if ($storage->bucket_class->can('items_in_rect')) {
    return map { @{ $storage->fetch_bucket($_->id)->items_in_rect($xl, $yl, $zl, $xu, $yu, $zu) } }
           @nodes;
  }
  return grep $_->[1] >= $xl && $_->[1] <= $xu &&
              $_->[2] >= $yl && $_->[2] <= $yu &&
              $_->[3] >= $zl && $_->[3] <= $zu,
         map { @{ $storage->fetch_bucket($_->id)->items } }
         @nodes;
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Strategy::3D - Base class for 3D indexing strategies

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'OctTree',
  );

=head1 DESCRIPTION

This class acts as a base class for 3D indexing strategy implementations.
It implements part of the strategy interface for three dimensions and
provides some defaults that are useful for 3D indexes:

=over 2

=item *

C<no_of_dimensions> returns 3 (doh).

=item *

C<no_of_subnodes> returns 8.

=item *

C<item_coord_types> defaults to three doubles.

=item *

C<coord_types> defaults to six doubles.

=back

=head1 METHODS

=head2 filter_items_in_rect

This L<Algorithm::SpatialIndex::Strategy> subclass implements
a generic C<filter_items_in_rect> method that assumes only
three dimensions and that items have three coordinates (x, y, z).

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
