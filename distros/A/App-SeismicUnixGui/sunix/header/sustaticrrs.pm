package App::SeismicUnixGui::sunix::header::sustaticrrs;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SUSTATICRRS - Elevation STATIC corrections, apply corrections from	

	      headers or from a source and receiver statics file,	

	      includes application of Residual Refraction Statics	



     sustaticrrs <stdin >stdout  [optional parameters]	 		



 Required parameters:							

	none								

 Optional Parameters:							

	v0=v1 or user-defined	or from header, weathering velocity	

	v1=user-defined		or from header, subweathering velocity	

	hdrs=0			=1 to read statics from headers		

 				=2 to read statics from files		

	sign=1			=-1 to subtract statics from traces(up shift)

 Options when hdrs=2:							

	sou_file=		input file for source statics (ms) 	

	rec_file=		input file for receiver statics (ms) 	

	ns=240 			number of sources 			

	nr=335 			number of receivers 			

	no=96 			number of offsets			



 Options when hdrs=3:                                                  

       blvl_file=              base of the near-surface model file (sampled

                                  at CMP locations)                    

       refr_file=              horizontal reference datum file (sampled at

                                  CMP locations)                       

       nsamp=                  number of midpoints on line             

       fx=                     first x location in velocity model      

       dx=                     midpoint interval                       

       V_r=                    replacement velocity                    

       mx=                     number of velocity model samples in     

                                  lateral direction                    

       mz=                     number of velocity model samples in     

                                  vertical direction                   

       dzv=                    velocity model depth interval           

       vfile=                  near-surface velocity model             



 Options when hdrs=4:                                                  

       nsamp=                  number of midpoints on line             

       fx=                     first x location in velocity model      ", 

       dx=                     midpoint interval                       ", 



 Options when hdrs=5:                                                  

       none                                                            



 Notes:								

 For hdrs=1, statics calculation is not performed, statics correction  

 is applied to the data by reading statics (in ms) from the header.	



 For hdrs=0, field statics are calculated, and				

 	input field sut is assumed measured in ms.			

 	output field sstat equals 10^scalel*(sdel - selev + sdepth)/swevel	

 	output field gstat equals sstat - sut/1000.				

 	output field tstat equals sstat + gstat + 10^scalel*(selev - gelev)/wevel



 For hdrs=2, statics are surface consistently obtained from the 	

 statics files. The geometry should be regular.			

 The source- and receiver-statics files should be unformated C binary 	

 floats and contain the statics (in ms) as a function of surface location.



 For hdrs=3, residual refraction statics and average refraction statics

 are computed.  For hdrs=4, residual refraction statics are applied,   

 and for hdrs=5, average refraction statics are applied (Cox, 1999).   

 These three options are coupled in many data processing sequences:    

 before stack residual and average refraction statics are computed but 

 only residual refractions statics are applied, and after stack average

 refraction statics are applied.  Refraction statics are often split   

 like this to avoid biasing stacking velocities.  The files blvl_file  

 and refr_file are the base of the velocity model defined in vfile and 

 the final reference datum, as described by Cox (1999), respectively.  

 Residual refraction statics are stored in the header field gstat, and 

 the average statics are stored in the header field tstat.  V_r is the 

 replacement velocity as described by Cox (1999).  The velocity file,  

 vfile, is designed to work with a horizontal upper surface defined in 

 refr_file.  If the survey has irregular topography, the horizontal    

 upper surface should be above the highest topographic point on the    

 line, and the velocity between this horizontal surface and topography 

 should be some very large value, such as 999999999, so that the       

 traveltimes through that region are inconsequential.                  



 Credits:

	CWP: Jamie Burns



	CWP: Modified by Mohammed Alfaraj, 11/10/1992, for reading

	     statics from headers and including sign (+-) option



      CWP: Modified by Timo Tjan, 29 June 1995, to include input of

           source and receiver statics from files. 



      CWP: Modified by Chris Robinson, 11/2000, to include the splitting

           of refraction statics into residuals and averages



 Trace header fields accessed:  ns, dt, delrt, gelev, selev,

	sdepth, gdel, sdel, swevel, sut, scalel

 Trace header fields modified:  sstat, gstat, tstat



 References:



 Cox, M., 1999, Static corrections for seismic reflection surveys:

    Soc. Expl. Geophys.





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

