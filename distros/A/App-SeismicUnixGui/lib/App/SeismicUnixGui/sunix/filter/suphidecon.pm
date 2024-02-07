package App::SeismicUnixGui::sunix::filter::suphidecon;

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
 SUPHIDECON - PHase Inversion Deconvolution				



    suphidecon < stdin > stdout					



 Required parameters:						  	

	none							   	

 Optional parameters:							

 ... time range used for wavelet extraction:			   	

 tm=-0.1	Pre zero time (maximum phase component )		

 tp=+0.4	Post zero time (minimum phase component + multiples)    

 percpad=50	percentage padding for nt prior to cepstrum calculation	



 pnoise=0.001	Pre-withening (assumed noise to prevent division by zero)



 Notes:								

 The wavelet is separated from the reflectivity and noise based on	

 their different 'smoothness' in the pseudo cepstrum domain.		

 The extracted wavelet also includes multiples. 			

 The wavelet is reconstructed in frequency domain, end removed		", 

 from the trace. (Method by Lichman and Northwood, 1996.)		







 Credits: Potash Corporation, Saskatechwan  Balasz Nemeth 

 given to CWP by Potash Corporation 2008 (originally as supid.c)



 Reference:

 Lichman,and Northwood, 1996; Phase Inversion deconvolution for

 long and short period multiples attenuation, in

 SEG Deconvolution 2, Geophysics reprint Series No. 17

 p. 701-718, originally presented at the 54th EAGE meeting, Paris,

 June 1992, revised March 1993, revision accepted September 1994.

 







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

my $suphidecon			= {
	_percpad					=> '',
	_pnoise					=> '',
	_tm					=> '',
	_tp					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suphidecon->{_Step}     = 'suphidecon'.$suphidecon->{_Step};
	return ( $suphidecon->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suphidecon->{_note}     = 'suphidecon'.$suphidecon->{_note};
	return ( $suphidecon->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suphidecon->{_percpad}			= '';
		$suphidecon->{_pnoise}			= '';
		$suphidecon->{_tm}			= '';
		$suphidecon->{_tp}			= '';
		$suphidecon->{_Step}			= '';
		$suphidecon->{_note}			= '';
 }


=head2 sub percpad 


=cut

 sub percpad {

	my ( $self,$percpad )		= @_;
	if ( $percpad ne $empty_string ) {

		$suphidecon->{_percpad}		= $percpad;
		$suphidecon->{_note}		= $suphidecon->{_note}.' percpad='.$suphidecon->{_percpad};
		$suphidecon->{_Step}		= $suphidecon->{_Step}.' percpad='.$suphidecon->{_percpad};

	} else { 
		print("suphidecon, percpad, missing percpad,\n");
	 }
 }


=head2 sub pnoise 


=cut

 sub pnoise {

	my ( $self,$pnoise )		= @_;
	if ( $pnoise ne $empty_string ) {

		$suphidecon->{_pnoise}		= $pnoise;
		$suphidecon->{_note}		= $suphidecon->{_note}.' pnoise='.$suphidecon->{_pnoise};
		$suphidecon->{_Step}		= $suphidecon->{_Step}.' pnoise='.$suphidecon->{_pnoise};

	} else { 
		print("suphidecon, pnoise, missing pnoise,\n");
	 }
 }


=head2 sub tm 


=cut

 sub tm {

	my ( $self,$tm )		= @_;
	if ( $tm ne $empty_string ) {

		$suphidecon->{_tm}		= $tm;
		$suphidecon->{_note}		= $suphidecon->{_note}.' tm='.$suphidecon->{_tm};
		$suphidecon->{_Step}		= $suphidecon->{_Step}.' tm='.$suphidecon->{_tm};

	} else { 
		print("suphidecon, tm, missing tm,\n");
	 }
 }


=head2 sub tp 


=cut

 sub tp {

	my ( $self,$tp )		= @_;
	if ( $tp ne $empty_string ) {

		$suphidecon->{_tp}		= $tp;
		$suphidecon->{_note}		= $suphidecon->{_note}.' tp='.$suphidecon->{_tp};
		$suphidecon->{_Step}		= $suphidecon->{_Step}.' tp='.$suphidecon->{_tp};

	} else { 
		print("suphidecon, tp, missing tp,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 3;

    return($max_index);
}
 
 
1;
