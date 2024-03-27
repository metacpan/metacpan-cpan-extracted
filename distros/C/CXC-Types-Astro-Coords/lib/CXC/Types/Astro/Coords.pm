package CXC::Types::Astro::Coords;

# ABSTRACT: type definitions for Coordinates

use v5.28;    # for POSIX::copysign

use strict;
use warnings;

use experimental 'signatures', 'postderef', 'declared_refs';

our $VERSION = '0.12';

use CXC::Types::Astro::Coords::Util 'mkSexagesimal';

use Type::Library
  -base,
  -declare => qw(
  Degrees

  LatitudeArray
  LatitudeDegrees
  LatitudeSexagesimal

  LongitudeArray
  LongitudeDegrees
  LongitudeSexagesimal

  RightAscensionArray
  RightAscensionDegrees
  RightAscensionSexagesimal

  DeclinationArray
  DeclinationDegrees
  DeclinationSexagesimal

  SexagesimalArray
  SexagesimalDegrees
  SexagesimalHMS
  SexagesimalDMS
  );

use Types::Standard        qw( Any Int Num StrMatch Tuple );
use Types::Common::Numeric qw( IntRange NumRange );
use Types::Common::String  qw( NonEmptyStr );
use Regexp::Common;
use Type::Utils -all;
use POSIX qw( fmod copysign );

my sub croak {
    require Carp;
    goto \&Carp::croak;
}














BEGIN {
    my @parameters = qw[ -any -optws -optsep -optunits -trim ];
    my %default    = mkSexagesimal( @parameters )->%*;

    sub methods ( %attr ) {
        return {
            ## no critic (BuiltinFunctions::ProhibitComplexMappings)
            map {
                my $value = $attr{$_};
                $_ => sub { $value },
              }
              keys %attr,
        };
    }

    __PACKAGE__->meta->add_type(
        name                 => 'Sexagesimal',
        constraint_generator => sub ( @args ) {
            croak( 'Sexagesimal requires parameters' )
              unless @args;
            my %parameterized = mkSexagesimal( @args )->%*;
            return Type::Tiny->new(
                display_name => 'Sexagesimal[' . join( q{,}, sort @args ) . ']',
                constraint   => $parameterized{constraint},
                parameters   => [@args],
                parent => Any,   # required to avoid an oops; see https://github.com/tobyink/p5-type-tiny/issues/151
                my_methods => methods( %parameterized ),
            );
        },
        constraint => $default{constraint},
        my_methods => methods( %default ),
    );
}













declare SexagesimalArray, as Tuple [ Int, IntRange [ 0, 59 ], NumRange [ 0, 60, 0, 1 ] ];









declare SexagesimalDegrees, as Num;

coerce SexagesimalArray,   from NonEmptyStr,      Sexagesimal->my_Str_toArrayRef;
coerce SexagesimalDegrees, from NonEmptyStr,      Sexagesimal->my_Str_toDegrees;
coerce SexagesimalDegrees, from SexagesimalArray, Sexagesimal->my_ArrayRef_toDegrees;







declare Degrees, as NumRange [ 0, 360, 0, 1 ];
coerce Degrees, from Num, q{  POSIX::fmod( 360 + POSIX::fmod( $_, 360 ), 360 ) };













declare LongitudeArray,
  as Tuple [ IntRange [ 0, 359 ], IntRange [ 0, 59 ], NumRange [ 0, 60, 0, 1 ] ];










declare LongitudeDegrees, as NumRange [ 0, 360, 0, 1 ];































declare LongitudeSexagesimal, as Sexagesimal [ -long, -trim, -optws, -optunits, -optsep ];

coerce LongitudeArray,   from NonEmptyStr,    LongitudeSexagesimal->my_Str_toArrayRef;
coerce LongitudeDegrees, from NonEmptyStr,    LongitudeSexagesimal->my_Str_toDegrees;
coerce LongitudeDegrees, from LongitudeArray, LongitudeSexagesimal->my_ArrayRef_toDegrees;



















declare LatitudeArray,
  as Tuple [ IntRange [ -90, 90 ], IntRange [ 0, 59 ], NumRange [ 0, 60, 0, 1 ] ], where sub {
    abs( $_->[0] ) + $_->[1] / 60 + $_->[2] / 3600 <= 90;
  }, inline_as {
    my $V = $_[1];
    return ( undef, qq{abs( $V\->[0] ) + $V\->[1] / 60 + $V\->[2] / 3600 <= 90} );
  };










