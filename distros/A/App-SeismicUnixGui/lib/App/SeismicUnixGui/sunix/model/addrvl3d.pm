package App::SeismicUnixGui::sunix::model::addrvl3d;

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
 ADDRVL3D - Add a random velocity layer (RVL) to a gridded             

            v(x,y,z) velocity model                                    



	addrvl3d <infile n1= n2= >outfile [parameters]			



 Required Parameters:							

 n1=		number of samples along 1st dimension			

 n2=		number of samples along 2nd dimension			



 Optional Parameters:							



 n3=1          number of samples along 3rd dimension			



 mode=1             add single layer populated with random vels	

                    =2 add nrvl layers of random thickness and vel     

 seed=from_clock    random number seed (integer)			



 ---->New layer geometry info						

 i1beg=1       1st dimension beginning sample 				

 i1end=n1/5    1st dimension ending sample 				

 i2beg=1       2nd dimension beginning sample 				

 i2end=n2      2nd dimension ending sample 				

 i3beg=1       3rd dimension beginning sample 				

 i3end=n3      3rd dimension ending sample 				

 ---->New layer velocity info						

 vlsd=v/3     range (std dev) of random velocity in layer, 		

               where v=v(0,0,i1) and i1=(i1beg+i1end)/2 	 	

 add=1         add random vel to original vel (v_orig) at that point 	

               =0 replace vel at that point with (v_orig+v_rand) 	

 how=0         random vels can be higher or lower than v_orig		

               =1 random vels are always lower than v_orig		

               =2 random vels are always higher than v_orig		

 cvel=2000     layer filled with constant velocity cvel 		

               (overides vlsd,add,how params)			

 ---->Smoothing parameters (0 = no smoothing)				

 r1=0.0	1st dimension operator length in samples		

 r2=0.0	2nd dimension operator length in samples		

 r3=0.0	3rd dimension operator length in samples		

 slowness=0	=1 smoothing on slowness; =0 smoothing on velocity	



 nrvl=n1/10    number of const velocity layers to add     		

 pdv=10.       percentage velocity deviation (max) from input model	



 Notes:								

 1. Smoothing radii usually fall in the range of [0,20].		

 2. Smoothing radii can be used to set aspect ratio of random velocity 

    anomalies in the new layer.  For example (r1=5,r2=0,r3=0) will     

    result in vertical vel streaks that mimick vertical fracturing.    

 3. Smoothing on slowness works better to preserve traveltimes relative

    to the unsmoothed case.						

 4. Default case is a random velocity (+/-30%) near surface layer whose

    thickness is 200f the total 2D model thickness.			

 5. Each layer vel is a random perturbation on input model at that level.

 6. The depth dimension is assumed to be along axis 1.			



 Example:								

 1. 2D RVL with no smoothing						

   makevel nz=250 nx=200 | addrvl3d n1=250 n2=200 | ximage n1=250      

 2. 3D RVL with no smoothing						

   makevel nz=250 nx=200 ny=220 |					

   addrvl3d n1=250 n2=200 n3=220 | 					

   xmovie n1=250 n2=200					    	







 Author:  Saudi Aramco: Chris Liner Jan/Feb 2005

          Based on smooth3d (CWP: Zhenyue Liu  March 1995)





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

