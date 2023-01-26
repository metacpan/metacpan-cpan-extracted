package App::SeismicUnixGui::sunix::NMO_Vel_Stk::suvelan_nsel;

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
 SUVELAN_NSEL - compute stacking VELocity panel for cdp gathers	     

		using the Normalized Selective CrossCorrelation sum	     



 suvelan_usel <stdin >stdout [optional parameters]			     



 Optional Parameters:							     

 nx=tr.cdpt              number of traces in cdp			     

 dx=tr.d2 	          offset increment				     

 nv=50                   number of velocities				     

 dv=100.0                velocity sampling interval			     

 fv=1500.0               first velocity				     

 tau=0.5                 threshold for significance values                  

 smute=1.5               samples with NMO stretch exceeding smute are zeroed

 dtratio=5               ratio of output to input time sampling intervals   

 nsmooth=dtratio*2+1     length of smoothing window                         

 verbose=0               =1 for diagnostic print on stderr		     

 pwr=1.0                 semblance value to the power      		     



 Notes:								     

 Normalized Selective CrossCorrelation Sum: is based on the coherence       

 measure known as crosscorrelation sum. The difference is that the selective

 approach sum only crosscorrelation pairs with relatively large differential

 moveout, thus increasing the resolving power in the velocity spectra       

 compared to that achieved by conventional methods. The normalization is    

 achieved in much the same way of normalizing the conventional              

 crosscorrelation sum.						             



 Each crosscorrelation is divided by the geometric mean		     

 of the energy of the traces involved, and the multiplying by a constant to 

 achieve maximum amplitude of unity. The constant is just the inverse of the

 total number of crosscorrelations included in the sum.  The selection is   

 made using a parabolic approximation of the differential moveout and       

 imposing a threshold for those differential moveouts.		   	     



 That threshold is the parameter tau in this program, which varies between 0

 to 1.	 A value of tau=0, means conventional crosscorrelation sum is applied

 implying that all crosscorrelations are included in the sum. In contrast,  

 a value of tau=1 (not recomended) means that only the crosscorrelation     

 formed by the trace pair involving the shortest and longest offset is      

 included in the sum. Intermediate values will produce percentages of the   

 crosscorrelations included in the sum that will be shown in the screen     

 before computing the velocity spectra. Typical values for tau are between  

 0.2 and 0.6, producing approximated percentages of crosscorrelations summed

 between 60 0x0p+0nd 20%. The higher the value of tau the lower the percentage

 and higher the increase in the resolving power of velocity spectra.        



 Keeping the percentage of crosscorrelations included in the sum between 20%

 and 60% will increase resolution and avoid the precense of artifacts in   

 the results.  In data contaminated by random noise or statics distortions   

 is recomended to mantaing the percentage of crosscorrelations included in   

 the sum above 25%. After computing the velocity spectra one might want to  

 adjust the level  and number of contours before velocity picking.	      



 

 Credits: CWP:  Valmore Celis, Sept 2002	

 

 Based on the original code: suvelan.c 

    Colorado School of Mines:  Dave Hale c. 1989



 References: 

 Neidell, N.S., and Taner, M.T., 1971, Semblance and other 

   coherency measures for multichannel data: Geophysics, 36, 498-509.

 Celis, V. T., 2002, Selective-correlation velocity analysis: CSM thesis.





 Trace header fields accessed:  ns, dt, delrt, offset, cdp

 Trace header fields modified:  ns, dt, offset, cdp



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

