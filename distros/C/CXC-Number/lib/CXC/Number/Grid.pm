package CXC::Number::Grid;

# ABSTRACT: A class representing a one dimensional numeric grid

use v5.28;

use POSIX ();

use Types::Standard qw( ArrayRef Bool Dict Enum HashRef InstanceOf Optional Slurpy );
use Type::Params    qw( signature signature_for );
use Ref::Util       qw( is_plain_hashref is_blessed_ref );
use List::Util      qw( uniqnum );

use CXC::Number::Grid::Types -types;
use CXC::Number::Grid::Failure qw( parameter_interface parameter_constraint internal );

use CXC::Number::Grid::Tree;
use constant Tree => 'CXC::Number::Grid::Tree';

use Safe::Isa;

use Moo;

our $VERSION = '0.13';

use constant GridObject   => InstanceOf [ ( __PACKAGE__ ) ];
use constant IncludeArray => ArrayRef [ Enum [ 0, 1 ] ];

use experimental 'signatures';

use Exporter::Shiny qw( join_n overlay_n );

use namespace::clean;

use MooX::StrictConstructor;

use overload
  '!'      => \&_overload_not,
  '|'      => \&_overload_or,
  '&'      => \&_overload_and,
  fallback => 1,
  bool     => sub { 1 };

BEGIN { with 'MooX::Tag::TO_HASH' }    # so can see has

my sub _croak {
    require Carp;
    goto \&Carp::croak;
}

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
    to_hash => 1,
);







has _raw_edges => (
    is       => 'ro',
    init_arg => 'edges',
    isa      => BinEdges,
    required => 1,
    coerce   => 1,
    to_hash  => 'edges',
);







has _include => (
    is       => 'lazy',
    init_arg => 'include',
    isa      => IncludeArray,
    builder  => sub { [ ( 1 ) x $_[0]->nbins ] },
    to_hash  => 'include,if_exists',
);

















































my sub edges_from_bounds;

around BUILDARGS => sub ( $orig, $class, @args ) {

    my $args = $class->$orig( @args );

    _croak( 'specify either <edges> or <bounds> but not both' )
      if exists $args->{edges} && exists $args->{bounds};

    edges_from_bounds( $args )
      if exists $args->{bounds};

    return $args;

};

