package Astro::Coords::Equatorial;

=head1 NAME

Astro::Coords::Equatorial - Manipulate equatorial coordinates

=head1 SYNOPSIS

  $c = new Astro::Coords::Equatorial( name => 'blah',
				      ra   => '05:22:56',
				      dec  => '-26:20:40.4',
				      type => 'B1950'
				      units=> 'sexagesimal');

  $c = new Astro::Coords::Equatorial( name => 'Vega',
                                      ra => ,
                                      dec => ,
                                      type => 'J2000',
                                      units => 'sex',
                                      pm => [ 0.202, 0.286],
                                      parallax => 0.13,
                                      epoch => 2004.529,
                                      );

  $c = new Astro::Coords( ra => '16h24m30.2s',
                          dec => '-00d54m2s',
                          type => 'J2000',
                          rv => 31,
                          vdefn => 'RADIO',
                          vframe => 'LSRK' );


=head1 DESCRIPTION

This class is used by C<Astro::Coords> for handling coordinates
specified in a fixed astronomical coordinate frame.

You are not expected to use this class directly, the C<Astro::Coords>
class should be used for all access (the C<Astro::Coords> constructor
is treated as a factory constructor).

If proper motions and parallax information are supplied with a
coordinate it is assumed that the RA/Dec supplied is correct
for the given epoch. An equinox can be specified through the 'type'
constructor, where a 'type' of 'J1950' would be Julian epoch 1950.0.

=cut

use 5.006;
use strict;
use warnings;
use warnings::register;
use Carp;

our $VERSION = '0.20';

use Astro::PAL ();
use base qw/ Astro::Coords /;

use overload '""' => "stringify", fallback => 1;

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Instantiate a new object using the supplied options.

  $c = new Astro::Coords::Equatorial(
			  name =>
                          ra =>
                          dec =>
			  long =>
			  lat =>
                          pm =>
                          parallax =>
			  type =>
			  units =>
                          epoch =>
                         );

C<ra> and C<dec> are used for HMSDeg systems (eg type=J2000). Long and
Lat are used for degdeg systems (eg where type=galactic). C<type> can
be "galactic", "j2000", "b1950", and "supergalactic".  The C<units>
can be specified as "sexagesimal" (when using colon or space-separated
strings), "degrees" or "radians". The default is determined from
context.  A reference to a 2-element array can be given to specify
different units for the two coordinates, e.g. C<['hours', 'degrees']>.

The name is just a string you can associate with the sky position.

All coordinates are converted to FK5 J2000 [epoch 2000.0] internally.

Units of parallax are arcsec. Units of proper motion are arcsec/year
(no correction for declination; tropical year for B1950, Julian year
for J2000).  If proper motions are supplied they must both be supplied
in a reference to an array:

  pm => [ 0.13, 0.45 ],

Additionally if non-zero proper motions are supplied then a non-zero
parallax must also be supplied.

If parallax and proper motions are given, the ra/dec coordinates are
assumed to be correct for the specified EQUINOX (Epoch = 2000.0 for
J2000, epoch = 1950.0 for B1950) unless an explicit epoch is
specified.  If the epoch is supplied it is assumed to be a Besselian
epoch for FK4 coordinates and Julian epoch for all others.

Radial velocities can be specified using hash arguments:

  rv  =>  radial velocity (km/s)
  vdefn => velocity definition (RADIO, OPTICAL, RELATIVSTIC) [default: OPTICAL]
  vframe => velocity reference frame (HEL,GEO,TOP,LSRK,LSRD) [default: HEL]

Note that the radial velocity is only used to calculate position if
parallax or proper motions are also supplied. These values will be used
for calculating a doppler correction.

Additionally, a redshift can be specified:

  redshift => 2.3

this overrides rv, vdefn and vframe. A redshift is assumed to be an optical
velocity in the heliocentric frame.

