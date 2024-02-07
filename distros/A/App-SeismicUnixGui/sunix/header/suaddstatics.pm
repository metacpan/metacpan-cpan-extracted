package App::SeismicUnixGui::sunix::header::suaddstatics;

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
 SUADDSTATICS - ADD random STATICS on seismic data			



 suaddstatics required parameters [optional parameters] > stdout	



 Required parameters:							

 shift=		the static shift will be generated 	 	

			randomly in the interval [+shift,-shif] (ms)	

 sources=		number of source locations			

 receivers=		number of receiver locations			

 cmps=			number of common mid point locations		

 maxfold=		maximum fold of input data			

 datafile=		name and COMPLETE path of the input file	



 Optional parameters:							

 dt=tr.dt			time sampling interval (ms)		

 seed=getpid()		 seed for random number generator		

 verbose=0			=1 print useful information		



 Notes:								

 Input data should be sorted into cdp gathers.				



 SUADDSTATICS applies static time shifts in a surface consistent way on

 seismic data sets. SUADDSTATICS writes the static time shifts in the  

 header field TSTAT. To perform the actual shifts the user should use 	

 the program SUSTATIC after SUADDSTATICS. SUADDSTATICS outputs the	

 corrupted data set to stdout.						



 Header field used by SUADDSTATICS: cdp, sx, gx, tstat, dt.		







 Credits: CWP Wences Gouveia, 11/07/94,  Colorado School of Mines



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

my $suaddstatics			= {
	_cmps					=> '',
	_datafile					=> '',
	_dt					=> '',
	_maxfold					=> '',
	_receivers					=> '',
	_seed					=> '',
	_shift					=> '',
	_sources					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suaddstatics->{_Step}     = 'suaddstatics'.$suaddstatics->{_Step};
	return ( $suaddstatics->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suaddstatics->{_note}     = 'suaddstatics'.$suaddstatics->{_note};
	return ( $suaddstatics->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suaddstatics->{_cmps}			= '';
		$suaddstatics->{_datafile}			= '';
		$suaddstatics->{_dt}			= '';
		$suaddstatics->{_maxfold}			= '';
		$suaddstatics->{_receivers}			= '';
		$suaddstatics->{_seed}			= '';
		$suaddstatics->{_shift}			= '';
		$suaddstatics->{_sources}			= '';
		$suaddstatics->{_verbose}			= '';
		$suaddstatics->{_Step}			= '';
		$suaddstatics->{_note}			= '';
 }


=head2 sub cmps 


=cut

 sub cmps {

	my ( $self,$cmps )		= @_;
	if ( $cmps ne $empty_string ) {

		$suaddstatics->{_cmps}		= $cmps;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' cmps='.$suaddstatics->{_cmps};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' cmps='.$suaddstatics->{_cmps};

	} else { 
		print("suaddstatics, cmps, missing cmps,\n");
	 }
 }


=head2 sub datafile 


=cut

 sub datafile {

	my ( $self,$datafile )		= @_;
	if ( $datafile ne $empty_string ) {

		$suaddstatics->{_datafile}		= $datafile;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' datafile='.$suaddstatics->{_datafile};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' datafile='.$suaddstatics->{_datafile};

	} else { 
		print("suaddstatics, datafile, missing datafile,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suaddstatics->{_dt}		= $dt;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' dt='.$suaddstatics->{_dt};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' dt='.$suaddstatics->{_dt};

	} else { 
		print("suaddstatics, dt, missing dt,\n");
	 }
 }


=head2 sub maxfold 


=cut

 sub maxfold {

	my ( $self,$maxfold )		= @_;
	if ( $maxfold ne $empty_string ) {

		$suaddstatics->{_maxfold}		= $maxfold;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' maxfold='.$suaddstatics->{_maxfold};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' maxfold='.$suaddstatics->{_maxfold};

	} else { 
		print("suaddstatics, maxfold, missing maxfold,\n");
	 }
 }


=head2 sub receivers 


=cut

 sub receivers {

	my ( $self,$receivers )		= @_;
	if ( $receivers ne $empty_string ) {

		$suaddstatics->{_receivers}		= $receivers;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' receivers='.$suaddstatics->{_receivers};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' receivers='.$suaddstatics->{_receivers};

	} else { 
		print("suaddstatics, receivers, missing receivers,\n");
	 }
 }


=head2 sub seed 


=cut

 sub seed {

	my ( $self,$seed )		= @_;
	if ( $seed ne $empty_string ) {

		$suaddstatics->{_seed}		= $seed;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' seed='.$suaddstatics->{_seed};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' seed='.$suaddstatics->{_seed};

	} else { 
		print("suaddstatics, seed, missing seed,\n");
	 }
 }


=head2 sub shift 


=cut

 sub shift {

	my ( $self,$shift )		= @_;
	if ( $shift ne $empty_string ) {

		$suaddstatics->{_shift}		= $shift;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' shift='.$suaddstatics->{_shift};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' shift='.$suaddstatics->{_shift};

	} else { 
		print("suaddstatics, shift, missing shift,\n");
	 }
 }


=head2 sub sources 


=cut

 sub sources {

	my ( $self,$sources )		= @_;
	if ( $sources ne $empty_string ) {

		$suaddstatics->{_sources}		= $sources;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' sources='.$suaddstatics->{_sources};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' sources='.$suaddstatics->{_sources};

	} else { 
		print("suaddstatics, sources, missing sources,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suaddstatics->{_verbose}		= $verbose;
		$suaddstatics->{_note}		= $suaddstatics->{_note}.' verbose='.$suaddstatics->{_verbose};
		$suaddstatics->{_Step}		= $suaddstatics->{_Step}.' verbose='.$suaddstatics->{_verbose};

	} else { 
		print("suaddstatics, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 8;

    return($max_index);
}
 
 
1;