my $addrvl3d			= {
	_add					=> '',
	_cvel					=> '',
	_how					=> '',
	_i1beg					=> '',
	_i1end					=> '',
	_i2beg					=> '',
	_i2end					=> '',
	_i3beg					=> '',
	_i3end					=> '',
	_mode					=> '',
	_n1					=> '',
	_n2					=> '',
	_n3					=> '',
	_nrvl					=> '',
	_nz					=> '',
	_pdv					=> '',
	_r1					=> '',
	_r2					=> '',
	_r3					=> '',
	_seed					=> '',
	_slowness					=> '',
	_v					=> '',
	_vlsd					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$addrvl3d->{_Step}     = 'addrvl3d'.$addrvl3d->{_Step};
	return ( $addrvl3d->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$addrvl3d->{_note}     = 'addrvl3d'.$addrvl3d->{_note};
	return ( $addrvl3d->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$addrvl3d->{_add}			= '';
		$addrvl3d->{_cvel}			= '';
		$addrvl3d->{_how}			= '';
		$addrvl3d->{_i1beg}			= '';
		$addrvl3d->{_i1end}			= '';
		$addrvl3d->{_i2beg}			= '';
		$addrvl3d->{_i2end}			= '';
		$addrvl3d->{_i3beg}			= '';
		$addrvl3d->{_i3end}			= '';
		$addrvl3d->{_mode}			= '';
		$addrvl3d->{_n1}			= '';
		$addrvl3d->{_n2}			= '';
		$addrvl3d->{_n3}			= '';
		$addrvl3d->{_nrvl}			= '';
		$addrvl3d->{_nz}			= '';
		$addrvl3d->{_pdv}			= '';
		$addrvl3d->{_r1}			= '';
		$addrvl3d->{_r2}			= '';
		$addrvl3d->{_r3}			= '';
		$addrvl3d->{_seed}			= '';
		$addrvl3d->{_slowness}			= '';
		$addrvl3d->{_v}			= '';
		$addrvl3d->{_vlsd}			= '';
		$addrvl3d->{_Step}			= '';
		$addrvl3d->{_note}			= '';
 }


=head2 sub add 


=cut

 sub add {

	my ( $self,$add )		= @_;
	if ( $add ne $empty_string ) {

		$addrvl3d->{_add}		= $add;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' add='.$addrvl3d->{_add};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' add='.$addrvl3d->{_add};

	} else { 
		print("addrvl3d, add, missing add,\n");
	 }
 }


=head2 sub cvel 


=cut

 sub cvel {

	my ( $self,$cvel )		= @_;
	if ( $cvel ne $empty_string ) {

		$addrvl3d->{_cvel}		= $cvel;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' cvel='.$addrvl3d->{_cvel};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' cvel='.$addrvl3d->{_cvel};

	} else { 
		print("addrvl3d, cvel, missing cvel,\n");
	 }
 }


=head2 sub how 


=cut

 sub how {

	my ( $self,$how )		= @_;
	if ( $how ne $empty_string ) {

		$addrvl3d->{_how}		= $how;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' how='.$addrvl3d->{_how};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' how='.$addrvl3d->{_how};

	} else { 
		print("addrvl3d, how, missing how,\n");
	 }
 }


=head2 sub i1beg 


=cut

 sub i1beg {

	my ( $self,$i1beg )		= @_;
	if ( $i1beg ne $empty_string ) {

		$addrvl3d->{_i1beg}		= $i1beg;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' i1beg='.$addrvl3d->{_i1beg};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' i1beg='.$addrvl3d->{_i1beg};

	} else { 
		print("addrvl3d, i1beg, missing i1beg,\n");
	 }
 }


=head2 sub i1end 


=cut

 sub i1end {

	my ( $self,$i1end )		= @_;
	if ( $i1end ne $empty_string ) {

		$addrvl3d->{_i1end}		= $i1end;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' i1end='.$addrvl3d->{_i1end};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' i1end='.$addrvl3d->{_i1end};

	} else { 
		print("addrvl3d, i1end, missing i1end,\n");
	 }
 }


=head2 sub i2beg 


=cut

 sub i2beg {

	my ( $self,$i2beg )		= @_;
	if ( $i2beg ne $empty_string ) {

		$addrvl3d->{_i2beg}		= $i2beg;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' i2beg='.$addrvl3d->{_i2beg};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' i2beg='.$addrvl3d->{_i2beg};

	} else { 
		print("addrvl3d, i2beg, missing i2beg,\n");
	 }
 }


=head2 sub i2end 


=cut

 sub i2end {

	my ( $self,$i2end )		= @_;
	if ( $i2end ne $empty_string ) {

		$addrvl3d->{_i2end}		= $i2end;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' i2end='.$addrvl3d->{_i2end};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' i2end='.$addrvl3d->{_i2end};

	} else { 
		print("addrvl3d, i2end, missing i2end,\n");
	 }
 }


=head2 sub i3beg 


=cut

 sub i3beg {

	my ( $self,$i3beg )		= @_;
	if ( $i3beg ne $empty_string ) {

		$addrvl3d->{_i3beg}		= $i3beg;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' i3beg='.$addrvl3d->{_i3beg};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' i3beg='.$addrvl3d->{_i3beg};

	} else { 
		print("addrvl3d, i3beg, missing i3beg,\n");
	 }
 }


=head2 sub i3end 


=cut

 sub i3end {

	my ( $self,$i3end )		= @_;
	if ( $i3end ne $empty_string ) {

		$addrvl3d->{_i3end}		= $i3end;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' i3end='.$addrvl3d->{_i3end};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' i3end='.$addrvl3d->{_i3end};

	} else { 
		print("addrvl3d, i3end, missing i3end,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$addrvl3d->{_mode}		= $mode;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' mode='.$addrvl3d->{_mode};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' mode='.$addrvl3d->{_mode};

	} else { 
		print("addrvl3d, mode, missing mode,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$addrvl3d->{_n1}		= $n1;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' n1='.$addrvl3d->{_n1};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' n1='.$addrvl3d->{_n1};

	} else { 
		print("addrvl3d, n1, missing n1,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$addrvl3d->{_n2}		= $n2;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' n2='.$addrvl3d->{_n2};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' n2='.$addrvl3d->{_n2};

	} else { 
		print("addrvl3d, n2, missing n2,\n");
	 }
 }


=head2 sub n3 


=cut

 sub n3 {

	my ( $self,$n3 )		= @_;
	if ( $n3 ne $empty_string ) {

		$addrvl3d->{_n3}		= $n3;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' n3='.$addrvl3d->{_n3};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' n3='.$addrvl3d->{_n3};

	} else { 
		print("addrvl3d, n3, missing n3,\n");
	 }
 }


=head2 sub nrvl 


=cut

 sub nrvl {

	my ( $self,$nrvl )		= @_;
	if ( $nrvl ne $empty_string ) {

		$addrvl3d->{_nrvl}		= $nrvl;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' nrvl='.$addrvl3d->{_nrvl};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' nrvl='.$addrvl3d->{_nrvl};

	} else { 
		print("addrvl3d, nrvl, missing nrvl,\n");
	 }
 }


=head2 sub nz 


=cut

 sub nz {

	my ( $self,$nz )		= @_;
	if ( $nz ne $empty_string ) {

		$addrvl3d->{_nz}		= $nz;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' nz='.$addrvl3d->{_nz};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' nz='.$addrvl3d->{_nz};

	} else { 
		print("addrvl3d, nz, missing nz,\n");
	 }
 }


=head2 sub pdv 


=cut

 sub pdv {

	my ( $self,$pdv )		= @_;
	if ( $pdv ne $empty_string ) {

		$addrvl3d->{_pdv}		= $pdv;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' pdv='.$addrvl3d->{_pdv};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' pdv='.$addrvl3d->{_pdv};

	} else { 
		print("addrvl3d, pdv, missing pdv,\n");
	 }
 }


=head2 sub r1 


=cut

 sub r1 {

	my ( $self,$r1 )		= @_;
	if ( $r1 ne $empty_string ) {

		$addrvl3d->{_r1}		= $r1;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' r1='.$addrvl3d->{_r1};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' r1='.$addrvl3d->{_r1};

	} else { 
		print("addrvl3d, r1, missing r1,\n");
	 }
 }


=head2 sub r2 


=cut

 sub r2 {

	my ( $self,$r2 )		= @_;
	if ( $r2 ne $empty_string ) {

		$addrvl3d->{_r2}		= $r2;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' r2='.$addrvl3d->{_r2};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' r2='.$addrvl3d->{_r2};

	} else { 
		print("addrvl3d, r2, missing r2,\n");
	 }
 }


=head2 sub r3 


=cut

 sub r3 {

	my ( $self,$r3 )		= @_;
	if ( $r3 ne $empty_string ) {

		$addrvl3d->{_r3}		= $r3;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' r3='.$addrvl3d->{_r3};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' r3='.$addrvl3d->{_r3};

	} else { 
		print("addrvl3d, r3, missing r3,\n");
	 }
 }


=head2 sub seed 


=cut

 sub seed {

	my ( $self,$seed )		= @_;
	if ( $seed ne $empty_string ) {

		$addrvl3d->{_seed}		= $seed;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' seed='.$addrvl3d->{_seed};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' seed='.$addrvl3d->{_seed};

	} else { 
		print("addrvl3d, seed, missing seed,\n");
	 }
 }


=head2 sub slowness 


=cut

 sub slowness {

	my ( $self,$slowness )		= @_;
	if ( $slowness ne $empty_string ) {

		$addrvl3d->{_slowness}		= $slowness;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' slowness='.$addrvl3d->{_slowness};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' slowness='.$addrvl3d->{_slowness};

	} else { 
		print("addrvl3d, slowness, missing slowness,\n");
	 }
 }


=head2 sub v 


=cut

 sub v {

	my ( $self,$v )		= @_;
	if ( $v ne $empty_string ) {

		$addrvl3d->{_v}		= $v;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' v='.$addrvl3d->{_v};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' v='.$addrvl3d->{_v};

	} else { 
		print("addrvl3d, v, missing v,\n");
	 }
 }


=head2 sub vlsd 


=cut

 sub vlsd {

	my ( $self,$vlsd )		= @_;
	if ( $vlsd ne $empty_string ) {

		$addrvl3d->{_vlsd}		= $vlsd;
		$addrvl3d->{_note}		= $addrvl3d->{_note}.' vlsd='.$addrvl3d->{_vlsd};
		$addrvl3d->{_Step}		= $addrvl3d->{_Step}.' vlsd='.$addrvl3d->{_vlsd};

	} else { 
		print("addrvl3d, vlsd, missing vlsd,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 22;

    return($max_index);
}
 
 
1;
