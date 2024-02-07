package App::SeismicUnixGui::sunix::NMO_Vel_Stk::surelanan;

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
 SURELANAN - REsiduaL-moveout semblance ANalysis for ANisotropic media	



 surelan refl= npicks=    [optional parameters]			



 Required parameters:							

 reflector file: reflec =						

 number of points in the reflector file =				



 Optional Parameters:							

 nr1=51		number of r1-parameter samples   		

 dr1=0.01              r1-parameter sampling interval			

 fr1=-0.25             first value of r1-parameter			

 nr2=51		number of r2-parameter samples   		

 dr2=0.01              r2-parameter sampling interval			

 fr2=-0.25             first value of r2-parameter			

 dzratio=5             ratio of output to input depth sampling intervals

 nsmooth=dzratio*2+1   length of semblance num and den smoothing window

 verbose=0             =1 for diagnostic print on stderr		

 method=linear		for linear interpolation of the interface       

 			=mono for monotonic cubic interpolation of interface

 			=akima for Akima's cubic interpolation of interface 

 			=spline for cubic spline interpolation of interface 



 Note: 								

 1. This program is part of Debashish Sarkar's anisotropic model building

 technique. 								

 2. Input migrated traces should be sorted by cdp - surelan outputs a 	

    group of semblance traces every time cdp changes.  Therefore, the  

    output will be useful only if cdp gathers are input.  		

 3. The residual-moveout semblance for cdp gathers is based		

	on z(h)*z(h) = z(0)*z(0) + r1*h^2 + r2*h^4/[h^2+z(0)^2] where z 

	depth and h is the half-offset.   				



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