sub edges_from_bounds ( $args ) {

    my $bounds = BinBounds->assert_coerce( $args->{bounds} );
    my $includes;

    if ( exists $args->{include} ) {
        $includes = IncludeArray->assert_coerce( $args->{include} );
        _croak( 'number of <include> flags does not match number of bounds pairs passed via <bounds>' )
          unless ( $bounds->@* ) / 2 == $includes->@*;
    }

    my $n     = $bounds->@*;
    my $b_idx = 0;
    my $i_idx = 0;

    my @edges   = $bounds->@[ $b_idx++, $b_idx++ ];
    my @include = ( $includes->[ $i_idx++ ] // 1 );

    while ( $b_idx < $n ) {
        my ( $start, $end ) = $bounds->@[ $b_idx++, $b_idx++ ];
        if ( $edges[-1] != $start ) {
            push @edges,   $start;
            push @include, 0;
        }
        push @edges, $end;
        push @include, ( $includes->[ $i_idx++ ] // 1 );
    }

    delete $args->{bounds};
    $args->{edges}   = \@edges;
    $args->{include} = \@include;
}

sub BUILD ( $self, $ ) {

    parameter_interface->throw( "the number of bins ( @{[ $self->nbins ]} ) "
          . "and includes ( @{[ scalar $self->_include->@* ]} ) must be equal" )
      if $self->nbins != $self->_include->@*;
}














sub bin_edges ( $self ) {
    my @edges;
    push @edges, Math::BigFloat->new( POSIX::DBL_MAX ) if $self->oob;
    push @edges, $self->_raw_edges->@*;
    unshift @edges, Math::BigFloat->new( - POSIX::DBL_MAX )
      if $self->oob;

    return $self->_convert( \@edges );
}












sub lb ( $self ) {
    return $self->_convert( [ $self->_raw_edges->@[ 0 .. $self->nbins - 1 ] ] );
}











sub ub ( $self ) {
    return $self->_convert( [ $self->_raw_edges->@[ 1 .. $self->nbins ] ] );
}










sub edges ( $self ) {
    return $self->_convert( $self->_raw_edges );
}









sub nedges ( $self ) {
    scalar $self->_raw_edges->@*;
}









sub nbins ( $self ) {
    $self->nedges - 1;
}










sub include ( $self ) {
    return [ $self->_include->@* ];
}










sub spacing ( $self ) {
    my $edges = $self->_raw_edges;
    return $self->_convert( [ map { ( $edges->[$_] - $edges->[ $_ - 1 ] ) } 1 .. $self->nbins ] );
}









sub min ( $self ) {
    return $self->_convert( $self->_raw_edges->[0] );
}









sub max ( $self ) {
    return $self->_convert( $self->_raw_edges->[-1] );
}









sub split ( $self ) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)

    my @grids;

    my $last_idx = 0;

    my $include = $self->_include;

    foreach my $idx ( 0 .. ( $include->@* - 1 ) ) {

        if ( !$include->[$idx] ) {

            # skip over consecutive excludes
            if ( $last_idx == $idx ) {
                ++$last_idx;
                next;
            }

            # there's one more edge than include values
            my @edges   = $self->_raw_edges->@[ $last_idx .. $idx ];
            my @include = $self->_include->@[ $last_idx .. $idx - 1 ];

            push @grids,
              __PACKAGE__->new( {
                  edges   => \@edges,
                  include => \@include,
                  oob     => $self->oob,
              } );

            $last_idx = $idx + 1;
        }
    }

    if ( $last_idx < $self->_include->@* ) {
        my $nbins = $self->nbins;
        push @grids,
          __PACKAGE__->new( {
              edges   => [ $self->_raw_edges->@[ $last_idx .. $nbins ] ],
              include => [ $self->_include->@[ $last_idx .. $nbins - 1 ] ],
              oob     => $self->oob,
          } );
    }

    return @grids;
}























sub overlay ( $self, @args ) {
    return overlay_n( $self, @args );
}



















































































sub overlay_n {

    state $signature = signature(
        positional => [
            ArrayRef [GridObject],
            Optional [
                Dict [
                    snap_dist => Optional [BigPositiveOrZeroNum],
                    snap_to   => Optional [ Enum [ 'underlay', 'overlay' ] ],
                ],
            ],
        ],
    );

    my @dict = ( @_ && is_plain_hashref( $_[-1] ) ? pop @_ : () );

    my ( $grids, $opt ) = $signature->( \@_, @dict, );

    $opt->{snap_to}   //= 'underlay';
    $opt->{snap_dist} //= Math::BigFloat->bzero;

    my $tr = Tree->new;

    my $gi = 0;
    for my $grid ( $grids->@* ) {
        ++$gi;
        my $edges   = $grid->_raw_edges;
        my $include = $grid->include;
        $tr->range_set( $edges->[$_], $edges->[ $_ + 1 ], [ $gi, $include->[$_] ] )
          for 0 .. ( $grid->nbins - 1 );

        # snap bin edges if they are from different grids and are too close.
        # do this in the loop so that there are only two grids at a time
        $tr->snap_overlaid( $gi, $opt->{snap_to}, $opt->{snap_dist} )
          if $gi > 1;
    }

    return $tr->to_grid;
}





























































































































