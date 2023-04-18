package Astro::Coords::Offset;

=head1 NAME

Astro::Coords::Offset - Represent an offset from a base position

=head1 SYNOPSIS

  use Astro::Coords::Offset;

  my $offset = new Astro::Coords::Offset( 10, 20,
                                          system => 'J2000',
                                          projection => "TAN" );

  my $offset = new Astro::Coords::Offset( $ang1, $ang2,
                                          system => 'J2000',
                                          projection => "TAN" );

  my ($a1, $a2) = $offset->offsets;
  my $arcsec = $a1->arcsec;

=head1 DESCRIPTION

Sometimes, it is necessary for a position to be specified that is
offset from the base tracking system. This class provides a means of
specifying an offset in a particular coordinate system and using a
specified projection.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

use Astro::PAL;
use Astro::Coords::Angle;

use constant PAZERO => new Astro::Coords::Angle( 0.0, units => 'radians' );

use vars qw/ @PROJ  @SYSTEMS /;

our $VERSION = '0.21';

# Allowed projections
@PROJ = qw| SIN TAN ARC DIRECT |;

# Allowed coordinate systems  J\d+ and B\d+ are also allowed by the
# PTCS - these are pattern matches
@SYSTEMS = (qw|
	      TRACKING
	      GAL
	      ICRS
	      ICRF
              |,
	      qr|J\d+(\.\d)?|,
	      qr|B\d+(\.\d)?|,
            qw|
	      APP
	      HADEC
	      AZEL
	      MOUNT
	      OBS
	      FPLANE
	      |);

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new Offset object. The first two arguments must be the
offsets in arcseconds or C<Astro::Coords::Angle> objects. The
projection and tracking system can be specified as optional hash
arguments (defaulting to TAN and J2000 respectively).

  my $off = new Astro::Coords::Offset( 10, -20 );

  my $off = new Astro::Coords::Offset( @off, system => "AZEL",
                                             projection => "SIN");

  my $off = new Astro::Coords::Offset( @off, system => "AZEL",
                                             projection => "SIN",
                                             posang => $pa,
                                     );

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $dc1 = shift;
  my $dc2 = shift;

  croak "Offsets must be supplied to constructor"
    if (!defined $dc1 || !defined $dc2);

  my %options = @_;

  # Aim for case-insensitive keys
  my %merged = (
		  system => "J2000",
		  projection => 'TAN',
		  tracking_system => undef,
		  posang => undef );

  for my $k (keys %options) {
    my $lk = lc($k);
    if (exists $merged{$lk}) {
      $merged{$lk} = $options{$k};
    }
  }

  # Store the offsets as Angle objects if they are not already
  $dc1 = new Astro::Coords::Angle( $dc1, units => 'arcsec' )
    unless UNIVERSAL::isa( $dc1, 'Astro::Coords::Angle');
  $dc2 = new Astro::Coords::Angle( $dc2, units => 'arcsec' )
    unless UNIVERSAL::isa( $dc2, 'Astro::Coords::Angle');


  # Create the object
  my $off = bless {
		   OFFSETS => [ $dc1, $dc2 ],
		   PROJECTION => undef,
		   POSANG   => PAZERO,
		   SYSTEM       => undef,
		   TRACKING_SYSTEM => undef,
		  }, $class;

  # Use accessor to set so that we get validation
  $off->projection( $merged{projection} );
  $off->system( $merged{system} );
  $off->tracking_system( $merged{tracking_system} )
    if defined $merged{tracking_system};
  $off->posang( $merged{posang} )
    if defined $merged{posang};

  return $off;
}

=back

=head2 Accessor Methods

=over 4

=item B<offsets>

Return the X and Y offsets.

  @offsets = $self->offsets;

as C<Astro::Coords::Angle> objects.

=cut

sub offsets {
  my $self = shift;
  return @{$self->{OFFSETS}};
}

=item B<xoffset>

Returns just the X offset.

  $x = $off->xoffset;

=cut

sub xoffset {
  my $self = shift;
  my @xy = $self->offsets;
  return $xy[0];
}

=item B<yoffset>

Returns just the Y offset.

  $x = $off->yoffset;

=cut

sub yoffset {
  my $self = shift;
  my @xy = $self->offsets;
  return $xy[1];
}

=item B<system>

Coordinate system of this offset. Can be different to the coordinate
system of the base position.

Allowed values are J2000, B1950, AZEL plus others specified by the
JAC TCS XML (see L<"SEE ALSO"> section at end). TRACKING is special
since it can change, depending on which output coordinate frame is
in use. See the C<tracking_system> attribute for more details.

"Az/El" is treated as "AZEL" for backwards compatibility reasons.

=cut

sub system {
  my $self = shift;
  if (@_) {
    my $p = shift;
    $p = uc($p);
    $p = "AZEL" if $p eq 'AZ/EL';

    # need to make sure that we convert the input system into
    # a TCS system
    my $match;
    for my $compare (@SYSTEMS) {
	if ($p =~ /^$compare/) {
	    if (!defined $match) {
                if (ref($compare)) {
                   # regex so we just take the input
                   $match = $p;
                } else {
                   # exact match to start of string so take the TCS value
   	 	   $match = $compare;
                }
	    } else {
		croak "Multiple matches for system '$p'";
	    }
	}
    }
    croak "Unknown system '$p'" unless defined $match;
    $self->{SYSTEM} = $match;
  }
  return $self->{SYSTEM};
}

=item B<posang>

Position angle of this offset as an C<Astro::Coords::Angle> object.
Position angle follows the normal "East of North" convention.

  $off->posang( 45 );
  $pa = $off->posang;

If a number is supplied it is assumed to be in degrees (this
matches the common usage in the JCMT TCS XML DTD).

