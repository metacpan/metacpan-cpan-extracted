package CXC::Number::Grid::Tree;

# ABSTRACT: A Tree representing a Grid

use v5.28;
use strict;
use warnings;

our $VERSION = '0.13';

use parent 'Tree::Range::RB';

use experimental 'signatures';

my sub _key_compare { $_[0] <=> $_[1] }

sub _croak {
    require Carp;
    goto \&Carp::croak;
}










sub new ( $class, $options = {} ) {

    my %options = ( cmp => \&_key_compare, $options->%* );
    return $class->SUPER::new( \%options );
}









sub to_string ( $self ) {
    my $ic = $self->range_iter_closure;
    my @string;
    while ( my ( $v, $lb, $ub ) = $ic->() ) {
        $v
          = defined $v
          ? ref $v
              ? "[ @{[ join( ', ', $v->@*) ]} ]"
              : $v
          : 'undef';
        $lb //= 'undef';
        $ub //= 'undef';
        push @string, "( $lb, $ub )\t=> $v";
    }

    return join( "\n", @string );
}












sub to_array ( $self ) {
    my @arr;
    my $ic = $self->range_iter_closure;
    $ic->();    # discard lower bound
    while ( my ( $v, $lb, $ub ) = $ic->() ) {
        push @arr, [ $lb, $ub, $v ];
    }
    pop @arr;    # discard upper bound
    return \@arr;
}









sub from_array ( $, $ranges ) {
    my $tree = __PACKAGE__->new;
    $tree->range_set( $_->@* ) for $ranges->@*;
    return $tree;
}









sub from_grid ( $, $grid ) {
    my $tree = __PACKAGE__->new;

    my $edges   = $grid->_raw_edges;
    my $include = $grid->include;

    $tree->range_set( $edges->@[ $_, $_ + 1 ], $include->[$_] ) for 0 .. ( $grid->nbins - 1 );
    return $tree;
}









sub to_grid ( $self ) {

    my @edges;
    my @include;
    my $ic = $self->range_iter_closure;


    # this is the lower bound
    my ( $v, $lower, $upper ) = $ic->();
    push @edges, $upper;

    while ( ( $v, $lower, $upper ) = $ic->() ) {
        if ( defined $upper ) {
            push @edges,   $upper;
            push @include, ref $v ? $v->[-1] : $v // 0;
        }
    }
    require CXC::Number::Grid;
    return CXC::Number::Grid->new( edges => \@edges, include => \@include );
}


















































sub snap_overlaid ( $self, $layer, $snap_to, $snap_dist ) {    ## no critic(Subroutines::ProhibitManyArgs)

    return if $snap_dist == 0;

    # Tree::Range doesn't represent a range as a node with the ability
    # to visit a predecessor.  It essentially only allows one way
    # tree traversal, so we need to traverse it forwards to handle
    # snapping to the right, and backwards to handle snapping to the left.
    $self->_snap_overlaid_edges( $layer, $snap_to, $snap_dist, $_ ) for qw( right left );
}











sub _snap_overlaid_edges ( $self, $layer, $snap_to, $snap_dist, $scan_direction ) {    ## no critic(Subroutines::ProhibitManyArgs)

    require CXC::Number::Grid::Range;

    defined( my $scan_reversed = { right => 0, left => 1 }->{$scan_direction} )
      or _croak( "illegal scan direction: '$scan_direction'" );

    my sub iter ( $key = undef ) {
        my $iter = $self->range_iter_closure( $key, $scan_reversed );
        # first range goes from +-inf to real bound; remove
        $iter->() unless defined $key;
        return $iter;
    }

    my $iter = iter();

    my sub next_range {
        my @r = $iter->();
        return @r
          ? CXC::Number::Grid::Range->new( {
                value => $r[0],
                lb    => $r[1],
                ub    => $r[2],
            } )
          : undef;
    }

    my $current = next_range();
    my $next;

    my %SnapTo = (
        overlay => {
            right => sub {
                # would prefer
                # $self->range_set( $prev->lb, $current->ub, $current->value );
                # but there's no way to get $prev from Tree::Range.
                #
                # This code depends upon Tree::Range storing [ $lb, $value ]
                # in each node, so deleting a node extends the previous
                # range.
                $self->delete( $current->lb );
                $iter = iter( $current->lb );
            },
            left => sub {
                $self->range_set( $next->lb, $current->ub, $next->value );
                $iter = iter( $current->ub );
            },
        },
        underlay => {
            right => sub {
                $self->range_set( $current->lb, $next->ub, $next->value );
                $iter = iter( $current->lb );

            },
            left => sub {
                $self->range_set( $next->lb, $current->ub, $next->value );
                $iter = iter( $current->ub );
            },
        },
    );

    my $snap = $SnapTo{$snap_to}{$scan_direction}
      or _croak( "unknown layer to snap to: $snap_to" );

    while ( defined( $next = next_range() ) ) {

        if (   abs( $current->ub - $current->lb ) <= $snap_dist
            && $next->layer == $layer
            && $current->layer < $next->layer )
        {
            $snap->();
            # all of the $snap routines reset the iterator
            $current = next_range();
        }
        else {
            $current = $next;
        }
    }
}