sub join_n {

    ## no critic(NamingConventions::ProhibitAmbiguousNames)

    # these are called as $sub->( \@edges, \@include, \@right_edges, \@right_include );
    # @edges and @include are mutable and always contain the left grid

    state %dispatch = (
        'shift-right' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            my $delta = $redges->[0] - $edges->[-1];
            $_ += $delta for $edges->@*;
            pop @$edges;
            push @$edges,   $redges->@*;
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
            push @$edges,   $redges->@*;
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
                push @$edges,   $redges->@*;
                push @$include, $rinclude->@*;
            }
            elsif ( $edges->[-1] < $redges->[0] ) {
                push @$edges, $redges->@*;
                push @$include, 1, $rinclude->@*;
            }
            else {
                parameter_constraint->throw( 'add-bin-include cannot handle overlapping grids' );
            }
        },

        'exclude' => sub {
            my ( $edges, $include, $redges, $rinclude ) = @_;

            # just in case grids actually abut
            if ( $edges->[-1] == $redges->[0] ) {

                pop @$edges;
                push @$edges,   $redges->@*;
                push @$include, $rinclude->@*;
            }
            elsif ( $edges->[-1] < $redges->[0] ) {
                push @$edges, $redges->@*;
                push @$include, 0, $rinclude->@*;
            }
            else {
                parameter_constraint->throw( 'add-bin-exclude cannot handle overlapping grids' );
            }
        },

    );


    state $check = signature(
        positional => [
            ArrayRef [GridObject],
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
                        ),
                    ],
                ],
            ],
        ],
    );

    my @dict = ( @_ && is_plain_hashref( $_[-1] ) ? pop @_ : () );

    my ( $grids, $opts ) = $check->( \@_, @dict, );

    $opts->{gap} //= 'include';

    parameter_interface->throw( 'join_n: no grids supplied' )
      unless $grids->@*;

    # sort grids
    my @grid_idx = sort { $grids->[$a]->min <=> $grids->[$b]->min } 0 .. ( $grids->@* - 1 );

    my ( $left, @rest ) = @grid_idx;
    my $gl = $grids->[$left];

    my @edges   = $gl->_raw_edges->@*;
    my @include = $gl->_include->@*;

    my $gr;

    for my $right ( @rest ) {

        $gr = $grids->[$right];

        ## no critic( ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions )
        parameter_constraint->throw( "grid[$right] overlaps grid[$left] by more than one bin" )
          unless $gl->_raw_edges->[-2] < $gr->_raw_edges->[0]
          && $gl->_raw_edges->[-1] < $gr->_raw_edges->[1];

        my $join = $dispatch{ $opts->{gap} } // internal->throw( "unexpected dispatch key: $opts->{gap}" );

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















sub not ( $self ) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)

    my $hash = $self->TO_HASH;
    $_ = $_ ? 0 : 1 for $hash->{include}->@*;
    return __PACKAGE__->new( $hash );
}

sub _overload_not ( $self, $, $ ) {
    return $self->not;
}













# need extra args if bitwise feature is on.
sub _overload_or ( $self, $other, $ =, $ =, $ = ) {
    $other->$_isa( __PACKAGE__ )
      or die( "can only perform the | operation between two ${ \__PACKAGE__ } objects " );
    return $self->or( $other );
}










sub or ( $self, @args ) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    return or_n( $self, @args );
}































signature_for or_n => ( positional => [ Slurpy [ ArrayRef [GridObject] ] ], );
sub or_n ( $grids ) {
    my $tr = Tree->new;

    my $gi = 0;

    # the code for and_n is easier to understand; rewrite this to use
    # that algorithm.
    for my $grid ( $grids->@* ) {
        ++$gi;
        my $edges   = $grid->_raw_edges;
        my $include = $grid->include;

        my @idx = 0 .. ( $grid->nbins - 1 );
        @idx = grep $include->[$_], @idx
          if $gi > 1;

        $tr->range_set( $edges->@[ $_, $_ + 1 ], $include->[$_] ) for @idx;
    }

    return $tr->to_grid;
}













# need extra args if bitwise feature is on.
sub _overload_and ( $self, $other, $ =, $ =, $ = ) {
    $other->$_isa( __PACKAGE__ )
      or die( "can only perform the | operation between two ${ \__PACKAGE__ } objects " );
    return $self->and( $other );
}










sub and ( $self, @args ) {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    return and_n( $self, @args );
}































