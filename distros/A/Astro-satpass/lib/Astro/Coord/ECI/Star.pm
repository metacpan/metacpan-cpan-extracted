=head1 NAME

Astro::Coord::ECI::Star - Compute the position of a star.

=head1 SYNOPSIS

 use Astro::Coord::ECI;
 use Astro::Coord::ECI::Star;
 use Astro::Coord::ECI::Utils qw{deg2rad};
 
 # 1600 Pennsylvania Ave, Washington DC USA
 # latitude 38.899 N, longitude 77.038 W,
 # altitude 16.68 meters above sea level
 my $lat = deg2rad (38.899);    # Radians
 my $long = deg2rad (-77.038);  # Radians
 my $alt = 16.68 / 1000;        # Kilometers
 
 my $star = Astro::Coord::ECI::Star->new (
     name => 'Spica')->position(
     3.51331869544372,    # Right ascension, radians
     -0.194802985206623,  # Declination, radians
 );
 my $sta = Astro::Coord::ECI->
     universal (time ())->
     geodetic ($lat, $long, $alt);
 my ($time, $rise) = $sta->next_elevation ($star);
 print "Star @{[$rise ? 'rise' : 'set']} is ",
     scalar localtime $time, "\n";

=head1 DESCRIPTION

This module implements the position of a star (or any other object
which can be regarded as fixed on the celestial sphere) as a function
of time, as described in Jean Meeus' "Astronomical Algorithms," second
edition. It is a subclass of L<Astro::Coord::ECI|Astro::Coord::ECI>,
with a position() method to set the catalog position (and optionally
proper motion as well), and the time_set() method overridden to compute
the position of the star at the given time.

=head2 Methods

The following methods should be considered public:

=over

=cut

package Astro::Coord::ECI::Star;

use strict;
use warnings;

our $VERSION = '0.081';

use base qw{Astro::Coord::ECI};

use Astro::Coord::ECI::Sun;	# Need for abberation calc.
use Astro::Coord::ECI::Utils qw{:all};
use Carp;
use Data::Dumper;
use POSIX qw{floor strftime};

=item $star = Astro::Coord::ECI::Star->new();

This method instantiates an object to represent the coordinates of a
star, or some other object which may be regarded as fixed on the
celestial sphere. This is a subclass of B<Astro::Coord::ECI>, with the
angularvelocity attribute initialized to zero.

Truth in advertising: The positions produced by this model are about
four arc seconds off Dr. Meeus' worked example for the position of
Theta Persei for Dynamical time November 13.19, 2028. This seems
excessive, but it's difficult to check intermediate results because
this calculation goes through ecliptic coordinates, whereas Dr. Meeus'
worked example is in equatorial coordinates.

=cut

sub new {
    my ($class, @args) = @_;
    ref $class and $class = ref $class;
    return $class->SUPER::new (angularvelocity => 0,
	@args);
}


=item @almanac = $star->almanac($station, $start, $end);

This method produces almanac data for the star for the given observing
station, between the given start and end times. The station is assumed
to be Earth-Fixed - that is, you can not do this for something in orbit.

The C<$station> argument may be omitted if the C<station> attribute has
been set. That is, this method can also be called as

 @almanac = $star->almanac( $start, $end )

The start time defaults to the current time setting of the $star
object, and the end time defaults to a day after the start time.

The almanac data consists of a list of list references. Each list
reference points to a list containing the following elements:

 [0] => time
 [1] => event (string)
 [2] => detail (integer)
 [3] => description (string)

The @almanac list is returned sorted by time.

The following events, details, and descriptions are at least
potentially returned:

 horizon: 0 = star sets, 1 = star rises;
 transit: 1 = star transits meridian;

=cut

sub __almanac_event_type_iterator {
    my ( $self, $station ) = @_;

    my $inx = 0;

    my $horizon = $station->__get_almanac_horizon();

    my $name = $self->get ('name') || $self->get ('id') || 'star';
    my @events = (
	[ $station, next_elevation => [ $self, $horizon, 1 ], 'horizon',
		[ "$name sets", "$name rises"] ],
	[ $station, next_meridian => [ $self ], 'transit',
		[ undef, "$name transits meridian"] ],
    );

    return sub {
	$inx < @events
	    and return @{ $events[$inx++] };
	return;
    };
}

use Astro::Coord::ECI::Mixin qw{ almanac };

=item @almanac = $star->almanac_hash($station, $start, $end);

This convenience method wraps $star->almanac(), but returns a list of
hash references, sort of like Astro::Coord::ECI::TLE->pass()
does. The hashes contain the following keys:

  {almanac} => {
    {event} => the event type;
    {detail} => the event detail (typically 0 or 1);
    {description} => the event description;
  }
  {body} => the original object ($star);
  {station} => the observing station;
  {time} => the time the quarter occurred.

The {time}, {event}, {detail}, and {description} keys correspond to
elements 0 through 3 of the list returned by almanac().

=cut

use Astro::Coord::ECI::Mixin qw{ almanac_hash };


use constant NEVER_PASS_ELEV => 2 * __PACKAGE__->SECSPERDAY;

=item $star = $star->position($ra, $dec, $range, $mra, $mdc, $mrg, $time);

This method sets the position and proper motion of the star in
equatorial coordinates. Right ascension and declination are
specified in radians, and range in kilometers. Proper motion in
range and declination is specified in radians B<per second> (an
B<extremely> small number!), and the proper motion in recession
in kilometers per second.

