package CXC::Number::Sequence::Ratio;

# ABSTRACT: Numeric Sequence with Relative Fractional Spacing

use strict;
use warnings;

use feature ':5.24';
use experimental 'lexical_subs';

# ABSTRACT: ratio sequence

use Carp;

use Types::Standard qw( Optional );
use Types::Common::Numeric qw( PositiveInt );
use Math::BigInt;
use List::Util qw( max );

use CXC::Number::Sequence::Failure -all;
use CXC::Number::Sequence::Types -all;

use CXC::Number::Sequence::Utils qw( buildargs_factory );

use enum qw( BITMASK: MIN MAX SOFT_MIN SOFT_MAX NELEM W0 RATIO E0 );

my %ArgMap = (
    w0       => { type => Spacing,                flag => W0 },
    e0       => { type => Optional [BigNum],      flag => E0 },
    max      => { type => Optional [BigNum],      flag => MAX },
    min      => { type => Optional [BigNum],      flag => MIN },
    nelem    => { type => Optional [PositiveInt], flag => NELEM },
    ratio    => { type => Ratio,                  flag => RATIO },
    soft_max => { type => Optional [BigNum],      flag => SOFT_MAX },
    soft_min => { type => Optional [BigNum],      flag => SOFT_MIN },
);

use Moo;

extends 'CXC::Number::Sequence';

use namespace::clean;

our $VERSION = '0.06';

my sub nelem {
    my ( $ratio, $w0, $Dr ) = @_;

    $w0 = $w0->copy->babs;
    $Dr = $Dr->copy->babs;

    return (
        ( ( $w0 - ( 1 - $ratio ) * $Dr ) / $w0 )->blog / $ratio->copy->blog )
      ->bceil + 1;
}

my sub DRn_factory {
    my ( $w0, $ratio ) = map { $_->copy } @_;

    $w0 = $w0->copy->babs;

    return sub {
        map { $w0 * ( 1 - $ratio->copy->bpow( $_ ) ) / ( 1 - $ratio ) } @_;
    };

}

my sub covers_range {
    my ( $ratio, $w0, $Dr ) = @_;

    return if $ratio->copy->babs >= 1;

    $Dr = $Dr->copy->babs;
    $w0 = $w0->copy->babs;

    return if $Dr <= $w0 / ( 1 - $ratio );

    my $min_w0 = $Dr * ( 1 - $ratio );
    parameter_constraint->throw(
        "spacing ($w0) is too small to cover range; must be >= $min_w0\n" );
}

my sub e0_le_min {

    my ( $ratio, $w0, $min, $max, $E0 ) = @_;

    # ensure we can get to $max
    covers_range( $ratio, $w0, $max - $E0 );

    my $DRn = DRn_factory( $w0, $ratio );

    # if $min == $E0, $nmin will be -1; it should be 0
    my $nmin = max( 0, nelem( $ratio, $w0, $min - $E0 ) - 2 );
    my $nmax = nelem( $ratio, $w0, $max - $E0 ) - 1;

    return [ map { $E0 + $_ } $DRn->( $nmin .. $nmax ) ];
}

my sub e0_ge_max {

    my ( $ratio, $w0, $min, $max, $E0 ) = @_;

    # ensure we can get to $min
    covers_range( $ratio, $w0, $E0 - $min );

    my $DRn  = DRn_factory( $w0, $ratio );
    my $nmin = nelem( $ratio, $w0, $E0 - $min ) - 1;

    # if $max == $E0, $nmax will be -1; it should be 0
    my $nmax = max( 0, nelem( $ratio, $w0, $max - $E0 ) - 2 );

    return [ map { $E0 - $_ } $DRn->( reverse $nmax .. $nmin ) ];
}

