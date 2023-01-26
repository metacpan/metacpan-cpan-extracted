package App::SeismicUnixGui::sunix::transform::sufft;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  SUFFT - fft real time traces to complex frequency traces		
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUFFT - fft real time traces to complex frequency traces		

 suftt <stdin >sdout sign=1 						

 Required parameters:							
 none									

 Optional parameters:							
 sign=1			sign in exponent of fft			
 dt=from header		sampling interval			
 verbose=1		=0 to stop advisory messages			

 Notes: To facilitate further processing, the sampling interval	
 in frequency and first frequency (0) are set in the			
 output header.							

 sufft | suifft is not quite a no-op since the trace			
 length will usually be longer due to fft padding.			

 Caveats: 								
 No check is made that the data IS real time traces!			

 Output is type complex. To view amplitude, phase or real, imaginary	
 parts, use    suamp 							

 Examples: 								
 sufft < stdin | suamp mode=amp | .... 				
 sufft < stdin | suamp mode=phase | .... 				
 sufft < stdin | suamp mode=uphase | .... 				
 sufft < stdin | suamp mode=real | .... 				
 sufft < stdin | suamp mode=imag | .... 				


 Credits:

	CWP: Shuki Ronen, Chris Liner, Jack K. Cohen
	CENPET: Werner M. Heigl - added well log support

 Note: leave dt set for later inversion

 Trace header fields accessed: ns, dt, d1, f1
 Trace header fields modified: ns, d1, f1, trid

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

my $sufft = {
    _dt      => '',
    _sign    => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sufft->{_Step} = 'sufft' . $sufft->{_Step};
    return ( $sufft->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sufft->{_note} = 'sufft' . $sufft->{_note};
    return ( $sufft->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sufft->{_dt}      = '';
    $sufft->{_mode}    = '';
    $sufft->{_sign}    = '';
    $sufft->{_verbose} = '';
    $sufft->{_Step}    = '';
    $sufft->{_note}    = '';
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ($dt) {

        $sufft->{_dt}   = $dt;
        $sufft->{_note} = $sufft->{_note} . ' dt=' . $sufft->{_dt};
        $sufft->{_Step} = $sufft->{_Step} . ' dt=' . $sufft->{_dt};

    }
    else {
        print("sufft, dt, missing dt,\n");
    }
}

=head2 sub sign 


=cut

sub sign {

    my ( $self, $sign ) = @_;
    if ($sign) {

        $sufft->{_sign} = $sign;
        $sufft->{_note} = $sufft->{_note} . ' sign=' . $sufft->{_sign};
        $sufft->{_Step} = $sufft->{_Step} . ' sign=' . $sufft->{_sign};

    }
    else {
        print("sufft, sign, missing sign,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ($verbose) {

        $sufft->{_verbose} = $verbose;
        $sufft->{_note}    = $sufft->{_note} . ' verbose=' . $sufft->{_verbose};
        $sufft->{_Step}    = $sufft->{_Step} . ' verbose=' . $sufft->{_verbose};

    }
    else {
        print("sufft, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    # : index=2
    my $max_index = 2;

    return ($max_index);
}

1;