The range defaults to 1 parsec, which is too close but probably good
enough since we do not take parallax into account when computing
position, and since you can override it with a range (in km!) if you so
desire. The proper motions default to 0. The time defaults to J2000.0,
and is used to set not only the current time of the object but also the
equinox_dynamical. If you are not interested in proper motion but are
interested in time, omit the proper motion arguments completely and
specify time as the fourth argument.

If you call this as a class method, a new Astro::Coord::ECI::Star
object will be constructed. If you call it without arguments, the
position of the star is returned.

Note that this is B<not> simply a synonym for the equatorial() method.
The equatorial() method returns the position of the star corrected for
precession and nutation. This method is used to set the catalog
position of the star in question.

=cut

sub position {
    my ($self, @args) = @_;
    return @{$self->{_star_position}} unless @args;
    $args[2] ||= PARSEC;
    @args < 5 and splice @args, 3, 0, 0, 0, 0;
    $args[3] ||= 0;
    $args[4] ||= 0;
    $args[5] ||= 0;
    $args[6] ||= PERL2000;
    $self = $self->new () unless ref $self;
    $self->{_star_position} = [@args];
    # CAVEAT: time_set() picks the equinox directly out of the above
    # hash.
    $self->dynamical ($args[6]);
    return $self;
}

=item $star->time_set()

This method sets coordinates of the object to the coordinates of the
star at the object's currently-set universal time. Proper motion is
taken into account if this was specified.

Although there's no reason this method can't be called directly, it
exists to take advantage of the hook in the B<Astro::Coord::ECI>
object, to allow the position of the star to be computed when the
time is set.

The computation comes from Jean Meeus' "Astronomical Algorithms", 2nd
Edition, Chapter 23, pages 149ff.

B<Note>, however, that for consistency with the Astro::Coord::ECI::Sun
and ::Moon classes, the position is precessed to the current time
setting.

=cut

use constant CONSTANT_OF_ABERRATION => deg2rad (20.49552 / 3600);

sub time_set {
    my $self = shift;

    $self->{_star_position} or croak <<eod;
Error - The position of the star has not been set.
eod

    my ($ra, $dec, $range, $mra, $mdc, $mrg, $epoch) = @{
	$self->{_star_position}};

    my $time = $self->universal;
    my $end = $self->dynamical;

#	Account for the proper motion of the star, and set our
#	equatorial coordinates to the result.

    my $deltat = $end - $epoch;
    #### $ra += $mra * $deltat;
    $ra = mod2pi($ra + $mra * $deltat);
    $dec += $mdc * $deltat;
    $range += $mrg * $deltat;
    ##!! $self->set (equinox => $epoch);
    $self->equatorial ($ra, $dec, $range);

#	NOTE: The call to precess() used to be here. I have no idea why,
#	other than that I thought I could go back and forth between
#	coordinates less (since I implemented in terms equatorial
#	coordinates). It seems to me at this point (version 0.003_04,
#	25-Oct-2007) that since precessing to a different equinox is
#	actually just a coordinate transform that it should come last.
#	Meeus actually gives the algorithm in ecliptic coordinates also;
#	if the transform could be smart, I could skip a couple
#	coordinate transforms.

#	Get ecliptic coordinates, and correct for nutation.

    my ($beta, $lambda) = $self->ecliptic ();
    my $delta_psi = nutation_in_longitude ($self->dynamical);
    $lambda += $delta_psi;


#	Calculate and add in the abberation terms (Meeus 23.2);

    my $T = jcent2000 ($time);			# Meeus (22.1)
    my $e = (-0.0000001267 * $T - 0.000042037) * $T + 0.016708634;# Meeus (25.4)
    my $pi = deg2rad ((0.00046 * $T + 1.71946) * $T + 102.93735);
    my $sun = $self->{_star_sun} ||= Astro::Coord::ECI::Sun->new ();
    $sun->universal ($time);

    my $geoterm = $sun->geometric_longitude () - $lambda;
    my $periterm = $pi - $lambda;
    my $deltalamda = ($e * cos ($periterm) - cos ($geoterm)) *
	    CONSTANT_OF_ABERRATION / cos ($beta);
    my $deltabeta = - (sin ($geoterm) - $e * sin ($periterm)) * sin ($beta) *
	    CONSTANT_OF_ABERRATION;
    $lambda += $deltalamda;
    $beta += $deltabeta;

    $self->ecliptic ($beta, $lambda, $range);

#	Set the equinox to that implied when our position was set.

    ## $self->set (equinox_dynamical => $epoch);
    $self->equinox_dynamical ($epoch);

#	Precess ourselves to the current equinox.

    $self->precess_dynamical ($end);

    return $self;
}


1;

=back

=head1 ACKNOWLEDGMENTS

The author wishes to acknowledge Jean Meeus, whose book "Astronomical
Algorithms" (second edition) formed the basis for this module.

=head1 SEE ALSO

The L<Astro::Coord::ECI::OVERVIEW|Astro::Coord::ECI::OVERVIEW>
documentation for a discussion of how the pieces/parts of this
distribution go together and how to use them.

L<Astro::Catalog|Astro::Catalog> by Alasdair Allan, which accommodates a
much more fulsome description of a star. The star's coordinates are
represented by an B<Astro::Coords> object.

L<Astro::Coords|Astro::Coords> by Tim Jenness can also be used to find
the position of a star at a given time given a catalog entry for the
star. A wide variety of coordinate representations is accommodated.
This package requires B<Astro::SLA>, which in its turn requires the
SLALIB library.

=head1 AUTHOR

Thomas R. Wyant, III (F<wyant at cpan dot org>)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2017 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
