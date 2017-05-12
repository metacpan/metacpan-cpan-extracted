package Astro::Telescope;

=head1 NAME

Astro::Telescope - class for obtaining telescope information

=head1 SYNOPSIS

  use Astro::Telescope;

  $tel = new Astro::Telescope( 'UKIRT' );

  $latitude = $tel->lat;
  $longitude = $tel->long;
  $altitude = $tel->alt;

  %limits = $tel->limits;

  @telescopes = Astro::Telescope->telNames();

=head1 DESCRIPTION

A class for handling properties of individual telescopes such
as longitude, latitude, height and observational limits.

=cut

use 5.006;
use warnings;
use warnings::register;
use strict;

our $ASTRO_PAL = 0;
eval { require Astro::PAL; };
if( ! $@ ) {
  $ASTRO_PAL = 1;
}

use Astro::Telescope::MPC;

use File::Spec;
use Carp;

use vars qw/ $VERSION /;
$VERSION = '0.71';

# separator to use for output sexagesimal notation
our $Separator = " ";

# Decimal degrees to radians conversion factor.
use constant DD2R => 0.017453292519943295769236907684886127134428718885417;

# Decimal hours to radians conversion factor.
use constant DH2R => 0.26179938779914943653855361527329190701643078328126;

# Radians to degrees conversion factor.
use constant DR2D => 57.295779513082320876798154814105170332405472466564;

# Earth's equatorial radius in metres.
use constant EQU_RAD => 6378100;

# Earth's flattening parameter (actually 1-f).
use constant E => 0.996647186;

# Related to flattening parameter (sqrt(1-(1-f)^2)).
use constant EPS => 0.081819221;

# Pi.
use constant PI => 4 * atan2( 1, 1 );

# AU to metre conversion factor.
use constant AU2METRE => 149598000000;

# Hash table containing mapping from PAL telescope name to
# MPC observatory code.
our %pal2obs = ( 'AAT' => '260',
                 'LPO4.2' => '950',
                 'LPO2.5' => '950',
                 'LP01' => '950',
                 'LICK120' => '662',
                 'MMT' => '696',
                 'DAO72' => '658',
                 'DUPONT' => '304',
                 'MTHOP1.5' => '696',
                 'STROMLO74' => '414',
                 'ANU2.3' => '413',
                 'GBVA140' => '256',
                 'TOLOLO4M' => 'I02',
                 'TOLOLO1.5M' => 'I02',
                 'BLOEMF' => '074',
                 'BOSQALEGRE' => '821',
                 'FLAGSTF61' => '689',
                 'LOWELL72' => '688',
                 'OKAYAMA' => '371',
                 'KPNO158' => '691',
                 'KPNO90' => '691',
                 'KPNO84' => '691',
                 'KPNO36FT' => '697',
                 'KOTTAMIA' => '088',
                 'ESO3.6' => '809',
                 'MAUNAK88' => '568',
                 'UKIRT' => '568',
                 'QUEBEC1.6' => '301',
                 'MTEKAR' => '098',
                 'MTLEMMON60' => '686',
                 'MCDONLD2.7' => '711',
                 'MCDONLD2.1' => '711',
                 'PALOMAR200' => '261',
                 'PALOMAR60' => '644',
                 'DUNLAP74' => '779',
                 'HPROV1.93' => '511',
                 'HPROV1.52' => '511',
                 'SANPM83' => '679',
                 'SAAO74' => '079',
                 'TAUTNBG' => '033',
                 'CATALINA61' => '693',
                 'STEWARD90' => '691',
                 'USSR6' => '115',
                 'ARECIBO' => '251',
                 'CAMB5KM' => '503',
                 'CAMB1MILE' => '503',
                 'GBVA300' => '256',
                 'JCMT' => '568',
                 'ESONTT' => '809',
                 'ST.ANDREWS' => '482',
                 'APO3.5' => '645',
                 'KECK1' => '568',
                 'TAUTSCHM' => '033',
                 'PALOMAR48' => '644',
                 'UKST' => 'E12',
                 'KISO' => '381',
                 'ESOSCHM' => '809',
                 'SUBARU' => '568',
                 'CFHT' => '568',
                 'KECK2' => '568',
                 'GEMININ' => '568',
                 'IRTF' => '568',
                 'CSO' => '568',
                 'VLT1' => '309',
                 'VLT2' => '309',
                 'VLT3' => '309',
                 'VLT4' => '309',
                 'MAGELLAN1' => '304',
                 'MAGELLAN2' => '304',
               );


