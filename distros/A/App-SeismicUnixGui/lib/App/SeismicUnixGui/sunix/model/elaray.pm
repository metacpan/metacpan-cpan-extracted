package App::SeismicUnixGui::sunix::model::elaray;

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
 ELARAY - ray tracing for elastic anisotropic models



 elaray <modelfile >rayends [optional parameters]			



 Optional Parameters:							

 xs=(max-min)/2 x coordinate of source (default is halfway across model)

 zs=min         z coordinate of source (default is at top of model)	

 nangle=101     number of takeoff angles				

 fangle=-45     first takeoff angle (in degrees)			

 langle=45      last takeoff angle (in degrees)			

 nxz=101        number of (x,z) in optional rayfile (see notes below)	

 mode=0         shoot P-rays						

	      =1 shoot SV-rays						

	      =2 shoot SH-rays						

 prim        =1 only reflected rays are plotted 		",     

             =0 only direct hits are displayed  			

 refseq=1,0,0   index of reflector followed by sequence of:		

		 transmission(0)					

		 reflection (1)						

		 transmission with mode conversion (2)			",					

		 reflection with mode conversion (3)			",					

                ray stops(-1).						

 krecord        if specified, only rays incident at interface with index

                krecord are displayed and stored			

 f0=1	         force impact strenght					

 fdip=0         force dip with respect to vertical			

 fazi=0         force azimuth with respect to positive x-axis 		

 reftrans=0	 =1 include reflec/transm coeff(currently only for P)	

 rayfile        file of ray x,z coordinates of ray-edge intersections	

 wavefile       file of ray x,z coordinates uniformly sampled in time	

 nt=		 number of (x,z) in optional wavefile (see notes below)	

 tw=		 traveltime associated with wavefront (alternative to nt)",	

 infofile       ASCII-file to store useful information 		

 outparfile     contains parameters for the plotting software. 	

                default is <outpar> 					

 NOTES:								

 The rayends file contains ray parameters for the locations at which	

 the rays terminate.  							



 The rayfile is useful for making plots of ray paths.			

 nxz should be larger than twice the number of triangles intersected	

 by the rays.								



 The wavefile is useful for making plots of wavefronts.		

 The time sampling interval in the wavefile is tmax/(nt-1),		

 where tmax is the maximum time for all rays. Alternatively, 

 one wavefront at time tw is plotted.	



 The infofile is useful for collecting information along the		

 individual rays. 							

 The outparfile stores information used for the plotting software	







 AUTHORS:  Andreas Rueger, Colorado School of Mines, 01/02/95

  The program is based on :

 	        gbray.c, AUTHOR: Andreas Rueger, 08/12/93

 	       	sdray.c, AUTHOR Dave Hale, CSM, 02/26/91



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

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $elaray			= {
	_f0					=> '',
	_fangle					=> '',
	_fazi					=> '',
	_fdip					=> '',
	_langle					=> '',
	_mode					=> '',
	_nangle					=> '',
	_nt					=> '',
	_nxz					=> '',
	_prim					=> '',
	_refseq					=> '',
	_reftrans					=> '',
	_tw					=> '',
	_xs					=> '',
	_zs					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$elaray->{_Step}     = 'elaray'.$elaray->{_Step};
	return ( $elaray->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$elaray->{_note}     = 'elaray'.$elaray->{_note};
	return ( $elaray->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$elaray->{_f0}			= '';
		$elaray->{_fangle}			= '';
		$elaray->{_fazi}			= '';
		$elaray->{_fdip}			= '';
		$elaray->{_langle}			= '';
		$elaray->{_mode}			= '';
		$elaray->{_nangle}			= '';
		$elaray->{_nt}			= '';
		$elaray->{_nxz}			= '';
		$elaray->{_prim}			= '';
		$elaray->{_refseq}			= '';
		$elaray->{_reftrans}			= '';
		$elaray->{_tw}			= '';
		$elaray->{_xs}			= '';
		$elaray->{_zs}			= '';
		$elaray->{_Step}			= '';
		$elaray->{_note}			= '';
 }


=head2 sub f0 


=cut

 sub f0 {

	my ( $self,$f0 )		= @_;
	if ( $f0 ne $empty_string ) {

		$elaray->{_f0}		= $f0;
		$elaray->{_note}		= $elaray->{_note}.' f0='.$elaray->{_f0};
		$elaray->{_Step}		= $elaray->{_Step}.' f0='.$elaray->{_f0};

	} else { 
		print("elaray, f0, missing f0,\n");
	 }
 }


=head2 sub fangle 


=cut

 sub fangle {

	my ( $self,$fangle )		= @_;
	if ( $fangle ne $empty_string ) {

		$elaray->{_fangle}		= $fangle;
		$elaray->{_note}		= $elaray->{_note}.' fangle='.$elaray->{_fangle};
		$elaray->{_Step}		= $elaray->{_Step}.' fangle='.$elaray->{_fangle};

	} else { 
		print("elaray, fangle, missing fangle,\n");
	 }
 }


=head2 sub fazi 


=cut

 sub fazi {

	my ( $self,$fazi )		= @_;
	if ( $fazi ne $empty_string ) {

		$elaray->{_fazi}		= $fazi;
		$elaray->{_note}		= $elaray->{_note}.' fazi='.$elaray->{_fazi};
		$elaray->{_Step}		= $elaray->{_Step}.' fazi='.$elaray->{_fazi};

	} else { 
		print("elaray, fazi, missing fazi,\n");
	 }
 }


=head2 sub fdip 


=cut

 sub fdip {

	my ( $self,$fdip )		= @_;
	if ( $fdip ne $empty_string ) {

		$elaray->{_fdip}		= $fdip;
		$elaray->{_note}		= $elaray->{_note}.' fdip='.$elaray->{_fdip};
		$elaray->{_Step}		= $elaray->{_Step}.' fdip='.$elaray->{_fdip};

	} else { 
		print("elaray, fdip, missing fdip,\n");
	 }
 }


=head2 sub langle 


=cut

 sub langle {

	my ( $self,$langle )		= @_;
	if ( $langle ne $empty_string ) {

		$elaray->{_langle}		= $langle;
		$elaray->{_note}		= $elaray->{_note}.' langle='.$elaray->{_langle};
		$elaray->{_Step}		= $elaray->{_Step}.' langle='.$elaray->{_langle};

	} else { 
		print("elaray, langle, missing langle,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$elaray->{_mode}		= $mode;
		$elaray->{_note}		= $elaray->{_note}.' mode='.$elaray->{_mode};
		$elaray->{_Step}		= $elaray->{_Step}.' mode='.$elaray->{_mode};

	} else { 
		print("elaray, mode, missing mode,\n");
	 }
 }


=head2 sub nangle 


=cut

 sub nangle {

	my ( $self,$nangle )		= @_;
	if ( $nangle ne $empty_string ) {

		$elaray->{_nangle}		= $nangle;
		$elaray->{_note}		= $elaray->{_note}.' nangle='.$elaray->{_nangle};
		$elaray->{_Step}		= $elaray->{_Step}.' nangle='.$elaray->{_nangle};

	} else { 
		print("elaray, nangle, missing nangle,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$elaray->{_nt}		= $nt;
		$elaray->{_note}		= $elaray->{_note}.' nt='.$elaray->{_nt};
		$elaray->{_Step}		= $elaray->{_Step}.' nt='.$elaray->{_nt};

	} else { 
		print("elaray, nt, missing nt,\n");
	 }
 }


=head2 sub nxz 


=cut

 sub nxz {

	my ( $self,$nxz )		= @_;
	if ( $nxz ne $empty_string ) {

		$elaray->{_nxz}		= $nxz;
		$elaray->{_note}		= $elaray->{_note}.' nxz='.$elaray->{_nxz};
		$elaray->{_Step}		= $elaray->{_Step}.' nxz='.$elaray->{_nxz};

	} else { 
		print("elaray, nxz, missing nxz,\n");
	 }
 }


=head2 sub prim 


=cut

 sub prim {

	my ( $self,$prim )		= @_;
	if ( $prim ne $empty_string ) {

		$elaray->{_prim}		= $prim;
		$elaray->{_note}		= $elaray->{_note}.' prim='.$elaray->{_prim};
		$elaray->{_Step}		= $elaray->{_Step}.' prim='.$elaray->{_prim};

	} else { 
		print("elaray, prim, missing prim,\n");
	 }
 }


=head2 sub refseq 


=cut

 sub refseq {

	my ( $self,$refseq )		= @_;
	if ( $refseq ne $empty_string ) {

		$elaray->{_refseq}		= $refseq;
		$elaray->{_note}		= $elaray->{_note}.' refseq='.$elaray->{_refseq};
		$elaray->{_Step}		= $elaray->{_Step}.' refseq='.$elaray->{_refseq};

	} else { 
		print("elaray, refseq, missing refseq,\n");
	 }
 }


=head2 sub reftrans 


=cut

 sub reftrans {

	my ( $self,$reftrans )		= @_;
	if ( $reftrans ne $empty_string ) {

		$elaray->{_reftrans}		= $reftrans;
		$elaray->{_note}		= $elaray->{_note}.' reftrans='.$elaray->{_reftrans};
		$elaray->{_Step}		= $elaray->{_Step}.' reftrans='.$elaray->{_reftrans};

	} else { 
		print("elaray, reftrans, missing reftrans,\n");
	 }
 }


=head2 sub tw 


=cut

 sub tw {

	my ( $self,$tw )		= @_;
	if ( $tw ne $empty_string ) {

		$elaray->{_tw}		= $tw;
		$elaray->{_note}		= $elaray->{_note}.' tw='.$elaray->{_tw};
		$elaray->{_Step}		= $elaray->{_Step}.' tw='.$elaray->{_tw};

	} else { 
		print("elaray, tw, missing tw,\n");
	 }
 }


=head2 sub xs 


=cut

 sub xs {

	my ( $self,$xs )		= @_;
	if ( $xs ne $empty_string ) {

		$elaray->{_xs}		= $xs;
		$elaray->{_note}		= $elaray->{_note}.' xs='.$elaray->{_xs};
		$elaray->{_Step}		= $elaray->{_Step}.' xs='.$elaray->{_xs};

	} else { 
		print("elaray, xs, missing xs,\n");
	 }
 }


=head2 sub zs 


=cut

 sub zs {

	my ( $self,$zs )		= @_;
	if ( $zs ne $empty_string ) {

		$elaray->{_zs}		= $zs;
		$elaray->{_note}		= $elaray->{_note}.' zs='.$elaray->{_zs};
		$elaray->{_Step}		= $elaray->{_Step}.' zs='.$elaray->{_zs};

	} else { 
		print("elaray, zs, missing zs,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 14;

    return($max_index);
}
 
 
1;
