package App::SeismicUnixGui::sunix::transform::sucepstrum;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUCEPSTRUM - transform to the CEPSTRal domain				
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUCEPSTRUM - transform to the CEPSTRal domain				

  sucepstrum <stdin >sdout sign1=1 					

 Required parameters:							
 none									

 Optional parameters:							
 sign1=1			sign in exponent of fft			
 sign2=-1			sign in exponent of ifft		
 dt=from header		sampling interval			
 verbose=1			=0 to stop advisory messages		

 .... phase unwrapping options .....				   	
 mode=ouphase	Oppenheim's phase unwrapping				
		=suphase simple jump detecting phase unwrapping		
 unwrap=1       |dphase| > pi/unwrap constitutes a phase wrapping	
 	 	=0 no phase unwrapping	(in mode=suphase  only)		
 trend=1	remove linear trend from the unwrapped phase	   	
 zeromean=0     assume phase(0)=0.0, else assume phase is zero mean	
 smooth=0      apply damped least squares smoothing to unwrapped phase 
 r=10     ... damping coefficient, only active when smooth=1           

 Notes:								
 The complex log fft of a function F(t) is given by:			
 clogfft(F(t)) = log(FFT(F(t)) = log|F(omega)| + iphi(omega)		
 where phi(omega) is the unwrapped phase. Note that 0< unwrap<= 1.0 	
 allows phase unwrapping to be tuned, if desired. 			

 The ceptrum is the inverse Fourier transform of the log fft of F(t) 	
 F(t_c) =cepstrum(F(t)) = INVFFT[log(FFT(F(t))]			
                        =INVFFT[log|F(omega)| + iphi(omega)]		
 Here t_c is the cepstral time domain. 				

 To facilitate further processing, the sampling interval		
 in quefrency and first quefrency (0) are set in the			
 output header.							

 Caveats: 								
 No check is made that the data ARE real time traces!			

 Use suminphase to make minimum phase representations of signals 	

 Credits:
      CWP: John Stockwell, June 2013 based on
	sufft by:
	CWP: Shuki Ronen, Chris Liner, Jack K. Cohen
	CENPET: Werner M. Heigl - added well log support
	U Montana: Bob Lankston - added m_unwrap_phase feature

 Note: leave dt set for later inversion

 Trace header fields accessed: ns, dt, d1, f1
 Trace header fields modified: ns, d1, f1, trid

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sucepstrum = {
    _dt       => '',
    _mode     => '',
    _r        => '',
    _sign1    => '',
    _sign2    => '',
    _smooth   => '',
    _trend    => '',
    _unwrap   => '',
    _verbose  => '',
    _zeromean => '',
    _Step     => '',
    _note     => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sucepstrum->{_Step} = 'sucepstrum' . $sucepstrum->{_Step};
    return ( $sucepstrum->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sucepstrum->{_note} = 'sucepstrum' . $sucepstrum->{_note};
    return ( $sucepstrum->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sucepstrum->{_dt}       = '';
    $sucepstrum->{_mode}     = '';
    $sucepstrum->{_r}        = '';
    $sucepstrum->{_sign1}    = '';
    $sucepstrum->{_sign2}    = '';
    $sucepstrum->{_smooth}   = '';
    $sucepstrum->{_trend}    = '';
    $sucepstrum->{_unwrap}   = '';
    $sucepstrum->{_verbose}  = '';
    $sucepstrum->{_zeromean} = '';
    $sucepstrum->{_Step}     = '';
    $sucepstrum->{_note}     = '';
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ( $dt ne $empty_string ) {

        $sucepstrum->{_dt} = $dt;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' dt=' . $sucepstrum->{_dt};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' dt=' . $sucepstrum->{_dt};

    }
    else {
        print("sucepstrum, dt, missing dt,\n");
    }
}

=head2 sub mode 


=cut

sub mode {

    my ( $self, $mode ) = @_;
    if ( $mode ne $empty_string ) {

        $sucepstrum->{_mode} = $mode;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' mode=' . $sucepstrum->{_mode};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' mode=' . $sucepstrum->{_mode};

    }
    else {
        print("sucepstrum, mode, missing mode,\n");
    }
}

=head2 sub r 


=cut

sub r {

    my ( $self, $r ) = @_;
    if ( $r ne $empty_string ) {

        $sucepstrum->{_r} = $r;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' r=' . $sucepstrum->{_r};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' r=' . $sucepstrum->{_r};

    }
    else {
        print("sucepstrum, r, missing r,\n");
    }
}

=head2 sub sign1 


=cut

sub sign1 {

    my ( $self, $sign1 ) = @_;
    if ( $sign1 ne $empty_string ) {

        $sucepstrum->{_sign1} = $sign1;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' sign1=' . $sucepstrum->{_sign1};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' sign1=' . $sucepstrum->{_sign1};

    }
    else {
        print("sucepstrum, sign1, missing sign1,\n");
    }
}

=head2 sub sign2 


=cut

sub sign2 {

    my ( $self, $sign2 ) = @_;
    print("sucepstrum,sign2: $sign2\n");
    if ( defined $sign2 && $sign2 ne $empty_string ) {

        use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
        my $control = control->new();
        $control->set_back_slashBgone($sign2);
        $sign2 = $control->get_back_slashBgone();

        $sucepstrum->{_sign2} = $sign2;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' sign2=' . $sucepstrum->{_sign2};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' sign2=' . $sucepstrum->{_sign2};

    }
    else {
        print("sucepstrum, sign2, missing sign2,\n");
    }
}

=head2 sub smooth 


=cut

sub smooth {

    my ( $self, $smooth ) = @_;
    if ( $smooth ne $empty_string ) {

        $sucepstrum->{_smooth} = $smooth;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' smooth=' . $sucepstrum->{_smooth};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' smooth=' . $sucepstrum->{_smooth};

    }
    else {
        print("sucepstrum, smooth, missing smooth,\n");
    }
}

=head2 sub trend 


=cut

sub trend {

    my ( $self, $trend ) = @_;
    if ( $trend ne $empty_string ) {

        $sucepstrum->{_trend} = $trend;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' trend=' . $sucepstrum->{_trend};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' trend=' . $sucepstrum->{_trend};

    }
    else {
        print("sucepstrum, trend, missing trend,\n");
    }
}

=head2 sub unwrap 


=cut

sub unwrap {

    my ( $self, $unwrap ) = @_;
    if ( $unwrap ne $empty_string ) {

        $sucepstrum->{_unwrap} = $unwrap;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' unwrap=' . $sucepstrum->{_unwrap};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' unwrap=' . $sucepstrum->{_unwrap};

    }
    else {
        print("sucepstrum, unwrap, missing unwrap,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sucepstrum->{_verbose} = $verbose;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' verbose=' . $sucepstrum->{_verbose};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' verbose=' . $sucepstrum->{_verbose};

    }
    else {
        print("sucepstrum, verbose, missing verbose,\n");
    }
}

=head2 sub zeromean 


=cut

sub zeromean {

    my ( $self, $zeromean ) = @_;
    if ( $zeromean ne $empty_string ) {

        $sucepstrum->{_zeromean} = $zeromean;
        $sucepstrum->{_note} =
          $sucepstrum->{_note} . ' zeromean=' . $sucepstrum->{_zeromean};
        $sucepstrum->{_Step} =
          $sucepstrum->{_Step} . ' zeromean=' . $sucepstrum->{_zeromean};

    }
    else {
        print("sucepstrum, zeromean, missing zeromean,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 9;

    return ($max_index);
}

1;
