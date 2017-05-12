#!perl

# Perl implementations of fortran code test code from the SLA SUN/67 documentation.

use strict;
use Test::More tests => 67;

use Astro::PAL;
#require_ok("Astro::PAL");

print "# See document SUN/67 for more details\n";

print "# Section 4.1 - Spherical trigonometry\n";

{
  # Longitude and latitude of London and Sydney (Radians)
  my $al = -0.2 * Astro::PAL::DD2R;
  my $bl = 51.5 * Astro::PAL::DD2R;
  my $as = 151.2 * Astro::PAL::DD2R;
  my $bs = -33.9 * Astro::PAL::DD2R;

  # Earth radius in km (spherical approximation)
  my $rkm = 6375.0;

  # Distance
  my $dist = Astro::PAL::palDsep($al, $bl, $as, $bs) * $rkm;

  # Initial heading (N=0 E=90)
  my $bear = Astro::PAL::palDbear($al, $bl, $as, $bs) / Astro::PAL::DD2R;

  is(nint($dist), 17011, "Distance from London to Sydney");
  is(nint($bear), 61, "Bearing from London to Sydney");

}

print "# Section 4.1.1 - Formatting angles\n";

{

  my $ix = 0;
  my @ints = (-23,567,22);
  my $string = join(" ",@ints);
  my $i = 1;
  for my $tst (@ints) {
    my $startpos = $i;
    ($i, $ix, my $j) = Astro::PAL::palIntin($string,$i);
    is($ix, $tst, "Extract integer from '".substr($string,$startpos-1)."'");
    if ($tst >= 0) {
      is($j,0,"Status from positive integer parse");
    } else {
      is($j, -1, "Status from negative integer parse");
    }
  }

  my @floats = (45.4,-344.4,-0.1,"4.3E5","-2.3D5");
  $string = join(",",@floats);
  $i = 1;
  my $dx = 0.0;
  for my $tst (@floats) {
    ($i, $dx, my $j) = Astro::PAL::palDfltin($string, $i);
    # Double precision fortran-style exponent not recognized by perl
    $tst =~ s/D/E/g;
    isnum( $dx, $tst, "%5g", "Compare input with parsed float");
    if ($tst >= 0) {
      is($j,0,"Status from float parse");
    } else {
      is($j, -1, "Status [negative] from float parse");
    }
  }


}

print "# Section 4.4.1 SLALIB support for precession and nutation\n";

{
  my @pmat = Astro::PAL::palPrec(2000.0,1985.372);

  # There will be issues with fortran vs C row ordering
  printf("# %13.10f %13.10f %13.10f\n", @pmat[0..2]);
  printf("# %13.10f %13.10f %13.10f\n", @pmat[3..5]);
  printf("# %13.10f %13.10f %13.10f\n", @pmat[6..8]);

  # Note that these numbers differ slightly because of the newer
  # precession model in PAL/SOFA.
  is(sprintf("%12.10f",$pmat[0]), 0.9999936411,
     "First element of precession matrix");
  is(sprintf("%12.10f",$pmat[8]), 0.9999989897,
     "Last element of precession matrix");

}

print "# Section 4.6 - Epoch\n";

{
  is(sprintf("%10.5f",Astro::PAL::palEpj(Astro::PAL::palEpb2d(1950.0))),
     1949.99979,
     "1950.0 Besselian epoch in Julian form");

}

print "# Section 4.11 - Mean Place transformations\n";

