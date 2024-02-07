package App::SeismicUnixGui::sunix::statsMath::sumean;

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
 SUMEAN - get the mean values of data traces				",	



 sumean < stdin > stdout [optional parameters] 			



 Required parameters:							

   power = 2.0		mean to the power				

			(e.g. = 1.0 mean amplitude, = 2.0 mean energy)	



 Optional parameters: 							

   verbose = 0		writes mean value of section to outpar	   	

			= 1 writes mean value of each trace / section to

				outpar					

   outpar=/dev/tty   output parameter file				

   abs = 1             average absolute value 

                       = 0 preserve sign if power=1.0



 Notes:			 					

 Each sample is raised to the requested power, and the sum of all those

 values is averaged for each trace (verbose=1) and the section.	

 The values power=1.0 and power=2.0 are physical, however other powers	

 represent other mathematical L-p norms and may be of use, as well.	





 Credits:

  Bjoern E. Rommel, IKU, Petroleumsforskning / October 1997

		    bjorn.rommel@iku.sintef.no


=head2 User's notes (Juan Lorenzo)


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

my $sumean			= {
	_abs					=> '',
	_outpar					=> '',
	_power					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sumean->{_Step}     = 'sumean'.$sumean->{_Step};
	return ( $sumean->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sumean->{_note}     = 'sumean'.$sumean->{_note};
	return ( $sumean->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sumean->{_abs}			= '';
		$sumean->{_outpar}			= '';
		$sumean->{_power}			= '';
		$sumean->{_verbose}			= '';
		$sumean->{_Step}			= '';
		$sumean->{_note}			= '';
 }


=head2 sub abs 


=cut

 sub abs {

	my ( $self,$abs )		= @_;
	if ( $abs ne $empty_string ) {

		$sumean->{_abs}		= $abs;
		$sumean->{_note}		= $sumean->{_note}.' abs='.$sumean->{_abs};
		$sumean->{_Step}		= $sumean->{_Step}.' abs='.$sumean->{_abs};

	} else { 
		print("sumean, abs, missing abs,\n");
	 }
 }


=head2 sub outpar 


=cut

 sub outpar {

	my ( $self,$outpar )		= @_;
	if ( $outpar ne $empty_string ) {

		$sumean->{_outpar}		= $outpar;
		$sumean->{_note}		= $sumean->{_note}.' outpar='.$sumean->{_outpar};
		$sumean->{_Step}		= $sumean->{_Step}.' outpar='.$sumean->{_outpar};

	} else { 
		print("sumean, outpar, missing outpar,\n");
	 }
 }


=head2 sub power 


=cut

 sub power {

	my ( $self,$power )		= @_;
	if ( $power ne $empty_string ) {

		$sumean->{_power}		= $power;
		$sumean->{_note}		= $sumean->{_note}.' power='.$sumean->{_power};
		$sumean->{_Step}		= $sumean->{_Step}.' power='.$sumean->{_power};

	} else { 
		print("sumean, power, missing power,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sumean->{_verbose}		= $verbose;
		$sumean->{_note}		= $sumean->{_note}.' verbose='.$sumean->{_verbose};
		$sumean->{_Step}		= $sumean->{_Step}.' verbose='.$sumean->{_verbose};

	} else { 
		print("sumean, verbose, missing verbose,\n");
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
