package App::SeismicUnixGui::sunix::transform::sugabor;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUGABOR -  Outputs a time-frequency representation of seismic data via
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUGABOR -  Outputs a time-frequency representation of seismic data via
	        the Gabor transform-like multifilter analysis technique 
		presented by Dziewonski, Bloch and  Landisman, 1969.	

    sugabor <stdin >stdout [optional parameters]			

 Required parameters:					 		
	if dt is not set in header, then dt is mandatory		

 Optional parameters:							
	dt=(from header)	time sampling interval (sec)		
	fmin=0			minimum frequency of filter array (hz)	
	fmax=NYQUIST 		maximum frequency of filter array (hz)	
	beta=3.0		ln[filter peak amp/filter endpoint amp]	
	band=.05*NYQUIST	filter bandwidth (hz) 			
	alpha=beta/band^2	filter width parameter			
	verbose=0		=1 supply additional info		
	holder=0		=1 output Holder regularity estimate	
				=2 output linear regularity estimate	

 Notes: This program produces a muiltifilter (as opposed to moving window)
 representation of the instantaneous amplitude of seismic data in the	
 time-frequency domain. (With Gaussian filters, moving window and multi-
 filter analysis can be shown to be equivalent.)			

 An input trace is passed through a collection of Gaussian filters	
 to produce a collection of traces, each representing a discrete frequency
 range in the input data. For each of these narrow bandwidth traces, a 
 quadrature trace is computed via the Hilbert transform. Treating the narrow
 bandwidth trace and its quadrature trace as the real and imaginary parts
 of a "complex" trace permits the "instantaneous" amplitude of each
 narrow bandwidth trace to be compute. The output is thus a representation
 of instantaneous amplitude as a function of time and frequency.	

 Some experimentation with the "band" parameter may necessary to produce
 the desired time-frequency resolution. A good rule of thumb is to run 
 sugabor with the default value for band and view the image. If band is
 too big, then the t-f plot will consist of stripes parallel to the frequency
 axis. Conversely, if band is too small, then the stripes will be parallel
 to the time axis. 							

 Caveat:								
 The Gabor transform is not a wavelet transform, but rather are sharp	
 frame basis. However, it is nearly a Morlet continuous wavelet transform
 so the concept of Holder regularity may have some meaning. If you are	
 computing Holder regularity of, say, a migrated seismic section, then
 set band to 1/3 of the frequency band of your data.			

 Examples:								
    suvibro | sugabor | suximage					
    suvibro | sugabor | suxmovie n1= n2= n3= 				
     (because suxmovie scales it's amplitudes off of the first panel,  
      may have to experiment with the wclip and bclip parameters	
    suvibro | sugabor | supsimage | ... ( your local PostScript utility)


 Credits:

	CWP: John Stockwell, Oct 1994
      CWP: John Stockwell Oct 2004, added holder=1 option
 Algorithm:

 This programs takes an input seismic trace and passes it
 through a collection of truncated Gaussian filters in the frequency
 domain.

 The bandwidth of each filter is given by the parameter "band". The
 decay of these filters is given by "alpha", and the number of filters
 is given by nfilt = (fmax - fmin)/band. The result, upon inverse
 Fourier transforming, is that nfilt traces are created, with each
 trace representing a different frequency band in the original data.

 For each of the resulting bandlimited traces, a quadrature (i.e. pi/2
 phase shifted) trace is computed via the Hilbert transform. The 
 bandlimited trace constitutes a "complex trace", with the bandlimited
 trace being the "real part" and the quadrature trace being the 
 "imaginary part".  The instantaneous amplitude of each bandlimited
 trace is then computed by computing the modulus of each complex trace.
 (See Taner, Koehler, and Sheriff, 1979, for a discussion of complex
 trace analysis.

 The final output for a given input trace is a map of instantaneous
 amplitude as a function of time and frequency.

 This is not a wavelet transform, but rather a redundant frame
 representation.

 References: 	Dziewonski, Bloch, and Landisman, 1969, A technique
		for the analysis of transient seismic signals,
		Bull. Seism. Soc. Am., 1969, vol. 59, no.1, pp.427-444.

		Taner, M., T., Koehler, F., and Sheriff, R., E., 1979,
		Complex seismic trace analysis, Geophysics, vol. 44,
		pp.1041-1063.

 		Chui, C., K.,1992, Introduction to Wavelets, Academic
		Press, New York.

 Trace header fields accessed: ns, dt, trid, ntr
 Trace header fields modified: tracl, tracr, d1, f2, d2, trid, ntr

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sugabor = {
    _alpha   => '',
    _band    => '',
    _beta    => '',
    _dt      => '',
    _fmax    => '',
    _fmin    => '',
    _holder  => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sugabor->{_Step} = 'sugabor' . $sugabor->{_Step};
    return ( $sugabor->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sugabor->{_note} = 'sugabor' . $sugabor->{_note};
    return ( $sugabor->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sugabor->{_alpha}   = '';
    $sugabor->{_band}    = '';
    $sugabor->{_beta}    = '';
    $sugabor->{_dt}      = '';
    $sugabor->{_fmax}    = '';
    $sugabor->{_fmin}    = '';
    $sugabor->{_holder}  = '';
    $sugabor->{_n1}      = '';
    $sugabor->{_nfilt}   = '';
    $sugabor->{_verbose} = '';
    $sugabor->{_Step}    = '';
    $sugabor->{_note}    = '';
}

=head2 sub alpha 


=cut

sub alpha {

    my ( $self, $alpha ) = @_;
    if ( $alpha ne $empty_string ) {

        $sugabor->{_alpha} = $alpha;
        $sugabor->{_note} =
          $sugabor->{_note} . ' alpha=' . $sugabor->{_alpha};
        $sugabor->{_Step} =
          $sugabor->{_Step} . ' alpha=' . $sugabor->{_alpha};

    }
    else {
        print("sugabor, alpha, missing alpha,\n");
    }
}

=head2 sub band 


=cut

sub band {

    my ( $self, $band ) = @_;
    if ( $band ne $empty_string ) {

        $sugabor->{_band} = $band;
        $sugabor->{_note} = $sugabor->{_note} . ' band=' . $sugabor->{_band};
        $sugabor->{_Step} = $sugabor->{_Step} . ' band=' . $sugabor->{_band};

    }
    else {
        print("sugabor, band, missing band,\n");
    }
}

=head2 sub beta 


=cut

sub beta {

    my ( $self, $beta ) = @_;
    if ( $beta ne $empty_string ) {

        $sugabor->{_beta} = $beta;
        $sugabor->{_note} = $sugabor->{_note} . ' beta=' . $sugabor->{_beta};
        $sugabor->{_Step} = $sugabor->{_Step} . ' beta=' . $sugabor->{_beta};

    }
    else {
        print("sugabor, beta, missing beta,\n");
    }
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ( $dt ne $empty_string ) {

        $sugabor->{_dt}   = $dt;
        $sugabor->{_note} = $sugabor->{_note} . ' dt=' . $sugabor->{_dt};
        $sugabor->{_Step} = $sugabor->{_Step} . ' dt=' . $sugabor->{_dt};

    }
    else {
        print("sugabor, dt, missing dt,\n");
    }
}

=head2 sub fmax 


=cut

sub fmax {

    my ( $self, $fmax ) = @_;
    if ( $fmax ne $empty_string ) {

        $sugabor->{_fmax} = $fmax;
        $sugabor->{_note} = $sugabor->{_note} . ' fmax=' . $sugabor->{_fmax};
        $sugabor->{_Step} = $sugabor->{_Step} . ' fmax=' . $sugabor->{_fmax};

    }
    else {
        print("sugabor, fmax, missing fmax,\n");
    }
}

=head2 sub fmin 


=cut

sub fmin {

    my ( $self, $fmin ) = @_;
    if ( $fmin ne $empty_string ) {

        $sugabor->{_fmin} = $fmin;
        $sugabor->{_note} = $sugabor->{_note} . ' fmin=' . $sugabor->{_fmin};
        $sugabor->{_Step} = $sugabor->{_Step} . ' fmin=' . $sugabor->{_fmin};

    }
    else {
        print("sugabor, fmin, missing fmin,\n");
    }
}

=head2 sub holder 


=cut

sub holder {

    my ( $self, $holder ) = @_;
    if ( $holder ne $empty_string ) {

        $sugabor->{_holder} = $holder;
        $sugabor->{_note} =
          $sugabor->{_note} . ' holder=' . $sugabor->{_holder};
        $sugabor->{_Step} =
          $sugabor->{_Step} . ' holder=' . $sugabor->{_holder};

    }
    else {
        print("sugabor, holder, missing holder,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sugabor->{_verbose} = $verbose;
        $sugabor->{_note} =
          $sugabor->{_note} . ' verbose=' . $sugabor->{_verbose};
        $sugabor->{_Step} =
          $sugabor->{_Step} . ' verbose=' . $sugabor->{_verbose};

    }
    else {
        print("sugabor, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 7;

    return ($max_index);
}

1;
