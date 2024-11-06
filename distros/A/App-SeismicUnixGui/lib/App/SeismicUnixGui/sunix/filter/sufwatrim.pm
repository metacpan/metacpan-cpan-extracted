package App::SeismicUnixGui::sunix::filter::sufwatrim;

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
 SUFWATRIM - FX domain Alpha TRIM					



  sufwatrim  <stdin > stdout [optional parameters]			



 Required parameters:							

 key=key1,key2,..	Header words defining mixing dimesnion		

 dx=d1,d2,..		Distance units for each header word		

 Optional parameters:							

 keyg=ep		Header word indicating the start of gather	

 vf=0			=1 Do a frequency dependent mix			

 vmin=5000		Velocity of the reflection slope		

			than should not be attenuated			

 Notes:		 						

 Trace with the header word mark set to one will be 			

 the output trace 							





 Credits: Potash Corporation of Saskatchewan, Balasz Nemeth

 Code given to CWP in 2008







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

my $sufwatrim			= {
	_dx					=> '',
	_key					=> '',
	_keyg					=> '',
	_vf					=> '',
	_vmin					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sufwatrim->{_Step}     = 'sufwatrim'.$sufwatrim->{_Step};
	return ( $sufwatrim->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sufwatrim->{_note}     = 'sufwatrim'.$sufwatrim->{_note};
	return ( $sufwatrim->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sufwatrim->{_dx}			= '';
		$sufwatrim->{_key}			= '';
		$sufwatrim->{_keyg}			= '';
		$sufwatrim->{_vf}			= '';
		$sufwatrim->{_vmin}			= '';
		$sufwatrim->{_Step}			= '';
		$sufwatrim->{_note}			= '';
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sufwatrim->{_dx}		= $dx;
		$sufwatrim->{_note}		= $sufwatrim->{_note}.' dx='.$sufwatrim->{_dx};
		$sufwatrim->{_Step}		= $sufwatrim->{_Step}.' dx='.$sufwatrim->{_dx};

	} else { 
		print("sufwatrim, dx, missing dx,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sufwatrim->{_key}		= $key;
		$sufwatrim->{_note}		= $sufwatrim->{_note}.' key='.$sufwatrim->{_key};
		$sufwatrim->{_Step}		= $sufwatrim->{_Step}.' key='.$sufwatrim->{_key};

	} else { 
		print("sufwatrim, key, missing key,\n");
	 }
 }


=head2 sub keyg 


=cut

 sub keyg {

	my ( $self,$keyg )		= @_;
	if ( $keyg ne $empty_string ) {

		$sufwatrim->{_keyg}		= $keyg;
		$sufwatrim->{_note}		= $sufwatrim->{_note}.' keyg='.$sufwatrim->{_keyg};
		$sufwatrim->{_Step}		= $sufwatrim->{_Step}.' keyg='.$sufwatrim->{_keyg};

	} else { 
		print("sufwatrim, keyg, missing keyg,\n");
	 }
 }


=head2 sub vf 


=cut

 sub vf {

	my ( $self,$vf )		= @_;
	if ( $vf ne $empty_string ) {

		$sufwatrim->{_vf}		= $vf;
		$sufwatrim->{_note}		= $sufwatrim->{_note}.' vf='.$sufwatrim->{_vf};
		$sufwatrim->{_Step}		= $sufwatrim->{_Step}.' vf='.$sufwatrim->{_vf};

	} else { 
		print("sufwatrim, vf, missing vf,\n");
	 }
 }


=head2 sub vmin 


=cut

 sub vmin {

	my ( $self,$vmin )		= @_;
	if ( $vmin ne $empty_string ) {

		$sufwatrim->{_vmin}		= $vmin;
		$sufwatrim->{_note}		= $sufwatrim->{_note}.' vmin='.$sufwatrim->{_vmin};
		$sufwatrim->{_Step}		= $sufwatrim->{_Step}.' vmin='.$sufwatrim->{_vmin};

	} else { 
		print("sufwatrim, vmin, missing vmin,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 4;

    return($max_index);
}
 
 
1;
