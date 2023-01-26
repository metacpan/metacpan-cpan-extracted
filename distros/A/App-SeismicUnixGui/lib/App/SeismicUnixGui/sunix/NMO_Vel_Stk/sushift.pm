package App::SeismicUnixGui::sunix::NMO_Vel_Stk::sushift;

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
 SUSHIFT - shifted/windowed traces in time				



 sushift <stdin >stdout [tmin= ] [tmax= ]				



 tmin=			min time to pass				

 tmax=			max time to pass				

 dt=                    sample rate in microseconds 			

 fill=0.0               value to place in padded samples 		



 (defaults for tmin and tmax are calculated from the first trace.	

 verbose=		1 echos parameters to stdout			



 Background :								

 tmin and tmax must be given in seconds				



 In the high resolution single channel seismic profiling the sample 	

 interval is short, the shot rate and the number of samples are high.	

 To reduce the file size the delrt time is changed during a profiling	

 trip. To process and display a seismic section a constant delrt is	

 needed. This program does this job.					



 The SEG-Y header variable delrt (delay in ms) is a short integer.	

 That's why in the example shown below delrt is rounded to 123 !	



   ... | sushift tmin=0.1234 tmax=0.2234 | ...				



 The dt= and fill= options are intended for manipulating velocity	

 volumes in trace format.  In particular models which were hung	

 from the water bottom when created & which then need to have the	

 water layer added.							







 Author:



 Toralf Foerster

 Institut fuer Ostseeforschung Warnemuende

 Sektion Marine Geologie

 Seestrasse 15

 D-18119 Rostock, Germany



 Trace header fields accessed: ns, delrt

 Trace header fields modified: ns, delrt



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

my $sushift			= {
	_dt					=> '',
	_fill					=> '',
	_tmax					=> '',
	_tmin					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sushift->{_Step}     = 'sushift'.$sushift->{_Step};
	return ( $sushift->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sushift->{_note}     = 'sushift'.$sushift->{_note};
	return ( $sushift->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sushift->{_dt}			= '';
		$sushift->{_fill}			= '';
		$sushift->{_tmax}			= '';
		$sushift->{_tmin}			= '';
		$sushift->{_verbose}			= '';
		$sushift->{_Step}			= '';
		$sushift->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$sushift->{_dt}		= $dt;
		$sushift->{_note}		= $sushift->{_note}.' dt='.$sushift->{_dt};
		$sushift->{_Step}		= $sushift->{_Step}.' dt='.$sushift->{_dt};

	} else { 
		print("sushift, dt, missing dt,\n");
	 }
 }


=head2 sub fill 


=cut

 sub fill {

	my ( $self,$fill )		= @_;
	if ( $fill ne $empty_string ) {

		$sushift->{_fill}		= $fill;
		$sushift->{_note}		= $sushift->{_note}.' fill='.$sushift->{_fill};
		$sushift->{_Step}		= $sushift->{_Step}.' fill='.$sushift->{_fill};

	} else { 
		print("sushift, fill, missing fill,\n");
	 }
 }


=head2 sub tmax 


=cut

 sub tmax {

	my ( $self,$tmax )		= @_;
	if ( $tmax ne $empty_string ) {

		$sushift->{_tmax}		= $tmax;
		$sushift->{_note}		= $sushift->{_note}.' tmax='.$sushift->{_tmax};
		$sushift->{_Step}		= $sushift->{_Step}.' tmax='.$sushift->{_tmax};

	} else { 
		print("sushift, tmax, missing tmax,\n");
	 }
 }


=head2 sub tmin 


=cut

 sub tmin {

	my ( $self,$tmin )		= @_;
	if ( $tmin ne $empty_string ) {

		$sushift->{_tmin}		= $tmin;
		$sushift->{_note}		= $sushift->{_note}.' tmin='.$sushift->{_tmin};
		$sushift->{_Step}		= $sushift->{_Step}.' tmin='.$sushift->{_tmin};

	} else { 
		print("sushift, tmin, missing tmin,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sushift->{_verbose}		= $verbose;
		$sushift->{_note}		= $sushift->{_note}.' verbose='.$sushift->{_verbose};
		$sushift->{_Step}		= $sushift->{_Step}.' verbose='.$sushift->{_verbose};

	} else { 
		print("sushift, verbose, missing verbose,\n");
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
