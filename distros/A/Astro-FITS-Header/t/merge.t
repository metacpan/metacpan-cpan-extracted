# -*-perl-*-

# Test merge header functionality

# Author: Tim Jenness <t.jenness@jach.hawaii.edu>

# Copyright (C) 2005 Particle Physics and Astronomy Research Council.
# All Rights Reserved.

use strict;
use warnings;
use Test::More tests => 39;

require_ok("Astro::FITS::Header");

# Read all the fits headers
my @all = <DATA>;
chomp(@all);
my @fits;
my $i = 0;
my $start = 0;
while ($i <= $#all) {
  if ($all[$i] eq "=cut" || $i == $#all) {
    my $end = ( $i == $#all ? $i : $i - 1);
    push(@fits, new Astro::FITS::Header( Cards => [ @all[$start..$end]]));
    $start = $i + 1;
  }
  $i++;
}

# merge in list and then in scalar context
my ($merged, @different) = $fits[0]->merge_primary( @fits[1..$#fits]);
my $scalar = $fits[0]->merge_primary( @fits[1..$#fits] );

is($merged->sizeof, 21, "Number of cards in merged header");
is(@different, 3, "Number of diff headers");
is($merged->itembyname("RA")->value+0, 5, "RA is in merged header");

is($scalar->sizeof, 21, "Number of cards in merged header");
is($scalar->itembyname("RA")->value+0, 5, "RA is in merged header");


ok($different[0]->itembyname("UNIQUE"), "UNIQUE was not merged");
$different[0]->removebyname( "UNIQUE" );

ok($different[0]->itembyname("COMMON"), "COMMON was not merged");
$different[0]->removebyname( "COMMON" );
ok($different[1]->itembyname("COMMON"), "COMMON was not merged");
$different[1]->removebyname( "COMMON" );

for my $i (0..$#different) {
  is($different[$i]->sizeof, 1, "Number of diffs in header $i");
  is($different[$i]->itembyname("RUN")->value, ($i+1), "Run number in diff");
  ok($different[$i]->itembyname("DATE-OBS"), "DATE-OBS is not merged");
}

# Now do the merge but merge unique keys to the merged header
($merged, @different) = $fits[0]->merge_primary( {merge_unique=>1},
						 @fits[1..$#fits]);

#print "Merged: $merged\n";

is($merged->sizeof, 23, "Number of cards in merged header");
is(@different, 3, "Number of diff headers");
is($merged->itembyname("RA")->value+0, 5, "RA is in merged header");
ok($merged->itembyname("UNIQUE"), "UNIQUE was now merged");
ok(!$merged->itembyname("DATE-OBS"), "DATE-OBS was not merged");

# COMMON should be merged since it is common to 2 of the 3
# but identical in those 2
ok($merged->itembyname("COMMON"), "COMMON was now merged");


for my $i (0..$#different) {
  is($different[$i]->sizeof, 1, "Number of diffs in header $i");
  is($different[$i]->itembyname("RUN")->value, ($i+1), "Run number in diff");
  ok($different[$i]->itembyname("DATE-OBS"), "DATE-OBS is not merged");
}

# Now clone the merge and test the force_return flag
my $m2 = new Astro::FITS::Header( Cards => [$merged->cards] );
my ($m3, @diff3) = $merged->merge_primary( { force_return_diffs => 0}, $m2);
is(@diff3, 0, "Empty diff");

($m3, @diff3) = $merged->merge_primary( { force_return_diffs => 1}, $m2);
is(@diff3, 2, "Forced non-Empty diff");

# Merge itself in list and scalar context
my ($m4) = $merged->merge_primary();
is("$m4", "$merged", "Full header comparison");
is($m4->sizeof, $merged->sizeof, "Get back what we started with");

$m4 = $merged->merge_primary();
is("$m4", "$merged", "Full header comparison");
is($m4->sizeof, $merged->sizeof, "Get back what we started with");


__END__
         Block 1 description:
DATE-OBS= '2005-05-01T12:00:00' / observation date
RA      =                   5. / Right Ascension of observation
DEC     =                   5. / Declination of observation
ADD_ATM =                    1 / flag for adding atmospheric emission
ADDFNOIS=                    0 / flag for adding 1/f noise
ADD_PNS =                    1 / flag for adding photon noise
FLUX2CUR=                    1 / flag for converting flux to current
SMU_SAMP=                    8 / number of samples between jiggle vertices
DISTFAC =                   0. / distortion factor (0=no distortion)
CONVSHAP=                    2 / convolution function (Gaussian=0)
CONV_SIG=                   1. / convolution function parameter
NBOLX   =                   40 / number of bolometers in X direction
NBOLY   =                   32 / number of bolometers in Y direction
SAMPLE_T=                   5. / The sample interval in msec
SUBSYSNR=                    1 / subsystem number
NVERT   =                    8 / Nr of vertices in the Jiggle pattern
MOVECODE=                    8 / Code for the SMU move algorithm
HIERARCH JIG_STEPX =     12.56 / The Jiggle step value in -X-direction on the sk
HIERARCH JIG_STEPY =     12.56 / The Jiggle step value in -Y-direction on the sk
NCYCLE  =                    4 / number of cycles
NUMSAMP =                  256 / number of samples
         Block 2 description:
RUN     =                    1 / Run number
UNIQUE  =                    1 / A unique header
COMMON  =                    T / A somewhat common header
=cut
         Block 1 description:
DATE-OBS= '2005-05-01T12:01:00' / observation date
RA      =                   5. / Right Ascension of observation
DEC     =                   5. / Declination of observation
ADD_ATM =                    1 / flag for adding atmospheric emission
ADDFNOIS=                    0 / flag for adding 1/f noise
ADD_PNS =                    1 / flag for adding photon noise
FLUX2CUR=                    1 / flag for converting flux to current
SMU_SAMP=                    8 / number of samples between jiggle vertices
DISTFAC =                   0. / distortion factor (0=no distortion)
CONVSHAP=                    2 / convolution function (Gaussian=0)
CONV_SIG=                   1. / convolution function parameter
NBOLX   =                   40 / number of bolometers in X direction
NBOLY   =                   32 / number of bolometers in Y direction
SAMPLE_T=                   5. / The sample interval in msec
SUBSYSNR=                    1 / subsystem number
NVERT   =                    8 / Nr of vertices in the Jiggle pattern
MOVECODE=                    8 / Code for the SMU move algorithm
HIERARCH JIG_STEPX =     12.56 / The Jiggle step value in -X-direction on the sk
HIERARCH JIG_STEPY =     12.56 / The Jiggle step value in -Y-direction on the sk
NCYCLE  =                    4 / number of cycles
NUMSAMP =                  256 / number of samples
         Block 2 description:
RUN     =                    2 / Run number
COMMON  =                    T / A somewhat common header
=cut
         Block 1 description:
DATE-OBS= '2005-05-01T12:02:00' / observation date
RA      =                   5. / Right Ascension of observation
DEC     =                   5. / Declination of observation
ADD_ATM =                    1 / flag for adding atmospheric emission
ADDFNOIS=                    0 / flag for adding 1/f noise
ADD_PNS =                    1 / flag for adding photon noise
FLUX2CUR=                    1 / flag for converting flux to current
SMU_SAMP=                    8 / number of samples between jiggle vertices
DISTFAC =                   0. / distortion factor (0=no distortion)
CONVSHAP=                    2 / convolution function (Gaussian=0)
CONV_SIG=                   1. / convolution function parameter
NBOLX   =                   40 / number of bolometers in X direction
NBOLY   =                   32 / number of bolometers in Y direction
SAMPLE_T=                   5. / The sample interval in msec
SUBSYSNR=                    1 / subsystem number
NVERT   =                    8 / Nr of vertices in the Jiggle pattern
MOVECODE=                    8 / Code for the SMU move algorithm
HIERARCH JIG_STEPX =     12.56 / The Jiggle step value in -X-direction on the sk
HIERARCH JIG_STEPY =     12.56 / The Jiggle step value in -Y-direction on the sk
NCYCLE  =                    4 / number of cycles
         Block 2 description:
NUMSAMP =                  256 / number of samples
RUN     =                    3 / Run number
