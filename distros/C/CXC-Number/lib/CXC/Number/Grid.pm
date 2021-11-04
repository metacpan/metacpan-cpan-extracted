package CXC::Number::Grid;

# ABSTRACT: A class representing a one dimensional numeric grid

use feature ':5.26';
use Carp;

use POSIX ();

use Tree::Range::RB;

use Types::Standard
  qw( ArrayRef InstanceOf Optional Enum Dict Bool );
use Type::Params qw( compile );
use Ref::Util qw[ is_plain_hashref is_blessed_ref ];

use CXC::Number::Grid::Types -types;
use CXC::Number::Grid::Failure
  qw( parameter_interface parameter_constraint internal );

use Safe::Isa;

use Moo;

use experimental 'signatures';
use experimental 'refaliasing';

our $VERSION = '0.06';

use Exporter::Shiny qw( join_n overlay_n );

use namespace::clean;

use MooX::StrictConstructor;

use overload '+' => \&_merge, fallback => 1, bool => sub { 1 };

my $DEBUG = $ENV{ __PACKAGE__ . "_DEBUG" } // 0;

sub _convert ( $self, $bignum ) {
    require Ref::Util;

    return Ref::Util::is_plain_arrayref( $bignum )
      ? [ map { $_->numify } $bignum->@* ]
      : $bignum->numify;
}









has oob => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);







has _raw_edges => (
    is       => 'lazy',
    init_arg => 'edges',
    isa      => BinEdges,
    required => 1,
    coerce   => 1,
);







has _include => (
    is       => 'lazy',
    init_arg => 'include',
    isa      => ArrayRef [ Enum [ 0, 1 ] ],
    builder  => sub { [ ( 1 ) x $_[0]->nbins ] },
);






























sub BUILD ( $self, $ ) {

    parameter_interface->throw( "the number of bins ( @{[ $self->nbins ]} ) "
          . "and includes ( @{[ scalar $self->_include->@* ]} ) must be equal" )
      if $self->nbins != $self->_include->@*;
}














sub bin_edges ( $self ) {
    my @edges;
    push @edges, Math::BigFloat->new( POSIX::DBL_MAX) if $self->oob;
    push @edges, $self->_raw_edges->@*;
    unshift @edges, Math::BigFloat->new( - POSIX::DBL_MAX)
      if $self->oob;

    return $self->_convert( \@edges );
}












sub lb ($self) {
    return $self->_convert( [ $self->_raw_edges->@[ 0 .. $self->nbins - 1 ] ] );
}











sub ub ($self) {
    return $self->_convert( [ $self->_raw_edges->@[ 1 .. $self->nbins ] ] );
}










sub edges ($self) {
    return $self->_convert( $self->_raw_edges );
}









sub nedges ($self) {
    scalar $self->_raw_edges->@*;
}









sub nbins ($self) {
    $self->nedges - 1;
}










sub include ($self) {
    return [ $self->_include->@* ];
}










sub spacing ($self) {
    my $edges = $self->_raw_edges;
    return $self->_convert( [ map { ( $edges->[$_] - $edges->[ $_ - 1 ] ) } 1 .. $self->nbins ] );
}









sub min ($self) {
    return $self->_convert( $self->_raw_edges->[0] );
}









sub max ($self) {
    return $self->_convert( $self->_raw_edges->[-1] );
}









sub split ($self) {

    my @grids;

    my $last = 0;

    my $include = $self->_include;

    foreach my $idx ( 0..($include->@*-1) ) {

        if ( !$include->[$idx] ) {

            # skip over consecutive excludes
            ++$last, next if $last == $idx;


            # there's one more edge than include values
            my @edges   = $self->_raw_edges->@[ $last .. $idx ];
            my @include = $self->_include->@[ $last .. $idx - 1 ];

            push @grids,
              __PACKAGE__->new( {
                  edges   => \@edges,
                  include => \@include,
                  oob     => $self->oob
              } );

            $last = $idx + 1;
        }
    }

    if ( $last < $self->_include->@* ) {
        my $nbins = $self->nbins;
        push @grids,
          __PACKAGE__->new( {
              edges   => [ $self->_raw_edges->@[ $last .. $nbins ] ],
              include => [ $self->_include->@[ $last .. $nbins - 1 ] ],
              oob     => $self->oob
          } );
    }

    return @grids;
}























