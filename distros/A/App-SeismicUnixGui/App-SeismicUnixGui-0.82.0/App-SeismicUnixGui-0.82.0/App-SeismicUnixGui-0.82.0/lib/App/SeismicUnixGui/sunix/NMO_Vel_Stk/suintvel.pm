package App::SeismicUnixGui::sunix::NMO_Vel_Stk::suintvel;

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
 SUINTVEL - convert stacking velocity model to interval velocity model	



 suintvel vs= t0= outpar=/dev/tty					



 Required parameters:					        	

	vs=	stacking velocities 					

	t0=	normal incidence times		 			



 Optional parameters:							

	mode=0			output h= v= ; =1 output v=  t= 	

	outpar=/dev/tty		output parameter file in the form:	

				h=layer thicknesses vector		

				v=interval velocities vector		

				....or ...				

				t=vector of times from t0		

				v=interval velocities vector		



 Examples:								

    suintvel vs=5000,5523,6339,7264 t0=.4,.8,1.125,1.425 outpar=intpar	



    suintvel par=stkpar outpar=intpar					



 If the file, stkpar, contains:					

    vs=5000,5523,6339,7264						

    t0=.4,.8,1.125,1.425						

 then the two examples are equivalent.					



 Note: suintvel does not have standard su syntax since it does not	

      operate on seismic data.  Hence stdin and stdout are not used.	



 Note: may go away in favor of par program, velconv, by Dave		





 Credits:

	CWP: Jack 



 Technical Reference:

	The Common Depth Point Stack

	William A. Schneider

	Proc. IEEE, v. 72, n. 10, p. 1238-1254

	1984



 Formulas:

    	Note: All sums on i are from 1 to k



	From Schneider:

	Let h[i] be the ith layer thickness measured at the cmp and

	v[i] the ith interval velocity.

	Set:

		t[i] = h[i]/v[i]

	Define:

		t0by2[k] = 0.5 * t0[k] = Sum h[i]/v[i]

		vh[k] = vs[k]*vs[k]*t0by2[k] = Sum v[i]*h[i]

	Then:

		dt[i] = h[i]/v[i] = t0by2[i] - t0by2[i-1]

		dvh[i] = h[i]*v[i] = vh[i] - vh[i-1]

		h[i] = sqrt(dvh[i] * dt[i])

		v[i] = sqrt(dvh[i] / dt[i])







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

my $suintvel			= {
	_h					=> '',
	_mode					=> '',
	_outpar					=> '',
	_par					=> '',
	_t					=> '',
	_t0					=> '',
	_v					=> '',
	_vs					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suintvel->{_Step}     = 'suintvel'.$suintvel->{_Step};
	return ( $suintvel->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suintvel->{_note}     = 'suintvel'.$suintvel->{_note};
	return ( $suintvel->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suintvel->{_h}			= '';
		$suintvel->{_mode}			= '';
		$suintvel->{_outpar}			= '';
		$suintvel->{_par}			= '';
		$suintvel->{_t}			= '';
		$suintvel->{_t0}			= '';
		$suintvel->{_v}			= '';
		$suintvel->{_vs}			= '';
		$suintvel->{_Step}			= '';
		$suintvel->{_note}			= '';
 }


=head2 sub h 


=cut

 sub h {

	my ( $self,$h )		= @_;
	if ( $h ne $empty_string ) {

		$suintvel->{_h}		= $h;
		$suintvel->{_note}		= $suintvel->{_note}.' h='.$suintvel->{_h};
		$suintvel->{_Step}		= $suintvel->{_Step}.' h='.$suintvel->{_h};

	} else { 
		print("suintvel, h, missing h,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$suintvel->{_mode}		= $mode;
		$suintvel->{_note}		= $suintvel->{_note}.' mode='.$suintvel->{_mode};
		$suintvel->{_Step}		= $suintvel->{_Step}.' mode='.$suintvel->{_mode};

	} else { 
		print("suintvel, mode, missing mode,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$suintvel->{_outpar}		= $outpar;
		$suintvel->{_note}		= $suintvel->{_note}.' outpar='.$suintvel->{_outpar};
		$suintvel->{_Step}		= $suintvel->{_Step}.' outpar='.$suintvel->{_outpar};

	} else { 
		print("suintvel, outpar, missing outpar,\n");
	 }
 }


=head2 sub par 


=cut

 sub par {

	my ( $self,$par )		= @_;
	if ( $par ne $empty_string ) {

		$suintvel->{_par}		= $par;
		$suintvel->{_note}		= $suintvel->{_note}.' par='.$suintvel->{_par};
		$suintvel->{_Step}		= $suintvel->{_Step}.' par='.$suintvel->{_par};

	} else { 
		print("suintvel, par, missing par,\n");
	 }
 }


=head2 sub t 


=cut

 sub t {

	my ( $self,$t )		= @_;
	if ( $t ne $empty_string ) {

		$suintvel->{_t}		= $t;
		$suintvel->{_note}		= $suintvel->{_note}.' t='.$suintvel->{_t};
		$suintvel->{_Step}		= $suintvel->{_Step}.' t='.$suintvel->{_t};

	} else { 
		print("suintvel, t, missing t,\n");
	 }
 }


=head2 sub t0 


=cut

 sub t0 {

	my ( $self,$t0 )		= @_;
	if ( $t0 ne $empty_string ) {

		$suintvel->{_t0}		= $t0;
		$suintvel->{_note}		= $suintvel->{_note}.' t0='.$suintvel->{_t0};
		$suintvel->{_Step}		= $suintvel->{_Step}.' t0='.$suintvel->{_t0};

	} else { 
		print("suintvel, t0, missing t0,\n");
	 }
 }


=head2 sub v 


=cut

 sub v {

	my ( $self,$v )		= @_;
	if ( $v ne $empty_string ) {

		$suintvel->{_v}		= $v;
		$suintvel->{_note}		= $suintvel->{_note}.' v='.$suintvel->{_v};
		$suintvel->{_Step}		= $suintvel->{_Step}.' v='.$suintvel->{_v};

	} else { 
		print("suintvel, v, missing v,\n");
	 }
 }


=head2 sub vs 


=cut

 sub vs {

	my ( $self,$vs )		= @_;
	if ( $vs ne $empty_string ) {

		$suintvel->{_vs}		= $vs;
		$suintvel->{_note}		= $suintvel->{_note}.' vs='.$suintvel->{_vs};
		$suintvel->{_Step}		= $suintvel->{_Step}.' vs='.$suintvel->{_vs};

	} else { 
		print("suintvel, vs, missing vs,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 7;

    return($max_index);
}
 
 
1;
