package App::SeismicUnixGui::sunix::header::suresstat;
use Moose;
our $VERSION = '0.0.1';

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: suresstat 
AUTHOR: Juan Lorenzo (Perl module only)
 DATE: June 2 2016 
 DESCRIPTION: surface consistent receiver-source static
 Version 1
 Notes: 
 Package name is the same as the file name
 Moose is a package that allows an object-oriented
 syntax to organizing your programs
=========================================================
 MODIFIED BY: Martial Morrison
 DATE: July 14 2016
 DESCRIPTION: Updated for Seismic Unix v44
 Version 1.1

	Added new subroutines: fn, imax, input_file (fn), max_fldr_cdp_tracf (imax), iterations (niter), max_sample_shift (ntpick)
		-These parameters were added to suresstat in SU v44

	Removed outdated subroutines: cfold, rfold, ntraces, nr, nc, nshot, number_of_traces
		-These parameters are no longer part of suresstat

=cut

=head2  Notes from Seismic Unix

 SURESSTAT - Surface consistent source and receiver statics calculation
 									
   suresstat fn=  [optional parameters]				
 									
 Required parameters: 							
 fn=		seismic file				
 ssol=		output file source statics				
 rsol=		output file receiver statics				
 									
 Optional parameters:							
 ntpick=50 	maximum static shift (samples)         			
 niter=5 	number of iterations					
 imax=100000 	largest shot (fldr),reciver(tracf) or cmp(cdp) number	
 sub=0 	subtract super trace 1 from super trace 2 (=1)		
 		sub=0 strongly biases static to a value of 0		
 mode=0 	use global maximum in cross-correllation window		
		=1 choose the peak perc=percent smaller than the global max.
 perc=10. 	percent of global max (used only for mode=1)		
 verbose=0 	print diagnostic output (verbose=1)                     
 									
 Notes:								
 Estimates surface-consistent source and receiver statics, meaning that
 there is one static correction value estimated for each shot and receiver
 position.								
 									
 The method employed here is based on the method of Ronen and Claerbout:
 Geophysics 50, 2759-2767 (1985).					
  									
 The input data are NMO-corrected and sorted into shot gathers (fldr).  
 Receiver id position should be stored in headerword tracf.	        
 The output files are binary files containing the source and receiver	
 statics, as a function of shot number (trace header fldr) and      	
 receiver station number (trace header tracf). 			
  									
 The code builds a supertrace1 and supertrace2, which are subsequently	
 cross-correllated. The program then picks the time lag associated with
 the largest peak in the cross-correllation according to two possible	
 criteria set by the parameter "mode". If mode=0, the maximum of the	
 cross-correllation window is chosen. If mode=1, the program will pick 
 a peak which is up to perc=percent smaller than the global maximum, but
 closer to zero lag than the global maximum.	(Choosing mode=0 is	
 recommended.)								
  									
 The geometry can be irregular: the program simply computes a static 	
 correction for each shot record (fldr=1 to fldr=nshot), with any missing 
 shots being assigned a static of 0.  A static correction for each    	
 receiver station (tracf=1 to tracf=nr) is calculated, with missing    
 receivers again assigned a static of 0.                               
 To window out the most cohherent region use suwind tmin= tmax= and 	
 save the result into a file. This will reduce the amount of time  	
 the code will spent on scaning the file,since the file is much smaller
 The ntpick parameter sets the maximum allowable shift desired (in	
   samples NOT time).							
									
 To apply the static corrections, use sustatic with hdrs=3
	

=cut

=head2 USAGE 1 

 Read a file with one colume of text 
 Read each line

 Example
        $suresstat->ssol($source_statics_output_file);
        $suresstat->rsol($receiver_statics_output_file);
        $suresstat->imax($max_cdp);
        $readfiles-Step();
=cut

my $suresstat = {
    _fn                           => '',
    _input_file                   => '',
    _imax                         => '',
    _max_fldr_cdp_tracf           => '',
    _ntpick                       => '',
    _max_sample_shift             => '',
    _niter                        => '',
    _iterations                   => '',
    _subtract                     => '',
    _mode                         => '',
    _perc                         => '',
    _ssol                         => '',
    _source_statics_file_output   => '',
    _rsol                         => '',
    _receiver_statics_file_output => '',
    _note                         => '',
    _Step                         => '',
    _verbose                      => ''
};

