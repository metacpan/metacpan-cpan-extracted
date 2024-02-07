package App::SeismicUnixGui::sunix::filter::sufilter;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUFILTER - applies a zero-phase, sine-squared tapered filter		
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   Nov 1 2012,July 27 2015
 DESCRIPTION: sufilter a lists of header words
 or an single value
 Version: 0.0.1
 		  0.0.2 updated to Moose
 		  0.0.3	genearated by sudoc2pm.pl Sept 7 2018

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTESuse L_SU_global_constants();

 SUFILTER - applies a zero-phase, sine-squared tapered filter		

 sufilter <stdin >stdout [optional parameters]         		

 Required parameters:                                         		
       if dt is not set in header, then dt is mandatory        	

 Optional parameters:							
       f=f1,f2,...             array of filter frequencies(HZ) 	
       amps=a1,a2,...          array of filter amplitudes		
       dt = (from header)      time sampling interval (sec)        	
	verbose=0		=1 for advisory messages		

 Defaults:f=.10*(nyquist),.15*(nyquist),.45*(nyquist),.50*(nyquist)	
                        (nyquist calculated internally)		
          amps=0.,1.,...,1.,0.  trapezoid-like bandpass filter		

 Examples of filters:							
 Bandpass:   sufilter <data f=10,20,40,50 | ...			
 Bandreject: sufilter <data f=10,20,30,40 amps=1.,0.,0.,1. | ..	
 Lowpass:    sufilter <data f=10,20,40,50 amps=1.,1.,0.,0. | ...	
 Highpass:   sufilter <data f=10,20,40,50 amps=0.,0.,1.,1. | ...	
 Notch:      sufilter <data f=10,12.5,35,50,60 amps=1.,.5,0.,.5,1. |..	

 Credits:
      CWP: John Stockwell, Jack Cohen
	CENPET: Werner M. Heigl - added well log support

 Possible optimization: Do assignments instead of crmuls where
 filter is 0.0.

 Trace header fields accessed: ns, dt, d1

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get 		 = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};
my $false        = $var->{_false};
my $true         = $var->{_true};

my $sufilter = {
    _amps    => '',
    _dt      => '',
    _error   => '',
    _f       => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    my ($self) = @_;

    if ( defined $sufilter->{_error}
        or $sufilter->{_error} eq $false )
    {

        $sufilter->{_Step} = 'sufilter' . $sufilter->{_Step};
        return ( $sufilter->{_Step} );

    }
    else {
        print("sufilter, Step, error either true or missing \n ");
    }
}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sufilter->{_note} = 'sufilter' . $sufilter->{_note};
    return ( $sufilter->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sufilter->{_amps}    = '';
    $sufilter->{_dt}      = '';
    $sufilter->{_error}   = '';
    $sufilter->{_f}       = '';
    $sufilter->{_verbose} = '';
    $sufilter->{_Step}    = '';
    $sufilter->{_note}    = '';
}

=head2 sub amps 


=cut

sub amps {

    my ( $self, $amps ) = @_;
    if ( $amps ne $empty_string ) {

        $sufilter->{_amps} = $amps;
        $sufilter->{_note} =
          $sufilter->{_note} . ' amps=' . $sufilter->{_amps};
        $sufilter->{_Step} =
          $sufilter->{_Step} . ' amps=' . $sufilter->{_amps};

    }
    else {
        print("sufilter, amps, missing amps,\n");
    }
}

=head2 sub amplitude


=cut

sub amplitude {

    my ( $self, $amps ) = @_;
    if ( $amps ne $empty_string ) {

        $sufilter->{_amps} = $amps;
        $sufilter->{_note} =
          $sufilter->{_note} . ' amps=' . $sufilter->{_amps};
        $sufilter->{_Step} =
          $sufilter->{_Step} . ' amps=' . $sufilter->{_amps};

    }
    else {
        print("sufilter, amps, missing amps,\n");
    }
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ( $dt ne $empty_string ) {

        $sufilter->{_dt}   = $dt;
        $sufilter->{_note} = $sufilter->{_note} . ' dt=' . $sufilter->{_dt};
        $sufilter->{_Step} = $sufilter->{_Step} . ' dt=' . $sufilter->{_dt};

    }
    else {
        print("sufilter, dt, missing dt,\n");
    }
}

=head2 sub f 


=cut

sub f {

    my ( $self, $f ) = @_;
    if ( $f ne $empty_string ) {

        $sufilter->{_f}    = $f;
        $sufilter->{_note} = $sufilter->{_note} . ' f=' . $sufilter->{_f};
        $sufilter->{_Step} = $sufilter->{_Step} . ' f=' . $sufilter->{_f};

    }
    else {
        print("sufilter, f, missing f,\n");
        $sufilter->{_error} = $true;
    }
}

=head2 sub freq 


=cut

sub freq {

    my ( $self, $f ) = @_;
    if ( $f ne $empty_string ) {

        $sufilter->{_f}    = $f;
        $sufilter->{_note} = $sufilter->{_note} . ' f=' . $sufilter->{_f};
        $sufilter->{_Step} = $sufilter->{_Step} . ' f=' . $sufilter->{_f};

    }
    else {
        print("sufilter, f, missing f,\n");
        $sufilter->{_error} = $true;
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sufilter->{_verbose} = $verbose;
        $sufilter->{_note} =
          $sufilter->{_note} . ' verbose=' . $sufilter->{_verbose};
        $sufilter->{_Step} =
          $sufilter->{_Step} . ' verbose=' . $sufilter->{_verbose};

    }
    else {
        print("sufilter, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    # index=3
    my $max_index = 3;

    return ($max_index);
}

1;
