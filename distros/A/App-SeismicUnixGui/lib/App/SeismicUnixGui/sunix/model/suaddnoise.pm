package App::SeismicUnixGui::sunix::model::suaddnoise;

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
 SUADDNOISE - add noise to traces					



 suaddnoise <stdin >stdout  sn=20  noise=gauss  seed=from_clock	



 Required parameters:							

 	if any of f=f1,f2,... and amp=a1,a2,... are specified by the user

	and if dt is not set in header, then dt is mandatory		



 Optional parameters:							

 	sn=20			signal to noise ratio			

 	noise=gauss		noise probability distribution		

 				=flat for uniform; default Gaussian	

 	seed=from_clock		random number seed (integer)		

	f=f1,f2,...		array of filter frequencies (as in sufilter)

	amps=a1,a2,...		array of filter amplitudes		

 	dt= (from header)	time sampling interval (sec)		

	verbose=0		=1 for echoing useful information	



 	tmpdir=	 if non-empty, use the value as a directory path	

		 prefix for storing temporary files; else if the	

	         the CWP_TMPDIR environment variable is set use		

	         its value for the path; else use tmpfile()		



 Notes:								

 Output = Signal +  scale * Noise					



 scale = (1/sn) * (absmax_signal/sqrt(2))/sqrt(energy_per_sample)	



 If the signal is already band-limited, f=f1,f2,... and amps=a1,a2,...	

 can be used, as in sufilter, to bandlimit the noise traces to match	

 the signal band prior to computing the scale defined above.		



 Examples of noise bandlimiting:					

 low freqency:    suaddnoise < data f=40,50 amps=1,0 | ...		

 high freqency:   suaddnoise < data f=40,50 amps=0,1 | ...		

 near monochromatic: suaddnoise < data f=30,40,50 amps=0,1,0 | ...	

 with a notch:    suaddnoise < data f=30,40,50 amps=1,0,1 | ...	

 bandlimited:     suaddnoise < data f=20,30,40,50 amps=0,1,1,0 | ...	





 Credits:

	CWP: Jack Cohen, Brian Sumner, Ken Larner

		John Stockwell (fixed filtered noise option)



 Notes:

	At S/N = 2, the strongest reflector is well delineated, so to

	see something 1/nth as strong as this dominant reflector

	requires S/N = 2*n.



 Trace header field accessed: ns





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

my $suaddnoise			= {
	_N					=> '',
	_Output					=> '',
	_amps					=> '',
	_dt					=> '',
	_f					=> '',
	_noise					=> '',
	_scale					=> '',
	_seed					=> '',
	_sn					=> '',
	_tmpdir					=> '',
	_verbose					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suaddnoise->{_Step}     = 'suaddnoise'.$suaddnoise->{_Step};
	return ( $suaddnoise->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suaddnoise->{_note}     = 'suaddnoise'.$suaddnoise->{_note};
	return ( $suaddnoise->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$suaddnoise->{_N}			= '';
		$suaddnoise->{_Output}			= '';
		$suaddnoise->{_amps}			= '';
		$suaddnoise->{_dt}			= '';
		$suaddnoise->{_f}			= '';
		$suaddnoise->{_noise}			= '';
		$suaddnoise->{_scale}			= '';
		$suaddnoise->{_seed}			= '';
		$suaddnoise->{_sn}			= '';
		$suaddnoise->{_tmpdir}			= '';
		$suaddnoise->{_verbose}			= '';
		$suaddnoise->{_Step}			= '';
		$suaddnoise->{_note}			= '';
 }


=head2 sub N 


=cut

 sub N {

	my ( $self,$N )		= @_;
	if ( $N ne $empty_string ) {

		$suaddnoise->{_N}		= $N;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' N='.$suaddnoise->{_N};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' N='.$suaddnoise->{_N};

	} else { 
		print("suaddnoise, N, missing N,\n");
	 }
 }


=head2 sub Output 


=cut

 sub Output {

	my ( $self,$Output )		= @_;
	if ( $Output ne $empty_string ) {

		$suaddnoise->{_Output}		= $Output;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' Output='.$suaddnoise->{_Output};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' Output='.$suaddnoise->{_Output};

	} else { 
		print("suaddnoise, Output, missing Output,\n");
	 }
 }


=head2 sub amps 


=cut

 sub amps {

	my ( $self,$amps )		= @_;
	if ( $amps ne $empty_string ) {

		$suaddnoise->{_amps}		= $amps;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' amps='.$suaddnoise->{_amps};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' amps='.$suaddnoise->{_amps};

	} else { 
		print("suaddnoise, amps, missing amps,\n");
	 }
 }


=head2 sub dt 


=cut

 sub dt {

	my ( $self,$dt )		= @_;
	if ( $dt ne $empty_string ) {

		$suaddnoise->{_dt}		= $dt;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' dt='.$suaddnoise->{_dt};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' dt='.$suaddnoise->{_dt};

	} else { 
		print("suaddnoise, dt, missing dt,\n");
	 }
 }


=head2 sub f 


=cut

 sub f {

	my ( $self,$f )		= @_;
	if ( $f ne $empty_string ) {

		$suaddnoise->{_f}		= $f;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' f='.$suaddnoise->{_f};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' f='.$suaddnoise->{_f};

	} else { 
		print("suaddnoise, f, missing f,\n");
	 }
 }


=head2 sub noise 


=cut

 sub noise {

	my ( $self,$noise )		= @_;
	if ( $noise ne $empty_string ) {

		$suaddnoise->{_noise}		= $noise;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' noise='.$suaddnoise->{_noise};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' noise='.$suaddnoise->{_noise};

	} else { 
		print("suaddnoise, noise, missing noise,\n");
	 }
 }


=head2 sub scale 


=cut

 sub scale {

	my ( $self,$scale )		= @_;
	if ( $scale ne $empty_string ) {

		$suaddnoise->{_scale}		= $scale;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' scale='.$suaddnoise->{_scale};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' scale='.$suaddnoise->{_scale};

	} else { 
		print("suaddnoise, scale, missing scale,\n");
	 }
 }


=head2 sub seed 


=cut

 sub seed {

	my ( $self,$seed )		= @_;
	if ( $seed ne $empty_string ) {

		$suaddnoise->{_seed}		= $seed;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' seed='.$suaddnoise->{_seed};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' seed='.$suaddnoise->{_seed};

	} else { 
		print("suaddnoise, seed, missing seed,\n");
	 }
 }


=head2 sub sn 


=cut

 sub sn {

	my ( $self,$sn )		= @_;
	if ( $sn ne $empty_string ) {

		$suaddnoise->{_sn}		= $sn;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' sn='.$suaddnoise->{_sn};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' sn='.$suaddnoise->{_sn};

	} else { 
		print("suaddnoise, sn, missing sn,\n");
	 }
 }


=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$suaddnoise->{_tmpdir}		= $tmpdir;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' tmpdir='.$suaddnoise->{_tmpdir};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' tmpdir='.$suaddnoise->{_tmpdir};

	} else { 
		print("suaddnoise, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suaddnoise->{_verbose}		= $verbose;
		$suaddnoise->{_note}		= $suaddnoise->{_note}.' verbose='.$suaddnoise->{_verbose};
		$suaddnoise->{_Step}		= $suaddnoise->{_Step}.' verbose='.$suaddnoise->{_verbose};

	} else { 
		print("suaddnoise, verbose, missing verbose,\n");
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