my $sustaticrrs			= {
	_V_r					=> '',
	_blvl_file					=> '',
	_dx					=> '',
	_dzv					=> '',
	_fx					=> '',
	_hdrs					=> '',
	_mx					=> '',
	_mz					=> '',
	_no					=> '',
	_nr					=> '',
	_ns					=> '',
	_nsamp					=> '',
	_rec_file					=> '',
	_refr_file					=> '',
	_sign					=> '',
	_sou_file					=> '',
	_v0					=> '',
	_v1					=> '',
	_vfile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sustaticrrs->{_Step}     = 'sustaticrrs'.$sustaticrrs->{_Step};
	return ( $sustaticrrs->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sustaticrrs->{_note}     = 'sustaticrrs'.$sustaticrrs->{_note};
	return ( $sustaticrrs->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sustaticrrs->{_V_r}			= '';
		$sustaticrrs->{_blvl_file}			= '';
		$sustaticrrs->{_dx}			= '';
		$sustaticrrs->{_dzv}			= '';
		$sustaticrrs->{_fx}			= '';
		$sustaticrrs->{_hdrs}			= '';
		$sustaticrrs->{_mx}			= '';
		$sustaticrrs->{_mz}			= '';
		$sustaticrrs->{_no}			= '';
		$sustaticrrs->{_nr}			= '';
		$sustaticrrs->{_ns}			= '';
		$sustaticrrs->{_nsamp}			= '';
		$sustaticrrs->{_rec_file}			= '';
		$sustaticrrs->{_refr_file}			= '';
		$sustaticrrs->{_sign}			= '';
		$sustaticrrs->{_sou_file}			= '';
		$sustaticrrs->{_v0}			= '';
		$sustaticrrs->{_v1}			= '';
		$sustaticrrs->{_vfile}			= '';
		$sustaticrrs->{_Step}			= '';
		$sustaticrrs->{_note}			= '';
 }


=head2 sub V_r 


=cut

 sub V_r {

	my ( $self,$V_r )		= @_;
	if ( $V_r ne $empty_string ) {

		$sustaticrrs->{_V_r}		= $V_r;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' V_r='.$sustaticrrs->{_V_r};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' V_r='.$sustaticrrs->{_V_r};

	} else { 
		print("sustaticrrs, V_r, missing V_r,\n");
	 }
 }


=head2 sub blvl_file 


=cut

 sub blvl_file {

	my ( $self,$blvl_file )		= @_;
	if ( $blvl_file ne $empty_string ) {

		$sustaticrrs->{_blvl_file}		= $blvl_file;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' blvl_file='.$sustaticrrs->{_blvl_file};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' blvl_file='.$sustaticrrs->{_blvl_file};

	} else { 
		print("sustaticrrs, blvl_file, missing blvl_file,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sustaticrrs->{_dx}		= $dx;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' dx='.$sustaticrrs->{_dx};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' dx='.$sustaticrrs->{_dx};

	} else { 
		print("sustaticrrs, dx, missing dx,\n");
	 }
 }


=head2 sub dzv 


=cut

 sub dzv {

	my ( $self,$dzv )		= @_;
	if ( $dzv ne $empty_string ) {

		$sustaticrrs->{_dzv}		= $dzv;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' dzv='.$sustaticrrs->{_dzv};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' dzv='.$sustaticrrs->{_dzv};

	} else { 
		print("sustaticrrs, dzv, missing dzv,\n");
	 }
 }


=head2 sub fx 


=cut

 sub fx {

	my ( $self,$fx )		= @_;
	if ( $fx ne $empty_string ) {

		$sustaticrrs->{_fx}		= $fx;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' fx='.$sustaticrrs->{_fx};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' fx='.$sustaticrrs->{_fx};

	} else { 
		print("sustaticrrs, fx, missing fx,\n");
	 }
 }


=head2 sub hdrs 


=cut

 sub hdrs {

	my ( $self,$hdrs )		= @_;
	if ( $hdrs ne $empty_string ) {

		$sustaticrrs->{_hdrs}		= $hdrs;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' hdrs='.$sustaticrrs->{_hdrs};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' hdrs='.$sustaticrrs->{_hdrs};

	} else { 
		print("sustaticrrs, hdrs, missing hdrs,\n");
	 }
 }


=head2 sub mx 


=cut

 sub mx {

	my ( $self,$mx )		= @_;
	if ( $mx ne $empty_string ) {

		$sustaticrrs->{_mx}		= $mx;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' mx='.$sustaticrrs->{_mx};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' mx='.$sustaticrrs->{_mx};

	} else { 
		print("sustaticrrs, mx, missing mx,\n");
	 }
 }


=head2 sub mz 


=cut

 sub mz {

	my ( $self,$mz )		= @_;
	if ( $mz ne $empty_string ) {

		$sustaticrrs->{_mz}		= $mz;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' mz='.$sustaticrrs->{_mz};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' mz='.$sustaticrrs->{_mz};

	} else { 
		print("sustaticrrs, mz, missing mz,\n");
	 }
 }


=head2 sub no 


=cut

 sub no {

	my ( $self,$no )		= @_;
	if ( $no ne $empty_string ) {

		$sustaticrrs->{_no}		= $no;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' no='.$sustaticrrs->{_no};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' no='.$sustaticrrs->{_no};

	} else { 
		print("sustaticrrs, no, missing no,\n");
	 }
 }


=head2 sub nr 


=cut

 sub nr {

	my ( $self,$nr )		= @_;
	if ( $nr ne $empty_string ) {

		$sustaticrrs->{_nr}		= $nr;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' nr='.$sustaticrrs->{_nr};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' nr='.$sustaticrrs->{_nr};

	} else { 
		print("sustaticrrs, nr, missing nr,\n");
	 }
 }


=head2 sub ns 


=cut

 sub ns {

	my ( $self,$ns )		= @_;
	if ( $ns ne $empty_string ) {

		$sustaticrrs->{_ns}		= $ns;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' ns='.$sustaticrrs->{_ns};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' ns='.$sustaticrrs->{_ns};

	} else { 
		print("sustaticrrs, ns, missing ns,\n");
	 }
 }


=head2 sub nsamp 


=cut

 sub nsamp {

	my ( $self,$nsamp )		= @_;
	if ( $nsamp ne $empty_string ) {

		$sustaticrrs->{_nsamp}		= $nsamp;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' nsamp='.$sustaticrrs->{_nsamp};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' nsamp='.$sustaticrrs->{_nsamp};

	} else { 
		print("sustaticrrs, nsamp, missing nsamp,\n");
	 }
 }


=head2 sub rec_file 


=cut

 sub rec_file {

	my ( $self,$rec_file )		= @_;
	if ( $rec_file ne $empty_string ) {

		$sustaticrrs->{_rec_file}		= $rec_file;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' rec_file='.$sustaticrrs->{_rec_file};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' rec_file='.$sustaticrrs->{_rec_file};

	} else { 
		print("sustaticrrs, rec_file, missing rec_file,\n");
	 }
 }


=head2 sub refr_file 


=cut

 sub refr_file {

	my ( $self,$refr_file )		= @_;
	if ( $refr_file ne $empty_string ) {

		$sustaticrrs->{_refr_file}		= $refr_file;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' refr_file='.$sustaticrrs->{_refr_file};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' refr_file='.$sustaticrrs->{_refr_file};

	} else { 
		print("sustaticrrs, refr_file, missing refr_file,\n");
	 }
 }


=head2 sub sign 


=cut

 sub sign {

	my ( $self,$sign )		= @_;
	if ( $sign ne $empty_string ) {

		$sustaticrrs->{_sign}		= $sign;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' sign='.$sustaticrrs->{_sign};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' sign='.$sustaticrrs->{_sign};

	} else { 
		print("sustaticrrs, sign, missing sign,\n");
	 }
 }


=head2 sub sou_file 


=cut

 sub sou_file {

	my ( $self,$sou_file )		= @_;
	if ( $sou_file ne $empty_string ) {

		$sustaticrrs->{_sou_file}		= $sou_file;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' sou_file='.$sustaticrrs->{_sou_file};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' sou_file='.$sustaticrrs->{_sou_file};

	} else { 
		print("sustaticrrs, sou_file, missing sou_file,\n");
	 }
 }


=head2 sub v0 


=cut

 sub v0 {

	my ( $self,$v0 )		= @_;
	if ( $v0 ne $empty_string ) {

		$sustaticrrs->{_v0}		= $v0;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' v0='.$sustaticrrs->{_v0};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' v0='.$sustaticrrs->{_v0};

	} else { 
		print("sustaticrrs, v0, missing v0,\n");
	 }
 }


=head2 sub v1 


=cut

 sub v1 {

	my ( $self,$v1 )		= @_;
	if ( $v1 ne $empty_string ) {

		$sustaticrrs->{_v1}		= $v1;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' v1='.$sustaticrrs->{_v1};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' v1='.$sustaticrrs->{_v1};

	} else { 
		print("sustaticrrs, v1, missing v1,\n");
	 }
 }


=head2 sub vfile 


=cut

 sub vfile {

	my ( $self,$vfile )		= @_;
	if ( $vfile ne $empty_string ) {

		$sustaticrrs->{_vfile}		= $vfile;
		$sustaticrrs->{_note}		= $sustaticrrs->{_note}.' vfile='.$sustaticrrs->{_vfile};
		$sustaticrrs->{_Step}		= $sustaticrrs->{_Step}.' vfile='.$sustaticrrs->{_vfile};

	} else { 
		print("sustaticrrs, vfile, missing vfile,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 18;

    return($max_index);
}
 
 
1;
