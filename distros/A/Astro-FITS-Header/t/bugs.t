# Astro::FITS::Header test harness -*-perl-*-

use strict;
use Test::More tests => 4;

require_ok( "Astro::FITS::Header" );
require_ok( "Astro::FITS::Header::Item" );

# Read header from DATA block.
my @raw = <DATA>;
chomp( @raw );

# Build the header item.
my $header = new Astro::FITS::Header( Cards => \@raw );

### Test bug where multiple headers being removed using a regular
### expression removed the wrong headers.

# Remove headers that start with CR..
$header->removebyname( qr/^CR/ );

# There should still be a "CTYPE2" header, so retrieve it.
my @card = $header->itembyname( "CTYPE2" );

ok( defined $card[0] );
is( $card[0]->value, "a2", "CTYPE2 is a2" );

exit;

__DATA__
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                  -32 / number of bits per data pixel
NAXIS   =                    3 / number of data axes
NAXIS1  =                   25 / length of data axis 1
NAXIS2  =                   36 / length of data axis 2
NAXIS3  =                  252 / length of data axis 3
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT   FITS (Flexible Image Transport System) format defined in Astronomy and
COMMENT   Astrophysics Supplement Series v44/p363, v44/p371, v73/p359, v73/p365.
COMMENT   Contact the NASA Science Office of Standards and Technology for the
COMMENT   FITS Definition document #100 and other FITS information.
CRVAL1  = -0.07249999791383749 / Axis 1 reference value
CRPIX1  =                 12.5 / Axis 1 pixel value
CTYPE1  = 'a1      '           / LINEAR
CRVAL2  = -0.07249999791383743 / Axis 2 reference value
CRPIX2  =                 18.0 / Axis 2 pixel value
CTYPE2  = 'a2      '           / LINEAR
CRVAL3  =  1.27557086671004E-6 / Axis 3 reference value
CRPIX3  =                126.0 / Axis 3 pixel value
CTYPE3  = 'a3      '           / LAMBDA
OBJECT  = 'galaxy  '           / Title of the dataset
DATE    = '2000-12-13T22:44:53' / file creation date (YYYY-MM-DDThh:mm:ss UTC)
ORIGIN  = 'NOAO-IRAF FITS Image Kernel July 1999' / FITS file originator
BSCALE  =                  1.0 / True_value = BSCALE * FITS_value + BZERO
BZERO   =                  0.0 / True_value = BSCALE * FITS_value + BZERO
HDUCLAS1= 'NDF     '           / Starlink NDF (hierarchical n-dim format)
HDUCLAS2= 'DATA    '           / Array component subclass
IRAF-TLM= '23:07:26 (27/02/2000)' / Time of last modification
TELESCOP= 'UKIRT, Mauna Kea, HI' / Telescope name
INSTRUME= 'CGS4    '           / Instrument
OBSERVER= 'SMIRF   '           / Observer name(s)
OBSREF  = '?       '           / Observer reference
DETECTOR= 'fpa046  '           / Detector array used
OBSTYPE = 'OBJECT  '           / Type of observation
INTTYPE = 'STARE+NDR'          / Type of integration
MODE    = 'ND_STARE'           / Observing mode
GRPNUM  =                    0 / Number of observation group
RUN     =                   54 / Number of run
EXPOSED =                  180 / Total exposure time for integration
OBJCLASS=                    0 / Class of observed object
CD1_1   = 0.144999980926513672 / Axis rotation and scaling matrix
CD1_2   =                  0.0 / Axis rotation and scaling matrix
CD1_3   =                  0.0 / Axis rotation and scaling matrix
CD2_1   =                  0.0 / Axis rotation and scaling matrix
CD2_2   = 0.144999980926513672 / Axis rotation and scaling matrix
CD2_3   =                  0.0 / Axis rotation and scaling matrix
CD3_1   =                  0.0 / Axis rotation and scaling matrix
CD3_2   =                  0.0 / Axis rotation and scaling matrix
CD3_3   = 2.07933226192836E-10 / Axis rotation and scaling matrix
MEANRA  = 10.34629999999999939 / Object RA at equinox (hrs)
MEANDEC =  20.1186000000000007 / Object Dec at equinox (deg)
RABASE  = 10.34629999999999939 / Offset zero-point RA at equinox (hrs)
DECBASE =  20.1186000000000007 / Offset zero-point Dec at equinox (deg)
RAOFF   =                    0 / Offset RA at equinox (arcsec)
DECOFF  =                    0 / Offset Dec at equinox (arcsec)
DROWS   =                  178 / No of det. in readout row
DCOLUMNS=                  256 / No of det. in readout column
DEPERDN =                    6 / Electrons per data number
CLOCK0  = -6.20000000000000018 / ALICE CLOCK0 voltage
CLOCK1  =                   -3 / ALICE CLOCK1 voltage
CLOCK2  =                 -7.5 / ALICE CLOCK2 voltage
CLOCK3  = -2.79999999999999982 / ALICE CLOCK3 voltage
CLOCK4  =                   -6 / ALICE CLOCK4 voltage
CLOCK5  =                   -2 / ALICE CLOCK5 voltage
CLOCK6  =                 -7.5 / ALICE CLOCK6 voltage
VSLEW   =                    4 / ALICE VSLEW voltage
VDET    = -3.02000000000000002 / ALICE VDET voltage
DET_BIAS=  0.57999999999999996 / ALICE DET_BIAS voltage
VDDUC   = -3.60000000000000009 / ALICE VDDUC voltage
VDETGATE=                 -4.5 / ALICE VDETGATE voltage
VGG_A   = -1.60000000000000009 / ALICE VGG_ACTIVE voltage
VGG_INA = -1.30000000000000004 / ALICE VGG_INACTIVE voltage
VDDOUT  =                   -1 / ALICE VDDOUT voltage
V3      = -2.79999999999999982 / ALICE V3 voltage
VLCLR   =                   -3 / ALICE VLCLR voltage
VLD_A   =                    4 / ALICE VLOAD_ACTIVE voltage
VLD_INA =                    4 / ALICE VLOAD_INACTIVE voltage
WFREQ   =                    1 / ALICE waveform state freq. (MHz)
RESET_DL= 0.200000000000000011 / NDR reset delay (seconds)
CHOP_DEL= 0.029999998999999999 / Chop delay (seconds)
READ_INT=                    5 / NDR read interval (seconds)
NEXP_PH =                    0 / Exposures in each chop phase
DEXPTIME=                  180 / Exposure time (seconds)
RDOUT_X1=                    1 / Start column of array readout
RDOUT_X2=                  256 / End   column of array readout
RDOUT_Y1=                   45 / Start row    of array readout
RDOUT_Y2=                  222 / End   row    of array readout
CHOPDIFF=                    T / Main-offset beam value stored
IF_SHARP=                    F / Shift & add disabled
LINEAR  =                    F / Linearisation disabled
FILTER  = 'B1      '           / Combined filter name
FILTERS = 'B1      '           / Combined filter name
DETINCR =                    1 / Increment (pixels) betw scan positions
DETNINCR=                    2 / Number of scan positions in scan
WPLANGLE=                    0 / IRPOL waveplate angle
SANGLE  = -2.19303900000000018 / Angle of slit
SLIT    = '0ew     '           / Name of slit
SLENGTH =                   18 / Length of slit
SWIDTH  =                    4 / Width of slit
DENCBASE=                  800 / Zeropoint (steps) of detector translation
DFOCUS  = 1.819309999999999983 / Detector focus position
GRATING = '150_lpmm'           / Name of grating
GLAMBDA = 1.274947000000000052 / Grating wavelength
GANGLE  = 17.09262000000000015 / Grating wavelength
GORDER  =                    3 / Grating order
GDISP   =        0.00020796522 / Grating dispersion
CLAMBDA =                    0 / CVF wavelength
IRTANGLE= 6.396519999999999762 / Image rotator angle
LAMP    = 'off     '           / Name of calibration lamp
BBTEMP  =                    0 / Black body temperature
CALAPER =                    0 / Aperture of tungsten-halogen lamp (%)
THLEVEL =                    0 / Level of tungsten-halogen lamp
IDATE   =             19980217 / Date as integer
OBSNUM  =                   54 / Number of observation
NEXP    =                    1 / Exposures in integration
AMSTART = 1.334643999999999942 / Airmass at start of obs
AMEND   = 1.320149999999999935 / Airmass at end of obs
RUTSTART= 8.000171999999999173 / Start time of obs (hrs)
RUTEND  = 8.101883000000000834 / End time of obs (hrs)
NBADPIX =                   32
END
