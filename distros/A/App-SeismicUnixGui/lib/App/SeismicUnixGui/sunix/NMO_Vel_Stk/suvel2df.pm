package App::SeismicUnixGui::sunix::NMO_Vel_Stk::suvel2df;

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
 SUVEL2DF - compute stacking VELocity semblance for a single time in   

			    over Vnmo and eta in 2-D			



    suvel2df <stdin >stdout [optional parameters]			



 Required Parameters:							

 tn			zero-offset time of reflection			

 offsetm		Maximum offset considered			



 Optional Parameters:							

 nv=50			number of velocities				

 dv=50.0		velocity sampling interval			

 fv=1500.0		first velocity					

 nvh=50		number of horizontal velocities			

 dvh=50.0		horizontal velocity sampling interval		

 fvh=1500.0		first horizontal velocity			

 xod=1.5		maximum offset-to-depth ratio to resolve	

 dtratio=5		ratio of output to input time sampling intervals

 nsmooth=dtratio*2+1	length of semblance num and den smoothing window

 verbose=0		=1 for diagnostic print on stderr		

 vavg=fv+0.5*(nv-1)*dv   average velocity used in the search		



 Notes:								

 Semblance is defined by the following quotient:			



		 n-1		 					

		[ sum q(t,j) ]^2					

		 j=0		 					

	s(t) = ------------------					

		 n-1		 					

		n sum [q(t,j)]^2					

		 j=0		 					



 where n is the number of non-zero samples after muting.		

 Smoothing (nsmooth) is applied separately to the numerator and denominator

 before computing this semblance quotient.				



 Input traces should be sorted by cdp - suvel2df outputs a group of	

 semblance traces every time cdp changes.  Therefore, the output will	

 be useful only if cdp gathers are input.				





 Credits:

	CWP: Tariq Alkhalifah,  February 1997

 Trace header fields accessed:  ns, dt, delrt, offset, cdp.

 Trace header fields modified:  ns, dt, offset.



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