my %ArgBuild;
%ArgBuild = (
    ( MIN | SOFT_MAX | W0 | RATIO ),
    sub {
        { elements => e0_le_min( $_->ratio, $_->w0, $_->min, $_->soft_max, $_->min ) };
    },

    ( MIN | NELEM | W0 | RATIO ),
    sub {
        my $DRn = DRn_factory( $_->w0, $_->ratio );
        my $E0  = $_->min;

        { elements => [ map { $E0 + $_ } $DRn->( 0 .. $_->nelem-1 ) ] };
    },

    ( SOFT_MIN | MAX | W0 | RATIO ),
    sub {
        { elements => e0_ge_max( $_->ratio, $_->w0, $_->soft_min, $_->max, $_->max ) };
    },


    ( MAX | NELEM | W0 | RATIO ),
    sub {

        my $DRn = DRn_factory( $_->w0, $_->ratio );
        my $E0  = $_->max;

        { elements => [ map { $E0 - $_ } $DRn->( reverse 0 .. $_->nelem-1 ) ] };

    },

    ( E0 | MIN | MAX | W0 | RATIO ),
    sub {

        my $elements = do {

            if ( $_->e0 < $_->min ) {
                e0_le_min( $_->ratio, $_->w0, $_->min, $_->max, $_->e0 );
            }

            # shrink & grow!
            elsif ( $_->e0 < $_->max ) {

                my $low
                  = e0_ge_max( 1 / $_->ratio, $_->w0 / $_->ratio, $_->min, $_->e0,
                    $_->e0 );

                my $high
                  = e0_le_min( $_->ratio, $_->w0, $_->e0, $_->max,
                    $_->e0 );

                # low and high share an edge; remove it.
                my @elements = ( $low->@* );
                pop @elements;
                push @elements, $high->@*;
                \@elements;
            }
            else {
                e0_ge_max( $_->ratio, $_->w0, $_->min, $_->max, $_->e0 );
            }
        };

        return { elements => $elements };
    },

);

# need the parens otherwise the => operator turns them into strings
my @ArgsCrossValidate = ( [

        E0 | MIN | MAX,
        sub {
            parameter_constraint->throw( "min < max\n" )
              unless $_->min < $_->max;

            parameter_constraint->throw( "w0 > 0 if E[0] <= min\n" )
              if $_->e0 <= $_->min &&  $_->w0 < 0;

            parameter_constraint->throw( "w0 < 0 if E[0] >= max\n" )
              if $_->e0 >= $_->max &&  $_->w0 > 0;
        },
    ],

    [
        MIN | SOFT_MAX,
        sub {
            parameter_constraint->throw( "min < soft_max\n" )
              unless $_->min < $_->soft_max;

            parameter_constraint->throw( "w0 > 0 if E[0] == min\n" )
              unless $_->w0 > 0;
        },
    ],

    [
        SOFT_MIN | MAX,
        sub {
            parameter_constraint->throw( "soft_min < max\n" )
              unless $_->soft_min < $_->max;

            parameter_constraint->throw( "w0 < 0 if E[0] == max\n" )
              unless $_->w0 < 0;
        },
    ],

);

around BUILDARGS => buildargs_factory(
    map       => \%ArgMap,
    build     => \%ArgBuild,
    xvalidate => \@ArgsCrossValidate
);

























































































1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory extrema extremum spacings

=head1 NAME

CXC::Number::Sequence::Ratio - Numeric Sequence with Relative Fractional Spacing

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use CXC::Number::Sequence::Ratio;

  $seq = CXC::Number::Sequence::Ratio->new( min = $min, max => $max,
                                            w0 => $spacing,
                                            ratio => $ratio );

  $sequence = $seq->elements;

=head1 DESCRIPTION

B<CXC::Number::Sequence::Ratio> generates an increasing sequence of numbers
covering a range, where the ratio of the spacing, I<w[k]>, between
consecutive numbers I<E[k]> and I<E[k-1]> is a constant, e.g.,

  w[k] = r * w[k-1]                  (1)

 In general, a number in the sequence is

                            k
                       1 - r
   E[k] = E[0] + w[0] -------        (2)
                       1 - r

Where I<E[0]> is the I<alignment> value, I<w[0]> is the initial spacing,
I<E[1]-E[0]>, and I<k> is the I<generating> index (not the output order).
The sequence is always output in increasing value, regardless of the
order in which it was generated.

I<r> must be positive and not equal to I<1> (that would generate a
linear sequence and the algorithms used in this module would
break). The alignment value, I<E[0]>, need not be one of the range
extrema, nor even in the range.

If the sequence must cover a specific range, then some
caveats apply. If I<< r < 1 >>, Eq. 2 may converge to a value
which does not allow covering the specified range:

                          w[0]
   E[Infinity] = E[0] + -------        (3)
                         1 - r

