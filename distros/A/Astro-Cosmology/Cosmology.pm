=head1 NAME

Astro::Cosmology - calculate cosmological distances, volumes, and times

=head1 DESCRIPTION

This module provides a set of routines to calculate a number
of cosmological quantities based on distance and time. Some are
a bit complex - e.g. the volume element at a given redshift - while
some, such as the conversion between flux and luminosity, are more mundane.

To calculate results for a given cosmology you create an
C<Astro::Cosmology> object with the desired cosmological parameters,
and then call the object's methods to perform the actual calculations.
If you aren't used to objects, it may sound confusing; hopefully
the L<SYNOPSIS|/SYNOPSIS> section below will help (after all, a
bit of code is worth a thousand words). The advantage of using an
object-orientated interface is that the object can carry around the
cosmological parameters, so you don't need to keep on specifying them
whenever you want to calculate anything; it also means you can write
routines which can just accept an C<Astro::Cosmology> object rather
than all the cosmological parameters.

This module I<requires> that the PDL distribution is installed
on your machine; PDL is available from CPAN or
http://pdl.perl.org/

=head1 WARNING

Whilst I believe the results are accurate, I do not guarantee this.
Caveat emptor, as the Romans used to say...

=head1 SYNOPSIS

  use Astro::Cosmology qw( :constants );

  # what is the luminosity distance, in metres, for
  # a couple of cosmologies
  #
  my $z   = sequence(10) / 10;
  my $eds = Astro::Cosmology->new;
  my $sn  = Astro::Cosmology->new( matter => 0.3, lambda => 0.7 );

  my $de  = 1.0e6 * PARSEC * $eds->lum_dist($z);
  my $ds  = 1.0e6 * PARSEC * $sn->lum_dist($z);

  # let's change the parameters of the $sn cosmology
  $sn->setvars( lambda=>0.6, matter=>0.2 );

=head1 UNITS

If H0 is set to 0, then the units used are the Hubble
distance, volume per steradian, or time. If greater than zero,
distances are measured in Mpc, volumes in Mpc^3/steradian,
and time in years.

=head1 NOTES

=over 4

=item *

The comoving volume routine gives a slightly smaller answer than
Figure 6 of Carroll, Press & Turner for z ~ 100. It could be due to
differences in the numerical methods, but I've not yet investigated
it thoroughly.

=item *

A year is defined to be YEAR_TROPICAL seconds.
Let me know if this is wrong.

=back

=head1 THEORY

The following calculations were cobbled together from a number
of sources, including the following (note that errors in the
documentation or code are mine, and are not due to these authors):

  Distance measures in cosmology, Hogg, D.W., astro-ph/9905116
  Perlmutter et al. 1997, ApJ, 483, 565
  Carroll, Press & Turner 1992, ARAA, 30, 499
  Weinberg, S., sections 14.6.8, 15.3.25
  Sandage, A. 1961, ApJ, 133, 355-392

In the following all values are in "natural" units:
Hubble distance, volume, or time.

Symbols used in the following:

  om    is omega_matter
  ol    is omega_lambda
  ok    is 1 - om - ol
  kappa is sqrt( abs(ok) )

=head2 Distances

For cosmologies with no lambda term, the luminosity distances
(C<dl>) are calculated by the standard formulae:

  empty:     dl = 0.5 * z * (2+z)
  flat:      dl = 2 * ( 1+z - sqrt(1+z) )
  otherwise: dl = (2 / (om*om)) *
                  ( om*z + (om-2) * (sqrt(1+om*z)-1) )

For non-zero lambda cosmologies, the luminosity distance is
calculated using:

  closed:  dl = (1+z) * sin( kappa * dc ) / kappa
  open:    dl = (1+z) * sinh( kappa * dc ) / kappa
  flat:    dl = (1+z) * dc

where C<dc> is the comoving distance, calculated by numerical
integration of the following from 0 to C<z>:

  1.0 / sqrt( (1+z)^2 * (1+om*z) - z*(2+z)*ol )

