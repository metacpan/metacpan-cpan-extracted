package App::SeismicUnixGui::sunix::par::unisam2;

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
 UNISAM2 - UNIformly SAMple a 2-D function f(x1,x2)			



 unisam2 [optional parameters] <inputfile >outputfile			



 Required Parameters:							

 none									

 Optional Parameters:							

 x1=             array of x1 values at which input f(x1,x2) is sampled	

 ... Or specify a unform linear set of values for x1 via:		

 nx1=1           number of input samples in 1st dimension		

 dx1=1           input sampling interval in 1st dimension		

 fx1=0           first input sample in 1st dimension			

 ...									

 n1=1            number of output samples in 1st dimension		

 d1=             output sampling interval in 1st dimension		

 f1=             first output sample in 1st dimension			

 x2=             array of x2 values at which input f(x1,x2) is sampled	

 ... Or specify a unform linear set of values for x2 via:		

 nx2=1           number of input samples in 2nd dimension		

 dx2=1           input sampling interval in 2nd dimension		

 fx2=0           first input sample in 2nd dimension			

 ...									

 n2=1            number of output samples in 2nd dimension		

 d2=             output sampling interval in 2nd dimension		

 f2=             first output sample in 2nd dimension			

 ... 									

 method1=linear  =linear for linear interpolation			

                 =mono for monotonic bicubic interpolation		

                 =akima for Akima bicubic interpolation		

                 =spline for bicubic spline interpolation		

 method2=linear  =linear for linear interpolation			

                 =mono for monotonic bicubic interpolation		

                 =akima for Akima bicubic interpolation		

                 =spline for bicubic spline interpolation		



 NOTES:								

 The number of input samples is the number of x1 values times the	

 number of x2 values.  The number of output samples is n1 times n2.	

 The output sampling intervals (d1 and d2) and first samples (f1 and f2)

 default to span the range of input x1 and x2 values.  In other words,	

 d1=(x1max-x1min)/(n1-1) and f1=x1min; likewise for d2 and f2.		



 Interpolation is first performed along the 2nd dimension for each	

 value of x1 specified.  Interpolation is then performed along the	

 1st dimension.							







 Author:  Dave Hale, Colorado School of Mines, 01/12/91\n"



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

