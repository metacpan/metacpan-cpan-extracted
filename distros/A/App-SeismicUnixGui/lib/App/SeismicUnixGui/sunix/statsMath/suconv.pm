package App::SeismicUnixGui::sunix::statsMath::suconv;

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
 SUCONV - convolution with user-supplied filter			



 suconv <stdin >stdout  filter= [optional parameters]			



 Required parameters: ONE of						

 sufile=		file containing SU trace to use as filter	

 filter=		user-supplied convolution filter (ascii)	



 Optional parameters:							

 panel=0		use only the first trace of sufile		

 			=1 convolve corresponding trace in sufile with	

 			trace in input data				



 Trace header fields accessed: ns					

 Trace header fields modified: ns					



 Notes: It is quietly assumed that the time sampling interval on the	

 single trace and the output traces is the same as that on the traces	

 in the input file.  The sufile may actually have more than one trace,	

 but only the first trace is used in panel=0. In panel=1 the corresponding

 trace from the sufile are convolved with its counterpart in the data.	

 Caveat, in panel=1 there have to be at least as many traces in sufile	

 as in the input data. If not, a warning is returned, and later traces	

 in the dataset are returned unchanged.				



 Examples:								

	suplane | suwind min=12 max=12 >TRACE				

	suconv<DATA sufile=TRACE | ...					

 Here, the su data file, "DATA", is convolved trace by trace with the

 the single su trace, "TRACE".					



	suconv<DATA filter=1,2,1 | ...					

 Here, the su data file, "DATA", is convolved trace by trace with the

 the filter shown.							





 Credits:

	CWP: Jack K. Cohen, Michel Dietrich



  CAVEATS: no space-variable or time-variable capacity.

     The more than one trace allowed in sufile is the

     beginning of a hook to handle the spatially variant case.



 Trace header fields accessed: ns

 Trace header fields modified: ns



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

my $suconv			= {
	_filter					=> '',
	_min					=> '',
	_panel					=> '',
	_sufile					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suconv->{_Step}     = 'suconv'.$suconv->{_Step};
	return ( $suconv->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suconv->{_note}     = 'suconv'.$suconv->{_note};
	return ( $suconv->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suconv->{_filter}			= '';
		$suconv->{_min}			= '';
		$suconv->{_panel}			= '';
		$suconv->{_sufile}			= '';
		$suconv->{_Step}			= '';
		$suconv->{_note}			= '';
 }


=head2 sub filter 


=cut

 sub filter {

	my ( $self,$filter )		= @_;
	if ( $filter ne $empty_string ) {

		$suconv->{_filter}		= $filter;
		$suconv->{_note}		= $suconv->{_note}.' filter='.$suconv->{_filter};
		$suconv->{_Step}		= $suconv->{_Step}.' filter='.$suconv->{_filter};

	} else { 
		print("suconv, filter, missing filter,\n");
	 }
 }


=head2 sub min 


=cut

 sub min {

	my ( $self,$min )		= @_;
	if ( $min ne $empty_string ) {

		$suconv->{_min}		= $min;
		$suconv->{_note}		= $suconv->{_note}.' min='.$suconv->{_min};
		$suconv->{_Step}		= $suconv->{_Step}.' min='.$suconv->{_min};

	} else { 
		print("suconv, min, missing min,\n");
	 }
 }


=head2 sub panel 


=cut

 sub panel {

	my ( $self,$panel )		= @_;
	if ( $panel ne $empty_string ) {

		$suconv->{_panel}		= $panel;
		$suconv->{_note}		= $suconv->{_note}.' panel='.$suconv->{_panel};
		$suconv->{_Step}		= $suconv->{_Step}.' panel='.$suconv->{_panel};

	} else { 
		print("suconv, panel, missing panel,\n");
	 }
 }


=head2 sub sufile 


=cut

 sub sufile {

	my ( $self,$sufile )		= @_;
	if ( $sufile ne $empty_string ) {

		$suconv->{_sufile}		= $sufile;
		$suconv->{_note}		= $suconv->{_note}.' sufile='.$suconv->{_sufile};
		$suconv->{_Step}		= $suconv->{_Step}.' sufile='.$suconv->{_sufile};

	} else { 
		print("suconv, sufile, missing sufile,\n");
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