{
  # Test star: ra=16:09:55.13 dec=-75:59:27.2
  #            equinox=1900 epoch=1963.087 pm1=-0.0312 s/yr pm2=0.103 as/yr
  #            parallax=0.062 radial velocity=-34.22
  #            epoch of observation = 1994.35

  my ($r0, $j) = Astro::PAL::palDtf2r(16,9,55.13);
  (my $d0, $j) = Astro::PAL::palDaf2r(75,59,27.2);
  $d0 = - $d0;

  my $eq0 = 1900.0;
  my $ep0 = 1963.087;
  my $pr = -0.0312 * Astro::PAL::DS2R;
  my $pd =  0.103  * Astro::PAL::DAS2R;
  my $px = 0.062;
  my $rv = -34.22;
  my $ep1 = 1994.35;

  # Epoch of observation as MJD and Besselian epoch
  my $ep1d = Astro::PAL::palEpj2d( $ep1 );
  my $ep1b = Astro::PAL::palEpb($ep1d);

  # Space motion to the current epoch
  my ($r1, $d1) = Astro::PAL::palPm($r0, $d0, $pr, $pd, $px, $rv, $ep0, $ep1b);

  is(r2rasex($r1), "16 09 54.155", "RA with space motion");
  is(r2decsex($d1), "-75 59 23.98", "Dec with space motion");

  # Remove E-terms of aberration for the original equinox
  my ($r2, $d2) = Astro::PAL::palSubet($r1, $d1, $eq0);

  is(r2rasex($r2), "16 09 54.229", "RA with old E-terms removed");
  is(r2decsex($d2), "-75 59 24.18", "Dec with old E-terms removed");

  # Precess to B1950
  my ($r3, $d3) = Astro::PAL::palPreces('FK4',$eq0, 1950.0,$r2, $d2);

  is(r2rasex($r3), "16 16 28.213", "RA precessed to 1950.0");
  is(r2decsex($d3), "-76 06 54.57", "Dec precessed to 1950.0");

  # Add E-terms for the standard equinox B1950
  my ($r4, $d4) = Astro::PAL::palAddet($r3, $d3, 1950.0);

  is(r2rasex($r4), "16 16 28.138", "RA with new E-terms");
  is(r2decsex($d4), "-76 06 54.37", "Dec with new E-terms");

  # Transform to J2000, no proper motion
  my ($r5, $d5) = Astro::PAL::palFk45z($r4, $d4, $ep1b);

  is(r2rasex($r5), "16 23 07.901", "RA J2000, current epoch");
  is(r2decsex($d5), "-76 13 58.87", "Dec J2000, current epoch");

  # Parallax
  my $w;
  ($w, my $eb, $w, $w) = Astro::PAL::palEvp(Astro::PAL::palEpj2d($ep1), 2000.0);

  my @v = Astro::PAL::palDcs2c($r5, $d5);
  for (0..2) {
    $v[$_] -= Astro::PAL::DAS2R * $px * $eb->[$_];
  }
  my ($r6, $d6) = Astro::PAL::palDcc2s(\@v);

  is(r2rasex($r6), "16 23 07.907", "RA including parallax");
  is(r2decsex($d6), "-76 13 58.92", "Dec including parallax");

}

print "# Section 4.12 - Mean Place to Apparent Place\n";

{

  # Polaris noth polar distance (deg)
  my ($rm, $j) = Astro::PAL::palDtf2r(2,31,49.8131);
  (my $dm, $j) = Astro::PAL::palDaf2r(89,15,50.661);
  my $pr = 21.7272 * Astro::PAL::DS2R / 100.0;
  my $pd = -1.5710 * Astro::PAL::DAS2R / 100.0;

  # calculate it for 2105 Dec 30 [SUN/67 does it for every 10 days
  # but that is hard to test for]
  (my $date, $j) = Astro::PAL::palCldj(2105,12,30);
  my ($ra, $da) = Astro::PAL::palMap($rm,$dm,$pr,$pd,0.0,0.0,2000.0,$date);
  my $npd = (Astro::PAL::DPIBY2 - $da)/ Astro::PAL::DD2R;
  is( sprintf("%7.5f",$npd), 0.46225,
      "Polaris north polar distance Dec 30 2105");

}

print "# Section 4.18 - Ephemerides\n";
{

  #  Demonstrate the size of the geocentric parallax correction
  #  in the case of the Moon.  The test example is for the AAT,
  #  before midnight, in summer, near first quarter.
  print "# Geocentric parallax correction for the Moon\n";

  # Get AAT longitude and latitude in radians and height in metres
  my ($ident, $name, $slongw, $palt, $h) = Astro::PAL::palObs('AAT');

  # UTC (1992 January 13, 11 13 59) to MJD
  my ($djutc, $j) = Astro::PAL::palCldj(1992,1,13);
  (my $fdutc, $j) = Astro::PAL::palDtf2d(11,13,59.0);
  $djutc += $fdutc;

  # UT1 (UT1-UTC value of -0.152 sec is from IERS Bulletin B)
  my $djut1 = $djutc + (-0.152 / 86_400.0);

  # TT
  my $djtt = $djutc + (Astro::PAL::palDtt($djutc)/86_400.0);

  # Local apparent sidereal time
  my $stl = Astro::PAL::palGmst($djut1) - $slongw +
    Astro::PAL::palEqeqx($djtt);

  # Geocentric position/velocity of Moon (mean of date)
  my @pmm = Astro::PAL::palDmoon($djtt);

  # Nutation to true equinox of date
  my @rmatn = Astro::PAL::palNut($djtt);

  # Need to rotate the positions and the velocities by the nutation
  # matrix [note that palDmxv only rotates vectors.]
  my @mpos = @pmm[0..2];
  my @mvel = @pmm[3..5];

  my @mposr = Astro::PAL::palDmxv(\@rmatn, \@mpos);
  my @mvelr = Astro::PAL::palDmxv(\@rmatn, \@mvel);

  # Combine the pos and vel into a single array
  my @pmt = (@mposr, @mvelr);

  # Report geocentric HA,Dec
  my ($rm, $dm) = Astro::PAL::palDcc2s(\@pmt);
  my ($sh, @ihmsf) = Astro::PAL::palDr2tf(2, Astro::PAL::palDranrm($stl-$rm));
  my ($sd, @idmsf) = Astro::PAL::palDr2af(1,$dm);
  my $rmstr = sprintf("%s%02d %02d %02d.%02d",$sh,@ihmsf);
  my $dmstr = sprintf("%s%02d %02d %02d.%01d",$sd,@idmsf);
  printf "# Geocentric: $dmstr $rmstr\n";
  is($rmstr,"+03 06 55.56", "RA geocentric");
  is($dmstr,"+15 03 38.9",  "Dec geocentric");

  # Geocentric position of observer (true equator and equinox of date)
  my @pv0 = Astro::PAL::palPvobs($palt, $h, $stl);

  # Place origin at observer
  for my $i (0..5) {
    $pmt[$i] -= $pv0[$i];
  }

  # Allow for planetary aberration
  my $tl = 499.004782 * sqrt($pmt[0]**2 + $pmt[1]**2 + $pmt[2]**2);
  for my $i (0..2) {
    $pmt[$i] -= $tl * $pmt[$i+3];
  }

  # Report topocentric HA,Dec
  ($rm, $dm) = Astro::PAL::palDcc2s(\@pmt);
  ($sh, @ihmsf) = Astro::PAL::palDr2tf(2,Astro::PAL::palDranrm($stl-$rm));
  ($sd, @idmsf) = Astro::PAL::palDr2af(1,$dm);
  $rmstr = sprintf("%s%02d %02d %02d.%02d",$sh,@ihmsf);
  $dmstr = sprintf("%s%02d %02d %02d.%01d",$sd,@idmsf);
  printf "# Topocentric: $dmstr $rmstr\n";
  is($rmstr,"+03 09 23.76", "RA topocentric");
  is($dmstr,"+15 40 51.4",  "Dec topocentric");


}

