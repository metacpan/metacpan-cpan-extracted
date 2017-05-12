#!/bin/perl

use strict;
use Test::More tests => 7;

BEGIN {
  use_ok "Astro::SLA";
}

###########################################################################

# Test a simple example
my $ra = "6 10 23.9";
my $dec = "-6 12 21.0";

print "# Input (B1950): RA=$ra DEC=$dec\n";

my ($nra,$ndec) = &btoj($ra,$dec);

is($nra, "6 12 50.37", "RA J2000");
is($ndec, "-6 13 11.76", "Dec J2000");

print "# Output (J2000): RA=$nra DEC=$ndec\n";

# Now test for the usual  '-00 00 01' case since sometimes
# this coordinate is treated as a positive dec.

$ra = "02 40 7.04";     # NGC 1068
$dec = "-00 13 31.66";

print "# Input (B1950): RA=$ra DEC=$dec\n";

($nra,$ndec) = &btoj($ra,$dec);

is($nra,"2 42 40.70", "RA" );
is($ndec, "-0 0 47.80", "Dec");

print "# Output (J2000): RA=$nra DEC=$ndec\n";

$ra = "12 34 37.25";   # Hubble deep field
$dec = "62 29 22.28";

print "# Input (B1950): RA=$ra DEC=$dec\n";

($nra,$ndec) = &btoj($ra,$dec);

is($nra, "12 36 51.20","RA");
is($ndec, "+62 12 52.50","Dec");

print "# Output (J2000): RA=$nra DEC=$ndec\n";


# Now test a positive declination


sub btoj {

  my ($ra,$dec) = (@_);
  my ($nra,$ndec,$bepoch,$dsign,$sign,$sign2,$status,$j);
  my (@idmsf,@ihmsf,$ra_rad,$dec_rad,$ra_j2000_rad,$dec_j2000_rad);


  my ($h,$m,$s) = split(/ /,$ra);
  my ($d,$dm,$ds) = split(/ /,$dec);

  slaDtf2r($h,$m,$s ,$ra_rad,$j);

  # Check for sign. Dont use numeric comparison since this
  # will not trap -00 01
  $dsign = ($d =~ /^\s*-/ ? -1 : 1);
  $d *= $dsign;  # since abs(-0) == -0

  slaDaf2r($d,$dm,$ds ,$dec_rad,$status);

  $dec_rad *= $dsign;

  ###########################################################################

  $bepoch = 1950.0;
  slaFk45z( $ra_rad, $dec_rad, $bepoch, $ra_j2000_rad, $dec_j2000_rad );

  @idmsf = ();
  &slaDr2af(2,$dec_j2000_rad,$sign,\@idmsf);

  @ihmsf = ();
  slaDr2tf(2,$ra_j2000_rad,$sign2,@ihmsf);

  $nra  = join(" ",@ihmsf[0..2]).".$ihmsf[3]";
  $ndec = $sign.join(" ",@idmsf[0..2]).".$idmsf[3]";

  return ($nra,$ndec);

}