my $suvelan_nsel			= {
	_dtratio					=> '',
	_dv					=> '',
	_dx					=> '',
	_fv					=> '',
	_nsmooth					=> '',
	_nv					=> '',
	_nx					=> '',
	_pwr					=> '',
	_smute					=> '',
	_tau					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suvelan_nsel->{_Step}     = 'suvelan_nsel'.$suvelan_nsel->{_Step};
	return ( $suvelan_nsel->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suvelan_nsel->{_note}     = 'suvelan_nsel'.$suvelan_nsel->{_note};
	return ( $suvelan_nsel->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suvelan_nsel->{_dtratio}			= '';
		$suvelan_nsel->{_dv}			= '';
		$suvelan_nsel->{_dx}			= '';
		$suvelan_nsel->{_fv}			= '';
		$suvelan_nsel->{_nsmooth}			= '';
		$suvelan_nsel->{_nv}			= '';
		$suvelan_nsel->{_nx}			= '';
		$suvelan_nsel->{_pwr}			= '';
		$suvelan_nsel->{_smute}			= '';
		$suvelan_nsel->{_tau}			= '';
		$suvelan_nsel->{_verbose}			= '';
		$suvelan_nsel->{_Step}			= '';
		$suvelan_nsel->{_note}			= '';
 }


=head2 sub dtratio 


=cut

 sub dtratio {

	my ( $self,$dtratio )		= @_;
	if ( $dtratio ne $empty_string ) {

		$suvelan_nsel->{_dtratio}		= $dtratio;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' dtratio='.$suvelan_nsel->{_dtratio};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' dtratio='.$suvelan_nsel->{_dtratio};

	} else { 
		print("suvelan_nsel, dtratio, missing dtratio,\n");
	 }
 }


=head2 sub dv 


=cut

 sub dv {

	my ( $self,$dv )		= @_;
	if ( $dv ne $empty_string ) {

		$suvelan_nsel->{_dv}		= $dv;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' dv='.$suvelan_nsel->{_dv};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' dv='.$suvelan_nsel->{_dv};

	} else { 
		print("suvelan_nsel, dv, missing dv,\n");
	 }
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$suvelan_nsel->{_dx}		= $dx;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' dx='.$suvelan_nsel->{_dx};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' dx='.$suvelan_nsel->{_dx};

	} else { 
		print("suvelan_nsel, dx, missing dx,\n");
	 }
 }


=head2 sub fv 


=cut

 sub fv {

	my ( $self,$fv )		= @_;
	if ( $fv ne $empty_string ) {

		$suvelan_nsel->{_fv}		= $fv;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' fv='.$suvelan_nsel->{_fv};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' fv='.$suvelan_nsel->{_fv};

	} else { 
		print("suvelan_nsel, fv, missing fv,\n");
	 }
 }


=head2 sub nsmooth 


=cut

 sub nsmooth {

	my ( $self,$nsmooth )		= @_;
	if ( $nsmooth ne $empty_string ) {

		$suvelan_nsel->{_nsmooth}		= $nsmooth;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' nsmooth='.$suvelan_nsel->{_nsmooth};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' nsmooth='.$suvelan_nsel->{_nsmooth};

	} else { 
		print("suvelan_nsel, nsmooth, missing nsmooth,\n");
	 }
 }


=head2 sub nv 


=cut

 sub nv {

	my ( $self,$nv )		= @_;
	if ( $nv ne $empty_string ) {

		$suvelan_nsel->{_nv}		= $nv;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' nv='.$suvelan_nsel->{_nv};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' nv='.$suvelan_nsel->{_nv};

	} else { 
		print("suvelan_nsel, nv, missing nv,\n");
	 }
 }


=head2 sub nx 


=cut

 sub nx {

	my ( $self,$nx )		= @_;
	if ( $nx ne $empty_string ) {

		$suvelan_nsel->{_nx}		= $nx;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' nx='.$suvelan_nsel->{_nx};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' nx='.$suvelan_nsel->{_nx};

	} else { 
		print("suvelan_nsel, nx, missing nx,\n");
	 }
 }


=head2 sub pwr 


=cut

 sub pwr {

	my ( $self,$pwr )		= @_;
	if ( $pwr ne $empty_string ) {

		$suvelan_nsel->{_pwr}		= $pwr;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' pwr='.$suvelan_nsel->{_pwr};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' pwr='.$suvelan_nsel->{_pwr};

	} else { 
		print("suvelan_nsel, pwr, missing pwr,\n");
	 }
 }


=head2 sub smute 


=cut

 sub smute {

	my ( $self,$smute )		= @_;
	if ( $smute ne $empty_string ) {

		$suvelan_nsel->{_smute}		= $smute;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' smute='.$suvelan_nsel->{_smute};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' smute='.$suvelan_nsel->{_smute};

	} else { 
		print("suvelan_nsel, smute, missing smute,\n");
	 }
 }


=head2 sub tau 


=cut

 sub tau {

	my ( $self,$tau )		= @_;
	if ( $tau ne $empty_string ) {

		$suvelan_nsel->{_tau}		= $tau;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' tau='.$suvelan_nsel->{_tau};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' tau='.$suvelan_nsel->{_tau};

	} else { 
		print("suvelan_nsel, tau, missing tau,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suvelan_nsel->{_verbose}		= $verbose;
		$suvelan_nsel->{_note}		= $suvelan_nsel->{_note}.' verbose='.$suvelan_nsel->{_verbose};
		$suvelan_nsel->{_Step}		= $suvelan_nsel->{_Step}.' verbose='.$suvelan_nsel->{_verbose};

	} else { 
		print("suvelan_nsel, verbose, missing verbose,\n");
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
