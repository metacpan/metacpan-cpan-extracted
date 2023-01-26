package App::SeismicUnixGui::sunix::transform::suicepstrum;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME:  SUICEPSTRUM - fft of complex log frequency traces to real time traces
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUICEPSTRUM - fft of complex log frequency traces to real time traces

  suicepstrum <stdin >sdout sign2=-1				

 Required parameters:						
 	none							

 Optional parameter:						
 	sign1=1		sign in exponent of first fft		
 	sign2=-1	sign in exponent of inverse fft		
	sym=0		=1 center  output 			
	dt=tr.dt	time sampling interval (s) from header	
			if not set assumed to be .004s		
 Output traces are normalized by 1/N where N is the fft size.	

 Note:								
 The forward  cepstral transform is the			
   F(t_c) = InvFFT[ln[FFT(F(t))]] 				
 The inverse  cepstral transform is the			
   F(t) = InvFFT[exp[FFT(F(t_c))]] 				

 Here t_c is the cepstral time (quefrency) domain 		

 Credits:
 
   CWP: John Stockwell, Dec 2010 based on
     suifft.c by:
	CWP: Shuki Ronen, Chris Liner, Jack K. Cohen,  c. 1989

 Trace header fields accessed: ns, trid
 Trace header fields modified: ns, trid

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suicepstrum = {
    _dt    => '',
    _sign1 => '',
    _sign2 => '',
    _sym   => '',
    _Step  => '',
    _note  => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suicepstrum->{_Step} = 'suicepstrum' . $suicepstrum->{_Step};
    return ( $suicepstrum->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suicepstrum->{_note} = 'suicepstrum' . $suicepstrum->{_note};
    return ( $suicepstrum->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suicepstrum->{_dt}    = '';
    $suicepstrum->{_sign1} = '';
    $suicepstrum->{_sign2} = '';
    $suicepstrum->{_sym}   = '';
    $suicepstrum->{_Step}  = '';
    $suicepstrum->{_note}  = '';
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ( $dt ne $empty_string ) {

        $suicepstrum->{_dt} = $dt;
        $suicepstrum->{_note} =
          $suicepstrum->{_note} . ' dt=' . $suicepstrum->{_dt};
        $suicepstrum->{_Step} =
          $suicepstrum->{_Step} . ' dt=' . $suicepstrum->{_dt};

    }
    else {
        print("suicepstrum, dt, missing dt,\n");
    }
}

=head2 sub sign1 


=cut

sub sign1 {

    my ( $self, $sign1 ) = @_;
    if ( $sign1 ne $empty_string ) {

        $suicepstrum->{_sign1} = $sign1;
        $suicepstrum->{_note} =
          $suicepstrum->{_note} . ' sign1=' . $suicepstrum->{_sign1};
        $suicepstrum->{_Step} =
          $suicepstrum->{_Step} . ' sign1=' . $suicepstrum->{_sign1};

    }
    else {
        print("suicepstrum, sign1, missing sign1,\n");
    }
}

=head2 sub sign2 


=cut

sub sign2 {

    my ( $self, $sign2 ) = @_;
    if ( $sign2 ne $empty_string ) {

        $suicepstrum->{_sign2} = $sign2;
        $suicepstrum->{_note} =
          $suicepstrum->{_note} . ' sign2=' . $suicepstrum->{_sign2};
        $suicepstrum->{_Step} =
          $suicepstrum->{_Step} . ' sign2=' . $suicepstrum->{_sign2};

    }
    else {
        print("suicepstrum, sign2, missing sign2,\n");
    }
}

=head2 sub sym 


=cut

sub sym {

    my ( $self, $sym ) = @_;
    if ( $sym ne $empty_string ) {

        $suicepstrum->{_sym} = $sym;
        $suicepstrum->{_note} =
          $suicepstrum->{_note} . ' sym=' . $suicepstrum->{_sym};
        $suicepstrum->{_Step} =
          $suicepstrum->{_Step} . ' sym=' . $suicepstrum->{_sym};

    }
    else {
        print("suicepstrum, sym, missing sym,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 3;

    return ($max_index);
}

1;