=head1 METHODS

=head2 Constructor

=over

=item B<new>

Create a new telescope object. Takes the telescope abbreviation
as the single argument.

  $tel = new Astro::Telescope( 'VLA' );

An argument must be supplied. Returns C<undef> if the telescope
is not recognized.

If more than one argument is supplied the assumption
is that the user is supplying telescope details. In that case,
"Name" and "Long" must be supplied, and either the geodetic latitude and
altitude ("Lat" and "Alt" -- but if "Alt" is not supplied it will
default to zero and this class will issue a warning), the geocentric
latitude and distance
("GeocLat" and "GeocDist"), or the parallax coefficients ("Parallax")
must be supplied. Latitudes and longitudes must be given in radians,
altitude and distance in metres, and the parallax constants in units
of Earth radii.

  $tel = new Astro::Telescope('telescope');
  $tel = new Astro::Telescope(Name => 'JCMT', Long => $long, Lat => $lat );


=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  return undef unless @_;

  # Create the new object
  my $tel = bless {}, $class;

  # Configure it with the supplied telescope name
  # or other arguments
  $tel->_configure( @_ ) or return undef;

  return $tel;
}

=back

=head2 Accessor Methods

=over 4

=item B<name>

Returns the abbreviated name of the telescope. This is the same as
that given to the constructor (although it will be upper-cased).

The object can be reconfigured to a new telescope by supplying
a new abbreviation to this method.

  $tel->name('JCMT');

The object will not change state if the name is not known.

=cut

sub name {
  my $self = shift;
  if (@_) {
    my $name = shift;
    $self->_configure( $name );
  }
  return $self->{Name};
}

=item B<fullname>

Returns the full name of the telescope. For example, if the abbreviated
name is "JCMT" this will return "JCMT 15 metre".

=cut

sub fullname {
  my $self = shift;
  return $self->{FullName};
}

=item B<obscode>

Returns or sets the IAU observatory code as listed at
http://cfa-www.harvard.edu/iau/lists/ObsCodes.html. The object will
not change state if the observatory code is not known.

=cut

sub obscode {
  my $self = shift;
  if( @_ ) {
    my $obscode = shift;
    $self->_configure( $obscode );
  }
  return $self->{ObsCode};
}

=item B<long>

Longitude of the telescope (east +ve). By default this is in radians.

An argument of "d" or "s" can be supplied to retrieve the value
in decimal degrees or sexagesimal string format respectively.

 $string = $tel->long("s");

=cut

sub long {
  my $self = shift;
  my $long = $self->{Long};
  $long = $self->_cvt_fromrad( $long, shift ) if @_;
  return $long
}

=item B<lat>

Geodetic latitude of the telescope. By default this is in radians.

An argument of "d" or "s" can be supplied to retrieve the value
in decimal degrees or sexagesimal string format respectively.

  $deg = $tel->lat("d");

=cut

sub lat {
  my $self = shift;
  my $lat = $self->{Lat};
  $lat = $self->_cvt_fromrad( $lat, shift ) if @_;
  return $lat
}

=item B<alt>

Altitude of the telescope in metres above mean sea level.

=cut

sub alt {
  my $self = shift;
  return $self->{Alt};
}

=item B<parallax>

Return the parallax constants, rho*sin(phi') and rho*cos(phi'),
where rho is the geocentric radius in Earth radii and phi' is
the geocentric latitude. Returned as a hash where 'Par_C' is
rho*sin(phi') and 'Par_S' is rho*cos(phi').

  @parallax = $tel->parallax;

=cut

sub parallax {
  my $self = shift;
  return %{$self->{Parallax}};
}

=item B<geoc_lat>

Return the geocentric latitude. By default this is in radians.

An argument of "d" or "s" can be supplied to retrieve the value
in decimal degrees or sexagesimal string format respectively.

  $deg = $tel->geoc_lat("d");

