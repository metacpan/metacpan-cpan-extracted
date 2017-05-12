package Astro::SLA;

=head1 NAME

Astro::SLA - Perl interface to SLAlib positional astronomy library

=head1 SYNOPSIS

  use SLA;
  use SLA qw(:constants :sla);

  slaFk45z($ra, $dec, 1950.0, $ra2000, $dec2000);
  slaCldj($yy, $mn, $dd, $mjd, $status);

  ($lst, $mjd) = lstnow($long);
  ($lst, $mjd) = ut2lst_tel($yy,$mn,$dd,$hh,$mm,$ss,'JCMT');

=head1 DESCRIPTION

This modules provides a Perl interface to either the C or Fortran
versions of the SLALIB astrometry library written by Pat Wallace.

In general the single precision routines have not been
implemented since perl can work in double precision.

The SLALIB constants (as provided in slamac.h) are available.

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

$VERSION = '1.03';

%EXPORT_TAGS = (
                'sla'=>[qw/
                            slaAddet slaAfin slaAirmas slaAmp slaAmpqk
                            slaAop slaAoppa slaAoppat slaAopqk slaAtmdsp
                            slaAv2m slaBear slaCaf2r slaCaldj slaCalyd
                            slaCc2s slaCc62s slaCd2tf slaCldj slaClyd
                            slaCr2af slaCr2tf slaCs2c6 slaDaf2r slaDafin
                            slaDat slaDav2m slaDbear slaDbjin slaDc62s
                            slaDcc2s slaDcmpf slaDcs2c slaDd2tf slaDe2h
                            slaDeuler slaDfltin slaDh2e slaDimxv slaDjcal
                            slaDjcl slaDm2av slaDmoon slaDmxm slaDmxv slaDpav
                            slaDr2af slaDr2tf slaDrange slaDranrm slaDs2c6
                            slaDs2tp slaDsep slaDtf2d slaDtf2r slaDtp2s
                            slaDtp2v slaDtps2c slaDtpv2c slaDtt slaDv2tp
                            slaDvdv slaDvn slaDvxv slaE2h slaEarth slaEcleq
                            slaEcmat slaEcor slaEg50 slaEpb slaEpb2d slaEpco
                            slaEpj slaEpj2d slaEqecl slaEqeqx slaEqgal
                            slaEtrms slaEuler slaEvp slaFk425 slaFk45z
                            slaFk54z slaFloatin slaGaleq slaGalsup slaGe50
                            slaGeoc slaGmst slaGmsta slaGresid slaH2e slaImxv
                            slaInvf slaKbj slaM2av slaMap slaMappa slaMapqk
                            slaMapqkz slaMoon slaMxm slaMxv slaNut slaNutc
                            slaOap slaOapqk slaObs slaPa slaPav slaPcd
                            slaPertue slaPertel
                            slaPda2h slaPdq2h slaPlanel slaPlanet slaPlante
                            slaPm slaPolmo slaPrebn slaPrec slaPreces
                            slaPrecl slaPrenut slaPvobs slaRandom slaRange
                            slaRanorm slaRcc slaRdplan slaRefco slaRefcoq
                            slaRefv slaRefz slaRverot slaRvgalc slaRvlg
                            slaRvlsrd slaRvlsrk slaS2tp slaSep slaSubet
                            slaSupgal slaTp2s slaTp2v slaTps2c slaTpv2c
                            slaUnpcd slaV2tp slaVdv slaVxv slaWait slaXy2xy
                            slaZd slaIntin
                          /],

                'constants'=>[qw/
                                  DPI D2PI D1B2PI D4PI D1B4PI DPISQ DSQRPI DPIBY2
                                  DD2R DR2D DAS2R DR2AS DH2R DR2H DS2R DR2S D15B2P
                                /],

                'funcs'=>[qw/
                              lstnow lstnow_tel ut2lst ut2lst_tel
                            /]
               );


Exporter::export_tags('sla','constants','funcs');

bootstrap Astro::SLA;


=head1 Routines

There are 3 distinct groups of routines that can be imported into
the namespace via tags:

=over 4

=item sla - import just the SLALIB routines

=item constants - import the SLALIB constants

=item funcs - import the extra routines

=back

Each group will be discussed in turn.

=head2 sla

All the double precision SLA routines are implemented except for
slaPxy, slaDmat, slaSvd, slaSvdcov, slaSvdsol (I may do these some
other time -- although they should be done in C<PDL>).

