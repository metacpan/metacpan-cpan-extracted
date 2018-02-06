# -*-perl-*-

# Bi-directional translation test. Converts all the FITS headers
# in the data directory to generic form and back to FITS.

# Author: Tim Jenness <t.jenness@jach.hawaii.edu>

# Copyright (C) 2005 Particle Physics and Astronomy Research Council.
# Copyright (C) 2013 Science and Technology Facilities Council.
# All Rights Reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either Version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place,Suite 330, Boston, MA 02111-1307,
# USA.

use 5.006;
use strict;
use warnings;
use Test::More;

use File::Spec;
use Scalar::Util qw/ looks_like_number /;

# For detailed comparison
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

eval {
  require Astro::FITS::Header;
};
if ($@) {
  plan skip_all => 'Test requires Astro::FITS::Header module';
} else {
  plan tests => 483;
}

require_ok( "Astro::FITS::HdrTrans" );

# As a basic test, count the number of expected FITS headers
# per instrument
my %COUNT = (
             ufti => 42,
             uist_ifu => 55,
             uist_sp => 55,
             uist_im => 55,
             cgs4 => 52,
             michelle => 56,
             ircam => 43,
             scuba => 37,
             wfcam => 44,
             acsis => 47,
             scuba2 => 40,
            );

my $datadir = File::Spec->catdir( "t","data");

opendir my $dh, $datadir or die "Unable to locate header data directory: $!";

for my $hdrfile (sort readdir $dh) {
  next unless $hdrfile =~ /\.hdr$/;
  #next unless $hdrfile eq 'gsd_ras.hdr';
  print "\n\n# Processing file $hdrfile...\n";

  # Get the ref instrument name.
  my $inst = $hdrfile;
  $inst =~ s/\.hdr$//;

  # Skip if we have a header that is not listed in the test hash.
  next unless exists $COUNT{$inst};

  # Get the Astro::FITS::Header object.
  my $fits = readfits( File::Spec->catfile( $datadir, $hdrfile) );
  die "Error reading fits headers from $hdrfile"
    unless defined $fits;

  # Convert to a hash.
  my %hdr;
  tie %hdr, "Astro::FITS::Header", $fits;

  # Translate from FITS...
  print "# Test translation from FITS...\n";
  my %generic = Astro::FITS::HdrTrans::translate_from_FITS( \%hdr );

  # and back to FITS.
  print "\n# and to FITS\n";
  my %nfits = Astro::FITS::HdrTrans::translate_to_FITS( \%generic );

  # For testing, dump the contents of the new FITS header.
  # This allows simple comparison with alternate implementations.
   print Dumper(\%nfits);

  # Now count the number of headers...
  my @keys = keys %nfits;
  is( scalar(@keys), $COUNT{$inst},
      "Expected number of FITS cards for instrument $inst");

  # and compare and contrast. For now, we assume that there are
  # the same number of keys since we can not start with the existing
  # FITS header since it has lots of untranslateable keys. The correct
  # way is for the reference data file to include exactly the keys
  # that are needed for translation (retaining the full header as a
  # reference). We would then compare %nfits to %hdr.
  for my $nkey (sort keys %nfits) {

    my $refval = $hdr{$nkey};
    my $thisval = $nfits{$nkey};

    # Special cases need the item type.
    my $item = $fits->itembyname( $nkey );

    if (!defined $item) {

      # Special case for SCUBA. It doesn't have a DATE header in the
      # reference FITS header.
      if( $inst eq 'scuba' && $nkey eq 'DATE' ) {
        ok( 1, 'cf scuba DATE' );
        next;
      }

#      ok(0, "$inst Key $nkey present in translated header but not reference header");
#      print "# Key $nkey had a value of '" .
#         (defined $thisval ? $thisval : "<UNDEF>") ."'\n";
      next;
    }

    if ($item->type eq 'FLOAT') {
      # have precision problems
      $refval  = sprintf( "%.3f", $refval);
      $thisval = sprintf( "%.3f", $thisval);

    } elsif ( defined( $refval ) &&
              $refval !~ /^[-+]/ &&
              $refval =~ /\d\d:\d\d:\d\d\.(\d+)/ ) {
      $refval =~ s/\.(\d+)//;
    }

    is( $thisval, $refval, "cf $inst $nkey");
  }

}


exit;


# Read the HDR data into a Astro::FITS::Header object.
sub readfits {
  my $file = shift;

  open my $fh, "<$file" or die "Error opening header file $file: $!";

  my @cards = <$fh>;

  return new Astro::FITS::Header( Cards => \@cards );

}