sub overlay ( $self, @args ) {
    return overlay_n( $self, @args );
}


package
  CXC::Number::Grid::Range {
    use Moo;
    use experimental 'signatures';
    use experimental 'declared_refs';
    use experimental 'refaliasing';

    use overload fallback => 0,
      bool => sub { 1 },
      '""' => \&to_string,
      '.'  => \&concatenate;

    has layer   => ( is => 'ro' );
    has include => ( is => 'ro' );
    has lb      => ( is => 'ro' );
    has ub      => ( is => 'ro' );

    around BUILDARGS => sub ( $orig, $class, @args ) {

        my \%args = ref $args[0] ? $args[0] : {@args};

        @args{ 'layer', 'include' } = delete( $args{value} )->@*
          if defined $args{value };

        return $class->$orig( \%args );
    };

    sub to_string ( $self, $=, $= ) {
        my $ub = $self->ub // 'undef';
        my $lb = $self->lb // 'undef';
        my $layer = $self->layer // 'undef';
        my $include = $self->include // 'undef';
        "( $lb, $ub ) => { layer => $layer, include => $include }";
    }

    sub concatenate ( $self, $other, $swap ) {
        my $str = $self->to_string;
        return $swap ? $other . $str : $str . $other;
    }

    sub value ( $self ) {
        return [ $self->layer, $self->include ];
    }

}

sub _dump_tree ( $tree ) {
    my $ic = $tree->range_iter_closure;
    say "------------";
    while ( my ( $v, $lb, $ub ) = $ic->() ) {
        $v = defined $v ? "[ @{[ join( ', ', $v->@*) ]} ]" : 'undef';
        $lb //= 'undef';
        $ub //= 'undef';
        say "( $lb, $ub )\t=> $v";
    }
    say "------------";
}

sub _reset_layer ( $tree ) {
    my $ic = $tree->range_iter_closure;
    while ( my ( $v, $lb, $ub ) = $ic->() ) {
        defined $v and $v->[0] = 1;
    }
}

















































