The implemented routines are:

 slaAddet slaAfin slaAirmas slaAmp slaAmpqk slaAop
 slaAoppa slaAoppat slaAopqk slaAtmdsp slaAv2m slaBear
 slaCaf2r slaCaldj slaCalyd slaCc2s slaCc62s slaCd2tf
 slaCldj slaClyd slaCr2af slaCr2tf slaCs2c6 slaDaf2r
 slaDafin slaDat slaDav2m slaDbear slaDbjin slaDc62s
 slaDcc2s slaDcmpf slaDcs2c slaDd2tf slaDe2h slaDeuler
 slaDfltin slaDh2e slaDimxv slaDjcal slaDjcl slaDm2av
 slaDmoon slaDmxm slaDmxv slaDpav slaDr2af slaDr2tf
 slaDrange slaDranrm slaDs2c6 slaDs2tp slaDsep slaDtf2d
 slaDtf2r slaDtp2s slaDtp2v slaDtps2c slaDtpv2c slaDtt
 slaDv2tp slaDvdv slaDvn slaDvxv slaE2h slaEarth slaEcleq
 slaEcmat slaEcor slaEg50 slaEpb slaEpb2d slaEpco slaEpj
 slaEpj2d slaEqecl slaEqeqx slaEqgal slaEtrms slaEuler
 slaEvp slaFk425 slaFk45z slaFk54z slaFloatin slaGaleq
 slaGalsup slaGe50 slaGeoc slaGmst slaGmsta slaGresid slaH2e
 slaImxv slaInvf slaKbj slaM2av slaMap slaMappa slaMapqk
 slaMapqkz slaMoon slaMxm slaMxv slaNut slaNutc slaOap
 slaOapqk slaObs slaPa slaPav slaPcd slaPda2h slaPdq2h
 slaPlanel slaPlanet slaPlante slaPm slaPolmo slaPrebn
 slaPrec slaPreces slaPrecl slaPrenut slaPvobs slaRandom
 slaRange slaRanorm slaRcc slaRdplan slaRefco slaRefcoq
 slaRefv slaRefz slaRverot slaRvgalc slaRvlg slaRvlsrd
 slaRvlsrk slaS2tp slaSep slaSubet slaSupgal slaTp2s slaTp2v
 slaTps2c slaTpv2c slaUnpcd slaV2tp slaVdv slaVxv slaWait
 slaXy2xy slaZd slaIntin

Also, slaGresid and slaRandom are not in the C library (although they
are in the Fortran version).  slaWait is implemented using the perl
'select(ready file descriptors)' command.

In general single precision routines are simply aliases of the
double precision equivalents.

For more information on the SLALIB routines consult the Starlink
documentation (Starlink User Note 67 (SUN/67)). This document
is available from the Starlink web site (http://www.starlink.ac.uk/)
[SUN67 available from:
http://www.starlink.ac.uk/cgi-bin/htxserver/sun67.htx/sun67.html ]


=cut

# Implement at the perl level (command is unimplemented at C level)

sub slaWait ($) {
  my $delay = shift;
  select (undef, undef, undef, $delay);

}


# slaObs
#   In order to overcome a segmentation violation under linux (at least)
#   occuring when 'c' is set to undef but is to be a return value
#   have a perl layer that replaces undef with '' in order to fix the
#   issue
# We also do this so that a constant can be supplied as the argument.
# undef first argument is converted to -1

sub slaObs ($$$$$$) {
  my $c = (defined $_[1] ? $_[1] : '');
  my $outc;
  my $n = (defined $_[0] ? $_[0] : -1);
  _slaObs($n, $c, $outc, $_[2], $_[3], $_[4], $_[5]);

  # Copy outc to the caller namespace only if a positive
  # number was specified to slaObs
  if ($n > 0) {
    $_[1] = $outc;
  }

  return;
}

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


=head2 Extra functions (using the 'funcs' tag)


=over 4

=item B<lstnow_tel>

Return current LST (in radians) and MJD for a given telescope.
The telescope identifiers should match those present in slaObs.
The supplied telescope name is converted to upper case.

   ($lst, $mjd) = lstnow_tel($tel);

Aborts if telescope name is unknown.

=cut

sub lstnow_tel {

  croak 'Usage: lstnow_tel($tel)' unless scalar(@_) == 1;

  my $tel = shift;

  # Upper case the telescope
  $tel = uc($tel);

  my ($w, $p, $h, $name);

  # Find the longitude of this telescope
  slaObs(-1, $tel, $name, $w, $p, $h);

  # Check telescope name
  if ($name eq '?') {
    croak "Telescope name $tel unrecognised by slaObs()";
  }

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
  slaDtf2d($hh, $mm, $ss, my $fd, my $j);
  if ($j != 0) {
    croak "Error calculating fractional day with H=$hh M=$mm S=$ss\n";
  }

  # Calculate modified julian date of UT day
  slaCldj($yy, $mn, $dd, my $mjd, my $slastatus);

  if ($slastatus != 0) {
    croak "Error calculating modified Julian date with args: $yy $mn $dd\n";
  }

  # Calculate sidereal time of greenwich
  my $gmst = slaGmsta($mjd, $fd);

  # Find MJD of current time (not just day)
  $mjd += $fd;

  # Equation of the equinoxes (requires TT although makes very
  # little differnece)
  my $tt = $mjd + ( slaDtt($mjd) / 86_400.0);
  my $eqeqx = slaEqeqx($tt);

  # Local sidereal time = GMST + EQEQX + Longitude in radians
  my $lst = slaDranrm($gmst + $eqeqx + $long);

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

  my ($w, $p, $h, $name);

  # Find the longitude of this telescope
  slaObs(-1, $tel, $name, $w, $p, $h);

  # Check telescope name
  if ($name eq '?') {
    croak "Telescope name $tel unrecognised by slaObs()";
  }

  # Convert longitude to west negative
  $w *= -1.0;

  # Run ut2lst
  return ut2lst(@_, $w);

}

=back


=head1 AUTHOR

Tim Jenness E<gt>tjenness@cpan.orgE<lt>

=head1 REQUIREMENTS

The Fortran version of SLALIB is available from Starlink under the
Gnu GPL. You can download it as part of the Starlink software
collection (http://www.starlink.rl.ac.uk).

The SLALIB library (C version) is proprietary.  Please contact Patrick
Wallace (ptw@tpsoft.demon.co.uk) if you would like to obtain a copy.

=head1 COPYRIGHT

Copyright (C) 2007, 2010 Tim Jenness and the Science and Technology Facilities
Council. Copyright (C) 1998-2005 Tim Jenness and the Particle Physics and
Astronomy Research Council.  All rights reserved.

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
