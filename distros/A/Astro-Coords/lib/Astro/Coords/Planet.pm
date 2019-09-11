package Astro::Coords::Planet;


=head1 NAME

Astro::Coords::Planet - coordinates relating to planetary motion

=head1 SYNOPSIS

  $c = new Astro::Coords::Planet( 'uranus' );

=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
for planets..

=cut

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.20';

use Astro::PAL ();
use Astro::Coords::Angle;
use base qw/ Astro::Coords /;

use overload '""' => "stringify";

our @PLANETS = qw/ sun mercury venus moon mars jupiter saturn
  uranus neptune /;

# invert the planet for lookup
my $i = 0;
our %PLANET = map { $_, $i++  } @PLANETS;

=head1 METHODS


=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Planet( 'mars' );

Returns undef on error.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $planet = lc(shift);

  return undef unless defined $planet;

  # Check that we have a valid planet
  return undef unless exists $PLANET{$planet};

  bless { planet => $planet,
	  diameter => undef,
	}, $class;

}



=back

=head2 Class Methods

=over 4

=item B<planets>

Retuns a list of supported planet names.

 @planets = Astro::Coords::Planet->planets();

=cut

sub planets {
  return @PLANETS;
}

=back

=head2 Accessor Methods

=over 4

=item B<planet>

Returns the name of the planet.

=cut

sub planet {
  my $self = shift;
  return $self->{planet};
}

=item B<name>

For planets, the name is always just the planet name.

=cut

sub name {
  my $self = shift;
  return $self->planet;
}

=back

=head1 General Methods

=over 4

=item B<array>

Return back 11 element array with first element containing the planet
name.

This method returns a standardised set of elements across all
types of coordinates.

=cut

sub array {
  my $self = shift;
  return ($self->planet, undef, undef,
	  undef, undef, undef, undef, undef, undef, undef, undef);
}

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "RADEC".

This is used to aid construction of summary tables when using
mixed coordinates.

It could be done using isa relationships.

=cut

sub type {
  return "PLANET";
}

=item B<stringify>

Stringify overload. Simple returns the name of the planet
in capitals.

=cut

sub stringify {
  my $self = shift;
  return uc($self->planet());
}

=item B<summary>

Return a one line summary of the coordinates.
In the future will accept arguments to control output.

  $summary = $c->summary();

=cut

sub summary {
  my $self = shift;
  my $name = $self->name;
  $name = '' unless defined $name;
  return sprintf("%-16s  %-12s  %-13s PLANET",$name,'','');
}

=item B<diam>

Returns the apparent angular planet diameter from the most recent calculation
of the apparent RA/Dec.

 $diam = $c->diam();

Returns the answer as a C<Astro::Coords::Angle> object. Note that this
number is not updated automatically. (so don't change the time and expect
to get the correct answer without first asking for a ra/dec calculation).

=cut

sub diam {
  my $self = shift;
  if (@_) {
    my $d = shift;
    $self->{diam} = new Astro::Coords::Angle( $d, units => 'rad' );
  }
  return $self->{diam};
}

=item B<apparent>

Return the apparent RA and Dec as two C<Astro::Coords::Angle> objects for the current
coordinates and time.

 ($ra_app, $dec_app) = $self->apparent();

=cut

sub apparent {
  my $self = shift;

  my ($ra_app, $dec_app) = $self->_cache_read( "RA_APP", "DEC_APP" );

  # Need to calculate it
  if (!defined $ra_app || !defined $dec_app) {

    my $tel = $self->telescope;
    my $long = (defined $tel ? $tel->long : 0.0 );
    my $lat = (defined $tel ? $tel->lat : 0.0 );

    ($ra_app, $dec_app, my $diam) = Astro::PAL::palRdplan($self->_mjd_tt, $PLANET{$self->planet},
                                                          $long, $lat );

    # Store the diameter
    $self->diam( $diam );

    # Convert to angle objects
    $ra_app = new Astro::Coords::Angle::Hour($ra_app, units => 'rad', range => '2PI');
    $dec_app = new Astro::Coords::Angle($dec_app, units => 'rad');

    # store in cache
    $self->_cache_write( "RA_APP" => $ra_app, "DEC_APP" => $dec_app );
  }

  return ($ra_app, $dec_app);
}

=item B<rv>

Radial velocity of the planet relative to the Earth geocentre.

=cut

sub rv {
  croak "Not yet implemented planetary radial velocities";
}

=item B<vdefn>

Velocity definition. Always 'RADIO'.

=cut

sub vdefn {
  return 'RADIO';
}

=item B<vframe>

Velocity reference frame. Always 'GEO'.

=cut

sub vframe {
  return 'GEO';
}

=item B<apply_offset>

Overrided method to warn if C<Astro::Coords::apply_offset> is
called on this subclass.

=cut

sub apply_offset {
  my $self = shift;
  warn "apply_offset: applying offset to planet position for a specific time.\n";
  return $self->SUPER::apply_offset(@_);
}

=back

=begin __PRIVATE_METHODS__

=over 4

=item B<_default_horizon>

Internal helper method for C<rise_time> and C<set_time>. Returns the
default horizon. For the sun returns Astro::Coords::SUN_RISE_SET.  For
the Moon returns:

  -(  0.5666 deg + moon radius + moon's horizontal parallax )

       34 arcmin    15-17 arcmin    55-61 arcmin           =  4 - 12 arcmin

[see the USNO pages at: http://aa.usno.navy.mil/faq/docs/RST_defs.html]

For all other planets returns 0.

Note that the moon calculation requires that the date stored in the object
is close to the date for which the rise/set time is required.

The USNO web page is quite confusing on the definition for the moon since
in one place it implies that the moonrise occurs when the centre of the moon
is above the horizon by 5-10 arcminutes (the above calculation) but on the
moon data page comparing moonrise with tables for a specific day indicates a
moonrise of -48 arcminutes.

=cut

sub _default_horizon {
  my $self = shift;
  my $name = lc($self->name);

  if ($name eq 'sun') {
    return &Astro::Coords::SUN_RISE_SET;
  } elsif ($name eq 'moon') {
    return (-0.8 * Astro::PAL::DD2R);
    # See http://aa.usno.navy.mil/faq/docs/RST_defs.html
    my $refterm = 0.5666 * Astro::PAL::DD2R; # atmospheric refraction

    # Get the moon radius
    $self->_apparent();
    my $radius = $self->diam() / 2;

    # parallax - assume 57 arcminutes for now
    my $parallax = (57 * 60) * Astro::PAL::DAS2R;

    print "Refraction: $refterm  Radius: $radius  Parallax: $parallax\n";

    return ( -1 * ( $refterm + $radius - $parallax ) );
  } else {
    return 0;
  }
}

=item B<_sidereal_period>

Returns the length of the source's "day" in seconds.

=cut

sub _sidereal_period {
  my $self = shift;
  my $name = lc($self->name);

  if ($name eq 'sun') {
    return 24 * 3600;
  } elsif ($name eq 'moon') {
    return 24 * 3600 * (1 + 1 / 29.53059);
  }
  else {
    $self->SUPER::_sidereal_period();
  }
}

=back

=end __PRIVATE_METHODS__

=head1 NOTES

Usually called via C<Astro::Coords>.

=head1 REQUIREMENTS

C<Astro::PAL> is used for all internal astrometric calculations.

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=cut

1;
