package App::SeismicUnixGui::sunix::statsMath::suinterp;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUINTERP - interpolate traces using automatic event picking		
 AUTHOR: Masoud Safari-Zanjani
 DATE:   Dec 10 2013,
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

  suinterp->su.h();
  suinterp->segy.h();
  suinterp->signal.h();

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUINTERP - interpolate traces using automatic event picking		

           suinterp < stdin > stdout					

 ninterp=1    number of traces to output between each pair of input traces
 nxmax=500    maximum number of input traces				
 freq1=4.     starting corner frequency of unaliased range		
 freq2=20.    ending corner frequency of unaliased range		
 deriv=0      =1 means take vertical derivative on pick section        
              (useful if interpolating velocities instead of seismic)  
 linear=0     =0 means use 8 point sinc temporal interpolation         
              =1 means use linear temporal interpolation               
              (useful if interpolating velocities instead of seismic)  
 lent=5       number of time samples to smooth for dip estimate	
 lenx=1       number of traces to smooth for dip estimate		
 lagc=400     number of ms agc for dip estimate			
 xopt=0       0 compute spatial derivative via FFT			
                 (assumes input traces regularly spaced and relatively	
                  noise-free)						
              1 compute spatial derivative via differences		
                 (will work on irregulary spaced data)			
 iopt=0     0 = interpolate
            1 = output low-pass model: useful for QC if interpolator failing
            2 = output dip picks in units of samples/trace		

 verbose=0	verbose = 1 echoes information				

 tmpdir= 	 if non-empty, use the value as a directory path	
		 prefix for storing temporary files; else if the	
	         the CWP_TMPDIR environment variable is set use		
	         its value for the path; else use tmpfile()		

 Notes:								
 This program outputs 'ninterp' interpolated traces between each pair of
 input traces.  The values for lagc, freq1, and freq2 are only used for
 event tracking. The output data will be full bandwidth with no agc.  The
 default parameters typically will do a satisfactory job of interpolation
 for dips up to about 12 ms/trace.  Using a larger value for freq2 causes
 the algorithm to do a better job on the shallow dips, but to fail on the
 steep dips.  Only one dip is assumed at each time sample between each pair
 of input traces.							

 The key assumption used here is that the low frequency data are unaliased
 and can be used for event tracking. Those dip picks are used to interpolate
 the original full-bandwidth data, giving some measure of interpolation
 at higher frequencies which otherwise would be aliased.  Using iopt equal
 to 1 allows you to visually check whether the low-pass picking model is
 aliased.								

 Trace headers for interpolated traces are not updated correctly.	
 The output header for an interpolated traces equals that for the preceding
 trace in the original input data.  The original input traces are passed
 through this module without modification.				

 The place this code is most likely to fail is on the first breaks.	

 Example run:    suplane | suinterp | suxwigb &			



 Credit: John Anderson (visiting scholar from Mobil) July 1994

 Trace header fields accessed: ns, dt