my $suvel2df			= {
	_dtratio					=> '',
	_dv					=> '',
	_dvh					=> '',
	_fv					=> '',
	_fvh					=> '',
	_j					=> '',
	_nsmooth					=> '',
	_nv					=> '',
	_nvh					=> '',
	_vavg					=> '',
	_verbose					=> '',
	_xod					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suvel2df->{_Step}     = 'suvel2df'.$suvel2df->{_Step};
	return ( $suvel2df->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suvel2df->{_note}     = 'suvel2df'.$suvel2df->{_note};
	return ( $suvel2df->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suvel2df->{_dtratio}			= '';
		$suvel2df->{_dv}			= '';
		$suvel2df->{_dvh}			= '';
		$suvel2df->{_fv}			= '';
		$suvel2df->{_fvh}			= '';
		$suvel2df->{_j}			= '';
		$suvel2df->{_nsmooth}			= '';
		$suvel2df->{_nv}			= '';
		$suvel2df->{_nvh}			= '';
		$suvel2df->{_vavg}			= '';
		$suvel2df->{_verbose}			= '';
		$suvel2df->{_xod}			= '';
		$suvel2df->{_Step}			= '';
		$suvel2df->{_note}			= '';
 }


=head2 sub dtratio 


=cut

 sub dtratio {

	my ( $self,$dtratio )		= @_;
	if ( $dtratio ne $empty_string ) {

		$suvel2df->{_dtratio}		= $dtratio;
		$suvel2df->{_note}		= $suvel2df->{_note}.' dtratio='.$suvel2df->{_dtratio};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' dtratio='.$suvel2df->{_dtratio};

	} else { 
		print("suvel2df, dtratio, missing dtratio,\n");
	 }
 }


=head2 sub dv 


=cut

 sub dv {

	my ( $self,$dv )		= @_;
	if ( $dv ne $empty_string ) {

		$suvel2df->{_dv}		= $dv;
		$suvel2df->{_note}		= $suvel2df->{_note}.' dv='.$suvel2df->{_dv};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' dv='.$suvel2df->{_dv};

	} else { 
		print("suvel2df, dv, missing dv,\n");
	 }
 }


=head2 sub dvh 


=cut

 sub dvh {

	my ( $self,$dvh )		= @_;
	if ( $dvh ne $empty_string ) {

		$suvel2df->{_dvh}		= $dvh;
		$suvel2df->{_note}		= $suvel2df->{_note}.' dvh='.$suvel2df->{_dvh};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' dvh='.$suvel2df->{_dvh};

	} else { 
		print("suvel2df, dvh, missing dvh,\n");
	 }
 }


=head2 sub fv 


=cut

 sub fv {

	my ( $self,$fv )		= @_;
	if ( $fv ne $empty_string ) {

		$suvel2df->{_fv}		= $fv;
		$suvel2df->{_note}		= $suvel2df->{_note}.' fv='.$suvel2df->{_fv};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' fv='.$suvel2df->{_fv};

	} else { 
		print("suvel2df, fv, missing fv,\n");
	 }
 }


=head2 sub fvh 


=cut

 sub fvh {

	my ( $self,$fvh )		= @_;
	if ( $fvh ne $empty_string ) {

		$suvel2df->{_fvh}		= $fvh;
		$suvel2df->{_note}		= $suvel2df->{_note}.' fvh='.$suvel2df->{_fvh};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' fvh='.$suvel2df->{_fvh};

	} else { 
		print("suvel2df, fvh, missing fvh,\n");
	 }
 }


=head2 sub j 


=cut

 sub j {

	my ( $self,$j )		= @_;
	if ( $j ne $empty_string ) {

		$suvel2df->{_j}		= $j;
		$suvel2df->{_note}		= $suvel2df->{_note}.' j='.$suvel2df->{_j};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' j='.$suvel2df->{_j};

	} else { 
		print("suvel2df, j, missing j,\n");
	 }
 }


=head2 sub nsmooth 


=cut

 sub nsmooth {

	my ( $self,$nsmooth )		= @_;
	if ( $nsmooth ne $empty_string ) {

		$suvel2df->{_nsmooth}		= $nsmooth;
		$suvel2df->{_note}		= $suvel2df->{_note}.' nsmooth='.$suvel2df->{_nsmooth};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' nsmooth='.$suvel2df->{_nsmooth};

	} else { 
		print("suvel2df, nsmooth, missing nsmooth,\n");
	 }
 }


=head2 sub nv 


=cut

 sub nv {

	my ( $self,$nv )		= @_;
	if ( $nv ne $empty_string ) {

		$suvel2df->{_nv}		= $nv;
		$suvel2df->{_note}		= $suvel2df->{_note}.' nv='.$suvel2df->{_nv};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' nv='.$suvel2df->{_nv};

	} else { 
		print("suvel2df, nv, missing nv,\n");
	 }
 }


=head2 sub nvh 


=cut

 sub nvh {

	my ( $self,$nvh )		= @_;
	if ( $nvh ne $empty_string ) {

		$suvel2df->{_nvh}		= $nvh;
		$suvel2df->{_note}		= $suvel2df->{_note}.' nvh='.$suvel2df->{_nvh};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' nvh='.$suvel2df->{_nvh};

	} else { 
		print("suvel2df, nvh, missing nvh,\n");
	 }
 }


=head2 sub vavg 


=cut

 sub vavg {

	my ( $self,$vavg )		= @_;
	if ( $vavg ne $empty_string ) {

		$suvel2df->{_vavg}		= $vavg;
		$suvel2df->{_note}		= $suvel2df->{_note}.' vavg='.$suvel2df->{_vavg};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' vavg='.$suvel2df->{_vavg};

	} else { 
		print("suvel2df, vavg, missing vavg,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suvel2df->{_verbose}		= $verbose;
		$suvel2df->{_note}		= $suvel2df->{_note}.' verbose='.$suvel2df->{_verbose};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' verbose='.$suvel2df->{_verbose};

	} else { 
		print("suvel2df, verbose, missing verbose,\n");
	 }
 }


=head2 sub xod 


=cut

 sub xod {

	my ( $self,$xod )		= @_;
	if ( $xod ne $empty_string ) {

		$suvel2df->{_xod}		= $xod;
		$suvel2df->{_note}		= $suvel2df->{_note}.' xod='.$suvel2df->{_xod};
		$suvel2df->{_Step}		= $suvel2df->{_Step}.' xod='.$suvel2df->{_xod};

	} else { 
		print("suvel2df, xod, missing xod,\n");
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
