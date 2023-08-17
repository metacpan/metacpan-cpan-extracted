package App::SeismicUnixGui::sunix::model::suimpedance;

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
 SUIMPEDANCE - Convert reflection coefficients to impedances.  



 suimpedance <stdin >stdout [optional parameters]		



 Optional Parameters:					  	

 v0=1500.	Velocity at first sample (m/sec)		

 rho0=1.0e6	Density at first sample  (g/m^3)		



 Notes:							

 Implements recursion [1-R(k)]Z(k) = [1+R(k)]Z(k-1).		

 The input traces are assumed to be reflectivities, and thus are

 expected to have amplitude values between -1.0 and 1.0.	





 Credits:

	SEP: Stew Levin



 Trace header fields accessed: ns

 



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

my $suimpedance			= {
	_rho0					=> '',
	_v0					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suimpedance->{_Step}     = 'suimpedance'.$suimpedance->{_Step};
	return ( $suimpedance->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suimpedance->{_note}     = 'suimpedance'.$suimpedance->{_note};
	return ( $suimpedance->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suimpedance->{_rho0}			= '';
		$suimpedance->{_v0}			= '';
		$suimpedance->{_Step}			= '';
		$suimpedance->{_note}			= '';
 }


=head2 sub rho0 


=cut

 sub rho0 {

	my ( $self,$rho0 )		= @_;
	if ( $rho0 ne $empty_string ) {

		$suimpedance->{_rho0}		= $rho0;
		$suimpedance->{_note}		= $suimpedance->{_note}.' rho0='.$suimpedance->{_rho0};
		$suimpedance->{_Step}		= $suimpedance->{_Step}.' rho0='.$suimpedance->{_rho0};

	} else { 
		print("suimpedance, rho0, missing rho0,\n");
	 }
 }


=head2 sub v0 


=cut

 sub v0 {

	my ( $self,$v0 )		= @_;
	if ( $v0 ne $empty_string ) {

		$suimpedance->{_v0}		= $v0;
		$suimpedance->{_note}		= $suimpedance->{_note}.' v0='.$suimpedance->{_v0};
		$suimpedance->{_Step}		= $suimpedance->{_Step}.' v0='.$suimpedance->{_v0};

	} else { 
		print("suimpedance, v0, missing v0,\n");
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
