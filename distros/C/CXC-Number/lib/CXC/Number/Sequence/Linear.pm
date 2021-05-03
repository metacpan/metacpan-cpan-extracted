package CXC::Number::Sequence::Linear;

# ABSTRACT: Numeric Sequence with Equal Spacing

use strict;
use warnings;

use feature ':5.24';
use experimental 'lexical_subs';

use Carp;

use Hash::Wrap 0.11 { -as => 'wrap_attrs_ro', -immutable => 1, -exists => 'has' };
use Types::Standard qw( Optional Bool );
use CXC::Number::Sequence::Failure -all;
use CXC::Number::Sequence::Types -all;
use CXC::Number::Sequence::Utils qw( buildargs_factory );

use enum
  qw( BITMASK: MIN MAX SOFT_MIN SOFT_MAX CENTER NELEM SPACING RANGEW ALIGN FORCE_EXTREMA );


use Moo;

our $VERSION = '0.05';

extends 'CXC::Number::Sequence';

sub BigFloat { Math::BigFloat->new( @_ ) }

use namespace::clean;

has _force_extrema => (
    is       => 'ro',
    isa      => Bool,
    init_arg => 'force_extrema',
    default  => 0,
);

my %ArgMap = (
    align    => { type => Optional [Alignment],      flag => ALIGN },
    spacing     => { type => Optional [BigPositiveNum], flag => SPACING },
    center   => { type => Optional [BigNum],         flag => CENTER },
    max      => { type => Optional [BigNum],         flag => MAX },
    min      => { type => Optional [BigNum],         flag => MIN },
    nelem    => { type => Optional [BigPositiveInt], flag => NELEM },
    rangew   => { type => Optional [BigPositiveNum], flag => RANGEW },
    soft_max => { type => Optional [BigNum],         flag => SOFT_MAX },
    soft_min => { type => Optional [BigNum],         flag => SOFT_MIN },
    force_extrema => { type => Optional [Bool], flag => FORCE_EXTREMA },
);

my sub build_sequence {
    my $attr = wrap_attrs_ro( shift );
    my @seq = map { $attr->min + $attr->spacing * $_ } 0 .. ($attr->nelem-1);

    # make sure that the bounds exactly match what is specified if the
    # sequence is exactly covering [min,max], just in case roundoff error
    # occurs.
    if ( $attr->args->has( 'force_extrema') &&
         $attr->args->force_extrema
       ) {
        $seq[0]  = $attr->min;
        $seq[-1] = $attr->max;
    }

    return \@seq;
}

# need the parens otherwise the => operator turns them into strings
my @ArgsCrossValidate = ( [
        MIN | MAX,
        sub {
            parameter_constraint->throw( "min < max\n" )
              unless $_->min < $_->max;
        },
    ],

    [
        MIN | SOFT_MAX,
        sub {
            parameter_constraint->throw( "min < soft_max\n" )
              unless $_->min < $_->soft_max;
        },
    ],

    [
        SOFT_MIN | MAX,
        sub {
            parameter_constraint->throw( "soft_min < max" )
              unless $_->soft_min < $_->max;
        },
    ],

    [
        SOFT_MIN | SOFT_MAX,
        sub {
            parameter_constraint->throw( "soft_min < soft_max" )
              unless $_->soft_min < $_->soft_max;
        },
    ],

    [
        CENTER | SOFT_MIN,
        sub {
            parameter_constraint->throw( "soft_min < center\n" )
              unless $_->soft_min < $_->center;
        },
    ],

    [
        CENTER | SOFT_MAX,
        sub {
            parameter_constraint->throw( "center < soft_max\n" )
              unless $_->center < $_->soft_max;
        },
    ],

    [
        CENTER | MIN,
        sub {
            parameter_constraint->throw( "min < center\n" )
              unless $_->min < $_->center;
        },
    ],

    [
        CENTER | MAX,
        sub {
            parameter_constraint->throw( "center < max\n" )
              unless $_->center < $_->max;
        },
    ],
);


