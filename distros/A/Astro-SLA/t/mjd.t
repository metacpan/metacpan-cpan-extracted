#!perl
# Simple test of Modified Julian Date commands

use strict;
use Test::More tests => 4;

BEGIN {
  use_ok "Astro::SLA";
}

# Pick a MJD

use constant MJD => 51603.5;  # midday on 29 Feb 2000


# Convert the MJD to d,m,y

slaDjcl(MJD, my $iy, my $im, my $id, my $frac, my $status);

is($status, 0, "Check status from MJD to dmy");

# Convert the fraction to hour/min/sec

my @ihmsf= ();

slaCd2tf(0, $frac, my $sign, @ihmsf);

# Now convert the year/mon/day to a MJD via the 
# ut2lst_tel() command [mainly to test that command as well]

my ($lst, $mjd) = ut2lst_tel($iy, $im, $id, $ihmsf[0], $ihmsf[1], $ihmsf[2], 'JCMT');
print "# MJD is $mjd and expected ". MJD ."\n";
is($mjd, MJD, "Compare MJD");

# and test LST because at one point we broke it
is(sprintf("%.3f",$lst),"3.196","LST");
