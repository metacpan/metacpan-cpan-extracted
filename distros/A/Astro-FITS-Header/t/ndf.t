#!perl
# Testing NDF read/write of fits headers

use strict;
use Test::More;

BEGIN {
  eval "use NDF;";
  if ($@) {
    plan skip_all => "NDF module not available";
    exit;
  } else {
    plan tests => 385;
  }
}

require_ok( "Astro::FITS::Header::NDF" );

my $file = "temp$$";
END { unlink $file . ".sdf" if defined $file; };

# Create an NDF file
my $status = &NDF::SAI__OK;
my $good = $status;
ndf_begin();
ndf_open(&NDF::DAT__ROOT(), $file, 'WRITE', 'UNKNOWN',
	     my $ndfid, my $place, $status);

# if the file was not there we have to create it from the place holder
# KLUGE : need to get NDF__NOID from the NDF module at some point
if ($ndfid == 0) {
  my @lbnd = (1);
  my @ubnd = (1);
  ndf_new('_INTEGER', 1, @lbnd, @ubnd, $place, $ndfid, $status );

  # Map the data array
  ndf_map($ndfid, 'DATA', '_INTEGER', 'WRITE', my $pntr, my $el, $status);
  my @data = (5);
  &array2mem(\@data, "i*", $pntr) if ($status == $good);
  ndf_unmap($ndfid,'DATA', $status);
}

ndf_annul($ndfid, $status);
ndf_end($status);

# Read the stuff from the end
my @cards = <DATA>;
chomp(@cards);

# Create a new object with those cards
my $hdr = new Astro::FITS::Header::NDF( Cards => \@cards );

# Store them on disk
$hdr->writehdr( File => $file );

ok( -e $file .".sdf", "Does $file exist?" );

# Read them back in
my $hdr2 = new Astro::FITS::Header::NDF( File => $file );

# Now compare with the original
my @newcards = $hdr2->cards;

for my $i (0..$#cards) {
  is($newcards[$i], $cards[$i], "Compare card $i");
}

# Create an error condition
my $hdr3;
eval {
  $hdr3 = Astro::FITS::Header::NDF->new( File => "NotThere.sdf" );
};
ok( !defined $hdr3, "Deliberate error" );

# Now read the header using an NDF identifier
$status = $good;
err_begin( $status );
ndf_begin();
ndf_find( &NDF::DAT__ROOT(), $file, $ndfid, $status);
my $hdr4 = Astro::FITS::Header::NDF->new( ndfID => $ndfid );

# Now compare with the original
@newcards = $hdr2->cards;

for my $i (0..$#cards) {
  is($newcards[$i], $cards[$i], "Compare card $i");
}

ndf_end($status );
err_end( $status );

exit;

