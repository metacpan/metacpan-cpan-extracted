package Astro::SpaceElevator;
use utf8; # because I'm crazy
use Data::Dumper;

# This module handles all of the details of the ECI coordinate system,
# which is a cartesian system with the origin at the earth's
# center. Also handles conversions from latitude/longitude into ECI
# (based on a reference geoid, not a sphere) and finds the location of
# the sun.
use Astro::Coord::ECI;
use Astro::Coord::ECI::Sun;
use Astro::Coord::ECI::Moon;
use Astro::Coord::ECI::Utils qw{PI rad2deg deg2rad};

# this module lets me do vector and matrix math at a high level, which
# makes the code easier to read.
use Math::MatrixReal 2.02;

=head1 NAME

Astro::SpaceElevator - Model a Space Elevator

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Astro::SpaceElevator;

    my $elevator = Astro::SpaceElevator->new(0, 120, 100_000, time());
    print "The elevator leaves the Earth's shadow at " . ($elevator->shadows->{Earth}{penumbra})[1] . "km above the base.\n";

=head1 METHODS

=head2 new

=over

Creates a new elevator object. Takes four arguments: the latitude, longitude and height (in km) of the elevator, and a time in seconds since the epoch, in the GMT timezone.

=back

=cut

sub new
{
    my ($class, $lat, $lon, $height, $time) = @_;
    $lat = deg2rad $lat;
    $lon = deg2rad $lon;

    my $self = bless({lat    => $lat,
                      lon    => $lon,
                      height => $height,
                     },
                     $class);
    $self->time($time);

    return $self;
}

=head2 time

=over

Gets the time associated with the model. If you supply an argument, it uses that as a new time to update all of the time-dependant aspects of the model.

=back

=cut

sub time
{
    my ($self, $time) = @_;

    if ($time)
    {
        $self->{time} = $time;
        $self->{sun}  = Astro::Coord::ECI::Sun->universal($time);
        $self->{moon} = Astro::Coord::ECI::Moon->universal($time);
        $self->{base} = _geodetic($self->{lat}, $self->{lon}, 0, $time);
    }

    return $self->{time};
}

sub _geodetic
{
    my ($lat, $lon, $elev, $time) = @_;
    return Astro::Coord::ECI->geodetic($lat, $lon, $elev)->universal($time);
}

sub _eci
{
    if (ref $_[0])
    {
        my ($vector, $time) = @_;
        return Astro::Coord::ECI->eci($vector->element(1,1),
                                      $vector->element(2,1),
                                      $vector->element(3,1))->universal($time);
    }
    
    my ($x, $y, $z, $time) = @_;
    return Astro::Coord::ECI->eci($x, $y, $z)->universal($time);
}

sub _vector
{
    my ($x, $y, $z) = @_;
    return Math::MatrixReal->new_from_cols([[$x, $y, $z]]);
}

sub _normalize
{
    my $vec = shift;
    return $vec / $vec->length;    
}

# the names of these next few functions are not necessarily the best
# possible choices, but they're what I could come up with
sub _between
{
    my ($a, $x, $b) = @_;
    return $a if ($x < $a);
    return $x if ($a <= $x and $x <= $b);
    return $b if ($b < $x);
}

sub _clip
{
    my ($a, $x1, $x2, $b) = @_;
    return if (($x1 < $a && $x2 < $a) || ($x1 > $b && $x2 > $b));
    return [_between($a, $x1, $b), _between($a, $x2, $b)];
}

sub _mangle
{
    my ($a, $b, @intersection) = @_;
    my $type = $intersection[0];

    return [] if $type eq 'none';
    return _clip($a, $intersection[-2], $intersection[-1], $b) if $type eq 'segment';
    return [$a, $intersection[-2], $intersection[-1], $b] if $type eq 'invsegment';
    return _clip($a, $intersection[-1], $b, $b) if $type eq 'ray';
    return [(_between($a, $intersection[-1], $b)) x 2];
}

sub _sign
{
    return shift >= 0 ? 1
                      : -1;
}

my $I = Math::MatrixReal->new_diag([1, 1, 1]);

=head2 shadows

=over

Returns a data structure giving the regions of the elevator that are in shadow, and which shadows are causing each region:

    {'Earth' => {'penumbra' => [0, '2466.25270202392'],
                 'umbra' => [0, '2309.7106914426']
                },
     'Moon' => {'penumbra' => [0, '66327.0611755147'],
                'umbra' => ['12691.4616515026', '18869.3918401299']
               }
     'time' => bless([ … ], 'Class::Date'),
    };

=back

