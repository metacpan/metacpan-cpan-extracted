# Astro::FITS::Header HIERARCH test harness -*-perl-*-

# strict
use strict;

#load test
use Test::More tests => 378;

# load modules
require_ok( "Astro::FITS::Header" );
require_ok( "Astro::FITS::Header::Item" );

# T E S T   H A R N E S S --------------------------------------------------

# read header from DATA block
my @raw = <DATA>;
chomp(@raw);

# build header array
my $header = new Astro::FITS::Header( Cards => \@raw );

# test the header
for my $i (0 .. $#raw) {
  my $card = $header->item($i);
  is( "$card", $raw[$i], "Check item ".$card->keyword);
}

# test HIERARCH keywords
is( $header->value("HIERARCH.ESO.OBS.NAME"), 'Photom-std-S705D',
    "HIERARCH.ESO.OBS.NAME" );

# Test the card parsing
my @cards = $header->allitems();
is( $cards[52]->keyword(), "HIERARCH.ESO.OBS.TPLNO",
  "HIERARCH.ESO.OBS.TPLNO");

exit;

__DATA__
SIMPLE  =                    T          / Standard FITS format (NOST-100.0)     
BITPIX  =                  -32          / # of bits storing pix values          
NAXIS   =                    2          / # of axes in frame                    
NAXIS1  =                 1024          / # pixels/row                          
NAXIS2  =                 1024          / # rows (also # scan lines)            
ORIGIN  = 'ESO-PARANAL'                 / European Southern Observatory         
DATE    = '2001-04-09T23:38:34.0939'    / Date this file was written (dd/mm/yyyy
EXPTIME =                1.773          / Total integration time. 00:00:01.773  
MJD-OBS =       52008.98484556          / Obs start 2001-04-09T23:38:10.656     
DATE-OBS= '2001-04-09T23:38:10.6563'    / Date of observation                   
ORIGFILE= 'ISAACSW-STD-Ks_0009.fits'    / Original File Name                    
TELESCOP= 'ESO-VLT-U1'                  / ESO <TEL>                             
INSTRUME= 'ISAAC   '                    / Instrument used                       
OBSERVER= '        '                    / Name of observer                      
PI-COI  = '        '                    / Name of PI and COI                    
UTC     =            85090.000          / 23:38:10.000 UT at start              
LST     =            29379.086          / 08:09:39.086 LST at start             
OBJECT  = 'STD     '                    / Original target                       
RA      =            129.06474          / 08:36:15.5 RA (J2000) pointing        
DEC     =            -10.23711          / -10:14:13.5  DEC (J2000) pointing     
EQUINOX =                2000.          / Standard FK5 (years)                  
RADECSYS= 'FK5     '                    / Coordinate reference frame            
CRVAL1  =            129.06474          / 08:36:15.5, RA at ref pixel           
CRVAL2  =            -10.23711          / -10:14:13.5, DEC at ref pixel         
CRPIX1  =                504.0          / Ref pixel in X                        
CRPIX2  =                491.0          / Ref pixel in Y                        
CDELT1  =           0.00004122          / SS arcsec per pixel in RA             
CDELT2  =          -0.00004122          / SS arcsec per pixel in DEC            
CTYPE1  = 'RA---TAN'                    / pixel coordinate system               
CTYPE2  = 'DEC--TAN'                    / pixel coordinate system               
CROTA1  =              0.00000          / Rotation in degrees                   
CROTA2  =              0.00000          / Rotation in degrees                   
PC001001=             1.000000          / Translation matrix element            
PC001002=            -0.000000          / Translation matrix element            
PC002001=            -0.000000          / Translation matrix element            
PC002002=             1.000000          / Translation matrix element            
ARCFILE = 'ISAAC.2001-04-09T23:38:10.656.fits' / Archive File Name              
CHECKSUM= 'YOpYZLnYYLnYYLnY'            / ASCII 1's complement checksum         
UT      = '23:38:10.000'                / UT at start                           
ST      = '08:09:39.086'                / ST at start                           
AIRMASS =              1.03900          / Averaged air mass                     
IMAGETYP= 'STD     '                    / Observation type                      
FILTER1 = 'Ks      '                    / Filter 1 name                         
FILTER2 = 'open    '                    / Filter 2 name                         
GRAT    = 'MR      '                    / Grating name                          
WLEN    =                  0.5          / Grating central wavelen               
ORDER   =                    1          / Grating order used                    
DATAMIN =            -1.833333          / Minimum pixel value                   
DATAMAX =          8651.833008          / Maximum pixel value                   
DATAMEAN=           939.563104          / Mean Pixel Value                      
DATARMS =           103.167024          / RMS of Pixel Values                   
DATAMED =           926.666687          / Median Pixel Value                    
HIERARCH ESO OBS TPLNO       =            5 / Template number within OB         
HIERARCH ESO OBS NAME        = 'Photom-std-S705D' / OB name                     
HIERARCH ESO OBS ID          =    200103132 / Observation block ID              
HIERARCH ESO OBS GRP         = '0       '   / linked blocks                     
HIERARCH ESO OBS PROG ID     = '60.A-9021(A)' / ESO program identification      
HIERARCH ESO OBS DID         = 'ESO-VLT-DIC.OBS-1.7' / OBS Dictionary           
HIERARCH ESO OBS OBSERVER    = 'UNKNOWN '   / Observer Name                     
HIERARCH ESO OBS PI-COI NAME = 'UNKNOWN '   / PI-COI name                       
HIERARCH ESO OBS PI-COI ID   =        52021 / ESO internal PI-COI ID            
HIERARCH ESO OBS TARG NAME   = 'S705-D  '   / OB target name                    
HIERARCH ESO OBS START       = '2001-04-09T23:22:20' / OB start time            
HIERARCH ESO TPL DID         = 'ESO-VLT-DIC.TPL-1.4' / Data dictionary for TPL  
HIERARCH ESO TPL ID          = 'ISAACSW_img_tec_Zp' / Template signature ID     
HIERARCH ESO TPL NAME        = 'Imaging. Standard Stars' / Template name        
HIERARCH ESO TPL PRESEQ      = 'ISAAC_img_cal_StandardStar' / Sequencer script  
HIERARCH ESO TPL START       = '2001-04-09T23:36:05' / TPL start time           
HIERARCH ESO TPL VERSION     = '@(#) Revision: 8813 ' / Version of the templat  
HIERARCH ESO TPL NEXP        =            5 / Number of exposures within templat
HIERARCH ESO TPL EXPNO       =            4 / Exposure number within template   
HIERARCH ESO SEQ RELOFFSETX  =     0.000000 / relative X offset                 
HIERARCH ESO SEQ RELOFFSETY  =  -606.469003 / relative Y offset                 
HIERARCH ESO SEQ CUMOFFSETX  =  -303.234501 / cummulative X offset              
HIERARCH ESO SEQ CUMOFFSETY  =  -303.234501 / cummulative Y offset              
HIERARCH ESO DPR CATG        = 'CALIB   '   / Observation category              
HIERARCH ESO DPR TYPE        = 'STD     '   / Observation type                  
HIERARCH ESO DPR TECH        = 'IMAGE   '   / Observation technique             
HIERARCH ESO TEL DID         = 'ESO-VLT-DIC.TCS' / Data dictionary for TEL      
HIERARCH ESO TEL ID          = 'v 1.370 '   / TCS version number                
HIERARCH ESO TEL DATE        = '2001-04-05T19:18:04.000' / TCS installation date
HIERARCH ESO TEL ALT         =       74.287 / Alt angle at start (deg)          
HIERARCH ESO TEL AZ          =      204.939 / Az angle at start (deg) S=0,W=90  
HIERARCH ESO TEL GEOELEV     =         2648. / Elevation above sea level (m)    
HIERARCH ESO TEL GEOLAT      =     -24.6259 / Tel geo latitute (+=North) (deg)  
HIERARCH ESO TEL GEOLON      =     -70.4032 / Tel geo longitute (+=East) (deg)  
HIERARCH ESO TEL OPER        = 'I, Condor'  / Telescope Operator                
HIERARCH ESO TEL FOCU ID     = 'NB      '   / Telescope focus station ID        
HIERARCH ESO TEL FOCU LEN    =      120.000 / Focal length (m)                  
HIERARCH ESO TEL FOCU SCALE  =        1.718 / Focal scale (arcsec/mm)           
HIERARCH ESO TEL FOCU VALUE  =      -36.921 / M2 setting (mm)                   
HIERARCH ESO TEL PARANG START=     -157.066 / Parallactic angle at start (deg)  
HIERARCH ESO TEL AIRM START  =        1.039 / Airmass at start                  
HIERARCH ESO TEL AMBI FWHM START=      0.69 / Observatory Seeing queried from AS
HIERARCH ESO TEL AMBI PRES START=    742.88 / Observatory ambient air pressure q
HIERARCH ESO TEL AMBI WINDSP =         3.34 / Observatory ambient wind speed que
HIERARCH ESO TEL AMBI WINDDIR=          298. / Observatory ambient wind directio
HIERARCH ESO TEL AMBI RHUM   =           15. / Observatory ambient relative humi
HIERARCH ESO TEL AMBI TEMP   =        13.43 / Observatory ambient temperature qu
HIERARCH ESO TEL MOON RA     = 145534.848451 / ~~:~~:~~.~ RA (J2000) (deg)      
HIERARCH ESO TEL MOON DEC    = -114331.86384 / -~~:~~:~~.~ DEC (J2000) (deg)    
HIERARCH ESO TEL TH M1 TEMP  =        12.49 / M1 superficial temperature        
HIERARCH ESO TEL TRAK STATUS = 'NORMAL  '   / Tracking status                   
HIERARCH ESO TEL DOME STATUS = 'FULLY-OPEN' / Dome status                       
HIERARCH ESO TEL CHOP ST     =            F / True when chopping is active      
HIERARCH ESO TEL PARANG END  =     -157.372 / Parallactic angle at end (deg)    
HIERARCH ESO TEL AIRM END    =        1.039 / Airmass at end                    
HIERARCH ESO TEL AMBI FWHM END=        0.75 / Observatory Seeing queried from AS
HIERARCH ESO TEL AMBI PRES END=      742.90 / Observatory ambient air pressure q
HIERARCH ESO ADA ABSROT START=    -58.62111 / Abs rot angle at exp start (deg)  
HIERARCH ESO ADA POSANG      =      0.00000 / Position angle at start           
HIERARCH ESO ADA GUID STATUS = 'ON      '   / Status of autoguider              
HIERARCH ESO ADA GUID RA     =   128.897610 / 08:35:35.4 Guide star RA J2000    
HIERARCH ESO ADA GUID DEC    =    -10.21325 / -10:12:47.7 Guide star DEC J2000  
HIERARCH ESO ADA ABSROT END  =    -58.35361 / Abs rot angle at exp end (deg)    
HIERARCH ESO INS SWSIM       = 'NORMAL  '   / Software simulated functions      
HIERARCH ESO INS ID          = 'ISAAC/HW 1.0/SW 1.48/' / Instrument identificati
HIERARCH ESO INS TIME        = '2001-04-09T23:38:34.441' / Aquired status time  
HIERARCH ESO INS DID         = 'ESO-VLT-DIC.ISAAC_ICS-0.1' / Data dictionary for
HIERARCH ESO INS MODE        = 'SWI1    '   / OS Exposure completed             
HIERARCH ESO INS PIXSCALE    =        0.148 / Pixel scale                       
HIERARCH ESO INS TEMP-MON TEMP1=     76.750 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME1= 'Cool Down' / Sensor placement                 
HIERARCH ESO INS TEMP-MON TEMP2=     69.330 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME2= 'Warm Up ' / Sensor placement                  
HIERARCH ESO INS TEMP-MON TEMP3=    108.120 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME3= 'Sorption' / Sensor placement                  
HIERARCH ESO INS TEMP-MON TEMP4=     68.450 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME4= 'Mirror  ' / Sensor placement                  
HIERARCH ESO INS TEMP-MON TEMP5=     67.830 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME5= 'Cstr #1 ' / Sensor placement                  
HIERARCH ESO INS TEMP-MON TEMP6=     68.520 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME6= 'Cstr #2 ' / Sensor placement                  
HIERARCH ESO INS TEMP-MON TEMP7=     68.150 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME7= 'Cstr #3 ' / Sensor placement                  
HIERARCH ESO INS TEMP-MON TEMP8=    104.840 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME8= 'Radiation Shield' / Sensor placement          
HIERARCH ESO INS TEMP-MON TEMP11=     3.750 / Status temp. scanner              
HIERARCH ESO INS TEMP-MON NAME11= 'flowrate' / Sensor placement                 
HIERARCH ESO INS TEMP-DETSW  =       59.999 / Temp. of detector SW              
HIERARCH ESO INS TEMP-DETSW SET=     60.000 / Set temp. of detector SW          
HIERARCH ESO INS TEMP-DETLW  =       29.999 / Temp. of detector LW              
HIERARCH ESO INS TEMP-DETLW SET=     30.000 / Set temp. of detector LW          
HIERARCH ESO INS LAMP1 TIME  =           29 / Calibration lamp activation time  
HIERARCH ESO INS LAMP1 NAME  = 'argon lamp' / Calibration lamp name             
HIERARCH ESO INS LAMP1 TYPE  = 'DIGITAL '   / Calibration lamp type             
HIERARCH ESO INS LAMP1 ST    =            F / Calibration lamp activated        
HIERARCH ESO INS LAMP1 TOTAL =         3295 / Calibration lamp lifetime         
HIERARCH ESO INS LAMP2 TIME  =           29 / Calibration lamp activation time  
HIERARCH ESO INS LAMP2 NAME  = 'xenon lamp' / Calibration lamp name             
HIERARCH ESO INS LAMP2 TYPE  = 'DIGITAL '   / Calibration lamp type             
HIERARCH ESO INS LAMP2 ST    =            F / Calibration lamp activated        
HIERARCH ESO INS LAMP2 TOTAL =         4846 / Calibration lamp lifetime         
HIERARCH ESO INS LAMP3 TIME  =          266 / Calibration lamp activation time  
HIERARCH ESO INS LAMP3 NAME  = 'halogen lamp' / Calibration lamp name           
HIERARCH ESO INS LAMP3 TYPE  = 'ANALOG  '   / Calibration lamp type             
HIERARCH ESO INS LAMP3 SET   =            0 / Value sent to amplifier.          
HIERARCH ESO INS LAMP3 CURRENT=           0 / Amplifier status current          
HIERARCH ESO INS LAMP3 TOTAL =        14777 / Calibration lamp lifetime         
HIERARCH ESO INS CALSHUT ST  =            F / Calibration shutter activated     
HIERARCH ESO INS CALSHUT TIME=           87 / Calibration shutter time (msec.)  
HIERARCH ESO INS CALMIRR NAME= 'OUT     '   / Name of mirror position           
HIERARCH ESO INS CALMIRR NO  =            1 / Position number of calib. shutter 
HIERARCH ESO INS M1 ST       =            T / Mode select mirror T=IN F=OUT     
HIERARCH ESO INS OPTI1 ID    = 'mask_S2 '   / OPTIi unique ID                   
HIERARCH ESO INS OPTI1 NAME  = 'mask_S2 '   / OPTIi name                        
HIERARCH ESO INS OPTI1 NO    =            7 / OPTIi slot number                 
HIERARCH ESO INS OPTI1 TYPE  = 'MASK    '   / OPTIi element                     
HIERARCH ESO INS FILT1 ID    = 'Ks      '   / FILTi unique ID                   
HIERARCH ESO INS FILT1 NAME  = 'Ks      '   / FILTi name                        
HIERARCH ESO INS FILT1 NO    =           12 / FILTi slot number                 
HIERARCH ESO INS FILT1 TYPE  = 'FILTER  '   / FILTi element                     
HIERARCH ESO INS FILT2 ID    = 'open    '   / FILTi unique ID                   
HIERARCH ESO INS FILT2 NAME  = 'open    '   / FILTi name                        
HIERARCH ESO INS FILT2 NO    =            2 / FILTi slot number                 
HIERARCH ESO INS FILT2 TYPE  = 'FREE    '   / FILTi element                     
HIERARCH ESO INS OPTI2 ID    = 'S2      '   / OPTIi unique ID                   
HIERARCH ESO INS OPTI2 NAME  = 'S2      '   / OPTIi name                        
HIERARCH ESO INS OPTI2 NO    =            6 / OPTIi slot number                 
HIERARCH ESO INS OPTI2 TYPE  = 'OBJECTIVE'  / OPTIi element                     
HIERARCH ESO INS M7 ST       =            F / Det. select mirror T=LW F=SW      
HIERARCH ESO INS COLLIM ENC  =        -4000 / Collimator encoder position       
HIERARCH ESO INS GRAT NAME   = 'MR      '   / Grating device name               
HIERARCH ESO INS GRAT ORDER  =            1 / Wavelength order number           
HIERARCH ESO INS GRAT WLEN   =    0.5000000 / Grating central wavelength        
HIERARCH ESO INS GRAT ENC    =       659536 / Grating encoder position          
HIERARCH ESO DET FRAM TYPE   = 'INT     '   / Type of frame                     
HIERARCH ESO DET FRAM NO     =            1 / Frame number                      
HIERARCH ESO DET FRAM UTC    = '2001-04-09T23:38:33.7973' / Time Recv Frame     
HIERARCH ESO DET EXP NO      =         1122 / Unique exposure ID number         
HIERARCH ESO DET EXP UTC     = '2001-04-09T23:38:34.0939' / File Creation Time  
HIERARCH ESO DET EXP NAME    = 'ISAACSW-STD-Ks_0009' / Exposure Name            
HIERARCH ESO DET DID         = 'ESO-VLT-DIC.IRACE-1.11' / Dictionary            
HIERARCH ESO DET CON OPMODE  = 'NORMAL  '   / Operational Mode                  
HIERARCH ESO DET IRACE SEQCONT=           F / Sequencer Cont. Mode              
HIERARCH ESO DET CHIP ID     = 'ESO-Hawaii' / Detector ID                       
HIERARCH ESO DET CHIP NAME   = 'Hawaii  '   / Detector name                     
HIERARCH ESO DET CHIP NX     =         1024 / Pixels in X                       
HIERARCH ESO DET CHIP NY     =         1024 / Pixels in Y                       
HIERARCH ESO DET CHIP TYPE   = 'IR      '   / The Type of Det Chip              
HIERARCH ESO DET CHIP PXSPACE=    1.800e-05 / Pixel-Pixel Spacing               
HIERARCH ESO DET DIT         =       1.7726 / Integration Time                  
HIERARCH ESO DET NCORRS      =            2 / Read-Out Mode                     
HIERARCH ESO DET NCORRS NAME = 'Double  '   / Read-Out Mode Name                
HIERARCH ESO DET MODE NAME   = 'DoubleCorr' / DCS Detector Mode                 
HIERARCH ESO DET DITDELAY    =        0.100 / Pause Between DITs                
HIERARCH ESO DET NDIT        =            6 / # of Sub-Integrations             
HIERARCH ESO DET NDITSKIP    =            0 / DITs skipped at 1st.INT           
HIERARCH ESO DET CHOP NCYCLES=            4 / # of Chop Cycles                  
HIERARCH ESO DET CHOP ST     =            F / Chopping On/Off                   
HIERARCH ESO DET RSPEED      =            6 / Read-Speed Factor                 
HIERARCH ESO DET RSPEEDADD   =            0 / Read-Speed Add                    
HIERARCH ESO DET WIN TYPE    =            0 / Win-Type: 0=SW/1=HW               
HIERARCH ESO DET WIN STARTX  =     1.000000 / Lower Left X Ref                  
HIERARCH ESO DET WIN STARTY  =     1.000000 / Lower left Y Ref                  
HIERARCH ESO DET WIN NX      =         1024 / # of Pixels in X                  
HIERARCH ESO DET WIN NY      =         1024 / # of Pixels in Y                  
HIERARCH ESO DET IRACE ADC1 NAME= 'LWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC1 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC1 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC1 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC1 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC1 DELAY=        3 / ADC Delay Adjustment              
HIERARCH ESO DET IRACE ADC2 NAME= 'LWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC2 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC2 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC2 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC2 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC2 DELAY=        3 / ADC Delay Adjustment              
HIERARCH ESO DET IRACE ADC3 NAME= 'LWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC3 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC3 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC3 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC3 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC3 DELAY=        3 / ADC Delay Adjustment              
HIERARCH ESO DET IRACE ADC4 NAME= 'LWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC4 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC4 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC4 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC4 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC4 DELAY=        3 / ADC Delay Adjustment              
HIERARCH ESO DET IRACE ADC5 NAME= 'LWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC5 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC5 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC5 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC5 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC5 DELAY=        3 / ADC Delay Adjustment              
HIERARCH ESO DET IRACE ADC6 NAME= 'LWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC6 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC6 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC6 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC6 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC6 DELAY=        3 / ADC Delay Adjustment              
HIERARCH ESO DET IRACE ADC7 NAME= 'LWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC7 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC7 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC7 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC7 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC7 DELAY=        3 / ADC Delay Adjustment              
HIERARCH ESO DET IRACE ADC8 NAME= 'LWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC8 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC8 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC8 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC8 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC8 DELAY=        3 / ADC Delay Adjustment              
HIERARCH ESO DET IRACE ADC9 NAME= 'SWL-ADC ' / Name for ADC Board               
HIERARCH ESO DET IRACE ADC9 HEADER=       0 / Header of ADC Board               
HIERARCH ESO DET IRACE ADC9 ENABLE=       1 / Enable ADC Board (0/1)            
HIERARCH ESO DET IRACE ADC9 FILTER1=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC9 FILTER2=      0 / ADC Filter Adjustment             
HIERARCH ESO DET IRACE ADC9 DELAY=        4 / ADC Delay Adjustment              
HIERARCH ESO DET MINDIT      =       1.7726 / Minimum DIT                       
HIERARCH ESO DET VOLT2 CLKHINM1= 'clk1Hi PIXEL2-3' / Name of High Clock         
HIERARCH ESO DET VOLT2 CLKHI1=       5.1000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM1= 'clk1Lo PIXEL2-3' / Name of Low Clock          
HIERARCH ESO DET VOLT2 CLKLO1=       0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM2= 'clk2Hi PIXEL1-4' / Name of High Clock         
HIERARCH ESO DET VOLT2 CLKHI2=       5.1000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM2= 'clk2Lo PIXEL1-4' / Name of Low Clock          
HIERARCH ESO DET VOLT2 CLKLO2=       0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM3= 'clk3Hi LSYNC1-2-3-4' / Name of High Clock     
HIERARCH ESO DET VOLT2 CLKHI3=       5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM3= 'clk3Lo LSYNC1-2-3-4' / Name of Low Clock      
HIERARCH ESO DET VOLT2 CLKLO3=       0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM4= 'clk4Hi LINE1-2' / Name of High Clock          
HIERARCH ESO DET VOLT2 CLKHI4=       5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM4= 'clk4Lo LINE1-2' / Name of Low Clock           
HIERARCH ESO DET VOLT2 CLKLO4=       0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM5= 'clk5Hi LINE3-4' / Name of High Clock          
HIERARCH ESO DET VOLT2 CLKHI5=       5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM5= 'clk5Lo LINE3-4' / Name of Low Clock           
HIERARCH ESO DET VOLT2 CLKLO5=       0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM6= 'clk6Hi FSYNC1-2-3-4' / Name of High Clock     
HIERARCH ESO DET VOLT2 CLKHI6=       5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM6= 'clk6Lo FSYNC1-2-3-4' / Name of Low Clock      
HIERARCH ESO DET VOLT2 CLKLO6=       0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM7= 'clk7Hi READ1-2-3-4' / Name of High Clock      
HIERARCH ESO DET VOLT2 CLKHI7=       5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM7= 'clk7Lo READ1-2-3-4' / Name of Low Clock       
HIERARCH ESO DET VOLT2 CLKLO7=       0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM8= 'clk8Hi RESET1-2-3-4' / Name of High Clock     
HIERARCH ESO DET VOLT2 CLKHI8=       5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM8= 'clk8Lo RESET1-2-3-4' / Name of Low Clock      
HIERARCH ESO DET VOLT2 CLKLO8=       0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM9= 'clk9Hi VDD1-2-3-4' / Name of High Clock       
HIERARCH ESO DET VOLT2 CLKHI9=       5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM9= 'clk9Lo VDD1-2-3-4' / Name of Low Clock        
HIERARCH ESO DET VOLT2 CLKLO9=       5.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM10= 'clk10Hi ' / Name of High Clock               
HIERARCH ESO DET VOLT2 CLKHI10=      5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM10= 'clk10Lo ' / Name of Low Clock                
HIERARCH ESO DET VOLT2 CLKLO10=      5.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM11= 'clk11Hi ' / Name of High Clock               
HIERARCH ESO DET VOLT2 CLKHI11=      0.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM11= 'clk11Lo ' / Name of Low Clock                
HIERARCH ESO DET VOLT2 CLKLO11=      0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM12= 'clock12Hi' / Name of High Clock              
HIERARCH ESO DET VOLT2 CLKHI12=      0.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM12= 'clock12Lo' / Name of Low Clock               
HIERARCH ESO DET VOLT2 CLKLO12=      0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM13= 'clock13Hi' / Name of High Clock              
HIERARCH ESO DET VOLT2 CLKHI13=      5.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM13= 'clock13Lo' / Name of Low Clock               
HIERARCH ESO DET VOLT2 CLKLO13=      0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM14= 'clock14Hi' / Name of High Clock              
HIERARCH ESO DET VOLT2 CLKHI14=      0.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM14= 'clock14Lo' / Name of Low Clock               
HIERARCH ESO DET VOLT2 CLKLO14=      0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM15= 'clock15Hi' / Name of High Clock              
HIERARCH ESO DET VOLT2 CLKHI15=      0.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM15= 'clock15Lo' / Name of Low Clock               
HIERARCH ESO DET VOLT2 CLKLO15=      0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 CLKHINM16= 'clock16Hi' / Name of High Clock              
HIERARCH ESO DET VOLT2 CLKHI16=      0.0000 / Set Value High Clock              
HIERARCH ESO DET VOLT2 CLKLONM16= 'clock16Lo' / Name of Low Clock               
HIERARCH ESO DET VOLT2 CLKLO16=      0.0000 / Set Value Low Clock               
HIERARCH ESO DET VOLT2 DCNM1 = 'DC1 VRESET1-2-3-4' / Name of DC Voltage         
HIERARCH ESO DET VOLT2 DC1   =       5.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM2 = 'DC2 DSUB'   / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC2   =       0.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM3 = 'DC3 CELLWELL' / Name of DC Voltage              
HIERARCH ESO DET VOLT2 DC3   =       5.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM4 = 'DC4 VBUS'   / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC4   =       5.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM5 = 'DC5 HIGH1'  / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC5   =       5.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM6 = 'DC6 HIGH2'  / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC6   =       5.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM7 = 'DC7 HIGH3'  / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC7   =       5.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM8 = 'DC8 HIGH4'  / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC8   =       5.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM9 = 'DC9 VDD1-2-3-4' / Name of DC Voltage            
HIERARCH ESO DET VOLT2 DC9   =       5.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM10= 'DC10 REF1 (-2-3-4)' / Name of DC Voltage        
HIERARCH ESO DET VOLT2 DC10  =       7.7500 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM11= 'DC11 REF2'  / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC11  =       0.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM12= 'DC12 REF3'  / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC12  =       0.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM13= 'DC13 REF4'  / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC13  =       0.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM14= 'DC14    '   / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC14  =       0.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM15= 'DC15    '   / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC15  =       0.0000 / Set Value DC Voltage              
HIERARCH ESO DET VOLT2 DCNM16= 'DC16    '   / Name of DC Voltage                
HIERARCH ESO DET VOLT2 DC16  =       0.0000 / Set Value DC Voltage              
HIERARCH ESO DET CHOP FREQ   =     0.000000 / Chopping Frequency                
HIERARCH ESO OCS COMP ID     = 'SW Version 1.44 2001/04/08 22:55:51' / OS Softwa
HIERARCH ESO OCS DID         = 'ESO-VLT-DIC.ISAAC_OS-1.4' / Data dictionary for 
HIERARCH ESO OCS SELECT-ARM  = 'SW      '   / Detector arm                      
COMMENT FTU-1.39/2002-11-29T15:57:11/Default.htt                                
END                                                                             
