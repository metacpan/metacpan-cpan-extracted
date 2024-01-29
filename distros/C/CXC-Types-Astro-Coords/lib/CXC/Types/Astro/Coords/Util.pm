package CXC::Types::Astro::Coords::Util;

# ABSTRACT: Coordinate Type utilities

use v5.28;
use warnings;

use experimental 'signatures', 'postderef', 'declared_refs';

our $VERSION = '0.11';

use POSIX ();
use Regexp::Common;
use List::Util 'zip';
use Exporter::Shiny qw( mkSexagesimal from_Degrees);


my sub croak {
    require Carp;
    goto \&Carp::croak;
}



































































































































## no critic (Subroutines::ProhibitExcessComplexity)
sub mkSexagesimal ( @wanted ) {

    state %comp = do {
        my %base = (
            -ra     => q{(?:[0-2]\d)|\d},
            -dec    => q{[+-]?\d\d?},
            -deg    => q{[+]?[0-3]?\d\d?},
            -negdeg => q{[+-]?[0-3]?\d\d?},
        );
        $base{-lat}     = $base{-dec};
        $base{-long}    = $base{-deg};
        $base{-neglong} = $base{-negdeg};
        $base{-any}     = $base{-negdeg};
        %base;
    };

    state %check = do {
        my %base = (
            -ra  => q{( (0 <= $1 && $1 < 24) && (0 <= $2 && $2 < 60) && (0 <= $3 && $3 < 60) )},
            -dec =>
              q{( (-90 <= $1 && $1 <= 90) && (0 <= $2 && $2 < 60) && (0 <= $3 && $3 < 60) && (abs( $1 ) + ( $2 + $3 / 60 ) / 60 <= 90) )},
            -deg => q{( (0 <= $1 && $1 < 360) && (0 <= $2 && $2 < 60) && (0 <= $3 && $3 < 60) )},
        );
        $base{-lat}     = $base{-dec};
        $base{-long}    = $base{-deg};
        $base{-negdeg}  = q{1};
        $base{-neglong} = $base{-negdeg};
        $base{-any}
          = q{ ( ($2//'d') eq 'h' ? (0 <= $1 && $1 < 24 && 0 <= $3 && $3 < 60 && 0 <= $4 && $4 < 60) : 1) };
        %base;
    };

    state %ArrayReftoDegrees = do {
        my %base = (
            -ra     => q{ ( 15 * $_->[0] + $_->[1] / 4 + $_->[2] / 240 ) },
            -dec    => q{ POSIX::copysign( abs($_->[0]) + $_->[1]/60 + $_->[2]/3600, $_->[0] ) },
            -deg    => q{ ( $_->[0] + $_->[1]/60 + $_->[2] / 3600 ) },
            -negdeg => q{ POSIX::copysign( abs($_->[0]) + $_->[1]/60 + $_->[2] / 3600, $_->[0] ) },
        );
        $base{-lat}     = $base{-dec};
        $base{-long}    = $base{-deg};
        $base{-neglong} = $base{-negdeg};
        $base{-any}     = $base{-negdeg};

        %base;
    };

    state %Match_toArrayRef = do {
        my %base = (
            -any => <<~'EOS',
            do { ($2//'d') eq 'h'
                  ? do {
                         my @array = ( $1, $3, $4 );
                         my $degrees = ( 15 * $array[0] +  $array[1] / 4 + $array[2] / 240 );
                         my @comp = ( int($degrees) );
                         $degrees -= $comp[0];
                         $degrees *= 60;
                         $comp[1] = int($degrees);
                         $comp[2] = 60 * ($degrees - $comp[1]);
                         \@comp;
                    }
                  : [ 0+$1, 0+$3, 0+$4 ]
              }
           EOS
        );
        $base{$_} = q<[ 0+$1, 0+$2, 0+$3 ]> for qw( -ra -dec -deg -negdeg -lat -long -neglong );
        %base;
    };

    #<<< no tidy
    state %unit
      = ( map { $_ =>
                   $_ eq '-ra' ? '[h]'
                : ($_ eq '-any' ? '([hd])'
                :                '[d]'
              ) } keys %comp );
    #>>> ydit on

    # ws after each term
    state @term_ws = (
        [ q{},   q{},   q{} ],    # no ws
        [ '\h+', '\h+', q{} ],    # required ws
        [ '\h*', '\h*', q{} ],    # optional ws
    );

    # sep after each term
    state @term_sep = (
        [ q{},   q{},   q{} ],    # no sep
        [ q{:},  q{:},  q{} ],    # required sep
        [ q{:?}, q{:?}, q{} ],    # optional sep
    );

    state %utils;

    my $utils = $utils{ join $;, sort @wanted } //= do {

        my %wanted;
        @wanted{@wanted} = ( 1 ) x @wanted;

        my $required_ws = !!delete( $wanted{-ws} )    ? 1 : 0;
        my $optional_ws = !!delete( $wanted{-optws} ) ? 2 : 0;
        my $want_ws     = $required_ws + $optional_ws;

        my $required_unit = !!delete( $wanted{-units} )    ? 1 : 0;
        my $optional_unit = !!delete( $wanted{-optunits} ) ? 2 : 0;
        # my $want_unit     = $required_unit + $optional_unit;

        my $required_sep = !!delete $wanted{-sep}    ? 1 : 0;
        my $optional_sep = !!delete $wanted{-optsep} ? 2 : 0;
        my $want_sep     = $required_sep + $optional_sep;

        my $want_trim = !!delete $wanted{-trim};

        croak( 'illegal combination: -ws and (-sep or -optsep)' )
          if $want_sep && $required_ws;

        croak( 'illegal combination of -sep and -units' )
          if $required_sep && $required_unit;

        croak( 'illegal combination of -sep and -optunits' )
          if $required_sep && $optional_unit;

        croak( 'illegal combination of -sep and -optws' )
          if $required_sep && $optional_ws;

        croak( 'illegal combination of -optsep and -units' )
          if $optional_sep && $required_unit;

        my ( $coord, @extra ) = grep defined delete $wanted{$_}, keys %comp;
        croak( 'too many coordinate systems specified: ' . join q{, }, $coord, @extra )
          if @extra;

        croak( 'unrecognized options: ', join q{, }, keys %wanted ) if keys %wanted;

        $coord //= '-any';

        my @comp = ( $comp{$coord}, '[0-5]?[0-9]', $RE{num}{decimal} );

        my @units
          = ( map { $required_unit ? $_ : $optional_unit ? qq{$_?} : q{} } $unit{$coord}, '[m]', '[s]' );

        my @ws = $term_ws[$want_ws]->@*;

        my @sep = $term_sep[$want_sep]->@*;

        ## no critic(BuiltinFunctions::ProhibitComplexMappings)
        my $qr = q{^} . join(
            q{},
            ( $want_trim ? '\h*' : () ),
            (
                map {
                    my ( $comp, $unit, $sep, $ws ) = $_->@*;
                    my @between = ( ( length $unit ? $unit : () ), ( length $sep ? $sep : () ) );
                    join q{}, q{(}, $comp, q{)},
                      (
                          @between == 1 ? $between[0]
                        : @between == 2 ? q{(?:} . join( q{|}, @between ) . q{)}
                        :                 ()
                      ),
                      $ws;
                } zip( \@comp, \@units, \@sep, \@ws ),
            ),
            ( $want_trim ? '\h*' : () ),
        ) . q{$};

        my $check = $check{$coord};
        {
            qr             => $qr,
            constraint     => qq{\$_ =~ /$qr/ && $check },
            Str_toArrayRef => qq{ do { \$_ =~ /$qr/ ? do { $Match_toArrayRef{$coord} } : \$_ } },
            Str_toDegrees  => <<~"EOS",
                                   do { \$_ =~ /$qr/
                                         ? do {
                                                use experimental 'declared_refs';
                                                local \$_ = $Match_toArrayRef{$coord};
                                                $ArrayReftoDegrees{$coord};
                                              }
                                         : \$_
                                   }
                                  EOS
            ArrayRef_toDegrees => $ArrayReftoDegrees{$coord},
        };
    };
    return $utils;
}

# convert degrees to components










sub from_Degrees ( $angle, $coord ) {

    my $degrees  = $angle;
    my $copysign = !!POSIX::signbit( $degrees );

    if ( $coord eq '-ra' ) {
        $degrees = POSIX::fmod( 360 + POSIX::fmod( abs( $degrees ), 360 ), 360 );
        $degrees /= 15;
        $copysign = !!0;
    }
    elsif ( $coord eq '-lat' or $coord eq '-dec' ) {
        croak( 'illegal argument: must be between [-90,+90]' )
          if abs( $degrees ) > 90;
        $degrees = abs( $degrees );
    }
    elsif ( $coord eq '-neglong' or $coord eq '-negdeg' ) {
        $degrees = POSIX::fmod( 360 + POSIX::fmod( abs( $degrees ), 360 ), 360 );
    }
    else {
        $copysign = !!0;
        $degrees  = POSIX::fmod( 360 + POSIX::fmod( abs( $degrees ), 360 ), 360 );
    }

    my @comp;

    $comp[0] = int( $degrees );
    $degrees -= $comp[0];
    $degrees *= 60;
    $comp[1] = int( $degrees );
    $comp[2] = 60 * ( $degrees - $comp[1] );

    $comp[0] = POSIX::copysign( $comp[0], $angle ) if $copysign;

    return \@comp;
}

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

=for :stopwords Terry Gaetz Diab Jerius Smithsonian Astrophysical Observatory Sexagesimal
mkSexagesimal optsep optunits optws sep unmatchable ws

=head1 NAME

CXC::Types::Astro::Coords::Util - Coordinate Type utilities

=head1 VERSION

version 0.11

=head1 SUBROUTINES

=head2 mkSexagesimal

 %type_components = mkSexagesimal( @flags );

Create components used to create validation and coercion routines for
Sexagesimal types in L<CXC::Types::Astro::Coords>.

The input is a list of flags (strings) which control the type of
quantities to be recognized by the type.  The output is a hash.

The input flags are:

=over

=item * coordinate systems

These flags specify the coordinate system to recognize.  The default is C<-any>.

It determines the accepted ranges on the coordinate components, the
range of the coordinate after adding the components, and the accepted
units for the components:

   +-----------+------------------------------+----------+-----------+
   |  Flag     |      Component's Range       |   Full   |   Units   |
   +-----------+----------+---------+---------+----------+-----------+
   | -ra       |   [0, 23]| [0, 59] | [0 ,60) |  [0,24)  |  h, m, s  |
   +-----------+----------+---------+---------+----------+-----------+
   | -dec      | [-90, 90]| [0, 59] | [0, 60) | [-90,90] |  d, m, s  |
   +-----------+----------+---------+---------+----------+-----------+
   | -deg      |  [0, 359]| [0, 59] | [0, 60) | [0,360)  |  d, m, s  |
   +-----------+----------+---------+---------+----------+-----------+
   | -lat      | [-90, 90]| [0, 59] | [0, 60) | [-90,90] |  d, m, s  |
   +-----------+----------+---------+---------+----------+-----------+
   | -long     |  [0, 359]| [0, 59] | [0, 60) | [0,360)  |  d, m, s  |
   +-----------+----------+---------+---------+----------+-----------+
   | -negdeg   |   none   | [0, 59] | [0, 60) |   none   |  d, m, s  |
   +-----------+----------+---------+---------+----------+-----------+
   | -neglong  |   none   | [0, 59] | [0, 60) |   none   |  d, m, s  |
   +-----------+----------+---------+---------+----------+-----------+
   | -any      |   none   | [0, 59] | [0, 60) |   none   | d|h, m, s |
   +-----------+----------+---------+---------+----------+-----------+

The C<-any> flag assumes that the input is in degrees, unless the C<d> unit
is specified. It always converts hours into degrees.

=item *

B<-units>, B<-optunits>

Unit specification is required or optional.

=item *

B<-sep>, B<-optsep>

The C<:> character between components is required or optional.  If
B<-optsep> is specified,

=item *

B<-ws>, B<-optws>

White space is required or optional between components or I<after> the unit.
White space is never allowed I<before> the unit.

For example

 22h 5m 3.2s

But not

 22 h 5 m 3.2 s

=item *

B<-trim>

leading and trailing white space is ignored.

=back

The following combination of options are flagged as illegal:

 -ws     -sep
 -ws     -optsep
 -sep    -unit
 -sep    -optunit
 -unit   -optsep

Do not specify more than one coordinate system.

Other combinations may be nonsensical and result in an unmatchable
regular expression.  For example, B<-optsep> without
either B<-optws> or B<-optunits> is essentially B<-sep>.

The output is a hash with the following elements:

=over

=item *

B<qr>

A string containing the regular expression to match.  This is I<not> a compiled regular expression.

=item *

B<constraint>

A string containing code suitable to be passed as the B<constraint> parameter to the L<Type::Tiny> constructor.

=item *

B<Str_toArrayRef>

A string containing code suitable to be passed to the L<Type::Util> B<coerce> command, e.g.

=item *

B<ArrayRef_toDegrees>

A string containing code returning the coordinate in degrees.  It the
coordinate components to be available in an array named C<@array>.

=back

=head2 from_Degrees

  \@components = from_Degrees( $degrees, $output_coord );

Convert from degrees to a three element array of the coordinate components.

B<$output_coord> is one of the coordinate systems supported by L</mkSexagesimal>.

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-types-astro-coords@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-Types-Astro-Coords>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-types-astro-coords

and may be cloned from

  https://gitlab.com/djerius/cxc-types-astro-coords.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::Types::Astro::Coords|CXC::Types::Astro::Coords>

=back

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