signature_for and_n => ( positional => [ Slurpy [ ArrayRef [GridObject] ] ], );
sub and_n ( $grids ) {


    # need to get all of the grid's bins on the same grid.

    # create a sorted list of bin edges from all of the grids, then,
    # ask each grid what it's include value is for each bin and

    my @edge    = uniqnum sort { $a <=> $b } map { $_->_raw_edges->@* } $grids->@*;
    my @include = ( 1 ) x ( @edge - 1 );
    my $nbins   = @include;

    for my $grid ( $grids->@* ) {
        my $tree = Tree->from_grid( $grid );

        # we don't care about the last edge, as anything beyond that
        # has fallen off the edge of the universe.
        for my $idx ( 0 .. $nbins - 1 ) {
            my ( $v ) = $tree->get_range( $edge[$idx] );
            $include[$idx] &&= $v // 0;
        }
    }

    return __PACKAGE__->new(
        edges   => \@edge,
        include => \@include,
    );
}




















sub combine_bins ( $self ) {

    my $edges   = $self->_raw_edges;
    my $include = $self->include;

    my $tr = Tree->new( {
        'equal-p' => sub { defined $_[0] && defined $_[1] && $_[0] == $_[1] },
    } );

    $tr->range_set( $edges->[$_], $edges->[ $_ + 1 ], $include->[$_] ) for 0 .. ( $include->@* - 1 );

    return $tr->to_grid;
}



















sub bignum ( $self ) {
    require Moo::Role;
    return Moo::Role->apply_roles_to_object(
        __PACKAGE__->new( $self->TO_HASH ),
        __PACKAGE__ . '::Role::BigNum',
    );
}

















sub pdl ( $self ) {
    require Moo::Role;
    return Moo::Role->apply_roles_to_object(
        __PACKAGE__->new( $self->TO_HASH ),
        __PACKAGE__ . '::Role::PDL',
    );
}











sub _modify_hashr ( $self, $hash ) {
    $hash->{edges}   = [ map { $_->copy } $hash->{edges}->@* ];
    $hash->{include} = [ $hash->{include}->@* ]
      if exists $hash->{include};
}










