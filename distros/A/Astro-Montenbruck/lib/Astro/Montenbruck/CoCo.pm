package Astro::Montenbruck::CoCo;

use strict;
use warnings;
use Exporter qw/import/;
use POSIX qw /tan atan2 asin acos/;
use Astro::Montenbruck::MathUtils qw/reduce_rad/;
use Math::Trig qw/:pi deg2rad rad2deg/;
use Readonly;

Readonly::Scalar our $ECL => 1;
Readonly::Scalar our $EQU => 2;

our %EXPORT_TAGS = (
    all => [ qw/ecl2equ equ2ecl equ2hor hor2equ ecl2equ_rect equ2ecl_rect/ ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, qw/$ECL $EQU/ );

our $VERSION = 0.01;

# Common routine for coordinate conversion
# $target = $ECL (1) for equator -> ecliptic
# $target = $EQU (2) for ecliptic -> equator
sub _equecl {
    my ( $x, $y, $e, $target ) = @_;
    my $k = $target == $ECL ? 1
                            : $target == $EQU ? -1 : 0;
    die "Unknown target: '$target'! \n" until $k;

    my $sin_a = sin($x);
    my $cos_e = cos($e);
    my $sin_e = sin($e);
    reduce_rad(atan2( $sin_a * $cos_e + $k * ( tan($y) * $sin_e ), cos($x) )),
      asin( sin($y) * $cos_e - $k * ( cos($y) * $sin_e * $sin_a ) );
}


sub equ2ecl {
    map { rad2deg $_ } _equecl( ( map { deg2rad $_ } @_ ), $ECL );
}

sub ecl2equ {
    map { rad2deg $_ } _equecl( ( map { deg2rad $_ } @_ ), $EQU );
}


# Converts between azimuth/altitude and hour-angle/declination.
# The equations are symmetrical in the two pairs of coordinates so that exactly
# the same code may be used to convert in either direction, there is no need
# to specify direction with a swich.
sub _equhor {
    my ($x, $y, $phi) = @_;
    my ($sx, $sy, $sphi) = map{ sin } ($x, $y, $phi);
    my ($cx, $cy, $cphi) = map{ cos } ($x, $y, $phi);

    my $sq = ($sy * $sphi) + ($cy * $cphi * $cx);
    my $q = asin($sq);
    my $cp = ($sy - ($sphi * $sq)) / ($cphi * cos($q));
    my $p = acos($cp);
    if ($sx > 0) {
        $p = pi2 - $p;
    }
    ($p, $q)
}

sub equ2hor {
    map {rad2deg $_} _equhor( map { deg2rad $_ } @_ )
}

sub hor2equ {
    equ2hor(@_)
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::CoCo - Coordinates conversions.

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Celestial sphera related calculations used by AstroScript modules.

=head1 EXPORT

=over

=item * L</equ2ecl($alpha, $delta, $epsilon)>

=item * L</ecl2equ($lambda, $beta, $epsilon)>

=back

=head1 FUNCTIONS

=head2 equ2ecl($alpha, $delta, $epsilon)

Conversion of equatorial into ecliptic coordinates

=head3 Arguments

=over

=item * B<$alpha> — right ascension

=item * B<$delta> — declination

=item * B<$epsilon> — ecliptic obliquity

=back

=head3 Returns

Ecliptic coordinates:

=over

=item * B<$lambda>

=item * B<$beta>

=back

All arguments and return values are in degrees.

=head2 ecl2equ($lambda, $beta, $epsilon)

Conversion of ecliptic into equatorial coordinates

=head3 Arguments

=over

=item * B<$lambda> — celestial longitude

=item * B<$beta> — celestial latitude

=item * B<$epsilon> — ecliptic obliquity

=back

=head3 Returns

Equatorial coordinates:

=over

=item * B<$alpha> — right ascension

=item * B<$delta> — declination

=back

All arguments and return values are in degrees.


=head2 equ2hor($h, $delta, $phi)

Conversion of equatorial into horizontal coordinates

=head3 Arguments

=over

=item *

B<$h> — the local hour angle, in degrees, measured westwards from the South.
C<h = Local Sidereal Time - Right Ascension>

=item *

B<$delta> — declination, in arc-degrees

=item *

B<$phi> — the observer's latitude, in arc-degrees, positive in the nothern
hemisphere, negative in the southern hemisphere.

=back

=head3 Returns

Horizontal coordinates:

=over

=item * B<azimuth>, in degrees, measured westward from the South

=item * B<altitude>, in degrees, positive above the horizon

=back

=head2 hor2equ($az, $alt, $phi)

Convert horizontal to equatorial coordinates.

=head3 Arguments

=over

=item *

B<$az> — azimuth, in degrees, measured westward from the South

=item *

B<$alt> — altitude, in degrees, positive above the horizon

=item *

B<$phi> — the observer's latitude, in arc-degrees, positive in the nothern
hemisphere, negative in the southern hemisphere.

=back

=head3 Returns

Horizontal coordinates:

=over

=item * hour angle, in arc-degrees

=item * declination, in arc-degrees

=back


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Astro::Montenbruck::CoCo

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2020 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