=cut

sub geoc_lat {
  my $self = shift;
  my $lat = $self->{GeocLat};
  $lat = $self->_cvt_fromrad( $lat, shift ) if @_;
  return $lat;
}

=item B<geoc_dist>

Return the distance from the centre of the Earth. By default
this is in metres.

  $geoc_dist = $tel->geoc_dist;

=cut

sub geoc_dist {
  my $self = shift;
  return $self->{GeocDist};
}

=item B<obsgeo>

Return the cartesian coordinates of the observatory. These are the form required
for specifying coordinates in the FITS OBSGEO-X, OBSGEO-Y and OBSGEO-Z header
items.

  ($x, $y, $z) = $tel->obsgeo;

Values are returned in metres.

=cut

sub obsgeo {
  my $self = shift;
  my $long = $self->long;
  my $gclat  = $self->geoc_lat;
  my $dist = $self->geoc_dist;

# Could use the PAL versions but we have local copies of these routines.
# Seem to give identical answers to PAL within about 50 m.
#  my $gdlat = $self->lat;
#  Astro::PAL::palGeoc( $gdlat, $self->alt, my $pal_r, my $pal_z);
#  $pal_r *= $AU2METRE;
#  $pal_z *= $AU2METRE;

  # calculate distance from observatory to centre of Earth projected onto the equator
  my $r = $dist * cos( $gclat );

  # calculate height above the equator
  my $z = $dist * sin( $gclat );

#  $z = $pal_z; $r = $pal_r;

  # now calculate coordinates projected from the longitude
  my $x = $r * cos( $long );
  my $y = $r * sin( $long );

  return ($x, $y, $z);
}

=item B<limits>

Return the telescope limits.

  %limits = $tel->limits;

The limits are returned as a hash with the following keys:

=over 4

=item type

Specifies the way in which the limits are specified. Effectively the
telescope mount. Values of "AZEL" (for altaz telescopes) and "HADEC"
(for equatorial telescopes) are currently supported.

=item el

Elevation limit of the telescope. Value is a hash with keys C<max>
and C<min>. Units are in radians. Only used if C<type> is C<AZEL>.

=item ha

Hour angle limit of the telescope. Value is a hash with keys C<max>
and C<min>. Units are in radians. Only used if C<type> is C<HADEC>.

=item dec

Declination limit of the telescope. Value is a hash with keys C<max>
and C<min>. Units are in radians. Only used if C<type> is C<HADEC>.

=back

Only some telescopes have limits defined (please send patches with new
limits if you know them). If limits are not available for this
telescope limits corresponding to "above the horizon" are returned.

If limits have been explicitly associated with this object using the
C<setlimits> method then those limits will be returned.

=cut

sub limits {
  my $self = shift;
  croak "Limits() method does not (yet) accept any arguments!" if @_;
  return %{$self->{LIMITS}} if defined $self->{LIMITS};

  # Just put them all in a big hash (this could come outside
  # the method since it does not change)
  my %limits = (
		JCMT => {
			 type => "AZEL",
			 el => { # 5 to 88 deg
				max => 88 * DD2R,
				min => 5 * DD2R,
			       },
			},
		UKIRT => {
			  type => "HADEC",
			  ha => { # +/- 4.5 hours
				max => 4.5 * DH2R,
				min => -4.5 * DH2R,
				},
			  dec=> { # -42 to +60 deg
				max => 60 * DD2R,
				min => -42 * DD2R,
				},
			 },

	       );

  # Return the hash if it exists
  if (exists $limits{ $self->name }) {
    return %{ $limits{ $self->name } };
  } else {
    # fudge something for simple observability
    return ( type => 'AZEL',
	     el   => {
		      max => 90 * DD2R,
		      min => 0,
		     }
	   );
  }

}

=item B<setlimits>

This method allows limits for this telescope object to be set explicitly.
The contents of the limits hash must be those described by the C<limits> method
and will be returned by the C<limits> method). Limits set
in this way will override built-in limits.

  $tel->setlimits( %limits );

Limits will be cleared if the object is reconfigured (eg by setting the obscode).

=cut