Usually called via C<Astro::Coords> as a factor method.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  return undef unless exists $args{type};

  # make sure we are upper cased.
  $args{type} = uc($args{type});

  my ($unit_c1, $unit_c2) = (ref $args{'units'}) ? @{$args{'units'}} : ($args{'units'}) x 2;

  # Convert input args to radians
  $args{ra} = Astro::Coords::Angle::Hour->to_radians($args{ra}, $unit_c1 )
    if exists $args{ra};
  $args{dec} = Astro::Coords::Angle->to_radians($args{dec}, $unit_c2 )
    if exists $args{dec};
  $args{long} = Astro::Coords::Angle->to_radians($args{long}, $unit_c1 )
    if exists $args{long};
  $args{lat} = Astro::Coords::Angle->to_radians($args{lat}, $unit_c2 )
    if exists $args{lat};

  # Default values for parallax and proper motions
  my( $pm, $parallax );
  if( exists( $args{parallax} ) ) {
    $parallax = $args{parallax};
  } else {
    $parallax = 0;
  }
  if( exists( $args{pm} ) ) {
    $pm = $args{pm};
  } else {
    $pm = [0,0];
  }

  # Try to sort out what we have been given. We need to convert
  # everything to FK5 J2000
  croak "Proper motions are supplied but not as a ref to array"
    unless ref($pm) eq 'ARRAY';

  # Extract the proper motions into convenience variables
  my $pm1 = $pm->[0];
  my $pm2 = $pm->[1];

  my ($ra, $dec, $native);

  if ($args{type} =~ /^j([0-9\.]+)/i) {
    return undef unless exists $args{ra} and exists $args{dec};
    return undef unless defined $args{ra} and defined $args{dec};

    $native = 'radec';

    $ra = $args{ra};
    $dec = $args{dec};

# The equinox is everything after the J.
    my $equinox = $1;

# Wind the RA/Dec to J2000 if the equinox isn't 2000.
    if( $equinox != 2000 ) {
      ($ra, $dec) = Astro::PAL::palPreces( 'FK5', $equinox, '2000.0', $ra, $dec );
    }

# Get the epoch. If it's not given (in $args{epoch}) then it's
# the same as the equinox.
    my $epoch = ( ( exists( $args{epoch} ) && defined( $args{epoch} ) ) ?
                  $args{epoch} :
                  $equinox );

# Wind the RA/Dec to epoch 2000.0 if the epoch isn't 2000.0,
# taking the proper motion and parallax into account.
    if( $epoch != 2000 &&
        ( $pm1 != 0 || $pm2 != 0 || $parallax != 0 ) ) {
      # Assume we are HEL without checking
      my $rv = ( exists $args{rv} && $args{rv} ? $args{rv} : 0);

      warnings::warnif('Proper motion specified without parallax')
        if ( $pm1 != 0 || $pm2 != 0 ) && ! $parallax;

      ( $ra, $dec ) = Astro::PAL::palPm( $ra, $dec,
                                         Astro::PAL::DAS2R * $pm1,
                                         Astro::PAL::DAS2R * $pm2,
                                         $parallax,
                                         $rv,
                                         $epoch, # input epoch
                                         2000.0, # output epoch
                                       );
    }

  } elsif ($args{type} =~ /^b([0-9\.]+)/i) {
    return undef unless exists $args{ra} and exists $args{dec};
    return undef unless defined $args{ra} and defined $args{dec};

    $native = 'radec1950';
    $ra = $args{ra};
    $dec = $args{dec};

# The equinox is everything after the B.
    my $equinox = $1;

# Get the epoch. If it's not given (in $args{epoch}) then it's
# the same as the equinox. Assume supplied epoch is Besselian
    my $epoch = ( ( exists( $args{epoch} ) && defined( $args{epoch} ) ) ?
                  $args{epoch} :
                  $equinox );

    my ( $ra0, $dec0 );

# For the implementation details, see section 4.1 of SUN/67.
    if( $pm1 != 0 || $pm2 != 0 || $parallax != 0 ) {
      # Assume we are HEL without checking
      my $rv = ( exists $args{rv} && $args{rv} ? $args{rv} : 0);

      warnings::warnif('Proper motion specified without parallax')
        if ( $pm1 != 0 || $pm2 != 0 ) && ! $parallax;

      # We are converting to J2000 but we need to convert that to Besselian epoch
      ($ra, $dec) = Astro::PAL::palPm( $ra, $dec,
                                       Astro::PAL::DAS2R * $pm1,
                                       Astro::PAL::DAS2R * $pm2,
                                       $parallax,
                                       $rv,
                                       $epoch,
                                       Astro::PAL::palEpco('B','J',2000.0), # Besselian epoch
                                     );
    }

    if( $equinox != 1950 ) {

# Remove the E-terms for the specified Besselian equinox
      ($ra, $dec) = Astro::PAL::palSubet( $ra, $dec, $equinox );

# Wind the RA/Dec to B1950 if the equinox isn't 1950.
      ($ra, $dec) = Astro::PAL::palPreces( 'FK4', $equinox, 1950.0, $ra, $dec );

# Add the E-terms back in.
      ($ra, $dec) = Astro::PAL::palAddet( $ra, $dec, 1950.0 );
    }

# Convert to J2000, no proper motion. We need the epoch at which the
# coordinate was valid
    ($ra, $dec) = Astro::PAL::palFk45z($ra, $dec, $epoch );

  } elsif ($args{type} =~ /^gal/i) {
    $native = 'glonglat';
    return undef unless exists $args{long} and exists $args{lat};
    return undef unless defined $args{long} and defined $args{lat};

    ($ra, $dec) = Astro::PAL::palGaleq( $args{long}, $args{lat} );

  } elsif ($args{type} =~ /^supergal/i) {
    return undef unless exists $args{long} and exists $args{lat};
    return undef unless defined $args{long} and defined $args{lat};

    $native = 'sglonglat';
    my ($glong, $glat) = Astro::PAL::palSupgal( $args{long}, $args{lat});
    ($ra, $dec) = Astro::PAL::palGaleq( $glong, $glat );

  } else {
    my $type = (defined $args{type} ? $args{type} : "<undef>");
    croak "Supplied coordinate type [$type] not recognized";
  }

  # Now the actual object
  my $c = bless { ra2000 => new Astro::Coords::Angle::Hour($ra, units => 'rad', range => '2PI'),
		  dec2000 => new Astro::Coords::Angle($dec, units => 'rad'),
		  name => $args{name},
		  pm => $args{pm}, parallax => $args{parallax}
		}, $class;

  # Specify the native encoding
  $c->native( $native );

  # Now set the velocity parameters
  if (exists $args{redshift}) {
    $c->_set_redshift( $args{redshift} );
  } else {
    $c->_set_rv( $args{rv} ) if exists $args{rv};
    $c->_set_vdefn( $args{vdefn} ) if exists $args{vdefn};
    $c->_set_vframe( $args{vframe} ) if exists $args{vframe};
  }

  return $c;
}


