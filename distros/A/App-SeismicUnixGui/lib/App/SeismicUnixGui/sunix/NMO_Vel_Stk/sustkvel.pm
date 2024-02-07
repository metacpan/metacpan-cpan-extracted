package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sustkvel;

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
 SUSTKVEL - convert constant dip layer interval velocity model to the	

	   stacking velocity model required by sunmo			



 sustkvel v= h= dip=0.0 outpar=/dev/tty				



 Required parameters:					        	

	v=	interval velocities 					

	h=	layer thicknesses at the cmp	 			



 Optional parameters:							

	dip=0.0			(constant) dip of the layers (degrees)	

	outpar=/dev/tty		output parameter file in the form	

				required by sunmo:			

				tv=zero incidence time pick vector	

				v=stacking velocities vector		



 Examples:								

    sustkvel v=5000,6000,8000,10000 h=1000,1200,1300,1500 outpar=stkpar

    sunmo <data.cdp par=stkpar >data.nmo				



    sustkvel par=intpar outpar=stkpar					

    sunmo <data.cdp par=stkpar >data.nmo				



 If the file, intpar, contains:					

    v=5000,6000,8000,10000						

    h=1000,1200,1300,1500						

 then the two examples are equivalent.  The created parameter file,	

 stkpar, is in the form of the velocity model required by sunmo.	



 Note: sustkvel does not have standard su syntax since it does not	

      operate on seismic data.  Hence stdin and stdout are not used.	



 Caveat: Does not accept a series of interval velocity models to	

	produce a variable velocity file for sunmo.			





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

		t0[k] = 2 Sum t[i] * cos(dip)

		vs[k] = (1.0/cos(dip)) sqrt(Sum v[i]*v[i]*t[i] / Sum t[i])

	Define:

		t0by2[k] = Sum h[i]/v[i]

		vh[k]    = Sum v[i]*h[i]

	Then:

		t0[k] = 2 * t0by2[k] * cos(dip)

		vs[k] = sqrt(vh[k] / t0by2[k]) / cos(dip)







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

my $sustkvel			= {
	_dip					=> '',
	_h					=> '',
	_outpar					=> '',
	_par					=> '',
	_tv					=> '',
	_v					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sustkvel->{_Step}     = 'sustkvel'.$sustkvel->{_Step};
	return ( $sustkvel->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sustkvel->{_note}     = 'sustkvel'.$sustkvel->{_note};
	return ( $sustkvel->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sustkvel->{_dip}			= '';
		$sustkvel->{_h}			= '';
		$sustkvel->{_outpar}			= '';
		$sustkvel->{_par}			= '';
		$sustkvel->{_tv}			= '';
		$sustkvel->{_v}			= '';
		$sustkvel->{_Step}			= '';
		$sustkvel->{_note}			= '';
 }


=head2 sub dip 


=cut

 sub dip {

	my ( $self,$dip )		= @_;
	if ( $dip ne $empty_string ) {

		$sustkvel->{_dip}		= $dip;
		$sustkvel->{_note}		= $sustkvel->{_note}.' dip='.$sustkvel->{_dip};
		$sustkvel->{_Step}		= $sustkvel->{_Step}.' dip='.$sustkvel->{_dip};

	} else { 
		print("sustkvel, dip, missing dip,\n");
	 }
 }


=head2 sub h 


=cut

 sub h {

	my ( $self,$h )		= @_;
	if ( $h ne $empty_string ) {

		$sustkvel->{_h}		= $h;
		$sustkvel->{_note}		= $sustkvel->{_note}.' h='.$sustkvel->{_h};
		$sustkvel->{_Step}		= $sustkvel->{_Step}.' h='.$sustkvel->{_h};

	} else { 
		print("sustkvel, h, missing h,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$sustkvel->{_outpar}		= $outpar;
		$sustkvel->{_note}		= $sustkvel->{_note}.' outpar='.$sustkvel->{_outpar};
		$sustkvel->{_Step}		= $sustkvel->{_Step}.' outpar='.$sustkvel->{_outpar};

	} else { 
		print("sustkvel, outpar, missing outpar,\n");
	 }
 }


=head2 sub par 


=cut

 sub par {

	my ( $self,$par )		= @_;
	if ( $par ne $empty_string ) {

		$sustkvel->{_par}		= $par;
		$sustkvel->{_note}		= $sustkvel->{_note}.' par='.$sustkvel->{_par};
		$sustkvel->{_Step}		= $sustkvel->{_Step}.' par='.$sustkvel->{_par};

	} else { 
		print("sustkvel, par, missing par,\n");
	 }
 }


=head2 sub tv 


=cut

 sub tv {

	my ( $self,$tv )		= @_;
	if ( $tv ne $empty_string ) {

		$sustkvel->{_tv}		= $tv;
		$sustkvel->{_note}		= $sustkvel->{_note}.' tv='.$sustkvel->{_tv};
		$sustkvel->{_Step}		= $sustkvel->{_Step}.' tv='.$sustkvel->{_tv};

	} else { 
		print("sustkvel, tv, missing tv,\n");
	 }
 }


=head2 sub v 


=cut

 sub v {

	my ( $self,$v )		= @_;
	if ( $v ne $empty_string ) {

		$sustkvel->{_v}		= $v;
		$sustkvel->{_note}		= $sustkvel->{_note}.' v='.$sustkvel->{_v};
		$sustkvel->{_Step}		= $sustkvel->{_Step}.' v='.$sustkvel->{_v};

	} else { 
		print("sustkvel, v, missing v,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 5;

    return($max_index);
}
 
 
1;