my %ArgBuild;
%ArgBuild = (

    #----------------------------------------
    # The sequence exactly covers [ min, max ]
    # spacing = ( max - min ) / ( nelem - 1);
    ( MIN | MAX | NELEM ),
    sub {
        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $_->min,
                    max           => $_->max,
                    nelem         => $_->nelem,
                    spacing          => ( $_->max - $_->min ) / ( $_->nelem - 1 ),
                } ) };
    },

    #----------------------------------------

    # The sequence covers [ MIN= (max-min) / 2 - (nelem - 1 ) * spacing, MIN + ( nelem - 1 ) * spacing ]
    # nelem = ceil( ( max - min ) / spacing )

    ( MIN | MAX | SPACING ),
    sub {
        local $_ = wrap_attrs_ro( {
            force_extrema => $_->has('force_extrema') ? $_->force_extrema : 0,
            center        => ( $_->max + $_->min ) / 2,
            spacing          => $_->spacing,
            rangew        => ( $_->max - $_->min ),
        } );

        $ArgBuild{ ( CENTER | RANGEW | SPACING ) }->();
    },

    #----------------------------------------

    # The sequence exactly covers [ min, min + nelem + spacing ]
    ( MIN | NELEM | SPACING ),
    sub {
        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $_->min,
                    max           => $_->min + ( $_->nelem - 1 )* $_->spacing,
                    nelem         => $_->nelem,
                    spacing          => $_->spacing
                } ) };
    },

    # The sequence exactly covers [ max - nelem + spacing, max ]
    ( MAX | NELEM | SPACING ),
    sub {
        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $_->max - ( $_->nelem - 1 )* $_->spacing,
                    max           => $_->max,
                    nelem         => $_->nelem,
                    spacing          => $_->spacing,
                } ) };
    },

