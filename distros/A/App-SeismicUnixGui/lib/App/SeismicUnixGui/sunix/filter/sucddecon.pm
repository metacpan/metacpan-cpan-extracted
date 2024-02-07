package App::SeismicUnixGui::sunix::filter::sucddecon;

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
 SUCDDECON - DECONvolution with user-supplied filter by straightforward

 	      Complex Division in the frequency domain			



 sucddecon <stdin >stdout [optional parameters]			



 Required parameters:							

 filter= 		ascii filter values separated by commas		

 		...or...						

 sufile=		file containing SU traces to use as filter	

                       (must have same number of traces as input data	

 			 for panel=1)					

 Optional parameters:							

 panel=0		use only the first trace of sufile as filter	

 			=1 decon trace by trace an entire gather	

 pnoise=0.001		white noise factor for stabilizing results	

	 				(see below)		 	

 sym=0		not centered, =1 center the output on each trace

 verbose=0		silent, =1 chatty				



 Notes:								

 For given time-domain input data I(t) (stdin) and deconvolution	

 filter F(t), the frequency-domain deconvolved trace can be written as:



	 I(f)		I(f) * complex_conjugate[F(f)]			

 D(f) = ----- ===> D(f) = ------------------------ 			

	 F(f)		|F(f)|^2 + delta				



 The real scalar delta is introduced to prevent the resulting deconvolved

 trace to be dominated by frequencies at which the filter power is close

 to zero. As described above, delta is set to some fraction (pnoise) of 

 the mean of the filter power spectra. Time sampling rate must be the 	

 same in the input data and filter traces. If panel=1 the two input files

 must have the same number of traces. Data and filter traces don't need to

 necessarily have the same number of samples, but the filter trace length

 length be always equal or shorter than the data traces. 		



 Trace header fields accessed: ns, dt					

 Trace header fields modified: none					





 Credits:

	CWP: Ivan Vasconcelos

              some changes by John Stockwell

  CAVEATS: 

	In the option, panel=1 the number of traces in the sufile must be 

	the same as the number of traces on the input.



 Trace header fields accessed: ns,dt

 Trace header fields modified: none



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

my $sucddecon			= {
	_filter					=> '',
	_panel					=> '',
	_pnoise					=> '',
	_sufile					=> '',
	_sym					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sucddecon->{_Step}     = 'sucddecon'.$sucddecon->{_Step};
	return ( $sucddecon->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sucddecon->{_note}     = 'sucddecon'.$sucddecon->{_note};
	return ( $sucddecon->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sucddecon->{_filter}			= '';
		$sucddecon->{_panel}			= '';
		$sucddecon->{_pnoise}			= '';
		$sucddecon->{_sufile}			= '';
		$sucddecon->{_sym}			= '';
		$sucddecon->{_verbose}			= '';
		$sucddecon->{_Step}			= '';
		$sucddecon->{_note}			= '';
 }


=head2 sub filter 


=cut

 sub filter {

	my ( $self,$filter )		= @_;
	if ( $filter ne $empty_string ) {

		$sucddecon->{_filter}		= $filter;
		$sucddecon->{_note}		= $sucddecon->{_note}.' filter='.$sucddecon->{_filter};
		$sucddecon->{_Step}		= $sucddecon->{_Step}.' filter='.$sucddecon->{_filter};

	} else { 
		print("sucddecon, filter, missing filter,\n");
	 }
 }


=head2 sub panel 


=cut

 sub panel {

	my ( $self,$panel )		= @_;
	if ( $panel ne $empty_string ) {

		$sucddecon->{_panel}		= $panel;
		$sucddecon->{_note}		= $sucddecon->{_note}.' panel='.$sucddecon->{_panel};
		$sucddecon->{_Step}		= $sucddecon->{_Step}.' panel='.$sucddecon->{_panel};

	} else { 
		print("sucddecon, panel, missing panel,\n");
	 }
 }


=head2 sub pnoise 


=cut

 sub pnoise {

	my ( $self,$pnoise )		= @_;
	if ( $pnoise ne $empty_string ) {

		$sucddecon->{_pnoise}		= $pnoise;
		$sucddecon->{_note}		= $sucddecon->{_note}.' pnoise='.$sucddecon->{_pnoise};
		$sucddecon->{_Step}		= $sucddecon->{_Step}.' pnoise='.$sucddecon->{_pnoise};

	} else { 
		print("sucddecon, pnoise, missing pnoise,\n");
	 }
 }


=head2 sub sufile 


=cut

 sub sufile {

	my ( $self,$sufile )		= @_;
	if ( $sufile ne $empty_string ) {

		$sucddecon->{_sufile}		= $sufile;
		$sucddecon->{_note}		= $sucddecon->{_note}.' sufile='.$sucddecon->{_sufile};
		$sucddecon->{_Step}		= $sucddecon->{_Step}.' sufile='.$sucddecon->{_sufile};

	} else { 
		print("sucddecon, sufile, missing sufile,\n");
	 }
 }


=head2 sub sym 


=cut

 sub sym {

	my ( $self,$sym )		= @_;
	if ( $sym ne $empty_string ) {

		$sucddecon->{_sym}		= $sym;
		$sucddecon->{_note}		= $sucddecon->{_note}.' sym='.$sucddecon->{_sym};
		$sucddecon->{_Step}		= $sucddecon->{_Step}.' sym='.$sucddecon->{_sym};

	} else { 
		print("sucddecon, sym, missing sym,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sucddecon->{_verbose}		= $verbose;
		$sucddecon->{_note}		= $sucddecon->{_note}.' verbose='.$sucddecon->{_verbose};
		$sucddecon->{_Step}		= $sucddecon->{_Step}.' verbose='.$sucddecon->{_verbose};

	} else { 
		print("sucddecon, verbose, missing verbose,\n");
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