sub setlimits {
  my $self = shift;
  my %limits = @_;
  croak "Supplied limits do not seem to contain a type key"
    unless exists $limits{type};
  $self->{LIMITS} = \%limits;
  return;
}

=back

=head2 Class Methods

=over 4

=item B<telNames>

Obtain a sorted list of all supported telescope names.

  @names = Astro::Telescope->telNames;

Currently only returns the PAL names, and only if Astro::PAL is
available. If it is not available, return an empty list.

=cut

sub telNames {
  my @names;
  if( $ASTRO_PAL ) {
    my $i = 1;
    my $ident = '';
    while (defined $ident) {
      my ($ident, $name, $w, $p, $h) = Astro::PAL::palObs($i);
      last unless defined $ident;
      $i++;
      push(@names, $ident);
    }
  }
  return sort @names;
}

=back

=begin __PRIVATE__

=head2 Private Methods

=over 4

=item B<_configure>

Reconfigure the object for a new telescope. Called automatically
by the constructor or if a new telescope name or observatory
code is provided.

Returns C<undef> if the telescope was not supported.

If more than one argument is supplied the assumption
is that the user is supplying telescope details. In that case,
"Name" and "Long" must be supplied, and either the geodetic latitude and
altitude ("Lat" and "Alt" -- but if "Alt" is not supplied it will
default to zero and this class will issue a warning), the geocentric
latitude and distance
("GeocLat" and "GeocDist"), or the parallax coefficients ("Parallax")
must be supplied. Latitudes and longitudes must be given in radians,
altitude and distance in metres, and the parallax constants in units
of Earth radii.

  $t->_configure('telescope');
  $t->_configure( $obscode );
  $t->_configure(Name => 'JCMT', Long => $long, Lat => $lat );

Any user defined limits are cleared by this routine.

=cut

sub _configure {
  my $self = shift;
  $self->{LIMITS} = undef; # reset user-supplied limits
  if (scalar(@_) == 1) {

    my $name = uc(shift);

    &Astro::Telescope::MPC::parse_table;

    if( exists( $Astro::Telescope::MPC::obs_codes{$name} ) ) {

      $self->{Name} = $Astro::Telescope::MPC::obs_codes{$name}->{Name};
      $self->{FullName} = $Astro::Telescope::MPC::obs_codes{$name}->{Name};
      $self->{ObsCode} = $name;
      $self->{Long} = $Astro::Telescope::MPC::obs_codes{$name}->{Long};
      $self->{Parallax}->{Par_C} = $Astro::Telescope::MPC::obs_codes{$name}->{Par_C};
      $self->{Parallax}->{Par_S} = $Astro::Telescope::MPC::obs_codes{$name}->{Par_S};

      ( $self->{GeocLat}, $self->{GeocDist} ) = $self->_par2geoc();
      ( $self->{Lat}, $self->{Alt} ) = $self->_geoc2geod();

    } elsif( $ASTRO_PAL ) {

      my ($ident, $fullname, $w, $p, $h) = Astro::PAL::palObs($name);

      if( defined $fullname ) {

        # Correct for East positive
        $w *= -1;

        $self->{Name} = $ident;
        $self->{FullName} = $fullname;
        $self->{Long} = $w;
        $self->{Lat} = $p;
        $self->{Alt} = $h;

        ( $self->{GeocLat}, $self->{GeocDist} ) = $self->_geod2geoc();
        $self->{Parallax} = $self->_geoc2par();

        $self->{ObsCode} = $pal2obs{$name};

      } else {
        return undef;
      }

    } else {
      return undef;
    }

    return 1;

  } else {
    my %args = @_;

    return undef unless exists $args{Name} && exists $args{Long};

    if( exists( $args{Lat} ) ) {

      if( !exists( $args{Alt} ) ) {
        warnings::warnif( "Warning: Altitude not given. Defaulting to zero." );
        $self->{Alt} = 0;
      } else {
        $self->{Alt} = $args{Alt};
      }
      $self->{Lat} = $args{Lat};

      if( !exists( $args{GeocLat} ) || !exists( $args{GeocDist} ) ) {
        ( $self->{GeocLat}, $self->{GeocDist} ) = $self->_geod2geoc();
      }

      if( !exists( $args{Parallax} ) ) {
        $self->{Parallax} = $self->_geoc2par();
      }
    } elsif( exists( $args{Parallax} ) ) {

      $self->{Parallax} = $args{Parallax};

      if( !exists( $args{GeocLat} ) || !exists( $args{GeocDist} ) ) {
        ( $self->{GeocLat}, $self->{GeocDist} ) = $self->_par2geoc();
      }

      if( !exists( $args{Lat} ) || !exists( $args{Alt} ) ) {
        ( $self->{Lat}, $self->{Alt} ) = $self->_geoc2geod();
      }
    } elsif( exists( $args{GeocLat} ) && exists( $args{GeocDist} ) ) {

      $self->{GeocLat} = $args{GeocLat};
      $self->{GeocDist} = $args{GeocDist};

      if( !exists( $args{Lat} ) || !exists( $args{Alt} ) ) {
        ( $self->{Lat}, $self->{Alt} ) = $self->_geoc2geod();
      }
      if( !exists( $args{Parallax} ) ) {
        $self->{Parallax} = $self->_geoc2par();
      }
    } else {
      return undef;
    }

    for my $key (qw/ Name Long FullName ObsCode / ) {
      $self->{$key} = $args{$key} if exists $args{$key};
    }
    return 1;
  }
}