=back

=head2 Accessor Methods

=over 4

=item B<radec>

Retrieve the Right Ascension and Declination (FK5 J2000) for the date
stored in the C<datetime> method. Defaults to current date if no time
is stored in the object.

  ($ra, $dec) = $c->radec();

For J2000 coordinates without proper motions or parallax, this will
return the same values as returned from the C<radec2000> method.

An explicit equinox can be supplied as either Besselian or Julian
epoch:

  ($ra, $dec) = $c->radec( 'B1950' );
  ($ra, $dec) = $c->radec( 'J2050' );
  ($ra, $dec) = $c->radec( 'B1900' );

Defaults to 'J2000'. Note that the epoch (as stored in the C<datetime>
attribute) is required when converting from FK5 to FK4 so calling this
method with 'B1950' will not be the same as calling the C<radec1950>
method unless the C<datetime> epoch is B1950.

Coordinates are returned as two C<Astro::Coords::Angle> objects.

=cut

sub radec {
  my $self = shift;
  my ($sys, $equ) = $self->_parse_equinox( shift || 'J2000' );

  # If we have proper motions we need to take them into account
  # Do this using palPm rather than via the base class since it
  # must be more efficient than going through apparent
  my @pm = $self->pm;
  my $par = $self->parallax;

  # First convert to J2000 current epoch

  # Fix PM array and parallax if none-defined
  @pm = (0,0) unless @pm;
  $par = 0 unless defined $par;

  # J2000 Epoch 2000.0
  my ($ra,$dec) = $self->radec2000();
  if ($pm[0] != 0 || $pm[1] != 0 || $par != 0) {
    # We have proper motions
    # Radial velocity in HEL frame
    # Note that we need to calculate the RA/Dec to get the HEL frame
    # if the radial velocity is not already in HEL
    # We have to ignore it for now and only use rv if it is
    # already heliocentric
    my $rv = 0;
    $rv = $self->rv if $self->vframe eq 'HEL';

    # Correct for proper motion
    ($ra, $dec) = Astro::PAL::palPm( $ra, $dec, Astro::PAL::DAS2R * $pm[0],
                                     Astro::PAL::DAS2R * $pm[1], $par, $rv, 2000.0,
                                     Astro::PAL::palEpj($self->_mjd_tt));

    # Convert to Angle objects
    $ra = new Astro::Coords::Angle::Hour( $ra, units => 'rad', range => '2PI');
    $dec = new Astro::Coords::Angle( $dec, units => 'rad' );
  }

  # Return it if we have the right answer
  if ($sys eq 'FK5' && $equ == 2000.0) {
    # Already have the right answer
  } elsif ($sys eq 'FK5') {
    # Preces to new equinox
    ($ra, $dec) = Astro::PAL::palPreces( 'FK5', 2000.0, $equ, $ra, $dec );

  } else {
    # Convert to BYYYY
    ($ra, $dec) = $self->_j2000_to_byyyy( $equ, $ra, $dec);

  }

  return (new Astro::Coords::Angle::Hour($ra, units => 'rad', range => '2PI'),
	  new Astro::Coords::Angle($dec, units => 'rad'));

}


