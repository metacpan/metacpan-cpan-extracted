package App::SeismicUnixGui::sunix::header::suutm;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUUTM - UTM projection of longitude and latitude in SU trace headers  



 suutm <stdin >stdout [optional parameters]                            



 Optional parameters:                                                  

    counit=(from header) input coordinate units code:                  

                    =1: length (meters or feet; no UTM projection)     

                    =2: seconds of arc                                 

                    =3: decimal degrees                                

                    =4: degrees, minutes, seconds                      

    idx=23          reference ellipsoid index (default is WGS 1984)    

    a=(from idx)    user-specified semimajor axis of ellipsoid         

    f=(from idx)    user-specified flattening of ellipsoid             

    zkey=           if set, header key to store UTM zone number        

    verbose=0       =1: echo ellipsoid parameters                      



    lon0=           central meridian for TM projection in degrees      

                    (default uses the 60 standard UTM longitude zones) 

    xoff=500000     false Easting (default: UTM)                       

    ysoff=10000000  false Northing, southern hemisphere (default: UTM) 

    ynoff=0         false Northing, northern hemisphere (default: UTM) 



 Notes:                                                                

    Universal Transverse Mercator (UTM) coordinates are defined between

    latitudes 80S (-80) and 84N (84). Longitude values must be between 

    -180 degrees (west) and 179.999... degrees (east).                 



    Latitudes are read from sy and gy (N positive), and longitudes     

    are read from sx and gx (E positive).                              

    The UTM zone is determined from the receiver coordinates gy and gx.



    Use suazimuth to calculate shot-receiver azimuths and offsets.     



 Reference ellipsoids:                                                 

    An ellipsoid may be specified by its semimajor axis a and its      

    flattening f, or one of the following ellipsoids may be selected   

    by its index idx (semimajor axes in meters):                       

     0  Sphere with radius of 6371000 m                                

     1  Airy 1830                                                      

     2  Australian National 1965                                       

     3  Bessel 1841 (Ethiopia, Indonesia, Japan, Korea)                

     4  Bessel 1841 (Namibia)                                          

     5  Clarke 1866                                                    

     6  Clarke 1880                                                    

     7  Everest (Brunei, E. Malaysia)                                  

     8  Everest (India 1830)                                           

     9  Everest (India 1956)                                           

    10  Everest (Pakistan)                                             

    11  Everest (W. Malaysia, Singapore 1948)                          

    12  Everest (W. Malaysia 1969)                                     

    13  Geodetic Reference System 1980 (GRS 1980)                      

    14  Helmert 1906                                                   

    15  Hough 1960                                                     

    16  Indonesian 1974                                                

    17  International 1924 / Hayford 1909                              

    18  Krassovsky 1940                                                

    19  Modified Airy                                                  

    20  Modified Fischer 1960                                          

    21  South American 1969                                            

    22  World Geodetic System 1972 (WGS 1972)                          

    23  World Geodetic System 1984 (WGS 1984) / NAD 1983               





 UTM grid:

 The Universal Transverse Mercator (UTM) system is a world wide

 coordinate system defined between 80S and 84N. It divides the

 Earth into 60 six-degree zones. Zone number 1 has its central

 meridian at 177W (-177 degrees), and numbers increase eastward.



 Within each zone, an Easting of 500,000 m is assigned to its 

 central meridian to avoid negative coordinates. On the northern

 hemisphere, Northings start at 0 m at the equator and increase 

 northward. On the southern hemisphere a false Northing of 

 10,000,000 m is applied, i.e. Northings start at 10,000,000 m at 

 the equator and decrease southward.



 Coordinate encoding (sx,sy,gx,gy):

    counit=1  units of length (coordinates are not converted)

    counit=2  seconds of arc

    counit=3  decimal degrees 

    counit=4  degrees, minutes and seconds encoded as integer DDDMMSS 

              with scalco=1 or DDDMMSS.ss with scalco=-100 (see segy.h)

 Units of length are also assumed, if counit <= 0 or counit >= 5.





 Author: 

    Nils Maercklin, RISSC, University of Naples, Italy, March 2007



 References:

 NIMA (2000). Department of Defense World Geodetic System 1984 - 

    its definition and relationships with local geodetic systems.

    Technical Report TR8350.2. National Imagery and Mapping Agency, 

    Geodesy and Geophysics Department, St. Louis, MO. 3rd edition.

 J. P. Snyder (1987). Map Projections - A Working Manual. 

    U.S. Geological Survey Professional Paper 1395, 383 pages.

    U.S. Government Printing Office.





 Trace header fields accessed: sx, sy, gx, gy, scalco, counit

 Trace header fields modified: sx, sy, gx, gy, scalco, counit



=head2 User's notes (Juan Lorenzo)
untested