sub to_string ( $self ) {

    my @edge = map { $_->numify } $self->_raw_edges->@*;
    my @bin  = map { [ $edge[$_], $edge[ $_ + 1 ] ] } 0 .. @edge - 2;

    if ( $self->_has_include ) {
        push $bin[$_]->@*, $self->include->[$_] for 0 .. @bin - 1;
    }

    return join "\n", map { join ', ', $_->@* } @bin;
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory nbins ndarrays nedges oob
ub unobscured Extrema bignum pdl

=head1 NAME

CXC::Number::Grid - A class representing a one dimensional numeric grid

=head1 VERSION

version 0.13

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

=head1 OBJECT ATTRIBUTES

=head2 oob

A boolean, which, if true, indicates that extra bins are added to
either end of the grid which catch values outside of the range of the
grid.

=head2 edges

An array of ascending numbers which represent the edges of the bins in the grid.

=head2 include

An array of flags (C<0>, C<1>), one per bin, indicating whether the bin should be included when binning or not.

=head1 CONSTRUCTORS

=head2 new

  $grid = CXC::Number::Grid->new( \%args );

The constructor takes the following arguments:

=over

=item C<edges> => I<array of numbers or Math::BigFloat objects>

The bin edges in the grid. Will be converted to L<Math::BigFloat>
objects if they're not already.  These must be in ascending order.

Specify either C<bounds> or C<edges> but not both.

=item C<include> => I<array of Flags>

An array of flags (C<0>, C<1>), one per I<bin> (not one per edge!),
indicating whether the bin should be included when binning or not.

=item C<oob> I<Boolean>

If true, C<< L</bin_edges> >> will extend the grid by one bin at each end.
The new lower bound is C<-POSIX::DBL_MAX> and the new upper bounds
will be C<POSIX::DBL_MAX>.  This allows out-of-bounds data to be accumulated
at the front and back of the grid.

=item C<bounds> => I<array of numbers or Math::BigFloat objects>

Instead of specifying the bin edges, the upper and lower bounds for
each bin may be specified.  If the supplied bins are not contiguous,
interstitial bins will be created with an include flag of 0.

The bounds are specified as I<lower bound>, I<upper bound> pairs in the
passed array, e.g.

   [ $lb0, $ub0, $lb1, $ub1 ]

Specify either C<bounds> or C<edges> but not both.

=back

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

=head2 not

  $flipped = $grid->not;

return a copy of C<$grid> with a Boolean not of its include values.

=head2 or

   $ABC = $A->or( $B, $C, ..., ?\%options );

Perform the logical OR of grids and return a new grid.
See C<< L</or_n> >> for a description of the options.

=head2 and

   $ABC = $A->and( $B, $C, ..., ?\%options );

Perform the logical AND of grids and return a new grid.
See C<< L</and_n> >> for a description of the options.

=head2 combine_bins

  $combined = $grid->combine_bins

Combine adjacent bins with the same C<include> value.

For instance, a grid with the following construction:

    edges   => [ 0, 2, 4, 8, 12, 16 ]
    include => [ 0, 0, 1, 1, 0 ]

Would be combined into

    edges   => [ 0, 4, 12, 16 ]
    include => [ 0, 1, 0 ]

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

Returns an object which returns ndarrays for the following methods

  edges     -> ndarray
  include   -> ndarray
  bin_edges -> ndarray
  spacing   -> ndarray
  lb        -> ndarray
  ub        -> ndarray

=head2 to_string

  $string = $grid->to_string

Create a fairly readable string representation of the structure of a
grid.

=head1 OVERLOAD

=head2 !

The logical NOT C<!> operator is overloaded; see L</not> for details.

=head2 |

   $AB = $A | $B

The logical OR C<!> operator is overloaded via

  $AB = $A->or($B);

see L</or> for details.

=head2 &

   $AB = $A | $B

The logical AND C<&> operator is overloaded via

  $AB = $A->and($B);

see L</or> for details.

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

=head2 or_n

  $grid = CXC::Number::Grid::or_n( $grid1, $grid2, ..., $gridN, ?\%options );

Logical OR of grids based upon their include values. For example, given
two grids:

  Grid A:

    edges   => [ 0, 2, 4, 8, 12, 16 ]
    include =>   [ 0, 1, 0, 1,  0 ]

  Grid B;
    edges   => [ 0, 3, 6, 9, 10, 11, 16 ]
    include =>   [ 1, 0, 1, 0,  1,  0 ]

The result of

     $A | $B

would be

     edges   => [ 0, 3, 4, 6, 9, 10, 11, 12, 16 ];
     include =>   [ 1, 1, 0, 1, 1,  1,  1,  0 ];

The L</oob> option for the returned grid is set to the default value.

=head2 and_n

  $grid = CXC::Number::Grid::and_n( $grid1, $grid2, ..., $gridN, ?\%options );

Logical AND of grids based upon their include values. For example, given
two grids:

  Grid A:

    edges   => [ 0, 2, 4, 8, 10, 16, 18 ]
    include => [  0, 1, 0, 1, 0,  1 ]

  Grid B;
    edges   => [ 1, 3, 6, 9, 10, 11, 16 ]
    include => [   1, 0, 1, 0,  1,  0 ]

The result of

     $A & $B

would be

    edges => [ 0, 1, 2, 3, 4, 6, 8, 9, 10, 11, 16, 18 ];
    include => [ 0, 0, 1, 0, 0, 0, 1, 0,  0,  0,  0 ];

The L</oob> option for the returned grid is set to the default value.

=head1 INTERNALS

=head2 Methods

=head3 _modify_hashr

This is called by MooX::Tag::TO_HASH to modify the generated hash
representation.

This routine makes copies of the structures so that the hash
can be modified without affecting the parent object.

=for Pod::Coverage BUILDARGS
BUILD

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

L<CXC::Number::Sequence|CXC::Number::Sequence>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