declare LatitudeDegrees, as NumRange [ -90, 90 ];


































declare LatitudeSexagesimal, as Sexagesimal [ -lat, -trim, -optws, -optunits, -optsep ];
coerce LatitudeArray,   from NonEmptyStr,   LatitudeSexagesimal->my_Str_toArrayRef;
coerce LatitudeDegrees, from NonEmptyStr,   LatitudeSexagesimal->my_Str_toDegrees;
coerce LatitudeDegrees, from LatitudeArray, LatitudeSexagesimal->my_ArrayRef_toDegrees;













declare RightAscensionArray,
  as Tuple [ IntRange [ 0, 23 ], IntRange [ 0, 59 ], NumRange [ 0, 60, 0, 1 ] ];










declare RightAscensionDegrees, as NumRange [ 0, 360 ];






























declare RightAscensionSexagesimal, as Sexagesimal [ -ra, -trim, -optws, -optunits, -optsep ];
coerce RightAscensionArray,   from NonEmptyStr, RightAscensionSexagesimal->my_Str_toArrayRef;
coerce RightAscensionDegrees, from NonEmptyStr, RightAscensionSexagesimal->my_Str_toDegrees;
coerce RightAscensionDegrees, from RightAscensionArray,
  RightAscensionSexagesimal->my_ArrayRef_toDegrees;

















declare DeclinationArray, as LatitudeArray, coercion => 1;









declare DeclinationDegrees, as LatitudeDegrees, coercion => 1;


































declare DeclinationSexagesimal, as LatitudeSexagesimal, coercible => 1;

coerce DeclinationArray,   from NonEmptyStr,      DeclinationSexagesimal->my_Str_toArrayRef;
coerce DeclinationDegrees, from NonEmptyStr,      DeclinationSexagesimal->my_Str_toDegrees;
coerce DeclinationDegrees, from DeclinationArray, DeclinationSexagesimal->my_ArrayRef_toDegrees;















declare SexagesimalHMS, as Sexagesimal [ -ra, -trim, -optws, -units ];
















declare SexagesimalDMS, as Sexagesimal [ -deg, -trim, -optws, -units ];

1;

#
# This file is part of CXC-Types-Astro-Coords
#
# This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Terry Gaetz Diab Jerius Smithsonian Astrophysical Observatory Coercible
DeclinationArray DeclinationDegrees DeclinationSexagesimal LatitudeArray
LatitudeDegrees LatitudeSexagesimal LongitudeArray LongitudeDegrees
LongitudeSexagesimal RightAscensionArray RightAscensionDegrees
RightAscensionSexagesimal SexagesimalArray SexagesimalDMS
SexagesimalDegrees SexagesimalHMS mkSexagesimal sexagesimal

=head1 NAME

CXC::Types::Astro::Coords - type definitions for Coordinates

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use CXC::Types::Astro::Coords -types;

=head1 DESCRIPTION

B<CXC::Types::Astro::Coords> provides L<Type::Tiny> compatible types for coordinate
conventions used in Astronomy.

=head1 TYPES