#----------------------------------------
# The sequence exactly covers [ MIN = center - spacing * (nelem-1) / 2, MIN + nelem * spacing ]

    ( CENTER | SPACING | NELEM ),
    sub {

        my $half_width = $_->spacing * ($_->nelem-1) / 2;

        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $_->center - $half_width,
                    max           => $_->center + $half_width,
                    nelem         => $_->nelem,
                    spacing          => $_->spacing,
                } ) };

    },

    # spacing = range_width / nelem
    # The sequence covers [ MIN=center - width/2, MIN + (nelem-1) * spacing ]
    ( CENTER | RANGEW | NELEM ),
    sub {
        my $spacing = $_->rangew / ($_->nelem - 1);

        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $_->center - $_->rangew / 2,
                    max           => $_->center + $_->rangew / 2,
                    nelem         => $_->nelem,
                    spacing          => $spacing,
                } ) };

    },

    #  spacing = range_width / nelem
    # The sequence covers [ MIN=center - width/2, MIN + (nelem-1) * spacing ]
    ( CENTER | RANGEW | SPACING ),
    sub {
        my $nelem = ( $_->rangew / $_->spacing )->bceil + 1;

        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $_->center - ($nelem-1) / 2 * $_->spacing,
                    max           => $_->center + ($nelem-1) / 2 * $_->spacing,
                    nelem         => $nelem,
                    spacing          => $_->spacing
                } ) };

    },

    # range_width is max of ( center - min, max - center )
    # spacing = range_width / (nelem-1)
    # The sequence covers [ MIN=center - width/2, MIN + (nelem-1) * spacing ]
    ( CENTER | SOFT_MIN | SOFT_MAX | NELEM ),
    sub {
        my $hw0 = $_->center - $_->soft_min;
        my $hw1 = $_->soft_max - $_->center;

        local $_ = wrap_attrs_ro( {
            force_extrema => $_->has('force_extrema') ? $_->force_extrema : 0,
            center        => $_->center,
            rangew        => 2 * ( $hw0 > $hw1 ? $hw0 : $hw1 ),
            nelem         => $_->nelem,
        } );
        $ArgBuild{ ( CENTER | RANGEW | NELEM ) }->();

    },

    # rangew is max of ( center - min, max - center )
    # spacing = rangew / (nelem-1)
    # The sequence covers [ MIN=center - width/2, MIN + (nelem-1) * spacing ]
    ( CENTER | SOFT_MIN | SOFT_MAX | SPACING ),
    sub {

        my $hw0 = $_->center - $_->soft_min;
        my $hw1 = $_->soft_max - $_->center;

        local $_ = wrap_attrs_ro( {
            force_extrema => $_->has('force_extrema') ? $_->force_extrema : 0,
            center        => $_->center,
            spacing          => $_->spacing,
            rangew        => 2 * ( $hw0 > $hw1 ? $hw0 : $hw1 ),
        } );

        $ArgBuild{ ( CENTER | RANGEW | SPACING ) }->();
    },

    #----------------------------------------

    # The sequence is anchored at min and covers [ min, soft_max ]
    ( MIN | SOFT_MAX | SPACING ),
    sub {
        my $nelem = ( ( $_->soft_max - $_->min ) / $_->spacing )->bceil + 1;

        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $_->min,
                    max           => $_->min + $nelem * $_->spacing,
                    nelem         => $nelem,
                    spacing          => $_->spacing
                } ) };
    },


    # The sequence is anchored at max and covers [ soft_min, max ]
    ( SOFT_MIN | MAX | SPACING ),
    sub {
        my $nelem = ( ( $_->max - $_->soft_min ) / $_->spacing )->bceil + 1;
        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $_->max - ($nelem-1) * $_->spacing,
                    max           => $_->max,
                    nelem         => $nelem,
                    spacing          => $_->spacing
                } ) };
    },

    #----------------------------------------
    # cover [min,max] with alignment
    ( MIN | MAX | SPACING | ALIGN ),
    sub {
        my ( $P, $f ) = $_->align->@*;
        my $E0    = $P - $f * $_->spacing;
        my $imin  = ( ( $_->min - $E0 ) / $_->spacing )->bfloor;
        my $imax  = ( ( $_->max - $E0 ) / $_->spacing )->bceil;
        my $nelem = $imax - $imin + 1;
        my $min   = $E0 + $imin * $_->spacing;

        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $min,
                    max           => $min + ($nelem-1) * $_->spacing,
                    nelem         => $nelem,
                    spacing          => $_->spacing,
                } ) };
    },

    ( MIN | MAX | NELEM | ALIGN ),
    sub {
        parameter_constraint->throw( "nelem > 2" )
          unless $_->nelem > 2;

        my ( $P, $f ) = $_->align->@*;
        my $spacing = ( $_->max - $_->min ) / ( $_->nelem - 2 );
        my $E0   = $P - $f * $spacing;
        my $imin = ( ( $_->min - $E0 ) / $spacing )->bfloor;
        my $imax = ( ( $_->max - $E0 ) / $spacing )->bceil;
        my $min  = $E0 + $imin * $spacing;

        {
            elements =>build_sequence( {
                    args          => $_,
                    min           => $min,
                    max           => $min + ($_->nelem-1) * $spacing,
                    nelem         => $_->nelem,
                    spacing          => $spacing,
                } ) };
    },

    #----------------------------------------

);

around BUILDARGS => buildargs_factory(
    map       => \%ArgMap,
    build     => \%ArgBuild,
    xvalidate => \@ArgsCrossValidate,
);

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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory Extrema spacing extrema
extremum fiducial nelem

=head1 NAME

CXC::Number::Sequence::Linear - Numeric Sequence with Equal Spacing

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use CXC::Number::Sequence::Linear;

  $sequence = CXC::Number::Sequence::Linear->new( %options );
  $values = $sequence->sequence;

=head1 DESCRIPTION

B<CXC::Number::Sequence::Linear> constructs a finite sequence of
increasing, equally spaced, numbers.

It subclasses L<CXC::Number::Sequence>, so see documentation for that
class for additional methods.

Sequence extrema may be specified or may be calculated from other
parameters, such as spacing, the number of elements, or a sequence center,
and the sequence may be aligned on a fiducial value,

Sequence extrema  may be  I<hard>, indicating that  the sequence  must exactly
cover the  extrema, or I<soft>, indicating  that the sequence may  cover a
larger  range.  Usually  the combination  of parameters  will uniquely
determine whether an extremum is soft  or hard, but in some cases soft
bounds  must be  explicitly  labelled  as soft,  requiring  use of  the
C<soft_min> and C<soft_max> parameters.