sub clone ( $self ) {
    return __PACKAGE__->from_array( $self->to_array );
}

1;

#
# This file is part of CXC-Number
#
# This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory extrema overlaid

=head1 NAME

CXC::Number::Grid::Tree - A Tree representing a Grid

=head1 VERSION

version 0.13

=head1 DESCRIPTION

This is a subclass of L<Tree::Range> which is used to manipulate grids

=head1 CONSTRUCTORS

=head2 new

  $tree = CXC::Number::Grid::Tree->new( ?\%options )

Construct a new tree, using a default numerical key comparison
function.  All options recognized by L<Tree::Range::RB> are accepted.

=head2 from_array

  $tree = CXC::Number::Grid::Tree->from_array( \@array );

Construct a tree object from an array generated by L</to_array>.

=head2 from_grid

  $tree = CXC::Number::Grid::Tree->from_grid( $grid );

Construct a tree object from a L<CXC::Number::Grid> object.

=head1 METHODS

=head2 to_string

  $tree->to_string;

Return a string representation of the tree.

=head2 to_array

  \@array = $tree->to_array;

Return an arrayref with one element per bin. Each element is an
arrayref and contains the lower bound, upper bound, and value stored
in the tree for the bin bin.

=head2 to_grid

  $grid = $tree->to_grid;

Return a L<CXC::Number::Grid> object represented by the tree.

=head2 snap_overlaid

   $tree->snap_overlaid( $layer, $snap_to, $snap_dist ) {

Snap overlaid bins' edges.

B<Works in place!!>

This assumes that the Tree has been

=over

=item 1

loaded with ranges from two grids, one of which overlays the other; and

=item 2

that the range values are arrayrefs with the first value being the
layer id (larger number indicates the top grid); and

=item 3

that the top grid is contiguous (e.g. no holes through which the
lower grid is visible)

=back

In the general case, the minimum and maximum edges of the top grid
will intersect bins in the lower grid.  If the remnants of those bins
(e.g. the parts not covered by the top grid) are small enough (e.g,
smaller than C<$snap_dist> in width), then this routine will either:

=over

=item *

move the outer edge of the top grid to coincide with the remaining edge of the intersected lower bin
(C<$snap_to = 'underlay'>)

=item *

move the remaining edge of the intersected lower bin to coincide with the edge of the top grid.
(C<$snap_to = 'overlay'>)

=back

=head2 clone

  $clone = $tree->clone;

Clone a tree, performing a shallow copy of the values associated with each bin in the tree.

=head1 INTERNALS

=head2 Methods

=head3 _snap_overlaid_edges

  $self->_snap_overlaid_edges( $layer, $snap_to, $snap_dist, $scan_direction ) {

A helper for L</snap_to>.  This routine is run twice, with
C<$scan_direction> set to C<left> and C<right>, then to handle the
extrema of the overlaid grid.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-number@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-number

and may be cloned from

  https://gitlab.com/djerius/cxc-number.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Number|CXC::Number>

=item *

L<CXC::Number::Grid|CXC::Number::Grid>

=item *

L<CXC::Number::Grid::Range|CXC::Number::Grid::Range>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
