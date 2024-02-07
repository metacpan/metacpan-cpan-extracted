package App::SeismicUnixGui::sunix::model::normray;

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
 NORMRAY - dynamic ray tracing for normal incidence rays in a sloth model



    normray <modelfile >rayends [optional parameters]			



 Optional Parameters:							

 caustic=	 0: show all rays 1: show only caustic rays		

 nonsurface=	 0: show rays which reach surface 1: show all rays      

 surface=	 0: shot ray from subsurface 1: from surface               

 nrays= 	 number of location to shoot rays                       

 dangle= 	 increment of ray angle for one location                

 nangle= 	 number of rays shot from one location                  

 ashift= 	 shift first taking off angle                           

 xs1= 	         x of shooting location                                 

 zs1= 	         z of shooting location                                 

 nangle=101     number of takeoff angles				

 fangle=-45     first takeoff angle (in degrees)			

 rayfile        file of ray x,z coordinates of ray-edge intersections	

 nxz=101        number of (x,z) in optional rayfile (see notes below)	

 wavefile=       file of ray x,z coordinates uniformly sampled in time	

 nt=101         number of (x,z) in optional wavefile (see notes below)	

 infofile=       ASCII-file to store useful information 		

 fresnelfile=    used if you want to plot the fresnel volumes. 		

                default is <fresnelfile.bin> 				

 outparfile=     contains parameters for the plotting software. 	

                default is <outpar> 					

 krecord=        if specified, only rays incident at interface with index

                krecord are displayed and stored			

 prim           =1, only single-reflected rays are plotted 		",     

                =0, only direct hits are displayed  			

 ffreq=-1       FresnelVolume frequency 				

 refseq=1,0,0   index of reflector followed by sequence of reflection (1)

                transmission(0) or ray stops(-1).			

                The default rayend is at the model boundary.		

                NOTE:refseq must be defined for each reflector		

 NOTES:								

 The rayends file contains ray parameters for the locations at which	

 the rays terminate.  							



 The rayfile is useful for making plots of ray paths.			

 nxz should be larger than twice the number of triangles intersected	

 by the rays.								



 The wavefile is useful for making plots of wavefronts.		

 The time sampling interval in the wavefile is tmax/(nt-1),		

 where tmax is the maximum time for all rays.				



 The infofile is useful for collecting information along the		

 individual rays. The fresnelfile contains data used to plot 		

 the Fresnel volumes. The outparfile stores information used 		

 for the plotting software.						







Author: Dave Hale, Colorado School of Mines, 02/16/91

 MODIFIED:  Andreas Rueger, Colorado School of Mines, 08/12/93

	Modifications include: functions writeFresnel, checkIfSourceIsOnEdge;

		options refseq=, krecord=, prim=, infofile=;

		computation of reflection/transmission losses, attenuation.

 MODIFIED: Boyi Ou, Colorado School of Mines, 4/14/95



 Notes:

 This code can shoot rays from specified interface by users, normally you

need to use gbmodel2 to generate interface parameters for this code, both

code have a parameter named nrays, it should be same. If you just want to

shoot rays from one specified location, you need to specify xs1,zs1,

otherwise, leave them alone. If you want to shoot rays from surface, you need

to define surface equal to 1. The rays from one location will be

