package Algorithm::SpatialIndex;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.06';

use Module::Pluggable (
  sub_name    => 'strategies',
  search_path => [__PACKAGE__ . "::Strategy"],
  require     => 1,
  inner       => 0,
);

use Module::Pluggable (
  sub_name    => 'storage_backends',
  search_path => [__PACKAGE__ . "::Storage"],
  require     => 1,
  inner       => 0,
);

use Algorithm::SpatialIndex::Node;
use Algorithm::SpatialIndex::Bucket;
use Algorithm::SpatialIndex::Strategy;
use Algorithm::SpatialIndex::Storage;

use Class::XSAccessor {
  getters => [qw(
    strategy
    storage
    limit_x_low
    limit_x_up
    limit_y_low
    limit_y_up
    limit_z_low
    limit_z_up
    bucket_size
    max_depth
  )],
};

sub new {
  my $class = shift;
  my %opt = @_;

  my $self = bless {
    limit_x_low => -100,
    limit_x_up  => 100,
    limit_y_low => -100,
    limit_y_up  => 100,
    limit_z_low => -100,
    limit_z_up  => 100,
    bucket_size => 100,
    max_depth   => 20,
    %opt,
  } => $class;

  $self->_init_strategy(\%opt);
  $self->_init_storage(\%opt);
  $self->strategy->_set_storage($self->storage);
  $self->strategy->_super_init_storage();

  return $self;
}

sub _init_strategy {
  my $self = shift;
  my $opt = shift;
  my $strategy = $opt->{strategy};

  croak("Need strategy") if not defined $strategy;
  my @strategies = grep /\b\Q$strategy\E$/, $self->strategies;
  if (@strategies == 0) {
    croak("Could not find specified strategy '$strategy'. Available strategies: " . join(', ', @strategies));
  }
  elsif (@strategies > 1) {
    croak("Found multiple matching strategy for '$strategy': " . join(', ', @strategies));
  }
  $strategy = shift @strategies;
  $self->{strategy} = $strategy->new(%$opt, index => $self);
}

sub _init_storage {
  my $self = shift;
  my $opt = shift;
  my $storage = $opt->{storage};

  croak("Need storage") if not defined $storage;
  my @storage_backends = grep /\b\Q$storage\E$/, $self->storage_backends;
  if (@storage_backends == 0) {
    croak("Could not find specified storage backends '$storage'");
  }
  elsif (@storage_backends > 1) {
    croak("Found multiple matching storage backends for '$storage': " . join(', ', @storage_backends));
  }
  $storage = shift @storage_backends;
  $self->{storage} = $storage->new(index => $self, opt => $opt);
}

sub insert {
  my $self = shift;
  return $self->{strategy}->insert(@_);
}

sub get_items_in_rect {
  my ($self, @rect) = @_;
  my $strategy = $self->strategy;
  return $strategy->filter_items_in_rect(@rect, $strategy->find_nodes_for(@rect));
}

1;
__END__

=head1 NAME

Algorithm::SpatialIndex - Flexible 2D/3D spacial indexing

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    strategy    => 'QuadTree', # or others
    storage     => 'Memory', # or others
    limit_x_low => -100,
    limit_x_up  => 100,
    limit_y_low => -100,
    limit_y_up  => 100,
    bucket_size => 100,
    max_depth   => 20,
  );
  
  # fill (many times with different values):
  $idx->insert($id, $x, $y);
  
  # query
  my @items = $idx->get_items_in_rect($xlow, $ylow, $xup, $yup);
  # @items now contains 0 or more array refs [$id, $x, $y]

=head1 DESCRIPTION

A generic implementation of spatial (2D and 3D) indexes with support for
pluggable algorithms (henceforth: I<strategies>) and storage backends.

Right now, this package ships with a quad tree implementation
(L<Algorithm::SpatialIndex::Strategy::QuadTree>), an experimental
oct tree (3D indexing, L<Algorithm::SpatialIndex::Strategy::OctTree>),
an in-memory storage backend (L<Algorithm::SpatialIndex::Storage::Memory>),
and an experimental database-backed storage
(L<Algorithm::SpatialIndex::Storage::DBI>),

B<NOTE: This is an experimental release. There must be bugs.>

The functionality is split between pluggable storage backends
(see L<Algorithm::SpatialIndex::Storage>) and I<strategies>
(see L<Algorithm::SpatialIndex::Strategy>, the latter of which
implement the actual indexing algorithm, usually some form of tree.

For the basic quad tree (L<Algorithm::SpatialIndex::Strategy::QuadTree>)
and oct tree strategies, the tree is built from
L<Algorithm::SpatialIndex::Node>s. For each leaf node of the tree,
the storage contains a I<bucket> (L<Algorithm::SpatialIndex::Bucket>).
The buckets are basically dumb, linear complexity storage for 
items. Each item is simply an array reference containing an
id followed by two or more coordinates. The dimensionality
depends on the strategy. For example,
quad trees are two-dimensional, oct trees three-dimensional.

=head2 new

Creates a new spatial index. Requires the following parameters:

=over 2

=item strategy

The strategy to use. This is the part of the strategy class name after a leading
C<Algorithm::SpatialIndex::Strategy::>.

=item storage

The storage backend to use. This is the part of the storage class name after a leading
C<Algorithm::SpatialIndex::Storage::>.

=back

The following parameters are optional:

=over 2

=item limit_x_low limit_x_up limit_y_low limit_y_up limit_z_low limit_z_up

The upper/lower limits of the x/y dimensions of the index. Defaults to
C<[-100, 100]> for both dimensions.

If the chosen strategy is suitable for 3D indexing, C<limit_z_low>
and C<limit_z_up> do the obvious.

=item bucket_size

The number of items to store in a single leaf node (bucket). If this
number is exceeded by an insertion, the node is split up according
to the chosen strategy.

C<bucket_size> defaults to 100. See also C<max_depth> below.

=item max_depth

The maximum depth of the underlying tree. There can be a collision
of limiting the bucket size with limiting the maximum depth of the
tree. If that is the case, the maximum depth takes precedence over
limiting the bucket size.

C<max_depth> defaults to 20.

=head2 insert

Insert a new item into the index. Takes the unique
item id, an x-, and a y coordinate as arguments.

For three-dimensional spatial indexes such as an oct tree,
you must pass three coordinates.

=head2 bucket_class

The class name of the bucket implementation to use for
the given tree. Defaults to using C<Algorithm::SpatialIndex::Bucket>.
May be either a fully qualified class name or just the
fourth level of the namespace, implicitly prefixed
by C<Algorithm::SpatialIndex::Bucket::>.

All storage engines and strategies must
use the C<bucket_class> accessor of the storage engines
when constructing new buckets to remain pluggable:

  $storage->bucket_class->new(...)

=head2 get_items_in_rect

Given the coordinates of two points that define a rectangle
(or a cuboid in 3D),
this method finds all items within that rectangle (or cuboid).

Returns a list of array references each of which
contains the id and coordinates of a single item.

Usage for 2D:

  $idx->get_items_in_rect($x1, $y1, $x2, $y2);

Usage for 3D:

  $idx->get_items_in_rect($x1, $y1, $z1, $x2, $y2, $z2);

If the chosen bucket implementation exposes a method of the
name C<items_in_rect>, it will be called instead of
manually filtering the items returned from
C<$bucket-E<gt>items()>. This is intended as an optimization.
If you're just going to implement an O(n) scan on your bucket,
don't bother.

=head1 SEE ALSO

L<Algorithm::SpatialIndex::Strategy::MedianQuadTree>

L<Algorithm::QuadTree>

L<Tree::M>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
