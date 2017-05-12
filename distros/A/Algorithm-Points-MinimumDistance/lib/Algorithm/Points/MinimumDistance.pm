package Algorithm::Points::MinimumDistance;
use strict;
use vars qw( $VERSION );
$VERSION = '0.01';

=head1 NAME

Algorithm::Points::MinimumDistance - Works out the distance from each point to its nearest neighbour.  Kinda.

=head1 DESCRIPTION

Given a set of points in N-dimensional Euclidean space, works out for
each point the distance to its nearest neighbour (unless its nearest
neighbour isn't very close).  The distance metric is a method;
subclass and override it for non-Euclidean space.

=head1 SYNOPSIS

  use Algorithm::Points::MinimumDistance;

  my @points = ( [1, 4], [3, 1], [5, 7] );
  my $dists = Algorithm::Points::MinimumDistance->new( points => \@points );

  foreach my $point (@points) {
      print "($point->[0], $point->[1]: Nearest neighbour distance is "
          . $dists->distance( point => $point ) . "\n";
  }

  print "Smallest distance between any two points is "
      . $dists->min_distance . "\n";

=head1 METHODS

=over 4

=item B<new>

  my @points = ( [1, 4], [3, 1], [5, 7] );
  my $dists = Algorithm::Points::MinimumDistance->new( points  => \@points,
                                                       boxsize => 2 );

C<points> should be an arrayref containing every point in your set.
The representation of a point is as an N-element arrayref where N is
the number of dimensions in which we are working.  There is no check
that all of your points have the right dimension.  Whatever dimension
the first point has is assumed to be the dimension of the space.  So
get it right.

C<boxsize> defaults to 20.

=cut

sub new {
    my ($class, %args) = @_;
    my @points = @{ $args{points} };
    my $dim = scalar @{ $points[0] };
    my $boxsize = $args{boxsize} || 20;

    # Precomputation for working out all boxes adjacent to a given box
    # (a point will be in all regions centred on its box or the
    # adjacent ones).
    # To find an adjacent box, vector-add one of these entries to it,
    # eg [1, 1] + [2, 0] - with a boxsize of 2, [3, 1] is adjacent to [1, 1].
    my @offsets = ( [ -$boxsize ], [ 0 ] , [ $boxsize ] );
    foreach (2..$dim) {
        @offsets = map { [ @$_, -$boxsize ], [ @$_, 0 ], [ @$_, $boxsize] }
                       @offsets;
    }

    my $self = { dimensions => $dim,
                 points     => \@points,
                 boxsize    => $boxsize,
                 offsets    => \@offsets,
                 regions    => { },
                 distances  => { }
	       };
    bless $self, $class;
    $self->_work_out_distances;

    return $self;
}

=item B<box>

  my @box = $nn->box( [1, 2] );

Returns the identifier of the box that the point lives in.
A box is labelled by its "bottom left-hand" corner point.

=cut

sub box {
    my ($self, $point) = @_;
    my @box = map { $_ - ($_ % $self->{boxsize}) } @$point;
    return @box;
}

sub _offsets {
    my $self = shift;
    return @{ $self->{offsets} };
}

# Accessor for the region centred on the box $args{centre}.  Returns a ref to
# an array of the points that are in that region.
sub region {
    my ($self, %args) = @_;
    my @centre = @{$args{centre}};
    my $key = join(",", @centre);
    my $regions = $self->{regions};
    $regions->{$key} ||= [];
    return $regions->{$key};
}

# Shevek says: "This is where the CPU time goes, but, gentle reader,
# please note that the complexity is LINEAR in the number of
# points. This is shit.  It's also trivial, so do it in XS."
# Kake says: "I don't speak XS yet."

sub _hash {
    my ($self, $point) = @_;

    # Compute the box in which $point lives.
    my @home_box = $self->box($point);

    # $point lives in the region centred on this box, plus all surrounding
    # regions.  Push it into each of these regions.  A region is
    # identified by the box at its centre.
    foreach my $delta ( $self->_offsets ) {
        my @centre = map { $delta->[$_] + $home_box[$_] } (0..$#home_box);
        my $region = $self->region( centre => \@centre );
        push @$region, $point;
    }
}

sub _work_out_distances {
    my $self = shift;
    my $points = $self->{points};

    # Work out which points live in which regions.
    $self->_hash($_) foreach (@$points);

    # For each point, check its distance from every other point inside
    # the region centred on its home box.  All points outside this region
    # are at least a distance 'boxsize' away.
    foreach my $point (@$points) {
        my @box = $self->box($point);
        my $min;
        my $region = $self->region( centre => \@box );
        foreach my $neighbour (@$region) {
            next if $neighbour == $point;    # Reference equality
            my $d = $self->d($point, $neighbour);
            $min = $d if (!defined $min or $d < $min);
        }
        $min ||= $self->{boxsize};
        $self->_store_distance( point => $point, distance => $min );
    }
}

sub _store_distance {
    my ($self, %args) = @_;
    my ($point, $distance) = @args{ qw( point distance ) };
    my $key = join(",", @$point);
    $self->{distances}{$key} = $distance;
}

# Override this for a different metric.
sub d {
    my ($self, $point1, $point2) = @_;
    my $t = 0;
    foreach (0..$#$point1) {
        $t += ($point1->[$_] - $point2->[$_]) ** 2;
    }
    return sqrt($t);
}

=item B<distance>

  my $nn = Algorithm::Points::MinimumDistance->new( ... );
  my $nn_dist = $nn->distance( point => [1, 4] );

Returns the distance between the specified point and its nearest
neighbour.  The point should be one of your original set.  There is no
check that this is the case.  Note that if a point has no particularly
close neighbours, then C<boxsize> will be returned instead.

=cut

sub distance {
    my ($self, %args) = @_;
    my $point = $args{point};
    my $key = join(",", @$point);
    return $self->{distances}{$key};
}

=item B<min_distance>

  my $nn = Algorithm::Points::MinimumDistance->new( ... );
  my $nn_dist = $nn->min_distance;

Returns the minimum nearest-neighbour distance for all points in the set.
Or C<boxsize> if none of the points are close to each other.

=cut

sub min_distance {
    my $self = shift;
    my $dists = $self->{distances};
    my $min;
    foreach my $dist ( values %$dists ) {
        $min = $dist if (!defined $min or $dist < $min);
    }
    return $min;
}

=back

=head1 ALGORITHM

We use the hash as an approximate conservative metric to basically do
clipping of space. A box is one cell of the space defined by the grid
size. A region is a box and all the neighbouring boxes in all directions,
i.e. all the boxes b such that
  d(b, c) <= 1 in the d-infinity metric
Noting that d(b, c) is always an integer in this case.

  +-+-+-+-+-+
  | | | | | |
  +-+-+-+-+-+
  | |x|x|x| |
  +-+-+-+-+-+
  | |x|b|x| |
  +-+-+-+-+-+
  | |x|x|x| |
  +-+-+-+-+-+
  | | | | | |
  +-+-+-+-+-+ 

Now all points outside the region defined by the box b and the
neighbours x can not be within maximum radius $C of any point in box b.

So we reverse the stunt and shove any point in box b into the hash
lists for all boxes b and x so that when testing a point in any box,
we have a list of all points in that box and any neighbouring boxes
(the region).

=head1 AUTHOR

Algorithm by Shevek, modularisation by Kake Pugh (kake@earth.li).

=head1 COPYRIGHT

     Copyright (C) 2003 Kake Pugh.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 CREDITS

Shevek is utterly fab for telling me how to solve this problem.  Greg
McCarroll is also fab for telling me what to call the module.

=cut

1;
