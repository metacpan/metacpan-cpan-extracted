package Astro::Coords::Fixed;

=head1 NAME

Astro::Coords::Fixed - Manipulate coordinates that are fixed on the sky

=head1 SYNOPSIS

  $c = new Astro::Coords::Fixed( az => 180,
                                 el => 45,
				 units => 'degrees');

  $c = new Astro::Coords::Fixed( ha => '02:30:00.0',
				 dec => '45:30:03',
				 units => 'sexagesimal',
				 tel => $telescope,
			       );

=head1 DESCRIPTION

This subclass of C<Astro::Coords> allows for the manipulation
of coordinates that are fixed on the sky. Sometimes a telescope
should be commanded to go to a fixed location (eg for a calibration)
and this class puts those coordinates (Azimuth and elevation for telescopes
such as JCMT and Gemini and Hour Angle and Declination for equatorial
telescopes such as UKIRT) on the same footing as astronomical coordinates.

Note that Azimuth and elevation do not require the telescope latitude
whereas Hour Angle and declination does.

=cut


use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.21';

use Astro::PAL ();
use Astro::Coords::Angle;
use base qw/ Astro::Coords /;

use overload '""' => "stringify";

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Constructor. Recognizes hash keys "ha", "dec" and "az", "el".

  $c = new Astro::Coords::Fixed( az => 35, el => 30 );

  $c = new Astro::Coords::Fixed( ha => $ha, dec => $dec, tel => $tel);

Usually called via C<Astro::Coords> rather than directly.

Note that the declination is equivalent to "Apparent Dec" used
elsewhere in these classes.

Azimuth and Elevation is the internal format. Currently there is no
caching (so there is always overhead converting to apparent
RA and Dec) since there is no cache flushing when the telescope
is changed.

A telescope is required (in the form of an C<Astro::Telescope> object)
if the position is specified as HA/Dec.

A reference to a 2-element array can be given to specify different units
for the two coordinates, e.g. C<['hours', 'degrees']>.

A name can be associated with this position.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  # We will always calculate ha, dec, az and el
  my ($az, $el);

  # Create a new object
  my $c = bless { }, $class;

  # Store the telescope if we have one
  $c->telescope( $args{tel} ) if exists $args{tel};

  my ($unit_c1, $unit_c2) = (ref $args{'units'}) ? @{$args{'units'}} : ($args{'units'}) x 2;

  if (exists $args{ha} && exists $args{dec} and exists $args{tel}
     and UNIVERSAL::isa($args{tel}, "Astro::Telescope")) {
    # HA and Dec

    # Convert input args to radians
    my $ha = Astro::Coords::Angle::Hour->to_radians($args{ha}, $unit_c1);
    my $dec = Astro::Coords::Angle->to_radians($args{dec}, $unit_c2);

    # Convert to "native" format
    my $lat = $args{tel}->lat;
    ($az, $el) = Astro::PAL::palDe2h( $ha, $dec, $lat );

    $az = new Astro::Coords::Angle( $az, units => 'rad', range => '2PI');
    $el = new Astro::Coords::Angle( $el, units => 'rad');

    # native form
    $c->native( 'hadec' );

  } elsif (exists $args{az} and exists $args{el}) {
    # Az and El

    # Convert input args to radians
    $az = new Astro::Coords::Angle( $args{az}, units => $unit_c1,
				    range => '2PI' );
    $el = new Astro::Coords::Angle( $args{el}, units => $unit_c2);

    # native form
    $c->native( 'azel' );

  } else {
    return undef;
  }

  # Store the name
  $c->name( $args{name} ) if exists $args{name};

  # Store it in the object
  $c->azel( $az, $el );

  return $c;
}


=back

=head2 Accessor Methods

=over 4

=item B<azel>

Return azimuth and elevation (as two C<Astro::Coords::Angle> objects);

 ($az, $el) = $c->azel;

Can also be used to store the azimuth and elevation
(as C<Astro::Coords::Angle> objects)

  $c->_azel( $az, $el);

=cut

sub azel {
  my $self = shift;
  if (@_) {
    my ($az, $el) = @_;
    croak "Azimuth not an Astro::Coords::Angle object"
      unless UNIVERSAL::isa( $az, "Astro::Coords::Angle");
    croak "Elevation not an Astro::Coords::Angle object"
      unless UNIVERSAL::isa( $el, "Astro::Coords::Angle");
    $self->{Az} = $az;
    $self->{El} = $el;
  }
  return ($self->{Az}, $self->{El});
}