=head2 Sexagesimal[`a]

  $type = Sexagesimal[ @flags ];

  $type = Sexagesimal; #  same as Sexagesimal[ qw( -any -optws -optsep -optunits -trim )]

Return a type tuned to recognize specific forms of sexagesimal
coordinate notation.  See the L<CXC::Types::Astro::Coords::Util>
B<mkSexagesimal> subroutine for more information on the available
flags.

=head2 SexagesimalArray

An array of three values (I<degrees>, I<minutes>, I<seconds>), where the values have ranges and types

  [unbounded]  <integer>
  [0, 59]      <integer>
  [0, 60)      <float>

Coercible from a string matching L</Sexagesimal>.

=head2 SexagesimalDegrees

A real number.

Coercible from either L</SexagesimalArray> or L</Sexagesimal>

=head2 Degrees

A real number in the range [0,360). Numbers are coerced by modulo 360.

=head2 LongitudeArray

An array of three values (I<degrees>, I<minutes>, I<seconds>), where the values have ranges and types

  [0,359]  <integer>
  [0, 59]  <integer>
  [0, 60)  <float>

Coercible from a string matching L</LongitudeSexagesimal>.

=head2 LongitudeDegrees

A real number in the range [0,360)

Coercible from either L</LongitudeArray> or L</LongitudeSexagesimal>

=head2 LongitudeSexagesimal

A string with three components (I<degrees>, I<minutes>, I<seconds>),
optionally separated by one of

=over

=item *

white space;

=item *

the C<:> character;

=item *

component specific suffices of C<d>, C<m>, or C<s>.

=back

The components have ranges of:

  [0, 359]  <integer>
  [0,  59]  <integer>
  [0,  60)  <integer/float>

=head2 LatitudeArray

An array of three values (I<degrees>, I<minutes>, I<seconds>), where
the values have ranges and types of

  [-90, 90]  <integer>
  [  0, 59]  <integer>
  [  0, 60)  <integer/float>

and

  abs($A[0]) + ( $A[1] + $A[2] / 60 ) / 60 <= 90

Coercible from a string matching L</LatitudeSexagesimal>.

=head2 LatitudeDegrees

A real number in the range [-90,+90]

Coercible from either L</LatitudeArray> or L</LatitudeSexagesimal>

=head2 LatitudeSexagesimal

A string with three components (I<degrees>, I<minutes>, I<seconds>) optionally separated by one of

=over

=item *

white space

=item *

the C<:> character,

=item *

component specific suffices of C<d>, C<m>, or C<s>

=back

The components have ranges and types of

   [-90, 90]  <integer>
   [  0, 59]  <integer>
   [  0, 60)  <integer/float>

and

  abs($A[0]) + ( $A[1] + $A[2] / 60 ) / 60 <= 90

=head2 RightAscensionArray

An array of three values (I<hours>, I<minutes>, I<seconds>), where the values have ranges and types of

  [0, 23]  <integer>
  [0, 59]  <integer>
  [0, 60)  <integer/float>

Coercible from a string matching L</RightAscensionSexagesimal>.

=head2 RightAscensionDegrees

A real number in the range [0,360]

Coercible from either L</RightAscensionArray> or L</RightAscensionSexagesimal>

=head2 RightAscensionSexagesimal

A string with three components (I<hours>, I<minutes>, I<seconds>) optionally separated by one of

=over

=item *

white space

=item *

the C<:> character,

=item *

component specific suffices of C<h>, C<m>, or C<s>

=back

The components have ranges and types of:

  [0, 23]  <integer>
  [0, 59]  <integer>
  [0, 60)  <integer/float>

=head2 DeclinationArray

An array of three values (I<degrees>, I<minutes>, I<seconds>), where the values have ranges and types of

  [-90, 90]  <integer>
  [  0, 59]  <integer>
  [  0, 60)  <integer/float>

and

  abs($A[0]) + ( $A[1] + $A[2] / 60 ) / 60 <= 90

Coercible from a string matching L</DeclinationSexagesimal>.

=head2 DeclinationDegrees

A real number in the range [-90,+90]

Coercible from either L</DeclinationArray> or L</DeclinationSexagesimal>

=head2 DeclinationSexagesimal

A string with three components (I<degrees>, I<minutes>, I<seconds>), optionally separated by one of

=over

=item *

white space;

=item *

the C<:> character;

=item *

component specific suffices of C<d>, C<m>, or C<s>.

=back

The components have ranges and types of

  [-90, 90]  <integer>
  [  0, 59]  <integer>
  [  0, 60)  <integer/float>

and

  abs($A[0]) + ( $A[1] + $A[2] / 60 ) / 60 <= 90

=head2 SexagesimalHMS

A string with three components (I<hours>, I<minutes>, I<seconds>).
Each component consists of a number and a suffix of C<h>,C<m>, C<s>.
Components may be separated by white space.

The components have ranges and types of:

  [0, 23]  <integer>
  [0, 59]  <integer>
  [0, 60)  <integer/float>

=head2 SexagesimalDMS

A string with three components  (I<degrees>, I<minutes>, I<seconds>).
Each component consists of a number, optional white space, and a
suffix of C<d>,C<m>, C<s>.  Components may be separated by white space.

The components have ranges and types of:

  [0, 359]  <integer>
  [0,  59]  <integer>
  [0,  60)  <integer/float>

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-types-astro-coords@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Types-Astro-Coords>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-types-astro-coords

and may be cloned from

  https://gitlab.com/djerius/cxc-types-astro-coords.git

=head1 AUTHORS

=over 4

=item *

Terry Gaetz <tgaetz@cfa.harvard.edu>

=item *

Diab Jerius <djerius@cfa.harvard.edu>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
