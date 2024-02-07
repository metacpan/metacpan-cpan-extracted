package App::SeismicUnixGui::sunix::filter::sudipfilt;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUDIPFILT - DIP--or better--SLOPE Filter in f-k domain	
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUDIPFILT - DIP--or better--SLOPE Filter in f-k domain	

 sudipfilt <infile >outfile [optional parameters]		

 Required Parameters:						
 dt=(from header)	if not set in header then mandatory	
 dx=(from header, d1)	if not set in header then mandatory	

 Optional parameters:						
 slopes=0.0		monotonically increasing slopes		
 amps=1.0		amplitudes corresponding to slopes	
 bias=0.0		slope made horizontal before filtering	

 verbose=0	verbose = 1 echoes information			

 tmpdir= 	 if non-empty, use the value as a directory path
		 prefix for storing temporary files; else if the
	         the CWP_TMPDIR environment variable is set use	
	         its value for the path; else use tmpfile()	

 Notes:							
 d2 is an acceptable alias for dx in the getpar		

 Slopes are defined by delta_t/delta_x, where delta		
 means change. Units of delta_t and delta_x are the same	
 as dt and dx. It is sometimes useful to fool the program	
 with dx=1 dt=1, thus avoiding units and small slope values.	

 Linear interpolation and constant extrapolation are used to	
 determine amplitudes for slopes that are not specified.	
 Linear moveout is removed before slope filtering to make	
 slopes equal to bias appear horizontal.  This linear moveout	
 is restored after filtering.  The bias parameter may be	
 useful for spatially aliased data.  The slopes parameter is	
 compensated for bias, so you need not change slopes when you	
 change bias.							


 Credits:

	CWP: Dave (algorithm--originally called slopef)
	     Jack (reformatting for SU)

 Trace header fields accessed: ns, dt, d2

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $sudipfilt = {
    _amps    => '',
    _bias    => '',
    _dt      => '',
    _dx      => '',
    _slopes  => '',
    _tmpdir  => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $sudipfilt->{_Step} = 'sudipfilt' . $sudipfilt->{_Step};
    return ( $sudipfilt->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $sudipfilt->{_note} = 'sudipfilt' . $sudipfilt->{_note};
    return ( $sudipfilt->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $sudipfilt->{_amps}    = '';
    $sudipfilt->{_bias}    = '';
    $sudipfilt->{_dt}      = '';
    $sudipfilt->{_dx}      = '';
    $sudipfilt->{_slopes}  = '';
    $sudipfilt->{_tmpdir}  = '';
    $sudipfilt->{_verbose} = '';
    $sudipfilt->{_Step}    = '';
    $sudipfilt->{_note}    = '';
}

=head2 sub amps 


=cut

sub amps {

    my ( $self, $amps ) = @_;
    if ($amps) {

        $sudipfilt->{_amps} = $amps;
        $sudipfilt->{_note} =
          $sudipfilt->{_note} . ' amps=' . $sudipfilt->{_amps};
        $sudipfilt->{_Step} =
          $sudipfilt->{_Step} . ' amps=' . $sudipfilt->{_amps};

    }
    else {
        print("sudipfilt, amps, missing amps,\n");
    }
}

=head2 sub bias 


=cut

sub bias {

    my ( $self, $bias ) = @_;
    if ( $bias ne $empty_string ) {

        $sudipfilt->{_bias} = $bias;
        $sudipfilt->{_note} =
          $sudipfilt->{_note} . ' bias=' . $sudipfilt->{_bias};
        $sudipfilt->{_Step} =
          $sudipfilt->{_Step} . ' bias=' . $sudipfilt->{_bias};

    }
    else {
        print("sudipfilt, bias, missing bias,\n");
    }
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $dt ) = @_;
    if ($dt) {

        $sudipfilt->{_dt} = $dt;
        $sudipfilt->{_note} =
          $sudipfilt->{_note} . ' dt=' . $sudipfilt->{_dt};
        $sudipfilt->{_Step} =
          $sudipfilt->{_Step} . ' dt=' . $sudipfilt->{_dt};

    }
    else {
        print("sudipfilt, dt, missing dt,\n");
    }
}

=head2 sub dx 


=cut

sub dx {

    my ( $self, $dx ) = @_;
    if ($dx) {

        $sudipfilt->{_dx} = $dx;
        $sudipfilt->{_note} =
          $sudipfilt->{_note} . ' dx=' . $sudipfilt->{_dx};
        $sudipfilt->{_Step} =
          $sudipfilt->{_Step} . ' dx=' . $sudipfilt->{_dx};

    }
    else {
        print("sudipfilt, dx, missing dx,\n");
    }
}

=head2 sub slopes 


=cut

sub slopes {

    my ( $self, $slopes ) = @_;
    if ($slopes) {

        $sudipfilt->{_slopes} = $slopes;
        $sudipfilt->{_note} =
          $sudipfilt->{_note} . ' slopes=' . $sudipfilt->{_slopes};
        $sudipfilt->{_Step} =
          $sudipfilt->{_Step} . ' slopes=' . $sudipfilt->{_slopes};

    }
    else {
        print("sudipfilt, slopes, missing slopes,\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ($tmpdir) {

        $sudipfilt->{_tmpdir} = $tmpdir;
        $sudipfilt->{_note} =
          $sudipfilt->{_note} . ' tmpdir=' . $sudipfilt->{_tmpdir};
        $sudipfilt->{_Step} =
          $sudipfilt->{_Step} . ' tmpdir=' . $sudipfilt->{_tmpdir};

    }
    else {
        print("sudipfilt, tmpdir, missing tmpdir,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $sudipfilt->{_verbose} = $verbose;
        $sudipfilt->{_note} =
          $sudipfilt->{_note} . ' verbose=' . $sudipfilt->{_verbose};
        $sudipfilt->{_Step} =
          $sudipfilt->{_Step} . ' verbose=' . $sudipfilt->{_verbose};

    }
    else {
        print("sudipfilt, verbose, missing verbose,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=36
    my $max_index = 36;

    return ($max_index);
}

1;
