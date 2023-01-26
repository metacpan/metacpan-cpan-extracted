package App::SeismicUnixGui::sunix::statsMath::suxmax;


=head1 DOCUMENTATION

=head2 SYNOPSIS

PACKAGE NAME:  SUXMAX - X-windows graph of the MAX, min, or absolute max value on	
AUTHOR: Juan Lorenzo
DATE:   
DESCRIPTION:
Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUXMAX - X-windows graph of the MAX, min, or absolute max value on	
	each trace of a SEGY (SU) data set				

   suxmax <stdin [optional parameters]					

 Optional parameters: 							
 mode=max		max value					
 			=min min value					
 			=abs absolute max value				

 n2=tr.ntr or number of traces in the data set (ntr is an alias for n2)

 d1=tr.d1 or tr.dt/10^6	sampling interval in the fast dimension	
   =.004 for seismic 		(if not set)				
   =1.0 for nonseismic		(if not set)				

 d2=tr.d2			sampling interval in the slow dimension	
   =1.0 			(if not set)				

 f1=tr.f1 or tr.delrt/10^3 or 0.0  first sample in the fast dimension	

 f2=tr.f2 or tr.tracr or tr.tracl  first sample in the slow dimension	
   =1.0 for seismic		    (if not set)			
   =d2 for nonseismic		    (if not set)			

 verbose=0              =1 to print some useful information		

 tmpdir=	 	if non-empty, use the value as a directory path	
		 	prefix for storing temporary files; else if the	
	         	the CWP_TMPDIR environment variable is set use	
	         	its value for the path; else use tmpfile()	

 Note that for seismic time domain data, the "fast dimension" is	
 time and the "slow dimension" is usually trace number or range.	
 Also note that "foreign" data tapes may have something unexpected	
 in the d2,f2 fields, use segyclean to clear these if you can afford	
 the processing time or use d2= f2= to over-ride the header values if	
 not.									

 See the sumax selfdoc for additional parameter.			
 See the xgraph selfdoc for the remaining parameters.			


 Credits:

	CWP: John Stockwell, based on Jack Cohen's SU JACKet 

 Notes:
	When the number of traces isn't known, we need to count
	the traces for xgraph.  You can make this value "known"
	either by getparring n2 or by having the ntr field set
	in the trace header.  A getparred value takes precedence
	over the value in the trace header.

	When we do have to count the traces, we use the "tmpfile"
	routine because on many machines it is implemented
	as a memory area instead of a disk file.
	
	 SUMAX - get trace by trace local/global maxima, minima, or absolute maximum

 sumax <stdin >stdout [optional parameters] 			

 Required parameters:						
	none								

 Optional parameters: 						
	output=ascii 		write ascii data to outpar		
				=binary for binary floats to stdout	
				=segy for SEGY traces to stdout		

	mode=maxmin		output both minima and maxima		
				=max maxima only			
				=min minima only			
				=abs absolute maxima only      		
				=rms RMS 		      		
				=thd search first max above threshold	

	threshamp=0		threshold amplitude value		
	threshtime=0		tmin to start search for threshold 	

	verbose=0 		writes global quantities to outpar	
				=1 trace number, values, sample location
				=2 key1 & key2 instead of trace number  
	key1=fldr		key for verbose=2                       
	key2=ep			key for verbose=2                       

	outpar=/dev/tty		output parameter file; contains output	
					from verbose			

 Examples: 								
 For global max and min values:  sumax < segy_data			
 For local and global max and min values:  sumax < segy_data verbose=1	
 To plot values specified by mode:					
    sumax < segy_data output=binary mode=modeval | xgraph n=npairs	
 To plot seismic data with the only values nonzero being those specified
 by mode=modeval:							
    sumax < segy_data output=segy mode=modeval | suxwigb		

 Note:	while traces are counted from 1, sample values are counted from 0.
	Also, if multiple min, max, or abs max values exist on a trace,	
       only the first one is captured.					

 See also: suxmax, supsmax						

 Credits:
	CWP : John Stockwell (total rewrite)
	Geocon : Garry Perratt (all ASCII output changed from 0.000000e+00 to 0.000000e+00)
	                       (added mode=rms).
      ESCI: Reginald Beardsley (added header key option)
	based on an original program by:
	SEP: Shuki Ronen
	CWP: Jack K. Cohen
      IFM-GEOMAR: Gerald Klein (added threshold option) 

 Trace header fields accessed: ns dt & user specified keys

=head2 Additional User's notes: 

Shares many of the properties of xgraph e.g., style.
Use may try to add other options from xgraph. At present I include
"style":
	 style=seismic	$        normal (axis 1 horizontal, axis 2 vertical) or  
			seismic (axis 1 vertical, axis 2 horizontal)

=head2 CHANGES and their DATES

=cut
 use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

	my $get					= L_SU_global_constants->new();
	my $var					= $get->var();
	my $empty_string    	= $var->{_empty_string};


	my $suxmax		= {
		_d1					=> '',
		_d2					=> '',
		_f1					=> '',
		_f2					=> '',
		_height		=> '',
		_mode					=> '',
		_n2					=> '',
		_style 				=> '',
		_tmpdir					=> '',
		_verbose					=> '',
		-width			=> '',
		_Step					=> '',
		_note					=> '',
    };


=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$suxmax->{_Step}     = 'suxmax'.$suxmax->{_Step};
	return ( $suxmax->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$suxmax->{_note}     = 'suxmax'.$suxmax->{_note};
	return ( $suxmax->{_note} );

 }


=head2 sub clear

