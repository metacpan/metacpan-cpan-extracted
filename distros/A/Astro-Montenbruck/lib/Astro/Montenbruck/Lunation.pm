package Astro::Montenbruck::Lunation;

use strict;
use warnings;

use Exporter qw/import/;
use Readonly;
use Math::Trig qw/deg2rad/;
use List::Util qw/any reduce/;
use List::MoreUtils qw/zip_unflatten/;
use Astro::Montenbruck::MathUtils qw/reduce_deg polynome/;
use Astro::Montenbruck::Time qw/is_leapyear day_of_year/;

Readonly our $NEW_MOON      => 'New Moon';
Readonly our $FIRST_QUARTER => 'First Quarter';
Readonly our $FULL_MOON     => 'Full Moon';
Readonly our $LAST_QUARTER  => 'Last Quarter';

Readonly::Array our @MONTH => ($NEW_MOON, $FIRST_QUARTER, $FULL_MOON, $LAST_QUARTER);
Readonly our @QUARTERS => qw/$NEW_MOON $FIRST_QUARTER $FULL_MOON $LAST_QUARTER @MONTH/;

my @funcs = qw/mean_phase search_event/;


our %EXPORT_TAGS = (
    quarters  => \@QUARTERS,
    functions => \@funcs,
    all       => [ @QUARTERS, @funcs ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION   = 0.03;



Readonly::Array my @NEW_MOON_TERMS => (
    -0.40720, 0.17241,  0.01608,  0.01039,  0.00739,  -0.00514,
    0.00208,  -0.00111, -0.00057, 0.00056,  -0.00042, 0.00042,
    0.00038,  -0.00024, -0.00017, -0.00007, 0.00004,  0.00004,
    0.00003,  0.00003,  -0.00003, 0.00003,  -0.00002, -0.00002,
    0.00002
);

Readonly::Array my @FULL_MOON_TERMS => (
    -0.40614, 0.17302,  0.01614,  0.01043,  0.00734,  -0.00515,
    0.00209,  -0.00111, -0.00057, 0.00056,  -0.00042, 0.00042,
    0.00038,  -0.00024, -0.00017, -0.00007, 0.00004,  0.00004,
    0.00003,  0.00003,  -0.00003, 0.00003,  -0.00002, -0.00002,
    0.00002
);

Readonly::Array my @QUARTER_TERMS => (
    -0.62801, 0.17172,  -0.01183, 0.00862,  0.00804,  0.00454,
    0.00204,  -0.00180, -0.00070, -0.00040, -0.00034, 0.00032,
    0.00032,  -0.00028, 0.00027,  -0.00017, -0.00005, 0.00004,
    -0.00004, 0.00004,  0.00003,  0.00003,  0.00002,  0.00002,
    -0.00002
);

Readonly::Array my @A_TERMS => (
    [ 251.88, 0.016321 ],
    [ 251.83, 26.651886 ],
    [ 349.42, 36.412478 ],
    [ 84.66,  18.206239 ],
    [ 141.74, 53.303771 ],
    [ 207.14, 2.453732 ],
    [ 154.84, 7.306860 ],
    [ 34.52,  27.261239 ],
    [ 207.19, 0.121824 ],
    [ 291.34, 1.844379 ],
    [ 161.72, 24.198154 ],
    [ 239.56, 25.513099 ],
    [ 331.55, 3.592518 ]
);


Readonly::Array my @A_CORR => (
    0.000325, 0.000165, 0.000164, 0.000126, 0.000110, 0.000062,
    0.000060, 0.000056, 0.000047, 0.000042, 0.000040, 0.000037,
    0.000035, 0.000023
);

Readonly::Array my @MANOM_SUN => ( 2.5534, 29.1053567, -1.4e-06, -1.1e-07 ); # Sun's mean anomaly
Readonly::Array my @MANOM_MOO => ( 201.5643, 385.81693528, 0.0107582, 1.238e-05, -5.8e-08 ); # Moon's mean anomaly
Readonly::Array my @ARGLA_MOO => ( 160.7108, 390.67050284, -0.0016118, -2.27e-06, -1.1e-08 ); # Moon's argument of latitude
Readonly::Array my @LONND_MOO => ( 124.7746, -1.56375588, 0.0020672, 2.15e-06 ); # Longitude of the ascending node)

Readonly::Hash our %QUARTER => (
    $NEW_MOON => {
        fraction => 0.0,
        terms    => \@NEW_MOON_TERMS
    },
    $FIRST_QUARTER => {
        fraction => 0.25,
        terms    => \@QUARTER_TERMS
    },
    $FULL_MOON => {
        fraction => 0.5,
        terms    => \@FULL_MOON_TERMS
    },
    $LAST_QUARTER => {
        fraction => 0.75,
        terms    => \@QUARTER_TERMS
    },
);



sub _mean_phase {
    my ( $date, $fraction ) = @_;

    my $n = is_leapyear( $date->[0] ) ? 366 : 365;
    my $y = $date->[0] + day_of_year(@$date) / $n;
    sprintf( '%.0f', ( $y - 2000 ) * 12.3685 ) + $fraction;
}

sub _mean_orbit {
    my ($k, $t) = @_;

    polynome( $t, 1, -2.516e-3, -7.4e-06 ),
    map {
        my @terms = @$_;
        reduce_deg(
            polynome( $t, $terms[0] + $terms[1] * $k, @terms[ 2 .. $#terms ] )
        )
    } ( \@MANOM_SUN, \@MANOM_MOO, \@ARGLA_MOO, \@LONND_MOO )
}

sub _mean_jde {
    my ($k, $t) = @_;

    polynome(
        $t,
        2451550.09766 + 29.530588861 * $k,
        0.00015437,
        1.5e-07,
        7.3e-10
    );
}

sub search_event {
    my ( $date, $quarter ) = @_;

    my $q = $QUARTER{$quarter};
    my $k = _mean_phase( $date, $q->{fraction} );
    my $t  = $k / 1236.85;

    # JDE
    my $j = _mean_jde($k, $t);
    my ( $E, $MS, $MM, $F, $N ) = _mean_orbit($k, $t);
    my $EE = $E * $E;
    my @A  = (
        299.77 + 0.107408 * $k - 0.009173 * $t * $t,
        map { polynome($k, @$_) } @A_TERMS
    );

    my $mm2 = $MM + $MM;
    my $ms2 = $MS + $MS;
    my $mm3 = $mm2 + $MM;
    my $ms3 = $ms2 + $MS;
    my $f2  = $F + $F;

    my @si = do {
        if ( $quarter eq $NEW_MOON || $quarter eq $FULL_MOON ) {
            (
                $MM,
                $MS,
                $mm2,
                $f2,
                $MM - $MS,
                $MM + $MS,
                $ms2,
                $MM - $f2,
                $MM + $f2,
                $mm2 * $F,
                $mm2 + $MS,
                $mm3,
                $MS + $f2,
                $MS - $f2,
                $mm2 - $MS,
                $N,
                $MM + $ms2,
                $mm2 - $f2,
                $ms3,
                $MM + $MS - $f2,
                $mm2 + $f2,
                $MM + $MS + $f2,
                $MM - $MS + $f2,
                $MM - $MS - $f2,
                $mm3 + $MS,
                $mm2 + $mm2
              )
        }
        else {
            (
                $MM,
                $MS,
                $MM + $MS,
                $mm2,
                $f2,
                $MM - $MS,
                $ms2,
                $MM - $f2,
                $MM + $f2,
                $mm3,
                $mm2 - $MS,
                $MS + $f2,
                $MS - $f2,
                $MM + $ms2,
                $mm2 + $MS,
                $N,
                $MM - $MS - $f2,
                $mm2 + $f2,
                $MM + $MS + $f2,
                $MM - $ms2,
                $MM + $MS - $f2,
                $ms3,
                $mm2 - $f2,
                $MM - $MS + $f2,
                $mm3 + $MS
              )
        }
    };

    my @rsi = map { sin( deg2rad($_) ) } @si;
    my @terms = grep { defined $_->[0] && defined $_->[1] }
      zip_unflatten( @{ $q->{terms} }, @rsi );
    my $s = 0;
    while ( my ( $i, $item ) = each @terms ) {
        my ( $x, $y ) = @$item;
        if ( $quarter eq $NEW_MOON || $quarter eq $FULL_MOON ) {
            if ( any { $i == $_ } ( 1, 4, 5, 9, 11, 12, 13 ) ) {
                $x *= $E;
            }
            elsif ( $i == 6 ) {
                $x *= $EE;
            }
        }
        else {
            if ( any { $i == $_ } ( 1, 2, 5, 10, 11, 12, 14 ) ) {
                $x *= $E;
            }
            elsif ( $i = 6 || $i == 13 ) {
                $x *= $EE;
            }
        }
        $s += $x * $y;
    }
    $j += $s;

    if ( $quarter eq $FIRST_QUARTER || $quarter eq $LAST_QUARTER ) {
        my ( $mm, $ms, $f ) = map { deg2rad($_) } ( $MM, $MS, $F );
        my $w =
          0.00306 - 0.00038 * cos($ms) +
          0.00026 * cos($mm) -
          2e-05 * cos( $ms + $mm ) +
          2e-05 * cos( $f + $f );
        $w = -$w if $quarter eq $LAST_QUARTER;
        $j += $w;
    }

    $s = reduce {
        $a + $b->[1] * sin( deg2rad( $b->[0] ) )
    }
    0, zip_unflatten( @A, @A_CORR );
    $j += $s;
    wantarray ? ($j, $F) : $j
}


sub is_eclipse_possible {
    my $f = shift;
    my $s = sin(deg2rad($f));
    return 0 if abs $s > 0.36; # no eclipse
    1;
}


1;
__END__


=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Lunation - Lunar quarters.

=head1 SYNOPSIS

  use Astro::Montenbruck::Lunation qw/:all/;

  # find instant of New Moon closest to 2019 Aug, 12
  $jd = search_event([2019, 8, 12], $NEW_MOON)


=head1 DESCRIPTION

Searches lunar quarters. Algorythms are based on
I<"Astronomical Algorythms"> by I<Jean Meeus>, I<Second Edition>, I<Willmann-Bell, Inc., 1998>.


=head1 EXPORT

=head2 CONSTANTS

=head3 QUARTERS

=over

=item * C<$NEW_MOON>

=item * C<$FIRST_QUARTER>

=item * C<$FULL_MOON>

=item * C<$LAST_QUARTER>

=back

=head3 MONTH

=over

=item * C<@MONTH> 

=back

Array of L<QUARTERS> in proper order.


=head1 SUBROUTINES

=head2 search_event(date => $arr, quarter => $scalar)

Calculate instant of apparent lunar phase closest to the given date.

=head3 Named Arguments

=over

=item * B<date> — array of B<year> (astronomical, zero-based), B<month> [1..12]
and B<day>, [1..31].

=item * B<quarter> — which quarter, one of: C<$NEW_MOON>, C<$FIRST_QUARTER>,
C<$FULL_MOON> or C<$LAST_QUARTER> see L</QUARTERS>.

=back

=head3 Returns

In scalar context returns I<Standard Julian day> of the event, dynamic time.

In list context:

=over

=item * I<Standard Julian day> of the event, dynamic time.

=item * Argument of latitude, arc-degrees. This value is required for detecting elipses.

=back



=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2021 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
