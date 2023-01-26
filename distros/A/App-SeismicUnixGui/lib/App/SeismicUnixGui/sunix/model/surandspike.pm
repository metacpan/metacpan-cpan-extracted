package App::SeismicUnixGui::sunix::model::surandspike;

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
 SURANDSPIKE - make a small data set of RANDom SPIKEs 		



   surandspike [optional parameters] > out_data_file  		



 Creates a common offset su data file with random spikes	



 Optional parameters:						

	n1=500 			number of time samples		

	n2=200			number of traces		

 	dt=0.002 		time sample rate in seconds	

	nspk=20			number of spikes per trace	

	amax=0.2		abs(max) spike value		

	mode=1			different spikes on each trace	

				=2 same spikes on each trace	

 	seed=from_clock    	random number seed (integer)    





 Credits:

	ARAMCO: Chris Liner



 Trace header fields set: ns, dt, offset



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

my $surandspike			= {
	_amax					=> '',
	_dt					=> '',
	_mode					=> '',
	_n1					=> '',
	_n2					=> '',
	_nspk					=> '',
	_seed					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$surandspike->{_Step}     = 'surandspike'.$surandspike->{_Step};
	return ( $surandspike->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$surandspike->{_note}     = 'surandspike'.$surandspike->{_note};
	return ( $surandspike->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$surandspike->{_amax}			= '';
		$surandspike->{_dt}			= '';
		$surandspike->{_mode}			= '';
		$surandspike->{_n1}			= '';
		$surandspike->{_n2}			= '';
		$surandspike->{_nspk}			= '';
		$surandspike->{_seed}			= '';
		$surandspike->{_Step}			= '';
		$surandspike->{_note}			= '';
 }


=head2 sub amax 


=cut

 sub amax {

	my ( $self,$amax )		= @_;
	if ( $amax ne $empty_string ) {

		$surandspike->{_amax}		= $amax;
		$surandspike->{_note}		= $surandspike->{_note}.' amax='.$surandspike->{_amax};
		$surandspike->{_Step}		= $surandspike->{_Step}.' amax='.$surandspike->{_amax};

	} else { 
		print("surandspike, amax, missing amax,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$surandspike->{_dt}		= $dt;
		$surandspike->{_note}		= $surandspike->{_note}.' dt='.$surandspike->{_dt};
		$surandspike->{_Step}		= $surandspike->{_Step}.' dt='.$surandspike->{_dt};

	} else { 
		print("surandspike, dt, missing dt,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$surandspike->{_mode}		= $mode;
		$surandspike->{_note}		= $surandspike->{_note}.' mode='.$surandspike->{_mode};
		$surandspike->{_Step}		= $surandspike->{_Step}.' mode='.$surandspike->{_mode};

	} else { 
		print("surandspike, mode, missing mode,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$surandspike->{_n1}		= $n1;
		$surandspike->{_note}		= $surandspike->{_note}.' n1='.$surandspike->{_n1};
		$surandspike->{_Step}		= $surandspike->{_Step}.' n1='.$surandspike->{_n1};

	} else { 
		print("surandspike, n1, missing n1,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$surandspike->{_n2}		= $n2;
		$surandspike->{_note}		= $surandspike->{_note}.' n2='.$surandspike->{_n2};
		$surandspike->{_Step}		= $surandspike->{_Step}.' n2='.$surandspike->{_n2};

	} else { 
		print("surandspike, n2, missing n2,\n");
	 }
 }


=head2 sub nspk 


=cut

 sub nspk {

	my ( $self,$nspk )		= @_;
	if ( $nspk ne $empty_string ) {

		$surandspike->{_nspk}		= $nspk;
		$surandspike->{_note}		= $surandspike->{_note}.' nspk='.$surandspike->{_nspk};
		$surandspike->{_Step}		= $surandspike->{_Step}.' nspk='.$surandspike->{_nspk};

	} else { 
		print("surandspike, nspk, missing nspk,\n");
	 }
 }


=head2 sub seed 


=cut

 sub seed {

	my ( $self,$seed )		= @_;
	if ( $seed ne $empty_string ) {

		$surandspike->{_seed}		= $seed;
		$surandspike->{_note}		= $surandspike->{_note}.' seed='.$surandspike->{_seed};
		$surandspike->{_Step}		= $surandspike->{_Step}.' seed='.$surandspike->{_seed};

	} else { 
		print("surandspike, seed, missing seed,\n");
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
