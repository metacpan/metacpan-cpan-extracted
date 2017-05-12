#!perl

# Simple test of precession [to test for a reported bug and its fix]

use strict;
use Test::More tests => 5;
BEGIN {
  use_ok "Astro::PAL";
}

my $ra =   1.43173721864225;
my $dec =  0.597125618475371;
my $eqxc = 1950.0;
my $eqxn = 2000.67738991558;

print "# Input: $ra $dec\n";

my $pra = 1.446386; # The answer
my $pdec = 0.597772;

# Preces copies of the ra/dec variables
my ($nra, $ndec) = Astro::PAL::palPreces('FK4', $eqxc, $eqxn, $ra, $dec);

print "# Precessed: $nra $ndec\n";

is(substr($nra,0,8),  $pra, "RA");
is(substr($ndec,0,8), $pdec, "dec");

# Now do the precession "by hand" the long way for comparison

# Generate precession matrix
my @pm = Astro::PAL::palPrebn( $eqxc, $eqxn );

# RA/Dec to x,y,z
my @v = Astro::PAL::palDcs2c( $ra, $dec);

# Preces
my @v2 = Astro::PAL::palDmxv( \@pm, \@v );

# return to RA/Dec
($nra, $ndec) = Astro::PAL::palDcc2s( \@v2 );
$nra = Astro::PAL::palDranrm( $nra );

print "# Precessed: $nra, $ndec\n";

is(substr($nra,0,8),  $pra, "RA");
is(substr($ndec,0,8), $pdec, "Dec");

