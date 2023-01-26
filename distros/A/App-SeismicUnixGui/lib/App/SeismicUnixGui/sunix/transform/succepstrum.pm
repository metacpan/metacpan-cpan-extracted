package App::SeismicUnixGui::sunix::transform::succepstrum;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  SUCCEPSTRUM - Compute the complex CEPSTRUM of a seismic trace 	"
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUCCEPSTRUM - Compute the complex CEPSTRUM of a seismic trace 	"

  sucepstrum < stdin > stdout					   	

 Required parameters:						  	
	none								
 Optional parameters:						  	
 sign1=1		sign of real to complex transform		
 sign2=-1		sign of complex to complex (inverse) transform	

 ...phase unwrapping .....						
 mode=ouphase		Oppenheim's algorithm for phase unwrapping	
			=suphase  simple unwrap phase			
 unwrap=1	 |dphase| > pi/unwrap constitutes a phase wrapping	
			(operative only for mode=suphase)		

 trend=1		deramp the phase, =0 do not deramp the phase	
 zeromean=0		assume phase starts at 0,  =1 phase is zero mean

 Notes:								
 The cepstrum is defined as the fourier transform of the the decibel   
 spectrum, as though it were a time domain signal.			

 CC(t) = FT[ln[T(omega)] ] = FT[ ln|T(omega)| + i phi(omega) ]		
	T(omega) = |T(omega)| exp(i phi(omega))				
       phi(omega) = unwrapped phase of T(omega)			

 Phase unwrapping:							
 The mode=ouphase uses the phase unwrapping method of Oppenheim and	
 Schaffer, 1975, which operates integrating the derivative of the phase

 The mode=suphase generates unwrapped phase assuming that jumps	
 in phase larger than dphase=pi/unwrap constitute a phase wrapping. In this case
 the jump in phase is replaced with the average of the jumps in phase  
 on either side of the location where the suspected phase wrapping occurs.

 In either mode, the user has the option of de-ramping the phase, by   
 removing its linear trend via trend=1 and of deciding whether the 	
 phase starts at phase=0 or is of  zero mean via zeromean=1.		


 Author: John Stockwell, Dec 2010
 			based on sucepstrum.c by:

 Credits:
 Balazs Nemeth of Potash Corporation of Saskatchewan Inc. 
			given to CWP in 2008


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $succepstrum = {
    _mode     => '',
    _phase    => '',
    _sign1    => '',
    _sign2    => '',
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

    $succepstrum->{_Step} = 'succepstrum' . $succepstrum->{_Step};
    return ( $succepstrum->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $succepstrum->{_note} = 'succepstrum' . $succepstrum->{_note};
    return ( $succepstrum->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $succepstrum->{_dphase}   = '';
    $succepstrum->{_mode}     = '';
    $succepstrum->{_phase}    = '';
    $succepstrum->{_sign1}    = '';
    $succepstrum->{_sign2}    = '';
    $succepstrum->{_trend}    = '';
    $succepstrum->{_unwrap}   = '';
    $succepstrum->{_zeromean} = '';
    $succepstrum->{_Step}     = '';
    $succepstrum->{_note}     = '';
}

=head2 sub mode 


=cut

sub mode {

    my ( $self, $mode ) = @_;
    if ( $mode ne $empty_string ) {

        $succepstrum->{_mode} = $mode;
        $succepstrum->{_note} =
          $succepstrum->{_note} . ' mode=' . $succepstrum->{_mode};
        $succepstrum->{_Step} =
          $succepstrum->{_Step} . ' mode=' . $succepstrum->{_mode};

    }
    else {
        print("succepstrum, mode, missing mode,\n");
    }
}

=head2 sub phase 


=cut

sub phase {

    my ( $self, $phase ) = @_;
    if ( $phase ne $empty_string ) {

        $succepstrum->{_phase} = $phase;
        $succepstrum->{_note} =
          $succepstrum->{_note} . ' phase=' . $succepstrum->{_phase};
        $succepstrum->{_Step} =
          $succepstrum->{_Step} . ' phase=' . $succepstrum->{_phase};

    }
    else {
        print("succepstrum, phase, missing phase,\n");
    }
}

=head2 sub sign1 


=cut

sub sign1 {

    my ( $self, $sign1 ) = @_;
    if ( $sign1 ne $empty_string ) {

        $succepstrum->{_sign1} = $sign1;
        $succepstrum->{_note} =
          $succepstrum->{_note} . ' sign1=' . $succepstrum->{_sign1};
        $succepstrum->{_Step} =
          $succepstrum->{_Step} . ' sign1=' . $succepstrum->{_sign1};

    }
    else {
        print("succepstrum, sign1, missing sign1,\n");
    }
}

=head2 sub sign2 


=cut

sub sign2 {

    my ( $self, $sign2 ) = @_;
    if ( $sign2 ne $empty_string ) {

        $succepstrum->{_sign2} = $sign2;
        $succepstrum->{_note} =
          $succepstrum->{_note} . ' sign2=' . $succepstrum->{_sign2};
        $succepstrum->{_Step} =
          $succepstrum->{_Step} . ' sign2=' . $succepstrum->{_sign2};

    }
    else {
        print("succepstrum, sign2, missing sign2,\n");
    }
}

=head2 sub trend 


=cut

sub trend {

    my ( $self, $trend ) = @_;
    if ( $trend ne $empty_string ) {

        $succepstrum->{_trend} = $trend;
        $succepstrum->{_note} =
          $succepstrum->{_note} . ' trend=' . $succepstrum->{_trend};
        $succepstrum->{_Step} =
          $succepstrum->{_Step} . ' trend=' . $succepstrum->{_trend};

    }
    else {
        print("succepstrum, trend, missing trend,\n");
    }
}

=head2 sub unwrap 


=cut

sub unwrap {

    my ( $self, $unwrap ) = @_;
    if ( $unwrap ne $empty_string ) {

        $succepstrum->{_unwrap} = $unwrap;
        $succepstrum->{_note} =
          $succepstrum->{_note} . ' unwrap=' . $succepstrum->{_unwrap};
        $succepstrum->{_Step} =
          $succepstrum->{_Step} . ' unwrap=' . $succepstrum->{_unwrap};

    }
    else {
        print("succepstrum, unwrap, missing unwrap,\n");
    }
}

=head2 sub zeromean 


=cut

sub zeromean {

    my ( $self, $zeromean ) = @_;
    if ( $zeromean ne $empty_string ) {

        $succepstrum->{_zeromean} = $zeromean;
        $succepstrum->{_note} =
          $succepstrum->{_note} . ' zeromean=' . $succepstrum->{_zeromean};
        $succepstrum->{_Step} =
          $succepstrum->{_Step} . ' zeromean=' . $succepstrum->{_zeromean};

    }
    else {
        print("succepstrum, zeromean, missing zeromean,\n");
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