=head2 CHANGES and their DATES

 Version: 0.1
 Juan Lorenzo 0.2 June 3, 2016  Juan lorenzo
 Juan Lorenzo 0.3 July 11 2016 start adding 
               remaining options

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suinterp = {
    _ninterp => '',
    _deriv   => '',
    _freq1   => '',
    _freq2   => '',
    _iopt    => '',
    _lagc    => '',
    _lent    => '',
    _lenx    => '',
    _linear  => '',
    _ninterp => '',
    _nxmax   => '',
    _tmpdir  => '',
    _verbose => '',
    _xopt    => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suinterp->{_Step} = 'suinterp' . $suinterp->{_Step};
    return ( $suinterp->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suinterp->{_note} = 'suinterp' . $suinterp->{_note};
    return ( $suinterp->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suinterp->{_deriv}   = '';
    $suinterp->{_freq1}   = '';
    $suinterp->{_freq2}   = '';
    $suinterp->{_iopt}    = '';
    $suinterp->{_lagc}    = '';
    $suinterp->{_lent}    = '';
    $suinterp->{_lenx}    = '';
    $suinterp->{_linear}  = '';
    $suinterp->{_ninterp} = '';
    $suinterp->{_nxmax}   = '';
    $suinterp->{_tmpdir}  = '';
    $suinterp->{_verbose} = '';
    $suinterp->{_xopt}    = '';
    $suinterp->{_Step}    = '';
    $suinterp->{_note}    = '';
}

=head2 sub deriv 


=cut

sub deriv {

    my ( $self, $deriv ) = @_;

    if ( defined $deriv
        && $deriv ne $empty_string )
    {

        $suinterp->{_deriv} = $deriv;
        $suinterp->{_note} =
          $suinterp->{_note} . ' deriv=' . $suinterp->{_deriv};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' deriv=' . $suinterp->{_deriv};

    }
    else {
        print("suinterp, deriv, missing deriv,\n");
    }
}

=head2 sub fmax 

same as freq2

=cut

sub fmax {

    my ( $self, $freq2 ) = @_;
    if ( defined $freq2
        && $freq2 ne $empty_string )
    {

        $suinterp->{_freq2} = $freq2;
        $suinterp->{_note} =
          $suinterp->{_note} . ' freq2=' . $suinterp->{_freq2};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' freq2=' . $suinterp->{_freq2};

    }
    else {
        print("suinterp, fmax, missing fmax,\n");
    }
}

=head2 sub freq1 


=cut

sub freq1 {

    my ( $self, $freq1 ) = @_;
    if ( defined $freq1
        && $freq1 ne $empty_string )
    {

        $suinterp->{_freq1} = $freq1;
        $suinterp->{_note} =
          $suinterp->{_note} . ' freq1=' . $suinterp->{_freq1};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' freq1=' . $suinterp->{_freq1};

    }
    else {
        print("suinterp, freq1, missing freq1,\n");
    }
}

=head2 sub freq2 


=cut

sub freq2 {

    my ( $self, $freq2 ) = @_;
    if ( defined $freq2
        && $freq2 ne $empty_string )
    {

        $suinterp->{_freq2} = $freq2;
        $suinterp->{_note} =
          $suinterp->{_note} . ' freq2=' . $suinterp->{_freq2};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' freq2=' . $suinterp->{_freq2};

    }
    else {
        print("suinterp, freq2, missing freq2,\n");
    }
}

=head2 sub iopt 


=cut

sub iopt {

    my ( $self, $iopt ) = @_;
    if ( defined $iopt
        && $iopt ne $empty_string )
    {

        $suinterp->{_iopt} = $iopt;
        $suinterp->{_note} =
          $suinterp->{_note} . ' iopt=' . $suinterp->{_iopt};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' iopt=' . $suinterp->{_iopt};

    }
    else {
        print("suinterp, iopt, missing iopt,\n");
    }
}

=head2 sub lagc 


=cut

sub lagc {

    my ( $self, $lagc ) = @_;
    if ( defined $lagc
        && $lagc ne $empty_string )
    {

        $suinterp->{_lagc} = $lagc;
        $suinterp->{_note} =
          $suinterp->{_note} . ' lagc=' . $suinterp->{_lagc};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' lagc=' . $suinterp->{_lagc};

    }
    else {
        print("suinterp, lagc, missing lagc,\n");
    }
}

=head2 sub lent 


=cut

sub lent {

    my ( $self, $lent ) = @_;
    if ( defined $lent
        && $lent ne $empty_string )
    {

        $suinterp->{_lent} = $lent;
        $suinterp->{_note} =
          $suinterp->{_note} . ' lent=' . $suinterp->{_lent};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' lent=' . $suinterp->{_lent};

    }
    else {
        print("suinterp, lent, missing lent,\n");
    }
}

=head2 sub lenx 

  number of traces to smooth 

=cut

sub lenx {

    my ( $self, $lenx ) = @_;
    if ( defined $lenx
        && $lenx ne $empty_string )
    {

        $suinterp->{_lenx} = $lenx;
        $suinterp->{_note} =
          $suinterp->{_note} . ' lenx=' . $suinterp->{_lenx};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' lenx=' . $suinterp->{_lenx};

    }
    else {
        print("suinterp, lenx, missing lenx,\n");
    }
}

=head2 sub linear 


=cut

sub linear {

    my ( $self, $linear ) = @_;
    if ( defined $linear
        && $linear ne $empty_string )
    {

        $suinterp->{_linear} = $linear;
        $suinterp->{_note} =
          $suinterp->{_note} . ' linear=' . $suinterp->{_linear};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' linear=' . $suinterp->{_linear};

    }
    else {
        print("suinterp, linear, missing linear,\n");
    }
}

=head2 sub ninterp 

How many new traces to create between each
existing pair 

=cut

sub ninterp {

    my ( $self, $ninterp ) = @_;
    if ( defined $ninterp
        && $ninterp ne $empty_string )
    {

        $suinterp->{_ninterp} = $ninterp;
        $suinterp->{_note} =
          $suinterp->{_note} . ' ninterp=' . $suinterp->{_ninterp};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' ninterp=' . $suinterp->{_ninterp};

    }
    else {
        print("suinterp, ninterp, missing ninterp,\n");
    }
}

=head2 sub num_new_traces2interp 

     same as ninterp
     number of new traces
     to crate between existant pairs

=cut

sub num_new_traces2interp {

    my ( $self, $ninterp ) = @_;

    if ( defined $ninterp
        && $ninterp ne $empty_string )
    {

        $suinterp->{_ninterp} = $ninterp;
        $suinterp->{_note} =
          $suinterp->{_note} . ' ninterp=' . $suinterp->{_ninterp};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' ninterp=' . $suinterp->{_ninterp};

    }
    else {
        print("suinterp, ninterp, missing ninterp,\n");
    }
}

=head2 sub smooth_ntr 

  same as lenx
  number of traces to smooth 

=cut

sub smooth_ntr {

    my ( $self, $lenx ) = @_;
    if ( defined $lenx
        && $lenx ne $empty_string )
    {

        $suinterp->{_lenx} = $lenx;
        $suinterp->{_note} =
          $suinterp->{_note} . ' lenx=' . $suinterp->{_lenx};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' lenx=' . $suinterp->{_lenx};

    }
    else {
        print("suinterp, lenx, missing lenx,\n");
    }
}

=head2 sub nxmax 


=cut

sub nxmax {

    my ( $self, $nxmax ) = @_;
    if ( defined $nxmax
        && $nxmax ne $empty_string )
    {

        $suinterp->{_nxmax} = $nxmax;
        $suinterp->{_note} =
          $suinterp->{_note} . ' nxmax=' . $suinterp->{_nxmax};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' nxmax=' . $suinterp->{_nxmax};

    }
    else {
        print("suinterp, nxmax, missing nxmax,\n");
    }
}

=head2 sub smooth_ns_t 

  same as lent
  number of samples to smooth in time

=cut

sub smooth_ns_t {

    my ( $self, $lent ) = @_;
    if ( defined $lent
        && $lent ne $empty_string )
    {

        $suinterp->{_lent} = $lent;
        $suinterp->{_note} =
          $suinterp->{_note} . ' lent=' . $suinterp->{_lent};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' lent=' . $suinterp->{_lent};

    }
    else {
        print("suinterp, smooth_ns_t, missing smooth_ns_t,\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ( defined $tmpdir
        && $tmpdir ne $empty_string )
    {

        $suinterp->{_tmpdir} = $tmpdir;
        $suinterp->{_note} =
          $suinterp->{_note} . ' tmpdir=' . $suinterp->{_tmpdir};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' tmpdir=' . $suinterp->{_tmpdir};

    }
    else {
        print("suinterp, tmpdir, missing tmpdir,\n");
    }
}

=head2 sub update_num_traces

 calculate if we know the original trace separation 
 .e.g. 2 m or 2 feet
 input the original trace separation
 return the update trace separation
 estimate the new trace separation after interpolation
 confirm that interpolation parameters exist

=cut

sub update_num_traces {

    my ( $variable, $old_num_traces ) = @_;

    if ( defined $old_num_traces
        && $old_num_traces ne $empty_string )
    {
        $suinterp->{_old_num_traces} = $old_num_traces;

        if ( defined $suinterp->{_ninterp}
            && $suinterp->{_ninterp} ne $empty_string )
        {

            $suinterp->{_update_num_traces} =
              ( $suinterp->{_old_num_traces} - 1 ) * $suinterp->{_ninterp} +
              $suinterp->{_old_num_traces};

        }
        else {
            print("Warning: required number of new interpolated traces\n\n");
        }

        $suinterp->{_note} =
            $suinterp->{_note}
          . ' updated_num_traces='
          . $suinterp->{_update_num_traces};
        print(
            "updated number of traces is $suinterp->{_update_num_traces}\n\n");

        return $suinterp->{_update_num_traces};
    }
}

=head2 sub update_trace_separation

 calculate if we know the original trace separation 
 e.g., 2 m or 2 feet
 input the original trace separation
 return the update trace separation
 estimate the new trace separation after interpolation
 confirm that interpolation parameters exist

 When ninterp=1 
 and interpolation factor=1
	print ("interpolated trace separation is $suinterp->{_update_trace_separation}\n\n");
	print ("interpolation factor  is $suinterp->{_interpolation_factor}\n\n");

=cut

sub update_trace_separation {

    my ( $variable, $old_trace_separation ) = @_;

    if ( defined $old_trace_separation
        && $old_trace_separation ne $empty_string )
    {

        $suinterp->{_old_trace_separation} = $old_trace_separation;

        if ( defined $suinterp->{_ninterp}
            && $suinterp->{_ninterp} ne $empty_string )
        {

            $suinterp->{_interpolation_factor} = $suinterp->{_ninterp} + 1;
            $suinterp->{_update_trace_separation} =
              $suinterp->{_old_trace_separation} /
              $suinterp->{_interpolation_factor};
            $suinterp->{_note} =
                $suinterp->{_note}
              . ' updated_trace_separation='
              . $suinterp->{_update_trace_separation};

            return $suinterp->{_update_trace_separation};

        }
        else {
            print("Warning: requires number of new traces to interpolate \n\n");
        }
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( defined $verbose
        && $verbose ne $empty_string )
    {

        $suinterp->{_verbose} = $verbose;
        $suinterp->{_note} =
          $suinterp->{_note} . ' verbose=' . $suinterp->{_verbose};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' verbose=' . $suinterp->{_verbose};

    }
    else {
        print("suinterp, verbose, missing verbose,\n");
    }
}

=head2 sub xopt 


=cut

sub xopt {

    my ( $self, $xopt ) = @_;
    if ( defined $xopt
        && $xopt ne $empty_string )
    {

        $suinterp->{_xopt} = $xopt;
        $suinterp->{_note} =
          $suinterp->{_note} . ' xopt=' . $suinterp->{_xopt};
        $suinterp->{_Step} =
          $suinterp->{_Step} . ' xopt=' . $suinterp->{_xopt};

    }
    else {
        print("suinterp, xopt, missing xopt,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 12;

    return ($max_index);
}

1;
