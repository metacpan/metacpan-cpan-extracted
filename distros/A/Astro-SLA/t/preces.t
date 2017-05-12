#!perl

# Simple test of precession [to test for a reported bug and its fix]

use strict;
use Test::More tests => 5;
BEGIN {
  use_ok "Astro::SLA";
}

my $ra =   1.43173721864225;
my $dec =  0.597125618475371;
my $eqxc = 1950.0;
my $eqxn = 2000.67738991558;

print "# Input: $ra $dec\n";

my $pra = 1.446386; # The answer
my $pdec = 0.597772;

# Preces copies of the ra/dec variables
slaPreces('FK4', $eqxc, $eqxn, my $nra = $ra, my $ndec = $dec);

print "# Precessed: $nra $ndec\n";

is(substr($nra,0,8),  $pra, "RA");
is(substr($ndec,0,8), $pdec, "dec");

# Now do the precession "by hand" the long way for comparison

# Generate precession matrix
my @pm;
slaPrebn( $eqxc, $eqxn, @pm);

# RA/Dec to x,y,z
my @v;
slaDcs2c( $ra, $dec, @v);

# Preces
my @v2;
slaDmxv( @pm, @v, @v2);

# return to RA/Dec
slaDcc2s( @v2, $nra, $ndec);
$nra = slaDranrm( $nra );

print "# Precessed: $nra, $ndec\n";

is(substr($nra,0,8),  $pra, "RA");
is(substr($ndec,0,8), $pdec, "Dec");

