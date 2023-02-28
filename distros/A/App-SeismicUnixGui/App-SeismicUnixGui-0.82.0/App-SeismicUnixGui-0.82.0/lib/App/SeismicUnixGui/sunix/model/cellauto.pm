package App::SeismicUnixGui::sunix::model::cellauto;

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
 CELLAUTO - Two-dimensional CELLular AUTOmata			  	



   cellauto > stdout [optional params]					



 Optional Parameters:							

 n1=500	output dimensions of image (n1 x n1 pixels)	 	

 rule=30	CA rule (Wolfram classification)			

 		Others: 54,60,62,90,94,102,110,122,126			

                       150,158,182,188,190,220,222,225,226,250		

 fill=0	Don't fill image (=1 fill image)			

 f0=330	fill zero values with f0				

 f1=3000	fill non-zero values with f1				

 ic=1		initial condition for centered unit value at t=0	

               = 2 for multiple random units				

 nc=20		number of random units (if ic=2)			

 tc=1		random initial units at t=0 (if ic=2)			

               = 2 for initial units at random (t,x)			

 verbose=0	silent operation					

               = 1 echos 'porosity' of the CA in bottom half of image	

 seed=from_clock    	random number seed (integer)            	



 Notes:								

 This program generates a select set of Wolframs fundamental cellular	

 automata. This may be useful for constructing rough, vuggy wavespeed	

 profiles. The numbering scheme follows Stephen Wolfram's.		



 Example: 								

  cellauto rule=110 ic=2 nc=100 fill=1 f1=3000 | ximage n1=500 nx=500 &



 Here we simulate a complex near surface with air-filled 		

 vugs in hard country rock, with smoothing applied via smooth2 	



  cellauto rule=110 ic=2 nc=100 fill=1 f1=3000 n1=500 |		

  smooth2 n1=500 n2=500 r1=5 r2=5 > vfile.bin				





 Credits:

	UHouston: Chris Liner 	



 Trace header fields accessed:  ns

 Trace header fields modified:  ns and delrt



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

my $cellauto			= {
	_f0					=> '',
	_f1					=> '',
	_fill					=> '',
	_ic					=> '',
	_n1					=> '',
	_nc					=> '',
	_rule					=> '',
	_seed					=> '',
	_tc					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$cellauto->{_Step}     = 'cellauto'.$cellauto->{_Step};
	return ( $cellauto->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$cellauto->{_note}     = 'cellauto'.$cellauto->{_note};
	return ( $cellauto->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$cellauto->{_f0}			= '';
		$cellauto->{_f1}			= '';
		$cellauto->{_fill}			= '';
		$cellauto->{_ic}			= '';
		$cellauto->{_n1}			= '';
		$cellauto->{_nc}			= '';
		$cellauto->{_rule}			= '';
		$cellauto->{_seed}			= '';
		$cellauto->{_tc}			= '';
		$cellauto->{_verbose}			= '';
		$cellauto->{_Step}			= '';
		$cellauto->{_note}			= '';
 }


=head2 sub f0 


=cut

 sub f0 {

	my ( $self,$f0 )		= @_;
	if ( $f0 ne $empty_string ) {

		$cellauto->{_f0}		= $f0;
		$cellauto->{_note}		= $cellauto->{_note}.' f0='.$cellauto->{_f0};
		$cellauto->{_Step}		= $cellauto->{_Step}.' f0='.$cellauto->{_f0};

	} else { 
		print("cellauto, f0, missing f0,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$cellauto->{_f1}		= $f1;
		$cellauto->{_note}		= $cellauto->{_note}.' f1='.$cellauto->{_f1};
		$cellauto->{_Step}		= $cellauto->{_Step}.' f1='.$cellauto->{_f1};

	} else { 
		print("cellauto, f1, missing f1,\n");
	 }
 }


=head2 sub fill 


=cut

 sub fill {

	my ( $self,$fill )		= @_;
	if ( $fill ne $empty_string ) {

		$cellauto->{_fill}		= $fill;
		$cellauto->{_note}		= $cellauto->{_note}.' fill='.$cellauto->{_fill};
		$cellauto->{_Step}		= $cellauto->{_Step}.' fill='.$cellauto->{_fill};

	} else { 
		print("cellauto, fill, missing fill,\n");
	 }
 }


=head2 sub ic 


=cut

 sub ic {

	my ( $self,$ic )		= @_;
	if ( $ic ne $empty_string ) {

		$cellauto->{_ic}		= $ic;
		$cellauto->{_note}		= $cellauto->{_note}.' ic='.$cellauto->{_ic};
		$cellauto->{_Step}		= $cellauto->{_Step}.' ic='.$cellauto->{_ic};

	} else { 
		print("cellauto, ic, missing ic,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$cellauto->{_n1}		= $n1;
		$cellauto->{_note}		= $cellauto->{_note}.' n1='.$cellauto->{_n1};
		$cellauto->{_Step}		= $cellauto->{_Step}.' n1='.$cellauto->{_n1};

	} else { 
		print("cellauto, n1, missing n1,\n");
	 }
 }


=head2 sub nc 


=cut

 sub nc {

	my ( $self,$nc )		= @_;
	if ( $nc ne $empty_string ) {

		$cellauto->{_nc}		= $nc;
		$cellauto->{_note}		= $cellauto->{_note}.' nc='.$cellauto->{_nc};
		$cellauto->{_Step}		= $cellauto->{_Step}.' nc='.$cellauto->{_nc};

	} else { 
		print("cellauto, nc, missing nc,\n");
	 }
 }


=head2 sub rule 


=cut

 sub rule {

	my ( $self,$rule )		= @_;
	if ( $rule ne $empty_string ) {

		$cellauto->{_rule}		= $rule;
		$cellauto->{_note}		= $cellauto->{_note}.' rule='.$cellauto->{_rule};
		$cellauto->{_Step}		= $cellauto->{_Step}.' rule='.$cellauto->{_rule};

	} else { 
		print("cellauto, rule, missing rule,\n");
	 }
 }


=head2 sub seed 


=cut

 sub seed {

	my ( $self,$seed )		= @_;
	if ( $seed ne $empty_string ) {

		$cellauto->{_seed}		= $seed;
		$cellauto->{_note}		= $cellauto->{_note}.' seed='.$cellauto->{_seed};
		$cellauto->{_Step}		= $cellauto->{_Step}.' seed='.$cellauto->{_seed};

	} else { 
		print("cellauto, seed, missing seed,\n");
	 }
 }


=head2 sub tc 


=cut

 sub tc {

	my ( $self,$tc )		= @_;
	if ( $tc ne $empty_string ) {

		$cellauto->{_tc}		= $tc;
		$cellauto->{_note}		= $cellauto->{_note}.' tc='.$cellauto->{_tc};
		$cellauto->{_Step}		= $cellauto->{_Step}.' tc='.$cellauto->{_tc};

	} else { 
		print("cellauto, tc, missing tc,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$cellauto->{_verbose}		= $verbose;
		$cellauto->{_note}		= $cellauto->{_note}.' verbose='.$cellauto->{_verbose};
		$cellauto->{_Step}		= $cellauto->{_Step}.' verbose='.$cellauto->{_verbose};

	} else { 
		print("cellauto, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 9;

    return($max_index);
}
 
 
1;
