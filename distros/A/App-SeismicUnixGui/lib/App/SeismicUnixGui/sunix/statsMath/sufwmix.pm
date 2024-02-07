package App::SeismicUnixGui::sunix::statsMath::sufwmix;

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
 SUFWMIX -  FX domain multidimensional Weighted Mix			



	sufwmix < stdin > stdout [optional parameters]			



 Required parameters:							

 key=key1,key2,..	Header words defining mixing dimension		

 dx=d1,d2,..		Distance units for each header word		

 Optional parameters:							

 keyg=ep		Header word indicating the start of gather	

 vf=0			=1 Do a frequency dependent mix			

 vmin=5000		Velocity of the reflection slope		

			than should not be attenuated			

 Notes:								

 Trace with the header word mark set to one will be			

 the output trace 							

  (a work in progress)							





 Credits:  



  Potash Corporation: Balazs Nemeth, Saskatoon Saskatchewan CA,

   given to CWP in 2008







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

my $sufwmix			= {
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

	$sufwmix->{_Step}     = 'sufwmix'.$sufwmix->{_Step};
	return ( $sufwmix->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sufwmix->{_note}     = 'sufwmix'.$sufwmix->{_note};
	return ( $sufwmix->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sufwmix->{_dx}			= '';
		$sufwmix->{_key}			= '';
		$sufwmix->{_keyg}			= '';
		$sufwmix->{_vf}			= '';
		$sufwmix->{_vmin}			= '';
		$sufwmix->{_Step}			= '';
		$sufwmix->{_note}			= '';
 }


=head2 sub dx 


=cut

 sub dx {

	my ( $self,$dx )		= @_;
	if ( $dx ne $empty_string ) {

		$sufwmix->{_dx}		= $dx;
		$sufwmix->{_note}		= $sufwmix->{_note}.' dx='.$sufwmix->{_dx};
		$sufwmix->{_Step}		= $sufwmix->{_Step}.' dx='.$sufwmix->{_dx};

	} else { 
		print("sufwmix, dx, missing dx,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$sufwmix->{_key}		= $key;
		$sufwmix->{_note}		= $sufwmix->{_note}.' key='.$sufwmix->{_key};
		$sufwmix->{_Step}		= $sufwmix->{_Step}.' key='.$sufwmix->{_key};

	} else { 
		print("sufwmix, key, missing key,\n");
	 }
 }


=head2 sub keyg 


=cut

 sub keyg {

	my ( $self,$keyg )		= @_;
	if ( $keyg ne $empty_string ) {

		$sufwmix->{_keyg}		= $keyg;
		$sufwmix->{_note}		= $sufwmix->{_note}.' keyg='.$sufwmix->{_keyg};
		$sufwmix->{_Step}		= $sufwmix->{_Step}.' keyg='.$sufwmix->{_keyg};

	} else { 
		print("sufwmix, keyg, missing keyg,\n");
	 }
 }


=head2 sub vf 


=cut

 sub vf {

	my ( $self,$vf )		= @_;
	if ( $vf ne $empty_string ) {

		$sufwmix->{_vf}		= $vf;
		$sufwmix->{_note}		= $sufwmix->{_note}.' vf='.$sufwmix->{_vf};
		$sufwmix->{_Step}		= $sufwmix->{_Step}.' vf='.$sufwmix->{_vf};

	} else { 
		print("sufwmix, vf, missing vf,\n");
	 }
 }


=head2 sub vmin 


=cut

 sub vmin {

	my ( $self,$vmin )		= @_;
	if ( $vmin ne $empty_string ) {

		$sufwmix->{_vmin}		= $vmin;
		$sufwmix->{_note}		= $sufwmix->{_note}.' vmin='.$sufwmix->{_vmin};
		$sufwmix->{_Step}		= $sufwmix->{_Step}.' vmin='.$sufwmix->{_vmin};

	} else { 
		print("sufwmix, vmin, missing vmin,\n");
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
