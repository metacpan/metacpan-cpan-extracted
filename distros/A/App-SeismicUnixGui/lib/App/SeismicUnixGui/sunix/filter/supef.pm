package App::SeismicUnixGui::sunix::filter::supef;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUPEF - Wiener predictive error filtering				
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUPEF - Wiener predictive error filtering				

 supef <stdin >stdout  [optional parameters]				

 Required parameters:							
 dt is mandatory if not set in header			 		

 Optional parameters:							
 cdp= 			CDPs for which minlag, maxlag, pnoise, mincorr, 
			maxcorr are set	(see Notes)			
 minlag=dt		first lag of prediction filter (sec)		
 maxlag=last		lag default is (tmax-tmin)/20			
 pnoise=0.001		relative additive noise level			
 mincorr=tmin		start of autocorrelation window (sec)		
 maxcorr=tmax		end of autocorrelation window (sec)		
 showwiener=0		=1 to show Wiener filter on each trace		
 mix=1,...	 	array of weights (floats) for moving		
				average of the autocorrelations		
 outpar=/dev/null	output parameter file, contains the Wiener filter
 			if showwiener=1 is set				
 method=linear	 for linear interpolation of cdp values			
		       =mono for monotonic cubic interpolation of cdps	
		       =akima for Akima's cubic interpolation of cdps	
		       =spline for cubic spline interpolation of cdps	

 Trace header fields accessed: ns, dt					
 Trace header fields modified: none					

 Notes:								

 1) To apply spiking decon (Wiener filtering with no gap):		

 Run the following command						

    suacor < data.su | suximage perc=95				

 You will see horizontal strip running across the center of your plot.	
 This is the autocorrelation wavelet for each trace. The idea of spiking
 decon is to apply a Wiener filter with no gap to the data to collapse	
 the waveform into a spike. The idea is to pick the width of the	
 autocorrelation waveform _from beginning to end_ (not trough to trough)
 and use this time for MAXLAG_SPIKING:					

  supef < data.su maxlag=MAXLAG_SPIKING  > dataspiked.su		

 2) Prediction Error Filter (i.e. gapped Wiener filtering)		
 The purpose of gapped decon is to suppress repetitions in the data	
 such as those caused by water bottom multiples.			

 To look for the period of the repetitions				

    suacor ntout=1000 < dataspiked.su | suximage perc=95		

 The value of ntout must be larger than the default 100. The idea is	
 to look for repetitions in the autocorrelation. These repetitions will
 appear as a family of parallel stripes above and below the main	
 autocorrelation waveform. Set MAXLAG_PEF to the period of the repetitions
 Set MINLAG_PEF to be slightly larger than the value of MAXLAG_SPIKING	
 that you used to spike the data. In general, the periodicity of the	
 repetitions in the autocorrelation will be the GAP_SIZE 		
 with     MAXLAG_PEF = GAP_SIZE + MINLAG_PEF 				
 some experimentation may be necessary to see sensitivity to choices	
 of MAXLAG_PEF.							

  supef < dataspiked.su minlag=MINLAG_PEF maxlag=MAXLAG_PEF > datapef.su

 Some experimentation may be required to get a satisfactory result.	

 3) It may be effective to sort your data into cdp gathers with susort,
 and perform sunmo correction to the water speed with sunmo, prior to 	
 attempts to suppress water bottom multiples. After applying supef, the
 user should apply inverse nmo to undo the nmo to water speed prior to	
 further processing. Or, do the predictive decon on fully nmo-corrected
 gathers.								

 For a filter expressed as a function of cdp, specify the array	
     cdp=cdp1,cdp2,...							
 and for each cdp specified, specify the minlag and maxlag arrays as	
      minlag=min1,min2,...     maxlag=max1,max2,...   			

 It is required that the number of minlag and maxlag values be equal to
 the number of cdp's specified.  If the number of			
 values in these arrays does not equal the number of cdp's, only the first
 value will be used.							

 Caveat:								
 The showwiener=1 option writes out the wiener filter to outpar, and   
 the prediction error filter to stdout, which is			", 
     1,0,0,...,-wiener[0],...,-wiener[imaxlag-1] 			
 where the sample value of -wiener[0], is  iminlag in the pe-filter.	
 The pe-filter is output as a SU format datafile, one pe-filter for each
 trace input.								


 Credits:
	CWP: Shuki Ronen, Jack K. Cohen, Ken Larner
      CWP: John Stockwell, added mixing feature (April 1998)
      CSM: Tanya Slota (September 2005) added cdp feature

      Technical Reference:
	A. Ziolkowski, "Deconvolution", for value of maxlag default:
		page 91: imaxlag < nt/10.  I took nt/20.

 Notes:
	The prediction error filter is 1,0,0...,0,-wiener[0], ...,
	so no point in explicitly forming it.

	If imaxlag < 2*iminlag - 1, then we don't need to compute the
	autocorrelation for lags:
		imaxlag-iminlag+1, ..., iminlag-1
	It doesn't seem worth the duplicated code to implement this.

 Trace header fields accessed: ns

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '1.0.1';