The comoving distance is always calculated by numerical
integration of the above formula. The angular diameter and
proper motion distances are defined as
C<dl/(1+z)^2> and C<dl/(1+z)> respectively.

=head2 Volumes

If C<dm> is the proper motion distance, then the
comoving volume C<vc> is given by

 flat:   vc = dm^3 / 3
 open:   vc = dm * sqrt(1+ok*dm^2) - asinh(dm*kappa) /
              ( 2 * kappa * ok )
 closed: vc = dm * sqrt(1+ok*dm^2) - asin(dm*kappa) /
              ( 2 * kappa * ok )

The differential comoving volume, C<dvc>, is calculated using
the proper motion distance, C<dm>, and the differential
proper motion distance, C<ddm>, by

  dvc = dm^2 * ddm / sqrt( 1 + ok*dm^2 )

where

  ddm = dc * sqrt( 1 + abs(ok) * dm^2 )

=head2 Times

The lookback time is calculated by integration of the following
formula from 0 to C<z>:

 1.0 / ( (1+z) * sqrt( (1+z)^2 * (1+om*z) - z*(2+z)*ol ) )

=head2 Flux and Magnitudes

The conversion between absolute and apparent magnitudes is
calculated using:

  $app_mag = $abs_mag + 25 + 5 * $cosmo->lum_dist($z)->log10();

The conversion between flux and luminosity is calculated using

  $lumin = FOURPI * $dl * $dl * $flux

where

  $dl = $cosmo->lum_dist($z) * 1.0e8 * PARSEC

Note that these equations do not include any pass-band
or evolutionary corrections.

=head2 Integration Technique

All integrations are performed using Romberg's method, which
is an iterative scheme using progressively higher-degree
polynomial approximations. The method stops when the answer
converges (ie the absolute difference in the values from the
last two iterations is smaller than the C<ABSTOL>
parameter, which is described in the L<new|/new> method).

