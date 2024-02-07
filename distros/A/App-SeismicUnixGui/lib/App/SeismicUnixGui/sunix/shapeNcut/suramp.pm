package App::SeismicUnixGui::sunix::shapeNcut::suramp;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  Juan Lorenzo (only Perl)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 SURAMP - Linearly taper the start and/or end of traces to zero.	



 suramp <stdin >stdout [optional parameters]				



 Required parameters:							

 	if dt is not set in header, then dt is mandatory		



 Optional parameters							

	tmin=tr.delrt/1000	end of starting ramp (sec)		

	tmax=(nt-1)*dt		beginning of ending ramp (sec)		

 	dt = (from header)	sampling interval (sec)			



 The taper is a linear ramp from 0 to tmin and/or tmax to the		

 end of the trace.  Default is a no-op!				





 Credits:



	CWP: Jack K. Cohen, Ken Larner 



 Trace header fields accessed: ns, dt, delrt



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

my $suramp			= {
	_dt					=> '',
	_tmax					=> '',
	_tmin					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suramp->{_Step}     = 'suramp'.$suramp->{_Step};
	return ( $suramp->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suramp->{_note}     = 'suramp'.$suramp->{_note};
	return ( $suramp->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suramp->{_dt}			= '';
		$suramp->{_tmax}			= '';
		$suramp->{_tmin}			= '';
		$suramp->{_Step}			= '';
		$suramp->{_note}			= '';
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suramp->{_dt}		= $dt;
		$suramp->{_note}		= $suramp->{_note}.' dt='.$suramp->{_dt};
		$suramp->{_Step}		= $suramp->{_Step}.' dt='.$suramp->{_dt};

	} else { 
		print("suramp, dt, missing dt,\n");
	 }
 }


=head2 sub tmax 


=cut

 sub tmax {

	my ( $self,$tmax )		= @_;
	if ( $tmax ne $empty_string ) {

		$suramp->{_tmax}		= $tmax;
		$suramp->{_note}		= $suramp->{_note}.' tmax='.$suramp->{_tmax};
		$suramp->{_Step}		= $suramp->{_Step}.' tmax='.$suramp->{_tmax};

	} else { 
		print("suramp, tmax, missing tmax,\n");
	 }
 }


=head2 sub tmin 


=cut

 sub tmin {

	my ( $self,$tmin )		= @_;
	if ( $tmin ne $empty_string ) {

		$suramp->{_tmin}		= $tmin;
		$suramp->{_note}		= $suramp->{_note}.' tmin='.$suramp->{_tmin};
		$suramp->{_Step}		= $suramp->{_Step}.' tmin='.$suramp->{_tmin};

	} else { 
		print("suramp, tmin, missing tmin,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 2;

    return($max_index);
}
 
 
1;