sub overlay_n {

    state $check = compile(
        ArrayRef [ InstanceOf [ ( __PACKAGE__ ) ] ],
        Optional [
            Dict [
                snap_dist => Optional [BigPositiveOrZeroNum],
                snap_to   => Optional [ Enum [ 'underlay', 'overlay' ] ],
            ],
        ],
    );

    my @dict = ( @_ && is_plain_hashref( $_[-1] ) ? pop @_ : () );

    my ( $grids, $opt ) = $check->( \@_, @dict, );
    $opt->{snap_to}   //= 'underlay';
    $opt->{snap_dist} //= Math::BigFloat->bzero;

    my $tr = Tree::Range::RB->new( { cmp => sub { $_[0] <=> $_[1] } } );

    my $gi = 0;
    for my $grid ( $grids->@* ) {
        ++$gi;
        my $edges  = $grid->_raw_edges;
        my $include = $grid->include;
        $tr->range_set(
            $edges->[$_],
            $edges->[ $_ + 1 ],
            [ $gi, $include->[$_] ] ) for 0 .. ( $grid->nbins - 1 );

        # snap bin edges if they are from different grids and are too close.
        # do this in the loop so that there are only two grids at a time
        if ( $gi > 1 ) {
            _snap_to( $tr, $opt->{snap_to}, $opt->{snap_dist} );
            _reset_layer( $tr );
        }
    }


    my @edges;
    my @include;
    my $ic = $tr->range_iter_closure;

    my ( $v, $lower, $upper ) = $ic->();
    push @edges, $upper;

    while ( ( $v, $lower, $upper ) = $ic->() ) {
        if ( defined $upper ) {
            push @edges, $upper;
            push @include, ( $v // [0] )->[-1];
        }
    }

    return __PACKAGE__->new( edges => \@edges, include => \@include );
}

sub _snap_to ( $tr, $snap_to, $snap_dist ) {

    return if $snap_dist == 0;

    # Tree::Range doesn't represent a range as a node with the ability
    # to visit a predecessor.  It essentially only allows one way
    # tree traversal, so we need to traverse it forwards to handle
    # snapping to the right, and backwards to handle snapping to the left.
    _merge_bins( $tr, $snap_dist, $snap_to, $_ ) for qw( right left );
}

sub _merge_bins ( $tr, $snap_dist, $snap_to, $scan_direction ) {

    defined( my $scan_reversed = { right => 0, left => 1 }->{$scan_direction} )
      // die( "illegal scan direction: '$scan_direction'" );

    my sub iter ( $key=undef ) {
        my $iter = $tr->range_iter_closure( $key, $scan_reversed );
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
                # $tr->range_set( $prev->lb, $current->ub, $current->value );
                # but there's no way to get $prev from Tree::Range.
                #
                # This code depends upon Tree::Range storing [ $lb, $value ]
                # in each node, so deleting a node extends the previous
                # range.
                $tr->delete( $current->lb );
                $iter = iter( $current->lb );
            },
            left => sub {
                $tr->range_set( $next->lb, $current->ub, $next->value );
                $iter = iter( $current->ub );
            }
        },
        underlay => {
            right => sub {
                $tr->range_set( $current->lb, $next->ub, $next->value );
                $iter = iter( $current->lb );

            },
            left => sub {
                $tr->range_set( $next->lb, $current->ub, $next->value );
                $iter = iter( $current->ub );
            },
        },
    );

    my $snap = $SnapTo{$snap_to}{$scan_direction};

    while ( defined( $next = next_range() ) ) {

        if ( abs( $current->ub - $current->lb ) <= $snap_dist
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




























































































































sub join_n {

# these are called as $sub->( \@edges, \@include, \@right_edges, \@right_include );
# @edges and @include are mutable and always contain the left grid

    state %dispatch = (
        'shift-right' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            my $delta = $redges->[0] - $edges->[-1];
            $_ += $delta for $edges->@*;
            pop @$edges;
            push @$edges,  $redges->@*;
            push @$include, $rinclude->@*;
        },

        'shift-left' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            my $delta = $redges->[0] - $edges->[-1];
            my $left  = pop @$edges;
            my $idx   = @$edges;
            push @$edges, map { $_ - $delta } $redges->@*;
            $edges->[$idx] = $left;

            push @$include, $rinclude->@*;
        },

        'snap-right' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            pop @$edges;
            push @$edges,  $redges->@*;
            push @$include, $rinclude->@*;
        },

        'snap-left' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            my $left = pop @$edges;
            my $idx  = @$edges;

            push @$edges, $redges->@*;
            $edges->[$idx] = $left;
            push @$include, $rinclude->@*;
        },

        'snap-both' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            my $middle = ( $redges->[0] + $edges->[-1] ) / 2;

            pop @$edges;
            my $idx = @$edges;
            push @$edges, $redges->@*;
            $edges->[$idx] = $middle;

            push @$include, $rinclude->@*;
        },

        'include' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            # just in case grids actually abut
            if ( $edges->[-1] == $redges->[0] ) {

                pop @$edges;
                push @$edges,  $redges->@*;
                push @$include, $rinclude->@*;
            }
            elsif ( $edges->[-1] < $redges->[0] ) {
                push @$edges, $redges->@*;
                push @$include, 1, $rinclude->@*;
            }
            else {
                parameter_constraint->throw(
                    "add-bin-include cannot handle overlapping grids" );
            }
        },

        'exclude' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            # just in case grids actually abut
            if ( $edges->[-1] == $redges->[0] ) {

                pop @$edges;
                push @$edges,  $redges->@*;
                push @$include, $rinclude->@*;
            }
            elsif ( $edges->[-1] < $redges->[0] ) {
                push @$edges, $redges->@*;
                push @$include, 0, $rinclude->@*;
            }
            else {
                parameter_constraint->throw(
                    "add-bin-exclude cannot handle overlapping grids" );
            }
        },

    );


    state $check = compile(
        ArrayRef [ InstanceOf [ ( __PACKAGE__ ) ] ],
        Optional [
            Dict [
                gap => Enum [ qw(
                      shift-right
                      shift-left
                      snap-right
                      snap-left
                      snap-both
                      include
                      exclude
                      )
                ],
            ],
        ],
    );

    my @dict = ( @_ && is_plain_hashref( $_[-1] ) ? pop @_ : () );

    my ( $grids, $opts ) = $check->( \@_, @dict, );

    $opts->{gap} //= 'include';

    parameter_interface->throw( "join_n: no grids supplied" )
      unless $grids->@*;

    # sort grids
    my @grid_idx = sort { $grids->[$a]->min <=> $grids->[$b]->min }
      0 .. ( $grids->@* - 1 );

    my ( $left, @rest ) = @grid_idx;
    my $gl = $grids->[$left];

    my @edges  = $gl->_raw_edges->@*;
    my @include = $gl->_include->@*;

    my $gr;

    for my $right ( @rest ) {

        $gr = $grids->[$right];

        parameter_constraint->throw(
            "grid[$right] overlaps grid[$left] by more than one bin" )
          unless $gl->_raw_edges->[-2] < $gr->_raw_edges->[0]
          && $gl->_raw_edges->[-1] < $gr->_raw_edges->[1];

        my $join = $dispatch{ $opts->{gap} }
          // internal->throw( "unexpected dispatch key: $opts->{gap}" );

        eval {
            $join->( \@edges, \@include, $gr->_raw_edges, $gr->_include );
            1;
        } or do {
            my $error = $@;
            if ( !is_blessed_ref $error ) {
                $error = "grid[$right]: $error";
            }
            else {
                $error->$_call_if_can( msg => "grid[$right]: " . $error->msg );
            }

            die $error;
        };
    }
    continue {
        $left = $right;
        $gl   = $gr;
    }

    return __PACKAGE__->new( edges => \@edges, include => \@include );
}


















