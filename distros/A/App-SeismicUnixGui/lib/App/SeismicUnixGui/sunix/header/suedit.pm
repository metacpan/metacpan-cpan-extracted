package App::SeismicUnixGui::sunix::header::suedit;

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
 SUEDIT - examine segy diskfiles and edit headers			



 suedit diskfile  (open for possible header modification if writable)	

 suedit <diskfile  (open read only)					



 The following commands are recognized:				

 number	read in that trace and print nonzero header words	

 <CR>		go to trace one step away (step is initially -1)	

 +		read in next trace (step is set to +1)			

 -		read in previous trace (step is set to -1)		

 dN		advance N traces (step is set to N)			

 %		print some percentiles of the trace data		

 r		print some ranks (rank[j] = jth smallest datum) 	

 p [n1 [n2]]  	tab plot sample n1 to n2 on current trace		

 g [tr1 tr2]  	ximage plot the trace [traces tr1 to tr2]	

 w [tr1 tr2]  	xwigb plot the trace [traces tr1 to tr2]	

 f [tr1 tr2]   ximage plot the amplitude spectra of the trace		

 u [tr1 tr2]   apply user pipeline to specified traces 

 ! key=val  	change a value in a field (e.g. ! tracr=101)		

 ?		print help file						

 q		quit							



 NOTE: sample numbers are 1-based (first sample is 1).			



 'u 1000000  1000100 suwind >subset.su' will quickly extract a few     

 traces from the middle of a large dataset                             





 Credits:

 SEP: Einar Kjartansson, Shuki Ronen, Stew Levin

 CWP: Jack K. Cohen

 Unocal: Reg Beardsley

 Trace header fields accessed: ns

 Trace header fields modified: ntr (only for internal plotting)



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

my $suedit			= {
	_key					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suedit->{_Step}     = 'suedit'.$suedit->{_Step};
	return ( $suedit->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suedit->{_note}     = 'suedit'.$suedit->{_note};
	return ( $suedit->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suedit->{_key}			= '';
		$suedit->{_Step}			= '';
		$suedit->{_note}			= '';
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$suedit->{_key}		= $key;
		$suedit->{_note}		= $suedit->{_note}.' key='.$suedit->{_key};
		$suedit->{_Step}		= $suedit->{_Step}.' key='.$suedit->{_key};

	} else { 
		print("suedit, key, missing key,\n");
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