=cut

 sub clear {

		$suxmax->{_d1}			= '';
		$suxmax->{_d2}			= '';
		$suxmax->{_f1}			= '';
		$suxmax->{_f2}			= '';
		$suxmax->{_height}			= '';	
		$suxmax->{_mode}			= '';
		$suxmax->{_n2}			= '';
		$suxmax->{_style}			= '';		
		$suxmax->{_tmpdir}			= '';
		$suxmax->{_verbose}			= '';
		$suxmax->{_width}			= '';		
		$suxmax->{_Step}			= '';
		$suxmax->{_note}			= '';
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$suxmax->{_d1}		= $d1;
		$suxmax->{_note}		= $suxmax->{_note}.' d1='.$suxmax->{_d1};
		$suxmax->{_Step}		= $suxmax->{_Step}.' d1='.$suxmax->{_d1};

	} else { 
		print("suxmax, d1, missing d1,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$suxmax->{_d2}		= $d2;
		$suxmax->{_note}		= $suxmax->{_note}.' d2='.$suxmax->{_d2};
		$suxmax->{_Step}		= $suxmax->{_Step}.' d2='.$suxmax->{_d2};

	} else { 
		print("suxmax, d2, missing d2,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$suxmax->{_f1}		= $f1;
		$suxmax->{_note}		= $suxmax->{_note}.' f1='.$suxmax->{_f1};
		$suxmax->{_Step}		= $suxmax->{_Step}.' f1='.$suxmax->{_f1};

	} else { 
		print("suxmax, f1, missing f1,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$suxmax->{_f2}		= $f2;
		$suxmax->{_note}		= $suxmax->{_note}.' f2='.$suxmax->{_f2};
		$suxmax->{_Step}		= $suxmax->{_Step}.' f2='.$suxmax->{_f2};

	} else { 
		print("suxmax, f2, missing f2,\n");
	 }
 }
 
=head2 sub height 


=cut

 sub height {

	my ( $self,$height )		= @_;
	if ( $height ne $empty_string ) {

		$suxmax->{_height}		= $height;
		$suxmax->{_note}		= $suxmax->{_note}.' height='.$suxmax->{_height};
		$suxmax->{_Step}		= $suxmax->{_Step}.' height='.$suxmax->{_height};

	} else { 
		print("suxmax, height, missing height,\n");
	 }
 }


=head2 sub mode 


=cut

 sub mode {

	my ( $self,$mode )		= @_;
	if ( $mode ne $empty_string ) {

		$suxmax->{_mode}		= $mode;
		$suxmax->{_note}		= $suxmax->{_note}.' mode='.$suxmax->{_mode};
		$suxmax->{_Step}		= $suxmax->{_Step}.' mode='.$suxmax->{_mode};

	} else { 
		print("suxmax, mode, missing mode,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$suxmax->{_n2}		= $n2;
		$suxmax->{_note}		= $suxmax->{_note}.' n2='.$suxmax->{_n2};
		$suxmax->{_Step}		= $suxmax->{_Step}.' n2='.$suxmax->{_n2};

	} else { 
		print("suxmax, n2, missing n2,\n");
	 }
 }
 
 
=head2 sub orientation

 subs style orientation

  whether the time axis is vertical (seismic stlye)
  or the time axis is horizontal (normal style)

=cut

sub orientation {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $suxmax->{_style} = $style;
        $suxmax->{_note} =
          $suxmax->{_note} . ' style=' . $suxmax->{_style};
        $suxmax->{_Step} =
          $suxmax->{_Step} . ' style=' . $suxmax->{_style};

    }
    else {
        print("suxmax, orientation, missing orientation,\n");
    }
}


=head2 sub style 

 subs style orientation

  whether the time axis is vertical (seismic stlye)
  or the time axis is horizontal (normal style)

=cut

sub style {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $suxmax->{_style} = $style;
        $suxmax->{_note} =
          $suxmax->{_note} . ' style=' . $suxmax->{_style};
        $suxmax->{_Step} =
          $suxmax->{_Step} . ' style=' . $suxmax->{_style};

    }
    else {
        print("suxmax, style, missing style,\n");
    }
}

=head2 sub tmpdir 


=cut

 sub tmpdir {

	my ( $self,$tmpdir )		= @_;
	if ( $tmpdir ne $empty_string ) {

		$suxmax->{_tmpdir}		= $tmpdir;
		$suxmax->{_note}		= $suxmax->{_note}.' tmpdir='.$suxmax->{_tmpdir};
		$suxmax->{_Step}		= $suxmax->{_Step}.' tmpdir='.$suxmax->{_tmpdir};

	} else { 
		print("suxmax, tmpdir, missing tmpdir,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$suxmax->{_verbose}		= $verbose;
		$suxmax->{_note}		= $suxmax->{_note}.' verbose='.$suxmax->{_verbose};
		$suxmax->{_Step}		= $suxmax->{_Step}.' verbose='.$suxmax->{_verbose};

	} else { 
		print("suxmax, verbose, missing verbose,\n");
	 }
 }
 
=head2 sub width 


=cut

 sub width {

	my ( $self,$width )		= @_;
	if ( $width ne $empty_string ) {

		$suxmax->{_width}		= $width;
		$suxmax->{_note}		= $suxmax->{_note}.' width='.$suxmax->{_width};
		$suxmax->{_Step}		= $suxmax->{_Step}.' width='.$suxmax->{_width};

	} else { 
		print("suxmax, width, missing width,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
    my $max_index = 10;

    return($max_index);
}
 
 
1; 