=item B<ra>

Retrieve the Right Ascension (FK5 J2000) for the date stored in the
C<datetime> method. Defaults to current date if no time is stored
in the object.

  $ra = $c->ra( format => 's' );

For J2000 coordinates without proper motions or parallax, this will
return the same values as returned from the C<ra2000> method.

See L<Astro::Coords/"NOTES"> for details on the supported format
specifiers and default calling convention.

=cut

sub ra {
  my $self = shift;
  my %opt = @_;
  my ($ra, $dec) = $self->radec;
  my $retval = $ra->in_format( $opt{format} );

  # Tidy up array to remove sign
  shift(@$retval) if ref($retval) eq "ARRAY";
  return $retval;
}

=item B<dec>

Retrieve the Declination (FK5 J2000) for the date stored in the
C<datetime> method. Defaults to current date if no time is stored
in the object.

  $dec = $c->dec( format => 's' );

For J2000 coordinates without proper motions or parallax, this will
return the same values as returned from the C<dec2000> method.

See L<Astro::Coords/"NOTES"> for details on the supported format
specifiers and default calling convention.

=cut

sub dec {
  my $self = shift;
  my %opt = @_;
  my ($ra, $dec) = $self->radec;
  return $dec->in_format( $opt{format} );
}

=item B<radec2000>

Retrieve the Right Ascension (FK5 J2000, epoch 2000.0). Default
is to return it as an C<Astro::Coords::Angle::Hour> object.

Proper motions and parallax are taken into account (although this may
happen in the object constructor). Use the C<radec> method if you want
J2000, reference epoch.

  ($ra, $dec) = $c->radec2000;

Results are returned as C<Astro::Coords::Angle> objects.

=cut

sub radec2000 {
  my $self = shift;
  return ($self->ra2000, $self->dec2000);
}

=item B<ra2000>

Retrieve the Right Ascension (FK5 J2000, epoch 2000.0). Default
is to return it as an C<Astro::Coords::Angle::Hour> object.

Proper motions and parallax are taken into account (although this may
happen in the object constructor).  Use the C<ra> method if you want
J2000, reference epoch.

  $ra = $c->ra2000( format => "s" );

See L<Astro::Coords/"NOTES"> for details on the supported format
specifiers and default calling convention.