An exception will be thrown if this is the case.

If I<< E[0] >= E[max] >> the sequence values are generated from
larger to smaller values.  C<< w[0] >> must be C<< < 0 >> , and C<r>
is the growth factor in the direction of smaller sequence
values.

It subclasses L<CXC::Number::Sequence>, so see documentation for that
class for additional methods.

A full description of the available parameters may be found in the
description of the constructor L</new>.

If an inconsistent set of parameters is passed, C<new> will throw an exception of class
C<CXC::Number::Sequence::Failure::parameter::IllegalCombination>.

If an unknown parameter is passed, C<new> will throw an exception of class
C<CXC::Number::Sequence::Failure::parameter::unknown>.

If a parameter value is illegal or a combination of values is illegal
(e.g. C<< min > max >>), C<new> will throw an exception of class
C<CXC::Number::Sequence::Failure::parameter::constraint>.

=head1 CONSTRUCTOR

=head2 new

  $sequence = CXC::Number::Sequence::Ratio->new( %attr );

Construct a sequence.  The available attributes are those for the parent
constructor in L<CXC::Number::Sequence::Base>, as well as the following:

Only certain combinations of parameters are allowed; see L</Valid Parameter Combinations>.

=head3 Range Parameters

Range extrema may be  I<hard>, indicating that  the sequence  must exactly
cover the  extrema, or I<soft>, indicating  that the sequence may  cover a
larger  range.  Usually  the combination  of parameters  will uniquely
determine whether an extremum is soft  or hard, but in some cases soft
bounds  must be  explicitly  labeled  as soft, requiring  use of  the
C<soft_min> and C<soft_max> parameters.

=over

=item C<min>

=item C<soft_min>

The minimum value that the sequence should cover.
Use C<soft_min> to disambiguate hard from soft limits as documented above.

=item C<max>

=item C<soft_max>

The maximum value that the sequence should cover.
Use C<soft_max> to disambiguate hard from soft limits as documented above.

=item C<C<nelem>>

The number of elements in the sequence

=back

=head3 Spacing and Alignment

=over

=item C<w0>

The spacing between I<E[0]> and I<E[1]>.  All other spacings are based
on this.  If C<< E[0] >= max >>, then C<w0> must be negative, otherwise it
must be positive.  If C<< w[0] >> has the incorrect sign, an exception
will be thrown.

=item C<e0>

C<E[0]>. This is usually implicitly specified by the C<min> or C<max>
parameters. Set it explicitly if it is not one of the extrema.

=back

=head3 Valid Parameter Combinations

=over

=item C<min>, C<soft_max>, C<w0>, C<ratio>

C<E[0] = min>, and the sequence minimally covers the range.

=item C<soft_min>, C<max>, C<w0>, C<ratio>

C<E[0] = max>, and the sequence minimally covers the range.  C<< w0 < 0 >>.

=item C<min>, C<nelem>, C<w0>, C<ratio>

C<E[0] = min> and the sequence exactly covers the specified range. C<< w0 > 0 >>

=item C<max>, C<nelem>, C<w0>, C<ratio>

C<E[0] = max>, and the sequence exactly covers the range.  C<< w0 < 0 >>.

=item C<e0> C<min>, C<max>, C<w0>, C<ratio>

C<E[0] = e0>, and the sequence covers the range. C<E[0]>
need not be inside the range. C<< w0 < 0 >> if C<< E[0] > max >>.

=back

=for Pod::Coverage BUILDARGS

# COPYRIGHT

=head1 EXAMPLES

=over

=item 1

  Range: [2,20]
  E[0] = 20
  w[0] = -1
  r    = 1.1

Cover the range C<[2, 20]>, with the alignment value at the max of the range.  Spacing increases
from C<20> to C<2>, starting at C<1>, by a factor of 1.1 per value.

 use Data::Dump;
 use aliased 'CXC::Number::Sequence::Ratio';
 dd Ratio->new( soft_min => 2, max => 20,
                ratio => 1.1, w0 => -1
              )->elements;

results in

 [
   1.4688329389,
   4.062575399,
   6.42052309,
   8.5641119,
   10.512829,
   12.28439,
   13.8949,
   15.359,
   16.69,
   17.9,
   19,
   20,
 ]


=back

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