=pod

 Notes:								
 Estimates surface-consistent source and receiver statics, meaning that
 there is one static correction value estimated for each shot and receiver
 position.

 The output files are binary files containing the source and receiver statics.

 Output source (sstat) and receiver (gstat) statics are in microseconds.
 Total statics (tstats) are in milliseconds.

 The method employed here is based on the method of Ronen and Claerbout:
 Geophysics 50, 2759-2767 (1985).	


=head2 sub clear:

 clean hash of its values

=cut

sub clear {
    $suresstat->{_fn}                           = '';
    $suresstat->{_input_file}                   = '';
    $suresstat->{_imax}                         = '';
    $suresstat->{_max_fldr_cdp_tracf}           = '';
    $suresstat->{_ntpick}                       = '';
    $suresstat->{_max_sample_shift}             = '';
    $suresstat->{_niter}                        = '';
    $suresstat->{_iterations}                   = '';
    $suresstat->{_subtract}                     = '';
    $suresstat->{_mode}                         = '';
    $suresstat->{_perc}                         = '';
    $suresstat->{_ssol}                         = '';
    $suresstat->{_source_statics_file_output}   = '';
    $suresstat->{_rsol}                         = '';
    $suresstat->{_receiver_statics_file_output} = '';
    $suresstat->{_note}                         = '';
    $suresstat->{_Step}                         = '';
    $suresstat->{_verbose}                      = '';
}

=head2 subroutine  fn

=cut

sub fn {
    my ( $variable, $fn ) = @_;
    if ($fn) {
        $suresstat->{_fn} = $fn;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' fn=' . $suresstat->{_fn};
        $suresstat->{_note} =
          $suresstat->{_note} . ' fn=' . $suresstat->{_fn};
    }

}

=head2 subroutine  input_file

=cut

sub input_file {
    my ( $variable, $input_file ) = @_;
    if ($input_file) {
        $suresstat->{_input_file} = $input_file;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' fn=' . $suresstat->{_input_file};
        $suresstat->{_note} =
          $suresstat->{_note} . ' input_file=' . $suresstat->{_input_file};
    }

}

=head2 subroutine  mode

=cut

sub mode {
    my ( $variable, $mode ) = @_;
    if ($mode) {
        $suresstat->{_mode} = $mode;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' mode=' . $suresstat->{_mode};
        $suresstat->{_note} =
          $suresstat->{_note} . ' mode=' . $suresstat->{_mode};
    }
}

=head2 subroutine  imax

=cut

sub imax {
    my ( $variable, $imax ) = @_;
    if ($imax) {
        $suresstat->{_imax} = $imax;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' imax=' . $suresstat->{_imax};
        $suresstat->{_note} =
          $suresstat->{_note} . ' imax=' . $suresstat->{_imax};
    }
}

=head2 subroutine  max_fldr_cdp_tracf

=cut

sub max_fldr_cdp_tracf {
    my ( $variable, $max_fldr_cdp_tracf ) = @_;
    if ($max_fldr_cdp_tracf) {
        $suresstat->{_max_fldr_cdp_tracf} = $max_fldr_cdp_tracf;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' imax=' . $suresstat->{_max_fldr_cdp_tracf};
        $suresstat->{_note} =
            $suresstat->{_note}
          . ' max_fldr_cdp_tracf='
          . $suresstat->{_max_fldr_cdp_tracf};
    }
}

=head2 subroutine  niter

=cut

sub niter {
    my ( $variable, $niter ) = @_;

    if ($niter) {
        $suresstat->{_niter} = $niter;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' niter=' . $suresstat->{_niter};
        $suresstat->{_note} =
          $suresstat->{_note} . ' niter=' . $suresstat->{_niter};
    }
}

=head2 subroutine  iterations

=cut

sub iterations {
    my ( $variable, $iterations ) = @_;

    if ($iterations) {
        $suresstat->{_iterations} = $iterations;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' niter=' . $suresstat->{_iterations};
        $suresstat->{_note} =
          $suresstat->{_note} . ' iterations=' . $suresstat->{_iterations};
    }
}

=head2 subroutine  note

=cut

sub note {
    my ( $variable, $note ) = @_;
    $suresstat->{_note} = $note;
    return $suresstat->{_note};
}

=head2 subroutine  ntpick

=cut

