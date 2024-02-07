package App::SeismicUnixGui::sunix::transform::suspecfk;
use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS

  PROGRAM NAME: suspecfk
  AUTHOR: Juan Lorenzo 
  DATE:   July 1 2016 
  DESCRIPTION:  A package that makes using and understanding suspecfk easier
  VERSION: 0.1

=head2 USE 

=head2 Notes

	This Program derives from suspecfk in Seismic Unix
	'_note' keeps track of actions for use in graphics
	'_Step' keeps track of actions for execution in the system

=head2 Example

=head2 Seismic Unix Notes

 SUSPECFK - F-K Fourier SPECtrum of data set			
 								
 suspecfk <infile >outfile [optional parameters]		
								
 Optional parameters:						
								
 dt=from header		time sampling interval		
 dx=from header(d2) or 1.0	spatial sampling interval	
								
 verbose=0	verbose = 1 echoes information			
								
 tmpdir= 	 if non-empty, use the value as a directory path
		 prefix for storing temporary files; else if the
	         the CWP_TMPDIR environment variable is set use	
	         its value for the path; else use tmpfile()	
 								
 Note: To facilitate further processing, the sampling intervals
       in frequency and wavenumber as well as the first	
	frequency (0) and the first wavenumber are set in the	
	output header (as respectively d1, d2, f1, f2).		



Note: The relation: w = 2 pi F is well known, but there	
	doesn't	seem to be a commonly used letter corresponding	
	to F for the spatial conjugate transform variable.  We	
	use K for this.  More specifically we assume a phase:	
		i(w t - k x) = 2 pi i(F t - K x).		
	and F, K define our notion of frequency, wavenumber.	
 								

=cut

my $suspecfk = {
    _dt      => '',
    _dx      => '',
    _note    => '',
    _Step    => '',
    _tmpdir  => '',
    _verbose => ''
};

=pod

=head1 Description of Subroutines

=head2 Subroutine clear
	
	Sets all variable strings to '' (nothing) 

=cut

sub clear {
    $suspecfk->{_dt}      = '';
    $suspecfk->{_dx}      = '';
    $suspecfk->{_note}    = '';
    $suspecfk->{_Step}    = '';
    $suspecfk->{_tmpdir}  = '';
    $suspecfk->{_verbose} = '';
}

=head2 Subroutine dt

      sampling interval

=cut

sub dt {
    my ( $sub, $dt ) = @_;
    if ($dt) {
        $suspecfk->{_dt}   = $dt if defined($dt);
        $suspecfk->{_note} = $suspecfk->{_note} . ' dt=' . $suspecfk->{_dt};
        $suspecfk->{_Step} = $suspecfk->{_Step} . ' dt=' . $suspecfk->{_dt};
    }
}

=head2 Subroutine dx

      sparation between traces

=cut

sub dx {
    my ( $sub, $dx ) = @_;
    if ($dx) {
        $suspecfk->{_dx}   = $dx if defined($dx);
        $suspecfk->{_note} = $suspecfk->{_note} . ' dx=' . $suspecfk->{_dx};
        $suspecfk->{_Step} = $suspecfk->{_Step} . ' dx=' . $suspecfk->{_dx};
    }
}

=head2 Subroutine tmpdir

      work directory which can be defined 

=cut

sub tmpdir {
    my ( $sub, $tmpdir ) = @_;
    if ($tmpdir) {
        $suspecfk->{_tmpdir} = $tmpdir if defined($tmpdir);
        $suspecfk->{_note} =
          $suspecfk->{_note} . ' tmpdir=' . $suspecfk->{_tmpdir};
        $suspecfk->{_Step} =
          $suspecfk->{_Step} . ' tmpdir=' . $suspecfk->{_tmpdir};
    }
}

=head2 Subroutine verbose

      echoes steps during progress of filtering 

=cut

sub verbose {
    my ( $sub, $verbose ) = @_;
    if ($verbose) {
        $suspecfk->{_verbose} = $verbose if defined($verbose);
        $suspecfk->{_note} =
          $suspecfk->{_note} . ' verbose=' . $suspecfk->{_verbose};
        $suspecfk->{_Step} =
          $suspecfk->{_Step} . ' verbose=' . $suspecfk->{_verbose};
    }
}

=head2 Subroutine Step

	Keeps track of actions for execution in the system

=cut

sub Step {
    $suspecfk->{_Step} = 'suspecfk' . $suspecfk->{_Step};
    return $suspecfk->{_Step};
}

=head2 Subroutine note

	Keeps track of actions for possible use in graphics

=cut

sub note {
    $suspecfk->{_note} = $suspecfk->{_note};
    return $suspecfk->{_note};
}

=head2 sub get_max_index

max index = number of input variables -1

=cut

sub get_max_index {
    my ($self) = @_;

    # only file_name : index=6
    my $max_index = 6;

    return ($max_index);
}

1;