{
  # Compute time and minimum geocentric apparent separation
  # between Venus and Jupiter during the close conjunction of 2 BC.
  print "# Geocentric apparent separation between Venus and Jupiter\n";

  # Search for closest approach on the given day
  my $djd0 = 1720859.5;
  my $sepmin = 10.0;
  my ($ihmin,$immin);

  for my $ihour (20..22) {
    for my $imin (0..59) {
      my ($fd, $j) = Astro::PAL::palDtf2d($ihour,$imin,0.0);

      # Julian date and MJD
      my $djd = $djd0 + $fd;
      my $djdm = $djd - 2_400_000.5;

      # Earth to Moon (mean of date)
      my @pv = Astro::PAL::palDmoon($djdm);

      # Precess Moon position to J2000
      my @rmatp = Astro::PAL::palPrec( Astro::PAL::palEpj($djdm),2000.0);
      my @pvm = Astro::PAL::palDmxv(\@rmatp,\@pv);

      # Sun to Earth-Moon Barycentre (mean J2000)
      ($j, my @pve) = Astro::PAL::palPlanet($djdm,3);

      # Correct from EMB to Earth
      for my $i (0..2) {
	$pve[$i] -= 0.012150581 * $pvm[$i];
      }

      # Sun to Venus
      ($j, @pv) = Astro::PAL::palPlanet($djdm,2);

      # Earth to Venus
      for my $i (0..5) {
	$pv[$i] -= $pve[$i];
     }

      # Light time to Venus (sec)
      my $tl = 499.004782 * sqrt(($pv[0] - $pve[0])**2 +
				 ($pv[1] - $pve[1])**2 +
				 ($pv[2] - $pve[2])**2);

      # Extrapolate backwards in time by that much
      for my $i (0..2) {
	$pv[$i] -= $tl * $pv[$i+3];
      }

      # To RA,Dec
      my ($rv, $dv) =  Astro::PAL::palDcc2s(\@pv);

      # Same for Jupiter
      ($j, @pv) = Astro::PAL::palPlanet($djdm,5);
      for my $i (0..5) {
	$pv[$i] -= $pve[$i];
      }
      $tl = 499.004782 * sqrt(($pv[0] - $pve[0])**2 +
			      ($pv[1] - $pve[1])**2 +
			      ($pv[2] - $pve[2])**2);
      for my $i (0..2) {
	$pv[$i] -= $tl * $pv[$i+3];
      }
      my ($rj, $dj) = Astro::PAL::palDcc2s(\@pv);

      # Separation (arcsec)
      my $sep = Astro::PAL::palDsep($rv,$dv,$rj,$dj);

      # Keep if smallest so far
      if ($sep < $sepmin) {
	$ihmin = $ihour;
	$immin = $imin;
	$sepmin = $sep;
      }
    }
  }
  my $sepas = sprintf( "%.1f",Astro::PAL::DR2AS * $sepmin);
  my $mintime = sprintf("%02d:%02d",$ihmin,$immin);
  is( $sepas, 33.3,
      "Separation between Jupiter and Venus. 2 B.C.E.");
  is( $mintime, "21:16", "Time of closest approach");

  print "# Min separation at $mintime - $sepas arcsec\n";
}

