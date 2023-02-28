package App::SeismicUnixGui::sunix::filter::sufxdecon;

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
 SUFXDECON - random noise attenuation by FX-DECONvolution              



 sufxdecon <stdin >stdout [...]	                                



 Required Parameters:							



 Optional Parameters:							

 taper=.1	length of taper                                         

 fmin=6.       minimum frequency to process in Hz  (accord to twlen)   

 fmax=.6/(2*dt)  maximum frequency to process in Hz                    

 twlen=entire trace  time window length (minimum .3 for lower freqs)   

 ntrw=10       number of traces in window                              

 ntrf=4        number of traces for filter (smaller than ntrw)         

 verbose=0	=1 for diagnostic print					

 tmpdir=	if non-empty, use the value as a directory path	prefix	

		for storing temporary files; else, if the CWP_TMPDIR	

		environment variable is set, use its value for the path;

		else use tmpfile()					



 Notes: Each trace is transformed to the frequency domain.             

        For each frequency, Wiener filtering, with unity prediction in 

        space, is used to predict the next sample.                     

        At the end of the process, data is mapped back to t-x domain.  ", 







 Credits:			



	CWP: Carlos E. Theodoro (10/07/97)



 References:      							

		Canales(1984):'Random noise reduction' 54th. SEGM	

		Gulunay(1986):'FXDECON and complex Wiener Predicition   

                             filter' 56th. SEGM	                

		Galbraith(1991):'Random noise attenuation by F-X        

                             prediction: a tutorial' 61th. SEGM	



 Algorithm:

	- read data

	- loop over time windows

		- select data

		- FFT (t -> f)

		- loop over space windows

			- select data

			- loop over frequencies

				- autocorelation

				- matrix problem

				- construct filter

				- filter data

			- loop along space window

				- FFT (f -> t)

				- reconstruct data

 	- output data



 Trace header fields accessed: ns, dt, d1

 Trace header fields modified: 





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

my $sufxdecon			= {
	_fmax					=> '',
	_fmin					=> '',
	_ntrf					=> '',
	_ntrw					=> '',
	_taper					=> '',
	_tmpdir					=> '',
	_twlen					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$sufxdecon->{_Step}     = 'sufxdecon'.$sufxdecon->{_Step};
	return ( $sufxdecon->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$sufxdecon->{_note}     = 'sufxdecon'.$sufxdecon->{_note};
	return ( $sufxdecon->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$sufxdecon->{_fmax}			= '';
		$sufxdecon->{_fmin}			= '';
		$sufxdecon->{_ntrf}			= '';
		$sufxdecon->{_ntrw}			= '';
		$sufxdecon->{_taper}			= '';
		$sufxdecon->{_tmpdir}			= '';
		$sufxdecon->{_twlen}			= '';
		$sufxdecon->{_verbose}			= '';
		$sufxdecon->{_Step}			= '';
		$sufxdecon->{_note}			= '';
 }


=head2 sub fmax 


=cut

 sub fmax {

	my ( $self,$fmax )		= @_;
	if ( $fmax ne $empty_string ) {

		$sufxdecon->{_fmax}		= $fmax;
		$sufxdecon->{_note}		= $sufxdecon->{_note}.' fmax='.$sufxdecon->{_fmax};
		$sufxdecon->{_Step}		= $sufxdecon->{_Step}.' fmax='.$sufxdecon->{_fmax};

	} else { 
		print("sufxdecon, fmax, missing fmax,\n");
	 }
 }


=head2 sub fmin 


=cut

 sub fmin {

	my ( $self,$fmin )		= @_;
	if ( $fmin ne $empty_string ) {

		$sufxdecon->{_fmin}		= $fmin;
		$sufxdecon->{_note}		= $sufxdecon->{_note}.' fmin='.$sufxdecon->{_fmin};
		$sufxdecon->{_Step}		= $sufxdecon->{_Step}.' fmin='.$sufxdecon->{_fmin};

	} else { 
		print("sufxdecon, fmin, missing fmin,\n");
	 }
 }


=head2 sub ntrf 


=cut

 sub ntrf {

	my ( $self,$ntrf )		= @_;
	if ( $ntrf ne $empty_string ) {

		$sufxdecon->{_ntrf}		= $ntrf;
		$sufxdecon->{_note}		= $sufxdecon->{_note}.' ntrf='.$sufxdecon->{_ntrf};
		$sufxdecon->{_Step}		= $sufxdecon->{_Step}.' ntrf='.$sufxdecon->{_ntrf};

	} else { 
		print("sufxdecon, ntrf, missing ntrf,\n");
	 }
 }


=head2 sub ntrw 


=cut

 sub ntrw {

	my ( $self,$ntrw )		= @_;
	if ( $ntrw ne $empty_string ) {

		$sufxdecon->{_ntrw}		= $ntrw;
		$sufxdecon->{_note}		= $sufxdecon->{_note}.' ntrw='.$sufxdecon->{_ntrw};
		$sufxdecon->{_Step}		= $sufxdecon->{_Step}.' ntrw='.$sufxdecon->{_ntrw};

	} else { 
		print("sufxdecon, ntrw, missing ntrw,\n");
	 }
 }


=head2 sub taper 


=cut

 sub taper {

	my ( $self,$taper )		= @_;
	if ( $taper ne $empty_string ) {

		$sufxdecon->{_taper}		= $taper;
		$sufxdecon->{_note}		= $sufxdecon->{_note}.' taper='.$sufxdecon->{_taper};
		$sufxdecon->{_Step}		= $sufxdecon->{_Step}.' taper='.$sufxdecon->{_taper};

	} else { 
		print("sufxdecon, taper, missing taper,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$sufxdecon->{_tmpdir}		= $tmpdir;
		$sufxdecon->{_note}		= $sufxdecon->{_note}.' tmpdir='.$sufxdecon->{_tmpdir};
		$sufxdecon->{_Step}		= $sufxdecon->{_Step}.' tmpdir='.$sufxdecon->{_tmpdir};

	} else { 
		print("sufxdecon, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub twlen 


=cut

 sub twlen {

	my ( $self,$twlen )		= @_;
	if ( $twlen ne $empty_string ) {

		$sufxdecon->{_twlen}		= $twlen;
		$sufxdecon->{_note}		= $sufxdecon->{_note}.' twlen='.$sufxdecon->{_twlen};
		$sufxdecon->{_Step}		= $sufxdecon->{_Step}.' twlen='.$sufxdecon->{_twlen};

	} else { 
		print("sufxdecon, twlen, missing twlen,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$sufxdecon->{_verbose}		= $verbose;
		$sufxdecon->{_note}		= $sufxdecon->{_note}.' verbose='.$sufxdecon->{_verbose};
		$sufxdecon->{_Step}		= $sufxdecon->{_Step}.' verbose='.$sufxdecon->{_verbose};

	} else { 
		print("sufxdecon, verbose, missing verbose,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 7;

    return($max_index);
}
 
 
1;
