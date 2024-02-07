package App::SeismicUnixGui::sunix::header::suazimuth;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUAZIMUTH - compute trace AZIMUTH, offset, and midpoint coordinates    

             and set user-specified header fields to these values       



  suazimuth <stdin >stdout [optional parameters]                        



 Required parameters:                                                   

     none                                                               



 Optional parameters:                                                   

   key=otrav      header field to store computed azimuths in            

   scale=1.0      value(key) = scale * azimuth                          

   az=0           azimuth convention flag                               

                   0: 0-179.999 deg, reciprocity assumed                

                   1: 0-359.999 deg, points from receiver to source     

                  -1: 0-359.999 deg, points from source to receiver     

   sector=1.0     if set, defines output in sectors of size             

                  sector=degrees_per_sector, the default mode is        

                  the full range of angles specified by az              



   offset=0       if offset=1 then set offset header field              

   offkey=offset  header field to store computed offsets in             



   cmp=0          if cmp=1, then compute midpoint coordinates and       

                  set header fields for (cmpx, cmpy)                    

   mxkey=ep       header field to store computed cmpx in                

   mykey=cdp      header field to store computed cmpy in                



 Notes:                                                                 

   All values are computed from the values in the coordinate fields     

   sx,sy (source) and gx,gy (receiver).                                 

   The output field "otrav" for the azimuth was chosen arbitrarily as 

   an example of a little-used header field, however, the user may      

   choose any field that is convenient for his or her application.      



   Setting the sector=number_of_degrees_per_sector sets key field to    

   sector number rather than an angle in degrees.                       



   For az=0, azimuths are measured from the North, however, reciprocity 

   is assumed, so azimuths go from 0 to 179.9999 degrees. If sector     

   option is set, then the range is from 0 to 180/sector.               



   For az=1, azimuths are measured from the North, with the assumption  

   that the direction vector points from the receiver to the source.    

   For az=-1, the direction vector points from the source to the        

   receiver. No reciprocity is assumed in these cases, so the angles go 

   from 0 to 359.999 degrees.                                           

   If the sector option is set, then the range is from 0 to 360/sector. 



 Caveat:                                                                

   This program honors the value of scalco in scaling the values of     

   sx,sy,gx,gy. Type "sukeyword scalco" for more information.         



   Type "sukeyword -o" to see the keywords and descriptions of all    

   header fields.                                                       



   To plot midpoints, use: su3dchart                                    





 Credits:

  based on suchw, su3dchart

      CWP: John Stockwell and  UTulsa: Chris Liner, Oct. 1998

      UTulsa: Chris Liner added offset option, Feb. 2002

         cll: fixed offset option and added cmp option, May 2003

      RISSC: Nils Maercklin added key options for offset and 

             midpoints, and added azimuth direction option, Sep. 2006



  Algorithms:

      offset = osign * sqrt( (gx-sx)*(gx-sx) + (gy-sy)*(gy-sy) )

               with osign = sgn( min((sx-gx),(sy-gy)) )



      midpoint x  value  xm = (sx + gx)/2

      midpoint y  value  ym = (sy + gy)/2

 

  Azimuth will be defined as the angle, measured in degrees,

  turned from North, of a vector pointing to the source from the midpoint, 

  or from the midpoint to the source. Azimuths go from 0-179.000 degrees

  or from 0-180.0 degrees.

   

  value(key) = scale*[90.0 - (180.0/PI)*(atan((sy - ym)/(sx - xm))) ]

      or

  value(key) = scale*[180.0 - (180.0/PI)*(atan2((ym - sy),(xm - sx)) ]

 

  Trace header fields accessed: sx, sy, gx, gy, scalco. 

  Trace header fields modified: (user-specified keys)





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

my $suazimuth			= {
	_az					=> '',
	_cmp					=> '',
	_key					=> '',
	_mxkey					=> '',
	_mykey					=> '',
	_offkey					=> '',
	_offset					=> '',
	_osign					=> '',
	_scale					=> '',
	_sector					=> '',
	_xm					=> '',
	_ym					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suazimuth->{_Step}     = 'suazimuth'.$suazimuth->{_Step};
	return ( $suazimuth->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suazimuth->{_note}     = 'suazimuth'.$suazimuth->{_note};
	return ( $suazimuth->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suazimuth->{_az}			= '';
		$suazimuth->{_cmp}			= '';
		$suazimuth->{_key}			= '';
		$suazimuth->{_mxkey}			= '';
		$suazimuth->{_mykey}			= '';
		$suazimuth->{_offkey}			= '';
		$suazimuth->{_offset}			= '';
		$suazimuth->{_osign}			= '';
		$suazimuth->{_scale}			= '';
		$suazimuth->{_sector}			= '';
		$suazimuth->{_xm}			= '';
		$suazimuth->{_ym}			= '';
		$suazimuth->{_Step}			= '';
		$suazimuth->{_note}			= '';
 }


=head2 sub az 


=cut

 sub az {

	my ( $self,$az )		= @_;
	if ( $az ne $empty_string ) {

		$suazimuth->{_az}		= $az;
		$suazimuth->{_note}		= $suazimuth->{_note}.' az='.$suazimuth->{_az};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' az='.$suazimuth->{_az};

	} else { 
		print("suazimuth, az, missing az,\n");
	 }
 }


=head2 sub cmp 


=cut

 sub cmp {

	my ( $self,$cmp )		= @_;
	if ( $cmp ne $empty_string ) {

		$suazimuth->{_cmp}		= $cmp;
		$suazimuth->{_note}		= $suazimuth->{_note}.' cmp='.$suazimuth->{_cmp};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' cmp='.$suazimuth->{_cmp};

	} else { 
		print("suazimuth, cmp, missing cmp,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$suazimuth->{_key}		= $key;
		$suazimuth->{_note}		= $suazimuth->{_note}.' key='.$suazimuth->{_key};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' key='.$suazimuth->{_key};

	} else { 
		print("suazimuth, key, missing key,\n");
	 }
 }


=head2 sub mxkey 


=cut

 sub mxkey {

	my ( $self,$mxkey )		= @_;
	if ( $mxkey ne $empty_string ) {

		$suazimuth->{_mxkey}		= $mxkey;
		$suazimuth->{_note}		= $suazimuth->{_note}.' mxkey='.$suazimuth->{_mxkey};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' mxkey='.$suazimuth->{_mxkey};

	} else { 
		print("suazimuth, mxkey, missing mxkey,\n");
	 }
 }


=head2 sub mykey 


=cut

 sub mykey {

	my ( $self,$mykey )		= @_;
	if ( $mykey ne $empty_string ) {

		$suazimuth->{_mykey}		= $mykey;
		$suazimuth->{_note}		= $suazimuth->{_note}.' mykey='.$suazimuth->{_mykey};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' mykey='.$suazimuth->{_mykey};

	} else { 
		print("suazimuth, mykey, missing mykey,\n");
	 }
 }


=head2 sub offkey 


=cut

 sub offkey {

	my ( $self,$offkey )		= @_;
	if ( $offkey ne $empty_string ) {

		$suazimuth->{_offkey}		= $offkey;
		$suazimuth->{_note}		= $suazimuth->{_note}.' offkey='.$suazimuth->{_offkey};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' offkey='.$suazimuth->{_offkey};

	} else { 
		print("suazimuth, offkey, missing offkey,\n");
	 }
 }


=head2 sub offset 


=cut

 sub offset {

	my ( $self,$offset )		= @_;
	if ( $offset ne $empty_string ) {

		$suazimuth->{_offset}		= $offset;
		$suazimuth->{_note}		= $suazimuth->{_note}.' offset='.$suazimuth->{_offset};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' offset='.$suazimuth->{_offset};

	} else { 
		print("suazimuth, offset, missing offset,\n");
	 }
 }


=head2 sub osign 


=cut

 sub osign {

	my ( $self,$osign )		= @_;
	if ( $osign ne $empty_string ) {

		$suazimuth->{_osign}		= $osign;
		$suazimuth->{_note}		= $suazimuth->{_note}.' osign='.$suazimuth->{_osign};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' osign='.$suazimuth->{_osign};

	} else { 
		print("suazimuth, osign, missing osign,\n");
	 }
 }


=head2 sub scale 


=cut

 sub scale {

	my ( $self,$scale )		= @_;
	if ( $scale ne $empty_string ) {

		$suazimuth->{_scale}		= $scale;
		$suazimuth->{_note}		= $suazimuth->{_note}.' scale='.$suazimuth->{_scale};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' scale='.$suazimuth->{_scale};

	} else { 
		print("suazimuth, scale, missing scale,\n");
	 }
 }


=head2 sub sector 


=cut

 sub sector {

	my ( $self,$sector )		= @_;
	if ( $sector ne $empty_string ) {

		$suazimuth->{_sector}		= $sector;
		$suazimuth->{_note}		= $suazimuth->{_note}.' sector='.$suazimuth->{_sector};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' sector='.$suazimuth->{_sector};

	} else { 
		print("suazimuth, sector, missing sector,\n");
	 }
 }


=head2 sub xm 


=cut

 sub xm {

	my ( $self,$xm )		= @_;
	if ( $xm ne $empty_string ) {

		$suazimuth->{_xm}		= $xm;
		$suazimuth->{_note}		= $suazimuth->{_note}.' xm='.$suazimuth->{_xm};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' xm='.$suazimuth->{_xm};

	} else { 
		print("suazimuth, xm, missing xm,\n");
	 }
 }


=head2 sub ym 


=cut

 sub ym {

	my ( $self,$ym )		= @_;
	if ( $ym ne $empty_string ) {

		$suazimuth->{_ym}		= $ym;
		$suazimuth->{_note}		= $suazimuth->{_note}.' ym='.$suazimuth->{_ym};
		$suazimuth->{_Step}		= $suazimuth->{_Step}.' ym='.$suazimuth->{_ym};

	} else { 
		print("suazimuth, ym, missing ym,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 11;

    return($max_index);
}
 
 
1;