my $supef = {
    _cdp        => '',
    _minlag     => '',
    _maxlag     => '',
    _pnoise     => '',
    _mincorr    => '',
    _maxcorr    => '',
    _mix        => '',
    _note       => '',
    _Step       => '',
    _outpar     => '',
    _method     => '',
    _ntout      => '',
    _showwiener => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $supef->{_Step} = 'supef ' . $supef->{_Step};
    return ( $supef->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $supef->{_note} = 'supef=' . $supef->{_note};
    return ( $supef->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $supef->{_cdp}        = '';
    $supef->{_minlag}     = '';
    $supef->{_maxlag}     = '';
    $supef->{_pnoise}     = '';
    $supef->{_mincorr}    = '';
    $supef->{_maxcorr}    = '';
    $supef->{_mix}        = '';
    $supef->{_note}       = '';
    $supef->{_Step}       = '';
    $supef->{_outpar}     = '';
    $supef->{_method}     = '';
    $supef->{_ntout}      = '';
    $supef->{_MAXLAG_PEF} = '';
    $supef->{_showwiener} = '';
}

=head2 sub cdp 


=cut

sub cdp {
    my ( $self, $cdp ) = @_;
    if ($cdp) {
        $supef->{_cdp}  = $cdp;
        $supef->{_note} = $supef->{_note} . ' cdp=' . $supef->{_cdp};
        $supef->{_Step} = $supef->{_Step} . ' cdp=' . $supef->{_cdp};
    }
}

=head2 sub minlag 


=cut

sub minlag {
    my ( $self, $minlag ) = @_;
    if ($minlag) {
        $supef->{_minlag} = $minlag;
        $supef->{_note}   = $supef->{_note} . ' minlag=' . $supef->{_minlag};
        $supef->{_Step}   = $supef->{_Step} . '  minlag=' . $supef->{_minlag};
    }
}

=head2 sub maxlag 


=cut

sub maxlag {
    my ( $self, $maxlag ) = @_;
    if ($maxlag) {
        $supef->{_maxlag} = $maxlag;
        $supef->{_note}   = $supef->{_note} . ' maxlag=' . $supef->{_maxlag};
        $supef->{_Step}   = $supef->{_Step} . ' maxlag=' . $supef->{_maxlag};
    }
}

=head2 sub pnoise 


=cut

sub pnoise {
    my ( $self, $pnoise ) = @_;
    if ($pnoise) {
        $supef->{_pnoise} = $pnoise;
        $supef->{_note}   = $supef->{_note} . ' pnoise=' . $supef->{_pnoise};
        $supef->{_Step}   = $supef->{_Step} . ' pnoise=' . $supef->{_pnoise};
    }
}

=head2 sub mincorr 


=cut

sub mincorr {
    my ( $self, $mincorr ) = @_;
    if ($mincorr) {
        $supef->{_mincorr} = $mincorr;
        $supef->{_note}    = $supef->{_note} . ' mincorr=' . $supef->{_mincorr};
        $supef->{_Step}    = $supef->{_Step} . ' mincorr=' . $supef->{_mincorr};
    }
}

=head2 sub maxcorr 


=cut

sub maxcorr {
    my ( $self, $maxcorr ) = @_;
    if ($maxcorr) {
        $supef->{_maxcorr} = $maxcorr;
        $supef->{_note}    = $supef->{_note} . ' maxcorr=' . $supef->{_maxcorr};
        $supef->{_Step}    = $supef->{_Step} . ' maxcorr=' . $supef->{_maxcorr};
    }
}

=head2 sub showwiener 


=cut

sub showwiener {
    my ( $self, $showwiener ) = @_;
    if ($showwiener) {
        $supef->{_showwiener} = $showwiener;
        $supef->{_note} =
          $supef->{_note} . ' wienerout=' . $supef->{_showwiener};
        $supef->{_Step} =
          $supef->{_Step} . ' wienerout=' . $supef->{_showwiener};
    }
}

=head2 sub mix 


=cut

sub mix {
    my ( $self, $mix ) = @_;
    if ($mix) {
        $supef->{_mix}  = $mix;
        $supef->{_note} = $supef->{_note} . ' mix=' . $supef->{_mix};
        $supef->{_Step} = $supef->{_Step} . ' mix=' . $supef->{_mix};
    }
}

=head2 sub outpar 


=cut

sub outpar {
    my ( $self, $outpar ) = @_;
    if ($outpar) {
        $supef->{_outpar} = $outpar;
        $supef->{_note}   = $supef->{_note} . ' outpar=' . $supef->{_outpar};
        $supef->{_Step}   = $supef->{_Step} . ' outpar=' . $supef->{_outpar};
    }
}

=head2 sub method 


=cut

sub method {
    my ( $self, $method ) = @_;
    if ($method) {
        $supef->{_method} = $method;
        $supef->{_note}   = $supef->{_note} . ' method=' . $supef->{_method};
        $supef->{_Step}   = $supef->{_Step} . ' method=' . $supef->{_method};
    }
}

=head2 sub ntout 


=cut

sub ntout {
    my ( $self, $ntout ) = @_;
    if ($ntout) {
        $supef->{_ntout} = $ntout;
        $supef->{_note}  = $supef->{_note} . ' ntout=' . $supef->{_ntout};
        $supef->{_Step}  = $supef->{_Step} . ' ntout=' . $supef->{_ntout};
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