my $surelanan			= {
	_dr1					=> '',
	_dr2					=> '',
	_dzratio					=> '',
	_fr1					=> '',
	_fr2					=> '',
	_method					=> '',
	_nr1					=> '',
	_nr2					=> '',
	_nsmooth					=> '',
	_refl					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$surelanan->{_Step}     = 'surelanan'.$surelanan->{_Step};
	return ( $surelanan->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$surelanan->{_note}     = 'surelanan'.$surelanan->{_note};
	return ( $surelanan->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$surelanan->{_dr1}			= '';
		$surelanan->{_dr2}			= '';
		$surelanan->{_dzratio}			= '';
		$surelanan->{_fr1}			= '';
		$surelanan->{_fr2}			= '';
		$surelanan->{_method}			= '';
		$surelanan->{_nr1}			= '';
		$surelanan->{_nr2}			= '';
		$surelanan->{_nsmooth}			= '';
		$surelanan->{_refl}			= '';
		$surelanan->{_verbose}			= '';
		$surelanan->{_Step}			= '';
		$surelanan->{_note}			= '';
 }


=head2 sub dr1 


=cut

 sub dr1 {

	my ( $self,$dr1 )		= @_;
	if ( $dr1 ne $empty_string ) {

		$surelanan->{_dr1}		= $dr1;
		$surelanan->{_note}		= $surelanan->{_note}.' dr1='.$surelanan->{_dr1};
		$surelanan->{_Step}		= $surelanan->{_Step}.' dr1='.$surelanan->{_dr1};

	} else { 
		print("surelanan, dr1, missing dr1,\n");
	 }
 }


=head2 sub dr2 


=cut

 sub dr2 {

	my ( $self,$dr2 )		= @_;
	if ( $dr2 ne $empty_string ) {

		$surelanan->{_dr2}		= $dr2;
		$surelanan->{_note}		= $surelanan->{_note}.' dr2='.$surelanan->{_dr2};
		$surelanan->{_Step}		= $surelanan->{_Step}.' dr2='.$surelanan->{_dr2};

	} else { 
		print("surelanan, dr2, missing dr2,\n");
	 }
 }


=head2 sub dzratio 


=cut

 sub dzratio {

	my ( $self,$dzratio )		= @_;
	if ( $dzratio ne $empty_string ) {

		$surelanan->{_dzratio}		= $dzratio;
		$surelanan->{_note}		= $surelanan->{_note}.' dzratio='.$surelanan->{_dzratio};
		$surelanan->{_Step}		= $surelanan->{_Step}.' dzratio='.$surelanan->{_dzratio};

	} else { 
		print("surelanan, dzratio, missing dzratio,\n");
	 }
 }


=head2 sub fr1 


=cut

 sub fr1 {

	my ( $self,$fr1 )		= @_;
	if ( $fr1 ne $empty_string ) {

		$surelanan->{_fr1}		= $fr1;
		$surelanan->{_note}		= $surelanan->{_note}.' fr1='.$surelanan->{_fr1};
		$surelanan->{_Step}		= $surelanan->{_Step}.' fr1='.$surelanan->{_fr1};

	} else { 
		print("surelanan, fr1, missing fr1,\n");
	 }
 }


=head2 sub fr2 


=cut

 sub fr2 {

	my ( $self,$fr2 )		= @_;
	if ( $fr2 ne $empty_string ) {

		$surelanan->{_fr2}		= $fr2;
		$surelanan->{_note}		= $surelanan->{_note}.' fr2='.$surelanan->{_fr2};
		$surelanan->{_Step}		= $surelanan->{_Step}.' fr2='.$surelanan->{_fr2};

	} else { 
		print("surelanan, fr2, missing fr2,\n");
	 }
 }


=head2 sub method 


=cut

 sub method {

	my ( $self,$method )		= @_;
	if ( $method ne $empty_string ) {

		$surelanan->{_method}		= $method;
		$surelanan->{_note}		= $surelanan->{_note}.' method='.$surelanan->{_method};
		$surelanan->{_Step}		= $surelanan->{_Step}.' method='.$surelanan->{_method};

	} else { 
		print("surelanan, method, missing method,\n");
	 }
 }


=head2 sub nr1 


=cut

 sub nr1 {

	my ( $self,$nr1 )		= @_;
	if ( $nr1 ne $empty_string ) {

		$surelanan->{_nr1}		= $nr1;
		$surelanan->{_note}		= $surelanan->{_note}.' nr1='.$surelanan->{_nr1};
		$surelanan->{_Step}		= $surelanan->{_Step}.' nr1='.$surelanan->{_nr1};

	} else { 
		print("surelanan, nr1, missing nr1,\n");
	 }
 }


=head2 sub nr2 


=cut

 sub nr2 {

	my ( $self,$nr2 )		= @_;
	if ( $nr2 ne $empty_string ) {

		$surelanan->{_nr2}		= $nr2;
		$surelanan->{_note}		= $surelanan->{_note}.' nr2='.$surelanan->{_nr2};
		$surelanan->{_Step}		= $surelanan->{_Step}.' nr2='.$surelanan->{_nr2};

	} else { 
		print("surelanan, nr2, missing nr2,\n");
	 }
 }


=head2 sub nsmooth 


=cut

 sub nsmooth {

	my ( $self,$nsmooth )		= @_;
	if ( $nsmooth ne $empty_string ) {

		$surelanan->{_nsmooth}		= $nsmooth;
		$surelanan->{_note}		= $surelanan->{_note}.' nsmooth='.$surelanan->{_nsmooth};
		$surelanan->{_Step}		= $surelanan->{_Step}.' nsmooth='.$surelanan->{_nsmooth};

	} else { 
		print("surelanan, nsmooth, missing nsmooth,\n");
	 }
 }


=head2 sub refl 


=cut

 sub refl {

	my ( $self,$refl )		= @_;
	if ( $refl ne $empty_string ) {

		$surelanan->{_refl}		= $refl;
		$surelanan->{_note}		= $surelanan->{_note}.' refl='.$surelanan->{_refl};
		$surelanan->{_Step}		= $surelanan->{_Step}.' refl='.$surelanan->{_refl};

	} else { 
		print("surelanan, refl, missing refl,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$surelanan->{_verbose}		= $verbose;
		$surelanan->{_note}		= $surelanan->{_note}.' verbose='.$surelanan->{_verbose};
		$surelanan->{_Step}		= $surelanan->{_Step}.' verbose='.$surelanan->{_verbose};

	} else { 
		print("surelanan, verbose, missing verbose,\n");
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