=back

=head2 General Methods

=over 4

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "FIXED".

This is used to aid construction of summary tables when using
mixed coordinates.

=cut

sub type {
  return "FIXED";
}

=item B<stringify>

Returns a string representation of the object. Returns
Azimth and Elevation in degrees.

=cut

sub stringify {
  my $self = shift;
  my $az = $self->az( format => "degrees" );
  my $el = $self->el( format => "degrees" );
  return "$az $el";
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
  return sprintf("%-16s  %-12s  %-13s   AZEL",$name,
		 $self->az(format=>"s"),
		 $self->el(format =>"s"));
}

=item B<array>

Array summarizing the object. Retuns
Return back 11 element array with first 3 elements being the
coordinate type (FIXED) and the az/el coordinates
(radians).

This method returns a standardised set of elements across all
types of coordinates.

=cut

sub array {
  my $self = shift;
  my ($az, $el) = $self->azel();
  return ( $self->type, $az->radians, $el->radians,
	   undef, undef, undef, undef, undef, undef, undef, undef);
}

=item B<ha>

Get the hour angle for the currently stored LST. By default
returns format as for other angular methods.

  $ha = $c->ha;
  $ha = $c->ha( format => "deg" );

=cut

sub ha {
  my $self = shift;
  my %opt = @_;
  my $ha = ($self->hadec)[0];
  return $ha->in_format( $opt{format} );
}

=item B<apparent>

Return the apparent RA and Dec (as two C<Astro::Coords::Angle> objects)
for the current time [note that the apparent declination
is fixed and the apparent RA changes].

If no telescope is present the equator is used.

=cut

sub apparent {
  my $self = shift;

  my ($ra_app, $dec_app) = $self->_cache_read( "RA_APP", "DEC_APP" );

  if (!defined $ra_app || !defined $dec_app) {

    (my $ha, $dec_app) = $self->hadec;
    $ra_app = $self->_lst - $ha->radians;
    $ra_app = new Astro::Coords::Angle::Hour( $ra_app, units => 'rad', range => '2PI' );

    # should not cache the DEC_APP since we did not calculate it
    $self->_cache_write( "RA_APP" => $ra_app );
  }

  return( $ra_app, $dec_app);
}

=item B<hadec>

Return the Hour angle and apparent declination (as two C<Astro::Coords::Angle> objects).
If no telescope is present the equator is used.

 ($ha, $dec) = $c->hadec;

=cut

sub hadec {
  my $self = shift;

  my ($ha, $dec_app) = $self->_cache_read( "HA", "DEC_APP" );

  if (!defined $ha || !defined $dec_app) {

    my ($az, $el) = $self->azel;
    my $tel = $self->telescope;
    my $lat = ( defined $tel ? $tel->lat : 0.0);

    # First need to get the hour angle and declination from the Az and El
    ($ha, $dec_app) = Astro::PAL::palDh2e($az->radians, $el->radians, $lat );

    $ha = new Astro::Coords::Angle::Hour( $ha, units => 'rad', range => 'PI');
    $dec_app = new Astro::Coords::Angle( $dec_app, units => 'rad');

    $self->_cache_write( "HA" => $ha, "DEC_APP" => $dec_app );
  }

  return ($ha, $dec_app);
}

=item B<ha_set>

For a fixed source, the setting Hour Angle has no meaning.

=cut

sub ha_set {
  return ();
}

=item B<meridian_time>

Meridian time is not defined for a fixed source.

=cut

sub meridian_time {
  return ();
}

=item B<transit_el>

Transit elevation is not defined for a fixed source. Always returns undef.

=cut

sub transit_el {
  return ();
}

=item B<apply_offset>

Overrided method to prevent C<Astro::Coords::apply_offset> being
called on this subclass.

=cut

sub apply_offset {
  croak 'apply_offset: attempting to apply an offset to fixed coordinates';
}

=back

=head1 NOTES

Usually called via C<Astro::Coords>.

=head1 REQUIREMENTS

C<Astro::PAL> is used for all internal astrometric calculations.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

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