sub ntpick {

    my ( $variable, $ntpick ) = @_;
    if ($ntpick) {
        $suresstat->{_ntpick} = $ntpick;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' ntpick=' . $suresstat->{_ntpick};
        $suresstat->{_note} =
          $suresstat->{_note} . ' ntpick=' . $suresstat->{_ntpick};
    }
}

=head2 subroutine  max_sample_shift

=cut

sub max_sample_shift {

    my ( $variable, $max_sample_shift ) = @_;
    if ($max_sample_shift) {
        $suresstat->{_max_sample_shift} = $max_sample_shift;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' ntpick=' . $suresstat->{_max_sample_shift};
        $suresstat->{_note} =
            $suresstat->{_note}
          . ' max_sample_shift='
          . $suresstat->{_max_sample_shift};
    }
}

=head2 subroutine  perc

=cut

sub perc {
    my ( $variable, $perc ) = @_;
    if ($perc) {
        $suresstat->{_perc} = $perc;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' perc=' . $suresstat->{_perc};
        $suresstat->{_note} =
          $suresstat->{_note} . ' perc=' . $suresstat->{_perc};
    }
}

=head2 subroutine receiver_statics_output_file

=cut

sub receiver_statics_file_output {
    my ( $variable, $receiver_statics_file_output ) = @_;
    if ($receiver_statics_file_output) {
        $suresstat->{_receiver_statics_file_output} =
          $receiver_statics_file_output;
        print 'receiver_statics_file_output='
          . $receiver_statics_file_output . "\n\n";
        $suresstat->{_Step} =
            $suresstat->{_Step}
          . ' rsol='
          . $suresstat->{_receiver_statics_file_output};
        $suresstat->{_note} =
            $suresstat->{_note}
          . ' receiver_statics_file_output='
          . $suresstat->{_receiver_statics_file_output};
    }
}

=head2 subroutine rsol

=cut

sub rsol {
    my ( $variable, $rsol ) = @_;
    if ($rsol) {
        $suresstat->{_rsol} = $rsol;
        print 'rsol=' . $rsol . "\n\n";
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' rsol=' . $suresstat->{_rsol};
        $suresstat->{_note} =
            $suresstat->{_note}
          . ' receiver_statics_file_output='
          . $suresstat->{_rsol};
    }
}

=head2 subroutine ssol

=cut

sub source_statics_file_output {
    my ( $variable, $source_statics_file_output ) = @_;
    if ($source_statics_file_output) {
        $suresstat->{_source_statics_file_output} = $source_statics_file_output;
        print 'source_statics_file_output='
          . $source_statics_file_output . "\n\n";
        $suresstat->{_Step} =
            $suresstat->{_Step}
          . ' ssol='
          . $suresstat->{_source_statics_file_output};
        $suresstat->{_note} =
            $suresstat->{_note}
          . ' ssol='
          . $suresstat->{_source_statics_file_output};
    }
}

=head2 subroutine source_statics_file

=cut

sub ssol {
    my ( $variable, $ssol ) = @_;
    if ($ssol) {
        $suresstat->{_ssol} = $ssol;
        print 'ssol=' . $ssol . "\n\n";
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' ssol=' . $suresstat->{_ssol};
        $suresstat->{_note} =
            $suresstat->{_note}
          . ' source_statics_file_output='
          . $suresstat->{_ssol};
    }
}

=head2 subroutine sub

=cut

sub subtract {
    my ( $variable, $subtract ) = @_;
    if ($subtract) {
        $suresstat->{_subtract} = $subtract;
        print 'subtract=' . $subtract . "\n\n";
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' sub=' . $suresstat->{_subtract};
        $suresstat->{_note} =
          $suresstat->{_note} . ' subtract=' . $suresstat->{_subtract};
    }
}

=head2 subroutine  Step

=cut

sub Step {

    $suresstat->{_Step} = 'suresstat ' . $suresstat->{_Step};
    return $suresstat->{_Step};
}

=head2 subroutine  verbose

=cut

sub verbose {

    my ( $variable, $verbose ) = @_;
    if ($verbose) {
        $suresstat->{_verbose} = $verbose;
        $suresstat->{_Step} =
          $suresstat->{_Step} . ' verbose=' . $suresstat->{_verbose};
        $suresstat->{_note} =
          $suresstat->{_note} . ' verbose=' . $suresstat->{_verbose};
    }
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
