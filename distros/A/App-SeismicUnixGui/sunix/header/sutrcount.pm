package App::SeismicUnixGui::sunix::header::sutrcount;

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
 SUTRCOUNT - SU program to count the TRaces in infile		



   sutrcount < infile					     	

 Required parameters:						

       none							

 Optional parameter:						

    outpar=stdout						

 Notes:       							

 Once you have the value of ntr, you may set the ntr header field

 via:      							

       sushw key=ntr a=NTR < datain.su  > dataout.su 		

 Where NTR is the value of the count obtained with sutrcount 	





 Credits:  B.Nemeth, Potash Corporation, Saskatchewan 

 		given to CWP in 2008 with permission of Potash Corporation





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

my $sutrcount			= {
	_key					=> '',
	_outpar					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sutrcount->{_Step}     = 'sutrcount'.$sutrcount->{_Step};
	return ( $sutrcount->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sutrcount->{_note}     = 'sutrcount'.$sutrcount->{_note};
	return ( $sutrcount->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sutrcount->{_key}			= '';
		$sutrcount->{_outpar}			= '';
		$sutrcount->{_Step}			= '';
		$sutrcount->{_note}			= '';
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sutrcount->{_key}		= $key;
		$sutrcount->{_note}		= $sutrcount->{_note}.' key='.$sutrcount->{_key};
		$sutrcount->{_Step}		= $sutrcount->{_Step}.' key='.$sutrcount->{_key};

	} else { 
		print("sutrcount, key, missing key,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$sutrcount->{_outpar}		= $outpar;
		$sutrcount->{_note}		= $sutrcount->{_note}.' outpar='.$sutrcount->{_outpar};
		$sutrcount->{_Step}		= $sutrcount->{_Step}.' outpar='.$sutrcount->{_outpar};

	} else { 
		print("sutrcount, outpar, missing outpar,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 1;

    return($max_index);
}
 
 
1;