=cut


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $PS_SEISMIC      	= $Project->PS_SEISMIC();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $suutm			= {
	_a					=> '',
	_counit					=> '',
	_f					=> '',
	_idx					=> '',
	_lon0					=> '',
	_scalco					=> '',
	_verbose					=> '',
	_xoff					=> '',
	_ynoff					=> '',
	_ysoff					=> '',
	_zkey					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suutm->{_Step}     = 'suutm'.$suutm->{_Step};
	return ( $suutm->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suutm->{_note}     = 'suutm'.$suutm->{_note};
	return ( $suutm->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suutm->{_a}			= '';
		$suutm->{_counit}			= '';
		$suutm->{_f}			= '';
		$suutm->{_idx}			= '';
		$suutm->{_lon0}			= '';
		$suutm->{_scalco}			= '';
		$suutm->{_verbose}			= '';
		$suutm->{_xoff}			= '';
		$suutm->{_ynoff}			= '';
		$suutm->{_ysoff}			= '';
		$suutm->{_zkey}			= '';
		$suutm->{_Step}			= '';
		$suutm->{_note}			= '';
 }


=head2 sub a 


=cut

 sub a {

	my ( $self,$a )		= @_;
	if ( $a ne $empty_string ) {

		$suutm->{_a}		= $a;
		$suutm->{_note}		= $suutm->{_note}.' a='.$suutm->{_a};
		$suutm->{_Step}		= $suutm->{_Step}.' a='.$suutm->{_a};

	} else { 
		print("suutm, a, missing a,\n");
	 }
 }


=head2 sub counit 


=cut

 sub counit {

	my ( $self,$counit )		= @_;
	if ( $counit ne $empty_string ) {

		$suutm->{_counit}		= $counit;
		$suutm->{_note}		= $suutm->{_note}.' counit='.$suutm->{_counit};
		$suutm->{_Step}		= $suutm->{_Step}.' counit='.$suutm->{_counit};

	} else { 
		print("suutm, counit, missing counit,\n");
	 }
 }


=head2 sub f 


=cut

 sub f {

	my ( $self,$f )		= @_;
	if ( $f ne $empty_string ) {

		$suutm->{_f}		= $f;
		$suutm->{_note}		= $suutm->{_note}.' f='.$suutm->{_f};
		$suutm->{_Step}		= $suutm->{_Step}.' f='.$suutm->{_f};

	} else { 
		print("suutm, f, missing f,\n");
	 }
 }


=head2 sub idx 


=cut

 sub idx {

	my ( $self,$idx )		= @_;
	if ( $idx ne $empty_string ) {

		$suutm->{_idx}		= $idx;
		$suutm->{_note}		= $suutm->{_note}.' idx='.$suutm->{_idx};
		$suutm->{_Step}		= $suutm->{_Step}.' idx='.$suutm->{_idx};

	} else { 
		print("suutm, idx, missing idx,\n");
	 }
 }


=head2 sub lon0 


=cut

 sub lon0 {

	my ( $self,$lon0 )		= @_;
	if ( $lon0 ne $empty_string ) {

		$suutm->{_lon0}		= $lon0;
		$suutm->{_note}		= $suutm->{_note}.' lon0='.$suutm->{_lon0};
		$suutm->{_Step}		= $suutm->{_Step}.' lon0='.$suutm->{_lon0};

	} else { 
		print("suutm, lon0, missing lon0,\n");
	 }
 }


=head2 sub scalco 


=cut

 sub scalco {

	my ( $self,$scalco )		= @_;
	if ( $scalco ne $empty_string ) {

		$suutm->{_scalco}		= $scalco;
		$suutm->{_note}		= $suutm->{_note}.' scalco='.$suutm->{_scalco};
		$suutm->{_Step}		= $suutm->{_Step}.' scalco='.$suutm->{_scalco};

	} else { 
		print("suutm, scalco, missing scalco,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suutm->{_verbose}		= $verbose;
		$suutm->{_note}		= $suutm->{_note}.' verbose='.$suutm->{_verbose};
		$suutm->{_Step}		= $suutm->{_Step}.' verbose='.$suutm->{_verbose};

	} else { 
		print("suutm, verbose, missing verbose,\n");
	 }
 }


=head2 sub xoff 


=cut

 sub xoff {

	my ( $self,$xoff )		= @_;
	if ( $xoff ne $empty_string ) {

		$suutm->{_xoff}		= $xoff;
		$suutm->{_note}		= $suutm->{_note}.' xoff='.$suutm->{_xoff};
		$suutm->{_Step}		= $suutm->{_Step}.' xoff='.$suutm->{_xoff};

	} else { 
		print("suutm, xoff, missing xoff,\n");
	 }
 }


=head2 sub ynoff 


=cut

 sub ynoff {

	my ( $self,$ynoff )		= @_;
	if ( $ynoff ne $empty_string ) {

		$suutm->{_ynoff}		= $ynoff;
		$suutm->{_note}		= $suutm->{_note}.' ynoff='.$suutm->{_ynoff};
		$suutm->{_Step}		= $suutm->{_Step}.' ynoff='.$suutm->{_ynoff};

	} else { 
		print("suutm, ynoff, missing ynoff,\n");
	 }
 }


=head2 sub ysoff 


=cut

 sub ysoff {

	my ( $self,$ysoff )		= @_;
	if ( $ysoff ne $empty_string ) {

		$suutm->{_ysoff}		= $ysoff;
		$suutm->{_note}		= $suutm->{_note}.' ysoff='.$suutm->{_ysoff};
		$suutm->{_Step}		= $suutm->{_Step}.' ysoff='.$suutm->{_ysoff};

	} else { 
		print("suutm, ysoff, missing ysoff,\n");
	 }
 }


=head2 sub zkey 


=cut

 sub zkey {

	my ( $self,$zkey )		= @_;
	if ( $zkey ne $empty_string ) {

		$suutm->{_zkey}		= $zkey;
		$suutm->{_note}		= $suutm->{_note}.' zkey='.$suutm->{_zkey};
		$suutm->{_Step}		= $suutm->{_Step}.' zkey='.$suutm->{_zkey};

	} else { 
		print("suutm, zkey, missing zkey,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 10;

    return($max_index);
}
 
 
1;