Typically, the romberg integration scheme produces greater
accuracy for smooth functions when compared to simpler
methods (e.g. Simpson's method) while having little extra
overhead for badly-behaved functions.

=head1 CONSTANTS

Currently the following constants are available via
C<use Astro::Cosmology qw( :constants )>:

=over 4

=item *

LIGHT - the speed of light in m/s.

=item *

PARSEC - one parsec in metres.

=item *

STERADIAN - one steradian in degrees^2.

=item *

YEAR_TROPICAL - one tropical year in seconds.

=item *

PI - defined as 4.0 * atan(1.0,1.0) [this is in uppercase, whatever
this document may say]

=item *

FOURPI - 4.0 * PI [again PI should be in upper case here]

=back

Please do I<not> use this feature, as it will be removed when
an 'Astronomy constants' is created - e.g. see the astroconst
package at http://clavelina.as.arizona.edu/astroconst/ .

=head1 SYNTAX

This document uses the C<$object-E<gt>func(...)> syntax throughout.
If you prefer the C<func($object,...)> style, then you need to
import the functions:

  use Astro::Cosmology qw( :Func );

Most functions have two names; a short one and a (hopefully) more
descriptive one, such as C<pmot_dist()> and C<proper_motion_distance()>.

Most of the routines below include a C<sig:> line in their documentation.
This is an attempt to say how they
`L<thread|PDL::indexing>' (in the L<PDL|PDL> sense of the word).
So, for routines like C<lum_dist> - which have a sig line of
C<dl() = $cosmo-E<gt>lum_dist( z() )> - the return value has the
same format as the input C<$z> value; supply a scalar, get a scalar back,
send in a piddle and get a piddle of the same dimensions back.
For routines like C<abs_mag> - with a sig line of
C<absmag() = $cosmo-E<gt>abs_mag( appmag(), z() )> - you can thread over
either of the two input values,
in this case the apparent magnitude and redshift.

=head1 SUMMARY

=head2 Utility routines

=over 4

=item * new

=item * version

=item * stringify

=item * setvars

=item * matter/omega_matter, lambda/omega_lambda, h0/hO

=back

=head2 Distance measures

=over 4

=item * lum_dist/luminosity_distance

=item * adiam_dist/angular_diameter_distance

=item * pmot_dist/proper_motion_distance

=item * comov_dist/comoving_distance

=back

=head2 Volume measures

=over 4

=item * comov_vol/comoving_volume

=item * dcomov_vol/differential_comoving_volume

=back

=head2 Time measures

=over 4

=item * lookback_time

=back

=head1 ROUTINES

=head2 new

  my $cosmo = Astro::Cosmology->new(
                matter => 0.3, lambda => 0.7 );
  my $cosmo = Astro::Cosmology->new(
                { matter => 0.3, lambda => 0.7 } );

Create the object with the required cosmological parameters.
Case does not matter and you can use the minimum number of
letters which remain unique (the parsing is done by
the L<PDL::Options|PDL::Options> module).

The options can be specified directly as a list - as shown
in the first example above - or in a hash reference - as shown
in the second example. You can not mix the two forms within
a single call. The options are:

  OMEGA_MATTER or MATTER  - default 1.0
  OMEGA_LAMBDA or LAMBDA  - default 0.0
  H0           or HO      - default 50.0
  ABSTOL                  - default 1.0e-5

If H0 is set to 0, then answers are returned in units of the Hubble
distance, volume, or time, otherwise in Mpc, Mpc^3/steradian, or
years.

C<ABSTOL> (absolute tolerance) is used as a convergence criteria when
integrating functions as well as whether values are close enough to 0.
You should not have to worry about it.

=head2 version

  print "Version is " . Astro::Cosmology->version . "\n";
  if ( $cosmo->version > 0.9 ) {
    do_something_interesting();
  }

Returns the version number of the Astro::Cosmolgy module
as a string. This method is I<not> exported, so it has to
be called using either of the two methods shown above.

=head2 stringify

  print $cosmo;

Returns a string representation of the object. The operator "" is
overloaded by this function, so that C<print $cosmo> gives a
readable answer.

=head2 setvars

  $cosmo->setvars( matter => 0.3, lambda => 0.7 );

Change the cosmological parameters of the current object.
The options are the same as for L<new|/new>.

=head2 omega_matter or matter

  $cosmo->omega_matter( 1.0 );
  my $omega = $cosmo->omega_matter;

If supplied with an argument, sets the value of C<Omega_matter>.
Returns the current value of the parameter.

=head2 omega_lambda or lambda

  $cosmo->omega_lambda( 0.8 );
  my $lambda = $cosmo->omega_lambda;

If supplied with an argument, sets the value of C<Omega_lambda>.
Returns the current value of the parameter.

=head2 h0 or hO

  $cosmo->h0( 75 );
  my $cosmo->$h0 = h0;

If supplied with an argument, sets the value of C<H0>.
Returns the current value of the parameter.

=head2 lum_dist or luminosity_distance

  sig: dl() = $cosmo->lum_dist( z() )

  my $dl = $cosmo->lum_dist( $z );

returns the luminosity distance, for a given redshift, C<$z>,
for the current cosmology.

=head2 adiam_dist or angular_diameter_distance

  sig: da() = $cosmo->adiam_dist( z() )

  my $da = $cosmo->adiam_dist( $z );

returns the angular diameter distance, for a given redshift, C<$z>,
for the current cosmology.

=head2 pmot_dist or proper_motion_distance

  sig: dm() = $cosmo->pmot_dist( z() )

  my $dm = $cosmo->pmot_dist( $z );

returns the proper motion distance, for a given redshift, C<$z>,
for the current cosmology.

=head2 comov_dist or comoving_distance

  sig: dc() = $cosmo->comov_dist( z() )

  my $dc = $cosmo->comov_dist( $z );

returns the line-of-sight comoving distance, for a given redshift,
C<$z>, for the current cosmology.

=head2 comov_vol or comoving_volume

  sig: dv() = $cosmo->comov_vol( z() )

  my $dv = $cosmo->comov_vol( $z );

returns the comoving volume out to a given redshift,
C<$z>, for the current cosmology. Does not work if
C<omega_matter> and C<omega_lambda> are both 0.0.

=head2 dcomov_vol or differential_comoving_volume

  sig: ddv() = $cosmo->dcomov_vol( z() )

  my $ddv = $cosmo->dcomov_vol( $z );

returns the differential comoving volume at a given redshift,
C<$z>, for the current cosmology. Does not work if
C<omega_matter> and C<omega_lambda> are both 0.0.

=head2 lookback_time

  sig: t() = $cosmo->lookback_time( zmax() )
  sig: t() = $cosmo->lookback_time( zmin(), zmax() )

  my $delta_t = $cosmo->lookback_time( [$zmin,] $zmax );

Returns the lookback time between C<$zmin> and C<$zmax>. If
C<$zmin> is not supplied it defaults to 0.0.

=head2 abs_mag or absolute_magnitude

  sig: absmag() = $cosmo->abs_mag( appmag(), z() )

  my $absolute_mag = $cosmo->abs_mag( $apparent_mag, $z );

Returns the absolute magnitude - excluding K and evolutionary
corrections - for the given apparent magnitude.

=head2 app_mag or apparent_magnitude

  sig: appmag() = $cosmo->app_mag( absmag(), z() )

  my $apparent_mag = $cosmo->app_mag( $absolute_mag, $z );

Returns the apparent magnitude for a given absolute magnitude.
As with abs_mag, the K- and evolutionary-corrections are left
up to the user.

=head2 luminosity

  sig: lumin() = $cosmo->luminosity( flux(), z() )

  my $lumin = $cosmo->luminosity( $flux, $z );

Returns the luminosity of a source of a given flux.
As with abs_mag, the K- and evolutionary-corrections are left
up to the user.

The spatial units of the flux must be C<cm^-2>, so
a flux in C<erg/cm^2/s> will be converted into
a luminosity in C<erg/s>.

=head2 flux

  sig: flux() = $cosmo->flux( lumin(), z() )

  my $flux = $cosmo->flux( $lumin, $z );

Returns the flux of a source of a given luminosity.
As with C<abs_mag>, the K- and evolutionary-corrections are left
up to the user.

The spatial units of the flux is C<cm^-2>, so
a luminosity in C<erg/s> will be converted into
a flux in C<erg/cm^2/s>.

=head1 TODO

Add ability to request a particular unit; for example
have C<$cosmo-E<gt>lum_dist()> return I<cm> rather than
I<Mpc>.

Add the ability to use Pen's approximations
("Analytical Fit to the Luminosity Distance for Flat
Cosmologies with a Cosmological Constant", 1999, ApJS, 120, 49).

There is currently no method to calculate the age of the
universe at a given redshift.

=head1 ACKNOWLEDGEMENTS

Thanks to Brad Holden for trying out early versions of this module
and for providing some of the test code.

The cosmology routines make use of code based on routines from

  NUMERICAL METHODS: FORTRAN Programs, (c) John H. Mathews 1994
  NUMERICAL METHODS for Mathematics, Science and Engineering, 2nd Ed, 1992
  Prentice Hall, Englewood Cliffs, New Jersey, 07632, U.S.A.

The "Integration Technique" section of the documentation is based on that
from from the Math::Integral::Romberg module by Eric Boesch (available
on CPAN).

=head1 SEE ALSO

L<PDL>, L<Math::Integral::Romberg>.

=head1 AUTHOR

Copyright (C) Douglas Burke <djburke@cpan.org>
1999, 2000, 2001.

All rights reserved. There is no warranty.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

#############################################################################
##
## CODE
##
#############################################################################

package Astro::Cosmology;

## TODO
##   need access to constants (also used in Internal/internal.pd)
##   (ie the ones that define the type of cosmology)
##

use strict;

use Carp;

use vars qw( $VERSION );
$VERSION = '0.90';

## set up some constants
## -- really should be from something like Astro::Constants
##    (see Astroconst at http://clavelina.as.arizona.edu/astroconst/)

my @export_consts = qw(LIGHT PARSEC STERADIAN PI FOURPI YEAR_TROPICAL);

# these are taken from my old PDL::Astro::Constants module
use constant LIGHT     => 299792458;       # speed of light in m/s
use constant PARSEC    => 3.085678e16;     # 1 parsec in m
use constant STERADIAN => 3282.80635;      # 1 steradian in deg^2

use constant YEAR_TROPICAL => 3.1556926e7; # 1 year (tropical) in seconds

use constant PI     => 4.0 * atan2(1.0,1.0);   # should perhaps fix the value, rather than calculate it
use constant FOURPI => 16.0 * atan2(1.0,1.0);   # should perhaps fix the value, rather than calculate it

my @export_funcs = 
  (
  qw(
     new setvars omega_matter matter omega_lambda lambda h0 h0
     abs_mag absolute_magnitude app_mag apparent_magnitude
     luminosity flux lookback_time lum_dist luminosity_distance
     pmot_dist proper_motion_distance adiam_dist angular_diameter_distance
     comov_dist comoving_distance comov_vol comovoing_volume
     dcomov_vol differential_comoving_volume
    )
  );

# set up the exports
use vars qw ( @EXPORT_OK %EXPORT_TAGS );
@EXPORT_OK = ( @export_funcs, @export_consts );
%EXPORT_TAGS = ( 
		Func => [@export_funcs],
		constants => [@export_consts], 
	       );

####################################################################
####################################################################

# This is a hack - we should load these in from Astro::Cosmology::Internal,
# or have them created from the same file
#
use constant UNKNOWN       =>  0;
use constant EMPTY         =>  1;
use constant MATTER_FLAT   =>  2;
use constant MATTER_OPEN   =>  3;
use constant MATTER_CLOSED =>  4;
use constant LAMBDA_FLAT   => 10;
use constant LAMBDA_OPEN   => 11;
use constant LAMBDA_CLOSED => 12;

####################################################################
####################################################################

use Astro::Cosmology::Internal;

## Public routines:

sub version { return "$VERSION"; }

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;

    # class structure
    my $self = {};

    # set up the default options, and apply any that are given
    $self->{options} =
	new PDL::Options {
	    OMEGA_MATTER => 1.0,
	    OMEGA_LAMBDA => 0.0,
	    H0           => 50.0,
	    ABSTOL       => 1.0e-5
	};
    $self->{options}->synonyms( { MATTER => 'OMEGA_MATTER', LAMBDA => 'OMEGA_LAMBDA', HO => 'H0' } );
    $self->{options}->incremental( 1 );

    bless $self, $class;

    # check values are sensible, sort out ancillary variables
    $self->setvars( @_ );

    # return the object
    return $self;

} # sub: new()

use overload ("\"\""   =>  \&Astro::Cosmology::stringify);
sub stringify {
    my $self = shift;
    my $om   = $self->matter();
    my $ol   = $self->lambda();
    my $h0   = $self->h0();
    return "[ Omega_matter = $om  Omega_lambda = $ol  H0 = $h0 km/s/Mpc ]";
} # sub: stringify()

sub setvars ($$) {
    my $self = shift;

    if ( ref($_[0]) eq "HASH" ) {
	$self->{options}->options( shift );
    } else {
	my %opts = ( @_ );
	$self->{options}->options( \%opts );
    }

    my $dataref = $self->{options}->current();

    my $matter  = $self->{OMEGA_MATTER} = $$dataref{OMEGA_MATTER};
    my $lambda  = $self->{OMEGA_LAMBDA} = $$dataref{OMEGA_LAMBDA};
    my $h0      = $self->{H0}           = $$dataref{H0};
    my $abstol  = $self->{ABSTOL}       = abs( $$dataref{ABSTOL} );

    $self->{COSMOLOGY} = UNKNOWN;

    # sensible values
    croak "ERROR: H0 must be >= 0.0.\n" unless $h0 >= 0.0;

    # conversion values (distance/volume/time calculations)
    # perhaps I should have called them HUBBLE_DIST/VOL/TIME ?
    if ( $h0 > $abstol ) {
	$self->{DCONV} = LIGHT * 1.0e-3 / $h0;
	$self->{VCONV} = LIGHT * LIGHT * LIGHT * 1.0e-9 / ( $h0 * $h0 * $h0);
	$self->{TCONV} = PARSEC * 1.0e3 / (YEAR_TROPICAL * $h0);
    } else {
	$self->{DCONV} = 1.0;
	$self->{VCONV} = 1.0;
	$self->{TCONV} = 1.0;
    }

    # just to ensure that it's defined
    my $kappa  = 1.0 - $matter - $lambda;
    $self->{OMEGA_KAPPA} = $kappa;
    $self->{KAPPA} = sqrt( abs($kappa) );

    # special case ?
    #
    if ( abs( $lambda ) <= $abstol ) {
	# lambda == 0.0

	if ( abs($matter) <= $abstol ) {
	    $self->{COSMOLOGY} = EMPTY;
	} elsif ( abs($kappa) <= $abstol ) {
	    $self->{COSMOLOGY} = MATTER_FLAT;
	} elsif ( $matter < 1.0 ) {
	    $self->{COSMOLOGY} = MATTER_OPEN;
	} else {
	    $self->{COSMOLOGY} = MATTER_CLOSED;
	}

    } else {
	# lambda != 0.0

	if ( $kappa < -$abstol ) {
	    # Closed
	    $self->{COSMOLOGY} = LAMBDA_CLOSED;
	} elsif ( $kappa > $abstol ) {
	    # Open
	    $self->{COSMOLOGY} = LAMBDA_OPEN;
	} else {
	    $self->{COSMOLOGY} = LAMBDA_FLAT;
	}
    }

    # this would indicate a coding error!
    croak "Unknown cosmology - omega_matter = $matter  omega_lambda = $lambda.\n"
	if $self->{COSMOLOGY} == UNKNOWN;

} # sub: setvars()

sub omega_matter ($;$) {
    my $self = shift;
    $self->setvars( OMEGA_MATTER => $_[0] ) if @_;
    return $self->{OMEGA_MATTER};
}
*matter = \&omega_matter;

sub omega_lambda ($;$) {
    my $self = shift;
    $self->setvars( OMEGA_LAMBDA => $_[0] ) if @_;
    return $self->{OMEGA_LAMBDA};
}
*lambda = \&omega_lambda;

sub h0 ($;$) {
    my $self = shift;
    $self->setvars( H0 => $_[0] ) if @_;
    return $self->{H0};
}
*hO = \&h0;

# we ignore the need for K/evolutionary corrections
# in the following
#
# NOTE:
#   correct use of units is rather poor
#
sub abs_mag ($$$) {
    my ( $self, $apparent, $z ) = @_;

    return ( $apparent - 25 - 5 * $self->lum_dist($z)->log10() );

} # sub: abs_mag()
*absolute_magnitude = \&abs_mag;

sub app_mag ($$$) {
    my ( $self, $absolute, $z ) = @_;

    return ( $absolute + 25 + 5 * $self->lum_dist($z)->log10() );

} # sub: app_mag()
*apparent_magnitude = \&app_mag;

sub luminosity ($$$) {
    my ( $self, $flux, $z ) = @_;

    my $dl = $self->lum_dist($z) * 1.0e8 * PARSEC;  # convert to cm
    return ( FOURPI * $dl * $dl * $flux );

} # sub: luminosity()

sub flux ($$$) {
    my ( $self, $luminosity, $z ) = @_;

    my $dl = $self->lum_dist($z) * 1.0e8 * PARSEC;  # convert to cm
    return ( $luminosity / ( FOURPI * $dl * $dl ) );

} # sub: flux()

# note:
#  one parameter:  age of z = 0  -> $1
#  two parameters: age of z = $1 -> $2
#
# ie lookback_time ( [ $z_low ], $z_high )
#
# note: we call the C code directly
#
sub lookback_time ($$;$) {
    my $self   = shift;
    my $z_low  = $#_ == 1 ? shift : 0;   # let PDL do the threading if z_high is a piddle
    my $z_high = shift;

    return Astro::Cosmology::Internal::_lookback_time( $z_low, $z_high,
			   $self->{OMEGA_MATTER}, $self->{OMEGA_LAMBDA},
			   $self->{ABSTOL}, $self->{TCONV} );

} # sub: lookback_time

####################################################################
#
# distance measures: PM code
#
####################################################################

sub lum_dist ($$) {
    my $self = shift;
    my $z    = shift;

    return Astro::Cosmology::Internal::_lum_dist( $z, $self->{COSMOLOGY}, $self->{OMEGA_MATTER}, $self->{OMEGA_LAMBDA},
		      $self->{KAPPA}, $self->{ABSTOL}, $self->{DCONV} );

} # sub: lum_dist()
*luminosity_distance = \&lum_dist;

sub pmot_dist ($$) {
    my $self = shift;
    my $z    = shift;

    return Astro::Cosmology::Internal::_lum_dist( $z, $self->{COSMOLOGY}, $self->{OMEGA_MATTER}, $self->{OMEGA_LAMBDA},
		      $self->{KAPPA}, $self->{ABSTOL}, $self->{DCONV} ) /
			  (1.0+$z);

} # sub: pmot_dist()
*proper_motion_distance = \&pmot_dist;

sub adiam_dist ($$) {
    my $self = shift;
    my $z    = shift;

    return Astro::Cosmology::Internal::_lum_dist( $z, $self->{COSMOLOGY}, $self->{OMEGA_MATTER}, $self->{OMEGA_LAMBDA},
		      $self->{KAPPA}, $self->{ABSTOL}, $self->{DCONV} ) /
			  ( (1.0+$z) * (1.0+$z) );

} # sub: adiam_dist()
*angular_diameter_distance = \&adiam_dist;

sub comov_dist ($$) {
    my $self = shift;
    my $z    = shift;

    return Astro::Cosmology::Internal::_comov_dist( $z, $self->{OMEGA_MATTER}, $self->{OMEGA_LAMBDA},
			$self->{ABSTOL}, $self->{DCONV} );

} # sub: comov_dist()
*comoving_distance = \&comov_dist;

####################################################################
#
# volume measures: PM code
#
####################################################################

sub comov_vol ($$) {
    my $self = shift;
    my $z    = shift;

    # we want dm to be in units of the hubble distance, which
    # means that we need DCONV == 1
    my $_dconv = $self->{DCONV};
    $self->{DCONV} = 1.0;
    my $dm = $self->pmot_dist( $z );
    $self->{DCONV} = $_dconv;

    return Astro::Cosmology::Internal::_comov_vol( $dm, $self->{COSMOLOGY},
		       $self->{OMEGA_MATTER}, $self->{OMEGA_LAMBDA}, $self->{OMEGA_KAPPA},
		       $self->{KAPPA}, $self->{VCONV} );

} # sub: comov_vol()
*comoving_volume = \&comov_vol;

sub dcomov_vol ($$) {
    my $self = shift;
    my $z    = shift;

    # we want dm to be in units of the hubble distance, which
    # means that we need _DCONV == 1
    my $_dconv = $self->{DCONV};
    $self->{DCONV} = 1.0;
    my $dm = $self->pmot_dist( $z );
    $self->{DCONV} = $_dconv;

    # calculate the differential proper motion distance
    my $ddmdz = Astro::Cosmology::Internal::_dpmot( $z, $dm, $self->{COSMOLOGY},
			$self->{OMEGA_MATTER}, $self->{OMEGA_LAMBDA}, $self->{OMEGA_KAPPA} );

    return Astro::Cosmology::Internal::_dcomov_vol( $dm, $ddmdz, $self->{OMEGA_KAPPA}, $self->{VCONV} );

} # sub: dcomov_vol()
*differential_comoving_volume = \&dcomov_vol;

## End
1;


