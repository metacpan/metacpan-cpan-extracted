package App::SeismicUnixGui::sunix::transform::suamp;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUAMP - output amp, phase, real or imag trace from			
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUAMP - output amp, phase, real or imag trace from			
 	(frequency, x) domain data					

 suamp <stdin >stdout mode=amp						

 Required parameters:							
 none									
 Optional parameter:							
 mode=amp	output flag		 				
 		=amp	output amplitude traces				
 		=logamp	output log(amplitude) traces			
 			=phase	output phase traces			
 			=ouphase output unwrapped phase traces (oppenheim)
 			=suphase output unwrapped phase traces (simple)	
 			=real	output real parts			
 	     	=imag	output imag parts	 			
 jack=0	=1  divide value at zero frequency by 2   		
		(operative only for mode=amp)				

 .... phase unwrapping options	..... 					
 unwrap=1	 |dphase| > pi/unwrap constitutes a phase wrapping	
			(operative only for mode=suphase)		
 trend=1	remove linear trend from the unwrapped phase		
 zeromean=0	assume phase(0)=0.0, else assume phase is zero mean	
 smooth=0	apply damped least squares smoothing to unwrapped phase 
 r=10.0	    ... damping coefficient, only active when smooth=1	

 Notes:								
 	The trace returned is half length from 0 to Nyquist. 		

 Example:								
 	sufft <data | suamp >amp_traces					
 Example: 								
	sufft < data > complex_traces					
 	 suamp < complex_traces mode=real > real_traces			
 	 suamp < complex_traces mode=imag > imag_traces			

 Note: the inverse of the above operation is: 				
	suop2 real_traces imag_traces op=zipper > complex_traces	

 Note: Explanation of jack=1 						
 The amplitude spectrum is the modulus of the complex output of	
 the fft. f(0) is thus the average over the range of integration	
 of the transform. For causal functions, or equivalently, half		
 transforms, f(0) is 1/2 of the average over the full range.		
 Most oscillatory functions encountered in wave applications are	
 zero mean, so this is usually not an issue.				

 Note: Phase unwrapping: 						

 The mode=ouphase uses the phase unwrapping method of Oppenheim and	
 Schaffer, 1975. 							
 The mode=suphase generates unwrapped phase assuming that jumps	
 in phase larger than pi/unwrap constitute a phase wrapping.		

 Credits:
	CWP: Shuki Ronen, Jack K. Cohen c.1986

 Notes:
	If efficiency becomes important consider inverting main loop
      and repeating extraction code within the branches of the switch.

 Trace header fields accessed: ns, trid
 Trace header fields modified: ns, trid

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

my $suamp = {
    _jack     => '',
    _mode     => '',
    _op       => '',
    _r        => '',
    _smooth   => '',
    _trend    => '',
    _unwrap   => '',
    _zeromean => '',
    _Step     => '',
    _note     => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suamp->{_Step} = 'suamp' . $suamp->{_Step};
    return ( $suamp->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suamp->{_note} = 'suamp' . $suamp->{_note};
    return ( $suamp->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suamp->{_jack}     = '';
    $suamp->{_mode}     = '';
    $suamp->{_op}       = '';
    $suamp->{_r}        = '';
    $suamp->{_smooth}   = '';
    $suamp->{_trend}    = '';
    $suamp->{_unwrap}   = '';
    $suamp->{_zeromean} = '';
    $suamp->{_Step}     = '';
    $suamp->{_note}     = '';
}

=head2 sub jack 


=cut

sub jack {

    my ( $self, $jack ) = @_;
    if ($jack) {

        $suamp->{_jack} = $jack;
        $suamp->{_note} = $suamp->{_note} . ' jack=' . $suamp->{_jack};
        $suamp->{_Step} = $suamp->{_Step} . ' jack=' . $suamp->{_jack};

    }
    else {
        print("suamp, jack, missing jack,\n");
    }
}

=head2 sub mode 


=cut

sub mode {

    my ( $self, $mode ) = @_;
    if ($mode) {

        $suamp->{_mode} = $mode;
        $suamp->{_note} = $suamp->{_note} . ' mode=' . $suamp->{_mode};
        $suamp->{_Step} = $suamp->{_Step} . ' mode=' . $suamp->{_mode};

    }
    else {
        print("suamp, mode, missing mode,\n");
    }
}


=head2 sub r 


=cut

sub r {

    my ( $self, $r ) = @_;
    if ($r) {

        $suamp->{_r}    = $r;
        $suamp->{_note} = $suamp->{_note} . ' r=' . $suamp->{_r};
        $suamp->{_Step} = $suamp->{_Step} . ' r=' . $suamp->{_r};

    }
    else {
        print("suamp, r, missing r,\n");
    }
}

=head2 sub smooth 


=cut

sub smooth {

    my ( $self, $smooth ) = @_;
    if ($smooth) {

        $suamp->{_smooth} = $smooth;
        $suamp->{_note}   = $suamp->{_note} . ' smooth=' . $suamp->{_smooth};
        $suamp->{_Step}   = $suamp->{_Step} . ' smooth=' . $suamp->{_smooth};

    }
    else {
        print("suamp, smooth, missing smooth,\n");
    }
}

=head2 sub trend 


=cut

sub trend {

    my ( $self, $trend ) = @_;
    if ($trend) {

        $suamp->{_trend} = $trend;
        $suamp->{_note}  = $suamp->{_note} . ' trend=' . $suamp->{_trend};
        $suamp->{_Step}  = $suamp->{_Step} . ' trend=' . $suamp->{_trend};

    }
    else {
        print("suamp, trend, missing trend,\n");
    }
}

=head2 sub unwrap 


=cut

sub unwrap {

    my ( $self, $unwrap ) = @_;
    if ($unwrap) {

        $suamp->{_unwrap} = $unwrap;
        $suamp->{_note}   = $suamp->{_note} . ' unwrap=' . $suamp->{_unwrap};
        $suamp->{_Step}   = $suamp->{_Step} . ' unwrap=' . $suamp->{_unwrap};

    }
    else {
        print("suamp, unwrap, missing unwrap,\n");
    }
}

=head2 sub zeromean 


=cut

sub zeromean {

    my ( $self, $zeromean ) = @_;
    if ($zeromean) {

        $suamp->{_zeromean} = $zeromean;
        $suamp->{_note} =
          $suamp->{_note} . ' zeromean=' . $suamp->{_zeromean};
        $suamp->{_Step} =
          $suamp->{_Step} . ' zeromean=' . $suamp->{_zeromean};

    }
    else {
        print("suamp, zeromean, missing zeromean,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    my $max_index = 6;

    return ($max_index);
}

1;