=item B<_cvt_fromrad>

Convert radians to either degrees ("d") or sexagesimal string ("s").

  $converted = $self->_cvt_fromrad($rad, "s");

If the second argument is not supplied the string is returned
unmodified.

The string is space separated by default but this can be overridden
by setting the variable $Astro::Telescope::Separator to a new value.

=cut

sub _cvt_fromrad {
  my $self = shift;
  my $rad = shift;
  my $format = shift;
  return $rad unless defined $format;
  my $degrees = $rad * DR2D;
  my $out;
  if ($format =~ /^d/) {
    $out = $degrees;
  } elsif ($format =~ /^s/) {

    my $deg = int( $degrees );
    my $rem = abs( $degrees - $deg );
    my $min = int( 60 * $rem );
    $rem = 60 * $rem - $min;
    my $sec = int( 60 * $rem );
    $rem = 60 * $rem - $sec;
    my $frac = int( $rem * 100 );

    $out = join($Separator,$deg,$min,$sec) . ".$frac";
  }
  return $out;
}

=item B<_geod2geoc>

Convert geodetic latitude and altitude to geocentric latitude and
distance from centre of earth.

  ( $geoc_lat, $geoc_dist ) = $self->_geod2geoc();

Returns latitude in radians and distance in metres.

=cut

sub _geod2geoc {
  my $self = shift;

  return undef unless ( defined $self->lat &&
                        defined $self->alt );

  my $lat = $self->lat;
  my $alt = $self->alt;

  my $lambda_sl = atan2( E * E * sin( $lat ) / cos( $lat ), 1 );
  my $sin_lambda_sl = sin( $lambda_sl );
  my $cos_lambda_sl = cos( $lambda_sl );
  my $sin_mu = sin( $lat );
  my $cos_mu = cos( $lat );
  my $sl_radius = sqrt( EQU_RAD * EQU_RAD / ( 1 + ( ( 1 / ( E * E ) ) - 1 ) * $sin_lambda_sl * $sin_lambda_sl ) );

  my $py  = $sl_radius * $sin_lambda_sl + $alt * $sin_mu;
  my $px = $sl_radius * $cos_lambda_sl + $alt * $cos_mu;
  my $geoc_lat = atan2( $py, $px );

  my $geoc_dist = sqrt( $py * $py + $px * $px );

  return( $geoc_lat, $geoc_dist );
}

=item B<_geoc2geod>

Convert geocentric latitude and distance from centre of Earth to
geodetic latitude and altitude.

  ( $geod_lat, $geod_alt ) = $self->_geoc2geod();

Returns latitude in radians and altitude in metres.

=cut