A full description of the available parameters may be found in the
description of the constructor L</new>.

=head2 Valid Parameter Combinations

I<Note:> If the sequence extrema are equal to the range bounds, then
the sequence B<exactly> covers the range.  Otherwise, the sequence
will cover the range, but may extend beyond one or more of the
extrema.

=over

=item C<min>, C<max>, C<nelem>.

The sequence exactly covers the specified range.

=item C<min>, C<max>, C<spacing>

If an integral multiple of C<spacing> fits within the range, the sequence exactly
covers it, otherwise the sequence is centered on the range.

=item C<min>, C<nelem>, C<spacing>

=item C<max>, C<nelem>, C<spacing>

The number of elements is chosen to exactly covers the calculated range.

=item C<min>, C<soft_max>, C<spacing>

=item C<soft_min>, C<max>, C<spacing>

The hard extremum is as specified. The number of elements is chosen to
cover the specified range.

=item C<center>, C<spacing>, C<nelem>

The sequence is centered as specified and exactly covers the range.

=item C<center>, C<rangew>, C<nelem>

The sequence is centered as specified and exactly covers the range.

=item C<center>, C<rangew>, C<spacing>

The sequence is centered as specified and covers the range.

=item C<center>, C<soft_min>, C<soft_max>, C<nelem>

=item C<center>, C<soft_min>, C<soft_max>, C<spacing>

The sequence is centered on the specified center and covers the
specified range.

=item C<min>, C<max>, C<spacing>, C<align>

=item C<min>, C<max>, C<nelem>, C<align>

The sequence covers the specified range and is aligned so that the
specified alignment point is at the specified relative position between
elements.

=back

=for Pod::Coverage BUILDARGS

=head1 Methods

=head2 C<new>

  $sequence = CXC::Number::Sequence::Linear->new( %attr );

Construct a linear spaced sequence.  The available attributes are
those for the parent constructor in L<CXC::Number::Sequence>, as well
as the following:

=over

=item C<force_extrema> I<Boolean>

Sometimes the extrema of the sequence will not exactly match what was
specified because of round-off error. If this option is true, then
sequences extrema will be set to the specified values.  This may result
in spacings which are slightly different in size (the exact spacings
are available via the C<spacing> method).

=item C<min>

=item C<soft_min>

The minimum value that the sequence should cover.
Use C<soft_min> to disambiguate hard from soft limits as documented above.

=item C<max>

=item C<soft_max>

The maximum value that the sequence should cover.
Use C<soft_max> to disambiguate hard from soft limits as documented above.

=item C<center>

The center of the sequence. If there are an odd number of elements, this will
be the center element, otherwise it will be the average of the middle two.

=item C<rangew>

The width of the range to be covered by the sequence.

=item C<C<nelem>>

The number of elements in the sequence

=item C<spacing>

The distance between elements in the sequence.

=item C<align> = I<[ $P, $f ]>

The sequence will be aligned such that the fiducial value C<$P> is located
at the fractional position C<$f> between elements. C<$P> need not be in
the range of data covered by the sequence.

For example, to align the sequence such that C<0> falls exactly half way between
two elements, even though the generated sequence doesn't include C<0>:

 use Data::Dump;
 use aliased 'CXC::Number::Sequence::Linear';
 dd Linear->new( min => 5.1,
                 max => 8,
                 spacing => 1,
                 align => [ 0, 0.5 ],
               )->elements;

results in

 [4.5, 5.5, 6.5, 7.5, 8.5]


=back

If an inconsistent set of parameters is passed, C<new> will throw an exception of class
C<CXC::Number::Sequence::Failure::parameter::interface>.

If an unknown parameter is passed, C<new> will throw an exception of class
C<CXC::Number::Sequence::Failure::parameter::unknown>.

If a parameter value is illegal (e.g., a negative spacing),
or a combination of values is illegal ( e.g. C<< min > max >>, C<new>
will throw an exception of class
C<CXC::Number::Sequence::Failure::parameter::constraint>.

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

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
