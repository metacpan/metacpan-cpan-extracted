package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sureduce;

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
 SUREDUCE - convert traces to display in reduced time		", 



 sureduce <stdin >stdout rv=					



 Required parameters:						

	dt=tr.dt	if not set in header, dt is mandatory	



 Optional parameters:						

	rv=8.0		reducing velocity in km/sec		",	



 Note: Useful for plotting refraction seismic data. 		

 To remove reduction, do:					

 suflip < reduceddata.su flip=3 | sureduce rv=RV > flip.su	

 suflip < flip.su flip=3 > unreduceddata.su			



 Trace header fields accessed: dt, ns, offset			

 Trace header fields modified: none				





 Author: UC Davis: Mike Begnaud  March 1995





 Trace header fields accessed: ns, dt, offset



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

my $sureduce			= {
	_dt					=> '',
	_flip					=> '',
	_rv					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sureduce->{_Step}     = 'sureduce'.$sureduce->{_Step};
	return ( $sureduce->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sureduce->{_note}     = 'sureduce'.$sureduce->{_note};
	return ( $sureduce->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sureduce->{_dt}			= '';
		$sureduce->{_flip}			= '';
		$sureduce->{_rv}			= '';
		$sureduce->{_Step}			= '';
		$sureduce->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sureduce->{_dt}		= $dt;
		$sureduce->{_note}		= $sureduce->{_note}.' dt='.$sureduce->{_dt};
		$sureduce->{_Step}		= $sureduce->{_Step}.' dt='.$sureduce->{_dt};

	} else { 
		print("sureduce, dt, missing dt,\n");
	 }
 }


=head2 sub flip 


=cut

 sub flip {

	my ( $self,$flip )		= @_;
	if ( $flip ne $empty_string ) {

		$sureduce->{_flip}		= $flip;
		$sureduce->{_note}		= $sureduce->{_note}.' flip='.$sureduce->{_flip};
		$sureduce->{_Step}		= $sureduce->{_Step}.' flip='.$sureduce->{_flip};

	} else { 
		print("sureduce, flip, missing flip,\n");
	 }
 }


=head2 sub rv 


=cut

 sub rv {

	my ( $self,$rv )		= @_;
	if ( $rv ne $empty_string ) {

		$sureduce->{_rv}		= $rv;
		$sureduce->{_note}		= $sureduce->{_note}.' rv='.$sureduce->{_rv};
		$sureduce->{_Step}		= $sureduce->{_Step}.' rv='.$sureduce->{_rv};

	} else { 
		print("sureduce, rv, missing rv,\n");
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
