package App::SeismicUnixGui::sunix::model::sujitter;

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
 SUJITTER - Add random time shifts to seismic traces			



     sujitter <stdin >stdout  [optional parameters]	 		



 Required parameters:							

	none								

 Optional Parameters:							

 	seed=from_clock    	random number seed (integer)            

	min=1 			minimum random time shift (samples)	

	max=1 			maximum random time shift (samples)	

	pon=1 			shift can be positive or negative	

				=0 shift is positive only		

	fldr=0 			each trace has new shift		

				=1 new shift when fldr header field changes

 Notes:								

 Useful for simulating random statics. See also:  suaddstatics		





 Credits:

	U of Houston: Chris Liner 

	UH:  Chris added fldr, min, pon options 12/10/08





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

my $sujitter			= {
	_fldr					=> '',
	_max					=> '',
	_min					=> '',
	_pon					=> '',
	_seed					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sujitter->{_Step}     = 'sujitter'.$sujitter->{_Step};
	return ( $sujitter->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sujitter->{_note}     = 'sujitter'.$sujitter->{_note};
	return ( $sujitter->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sujitter->{_fldr}			= '';
		$sujitter->{_max}			= '';
		$sujitter->{_min}			= '';
		$sujitter->{_pon}			= '';
		$sujitter->{_seed}			= '';
		$sujitter->{_Step}			= '';
		$sujitter->{_note}			= '';
 }


=head2 sub fldr 


=cut

 sub fldr {

	my ( $self,$fldr )		= @_;
	if ( $fldr ne $empty_string ) {

		$sujitter->{_fldr}		= $fldr;
		$sujitter->{_note}		= $sujitter->{_note}.' fldr='.$sujitter->{_fldr};
		$sujitter->{_Step}		= $sujitter->{_Step}.' fldr='.$sujitter->{_fldr};

	} else { 
		print("sujitter, fldr, missing fldr,\n");
	 }
 }


=head2 sub max 


=cut

 sub max {

	my ( $self,$max )		= @_;
	if ( $max ne $empty_string ) {

		$sujitter->{_max}		= $max;
		$sujitter->{_note}		= $sujitter->{_note}.' max='.$sujitter->{_max};
		$sujitter->{_Step}		= $sujitter->{_Step}.' max='.$sujitter->{_max};

	} else { 
		print("sujitter, max, missing max,\n");
	 }
 }


=head2 sub min 


=cut

 sub min {

	my ( $self,$min )		= @_;
	if ( $min ne $empty_string ) {

		$sujitter->{_min}		= $min;
		$sujitter->{_note}		= $sujitter->{_note}.' min='.$sujitter->{_min};
		$sujitter->{_Step}		= $sujitter->{_Step}.' min='.$sujitter->{_min};

	} else { 
		print("sujitter, min, missing min,\n");
	 }
 }


=head2 sub pon 


=cut

 sub pon {

	my ( $self,$pon )		= @_;
	if ( $pon ne $empty_string ) {

		$sujitter->{_pon}		= $pon;
		$sujitter->{_note}		= $sujitter->{_note}.' pon='.$sujitter->{_pon};
		$sujitter->{_Step}		= $sujitter->{_Step}.' pon='.$sujitter->{_pon};

	} else { 
		print("sujitter, pon, missing pon,\n");
	 }
 }


=head2 sub seed 


=cut

 sub seed {

	my ( $self,$seed )		= @_;
	if ( $seed ne $empty_string ) {

		$sujitter->{_seed}		= $seed;
		$sujitter->{_note}		= $sujitter->{_note}.' seed='.$sujitter->{_seed};
		$sujitter->{_Step}		= $sujitter->{_Step}.' seed='.$sujitter->{_seed};

	} else { 
		print("sujitter, seed, missing seed,\n");
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
