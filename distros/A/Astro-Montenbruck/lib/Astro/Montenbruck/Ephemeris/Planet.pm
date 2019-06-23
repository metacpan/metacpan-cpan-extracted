package Astro::Montenbruck::Ephemeris::Planet;
use strict;
use warnings;

use Readonly;
use Math::Trig qw/:pi rad2deg/;
use Astro::Montenbruck::MathUtils qw/frac polar/;

our $VERSION = 0.02;

Readonly our $MO => 'Moon';
Readonly our $SU => 'Sun';
Readonly our $ME => 'Mercury';
Readonly our $VE => 'Venus';
Readonly our $MA => 'Mars';
Readonly our $JU => 'Jupiter';
Readonly our $SA => 'Saturn';
Readonly our $UR => 'Uranus';
Readonly our $NE => 'Neptune';
Readonly our $PL => 'Pluto';

Readonly::Array our @PLANETS =>
  ( $MO, $SU, $ME, $VE, $MA, $JU, $SA, $UR, $NE, $PL );

use Exporter qw/import/;

our %EXPORT_TAGS = ( ids => [qw/$MO $SU $ME $VE $MA $JU $SA $UR $NE $PL/], );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'ids'} }, '@PLANETS' );

sub new {
    my ( $class, %arg ) = @_;
    bless { _id => $arg{id}, }, $class;
}


# from the time derivatives of the polar coordinates (l, b, r)
# derive the components of the velocity vector in ecliptic coordinates
sub _posvel {
    my ( $self, $l, $b, $r, $dl, $db, $dr ) = @_;
    my $cl = cos($l);
    my $sl = sin($l);
    my $cb = cos($b);
    my $sb = sin($b);
    my $x  = $r * $cl * $cb;
    my $vx = $dr * $cl * $cb - $dl * $r * $sl * $cb - $db * $r * $cl * $sb;
    my $y  = $r * $sl * $cb;
    my $vy = $dr * $sl * $cb + $dl * $r * $cl * $cb - $db * $r * $sl * $sb;
    my $z  = $r * $sb;
    my $vz = $dr * $sb + $db * $r * $cb;

    $x, $y, $z, $vx, $vy, $vz;
}

sub _geocentric {
    my ( $self, $t, $hpla_ref, $gsun_ref ) = @_;

    my $m = pi2 * frac( 0.9931266 + 99.9973604 * $t ); # Sun
    # calculate the heliocentric velosity vector, which is required
    # to take account of the various aberration effects.
    my $dls = 172.00 + 5.75 * sin($m);
    my $drs = 2.87 * cos($m);
    my $dbs = 0.0;
    ###
    my ( $dl, $db, $dr ) = $self->_lbr_geo($t);

    # ecliptic geocentric coordinates of the Sun
    my ( $xs, $ys, $zs, $vxs, $vys, $vzs ) =
      $self->_posvel( $gsun_ref->{l}, $gsun_ref->{b}, $gsun_ref->{r}, $dls, $dbs, $drs );
    # ecliptic heliocentric coordinates of the planet
    my ( $xp, $yp, $zp, $vx, $vy, $vz ) =
      $self->_posvel( $hpla_ref->{l}, $hpla_ref->{b}, $hpla_ref->{r}, $dl, $db, $dr );
    my $x = $xp + $xs;
    my $y = $yp + $ys;
    my $z = $zp + $zs;

    # mean heliocentric motion
    my $delta0 = sqrt( $x * $x + $y * $y + $z * $z );
    my $fac    = 0.00578 * $delta0 * 1E-4;

    # apparent
    $x -= $fac * ( $vx + $vxs );
    $y -= $fac * ( $vy + $vys );
    $z -= $fac * ( $vz + $vzs );

    $x, $y, $z # ecliptic geocentric coordinates of the planet
}

sub position {
    my ( $self, $t, $sun, $nut_func ) = @_;
    my ( $l, $b, $r ) = $self->heliocentric($t);
    # geocentric ecliptic coordinates (light-time corrected)
    my ( $rad, $the, $phi ) = polar(
        $nut_func->(
            $self->_geocentric( $t, { l => $l, b => $b, r => $r }, $sun )
        )
    );
    # convert to degrees
    rad2deg($phi), rad2deg($the), $rad;
}

sub heliocentric {
    die "Must be overriden by a descendant";
}

1;
__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::Montenbruck::Ephemeris::Planet - Base class for a planet.

=head1 SYNOPSIS

  package Astro::Montenbruck::Ephemeris::Planet::Mercury;
  use base qw/Astro::Montenbruck::Ephemeris::Planet/;
  ...

  sub  heliocentric {
    # implement the method
  }


=head1 DESCRIPTION

Base class for a planet. Designed to be extended. Used internally in
Astro::Montenbruck::Ephemeris modules. Subclasses must implement B<heliocentric>
method.

=head1 SUBROUTINES/METHODS

=head2 $planet = Astro::Montenbruck::Ephemeris::Planet->new( $id )

Constructor. B<$id> is identifier from C<@PLANETS> array (See L</"EXPORTED CONSTANTS">).

=head2 $self->position($t, $sun)

Geocentric ecliptic coordinates of a planet

=head3 Arguments

=over

=item *

B<$t> — time in Julian centuries since J2000: C<(JD-2451545.0)/36525.0>

=item *

B<$sun> — ecliptic geocentric coordinates of the Sun (hashref with B<'x'>, B<'y'>, B<'z'> keys)

=back

=head3 Returns

Array of geocentric ecliptical coordinates.

=over

=item * longitude, arc-degrees

=item * latitude, arc-degrees

=item * distance from Earth, AU

=back

=head2 $self->heliocentric($t)

Given time in centuries since epoch 2000.0, calculate apparent geocentric
ecliptical coordinates C<($l, $b, $r)>.

=over

=item * B<$l> — longitude, radians

=item * B<$b> — latitude, radians

=item * B<$r> — distance from Earth, A.U.

=back



=head1 EXPORTED CONSTANTS

=over

=item * C<$MO> — Moon

=item * C<$SU> — Sun

=item * C<$ME> — Mercury

=item * C<$VE> — Venus

=item * C<$MA> — Mars

=item * C<$JU> — Jupiter

=item * C<$SA> — Saturn

=item * C<$UR> — Uranus

=item * C<$NE> — Neptune

=item * C<$PL> — Pluto

=item * C<@PLANETS> — array containing all the ids listed above

=back

=head1 AUTHOR

Sergey Krushinsky, C<< <krushi at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Sergey Krushinsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
