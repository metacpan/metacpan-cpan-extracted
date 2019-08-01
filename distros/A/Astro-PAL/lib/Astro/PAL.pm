package Astro::PAL;

=head1 NAME

Astro::PAL - Perl interface to Starlink PAL positional astronomy library

=head1 SYNOPSIS

  use PAL;
  use PAL qw(:constants :pal);

  ($ra2000, $dec2000) = palFk45z($ra, $dec, 1950.0);
  ($mjd, $status) = palCldj($yy, $mn, $dd);

  ($lst, $mjd) = lstnow($long);
  ($lst, $mjd) = ut2lst_tel($yy,$mn,$dd,$hh,$mm,$ss,'JCMT');

=head1 DESCRIPTION

This modules provides a Perl interface to either the Starlink
PAL positional astronomy library.

Return values are returned on the stack rather than being modified
in place.

In addition small utility subroutines are provided that
do useful tasks (from the author's point of view) - specifically
routines for calculating the Local Sidereal Time.

=cut

# '  -- close quote for my 'authors' apostrophe above.

use strict;
use Carp;
use vars qw($VERSION %EXPORT_TAGS);

use Exporter 'import';
use base qw/ DynaLoader /;

$VERSION = '1.08';

%EXPORT_TAGS = (
                'pal'=>[qw/
                            palAddet
                            palAirmas
                            palAltaz
                            palAmp
                            palAmpqk
                            palAop
                            palAoppa
                            palAoppat
                            palAopqk
                            palAtmdsp
                            palCaldj
                            palCldj
                            palDaf2r
                            palDafin
                            palDat
                            palDav2m
                            palDbear
                            palDcc2s
                            palDcmpf
                            palDcs2c
                            palDd2tf
                            palDe2h
                            palDeuler
                            palDfltin
                            palDh2e
                            palDimxv
                            palDjcal
                            palDjcl
                            palDm2av
                            palDmoon
                            palDmxm
                            palDmxv
                            palDpav
                            palDr2af
                            palDr2tf
                            palDrange
                            palDranrm
                            palDs2tp
                            palDsep
                            palDsepv
                            palDt
                            palDtf2d
                            palDtf2r
                            palDtp2s
                            palDtps2c
                            palDtt
                            palDvdv
                            palDvn
                            palDvxv
                            palEcmat
                            palEcleq
                            palEpb
                            palEpb2d
                            palEpco
                            palEpj
                            palEpj2d
                            palEpv
                            palEqecl
                            palEqeqx
                            palEqgal
                            palEtrms
                            palEvp
                            palFk45z
                            palFk524
                            palFk54z
                            palFitxy
                            palGaleq
                            palGalsup
                            palGeoc
                            palGmst
                            palGmsta
                            palHfk5z
                            palIntin
                            palInvf
                            palMap
                            palMappa
                            palMapqk
                            palMapqkz
                            palNut
                            palNutc
                            palOap
                            palOapqk
                            palObs
                            palPa
                            palPcd
                            palPertel
                            palPertue
                            palPlanel
                            palPlanet
                            palPlante
                            palPm
                            palPolmo
                            palPrebn
                            palPrec
                            palPreces
                            palPrenut
                            palPvobs
                            palPxy
                            palRdplan
                            palRefco
                            palRefcoq
                            palRefro
                            palRefv
                            palRefz
                            palRverot
                            palRvgalc
                            palRvlg
                            palRvlsrd
                            palRvlsrk
                            palSubet
                            palSupgal
                            palUnpcd
                            palXy2xy
                          /],
                'constants'=>[qw/
                                  DPI D2PI D1B2PI D4PI D1B4PI DPISQ DSQRPI DPIBY2
                                  DD2R DR2D DAS2R DR2AS DH2R DR2H DS2R DR2S D15B2P
                                /],
                'funcs'=>[qw/
			  lstnow lstnow_tel ut2lst ut2lst_tel
			  /]
		);


Exporter::export_tags('pal','constants','funcs');

bootstrap Astro::PAL;


=head1 Routines

There are 3 distinct groups of routines that can be imported into
the namespace via tags:

=over 4

=item pal - import just the PAL routines

=item constants - import the PAL constants

=item funcs - import the extra routines

=back

Each group will be discussed in turn.

=head2 PAL

The PAL routines directly match the C API with the caveat that returned
values are returned on the perl argument stack rather than being modified
directly in the call arguments. Arguments are never modified. This differs
from the Astro::SLA wrapper around the SLALIB library.

For example,

  ($xi, $eta, $j) = palDst2p( $ra, $dec, $raz, $decz );
  @pv = palDmoon( $date );
  ($nstrt, $fd, $j) = palDafin( $time, $nstrt );


If a routine returns an array as well as a status the status value
is returned first:

 ($j, @iymsf) = palDjcal( $ndp, $djm );

If a routine returns multiple arrays they are returned as references:

 ($dvb, $dpb, $dvh, $dph) = palEvp( $date, $deqx );
 @dvbarr = @$dvb;

Routines that take vectors or matrices should be given references
to arrays:

 @rmatn = palNut( $djtt );
 @mposr = palDmxv( \@rmatn, \@mpos );

See the PAL or SLALIB documentation for details of the functions
themselves.

=head3 Anomalies

=over 4

=item palObs

palObs is special in that it returns an empty list if the return
status is bad. Additionally, palObs is called with a single
argument and the behaviour depends on whether the argument looks
like an integer or a string.

 ($ident, $name, $w, $p, $h) = palObs( 27 );
 ($ident, $name, $w, $p, $h) = palObs( "JCMT" );

=cut

# We need a local version of palObs that converts the single
# argument to the right form for the internal XS implementation

sub palObs {
  my $arg = shift;
  return () unless defined $arg;

  my $n = 0;
  my $c = "";

  if ( $arg =~ /^\d+$/) {
    $n = $arg;
  } else {
    $c = $arg;
  }

  return _palObs( $n, $c );
}

=item palAopqk

palAopqk can be called either with a reference to an
array or a list

  @results = palAopqk( $rap, $dap, @aoprms );
  @results = palAopqk( $rap, $dap, \@aoprms );

=cut

# Sanity check argument counting before passing to XS layer

sub palAopqk {
  my $rap = shift;
  my $dap = shift;

  my @aoprms;
  if (@_ > 1) {
    @aoprms = @_;
  } else {
    @aoprms = @{$_[0]};
  }
  croak "palAopqk: Need 14 elements in star-independent apparent to observed array"
    unless @aoprms == 14;

  return pal_Aopqk( $rap, $dap, \@aoprms );
}

=item palAoppat

For the C API the calling convention is to modify the AOPRMS array in
place, for the perl API we accept the AOPRMS array but return the
updated version.

  @aoprms = Astro::PAL::palAoppat( $date, \@aoprms );
  @aoprms = Astro::PAL::palAoppat( $date, @aoprms );

=cut

sub palAoppat {
  croak 'Usage: palAoppat( date, @aoprms )'
    unless @_ > 1;

  my $date = shift;

  my @aoprms;
  if (@_ > 1) {
    @aoprms = @_;
  } else {
    @aoprms = @{$_[0]};
  }

  croak "palAoppat: Need 14 elements in star-independent apparent to observed array"
    unless @aoprms == 14;

  $aoprms[13] = pal_Aoppat( $date, $aoprms[12] );

  return @aoprms;

}


# palAoppat C interface requires the full @AOPRMS array and simply updates
# element 13 based on element 12.

=back

=head2 Constants

Constants supplied by this module (note that they are implemented via the
L<constant> pragma):

=over 4

=item DPI - Pi

=item D2PI - 2 * Pi

=item D1B2PI - 1 / (2 * Pi)

=item D4PI - 4 * Pi

=item D1B4PI - 1 / (4 * Pi)

=item DPISQ - Pi ** 2 (Pi squared)

=item DSQRPI - sqrt(Pi)

=item DPIBY2 - Pi / 2: 90 degrees in radians

=item DD2R - Pi / 180: degrees to radians

=item DR2D - 180/Pi:  radians to degrees

=item DAS2R - pi/(180*3600): arcseconds to radians

=item DR2AS - 180*3600/pi: radians to arcseconds

=item DH2R - pi/12: hours to radians

=item DR2H - 12/pi: radians to hours

=item DS2R - pi / (12*3600): seconds of time to radians

=item DR2S - 12*3600/pi: radians to seconds of time

=item D15B2P - 15/(2*pi): hours to degrees * radians to turns

=back

=cut

# Could implement these directly via the include file in the XS layer.
# Since these cant change - implement them explicitly.

# Pi
use constant DPI => 3.1415926535897932384626433832795028841971693993751;

# 2pi
use constant D2PI => 6.2831853071795864769252867665590057683943387987502;

# 1/(2pi)
use constant D1B2PI => 0.15915494309189533576888376337251436203445964574046;

# 4pi
use constant D4PI => 12.566370614359172953850573533118011536788677597500;

# 1/(4pi)
use constant D1B4PI => 0.079577471545947667884441881686257181017229822870228;

# pi^2
use constant DPISQ => 9.8696044010893586188344909998761511353136994072408;

# sqrt(pi)
use constant DSQRPI => 1.7724538509055160272981674833411451827975494561224;

# pi/2:  90 degrees in radians
use constant DPIBY2 => 1.5707963267948966192313216916397514420985846996876;

# pi/180:  degrees to radians
use constant DD2R => 0.017453292519943295769236907684886127134428718885417;

# 180/pi:  radians to degrees
use constant DR2D => 57.295779513082320876798154814105170332405472466564;

# pi/(180*3600):  arcseconds to radians
use constant DAS2R => 4.8481368110953599358991410235794797595635330237270e-6;

# 180*3600/pi :  radians to arcseconds
use constant DR2AS => 2.0626480624709635515647335733077861319665970087963e5;

# pi/12:  hours to radians
use constant DH2R => 0.26179938779914943653855361527329190701643078328126;

# 12/pi:  radians to hours
use constant DR2H => 3.8197186342054880584532103209403446888270314977709;

# pi/(12*3600):  seconds of time to radians
use constant DS2R => 7.2722052166430399038487115353692196393452995355905e-5;

# 12*3600/pi:  radians to seconds of time
use constant DR2S => 1.3750987083139757010431557155385240879777313391975e4;

# 15/(2pi):  hours to degrees x radians to turns
use constant D15B2P => 2.3873241463784300365332564505877154305168946861068;


=head2 Extra functions

These are exportable using the 'funcs' tag or used directly
through the Astro::PAL namespace.

They directly match the Astro::SLA equivalents.

=over 4

=item B<lstnow_tel>

Return current LST (in radians) and MJD for a given telescope.
The telescope identifiers should match those present in palObs.
The supplied telescope name is converted to upper case.

   ($lst, $mjd) = lstnow_tel($tel);

Aborts if telescope name is unknown.

=cut

sub lstnow_tel {

  croak 'Usage: lstnow_tel($tel)' unless scalar(@_) == 1;

  my $tel = shift;

  # Upper case the telescope
  $tel = uc($tel);

  # Find the longitude of this telescope
  my ($ident, $name, $w, $p, $h) = palObs( $tel );

  # Check telescope name
  croak "Telescope name $tel unrecognised by palObs()"
    unless defined $ident;

  # Convert longitude to west negative
  $w *= -1.0;

  # Run lstnow
  lstnow($w);

}


=item B<lstnow>

Return current LST (in radians) and MJD (days)
Longitude should be negative if degrees west
and in radians.

  ($lst, $mjd) = lstnow($long);

=cut

sub lstnow {

  croak 'Usage: lstnow($long)' unless scalar(@_) == 1;

  my $long = shift;

  my ($sign, @ihmsf);

  # Get current UT time
  my ($sec, $min, $hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);

  # Calculate LST
  $year += 1900;
  $mon++;
  my ($lst, $mjd) = ut2lst($year, $mon, $mday, $hour, $min, $sec, $long);

  return ($lst, $mjd);

}


=item B<ut2lst>

Given the UT time, calculate the Modified Julian date (UTC) and the
local sidereal time (radians) for the specified longitude.

 ($lst, $mjd) = ut2lst(yy, mn, dd, hh, mm, ss, long)

Longitude should be negative if degrees west and in radians.

=cut

sub ut2lst {

  croak 'Usage: ut2lst(yy,mn,dd,hh,mm,ss,long)'
    unless scalar(@_) == 7;

  my ($yy, $mn, $dd, $hh, $mm, $ss, $long) = @_;

  # Calculate fraction of day
  my ($fd, $j) = palDtf2d($hh, $mm, $ss);
  if ($j != 0) {
    croak "Error calculating fractional day with H=$hh M=$mm S=$ss\n";
  }

  # Calculate modified julian date of UT day
  my ($mjd, $palstatus) = palCldj($yy, $mn, $dd);

  if ($palstatus != 0) {
    croak "Error calculating modified Julian date with args: $yy $mn $dd\n";
  }

  # Calculate sidereal time of greenwich
  my $gmst = palGmsta($mjd, $fd);

  # Find MJD of current time (not just day)
  $mjd += $fd;

  # Equation of the equinoxes (requires TT although makes very
  # little differnece)
  my $tt = $mjd + ( palDtt($mjd) / 86_400.0);
  my $eqeqx = palEqeqx($tt);

  # Local sidereal time = GMST + EQEQX + Longitude in radians
  my $lst = palDranrm($gmst + $eqeqx + $long);

  return ($lst, $mjd);
}

=item B<ut2lst_tel>

Given the UT time, calculate the Modified Julian date and the
local sidereal time (radians) for the specified telescope.

 ($lst, $mjd) = ut2lst_tel(yy, mn, dd, hh, mm, ss, tel)

=cut

sub ut2lst_tel ($$$$$$$) {
  croak 'Usage: ut2lst_tel($tel)' unless scalar(@_) == 7;

  my $tel = pop(@_);

  # Upper case the telescope
  $tel = uc($tel);

  # Find the longitude of this telescope
  my ($ident, $name, $w, $p, $h) = palObs($tel);

  # Check telescope name
  croak "Telescope name $tel unrecognised by palObs()"
    unless defined $ident;

  # Convert longitude to west negative
  $w *= -1.0;

  # Run ut2lst
  return ut2lst(@_, $w);

}

=back


=head1 AUTHOR

Tim Jenness E<gt>tjenness@cpan.orgE<lt>

=head1 REQUIREMENTS

The PAL library is available from Starlink.

=head1 COPYRIGHT

Copyright (C) 2014 Tim Jenness
Copyright (C) 2012 Tim Jenness and the Science and Technology Facilities
Council.

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
