package App::SeismicUnixGui::sunix::transform::suifft;

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
 SUIFFT - fft complex frequency traces to real time traces	



 suiftt <stdin >sdout sign=-1					



 Required parameters:						

 	none							



 Optional parameter:						

 	sign=-1		sign in exponent of inverse fft		



 Output traces are normalized by 1/N where N is the fft size.	



 Note: sufft | suifft is not quite a no-op since the trace	

 	length will usually be longer due to fft padding.	





 Credits:



	CWP: Shuki, Chris, Jack



 Trace header fields accessed: ns, trid

 Trace header fields modified: ns, trid



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

my $suifft			= {
	_sign					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suifft->{_Step}     = 'suifft'.$suifft->{_Step};
	return ( $suifft->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suifft->{_note}     = 'suifft'.$suifft->{_note};
	return ( $suifft->{_note} );

 }



=head2 sub clear

=cut

 sub clear {
		$suifft->{__sign}			= '';
		$suifft->{_empty_string}			= '';
		$suifft->{_false}			= '';
		$suifft->{_get}			= '';
		$suifft->{_index}			= '';
		$suifft->{_max_index}			= '';
		$suifft->{_off}			= '';
		$suifft->{_on}			= '';
		$suifft->{_sign}			= '';
		$suifft->{_suifft}			= '';
		$suifft->{_true}			= '';
		$suifft->{_var}			= '';
		$suifft->{_Step}			= '';
		$suifft->{_note}			= '';
 }


=head2 sub sign 


=cut

 sub sign {

	my ( $self,$sign )		= @_;
	if ( $sign ne $empty_string ) {

		$suifft->{_sign}		= $sign;
		$suifft->{_note}		= $suifft->{_note}.' sign='.$suifft->{_sign};
		$suifft->{_Step}		= $suifft->{_Step}.' sign='.$suifft->{_sign};

	} else { 
		print("suifft, sign, missing sign,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 0;

    return($max_index);
}
 
 
1; 
