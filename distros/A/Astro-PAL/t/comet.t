#!perl

# Test orbital elements for comet
# HaleBopp
# We know that at the time:
#   MJD = 50745.7083333335
# HaleBopp had an apparent RA/Dec of
#   Apparent RA :    08:09:03.91
#   Apparent dec:   -47:24:51.53
#  [at JCMT SCUBA observing]

# This test makes sure that we get that.
# If this test fails it probably indicates that you need to
# update pallib to a version that can handle perturbation of
# elements correctly.

# Copyright (C) 2003-2005 Particle Physics and Astronomy Research Council
# All Rights Reserved.

use strict;
use Test::More tests => 10;

BEGIN {
  use_ok(  "Astro::PAL" );
}

# Elements
my %halebopp = (
		# from JPL horizons
		EPOCH => 52440.0000,
		EPOCHPERIH => 50538.179590069,
		ORBINC => 89.4475147* &Astro::PAL::DD2R,
		ANODE =>  282.218428* &Astro::PAL::DD2R,
		PERIH =>  130.7184477* &Astro::PAL::DD2R,
		AORQ => 0.9226383480674554,
		E => 0.9949722217794675,
		AORL => 0.0,
		DM => 0,
	      );

# Time UT: 1997-10-24T17:00:00
# MJD should be 50745.7083333335
my $yy = 1997;
my $mm = 10;
my $dd = 24;
my $hh = 17;
my ($lst, $MJD) = ut2lst_tel($yy, $mm, $dd, $hh, 0, 0, 'JCMT');

is(sprintf("%.4f",$MJD),"50745.7083", "Verify MJD");

# Correct to TT
my $offset = Astro::PAL::palDtt( $MJD );
$MJD += ($offset / (86_400));

print "# TT MJD = $MJD\n";

# Perturb the elements
my $jform = 3;
($halebopp{EPOCH},$halebopp{ORBINC}, $halebopp{ANODE},
 $halebopp{PERIH},$halebopp{AORQ},$halebopp{E},
 $halebopp{AORL},
 my $jstat ) = Astro::PAL::palPertel($jform,$halebopp{EPOCH},$MJD,
                                     $halebopp{EPOCHPERIH},$halebopp{ORBINC},$halebopp{ANODE},
                                     $halebopp{PERIH},$halebopp{AORQ},$halebopp{E},
                                     $halebopp{AORL} );

is( $jstat, 0, "Status return from perturbing the elements");

# Telescope information
my $name = 'JCMT';
my ($ident, $fullname, $long, $lat, $h) = Astro::PAL::palObs($name);
$long *= -1; # Need east positive
print "# $fullname, $long, $lat, $h \n";

# Now use the elements
my ($ra, $dec, $dist, $j) = Astro::PAL::palPlante($MJD, $long, $lat, $jform,
                                                  $halebopp{EPOCH}, $halebopp{ORBINC},
                                                  $halebopp{ANODE}, $halebopp{PERIH},
                                                  $halebopp{AORQ}, $halebopp{E}, $halebopp{AORL},
                                                  $halebopp{DM});

is( $j, 0, "Status from palPlante");

# Convert RA and Dec to sexagesimal
my $ra_str = fromrad( $ra / 15 );
my $dec_str = fromrad( $dec );
print "# app RA: $ra -> $ra_str  App Dec: $dec -> $dec_str \n";

is(substr($ra_str,1,8),"08:09:03","Hale-Bopp app RA");
is(substr($dec_str,0,11),"-47:24:51.4","Hale-Bopp app Dec");


# Calculate hour angle
my $ha = $lst -$ra;
is(sprintf("%.2f",($ha * Astro::PAL::DR2H)), "0.69", "Hour Angle");

my ($az, $el) = Astro::PAL::palDe2h($ha, $dec, $lat);

$az *= Astro::PAL::DR2D;
$el *= Astro::PAL::DR2D;
print "# Az: $az El: $el\n";

is( sprintf("%.1f",$el),"22.1", "EL");
is( sprintf("%.2f",$az),"187.57", "AZ");

# Now switch to 3200 Phaethon. This caused real problems with some
# pallib versions and architectures
print "# Testing 3200 Phaethon. Will not pass in older SLA versions (<2.5.3)\n";

my %elem = (
	    'AORQ' => '0.139854192733765',
	    'E' => '0.889994084835052',
	    'EPOCHPERIH' => '53431.54296875',
	    'PERIH' => '5.61957263946533',
	    'ORBINC' => '0.386924684047699',
	    'ANODE' => '4.63256978988647',
	    'EPOCH' => '53200',
	    'AORL' => 0,
	   );

my $now = 53613.09;

my ($EPOCH1, $ORBINC1, $ANODE1, $PERIH1,
    $AORQ1, $E1, $AORL1, $J) = Astro::PAL::palPertel( 3, $elem{EPOCH}, $now,
                                                      $elem{EPOCHPERIH},
                                                      $elem{ORBINC},
                                                      $elem{ANODE},
                                                      $elem{PERIH},
                                                      $elem{AORQ},
                                                      $elem{E},
                                                      $elem{AORL});

is( $J, 0, "Test perturbation of elements for 3200 Phaethon" );

exit;

sub fromrad {
  # Convert rad to sexagesimal
  my $in = shift;
  my $res = 2;
  my ($sign, @dmsf) = Astro::PAL::palDr2af($res, $in);
  $sign = ' ' if $sign eq "+";
  $in = $sign . sprintf("%02d:%02d:%02d.%0$res"."d",@dmsf);
  return $in;
}