=cut

sub shadows
{
    my ($self, $include_lunar) = @_;

    my $time   = $self->{time};
    my $sun    = $self->{sun};
    my $moon   = $self->{moon};
    my $base   = $self->{base};
    my $height = $self->{height};

    my $earth_radius = 3186.3985;
    my $moon_radius = $moon->get('diameter') / 2;
    my $sun_radius = $sun->get('diameter') / 2;

    my $sunV = _vector($sun->eci);
    my $moonV = _vector($moon->eci);

    my $elev_direction = _normalize(_vector(_geodetic($self->{lat}, $self->{lon}, $self->{height}, $time)->eci));
    my $baseV = _vector($base->eci);

    my ($umbra, $penumbra);
    my %data = (Earth => {},
                Moon => {});

    # first we check to see if the sun has risen over the base station.
    my (undef, $elevation, undef) = $base->azel($sun, 1);
    if ($elevation <= 0)
    {
        # Figure out the dimensions of the umbra, which is a function
        # of the Earth's distance from the sun. The penumbra is
        # congruent to the umbra, but reflected around the plane of
        # the terminator. In this case the math simplifies because the
        # terminator goes through the orgin.
        my $umbraV = -$sunV * ($earth_radius / $sun_radius);
        my $umbraA = _normalize($sunV);
        my $umbraΘ = PI/2 + _eci($umbraV, $time)->dip();

        $data{Earth}{umbra} = _mangle(0, $height,
                                      _intersect($umbraV, $umbraA, $umbraΘ,
                                                 $baseV, $elev_direction));
        $data{Earth}{penumbra} = _mangle(0, $height,
                                         _intersect(-$umbraV, -$umbraA, $umbraΘ,
                                                    $baseV, $elev_direction));
    }

    if ($include_lunar)
    {
        # Here the terminator is the Moon's of course.
        my $umbra_temp = ($sunV - $moonV) * ($moon_radius / $sun_radius);
        my $umbraV = -$umbra_temp + $moonV;
        my $penumbraV = $umbra_temp + $moonV;
        my $umbraΘ = PI/2 - atan2($umbraV->length, $moon_radius);

        $data{Moon}{umbra} = _mangle(0, $height,
                                     _intersect($umbraV, _normalize($umbra_temp), $umbraΘ,
                                                $baseV, $elev_direction));
        $data{Moon}{penumbra} = _mangle(0, $height,
                                        _intersect($penumbraV, -_normalize($umbra_temp), $umbraΘ,
                                                   $baseV, $elev_direction));
    }

    return \%data;
}

sub _intersect
{
    # I've taken this algorithm for intersecting lines and cones from
    # http://www.geometrictools.com/Documentation/IntersectionLineCone.pdf,
    # though I'm not rejecting intersections with the anti-cone, as
    # they indicate a transition into an annular eclipse.

    # the cone is defined using a Vertex, an Axis and the angle (Θ)
    # between the axis and the edge of the cone. The axis is a
    # normalized vector that indicates the direction the cone is
    # facing.

    my ($V, $A, $Θ, $P, $D) = @_;
    my $Δ = $P - $V;
    my $M = ($A * ~$A) - ((cos $Θ)**2 * $I);

    my $c0 = (~$Δ * $M * $Δ)->element(1, 1);
    my $c1 = (~$D * $M * $Δ)->element(1, 1);
    my $c2 = (~$D * $M * $D)->element(1, 1);

    if ($c2 != 0)
    {
        my $δ = $c1**2 - $c0*$c2;

        return ('none') if ($δ < 0);
        return ('point', -$c1 / $c2) if ($δ == 0);

        my $t1 = (-$c1 + sqrt($δ)) / $c2;
        my $t2 = (-$c1 - sqrt($δ)) / $c2;

        my $d1 = (($P + $t1*$D) - $V) . $A;
        my $d2 = (($P + $t2*$D) - $V) . $A;

        my $type = (_sign($d1) == _sign($d2)) ? 'segment' : 'invsegment';
        return ($type, $t1, $t2) if ($δ > 0);
    }
    elsif ($c1 != 0)
    {
        my $Pi = $P - ($c0/(2 * $c1)) * $D;
        return ('ray', ($P - $Pi)->length());
    }
    elsif ($c0 != 0)
    {
        return ('empty');
    }
    else
    {
        return ('ray', 0);
    }

    return ('none');
}

=head1 AUTHOR

Daniel Brooks, C<< <db48x at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-astro-spaceelevator at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Astro-SpaceElevator>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT

Copyright © 2007 by Daniel Brooks. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
