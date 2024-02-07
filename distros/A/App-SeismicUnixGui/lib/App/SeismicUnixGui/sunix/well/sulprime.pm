package App::SeismicUnixGui::sunix::well::sulprime;

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
 SULPRIME - find appropriate Backus average length for  	

 		a given log suite, frequency, and purpose		



 sulprime < vp_vs_rho.su  [options]		or		

 sulprime < vp_vs_rho_gr.su   [options]			



 Required parameters:						

 none								



 Optional parameter:						

 b=2.0		target value of Backus number		 	

		b=2 is transmission limit (ok for proc, mig, etc.)

		b=0.3 is scattering limit (ok for modeling)	

 dz=1		input depth sample interval (ft)		 

 f=60		frequency (Hz)... dominant or max (to be safe) 	

 nmax=301	maximum averaging length (samples)		

 verbose=1	print intermediate results			

		=0 print final result only			



 Notes:							

 1. input is in sync with subackus, but vp and gr not used	

     (gr= gamma ray log)					

 Related codes:  subackus, subackush				



 

 Credits:

	UHouston: Chris Liner Sept 2008

              I gratefully acknowledge Saudi Aramco for permission

              to release this code developed while I worked for the

              EXPEC-ARC research division.

 Reference:			

     The Backus Number (Liner and Fei, 2007, TLE)





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

my $sulprime			= {
	_b					=> '',
	_dz					=> '',
	_f					=> '',
	_gr					=> '',
	_nmax					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sulprime->{_Step}     = 'sulprime'.$sulprime->{_Step};
	return ( $sulprime->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sulprime->{_note}     = 'sulprime'.$sulprime->{_note};
	return ( $sulprime->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sulprime->{_b}			= '';
		$sulprime->{_dz}			= '';
		$sulprime->{_f}			= '';
		$sulprime->{_gr}			= '';
		$sulprime->{_nmax}			= '';
		$sulprime->{_verbose}			= '';
		$sulprime->{_Step}			= '';
		$sulprime->{_note}			= '';
 }


=head2 sub b 


=cut

 sub b {

	my ( $self,$b )		= @_;
	if ( $b ne $empty_string ) {

		$sulprime->{_b}		= $b;
		$sulprime->{_note}		= $sulprime->{_note}.' b='.$sulprime->{_b};
		$sulprime->{_Step}		= $sulprime->{_Step}.' b='.$sulprime->{_b};

	} else { 
		print("sulprime, b, missing b,\n");
	 }
 }


=head2 sub dz 


=cut

 sub dz {

	my ( $self,$dz )		= @_;
	if ( $dz ne $empty_string ) {

		$sulprime->{_dz}		= $dz;
		$sulprime->{_note}		= $sulprime->{_note}.' dz='.$sulprime->{_dz};
		$sulprime->{_Step}		= $sulprime->{_Step}.' dz='.$sulprime->{_dz};

	} else { 
		print("sulprime, dz, missing dz,\n");
	 }
 }


=head2 sub f 


=cut

 sub f {

	my ( $self,$f )		= @_;
	if ( $f ne $empty_string ) {

		$sulprime->{_f}		= $f;
		$sulprime->{_note}		= $sulprime->{_note}.' f='.$sulprime->{_f};
		$sulprime->{_Step}		= $sulprime->{_Step}.' f='.$sulprime->{_f};

	} else { 
		print("sulprime, f, missing f,\n");
	 }
 }


=head2 sub gr 


=cut

 sub gr {

	my ( $self,$gr )		= @_;
	if ( $gr ne $empty_string ) {

		$sulprime->{_gr}		= $gr;
		$sulprime->{_note}		= $sulprime->{_note}.' gr='.$sulprime->{_gr};
		$sulprime->{_Step}		= $sulprime->{_Step}.' gr='.$sulprime->{_gr};

	} else { 
		print("sulprime, gr, missing gr,\n");
	 }
 }


=head2 sub nmax 


=cut

 sub nmax {

	my ( $self,$nmax )		= @_;
	if ( $nmax ne $empty_string ) {

		$sulprime->{_nmax}		= $nmax;
		$sulprime->{_note}		= $sulprime->{_note}.' nmax='.$sulprime->{_nmax};
		$sulprime->{_Step}		= $sulprime->{_Step}.' nmax='.$sulprime->{_nmax};

	} else { 
		print("sulprime, nmax, missing nmax,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sulprime->{_verbose}		= $verbose;
		$sulprime->{_note}		= $sulprime->{_note}.' verbose='.$sulprime->{_verbose};
		$sulprime->{_Step}		= $sulprime->{_Step}.' verbose='.$sulprime->{_verbose};

	} else { 
		print("sulprime, verbose, missing verbose,\n");
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
