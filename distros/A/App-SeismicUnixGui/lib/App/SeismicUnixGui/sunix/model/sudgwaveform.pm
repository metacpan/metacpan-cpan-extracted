package App::SeismicUnixGui::sunix::model::sudgwaveform;

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
 SUDGWAVEFORM - make Gaussian derivative waveform in SU format		



  sudgwaveform >stdout  [optional parameters]				





 Optional parameters:							

 n=2    	order of derivative (n>=1)				

 fpeak=35	peak frequency						

 nfpeak=n*n	max. frequency = nfpeak * fpeak				

 nt=128	length of waveform					

 shift=0	additional time shift in s (used for plotting)		

 sign=1	use =-1 to change sign					

 verbose=0	=0 don't display diagnostic messages			

               =1 display diagnostic messages				

 Notes:								

 This code computes a waveform that is the n-th order derivative of a	

 Gaussian. The variance of the Gaussian is specified through its peak	

 frequency, i.e. the frequency at which the amplitude spectrum of the	

 Gaussian has a maximum. nfpeak is used to compute maximum frequency,	

 which in turn is used to compute the sampling interval. Increasing	

 nfpeak gives smoother plots. In order to have a (pseudo-) causal	

 pulse, the program computes a time shift equal to sqrt(n)/fpeak. An	

 additional shift can be applied with the parameter shift. A positive	

 value shifts the waveform to the right.				



 Examples:								

 2-loop Ricker: dgwaveform n=1	>ricker2.su				

 3-loop Ricker: dgwaveform n=2 >ricker3.su				

 Sonic transducer pulse: dgwaveform n=10 fpeak=300 >sonic.su		



 To display use suxgraph. For example:					

 dgwaveform n=10 fpeak=300 | suxgraph style=normal &			



 For other seismic waveforms, please use "suwaveform".		





 Credits:



	Werner M. Heigl, February 2007



 This copyright covers parts that are not part of the original

 CWP/SU: Seismic Un*x codes called by this program:



 Copyright (c) 2007 by the Society of Exploration Geophysicists.

 For more information, go to http://software.seg.org/2007/0004 .

 You must read and accept usage terms at:

 http://software.seg.org/disclaimer.txt before use.



 Revision history:

 Original SEG version by Werner M. Heigl, Apache E&P Technology,

 February 2007.



 Jan 2010 - subroutines deriv_n_gauss and hermite_n_polynomial moved

 to libcwp.a

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

my $sudgwaveform			= {
	_fpeak					=> '',
	_n					=> '',
	_nfpeak					=> '',
	_nt					=> '',
	_shift					=> '',
	_sign					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sudgwaveform->{_Step}     = 'sudgwaveform'.$sudgwaveform->{_Step};
	return ( $sudgwaveform->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sudgwaveform->{_note}     = 'sudgwaveform'.$sudgwaveform->{_note};
	return ( $sudgwaveform->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sudgwaveform->{_fpeak}			= '';
		$sudgwaveform->{_n}			= '';
		$sudgwaveform->{_nfpeak}			= '';
		$sudgwaveform->{_nt}			= '';
		$sudgwaveform->{_shift}			= '';
		$sudgwaveform->{_sign}			= '';
		$sudgwaveform->{_verbose}			= '';
		$sudgwaveform->{_Step}			= '';
		$sudgwaveform->{_note}			= '';
 }


=head2 sub fpeak 


=cut

 sub fpeak {

	my ( $self,$fpeak )		= @_;
	if ( $fpeak ne $empty_string ) {

		$sudgwaveform->{_fpeak}		= $fpeak;
		$sudgwaveform->{_note}		= $sudgwaveform->{_note}.' fpeak='.$sudgwaveform->{_fpeak};
		$sudgwaveform->{_Step}		= $sudgwaveform->{_Step}.' fpeak='.$sudgwaveform->{_fpeak};

	} else { 
		print("sudgwaveform, fpeak, missing fpeak,\n");
	 }
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$sudgwaveform->{_n}		= $n;
		$sudgwaveform->{_note}		= $sudgwaveform->{_note}.' n='.$sudgwaveform->{_n};
		$sudgwaveform->{_Step}		= $sudgwaveform->{_Step}.' n='.$sudgwaveform->{_n};

	} else { 
		print("sudgwaveform, n, missing n,\n");
	 }
 }


=head2 sub nfpeak 


=cut

 sub nfpeak {

	my ( $self,$nfpeak )		= @_;
	if ( $nfpeak ne $empty_string ) {

		$sudgwaveform->{_nfpeak}		= $nfpeak;
		$sudgwaveform->{_note}		= $sudgwaveform->{_note}.' nfpeak='.$sudgwaveform->{_nfpeak};
		$sudgwaveform->{_Step}		= $sudgwaveform->{_Step}.' nfpeak='.$sudgwaveform->{_nfpeak};

	} else { 
		print("sudgwaveform, nfpeak, missing nfpeak,\n");
	 }
 }


=head2 sub nt 


=cut

 sub nt {

	my ( $self,$nt )		= @_;
	if ( $nt ne $empty_string ) {

		$sudgwaveform->{_nt}		= $nt;
		$sudgwaveform->{_note}		= $sudgwaveform->{_note}.' nt='.$sudgwaveform->{_nt};
		$sudgwaveform->{_Step}		= $sudgwaveform->{_Step}.' nt='.$sudgwaveform->{_nt};

	} else { 
		print("sudgwaveform, nt, missing nt,\n");
	 }
 }


=head2 sub shift 


=cut

 sub shift {

	my ( $self,$shift )		= @_;
	if ( $shift ne $empty_string ) {

		$sudgwaveform->{_shift}		= $shift;
		$sudgwaveform->{_note}		= $sudgwaveform->{_note}.' shift='.$sudgwaveform->{_shift};
		$sudgwaveform->{_Step}		= $sudgwaveform->{_Step}.' shift='.$sudgwaveform->{_shift};

	} else { 
		print("sudgwaveform, shift, missing shift,\n");
	 }
 }


=head2 sub sign 


=cut

 sub sign {

	my ( $self,$sign )		= @_;
	if ( $sign ne $empty_string ) {

		$sudgwaveform->{_sign}		= $sign;
		$sudgwaveform->{_note}		= $sudgwaveform->{_note}.' sign='.$sudgwaveform->{_sign};
		$sudgwaveform->{_Step}		= $sudgwaveform->{_Step}.' sign='.$sudgwaveform->{_sign};

	} else { 
		print("sudgwaveform, sign, missing sign,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sudgwaveform->{_verbose}		= $verbose;
		$sudgwaveform->{_note}		= $sudgwaveform->{_note}.' verbose='.$sudgwaveform->{_verbose};
		$sudgwaveform->{_Step}		= $sudgwaveform->{_Step}.' verbose='.$sudgwaveform->{_verbose};

	} else { 
		print("sudgwaveform, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 6;

    return($max_index);
}
 
 
1;
