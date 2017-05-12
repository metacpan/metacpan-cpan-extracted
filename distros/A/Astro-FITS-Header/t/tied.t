#!perl
# Astro::FITS::Header test harness

# strict
use strict;

#load test
use Test::More tests => 294;

# load modules
use Astro::FITS::Header;
use Astro::FITS::Header::Item;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# read header from DATA block
my @raw = <DATA>;
chomp(@raw);

# build header array
my $header = new Astro::FITS::Header( Cards => \@raw );

# tie
my %keywords;
tie %keywords, "Astro::FITS::Header", $header;

# fetch
my $value = $keywords{"TELESCOP"};
is( "$value", "UKIRT, Mauna Kea, HI");

# store
$keywords{"TELESCOP"} = "JCMT, Mauna Kea, HI";
my @values = $header->value("TELESCOP");
is( "$values[0]", "JCMT, Mauna Kea, HI");

# Get the comment, set a new one and retrieve it
is($keywords{"TELESCOP_COMMENT"}, "Telescope name");
my $new = "Not a telescope";
$keywords{TELESCOP_COMMENT} = $new;
is($keywords{TELESCOP_COMMENT}, $new);


# store 
$keywords{"LIFE"} = 42;
my @end = $header->index('END');
my @test = $header->index('LIFE');

is($end[0],125);
is($test[0],124);


##########
# "Missing" header values
#

ok( exists( $keywords{"MSBID"} ) );

$value = $keywords{"MSBID"};
is( $value, undef );

$value = $keywords{"MSBID_COMMENT"};
is( "$value", "Unique identifier" );

ok( !exists( $keywords{"CSOTAU"} ) );

$value = $keywords{"CSOTAU"};
is( $value, undef );

$value = $keywords{"CSOTAU_COMMENT"};
is( "$value", "                       / Tau at 225 GHz from CSO\n" );

##########
# Multiline comments
#
my $s = "Comment line 1\nComment line 2\nComment line 3";

# Store multiline comment
$keywords{"COMMENT"} = $s;

# It doesn't make any values
@values = $header->value("COMMENT");
is( $values[0], undef);
is( $values[1], undef);
is( $values[2], undef);


# The comments come out correctly in the comment method
my @comments = $header->comment("COMMENT");
my @s = split("\n",$s);
chomp @s;
is( $comments[0], $s[0] );
is( $comments[1], $s[1] );
is( $comments[2], $s[2] );

# The comments come out correctly in the tied method
is( $s."\n", $keywords{"COMMENT"} );

##########
# Multiline values
$s = "0\n1\n2";
my $sr = [0,1,2];

# Assigning with array ref yields correct string
$keywords{"TESTVAL"} = $sr;
is( $keywords{"TESTVAL"}, $s );

# ... and also gives the correct values
my(@vals) = $header->value("TESTVAL");
is($vals[0], 0);
is($vals[1], 1);
is($vals[2], 2);


# ... and also acts correctly in arithmetic expressions
{ no warnings;
  is( $keywords{"TESTVAL"} + 1, 1 );
}

# ... and also truncates OK
$keywords{"TESTVAL"}++;
is($keywords{"TESTVAL"}, 1);

##############################

# delete
delete $keywords{"LIFE"};
my @item = $header->itembyname("LIFE");
unless (defined($item[0])) { ok(1) } else { ok(0) };

# exists
ok(exists $keywords{"SIMPLE"});
ok(!exists $keywords{"ARGH"});
ok(!exists $keywords{"LIFE"});

# firstkey, nextkey
my $line = 0;
my $key;
foreach $key (keys %keywords) {
    my @values = $header->value($key);

    is($header->keyword($line),$key);

    if($key ne 'COMMENT') {  # Skip [multiline] comments...
	# END card is a special case -- should return ' '
	if($key eq 'END') {
	    is(' ',$keywords{$key});
	} else {
	    is($values[0],$keywords{$key});
	}
    }

    do {
	$line += 1;
    }	until(($header->keyword($line)||'') ne 'COMMENT' || $key ne 'COMMENT');

}

# Test array ref return
my $hdr = tied %keywords;

# First get the string
my $str = $keywords{COMMENT};
ok(not ref $str );

# Then the array
$hdr->tiereturnsref(1);
my $strref = $keywords{COMMENT};

is(ref($strref), "ARRAY");

my @strings = @$strref;

is(scalar(@strings), 3); # There are 4 comments
is(join('',@strings), $str);
$hdr->tiereturnsref(0);

# Test that we can copy in a new hash
# This test will fail in v2.4 of Astro::FITS::Header
my $href = \%keywords;
%{ $href } = ( TELESCOP => 'GEMINI', instrume => 'MICHELLE' );
is($href->{TELESCOP}, 'GEMINI');
is($href->{INSTRUME}, 'MICHELLE');


# Test that SIMPLE and END get put at the beginning and end, respectively
 
is($href->{SIMPLE},undef);
is($href->{END},undef);
 
$keywords{SIMPLE} = 0;
$keywords{END} = "Drop this string on the floor";
my @keys = keys %keywords;
is($keys[0],'SIMPLE');
is($keys[3],'END');
is($keywords{SIMPLE},0);
is($keywords{END},' ');


#clear
undef %keywords;

is($header->keyword(0),undef);


# Test the override
my %keywords2;
my $header2 = new Astro::FITS::Header( Cards => \@raw );
tie %keywords2, "Astro::FITS::Header", $header2, tiereturnsref => 1;
my $value2 = $keywords2{COMMENT};
is(ref $value2, "ARRAY");

# Test comment parsing in keyword setting
$href->{NUM} = "3 / test";
is($href->{NUM},3, "Test value from auto-parse");
is($href->{NUM_COMMENT},'test', "Test comment from auto-parse");

$href->{SLASHSTR} = "foo\\/bar / value is 'foo/bar'";
is($href->{SLASHSTR},'foo/bar', "Test value from complex auto-parse");
is($href->{SLASHSTR_COMMENT},'value is \'foo/bar\'', "Test comment from complex auto-parse");

# test HISTORY handling
$keywords{HISTORY} = "foo";
$keywords{HISTORY} .= "bar";
ok($keywords{HISTORY} eq <<FOO
foo
bar
FOO
    );

# principal of least surprise.... you should get back what you put in!
#$href->{REVERSE} = "foo / bar";
#is($href->{REVERSE}, "foo / bar");

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
CNFINDEX=                75488 / Index increments when h/w config changes       
CVF     = 'open    '           / Name of CVF                                    
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
MSBID   =                      / Unique identifier                              
CSOTAU                         / Tau at 225 GHz from CSO                        
END                                                                             