By default returns a position angle of 0 deg.

=cut

sub posang {
  my $self = shift;
  if (@_) {
    my $pa = shift;
    if (!defined $pa) {
      $self->{POSANG} = PAZERO;
    } elsif (UNIVERSAL::isa($pa, "Astro::Coords::Angle")) {
      $self->{POSANG} = $pa;
    } elsif ($pa =~ /\d/) {
      $self->{POSANG} = new Astro::Coords::Angle( $pa, units => 'deg');
    } else {
      croak "Position angle for offset supplied in non-recognizable form ('$pa')";
    }
  }
  return $self->{POSANG};
}

=item B<projection>

Return (or set) the projection that should be used for this offset.
Defaults to tangent plane. Allowed options are TAN, SIN or ARC.

=cut

sub projection {
  my $self = shift;
  if (@_) {
    my $p = shift;
    $p = uc($p);
    my $match = join("|",@PROJ);
    croak "Unknown projection '$p'"
      unless $p =~ /^$match$/;
    $self->{PROJECTION} = $p;
  }
  return $self->{PROJECTION};
}



#  From the TCS:
#   if (otype == direct)
#     {
#        *dc1 = t1 - b1;
#        *dc2 = t2 - b2;
#     }
#   else if (otype == tan_offset)
#     {
#        slaDs2tp(t1,t2,b1,b2,dc1,dc2,&jstat);
#     }
#   else if (otype == sin_offset)
#     {
#        da = t1 - b1;
#        cd = cos(t2);
#        *dc1 = cd * sin(da);
#        *dc2 = sin(t2)*cos(b2) - cd * sin(b2) * cos(da);
#     }
#   else if (otype == arc_offset)
#     {
#        da = t1 - b1;
#        cd = cos(t2);
#        sd = sin(t2);
#        cd0 = cos(b2);
#        sd0 = sin(b2);
#        cda = cos(da);
#        theta = acos(sd*sd0 + cd*cd0*cda);
#        to = theta/(sin(theta));
#        *dc1 = to*cd*sin(da);
#        *dc2 = to*(sd*cd0 - cd*sd0*cda);
#     }

=item B<tracking_system>

In some cases, the offset can be specified to be relative to the
system that the telescope is currently using to track the source.
This does not necessarily have to be the same as the coordinate
frame that was originally used to specify the target. For example,
it is perfectly acceptable to ask a telescope to go to a certain
Az/El and then ask it to track in RA/Dec.

This method allows the tracking system to be specified
independenttly of the offset coordinate system. It will only
be used if the offset is specified to use "TRACKING" (but it allows
the system to disambiguate an offset that was defined as "TRACKING B1950"
from an offset that is simply "B1950".

The allowed types are the same as for C<system> except that "TRACKING"
is not permitted.

=cut

sub tracking_system {
  my $self = shift;
  if (@_) {
    my $p = shift;
    $p = uc($p);
    croak "Tracking System can not itself be 'TRACKING'"
      if $p eq 'TRACKING';
    my $match = join("|",@SYSTEMS);
    croak "Unknown system '$p'"
      unless $p =~ /^$match$/;
    $self->{TRACKING_SYSTEM} = $p;
  }
  return $self->{TRACKING_SYSTEM};
}

=back

=head2 General Methods

=over 4

=item B<invert>

Return a new offset object with the sense of the offset inverted.

  $inv = $offset->invert;

=cut

# We could do this by adding 180 deg to posang but people really
# expect the sign to change

sub invert {
  my $self = shift;

  my @xy = map { $_->negate } $self->offsets;
  my $pa = $self->posang->clone;
  $pa = undef if $pa->radians == 0;
  return $self->new( @xy, system => $self->system,
		     projection => $self->projection,
		     posang => $pa);
}

=item B<clone>

Create a cloned copy of this offset.

  $clone = $offset->clone;

=cut

sub clone {
  my $self = shift;
  my @xy = map { $_->clone() } $self->offsets;
  my $pa = $self->posang->clone;
  $pa = undef if $pa->radians == 0;
  return $self->new( @xy, posang => $pa,
		     system => $self->system,
		     projection => $self->projection
		   );
}

=item B<offsets_rotated>

This can be thought of as a version of C<offsets> which returns offsets which
have been rotated through the position angle.  It uses the C<offsets> method
internally to fetch the stored values.  Results are C<Astro::Coords::Angle>
objects.

  ($x_rotated, $y_rotated) = $offset->offsets_rotated();

It is assumed that the coordinate system has the first coordinate being
positive to the East in order to match the definiton of the
C<posang> given above.

=cut

sub offsets_rotated {
  my $self  = shift;
  my $paobj = $self->posang();

  # If position angle not specified, assume zero.
  return $self->offsets() unless defined $paobj;

  # Also do nothing if the angle is zero.
  my $pa = $paobj->radians();
  return $self->offsets() if $pa == 0.0;

  my ($x, $y) = map {$_->arcsec()} $self->offsets();

  # This code taken from OMP::Translator::Base::PosAngRot
  # which could now be defined in terms of this method,
  # except that it does not use an Astro::Coords::Offset.

  my $cospa = cos($pa);
  my $sinpa = sin($pa);

  my $xr =   $x * $cospa  +  $y * $sinpa;
  my $yr = - $x * $sinpa  +  $y * $cospa;

  return map {new Astro::Coords::Angle($_, units => 'arcsec')} ($xr, $yr);
}

=back

=head1 SEE ALSO

The allowed offset types are designed to match the specification used
by the Portable Telescope Control System configuration XML.
See L<http://www.jach.hawaii.edu/JACdocs/JCMT/OCS/ICD/006> for more
on this.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2002-2006 Particle Physics and Astronomy Research Council.
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