{
  print "# Verify PAL_RDPLAN\n";

  # These are the results from the fortran code:
my $ref = <<"EOF";
      Sun       06 28 14.03  +23 17 17.3  1887.8
      Mercury   08 08 58.61  +19 20 57.1     9.3
      Venus     09 38 53.62  +15 35 32.8    22.8
      Moon      06 28 15.94  +23 17 21.3  1902.3
      Mars      09 06 49.34  +17 52 26.6     4.0
      Jupiter   00 11 12.08  -00 10 57.5    41.1
      Saturn    16 01 43.35  -18 36 55.9    18.2
      Uranus    00 13 33.55  +00 39 36.1     3.5
      Neptune   09 49 35.76  +13 38 40.8     2.2
EOF

  # Parse the results into a comparison array
  my @lines = split /\n/,$ref;
  my %cmp;
  for (@lines) {
    s/^\s+//;
    s/\s+$//;
    if ( /(\w+)\s+(\d+\s\d+\s\d+\.\d+)\s+([+-]\d+\s\d+\s\d+\.\d+)\s+(\d*\.\d+)/ ) {
      # Numify the diameter
      my $diam = $4 + 0.0;
      $cmp{$1} = [ $2, $3, $diam ];
    }
  }

  #  For a given date, time and geographical location, output
  #  a table of planetary positions and diameters.
  my @pnames = qw/ Sun Mercury Venus Moon Mars Jupiter
		   Saturn Uranus Neptune /;

  # Use the values given in the example
  my $date = "1927 6 29";
  my $time = "5 25"; # TT
  my $long = "-2 42"; # Preston
  my $lat  = "53 46";

  # Now parse the strings (to be authentic)
  my $i = 1;

  # Parse the year
  ($i, my $iy, my $j) = Astro::PAL::palIntin($date,$i);
  ($i, my $im, $j) = Astro::PAL::palIntin($date,$i);
  ($i, my $id, $j) = Astro::PAL::palIntin($date,$i);

  # Parse the time (which is meant to be in dynamical time)
  ($i, my $fd, $j) = Astro::PAL::palDafin($time,1);
  $fd *= Astro::PAL::D15B2P;

  # Generate MJD (TT)
  (my $djm, $j) = Astro::PAL::palCldj($iy,$im,$id);
  $djm += $fd;

  # Parse coordinates
  ($i, my $elong, $j) = Astro::PAL::palDafin($long,1);
  ($i, my $phi, $j) = Astro::PAL::palDafin($lat,1);

  # Loop planet by planet
  for my $np (0..$#pnames) {
    my ($ra, $dec, $diam) = Astro::PAL::palRdplan($djm,$np,$elong,$phi);

    $diam *= Astro::PAL::DR2AS;
    my $refRA = r2rasex($ra,2);
    my $refDEC = r2decsex($dec,1);

    # Compare
    my $arr = $cmp{$pnames[$np]};
    is($refRA, $arr->[0], "Compare RA for $pnames[$np]");
    is($refDEC, $arr->[1], "Compare Dec for $pnames[$np]");
    is(sprintf("%.1f",$diam), 
       sprintf("%.1f",$arr->[2]), "Compare diameter for $pnames[$np]");

    printf("# %-10s %s %s   %6.1f\n", $pnames[$np], r2rasex($ra,2),
	   r2decsex($dec,1), $diam);

  }


}


exit;
# Helper routines
sub nint {
  return int( $_[0] + 0.5 );
}

# Decimal places optional second argument
# Convert radians to string hours
sub r2rasex {
  my $ra = Astro::PAL::palDranrm(shift);
  my $nparg = shift;
  my $np = (defined $nparg ? $nparg : 3);
  my ($sign, @ihmsf) = Astro::PAL::palDr2tf($np,$ra);
  return sprintf("%02d %02d %02d.%0".$np."d",@ihmsf);
}

# Convert radians to string deg
sub r2decsex {
  my $dec = shift;
  my $nparg = shift;
  my $np = (defined $nparg ? $nparg : 2);
  my ($sign, @ihmsf) = Astro::PAL::palDr2af($np,$dec);
  return sprintf("%1s%02d %02d %02d.%0".$np."d",$sign,@ihmsf);
}

# Compare float using supplied format string
sub isnum {
  my ($totest, $ref, $fmt, $msg) = @_;
  my $refstr = sprintf($fmt, $ref);
  my $toteststr = sprintf($fmt, $totest);
  is( $toteststr, $refstr, $msg ." (comparing $totest to $ref)");
}
