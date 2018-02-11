package Astro::Coords::Interpolated;


=head1 NAME

Astro::Coords::Interpolated - Specify astronomical coordinates using two reference positions

=head1 SYNOPSIS

  $c = new Astro::Coords::Interpolated( ra1 => '05:22:56',
					dec1 => '-26:20:44.4',
					mjd1 => 52440.5,
					ra2 => '05:23:56',
					dec2 => '-26:20:50.4',
					mjd2 => 52441.5,);

=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
for moving sources specified as two coordinates at two epochs.

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.19';

use base qw/ Astro::Coords /;

use overload '""' => "stringify";

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Interpolated( ra1 => '05:22:56',
					dec1 => '-26:20:44.4',
					mjd1 => 52440.5,
					ra2 => '05:23:56',
					dec2 => '-26:20:50.4',
					mjd2 => 52441.5,
					units =>
				      );

Returns undef on error. The positions are assumed to be apparent
RA/Dec for the telescope location. Units are optional (see
C<Astro::Coords::Equatorial>).

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  # Sanity check
  for (qw/ ra1 dec1 mjd1 ra2 dec2 mjd2 /) {
    return undef unless exists $args{$_};
  }

  # Convert input args to objects
  $args{ra1} = new Astro::Coords::Angle::Hour($args{ra1}, units => $args{units},
					      range => '2PI' );
  $args{dec1} = new Astro::Coords::Angle($args{dec1}, units => $args{units} );
  $args{ra2} = new Astro::Coords::Angle::Hour($args{ra2}, units => $args{units},
					      range => '2PI' );
  $args{dec2} = new Astro::Coords::Angle($args{dec2}, units => $args{units} );

  return bless \%args, $class;

}


=back

=head2 Accessor Methods

=over 4

=item B<ra1>

Apparent Right Ascension of first reference position.

  $ra = $c->ra1( %opts );

See L<Astro::Coords/"NOTES"> for details on the supported format
specifiers and default calling convention.

=cut

sub ra1 {
  my $self = shift;
  my %opt = @_;
  my $retval = $self->{ra1}->in_format( $opt{format} );

  # Tidy up array
  shift(@$retval) if ref($retval) eq "ARRAY";
  return $retval;
}

=item B<dec1>

Apparent declination of first reference position.

  $dec = $c->dec1( format => "sexagesimal" );

See L<Astro::Coords/"NOTES"> for details on the supported format
specifiers and default calling convention.

=cut

sub dec1 {
  my $self = shift;
  my %opt = @_;
  return $self->{dec1}->in_format( $opt{format} );
}

=item B<mjd1>

Time (MJD) when the first reference position was valid.

=cut

sub mjd1 {
  my $self = shift;
  return $self->{mjd1};
}

=item B<ra2>

Apparent Right Ascension of second reference position.

  $ra = $c->ra2( format => 'rad' );

See L<Astro::Coords/"NOTES"> for details on the supported format
specifiers and default calling convention.

=cut

sub ra2 {
  my $self = shift;
  my %opt = @_;
  my $retval = $self->{ra2}->in_format( $opt{format} );

  # Tidy up array
  shift(@$retval) if ref($retval) eq "ARRAY";
  return $retval;
}

=item B<dec2>

Apparent declination of second reference position.

  $dec = $c->dec2( format => "sexagesimal" );

See L<Astro::Coords/"NOTES"> for details on the supported format
specifiers and default calling convention.

=cut

sub dec2 {
  my $self = shift;
  my %opt = @_;
  return $self->{dec2}->in_format( $opt{format} );
}

=item B<mjd2>

Time (MJD) when the second reference position was valid.

=cut

sub mjd2 {
  my $self = shift;
  return $self->{mjd2};
}

=back

=head1 General Methods

=over 4

=item B<array>

Return back 11 element array with first element containing the
string "INTERP", the next ten elements as undef.

This method returns a standardised set of elements across all
types of coordinates.

The original design did not contain this type of coordinate specification
and so the array returned can not yet include it. Needs more work to integrate
into the other coordinate systems.

=cut

sub array {
  my $self = shift;
  return ( $self->type, undef, undef,
	   undef,undef,undef,undef,undef,undef,undef,undef);
}

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "INTERP".

This is used to aid construction of summary tables when using
mixed coordinates.

It could be done using isa relationships.

=cut

sub type {
  return "INTERP";
}

=item B<stringify>

Stringify overload. Just returns the type.

=cut

sub stringify {
  my $self = shift;
  return $self->type;
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
  return sprintf("%-16s  %-12s  %-13s INTERP",$name,'','');
}

=item B<apparent>

Return the apparent RA and Dec (as two C<Astro::Coords::Angle> objects) for the current
coordinates and time.

  ($ra,$dec) = $c->apparent();

Apparent RA/Dec is obtained by linear interpolation from the reference
positions. If the requested time lies outside the reference times
the position will be extrapolated.

=cut

sub apparent {
  my $self = shift;

  my $mjd1 = $self->mjd1;
  my $mjd2 = $self->mjd2;

  my ($ra_app, $dec_app);

  if ($mjd1 == $mjd2) {
    # special case when times are identical

    $ra_app = $self->{ra1};
    $dec_app = $self->{dec1};
  }
  else {
    # else linear interpolation

    my $mjd = $self->datetime->mjd;
    my $ra1  = $self->ra1->radians;
    my $ra2  = $self->ra2->radians;
    my $dec1 = $self->dec1->radians;
    my $dec2 = $self->dec2->radians;

    $ra_app = $ra1  + ( $ra2  - $ra1  ) * ( $mjd - $mjd1 ) / ( $mjd2 - $mjd1 );
    $dec_app = $dec1 + ( $dec2 - $dec1 ) * ( $mjd - $mjd1 ) / ( $mjd2 - $mjd1 );
  }

  $ra_app = new Astro::Coords::Angle::Hour($ra_app, units => 'rad', range => '2PI');
  $dec_app = new Astro::Coords::Angle($dec_app, units => 'rad');

  $self->_cache_write( "RA_APP" => $ra_app, "DEC_APP" => $dec_app );

  return ($ra_app, $dec_app);
}

=item B<apply_offset>

Overrided method to warn if C<Astro::Coords::apply_offset> is
called on this subclass.

=cut

sub apply_offset {
  my $self = shift;
  warn "apply_offset: applying offset to interpolated position for a specific time.\n";
  return $self->SUPER::apply_offset(@_);
}

=back

=head1 NOTES

Usually called via C<Astro::Coords>. This is the coordinate style
used by SCUBA for non-sidereal sources instead of using orbital elements.

Apparent RA/Decs suitable for use in this class can be obtained
from http://ssd.jpl.nasa.gov/.

=head1 SEE ALSO

L<Astro::Coords::Elements>

=head1 REQUIREMENTS

Does not use any external PAL routines.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2012 Science and Technology Facilities Council.
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