sub _geoc2geod {
  my $self = shift;

  return undef unless ( defined $self->{GeocLat} &&
                        defined $self->{GeocDist} );

  my $geoc_lat = $self->{GeocLat};
  my $geoc_dist = $self->{GeocDist};

  my $t_lat = sin( $geoc_lat ) / cos( $geoc_lat );
  my $x_alpha = E * EQU_RAD / sqrt( $t_lat * $t_lat + E * E );
  my $mu_alpha = atan2( sqrt( EQU_RAD * EQU_RAD - $x_alpha * $x_alpha ), E * $x_alpha );
  if( $geoc_lat < 0 ) {
    $mu_alpha = 0 - $mu_alpha;
  }
  my $sin_mu_a = sin( $mu_alpha );
  my $delt_lambda = $mu_alpha - $geoc_lat;
  my $r_alpha = $x_alpha / cos( $geoc_lat );
  my $l_point = $geoc_dist - $r_alpha;
  my $alt = $l_point * cos( $delt_lambda );
  my $denom = sqrt( 1 - EPS * EPS * $sin_mu_a * $sin_mu_a );
  my $rho_alpha = EQU_RAD * ( 1 - EPS ) / ( $denom * $denom * $denom );
  my $delt_mu = atan2( $l_point * sin( $delt_lambda ), $rho_alpha + $alt );
  my $geod_lat = $mu_alpha - $delt_mu;
  my $lambda_sl = atan2( E * E * sin( $geod_lat ) / cos( $geod_lat ), 1 );
  my $sin_lambda_sl = sin( $lambda_sl );
  my $sea_level_r = sqrt( EQU_RAD * EQU_RAD / ( 1 + ( ( 1 / ( E * E ) ) - 1 ) * $sin_lambda_sl * $sin_lambda_sl ) );

  return ( $geod_lat, $alt );
}

=item B<_geoc2par>

Convert geocentric latitude and distance from centre of Earth to
parallax constants.

  $parallax = $self->_geoc2par();

Returns a hash reference, where keys are 'Par_C' and 'Par_S' for
C and S constants, respectively.

=cut

sub _geoc2par {
  my $self = shift;

  return undef unless ( defined $self->{GeocLat} &&
                        defined $self->{GeocDist} );

  my %return;

  my $geoc_lat = $self->{GeocLat};
  my $geoc_dist = $self->{GeocDist};

  my $rho = $geoc_dist / EQU_RAD;

  $return{Par_C} = $rho * sin( $geoc_lat );
  $return{Par_S} = $rho * cos( $geoc_lat );

  return \%return;

}

=item B<_par2geoc>

Convert parallax constants to geocentric latitude and distance from
centre of Earth.

  ( $geoc_lat, $geoc_dist ) = $self->_par2geoc();

=cut

sub _par2geoc {
  my $self = shift;

  return undef unless ( defined $self->{Parallax} );

  my $par_S = $self->{Parallax}->{Par_S};
  my $par_C = $self->{Parallax}->{Par_C};

  my $geoc_lat = atan2( $par_C, $par_S );
  my $geoc_dist = sqrt( $par_S * $par_S + $par_C * $par_C ) * EQU_RAD;

  return( $geoc_lat, $geoc_dist );

}

=back

=head2 Backwards Compatibility

These methods are provided for programs that used the original
interface:

  lat_by_rad, long_by_rad, lat_by_deg, long_by_deg, alt_by_deg,
  alt_by_rad

=cut

sub lat_by_rad {
  my $self = shift;
  return $self->lat;
}

sub long_by_rad {
  my $self = shift;
  return $self->long;
}

sub alt_by_rad {
  my $self = shift;
  return $self->alt;
}

sub lat_by_deg {
  my $self = shift;
  return $self->lat('d');
}

sub long_by_deg {
  my $self = shift;
  return $self->long('d');
}

sub alt_by_deg {
  my $self = shift;
  return $self->alt('d');
}

=end __PRIVATE__

=head1 REQUIREMENTS

The list of telescope properties is currently obtained from those
provided by PAL (C<Astro::PAL>) and also from the Minor Planet
Center (http://www.cfa.harvard.edu/iau/lists/ObsCodes.html).

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>,
Brad Cavanagh E<lt>b.cavanagh@jach.hawaii.eduE<gt>

=head1 COPYRIGHT

Copyright (C) 2007, 2008, 2010, 2012 Science and Technology Facilities Council.
Copyright (C) 1998-2005 Particle Physics and Astronomy Research Council.
All Rights Reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