my $unisam2			= {
	_d1					=> '',
	_d2					=> '',
	_dx1					=> '',
	_dx2					=> '',
	_f1					=> '',
	_f2					=> '',
	_fx1					=> '',
	_fx2					=> '',
	_method1					=> '',
	_method2					=> '',
	_n1					=> '',
	_n2					=> '',
	_nx1					=> '',
	_nx2					=> '',
	_x1					=> '',
	_x2					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$unisam2->{_Step}     = 'unisam2'.$unisam2->{_Step};
	return ( $unisam2->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$unisam2->{_note}     = 'unisam2'.$unisam2->{_note};
	return ( $unisam2->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$unisam2->{_d1}			= '';
		$unisam2->{_d2}			= '';
		$unisam2->{_dx1}			= '';
		$unisam2->{_dx2}			= '';
		$unisam2->{_f1}			= '';
		$unisam2->{_f2}			= '';
		$unisam2->{_fx1}			= '';
		$unisam2->{_fx2}			= '';
		$unisam2->{_method1}			= '';
		$unisam2->{_method2}			= '';
		$unisam2->{_n1}			= '';
		$unisam2->{_n2}			= '';
		$unisam2->{_nx1}			= '';
		$unisam2->{_nx2}			= '';
		$unisam2->{_x1}			= '';
		$unisam2->{_x2}			= '';
		$unisam2->{_Step}			= '';
		$unisam2->{_note}			= '';
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$unisam2->{_d1}		= $d1;
		$unisam2->{_note}		= $unisam2->{_note}.' d1='.$unisam2->{_d1};
		$unisam2->{_Step}		= $unisam2->{_Step}.' d1='.$unisam2->{_d1};

	} else { 
		print("unisam2, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$unisam2->{_d2}		= $d2;
		$unisam2->{_note}		= $unisam2->{_note}.' d2='.$unisam2->{_d2};
		$unisam2->{_Step}		= $unisam2->{_Step}.' d2='.$unisam2->{_d2};

	} else { 
		print("unisam2, d2, missing d2,\n");
	 }
 }


=head2 sub dx1 


=cut

 sub dx1 {

	my ( $self,$dx1 )		= @_;
	if ( $dx1 ne $empty_string ) {

		$unisam2->{_dx1}		= $dx1;
		$unisam2->{_note}		= $unisam2->{_note}.' dx1='.$unisam2->{_dx1};
		$unisam2->{_Step}		= $unisam2->{_Step}.' dx1='.$unisam2->{_dx1};

	} else { 
		print("unisam2, dx1, missing dx1,\n");
	 }
 }


=head2 sub dx2 


=cut

 sub dx2 {

	my ( $self,$dx2 )		= @_;
	if ( $dx2 ne $empty_string ) {

		$unisam2->{_dx2}		= $dx2;
		$unisam2->{_note}		= $unisam2->{_note}.' dx2='.$unisam2->{_dx2};
		$unisam2->{_Step}		= $unisam2->{_Step}.' dx2='.$unisam2->{_dx2};

	} else { 
		print("unisam2, dx2, missing dx2,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$unisam2->{_f1}		= $f1;
		$unisam2->{_note}		= $unisam2->{_note}.' f1='.$unisam2->{_f1};
		$unisam2->{_Step}		= $unisam2->{_Step}.' f1='.$unisam2->{_f1};

	} else { 
		print("unisam2, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$unisam2->{_f2}		= $f2;
		$unisam2->{_note}		= $unisam2->{_note}.' f2='.$unisam2->{_f2};
		$unisam2->{_Step}		= $unisam2->{_Step}.' f2='.$unisam2->{_f2};

	} else { 
		print("unisam2, f2, missing f2,\n");
	 }
 }


=head2 sub fx1 


=cut

 sub fx1 {

	my ( $self,$fx1 )		= @_;
	if ( $fx1 ne $empty_string ) {

		$unisam2->{_fx1}		= $fx1;
		$unisam2->{_note}		= $unisam2->{_note}.' fx1='.$unisam2->{_fx1};
		$unisam2->{_Step}		= $unisam2->{_Step}.' fx1='.$unisam2->{_fx1};

	} else { 
		print("unisam2, fx1, missing fx1,\n");
	 }
 }


=head2 sub fx2 


=cut

 sub fx2 {

	my ( $self,$fx2 )		= @_;
	if ( $fx2 ne $empty_string ) {

		$unisam2->{_fx2}		= $fx2;
		$unisam2->{_note}		= $unisam2->{_note}.' fx2='.$unisam2->{_fx2};
		$unisam2->{_Step}		= $unisam2->{_Step}.' fx2='.$unisam2->{_fx2};

	} else { 
		print("unisam2, fx2, missing fx2,\n");
	 }
 }


=head2 sub method1 


=cut

 sub method1 {

	my ( $self,$method1 )		= @_;
	if ( $method1 ne $empty_string ) {

		$unisam2->{_method1}		= $method1;
		$unisam2->{_note}		= $unisam2->{_note}.' method1='.$unisam2->{_method1};
		$unisam2->{_Step}		= $unisam2->{_Step}.' method1='.$unisam2->{_method1};

	} else { 
		print("unisam2, method1, missing method1,\n");
	 }
 }


=head2 sub method2 


=cut

 sub method2 {

	my ( $self,$method2 )		= @_;
	if ( $method2 ne $empty_string ) {

		$unisam2->{_method2}		= $method2;
		$unisam2->{_note}		= $unisam2->{_note}.' method2='.$unisam2->{_method2};
		$unisam2->{_Step}		= $unisam2->{_Step}.' method2='.$unisam2->{_method2};

	} else { 
		print("unisam2, method2, missing method2,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$unisam2->{_n1}		= $n1;
		$unisam2->{_note}		= $unisam2->{_note}.' n1='.$unisam2->{_n1};
		$unisam2->{_Step}		= $unisam2->{_Step}.' n1='.$unisam2->{_n1};

	} else { 
		print("unisam2, n1, missing n1,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$unisam2->{_n2}		= $n2;
		$unisam2->{_note}		= $unisam2->{_note}.' n2='.$unisam2->{_n2};
		$unisam2->{_Step}		= $unisam2->{_Step}.' n2='.$unisam2->{_n2};

	} else { 
		print("unisam2, n2, missing n2,\n");
	 }
 }


=head2 sub nx1 


=cut

 sub nx1 {

	my ( $self,$nx1 )		= @_;
	if ( $nx1 ne $empty_string ) {

		$unisam2->{_nx1}		= $nx1;
		$unisam2->{_note}		= $unisam2->{_note}.' nx1='.$unisam2->{_nx1};
		$unisam2->{_Step}		= $unisam2->{_Step}.' nx1='.$unisam2->{_nx1};

	} else { 
		print("unisam2, nx1, missing nx1,\n");
	 }
 }


=head2 sub nx2 


=cut

 sub nx2 {

	my ( $self,$nx2 )		= @_;
	if ( $nx2 ne $empty_string ) {

		$unisam2->{_nx2}		= $nx2;
		$unisam2->{_note}		= $unisam2->{_note}.' nx2='.$unisam2->{_nx2};
		$unisam2->{_Step}		= $unisam2->{_Step}.' nx2='.$unisam2->{_nx2};

	} else { 
		print("unisam2, nx2, missing nx2,\n");
	 }
 }


=head2 sub x1 


=cut

 sub x1 {

	my ( $self,$x1 )		= @_;
	if ( $x1 ne $empty_string ) {

		$unisam2->{_x1}		= $x1;
		$unisam2->{_note}		= $unisam2->{_note}.' x1='.$unisam2->{_x1};
		$unisam2->{_Step}		= $unisam2->{_Step}.' x1='.$unisam2->{_x1};

	} else { 
		print("unisam2, x1, missing x1,\n");
	 }
 }


=head2 sub x2 


=cut

 sub x2 {

	my ( $self,$x2 )		= @_;
	if ( $x2 ne $empty_string ) {

		$unisam2->{_x2}		= $x2;
		$unisam2->{_note}		= $unisam2->{_note}.' x2='.$unisam2->{_x2};
		$unisam2->{_Step}		= $unisam2->{_Step}.' x2='.$unisam2->{_x2};

	} else { 
		print("unisam2, x2, missing x2,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 15;

    return($max_index);
}
 
 
1;