approximately symmetric with direction Normal_direction - ashift.(if nangle is

odd, it is symmetric, even, almost symmetric. The formula for the first take

off angle is: angle=normal_direction-nangle/2*dangle-ashift. If you only want to

see caustics, you specify caustic=1, if you want to see rays which does not

reach surface, you specify nonsurface=1. 

/

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

my $normray			= {
	_angle					=> '',
	_ashift					=> '',
	_caustic					=> '',
	_dangle					=> '',
	_fangle					=> '',
	_ffreq					=> '',
	_fresnelfile					=> '',
	_infofile					=> '',
	_krecord					=> '',
	_nangle					=> '',
	_nonsurface					=> '',
	_nrays					=> '',
	_nt					=> '',
	_nxz					=> '',
	_outparfile					=> '',
	_prim					=> '',
	_refseq					=> '',
	_surface					=> '',
	_wavefile					=> '',
	_xs1					=> '',
	_zs1					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$normray->{_Step}     = 'normray'.$normray->{_Step};
	return ( $normray->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$normray->{_note}     = 'normray'.$normray->{_note};
	return ( $normray->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$normray->{_angle}			= '';
		$normray->{_ashift}			= '';
		$normray->{_caustic}			= '';
		$normray->{_dangle}			= '';
		$normray->{_fangle}			= '';
		$normray->{_ffreq}			= '';
		$normray->{_fresnelfile}			= '';
		$normray->{_infofile}			= '';
		$normray->{_krecord}			= '';
		$normray->{_nangle}			= '';
		$normray->{_nonsurface}			= '';
		$normray->{_nrays}			= '';
		$normray->{_nt}			= '';
		$normray->{_nxz}			= '';
		$normray->{_outparfile}			= '';
		$normray->{_prim}			= '';
		$normray->{_refseq}			= '';
		$normray->{_surface}			= '';
		$normray->{_wavefile}			= '';
		$normray->{_xs1}			= '';
		$normray->{_zs1}			= '';
		$normray->{_Step}			= '';
		$normray->{_note}			= '';
 }


=head2 sub angle 


=cut

 sub angle {

	my ( $self,$angle )		= @_;
	if ( $angle ne $empty_string ) {

		$normray->{_angle}		= $angle;
		$normray->{_note}		= $normray->{_note}.' angle='.$normray->{_angle};
		$normray->{_Step}		= $normray->{_Step}.' angle='.$normray->{_angle};

	} else { 
		print("normray, angle, missing angle,\n");
	 }
 }


=head2 sub ashift 


=cut

 sub ashift {

	my ( $self,$ashift )		= @_;
	if ( $ashift ne $empty_string ) {

		$normray->{_ashift}		= $ashift;
		$normray->{_note}		= $normray->{_note}.' ashift='.$normray->{_ashift};
		$normray->{_Step}		= $normray->{_Step}.' ashift='.$normray->{_ashift};

	} else { 
		print("normray, ashift, missing ashift,\n");
	 }
 }


=head2 sub caustic 


=cut

 sub caustic {

	my ( $self,$caustic )		= @_;
	if ( $caustic ne $empty_string ) {

		$normray->{_caustic}		= $caustic;
		$normray->{_note}		= $normray->{_note}.' caustic='.$normray->{_caustic};
		$normray->{_Step}		= $normray->{_Step}.' caustic='.$normray->{_caustic};

	} else { 
		print("normray, caustic, missing caustic,\n");
	 }
 }


=head2 sub dangle 


=cut

 sub dangle {

	my ( $self,$dangle )		= @_;
	if ( $dangle ne $empty_string ) {

		$normray->{_dangle}		= $dangle;
		$normray->{_note}		= $normray->{_note}.' dangle='.$normray->{_dangle};
		$normray->{_Step}		= $normray->{_Step}.' dangle='.$normray->{_dangle};

	} else { 
		print("normray, dangle, missing dangle,\n");
	 }
 }


=head2 sub fangle 


=cut

 sub fangle {

	my ( $self,$fangle )		= @_;
	if ( $fangle ne $empty_string ) {

		$normray->{_fangle}		= $fangle;
		$normray->{_note}		= $normray->{_note}.' fangle='.$normray->{_fangle};
		$normray->{_Step}		= $normray->{_Step}.' fangle='.$normray->{_fangle};

	} else { 
		print("normray, fangle, missing fangle,\n");
	 }
 }


=head2 sub ffreq 


=cut

 sub ffreq {

	my ( $self,$ffreq )		= @_;
	if ( $ffreq ne $empty_string ) {

		$normray->{_ffreq}		= $ffreq;
		$normray->{_note}		= $normray->{_note}.' ffreq='.$normray->{_ffreq};
		$normray->{_Step}		= $normray->{_Step}.' ffreq='.$normray->{_ffreq};

	} else { 
		print("normray, ffreq, missing ffreq,\n");
	 }
 }


=head2 sub fresnelfile 


=cut

 sub fresnelfile {

	my ( $self,$fresnelfile )		= @_;
	if ( $fresnelfile ne $empty_string ) {

		$normray->{_fresnelfile}		= $fresnelfile;
		$normray->{_note}		= $normray->{_note}.' fresnelfile='.$normray->{_fresnelfile};
		$normray->{_Step}		= $normray->{_Step}.' fresnelfile='.$normray->{_fresnelfile};

	} else { 
		print("normray, fresnelfile, missing fresnelfile,\n");
	 }
 }


=head2 sub infofile 


=cut

 sub infofile {

	my ( $self,$infofile )		= @_;
	if ( $infofile ne $empty_string ) {

		$normray->{_infofile}		= $infofile;
		$normray->{_note}		= $normray->{_note}.' infofile='.$normray->{_infofile};
		$normray->{_Step}		= $normray->{_Step}.' infofile='.$normray->{_infofile};

	} else { 
		print("normray, infofile, missing infofile,\n");
	 }
 }


=head2 sub krecord 


=cut

 sub krecord {

	my ( $self,$krecord )		= @_;
	if ( $krecord ne $empty_string ) {

		$normray->{_krecord}		= $krecord;
		$normray->{_note}		= $normray->{_note}.' krecord='.$normray->{_krecord};
		$normray->{_Step}		= $normray->{_Step}.' krecord='.$normray->{_krecord};

	} else { 
		print("normray, krecord, missing krecord,\n");
	 }
 }


=head2 sub nangle 


=cut

 sub nangle {

	my ( $self,$nangle )		= @_;
	if ( $nangle ne $empty_string ) {

		$normray->{_nangle}		= $nangle;
		$normray->{_note}		= $normray->{_note}.' nangle='.$normray->{_nangle};
		$normray->{_Step}		= $normray->{_Step}.' nangle='.$normray->{_nangle};

	} else { 
		print("normray, nangle, missing nangle,\n");
	 }
 }


=head2 sub nonsurface 


=cut

 sub nonsurface {

	my ( $self,$nonsurface )		= @_;
	if ( $nonsurface ne $empty_string ) {

		$normray->{_nonsurface}		= $nonsurface;
		$normray->{_note}		= $normray->{_note}.' nonsurface='.$normray->{_nonsurface};
		$normray->{_Step}		= $normray->{_Step}.' nonsurface='.$normray->{_nonsurface};

	} else { 
		print("normray, nonsurface, missing nonsurface,\n");
	 }
 }


=head2 sub nrays 


=cut

 sub nrays {

	my ( $self,$nrays )		= @_;
	if ( $nrays ne $empty_string ) {

		$normray->{_nrays}		= $nrays;
		$normray->{_note}		= $normray->{_note}.' nrays='.$normray->{_nrays};
		$normray->{_Step}		= $normray->{_Step}.' nrays='.$normray->{_nrays};

	} else { 
		print("normray, nrays, missing nrays,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$normray->{_nt}		= $nt;
		$normray->{_note}		= $normray->{_note}.' nt='.$normray->{_nt};
		$normray->{_Step}		= $normray->{_Step}.' nt='.$normray->{_nt};

	} else { 
		print("normray, nt, missing nt,\n");
	 }
 }


=head2 sub nxz 


=cut

 sub nxz {

	my ( $self,$nxz )		= @_;
	if ( $nxz ne $empty_string ) {

		$normray->{_nxz}		= $nxz;
		$normray->{_note}		= $normray->{_note}.' nxz='.$normray->{_nxz};
		$normray->{_Step}		= $normray->{_Step}.' nxz='.$normray->{_nxz};

	} else { 
		print("normray, nxz, missing nxz,\n");
	 }
 }


=head2 sub outparfile 


=cut

 sub outparfile {

	my ( $self,$outparfile )		= @_;
	if ( $outparfile ne $empty_string ) {

		$normray->{_outparfile}		= $outparfile;
		$normray->{_note}		= $normray->{_note}.' outparfile='.$normray->{_outparfile};
		$normray->{_Step}		= $normray->{_Step}.' outparfile='.$normray->{_outparfile};

	} else { 
		print("normray, outparfile, missing outparfile,\n");
	 }
 }


=head2 sub prim 


=cut

 sub prim {

	my ( $self,$prim )		= @_;
	if ( $prim ne $empty_string ) {

		$normray->{_prim}		= $prim;
		$normray->{_note}		= $normray->{_note}.' prim='.$normray->{_prim};
		$normray->{_Step}		= $normray->{_Step}.' prim='.$normray->{_prim};

	} else { 
		print("normray, prim, missing prim,\n");
	 }
 }


=head2 sub refseq 


=cut

 sub refseq {

	my ( $self,$refseq )		= @_;
	if ( $refseq ne $empty_string ) {

		$normray->{_refseq}		= $refseq;
		$normray->{_note}		= $normray->{_note}.' refseq='.$normray->{_refseq};
		$normray->{_Step}		= $normray->{_Step}.' refseq='.$normray->{_refseq};

	} else { 
		print("normray, refseq, missing refseq,\n");
	 }
 }


=head2 sub surface 


=cut

 sub surface {

	my ( $self,$surface )		= @_;
	if ( $surface ne $empty_string ) {

		$normray->{_surface}		= $surface;
		$normray->{_note}		= $normray->{_note}.' surface='.$normray->{_surface};
		$normray->{_Step}		= $normray->{_Step}.' surface='.$normray->{_surface};

	} else { 
		print("normray, surface, missing surface,\n");
	 }
 }


=head2 sub wavefile 


=cut

 sub wavefile {

	my ( $self,$wavefile )		= @_;
	if ( $wavefile ne $empty_string ) {

		$normray->{_wavefile}		= $wavefile;
		$normray->{_note}		= $normray->{_note}.' wavefile='.$normray->{_wavefile};
		$normray->{_Step}		= $normray->{_Step}.' wavefile='.$normray->{_wavefile};

	} else { 
		print("normray, wavefile, missing wavefile,\n");
	 }
 }


=head2 sub xs1 


=cut

 sub xs1 {

	my ( $self,$xs1 )		= @_;
	if ( $xs1 ne $empty_string ) {

		$normray->{_xs1}		= $xs1;
		$normray->{_note}		= $normray->{_note}.' xs1='.$normray->{_xs1};
		$normray->{_Step}		= $normray->{_Step}.' xs1='.$normray->{_xs1};

	} else { 
		print("normray, xs1, missing xs1,\n");
	 }
 }


=head2 sub zs1 


=cut

 sub zs1 {

	my ( $self,$zs1 )		= @_;
	if ( $zs1 ne $empty_string ) {

		$normray->{_zs1}		= $zs1;
		$normray->{_note}		= $normray->{_note}.' zs1='.$normray->{_zs1};
		$normray->{_Step}		= $normray->{_Step}.' zs1='.$normray->{_zs1};

	} else { 
		print("normray, zs1, missing zs1,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 20;

    return($max_index);
}
 
 
1;