__DATA__
SIMPLE  =                    T / file does conform to FITS standard             
BITPIX  =                  -32 / number of bits per data pixel                  
NAXIS   =                    3 / number of data axes                            
NAXIS1  =                    5 / length of data axis 1                          
NAXIS2  =                   37 / length of data axis 2                          
NAXIS3  =                   32 / length of data axis 3                          
EXTEND  =                    T / FITS dataset may contain extensions            
COMMENT   FITS (Flexible Image Transport System) format defined in Astronomy and
COMMENT   Astrophysics Supplement Series v44/p363, v44/p371, v73/p359, v73/p365.
COMMENT   Contact the NASA Science Office of Standards and Technology for the   
COMMENT   FITS Definition document #100 and other FITS information.             
DATE    = '2001-03-17T05:32:30' / file creation date (YYYY-MM-DDThh:mm:ss UTC)  
ORIGIN  = 'Starlink Project, U.K.' / Origin of this FITS file                   
BSCALE  =              1.0E+00 / True_value = BSCALE * FITS_value + BZERO       
BZERO   =              0.0E+00 / True_value = BSCALE * FITS_value + BZERO       
HDUCLAS1= 'NDF     '           / Starlink NDF (hierarchical n-dim format)       
HDUCLAS2= 'DATA    '           / Array component subclass                       
ACCEPT  = 'PROMPT  '           / accept update; PROMPT, YES or NO               
ALIGN_AX= 'not used'           / Alignment measurements in X or Y axis          
ALIGN_SH=                   -1 / Distance between successive alignment offsets (
ALT-OBS =                 4092 / Height of observatory above sea level (metres) 
AMEND   =             1.033522 / Airmass at end of observation                  
AMSTART =             1.033343 / Airmass at start of observation                
APEND   =             626.6301 / Air pressure at end of observation (mbar)      
APSTART =             626.5079 / Air pressure at start of observation (mbar)    
ATEND   =            -0.695969 / Air temp. at end of observation (C)            
ATSTART =            -0.793648 / Air temp. at start of observation (C)          
BOLOMS  = 'LONG    '           / Names of bolometers measured                   
CALIBRTR=                    T / Internal calibrator is on or off               
CAL_FRQ =             2.929688 / Calibrator frequency (Hz)                      
CENT_CRD= 'RJ      '           / Centre coordinate system                       
CHOP_CRD= 'AZ      '           / Chopper coordinate system                      
CHOP_FRQ=               7.8125 / Chopper frequency (Hz)                         
CHOP_FUN= 'SCUBAWAVE'          / Chopper waveform                               
CHOP_PA =                   90 / Chopper P.A., 0 = in lat, 90 = in long         
CHOP_THR=                   60 / Chopper throw (arcsec)                         
DATA_DIR= '20010316'           / Sub-directory where datafile was stored        
DATA_KPT= 'DEMOD   '           / The type of data stored to disk                
DRGROUP = 'UNKNOWN '           / Pipeline combination of observations           
DRRECIPE= 'UNKNOWN '           / Data reduction recipe name                     
END_AZD =              349.946 / Azimuth at end of observation (deg)            
END_EL  =                   -1 / Elevation of last SKYDIP point (deg)           
END_ELD =              75.3348 / Elevation at end of observation                
EQUINOX =                 2000 / Equinox of mean coordinate system              
EXPOSED =                    0 / Exposure per pixel (seconds)                   
EXP_NO  =                    1 / Exposure number at end of observation          
EXP_TIME=                1.024 / Exposure time for each basic measurement (sec) 
E_PER_I =                    1 / Number of exposures per integration            
FILTER  = '450W:850W'          / Filters used                                   
FOCUS_SH=                   -1 / Shift between focus measurements (mm)          
GAIN    =                   10 / Programmable gain                              
HSTEND  = '5:10:43.99967'      / HST at end of observation                      
HSTSTART= '5:09:42.00073'      / HST at start of observation                    
HUMEND  =                   15 / Humidity (%) at end of observation             
HUMSTART=                   15 / Humidity (%) at start of observation           
INSTRUME= 'SCUBA   '           / Name of instrument used                        
INT_NO  =                    1 / Integration number at end of observation       
JIGL_CNT=                   16 / Number of offsets in jiggle pattern            
JIGL_NAM= 'JCMTDATA_DIR:EASY_16_6P18.JIG' / File containing jiggle offsets      
J_PER_S =                   16 / Number of jiggles per switch position          
J_REPEAT=                    1 / No. jiggle pattern repeats in a switch         
LAT     = '+034:12:47.91'      / Object latitude                                
LAT-OBS =        19.8258323669 / Latitude of observatory (degrees)              
LAT2    = 'not used'           / Object latitude at MJD2                        
LOCL_CRD= 'RJ      '           / Local offset coordinate system                 
LONG    = '+016:13:41.06'      / Object longitude                               
LONG-OBS=        204.520278931 / East longitude of observatory (degrees)        
LONG2   = 'not used'           / Object Longitude at MJD2                       
MAP_HGHT=                  180 / Height of rectangle to be mapped (arcsec)      
MAP_PA  =                    0 / P.A. of map vertical, +ve towards +ve long     
MAP_WDTH=                  180 / Width of rectangle to be mapped (arcsec)       
MAP_X   =                    0 / Map X offset from telescope centre (arcsec)    
MAP_Y   =                    0 / Map Y offset from telescope centre (arcsec)    
MAX_EL  =                   -1 / Max elevation of sky-dip (deg)                 
MEANDEC =             34.20982 / 34:12:35.36499 = approx. mean Dec. (deg)       
MEANRA  =             243.4202 / 243:25:12.59766 = approx. mean R.A. (deg)      
MEAS_NO =                    1 / Measurement number at end of observation       
MIN_EL  =                   -1 / Min elevation of sky-dip (deg)                 
MJD1    =                   -1 / Modified Julian day planet at RA,DEC           
MJD2    =                   -1 / Modified Julian day planet at RA2,DEC2         
MODE    = 'POINTING'           / The type of observation                        
N_INT   =                    1 / No. integrations in the observation            
N_MEASUR=                    1 / No. measurements in the observation            
OBJECT  = '1611+343'           / Name of object                                 
OBJ_TYPE= 'UNKNOWN '           / Type of object                                 
OBSDEF  = 'ss:odfsxpo.t_1611x343_050456' / The observation definition file      
OBSERVER= 'Captain Nemo'       / The name of the observer                       
PROJ_ID = 'scuba   '           / The project identification                     
RUN     =                  101 / Run number of observation                      
SAM_CRDS= 'NA      '           / Coordinatesystem of sampling mesh              
SAM_DX  =                   -1 / Sample spacing along scan direction (arcsec)   
SAM_DY  =                   -1 / Sample spacing perp. to scan (arcsec)          
SAM_MODE= 'JIGGLE  '           / Sampling method                                
SAM_PA  =                   -1 / Scan P.A. rel. to lat. line; 0=lat, 90=long    
SCAN_REV=                    F / .TRUE. if alternate scans reverse direction    
SPK_NSIG=                    0 / N sigmas from fit of spike threshold           
SPK_RMVL=                    T / Automatic spike removal                        
SPK_WDTH=                    0 / Assumed width of spike                         
START_EL=                   -1 / Elevation of first SKYDIP point (deg)          
STATE   = 'Terminating         :' / SCUCD state                                 
STEND   = '16:25:54.10538'     / ST at end of observation                       
STRT_AZD=              350.459 / Azimuth at observation start (deg)             
STRT_ELD=               75.364 / Elevation at observation start (deg)           
STSTART = '16:24:52.939'       / ST at start of observation                     
SWTCH_MD= 'BMSW    '           / Switch mode of observation                     
SWTCH_NO=                    2 / Switch number at end of observation            
S_PER_E =                    2 / Number of switch positions per exposure        
TELESCOP= 'JCMT    '           / Name of telescope                              
TEL_OPER= 'Ned Land'           / Telescope operator                             
UTDATE  = '2001:3:16'          / UT date of observation                         
UTEND   = '15:10:42.99889'     / UT at end of observation                       
UTSTART = '15:09:42.00073'     / UT at start of observation                     
VERSION =                  1.1 / SCUCD version                                  
WPLTNAME= 'JCMTDATA_DIR:WPLATE_16.DAT' / File name of waveplate positions       
ALIGN_DX=             0.724521 / SMU tables X axis alignment offset             
ALIGN_DY=                -0.09 / SMU tables Y axis alignment offset             
ALIGN_X =             -4.26865 / SMU tables X axis                              
ALIGN_Y =              2.61996 / SMU tables Y axis                              
AZ_ERR  =            -0.277546 / Error in the telescope azimuth                 
CHOPPING=                    T / SMU Chopper chopping state                     
EL_ERR  =              1.12316 / Error in the telescope elevation               
FOCUS_DZ=            -0.071401 / SMU tables Z axis focus offset                 
FOCUS_Z =             -16.6062 / SMU tables Z axis                              
SEEING  =             0.288833 / SAO atmospheric seeing                         
SEE_DATE= '0103161415'         / Date and time of SAO seeing                    
TAU_225 =                0.035 / CSO tau                                        
TAU_DATE= '0103161455'         / Date and time of CSO tau                       
TAU_RMS =              3.0E-03 / CSO tau rms                                    
UAZ     =            -0.402539 / User azimuth pointing offset                   
UEL     =              3.99758 / User elevation pointing offset                 
UT_DATE = '16 MAR 2001'        / UT date at start of observation                
BAD_LIM =                   32 / No. spikes before quality set bad              
CALIB_LG=                    6 / Lag of internal calibrator in samples          
CALIB_PD=             42.66667 / Period of internal calibrator in samples       
CHOP_LG =                    4 / Chop lag in samples                            
CHOP_PD =                   16 / Chop period in samples                         
CNTR_DU3=                    0 / Nasmyth dU3 coord of instrument centre         
CNTR_DU4=                    0 / Nasmyth dU4 coord of instrument centre         
ETATEL_1=                   -1 / Transmission of telescope                      
ETATEL_2=                   -1 / Transmission of telescope                      
ETATEL_3=                   -1 / Transmission of telescope                      
ETATEL_4=                   -1 / Transmission of telescope                      
ETATEL_5=                   -1 / Transmission of telescope                      
FILT_1  = '850     '           / Filter name                                    
FILT_2  = 'not_used'           / Filter name                                    
FILT_3  = 'not_used'           / Filter name                                    
FILT_4  = 'not_used'           / Filter name                                    
FILT_5  = 'not_used'           / Filter name                                    
FLAT    = 'jcmtdata_dir:lwswphot.dat' / Name of flat-field file                 
JIG_DSCD=                   -1 / No. samples discarded after jiggle movement    
L_GD_BOL= 'H7      '           / Bol. to whose value LW guard ring is set       
L_GUARD =                    F / Long wave guard ring on or off                 
MEAS_BOL= 'LONG    '           / Bolometers  actually measured in observation   
N_BOLS  =                   37 / Number of bolometers selected                  
N_SUBS  =                    1 / Number of sub-instruments used                 
PHOT_BBF= 'not_used       LL,C14,NULL' / The bolometers on the source           
PRE_DSCD=                    0 / No. of samples discarded before chop movement  
PST_DSCD=                    0 / No. samples discarded after chop movement      
REBIN   = 'LINEAR  '           / Rebinning method used by SCUIP                 
REF_ADC =                   -1 / A/D card of FLATFIELD reference bolometer      
REF_CHAN=                   -1 / Channel of FLATFIELD reference bolometer       
SAM_TIME=                  125 / A/D sample period in ticks (64musec)           
SIMULATE=                    F / True if data is simulated                      
SKY     = 'jcmtdata_dir:skydip_startup.dat' / Name of sky opacities file        
SUB_1   = 'LONG    '           / SCUBA instrument being used                    
SUB_2   = 'not used'           / SCUBA instrument being used                    
SUB_3   = 'not used'           / SCUBA instrument being used                    
SUB_4   = 'not used'           / SCUBA instrument being used                    
SUB_5   = 'not used'           / SCUBA instrument being used                    
S_GD_BOL= 'D9      '           / Bol. to whose value SW guard ring is set       
S_GUARD =                    F / Short wave guard ring on or off                
TAUZ_1  =                    0 / Zenith sky optical depth                       
TAUZ_2  =                    0 / Zenith sky optical depth                       
TAUZ_3  =                    0 / Zenith sky optical depth                       
TAUZ_4  =                    0 / Zenith sky optical depth                       
TAUZ_5  =                    0 / Zenith sky optical depth                       
T_AMB   =                   -1 / The ambient air temperature (K)                
T_COLD_1=                   -1 / Effective temperature of cold load (K)         
T_COLD_2=                   -1 / Effective temperature of cold load (K)         
T_COLD_3=                   -1 / Effective temperature of cold load (K)         
T_COLD_4=                   -1 / Effective temperature of cold load (K)         
T_COLD_5=                   -1 / Effective temperature of cold load (K)         
T_HOT   =                   -1 / The temperature of the hot load (K)            
T_TEL   =                   -1 / The temperature of the telescope               
USE_CAL =                    F / .TRUE. if dividing chop by cal before rebin    
WAVE_1  =                  863 / Wavelength of map (microns)                    
WAVE_2  =                    0 / Wavelength of map (microns)                    
WAVE_3  =                    0 / Wavelength of map (microns)                    
WAVE_4  =                    0 / Wavelength of map (microns)                    
WAVE_5  =                    0 / Wavelength of map (microns)                    
END                                                                             