=cut

sub ra2000 {
  my $self = shift;
  my %opt = @_;
  my $ra = $self->{ra2000};
  my $retval = $ra->in_format( $opt{format} );

  # Tidy up array
  shift(@$retval) if ref($retval) eq "ARRAY";
  return $retval;
}

=item B<dec2000>

Retrieve the declination (FK5 J2000, epoch 2000.0). Default
is to return it in radians.

  $dec = $c->dec( format => "sexagesimal" );

Proper motions and parallax are taken into account (although this may
happen in the object constructor).  Use the C<dec> method if you want
J2000, reference epoch.

See L<Astro::Coords/"NOTES"> for details on the supported format
specifiers and default calling convention.

=cut

sub dec2000 {
  my $self = shift;
  my %opt = @_;
  my $dec = $self->{dec2000};
  return $dec->in_format( $opt{format} );
}


=item B<parallax>

Retrieve (or set) the parallax of the target. Units should be
given in arcseconds. There is no default.

  $par = $c->parallax();
  $c->parallax( 0.13 );

=cut

sub parallax {
  my $self = shift;
  if (@_) {
    $self->{parallax} = shift;
  }
  return $self->{parallax};
}

=item B<pm>

Proper motions in units of arcsec / Julian year (not corrected for
declination).

  @pm = $self->pm();
  $self->pm( $pm1, $pm2);

If the proper motions are not defined, an empty list will be returned.

If non-zero proper motions are supplied then a non-zero
parallax must also be supplied.

=cut

sub pm {
  my $self = shift;
  if (@_) {
    my $pm1 = shift;
    my $pm2 = shift;
    if (!defined $pm1) {
      warnings::warnif("Proper motion 1 not defined. Using 0.0 arcsec/year");
      $pm1 = 0.0;
    }
    if (!defined $pm2) {
      warnings::warnif("Proper motion 2 not defined. Using 0.0 arcsec/year");
      $pm2 = 0.0;
    }
    $self->{pm} = [ $pm1, $pm2 ];

    my $parallax = $self->parallax;
    warnings::warnif('Proper motion specified without parallax')
      if ( $pm1 != 0 || $pm2 != 0 ) && ! $parallax;
  }
  if( !defined( $self->{pm} ) ) { $self->{pm} = []; }
  return @{ $self->{pm} };
}

=back

=head2 General Methods

=over 4

=item B<apparent>

Return the apparent RA and Dec as two C<Astro::Coords::Angle> objects for the current
coordinates and time.

 ($ra_app, $dec_app) = $self->apparent();

=cut

sub apparent {
  my $self = shift;

  # Assumes that Parallax and proper motions are constants for this object
  my ($ra_app, $dec_app) = $self->_cache_read( "RA_APP", "DEC_APP" );

  if (!defined $ra_app || !defined $dec_app) {

    my $ra = $self->ra2000;
    my $dec = $self->dec2000;
    my $mjd = $self->_mjd_tt;
    my $par = $self->parallax;
    my @pm = $self->pm;

    @pm = (0,0) unless @pm;
    $par = 0.0 unless defined $par;

    # do not attempt to correct for radial velocity unless we are doing parallax or
    # proper motion correction
    my $rv = 0;
    if ($par != 0 || $pm[0] != 0 || $pm[1] != 0 ) {
      # Radial velocity in HEL frame
      # Note that we need to calculate the apparent RA/Dec to get the HEL frame
      # if the radial velocity is not already in HEL
      # We have to ignore it for now and only use rv if it is heliocentric
      $rv = $self->rv if $self->vframe eq 'HEL';
    }

    ($ra_app, $dec_app) = Astro::PAL::palMap( $ra, $dec,
                                              Astro::PAL::DAS2R * $pm[0],
                                              Astro::PAL::DAS2R * $pm[1], $par, $rv, 2000.0, $mjd );

    $ra_app = new Astro::Coords::Angle::Hour($ra_app, units => 'rad', range => '2PI');
    $dec_app = new Astro::Coords::Angle($dec_app, units => 'rad');

    $self->_cache_write( "RA_APP" => $ra_app, "DEC_APP" => $dec_app );
  }

  return ($ra_app, $dec_app);
}