sub bignum ($self) {
    require Moo::Role;
    return Moo::Role->apply_roles_to_object(
                                            __PACKAGE__->new( edges => $self->_raw_edges ),
                                            __PACKAGE__ . '::Role::BigNum',
                                           );
}
















sub pdl ($self) {
    require Moo::Role;
    return Moo::Role->apply_roles_to_object(
                                            __PACKAGE__->new( edges => $self->_raw_edges ),
                                            __PACKAGE__ . '::Role::PDL',
                                           );
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory overlayed nbins nedges
oob ub unobscured Extrema bignum pdl

=head1 NAME

CXC::Number::Grid - A class representing a one dimensional numeric grid

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  $grid1 = CXC::Number::Grid->new( edges => [ 1, 2, 3 ] );
  $grid2 = CXC::Number::Grid->new( edges => [ 4, 5, 6 ] );

  $gridj = $grid1->join( $grid2 );

=head1 DESCRIPTION

C<CXC::Number::Grid> provides an abstraction of a one dimensional
grid.  A grid is composed of contiguous bins, each of which has a flag
indicating whether or not it should be included in a process (where
I<process> is defined by the user of the grid).

This class provides facilities to I<join> grids (e.g. butt them
together) and I<overlay> grids, with a number of approaches to
handle the consequences of inevitable numeric imprecision.

Underneath the grid is stored as L<Math::BigFloat> objects.

=head1 CONSTRUCTOR

=head2 new

  $grid = CXC::Number::Grid->new( \%args );

The constructor takes the following arguments:

=over

=item C<edges> => I<array of numbers or Math::BigFloat objects>

The bin edges in the grid. Will be converted to L<Math::BigFloat> objects if they're not already.
These must be in ascending order.

=item C<include> => I<array of Flags>

An array of flags (C<0>, C<1>), one per I<bin> (not one per edge!),
indicating whether the bin should be included when binning or not.

=item C<oob> I<Boolean>

If true, C<< L</bin_edges> >> will extend the grid by one bin at each end.
The new lower bound is C<-POSIX::DBL_MAX> and the new upper bounds
will be C<POSIX::DBL_MAX>.  This allows out-of-bounds data to be accumulated
at the front and back of the grid.

=back

=head1 ATTRIBUTES

=head2 oob

A boolean, which, if true, indicates that extra bins are added to
either end of the grid which catch values outside of the range of the
grid.

=head2 edges

An array of ascending numbers which represent the edges of the bins in the grid.

=head2 include

An array of flags (C<0>, C<1>), one per bin, indicating whether the bin should be included when binning or not.

=head1 METHODS

=head2 bin_edges

  $bin_edges = $grid->bin_edges;

Return the bin edges which should be used for binning as an array of
Perl numbers.  This differs from C<< L</edges> >> in that this
includes the extra bins required to collect out-of-bounds values if
the C<< L</oob> >> parameter is true.  Extrema edges are set to
C<-POSIX::DBL_MAX> and C<POSIX::DBL_MAX>.

=head2 lb

  $lb = $grid->lb;

Returns a reference to an array of Perl numbers which contains the
lower bound values for the bins in the grid.  This does I<not> return
out-of-bounds bin values.

=head2 ub

  $ub = $grid->ub;

Returns a reference to an array of Perl numbers which contains the
upper bound values for the bins in the grid.  This does I<not> return
out-of-bounds bin values.

=head2 edges

  $edges = $grid->edges;

Returns a reference to an array of Perl numbers which contains the edge values
for the bins in the grid.

=head2 nedges

  $nedges = $grid->nedges;

The number of bin edges.

=head2 nbins

  $nbins = $grid->nbins;

The number of bins.

=head2 include

  $include = $grid->include;

Returns a reference to an array of flags C<0>, C<1>, indicating whether a bin
should be included in a I<process>.

=head2 spacing

  $spacing = $grid->spacing;

Returns a reference to an array of Perl numbers which contains the widths of each bin
in the grid.

=head2 min

  $min = $grid->min;

Returns the minimum bound of the grid as a Perl number.

=head2 max

  $max = $grid->max;

Returns the maximum bound of the grid as a Perl number.

=head2 split

  @grids = $grid->split;

Splits a grid on bins with an include value of C<0>.

=head2 join

  $grid = $grid1->join( $grid2, $grid3, ..., ?\%options );

Join two grids together. This is akin to a I<butt> joint, with control
over how to handle any gap between the grids.

See C<< L</join_n> >> for a description of the options.

=head2 overlay

  $grid = $grid1->overlay( $grid2, ..., $gridn, ?\%options );

Overlay one or more grids on top of C<$grid1> and return a new grid.

See C<< L</overlay_n> >> for a description of the options.

=head2 bignum

  $bin_edges = $grid->bignum->bin_edges;

Returns an object which returns copies of the internal
L<Math::BigFloat> objects for the following methods

  edges     -> Array[Math::BigFloat]
  bin_edges -> Array[Math::BigFloat]
  spacing   -> Array[Math::BigFloat]
  lb        -> Array[Math::BigFloat]
  ub        -> Array[Math::BigFloat]
  min       -> Math::BigFloat
  max       -> Math::BigFloat

=head2 pdl

  $bin_edges = $grid->pdl->bin_edges;

Returns an object which returns piddles for the following methods

  edges     -> piddle
  bin_edges -> piddle
  spacing   -> piddle
  lb        -> piddle
  ub        -> piddle

=head1 SUBROUTINES

=head2 overlay_n

  $grid = CXC::Number::Grid::overlay_n( $grid1, $grid2, ... $gridN, ?\%options );

Overlay each successive grid on the overlay of the previous sequence of grids.
The process essentially excises the range in the underlying grid covered by the
overlying grid and inserts the overlying grid in that place.  For example, if

  $overlay = overlay_n( $grid1, $grid2 );

with

 $grid1:
 :     +-------------------------------------------------+
 :     |    |    |    |    |    |    |    |    |    |    |
 :     +-------------------------------------------------+
 $grid2:
 :            +--------------------------------+
 :            |          |         |           |
 :            +--------------------------------+
 $overlay:
 :     +-------------------------------------------------+
 :     |    | |          |         |           |    |    |
 :     +-------------------------------------------------+

The C<%options> hash is optional; the following options are available:

=over

=item C<snap_dist> => I<float>

If the minimum or maximum edge of an overlying grid is closer than
this number to the nearest unobscured edge in the underlying grid,
snap the grid edges according to the value of L<snap_to>.

The default value is C<0>, which turns off snapping.

=item C<snap_to> => C<underlay> | C<overlay>

This indicates how to treat bin edges when C<< L</snap_dist> >> is not zero.
From the above example of the overlay of two grids:

     0    1 2          3         4           5    6    7
     +-------------------------------------------------+
     |    | |          |         |           |    |    |
     +-------------------------------------------------+
     1    1 2          2         2           2    1    1

The upper numbers are the edge indices and the lower indicate the grid
the edge came from.

Note how close edges I<1> and I<2> are.  Imagine that they are
actually supposed to be the same, but numerical imprecision is at
play.

Setting C<snap_to> to C<underlay> will adjust edge I<2> (which
originates from C<$grid2>, the overlying grid) so that it is equal to
edge I<1> (from C<$grid1>, the underlying grid).

     0    1            2         3           4    5    6
     +-------------------------------------------------+
     |    |            |         |           |    |    |
     +-------------------------------------------------+
     1    1            2         2           2    1    1

Conversely, setting C<snap_to> to C<overlay> will adjust edge I<1>
(originating from C<$grid1>, the underlying grid) so that it is equal
to edge I<2> (from C<$grid2> the overlying grid).

     0      1          2         3           4    5    6
     +-------------------------------------------------+
     |      |          |         |           |    |    |
     +-------------------------------------------------+
     1      2          2         2           2    1    1

=back

=head2 join_n

  $grid = CXC::Number::Grid::join_n( $grid1, $grid2, ..., $gridN, ?\%options );

Join one or more grids. This is akin to a I<butt> joint, with control
over how to handle any gap between the grids.

While normally grids should not overlap, up to one overlapping bin is
allowed in order to accommodate numerical imprecision.  The C<< L</gap> >>
option determines how to handle overlaps or gap.

The C<%options> hash is optional; the following options are available:

=over

=item gap =>  I<directive>

What to do if the two grids do not exactly touch. The default is C<include>.

Available directives are:

=over

=item C<shift-right>

Translate the left grid until its maximum edge coincides with the right grid's minimum edge.

 Before:
 :  +-----------------------+ +-----------------------+
 :  |  |  |  |  |  |  |  |  | |  |  |  |  |  |  |  |  |
 :  +-----------------------+ +-----------------------+
 After:
 :    +-----------------------+-----------------------+
 :    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
 :    +-----------------------+-----------------------+

=item C<shift-left>

Translate the right grid until its minimum edge coincides with the let grid's maximum edge.

 Before:
 :  +-----------------------+ +-----------------------+
 :  |  |  |  |  |  |  |  |  | |  |  |  |  |  |  |  |  |
 :  +-----------------------+ +-----------------------+
 After:
 :  +-----------------------+-----------------------+
 :  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
 :  +-----------------------+-----------------------+

=item C<snap-right>

Set the left grid's maximum edge to the right grid's minimum edge.

 Before:
 :  +-----------------------+ +-----------------------+
 :  |  |  |  |  |  |  |  |  | |  |  |  |  |  |  |  |  |
 :  +-----------------------+ +-----------------------+
 After:
 :  +-------------------------------------------------+
 :  |  |  |  |  |  |  |  |    |  |  |  |  |  |  |  |  |
 :  +-------------------------------------------------+

=item C<snap-left>

Set the right grid's minimum edge to the left grid's maximum edge.

 Before:
 :  +-----------------------+ +-----------------------+
 :  |  |  |  |  |  |  |  |  | |  |  |  |  |  |  |  |  |
 :  +-----------------------+ +-----------------------+
 After:
 :  +-------------------------------------------------+
 :  |  |  |  |  |  |  |  |  |    |  |  |  |  |  |  |  |
 :  +-------------------------------------------------+

=item C<snap-both>

Set both the right grid's minimum edge and the left grid's maximum edge
to the average of the two.

 Before:
 :  +-----------------------+ +-----------------------+
 :  |  |  |  |  |  |  |  |  | |  |  |  |  |  |  |  |  |
 :  +-----------------------+ +-----------------------+
 After:
 :  +-------------------------------------------------+
 :  |  |  |  |  |  |  |  |   |   |  |  |  |  |  |  |  |
 :  +-------------------------------------------------+

=item C<include>

Add a new bin

 Before:
 :  +-----------------------+ +-----------------------+
 :  |  |  |  |  |  |  |  |  | |  |  |  |  |  |  |  |  |
 :  +-----------------------+ +-----------------------+
 After:
 :  +-------------------------------------------------+
 :  |  |  |  |  |  |  |  |  | |  |  |  |  |  |  |  |  |
 :  +-------------------------------------------------+

=back

=item C<exclude>

Add a new bin, and mark it as being excluded

 Before:
 :  +-----------------------+ +-----------------------+
 :  |  |  |  |  |  |  |  |  | |  |  |  |  |  |  |  |  |
 :  +-----------------------+ +-----------------------+
 After:
 :  +-------------------------------------------------+
 :  |  |  |  |  |  |  |  |  |X|  |  |  |  |  |  |  |  |
 :  +-------------------------------------------------+

=back

=for Pod::Coverage BUILD

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Number> or by email
to L<bug-cxc-number@rt.cpan.org|mailto:bug-cxc-number@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Number|CXC::Number>

=item *

L<CXC::Number::Sequence|CXC::Number::Sequence>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
