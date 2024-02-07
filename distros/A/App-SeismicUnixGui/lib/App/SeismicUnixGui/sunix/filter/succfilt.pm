package App::SeismicUnixGui::sunix::filter::succfilt;

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
 SUCCFILT -  FX domain Correlation Coefficient FILTER			



   sucff < stdin > stdout [optional parameters]			



 Optional parameters:							

 cch=1.0		Correlation coefficient high pass value		

 ccl=0.3		Correlation coefficient low pass value		

 key=ep		ensemble identifier				

 padd=25		FFT padding in percentage			



 Notes:                       						

 This program uses "get_gather" and "put_gather" so requires that	

 the  data be sorted into ensembles designated by "key", with the ntr

 field set to the number of traces in each respective ensemble.  	



 Example:                     						

 susort ep offset < data.su > datasorted.su				

 suputgthr dir=Data verbose=1 < datasorted.su				

 sugetgthr dir=Data verbose=1 > dataupdated.su				

 succfilt  < dataupdated.su > ccfiltdata.su				



 (Work in progress, editing required)                 			



 

 Credits:

  Potash Corporation: Balazs Nemeth, Saskatoon Canada. c. 2008







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

my $succfilt			= {
	_cch					=> '',
	_ccl					=> '',
	_dir					=> '',
	_key					=> '',
	_padd					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$succfilt->{_Step}     = 'succfilt'.$succfilt->{_Step};
	return ( $succfilt->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$succfilt->{_note}     = 'succfilt'.$succfilt->{_note};
	return ( $succfilt->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$succfilt->{_cch}			= '';
		$succfilt->{_ccl}			= '';
		$succfilt->{_dir}			= '';
		$succfilt->{_key}			= '';
		$succfilt->{_padd}			= '';
		$succfilt->{_Step}			= '';
		$succfilt->{_note}			= '';
 }


=head2 sub cch 


=cut

 sub cch {

	my ( $self,$cch )		= @_;
	if ( $cch ne $empty_string ) {

		$succfilt->{_cch}		= $cch;
		$succfilt->{_note}		= $succfilt->{_note}.' cch='.$succfilt->{_cch};
		$succfilt->{_Step}		= $succfilt->{_Step}.' cch='.$succfilt->{_cch};

	} else { 
		print("succfilt, cch, missing cch,\n");
	 }
 }


=head2 sub ccl 


=cut

 sub ccl {

	my ( $self,$ccl )		= @_;
	if ( $ccl ne $empty_string ) {

		$succfilt->{_ccl}		= $ccl;
		$succfilt->{_note}		= $succfilt->{_note}.' ccl='.$succfilt->{_ccl};
		$succfilt->{_Step}		= $succfilt->{_Step}.' ccl='.$succfilt->{_ccl};

	} else { 
		print("succfilt, ccl, missing ccl,\n");
	 }
 }


=head2 sub dir 


=cut

 sub dir {

	my ( $self,$dir )		= @_;
	if ( $dir ne $empty_string ) {

		$succfilt->{_dir}		= $dir;
		$succfilt->{_note}		= $succfilt->{_note}.' dir='.$succfilt->{_dir};
		$succfilt->{_Step}		= $succfilt->{_Step}.' dir='.$succfilt->{_dir};

	} else { 
		print("succfilt, dir, missing dir,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$succfilt->{_key}		= $key;
		$succfilt->{_note}		= $succfilt->{_note}.' key='.$succfilt->{_key};
		$succfilt->{_Step}		= $succfilt->{_Step}.' key='.$succfilt->{_key};

	} else { 
		print("succfilt, key, missing key,\n");
	 }
 }


=head2 sub padd 


=cut

 sub padd {

	my ( $self,$padd )		= @_;
	if ( $padd ne $empty_string ) {

		$succfilt->{_padd}		= $padd;
		$succfilt->{_note}		= $succfilt->{_note}.' padd='.$succfilt->{_padd};
		$succfilt->{_Step}		= $succfilt->{_Step}.' padd='.$succfilt->{_padd};

	} else { 
		print("succfilt, padd, missing padd,\n");
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
