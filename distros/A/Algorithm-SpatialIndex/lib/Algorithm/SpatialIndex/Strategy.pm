package Algorithm::SpatialIndex::Strategy;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use Algorithm::SpatialIndex::Storage;
use Scalar::Util 'weaken';

use Class::XSAccessor {
  getters => [qw(
    index
    storage
    bucket_size
  )],
};

sub new {
  my $class = shift;
  my %opt = @_;

  my $self = bless {
    bucket_size => 100,
    %opt,
  } => $class;

  weaken($self->{index});

  $self->init() if $self->can('init');

  return $self;
}

sub _super_init_storage {
  my $self = shift;
  $self->init_storage if $self->can('init_storage');
}

sub _set_storage {
  my $self = shift;
  my $storage = shift;
  $self->{storage} = $storage;
  Scalar::Util::weaken($self->{storage});
}

sub no_of_subnodes {
  croak("no_of_subnodes needs to be implemented in a subclass");
}

sub no_of_dimensions {
  croak("no_of_dimensions needs to be implemented in a subclass");
}

sub coord_types {
  croak("coord_types needs to be implemented in a subclass");
}

sub item_coord_types {
  croak("item_coord_types needs to be implemented in a subclass");
}

sub insert {
  croak("insert needs to be implemented in a subclass");
}

sub find_node_for {
  croak("find_node_for needs to be implemented in a subclass");
}

sub find_nodes_for {
  croak("find_nodes_for needs to be implemented in a subclass");
}

sub filter_items_in_rect {
  croak("filter_items_in_rect needs to be implemented in a subclass");
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Strategy - Base class for indexing strategies

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy => 'QuadTree', # or others
  );

=head1 DESCRIPTION

This is the base class for all algorithm implementations (I<Strategies>)
in C<Algorithm::SpatialIndex>. Your implementation should probably not
inherit from this class directly, but from either L<Algorithm::SpatialIndex::Strategy::2D>
or L<Algorithm::SpatialIndex::Strategy::3D> depending on the dimensionality of
your index.

=head1 METHODS

=head2 insert

Inserts a new element into the index. Arguments:
Element (not node!) integer id, Element x/y (and possibly z) coordinates.

Needs to be implemented in a subclass.

=head2 find_node_for

Given x/y (or x/y/z) coordinates, returns
the L<Algorithm::SpatialIndex::Node>
that contains the given point.

Returns undef if the point is outside of the index range.

Needs to be implemented in a subclass.

=head2 find_nodes_for

Given two sets of x/y (or x/y/z) coordinates, returns
all L<Algorithm::SpatialIndex::Node>s that are completely
or partly within the rectangle defined by the two points.

Needs to be implemented in a subclass.

=head2 new

Constructor. Called by the L<Algorithm::SpatialIndex>
constructor. You probably do not need to call or implement this.
Calls your C<init> method if available.

=head2 init

If your subcass implements this, it will be called on the
fresh object in the constructor.

=head2 init_storage

If your subcass implements this, it will be called on the
in the constructor after initializing its storage attribute.

=head2 no_of_dimensions

A method returning the number of dimensions that the index handles.

This is set to a default in the 2D/3D subclasses.

=head2 no_of_subnodes

Returns the number of subnodes per node. Required by the storage
initialization.

This is set to a default in the 2D/3D subclasses.

=head2 coord_types

Returns (as a list) all node coordinate's types. If you need to store
one x/y pair of floating point coordinates per node, you may return:

  qw(double double)

or if less precision is acceptable for space savings:

  qw(float float)

If you need to store three coordinates but only in one dimension,
you simply do:

  qw(float float float)

The storage backend is free to upgrade a float to a double
value and even an integer to a double.

Valid coordinate types are:

  float, double, integer, unsigned

The integer types will be treated as C longs (likely 32bit).

This is set to a default in the 2D/3D subclasses.
You may want to override that in your subclass.

=head2 item_coord_types

Same as coord_types, but indicating what's required for each
item stored in the tree.

This is set to a default in the 2D/3D subclasses.

=item filter_items_in_rect

This method is implemented in L<Algorithm::SpatialIndex::Strategy::2D>
and L<Algorithm::SpatialIndex::Strategy::3D> for their respective
dimensionality. If you inherit from those classes, you will not
have to reimplement this in your strategy implementation.

Given the four or six coordinates of a rectangle (2D) or cuboid (3D)
and one or more leaf node objects, this method fetches all items
associated with the node(s) and returns all of those items
that lie in the specified rectangle or cuboid.

The rectangle/cuboid coordinates are expected to be sorted (thus
the use of C<$xl, $yl> and C<$xu, $yu> instead of 1/2) in the
example:

  # 2D
  my @items = $strategy->filter_items_in_rect($xl, $yl, $xu, $yu, $node1, $node2, ...);
  
  # 3D
  my @items = $strategy->filter_items_in_rect(
    $xl, $yl, $zl,
    $xu, $yu, $zu,
    $node1, $node2, ...
  );

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