=item B<array>

Return back 11 element array with first 3 elements being the
coordinate type (RADEC) and the ra/dec coordinates in J2000
epoch 2000.0 (radians).

This method returns a standardised set of elements across all
types of coordinates.

=cut

sub array {
  my $self = shift;
  my ($ra, $dec) = $self->radec2000;
  return ( $self->type, $ra->radians, $dec->radians,
	   undef, undef, undef, undef, undef, undef, undef, undef);
}

=item B<type>

Returns the generic type associated with the coordinate system.
For this class the answer is always "RADEC".

This is used to aid construction of summary tables when using
mixed coordinates.

=cut

sub type {
  return "RADEC";
}

=item B<stringify>

A string representation of the object.

Returns RA and Dec (J2000) in string format.

=cut

sub stringify {
  my $self = shift;
  my ($ra, $dec) = $self->radec();
  return "$ra $dec";
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
  my ($ra, $dec) = $self->radec;

  return sprintf("%-16s  %-12s  %-13s  J2000",$name,$ra, $dec);
}

=item B<set_vel_pars>

Set the velocity parameters.

  $c->set_vel_pars( $rv, $vdefn, $vframe );

This does not include redshift.

=cut

sub set_vel_pars {
  my $self = shift;
  my ($rv, $vdefn, $vframe) = @_;

  $self->_set_rv( $rv ) if defined $rv;
  $self->_set_vdefn( $vdefn ) if defined $vdefn;
  $self->_set_vframe( $vframe ) if defined $vframe;

  return;
}

=back

=begin __PRIVATE_METHODS__

=head2 Private Methods

=over 4

=item B<_calc_mtime>

Calculate meridian time, in the direction specified by C<$event>
(-1 before, +1 after).

  $mtime = $self->_calc_mtime($reftime, $event);

This is a non-iterative version of Astro::Coords::_calc_mtime,
for the simplest case.  It calls the superclass method if
proper motion or parallax are involved.

=cut

sub _calc_mtime {
  my $self = shift;
  return $self->SUPER::_calc_mtime(@_)
    if $self->parallax() or $self->pm();

  my ($reftime, $event ) = @_;

  # event must be 1 or -1
  if (!defined $event || ($event != 1 && $event != -1)) {
    croak "Event must be either +1 or -1";
  }

  # do we have DateTime objects
  my $dtime = $self->_isdt();

  my $mtime = $self->_local_mtcalc();
  my $diff = $mtime->epoch - $reftime->epoch;

  if (($diff >= 0 and $event == +1)
  or  ($diff <= 0 and $event == -1)) {
    return $mtime;
  }
  else {
    # We went the wrong way.
    if ($dtime) {
      $mtime->add(seconds => $event * $self->_sidereal_period());
    } else {
      $mtime = $mtime + ($event * $self->_sidereal_period());
    }
  }
  return $mtime;
}

=item B<_iterative_el>

For the simplest case, the initial guess should have been good enough,
so iterating would not be necessary.  Therefore if there is no
proper motion or parallax, this subroutine does nothing.

See L<Astro::Coords/_iterative_el>.

=cut


sub _iterative_el {
  my $self = shift;
  return $self->SUPER::_iterative_el(@_)
    if $self->parallax() or $self->pm();

  # Check that the elevation is indeed correct:
  # (Should not be necessary, remove if it wastes too much time.)
  my ($refel, undef) = @_;
  my $el = $self->el();
  my $tol = 30 * Astro::PAL::DAS2R;
  return $self->SUPER::_iterative_el(@_)
      if (abs($el - $refel) > $tol);

  return 1;
}

=back

=end __PRIVATE_METHODS__

=head1 NOTES

Usually called via C<Astro::Coords>.

=head1 REQUIREMENTS

C<Astro::PAL> is used for all internal astrometric calculations.

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>

Proper motion, equinox and epoch support added by Brad Cavanagh
<b.cavanagh@jach.hawaii.edu>

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
