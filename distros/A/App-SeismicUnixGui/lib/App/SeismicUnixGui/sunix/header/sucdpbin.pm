package App::SeismicUnixGui::sunix::header::sucdpbin;

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
 SUCDPBIN - Compute CDP bin number					



 sucdpbin <stdin >stdout xline= yline= dcdp=				



 Required parameters:							

 xline=		array of X defining the CDP line		

 yline=		array of Y defining the CDP line		

 dcdp=			distance between bin centers			



 Optional parameters							

 verbose=0		<>0 output informations				

 cdpmin=1001		min cdp bin number				

 distmax=dcdp		search radius					



 xline,yline defines the CDP line made of continuous straight lines. 	

 If a smoother line is required, use unisam to interpolate.		

 Bin centers are located at dcdp constant interval on this line. 	

 Each trace will be numbered with the number of the closest bin. If no  

 bin center is found within the search radius. cdp is set to 0		





 Credits:

 2009 Dominique Rousset - Mohamed Hamza 

      Université de Pau et des Pays de l'Adour (France)





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

my $sucdpbin			= {
	_cdpmin					=> '',
	_dcdp					=> '',
	_distmax					=> '',
	_verbose					=> '',
	_xline					=> '',
	_yline					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sucdpbin->{_Step}     = 'sucdpbin'.$sucdpbin->{_Step};
	return ( $sucdpbin->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sucdpbin->{_note}     = 'sucdpbin'.$sucdpbin->{_note};
	return ( $sucdpbin->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sucdpbin->{_cdpmin}			= '';
		$sucdpbin->{_dcdp}			= '';
		$sucdpbin->{_distmax}			= '';
		$sucdpbin->{_verbose}			= '';
		$sucdpbin->{_xline}			= '';
		$sucdpbin->{_yline}			= '';
		$sucdpbin->{_Step}			= '';
		$sucdpbin->{_note}			= '';
 }


=head2 sub cdpmin 


=cut

 sub cdpmin {

	my ( $self,$cdpmin )		= @_;
	if ( $cdpmin ne $empty_string ) {

		$sucdpbin->{_cdpmin}		= $cdpmin;
		$sucdpbin->{_note}		= $sucdpbin->{_note}.' cdpmin='.$sucdpbin->{_cdpmin};
		$sucdpbin->{_Step}		= $sucdpbin->{_Step}.' cdpmin='.$sucdpbin->{_cdpmin};

	} else { 
		print("sucdpbin, cdpmin, missing cdpmin,\n");
	 }
 }


=head2 sub dcdp 


=cut

 sub dcdp {

	my ( $self,$dcdp )		= @_;
	if ( $dcdp ne $empty_string ) {

		$sucdpbin->{_dcdp}		= $dcdp;
		$sucdpbin->{_note}		= $sucdpbin->{_note}.' dcdp='.$sucdpbin->{_dcdp};
		$sucdpbin->{_Step}		= $sucdpbin->{_Step}.' dcdp='.$sucdpbin->{_dcdp};

	} else { 
		print("sucdpbin, dcdp, missing dcdp,\n");
	 }
 }


=head2 sub distmax 


=cut

 sub distmax {

	my ( $self,$distmax )		= @_;
	if ( $distmax ne $empty_string ) {

		$sucdpbin->{_distmax}		= $distmax;
		$sucdpbin->{_note}		= $sucdpbin->{_note}.' distmax='.$sucdpbin->{_distmax};
		$sucdpbin->{_Step}		= $sucdpbin->{_Step}.' distmax='.$sucdpbin->{_distmax};

	} else { 
		print("sucdpbin, distmax, missing distmax,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sucdpbin->{_verbose}		= $verbose;
		$sucdpbin->{_note}		= $sucdpbin->{_note}.' verbose='.$sucdpbin->{_verbose};
		$sucdpbin->{_Step}		= $sucdpbin->{_Step}.' verbose='.$sucdpbin->{_verbose};

	} else { 
		print("sucdpbin, verbose, missing verbose,\n");
	 }
 }


=head2 sub xline 


=cut

 sub xline {

	my ( $self,$xline )		= @_;
	if ( $xline ne $empty_string ) {

		$sucdpbin->{_xline}		= $xline;
		$sucdpbin->{_note}		= $sucdpbin->{_note}.' xline='.$sucdpbin->{_xline};
		$sucdpbin->{_Step}		= $sucdpbin->{_Step}.' xline='.$sucdpbin->{_xline};

	} else { 
		print("sucdpbin, xline, missing xline,\n");
	 }
 }


=head2 sub yline 


=cut

 sub yline {

	my ( $self,$yline )		= @_;
	if ( $yline ne $empty_string ) {

		$sucdpbin->{_yline}		= $yline;
		$sucdpbin->{_note}		= $sucdpbin->{_note}.' yline='.$sucdpbin->{_yline};
		$sucdpbin->{_Step}		= $sucdpbin->{_Step}.' yline='.$sucdpbin->{_yline};

	} else { 
		print("sucdpbin, yline, missing yline,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 5;

    return($max_index);
}
 
 
1;
