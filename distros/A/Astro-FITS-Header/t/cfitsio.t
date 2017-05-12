#!perl
# Testing CFITSIO read/write of fits headers

use strict;

use Test::More;

BEGIN {
  eval "use Astro::FITS::CFITSIO qw / :longnames /; use Astro::FITS::CFITSIO qw/ :constants /;";
  if ($@) {
    plan skip_all => "Astro::FITS::CFITSIO module not available";
    exit;
  } else {
    plan tests => 41;
  }
}

use File::Spec;
use File::Copy;

# ----------------------------------------------------------------------------

# Copy the test data to a temporary location
BEGIN{ copy( File::Spec->catfile("t", "cfitsio.fit"),
             File::Spec->catfile("t", "test.fit" ) )
       or croak("Unable to copy test data file to temporary location"); };

# Delete the temporary copy of the test data
END{ unlink File::Spec->catfile("t", "test.fit" )
     or croak("Unable to delete test data"); };

# ----------------------------------------------------------------------------

require_ok( "Astro::FITS::Header::CFITSIO" );

# Read from the __DATA__ block
my @cards = <DATA>;
chomp(@cards);

# Version test, need cfitsio library version > 2.1
ok( fits_get_version(my $version) > 2.1, "Check Astro::FITS::CFITSIO version number");

# get the path to the test data file
my $file = File::Spec->catfile("t", "test.fit");

# create a header
my $header = new Astro::FITS::Header::CFITSIO( File => $file );

# overwrite the header in memory with cards stored in __DATA__
# its a cheap and cheerful kludge and not the OO way to do it
$header->configure( Cards => \@cards );

# write our modified header out again
$header->writehdr( File => $file );

# open the header back up again reading directly from the file
my $compare = new Astro::FITS::Header::CFITSIO( File => $file );

# test the header against the raw data
for my $i (0 .. $#cards) {
  my @items = $compare->item($i);
  is( "$items[0]", $cards[$i], "Compare item $i");
}

exit;

__DATA__
SIMPLE  =                    T /  file does conform to FITS standard            
BITPIX  =                  -32 /  number of bits per data pixel                 
NAXIS   =                    2 /  number of data axes                           
NAXIS1  =                   59 /  length of data axis 1                         
NAXIS2  =                  110 /  length of data axis 2                         
EXTEND  =                    T /  FITS dataset may contain extensions           
COMMENT   FITS (Flexible Image Transport System) format defined in Astronomy and
COMMENT   Astrophysics Supplement Series v44/p363, v44/p371, v73/p359, v73/p365.
COMMENT   Contact the NASA Science Office of Standards and Technology for the   
COMMENT   FITS Definition document #100 and other FITS information.             
CLOCK0  = -6.20000000000000018 / ALICE CLOCK0 voltage                           
CLOCK1  =                   -3 / ALICE CLOCK1 voltage                           
CLOCK2  =                 -7.5 / ALICE CLOCK2 voltage                           
CLOCK3  = -2.79999999999999982 / ALICE CLOCK3 voltage                           
CLOCK4  =                   -6 / ALICE CLOCK4 voltage                           
CLOCK5  =                   -2 / ALICE CLOCK5 voltage                           
CLOCK6  =                 -7.5 / ALICE CLOCK6 voltage                           
CRVAL1  =             -0.03125 / Axis 1 reference value                         
CRPIX1  =                 29.5 / Axis 1 pixel value                             
CTYPE1  = 'LINEAR  '           / Quantity represented by axis 1                 
CRVAL2  =             -0.03125 / Axis 2 reference value                         
CRPIX2  =                 55.0 / Axis 2 pixel value                             
CTYPE2  = 'LINEAR  '           / Quantity represented by axis 2                 
CD1_1   =               0.0625 / Axis rotation and scaling matrix               
CD1_2   =                  0.0 / Axis rotation and scaling matrix               
CD2_1   =                  0.0 / Axis rotation and scaling matrix               
CD2_2   =               0.0625 / Axis rotation and scaling matrix               
OBJECT  = '        '           /  Title of the dataset                          
DATE    = '2000-12-12T20:28:35'/  file creation date (YYYY-MM-DDThh:mm:ss UTC)  
ORIGIN  = 'Starlink Project, U.K.'/  Origin of this FITS file                   
BSCALE  =                  1.0 /  True_value = BSCALE * FITS_value + BZERO      
BZERO   =                  0.0 /  True_value = BSCALE * FITS_value + BZERO      
HDUCLAS1= 'NDF     '           /  Starlink NDF (hierarchical n-dim format)      
HDUCLAS2= 'DATA    '           /  Array component subclass                      
LINEAR  =                    F / Linearisation disabled                         
FILTER  = 'B1      '           / Combined filter name                           
FILTERS = 'B1      '           / Combined filter name                           
LAMP    = 'off     '           / Name of calibration lamp                       
END                                                                             
