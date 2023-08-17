package App::SeismicUnixGui::sunix::plot::suxmovie;

=head1 DOCUMENTATION

=head2 SYNOPSIS

PERL PROGRAM NAME:  SUXMOVIE - X MOVIE plot of a 2D or 3D segy data set 			
AUTHOR: Juan Lorenzo
DATE:   
DESCRIPTION:
Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUXMOVIE - X MOVIE plot of a 2D or 3D segy data set 			

 suxmovie <stdin [optional parameters]		 			

 Optional parameters: 							

 n1=tr.ns         	    	number of samples per trace  		
 ntr=tr.ntr     	    	number of traces in the data set	
 n2=tr.shortpad or tr.ntr	number of traces in inline direction 	
 n3=ntr/n2     	    	number of traces in crossline direction	

 d1=tr.d1 or tr.dt/10^6    sampling interval in the fast dimension	
   =.004 for seismic 		(if not set)				
   =1.0 for nonseismic		(if not set)				

 d2=tr.d2		    sampling interval in the slow dimension	
   =1.0 			(if not set)				

 d3=1.0		    sampling interval in the slowest dimension	

 f1=tr.f1 or 0.0  	    first sample in the z dimension		
 f2=tr.f2 or 1.0           first sample in the x dimension		
 f3=1.0 		    						

 mode=0          0= x,z slice movie through y dimension (in line)      
                 1= y,z slice movie through x dimension (cross line)   
                 2= x,y slice movie through z dimension (time slice)   

 verbose=0              =1 to print some useful information		

 tmpdir=	 	if non-empty, use the value as a directory path	
		 	prefix for storing temporary files; else if the	
	         	the CWP_TMPDIR environment variable is set use	
	         	its value for the path; else use tmpfile()	

 Notes:
 For seismic data, the "fast dimension" is either time or		
 depth and the "slow dimension" is usually trace number.	        
 The 3D data set is expected to have n3 sets of n2 traces representing 
 the horizontal coverage of n2*d2 in x  and n3*d3 in y direction.      

 The data is read to memory with and piped to xmovie with the         	
 respective sampling parameters.			        	
 See the xmovie selfdoc for the remaining parameters and X functions.

PERL PROGRAM NAME:  XMOVIE - image one or more frames of a uniformly sampled function f(x1,x2)
AUTHOR: Juan Lorenzo
DATE:   
DESCRIPTION:
Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 XMOVIE - image one or more frames of a uniformly sampled function f(x1,x2)

 xmovie n1= n2= [optional parameters] <fileoffloats			

 X Functionality:							
 Button 1	Zoom with rubberband box				
 Button 2 	reverse the direction of the movie.			
 Button 3 	stop and start the movie.				
 q or Q key	Quit 							
 s or S key	stop display and switch to Step mode		    
 b or B key	set frame direction to Backward			 
 f or F key	set frame direction to Forward			  
 n or N key	same as 'f'					     
 c or C key	set display mode to Continuous mode		     

 Required Parameters:							
 n1=		    number of samples in 1st (fast) dimension	
 n2=		    number of samples in 2nd (slow) dimension	

 Optional Parameters:							
 d1=1.0		 sampling interval in 1st dimension		
 f1=0.0		 first sample in 1st dimension			
 d2=1.0		 sampling interval in 2nd dimension		
 f2=0.0		 first sample in 2nd dimension			
 perc=100.0	     percentile used to determine clip		
 clip=(perc percentile) clip used to determine bclip and wclip		
 bperc=perc	     percentile for determining black clip value	
 wperc=100.0-perc       percentile for determining white clip value	
 bclip=clip	     data values outside of [bclip,wclip] are clipped
 wclip=-clip	    data values outside of [bclip,wclip] are clipped
 x1beg=x1min	    value at which axis 1 begins			
 x1end=x1max	    value at which axis 1 ends			
 x2beg=x2min	    value at which axis 2 begins			
 x2end=x2max	    value at which axis 2 ends			
 fframe=1	       value corresponding to first frame		
 dframe=1	       frame sampling interval			
 loop=0		 =1 to loop over frames after last frame is input
			=2 to run movie back and forth		 
 interp=1	       =0 for a non-interpolated, blocky image	
 verbose=1	      =1 for info printed on stderr (0 for no info)	
 idm=0		  =1 to set initial display mode to stepmode

 Optional resource parameters (defaults taken from resource database):	
 windowtitle=      	 title on window and icon			
 width=		 width in pixels of window			
 height=		height in pixels of window			
 nTic1=		 number of tics per numbered tic on axis 1	
 grid1=		 grid lines on axis 1 - none, dot, dash, or solid
 label1=		label on axis 1				
 nTic2=		 number of tics per numbered tic on axis 2	
 grid2=		 grid lines on axis 2 - none, dot, dash, or solid
 label2=		label on axis 2				
 labelFont=	     font name for axes labels			
 title=		 title of plot					
 titleFont=	     font name for title				
 titleColor=	    color for title				
 axesColor=	     color for axes					
 gridColor=	     color for grid lines				
 style=		 normal (axis 1 horizontal, axis 2 vertical) or	
			seismic (axis 1 vertical, axis 2 horizontal)	
 sleep=		 delay between frames in seconds (integer)	

 Color options:							
 cmap=gray     gray, hue, saturation, or default colormaps may be specified
 bhue=0	hue mapped to bclip (hue and saturation maps)		
 whue=240      hue mapped to wclip (hue and saturation maps)		
 sat=1	 saturation (hue map only)				
 bright=1      brightness (hue and saturation maps)			
 white=(bclip+wclip)/2  data value mapped to white (saturation map only)

 Notes:								
 Colors are specified using the HSV color wheel model:			
   Hue:  0=360=red, 60=yellow, 120=green, 180=cyan, 240=blue, 300=magenta
   Saturation:  0=white, 1=pure color					
   Value (brightness):  0=black, 1=maximum intensity			
 For the saturation mapping (cmap=sat), data values between white and bclip
   are mapped to bhue, with saturation varying from white to the pure color.
   Values between wclip and white are similarly mapped to whue.	
 For the hue mapping (cmap=hue), data values between wclip and bclip are
   mapped to hues between whue and bhue.  Intermediate hues are found by
   moving counterclockwise around the circle from bhue to whue.  To reverse
   the polarity of the image, exchange bhue and whue.  Equivalently,	
   exchange bclip and wclip (setting perc=0 is an easy way to do this).
   Hues in excess of 360 degrees can be specified in order to reach the
   opposite side of the color circle, or to wrap around the circle more
   than once.								

 The title string may contain a C printf format string containing a	
   conversion character for the frame number.  The frame number is	
   computed from dframe and fframe.  E.g., try setting title="Frame 0". 
 
 	

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suxmovie = {
	_axesColor   => '',
	_bclip       => '',
	_bhue        => '',
	_bperc       => '',
	_bright      => '',
	_clip        => '',
	_cmap        => '',
	_d1          => '',
	_d2          => '',
	_d3          => '',
	_dframe      => '',
	_f1          => '',
	_f2          => '',
	_f3          => '',
	_fframe      => '',
	_grid1       => '',
	_grid2       => '',
	_gridColor   => '',
	_height      => '',
	_high_clip     => '',
	_idm         => '',
	_interp      => '',
	_label1      => '',
	_label2      => '',
	_labelFont   => '',
	_low_clip        => '',
	_loop        => '',
	_mode        => '',
	_n1          => '',
	_n2          => '',
	_n3          => '',
	_nTic1       => '',
	_nTic2       => '',
	_ntr         => '',
	_perc        => '',
	_sat         => '',
	_sleep       => '',
	_style       => '',
	_title       => '',
	_titleColor  => '',
	_titleFont   => '',
	_tmpdir      => '',
	_verbose     => '',
	_wclip       => '',
	_white       => '',
	_whue        => '',
	_width       => '',
	_windowtitle => '',
	_wperc       => '',
	_x1beg       => '',
	_x1end       => '',
	_x2beg       => '',
	_x2end       => '',
	_Step        => '',
	_note        => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$suxmovie->{_Step} = 'suxmovie' . $suxmovie->{_Step};
	return ( $suxmovie->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$suxmovie->{_note} = 'suxmovie' . $suxmovie->{_note};
	return ( $suxmovie->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$suxmovie->{_axesColor}   = '';
	$suxmovie->{_bclip}       = '';
	$suxmovie->{_bhue}        = '';
	$suxmovie->{_bperc}       = '';
	$suxmovie->{_bright}      = '';
	$suxmovie->{_clip}        = '';
	$suxmovie->{_cmap}        = '';
	$suxmovie->{_d1}          = '';
	$suxmovie->{_d2}          = '';
	$suxmovie->{_d3}          = '';
	$suxmovie->{_dframe}      = '';
	$suxmovie->{_f1}          = '';
	$suxmovie->{_f2}          = '';
	$suxmovie->{_f3}          = '';
	$suxmovie->{_fframe}      = '';
	$suxmovie->{_grid1}       = '';
	$suxmovie->{_grid2}       = '';
	$suxmovie->{_gridColor}   = '';
	$suxmovie->{_height}      = '';
	$suxmovie->{_idm}         = '';
	$suxmovie->{_interp}      = '';
	$suxmovie->{_label1}      = '';
	$suxmovie->{_label2}      = '';
	$suxmovie->{_labelFont}   = '';
	$suxmovie->{_loop}        = '';
	$suxmovie->{_mode}        = '';	
	$suxmovie->{_n1}          = '';
	$suxmovie->{_n2}          = '';
	$suxmovie->{_n3}          = '';
	$suxmovie->{_nTic1}       = '';
	$suxmovie->{_nTic2}       = '';
	$suxmovie->{_ntr}         = '';	
	$suxmovie->{_perc}        = '';
	$suxmovie->{_sat}         = '';
	$suxmovie->{_sleep}       = '';
	$suxmovie->{_style}       = '';
	$suxmovie->{_title}       = '';
	$suxmovie->{_titleColor}  = '';
	$suxmovie->{_titleFont}   = '';
	$suxmovie->{_tmpdir}	= '';	
	$suxmovie->{_verbose}     = '';
	$suxmovie->{_wclip}       = '';
	$suxmovie->{_white}       = '';
	$suxmovie->{_whue}        = '';
	$suxmovie->{_width}       = '';
	$suxmovie->{_windowtitle} = '';
	$suxmovie->{_wperc}       = '';
	$suxmovie->{_x1beg}       = '';
	$suxmovie->{_x1end}       = '';
	$suxmovie->{_x2beg}       = '';
	$suxmovie->{_x2end}       = '';
	$suxmovie->{_Step}        = '';
	$suxmovie->{_note}        = '';
	
};

=head2 sub axesColor 


=cut

sub axesColor {

	my ( $self, $axesColor ) = @_;
	if ( $axesColor ne $empty_string ) {

		$suxmovie->{_axesColor} = $axesColor;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' axesColor=' . $suxmovie->{_axesColor};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' axesColor=' . $suxmovie->{_axesColor};

	}
	else {
		print("xmovie, axesColor, missing axesColor,\n");
	}
}

=head2 sub bclip 

subs bclip or loclip or low_clip

=cut

sub bclip {

	my ( $self, $bclip ) = @_;
	if ( $bclip ne $empty_string ) {

		$suxmovie->{_bclip} = $bclip;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' bclip=' . $suxmovie->{_bclip};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' bclip=' . $suxmovie->{_bclip};

	}
	else {
		print("xmovie, bclip, missing bclip,\n");
	}
}

=head2 sub bhue 


=cut

sub bhue {

	my ( $self, $bhue ) = @_;
	if ( $bhue ne $empty_string ) {

		$suxmovie->{_bhue} = $bhue;
		$suxmovie->{_note} = $suxmovie->{_note} . ' bhue=' . $suxmovie->{_bhue};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' bhue=' . $suxmovie->{_bhue};

	}
	else {
		print("xmovie, bhue, missing bhue,\n");
	}
}

=head2 sub bperc 


=cut

sub bperc {

	my ( $self, $bperc ) = @_;
	if ( $bperc ne $empty_string ) {

		$suxmovie->{_bperc} = $bperc;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' bperc=' . $suxmovie->{_bperc};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' bperc=' . $suxmovie->{_bperc};

	}
	else {
		print("xmovie, bperc, missing bperc,\n");
	}
}

=head2 sub bright 


=cut

sub bright {

	my ( $self, $bright ) = @_;
	if ( $bright ne $empty_string ) {

		$suxmovie->{_bright} = $bright;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' bright=' . $suxmovie->{_bright};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' bright=' . $suxmovie->{_bright};

	}
	else {
		print("xmovie, bright, missing bright,\n");
	}
}

=head2 sub clip


=cut

sub clip {

	my ( $self, $clip ) = @_;
	if ( $clip ne $empty_string ) {

		$suxmovie->{_clip} = $clip;
		$suxmovie->{_note} = $suxmovie->{_note} . ' clip=' . $suxmovie->{_clip};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' clip=' . $suxmovie->{_clip};

	}
	else {
		print("suxmovie, clip, missing clip,\n");
	}
}

=head2 sub cmap 


=cut

sub cmap {

	my ( $self, $cmap ) = @_;
	if ( $cmap ne $empty_string ) {

		$suxmovie->{_cmap} = $cmap;
		$suxmovie->{_note} = $suxmovie->{_note} . ' cmap=' . $suxmovie->{_cmap};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' cmap=' . $suxmovie->{_cmap};

	}
	else {
		print("xmovie, cmap, missing cmap,\n");
	}
}

=head2 sub d1 


=cut

sub d1 {

	my ( $self, $d1 ) = @_;
	if ( $d1 ne $empty_string ) {

		$suxmovie->{_d1}   = $d1;
		$suxmovie->{_note} = $suxmovie->{_note} . ' d1=' . $suxmovie->{_d1};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' d1=' . $suxmovie->{_d1};

	}
	else {
		print("suxmovie, d1, missing d1,\n");
	}
}

=head2 sub d2 


=cut

sub d2 {

	my ( $self, $d2 ) = @_;
	if ( $d2 ne $empty_string ) {

		$suxmovie->{_d2}   = $d2;
		$suxmovie->{_note} = $suxmovie->{_note} . ' d2=' . $suxmovie->{_d2};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' d2=' . $suxmovie->{_d2};

	}
	else {
		print("suxmovie, d2, missing d2,\n");
	}
}

=head2 sub d3 


=cut

sub d3 {

	my ( $self, $d3 ) = @_;
	if ( $d3 ne $empty_string ) {

		$suxmovie->{_d3}   = $d3;
		$suxmovie->{_note} = $suxmovie->{_note} . ' d3=' . $suxmovie->{_d3};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' d3=' . $suxmovie->{_d3};

	}
	else {
		print("suxmovie, d3, missing d3,\n");
	}
}

=head2 sub dframe 


=cut

sub dframe {

	my ( $self, $dframe ) = @_;
	if ( $dframe ne $empty_string ) {

		$suxmovie->{_dframe} = $dframe;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' dframe=' . $suxmovie->{_dframe};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' dframe=' . $suxmovie->{_dframe};

	}
	else {
		print("xmovie, dframe, missing dframe,\n");
	}
}

=head2 sub f1 


=cut

sub f1 {

	my ( $self, $f1 ) = @_;
	if ( $f1 ne $empty_string ) {

		$suxmovie->{_f1}   = $f1;
		$suxmovie->{_note} = $suxmovie->{_note} . ' f1=' . $suxmovie->{_f1};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' f1=' . $suxmovie->{_f1};

	}
	else {
		print("suxmovie, f1, missing f1,\n");
	}
}

=head2 sub f2 


=cut

sub f2 {

	my ( $self, $f2 ) = @_;
	if ( $f2 ne $empty_string ) {

		$suxmovie->{_f2}   = $f2;
		$suxmovie->{_note} = $suxmovie->{_note} . ' f2=' . $suxmovie->{_f2};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' f2=' . $suxmovie->{_f2};

	}
	else {
		print("suxmovie, f2, missing f2,\n");
	}
}

=head2 sub f3 


=cut

sub f3 {

	my ( $self, $f3 ) = @_;
	if ( $f3 ne $empty_string ) {

		$suxmovie->{_f3}   = $f3;
		$suxmovie->{_note} = $suxmovie->{_note} . ' f3=' . $suxmovie->{_f3};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' f3=' . $suxmovie->{_f3};

	}
	else {
		print("suxmovie, f3, missing f3,\n");
	}
}

=head2 sub fframe 


=cut

sub fframe {

	my ( $self, $fframe ) = @_;
	if ( $fframe ne $empty_string ) {

		$suxmovie->{_fframe} = $fframe;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' fframe=' . $suxmovie->{_fframe};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' fframe=' . $suxmovie->{_fframe};

	}
	else {
		print("xmovie, fframe, missing fframe,\n");
	}
}

=head2 sub grid1 


=cut

sub grid1 {

	my ( $self, $grid1 ) = @_;
	if ( $grid1 ne $empty_string ) {

		$suxmovie->{_grid1} = $grid1;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' grid1=' . $suxmovie->{_grid1};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' grid1=' . $suxmovie->{_grid1};

	}
	else {
		print("xmovie, grid1, missing grid1,\n");
	}
}

=head2 sub grid2 


=cut

sub grid2 {

	my ( $self, $grid2 ) = @_;
	if ( $grid2 ne $empty_string ) {

		$suxmovie->{_grid2} = $grid2;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' grid2=' . $suxmovie->{_grid2};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' grid2=' . $suxmovie->{_grid2};

	}
	else {
		print("xmovie, grid2, missing grid2,\n");
	}
}

=head2 sub gridColor 


=cut

sub gridColor {

	my ( $self, $gridColor ) = @_;
	if ( $gridColor ne $empty_string ) {

		$suxmovie->{_gridColor} = $gridColor;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' gridColor=' . $suxmovie->{_gridColor};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' gridColor=' . $suxmovie->{_gridColor};

	}
	else {
		print("xmovie, gridColor, missing gridColor,\n");
	}
}

=head2 sub height 


=cut

sub height {

	my ( $self, $height ) = @_;
	if ( $height ne $empty_string ) {

		$suxmovie->{_height} = $height;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' height=' . $suxmovie->{_height};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' height=' . $suxmovie->{_height};

	}
	else {
		print("xmovie, height, missing height,\n");
	}
}

=head2 sub hiclip 

subs wclip or hiclip or high_clip

=cut

sub hiclip {

	my ( $self, $wclip ) = @_;
	if ( $wclip ne $empty_string ) {

		$suxmovie->{_wclip} = $wclip;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' wclip=' . $suxmovie->{_wclip};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' wclip=' . $suxmovie->{_wclip};

	}
	else {
		print("xmovie, hiclip, missing wclip,\n");
	}
}

=head2 sub high_clip 

subs wclip or hiclip or high_clip

=cut

sub high_clip {

	my ( $self, $wclip ) = @_;
	if ( $wclip ne $empty_string ) {

		$suxmovie->{_wclip} = $wclip;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' wclip=' . $suxmovie->{_wclip};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' wclip=' . $suxmovie->{_wclip};

	}
	else {
		print("xmovie, high_clip, missing wclip,\n");
	}
}


=head2 sub idm 


=cut

sub idm {

	my ( $self, $idm ) = @_;
	if ( $idm ne $empty_string ) {

		$suxmovie->{_idm}  = $idm;
		$suxmovie->{_note} = $suxmovie->{_note} . ' idm=' . $suxmovie->{_idm};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' idm=' . $suxmovie->{_idm};

	}
	else {
		print("xmovie, idm, missing idm,\n");
	}
}

=head2 sub interp 


=cut

sub interp {

	my ( $self, $interp ) = @_;
	if ( $interp ne $empty_string ) {

		$suxmovie->{_interp} = $interp;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' interp=' . $suxmovie->{_interp};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' interp=' . $suxmovie->{_interp};

	}
	else {
		print("xmovie, interp, missing interp,\n");
	}
}

=head2 sub label1 


=cut

sub label1 {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$suxmovie->{_label1} = $label1;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' label1=' . $suxmovie->{_label1};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' label1=' . $suxmovie->{_label1};

	}
	else {
		print("xmovie, label1, missing label1,\n");
	}
}

=head2 sub label2 

subs label2 or xlabel

=cut

sub label2 {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$suxmovie->{_label2} = $label2;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' label2=' . $suxmovie->{_label2};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' label2=' . $suxmovie->{_label2};

	}
	else {
		print("xmovie, label2, missing label2,\n");
	}
}

=head2 sub labelFont 


=cut

sub labelFont {

	my ( $self, $labelFont ) = @_;
	if ( $labelFont ne $empty_string ) {

		$suxmovie->{_labelFont} = $labelFont;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' labelFont=' . $suxmovie->{_labelFont};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' labelFont=' . $suxmovie->{_labelFont};

	}
	else {
		print("xmovie, labelFont, missing labelFont,\n");
	}
}

=head2 sub loclip 

subs bclip or loclip or low_clip

=cut

sub loclip {

	my ( $self, $bclip ) = @_;
	if ( $bclip ne $empty_string ) {

		$suxmovie->{_bclip} = $bclip;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' bclip=' . $suxmovie->{_bclip};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' bclip=' . $suxmovie->{_bclip};

	}
	else {
		print("xmovie, loclip, missing bclip,\n");
	}
}


=head2 sub low_clip 

subs bclip or loclip or low_clip

=cut

sub low_clip {

	my ( $self, $bclip ) = @_;
	if ( $bclip ne $empty_string ) {

		$suxmovie->{_bclip} = $bclip;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' bclip=' . $suxmovie->{_bclip};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' bclip=' . $suxmovie->{_bclip};

	}
	else {
		print("xmovie, low_clip, missing bclip,\n");
	}
}

=head2 sub loop 


=cut

sub loop {

	my ( $self, $loop ) = @_;
	if ( $loop ne $empty_string ) {

		$suxmovie->{_loop} = $loop;
		$suxmovie->{_note} = $suxmovie->{_note} . ' loop=' . $suxmovie->{_loop};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' loop=' . $suxmovie->{_loop};

	}
	else {
		print("xmovie, loop, missing loop,\n");
	}
}

=head2 sub mode 


=cut

sub mode {

	my ( $self, $mode ) = @_;
	if ( $mode ne $empty_string ) {

		$suxmovie->{_mode} = $mode;
		$suxmovie->{_note} = $suxmovie->{_note} . ' mode=' . $suxmovie->{_mode};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' mode=' . $suxmovie->{_mode};

	}
	else {
		print("suxmovie, mode, missing mode,\n");
	}
}

=head2 sub n1 


=cut

sub n1 {

	my ( $self, $n1 ) = @_;
	if ( $n1 ne $empty_string ) {

		$suxmovie->{_n1}   = $n1;
		$suxmovie->{_note} = $suxmovie->{_note} . ' n1=' . $suxmovie->{_n1};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' n1=' . $suxmovie->{_n1};

	}
	else {
		print("xmovie, n1, missing n1,\n");
	}
}

=head2 sub n2 


=cut

sub n2 {

	my ( $self, $n2 ) = @_;
	if ( $n2 ne $empty_string ) {

		$suxmovie->{_n2}   = $n2;
		$suxmovie->{_note} = $suxmovie->{_note} . ' n2=' . $suxmovie->{_n2};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' n2=' . $suxmovie->{_n2};

	}
	else {
		print("xmovie, n2, missing n2,\n");
	}
}

=head2 sub n3 


=cut

sub n3 {

	my ( $self, $n3 ) = @_;
	if ( $n3 ne $empty_string ) {

		$suxmovie->{_n3}   = $n3;
		$suxmovie->{_note} = $suxmovie->{_note} . ' n3=' . $suxmovie->{_n3};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' n3=' . $suxmovie->{_n3};

	}
	else {
		print("suxmovie, n3, missing n3,\n");
	}
}

=head2 sub nTic1 


=cut

sub nTic1 {

	my ( $self, $nTic1 ) = @_;
	if ( $nTic1 ne $empty_string ) {

		$suxmovie->{_nTic1} = $nTic1;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' nTic1=' . $suxmovie->{_nTic1};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' nTic1=' . $suxmovie->{_nTic1};

	}
	else {
		print("xmovie, nTic1, missing nTic1,\n");
	}
}

=head2 sub nTic2 


=cut

sub nTic2 {

	my ( $self, $nTic2 ) = @_;
	if ( $nTic2 ne $empty_string ) {

		$suxmovie->{_nTic2} = $nTic2;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' nTic2=' . $suxmovie->{_nTic2};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' nTic2=' . $suxmovie->{_nTic2};

	}
	else {
		print("xmovie, nTic2, missing nTic2,\n");
	}
}

=head2 sub ntr 


=cut

sub ntr {

	my ( $self, $ntr ) = @_;
	if ( $ntr ne $empty_string ) {

		$suxmovie->{_ntr}  = $ntr;
		$suxmovie->{_note} = $suxmovie->{_note} . ' ntr=' . $suxmovie->{_ntr};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' ntr=' . $suxmovie->{_ntr};

	}
	else {
		print("suxmovie, ntr, missing ntr,\n");
	}
}

=head2 sub perc 


=cut

sub perc {

	my ( $self, $perc ) = @_;
	if ( $perc ne $empty_string ) {

		$suxmovie->{_perc} = $perc;
		$suxmovie->{_note} = $suxmovie->{_note} . ' perc=' . $suxmovie->{_perc};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' perc=' . $suxmovie->{_perc};

	}
	else {
		print("xmovie, perc, missing perc,\n");
	}
}

=head2 sub sat 


=cut

sub sat {

	my ( $self, $sat ) = @_;
	if ( $sat ne $empty_string ) {

		$suxmovie->{_sat}  = $sat;
		$suxmovie->{_note} = $suxmovie->{_note} . ' sat=' . $suxmovie->{_sat};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' sat=' . $suxmovie->{_sat};

	}
	else {
		print("xmovie, sat, missing sat,\n");
	}
}

=head2 sub sleep 


=cut

sub sleep {

	my ( $self, $sleep ) = @_;
	if ( $sleep ne $empty_string ) {

		$suxmovie->{_sleep} = $sleep;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' sleep=' . $suxmovie->{_sleep};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' sleep=' . $suxmovie->{_sleep};

	}
	else {
		print("xmovie, sleep, missing sleep,\n");
	}
}

=head2 sub style 


=cut

sub style {

	my ( $self, $style ) = @_;
	if ( $style ne $empty_string ) {

		$suxmovie->{_style} = $style;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' style=' . $suxmovie->{_style};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' style=' . $suxmovie->{_style};

	}
	else {
		print("xmovie, style, missing style,\n");
	}
}

=head2 sub title 


=cut

sub title {

	my ( $self, $title ) = @_;
	if ( $title ne $empty_string ) {

		$suxmovie->{_title} = $title;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' title=' . $suxmovie->{_title};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' title=' . $suxmovie->{_title};

	}
	else {
		print("xmovie, title, missing title,\n");
	}
}

=head2 sub titleColor 


=cut

sub titleColor {

	my ( $self, $titleColor ) = @_;
	if ( $titleColor ne $empty_string ) {

		$suxmovie->{_titleColor} = $titleColor;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' titleColor=' . $suxmovie->{_titleColor};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' titleColor=' . $suxmovie->{_titleColor};

	}
	else {
		print("xmovie, titleColor, missing titleColor,\n");
	}
}

=head2 sub titleFont 


=cut

sub titleFont {

	my ( $self, $titleFont ) = @_;
	if ( $titleFont ne $empty_string ) {

		$suxmovie->{_titleFont} = $titleFont;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' titleFont=' . $suxmovie->{_titleFont};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' titleFont=' . $suxmovie->{_titleFont};

	}
	else {
		print("xmovie, titleFont, missing titleFont,\n");
	}
}

=head2 sub tmpdir 


=cut

sub tmpdir {

	my ( $self, $tmpdir ) = @_;
	if ( $tmpdir ne $empty_string ) {

		$suxmovie->{_tmpdir} = $tmpdir;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' tmpdir=' . $suxmovie->{_tmpdir};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' tmpdir=' . $suxmovie->{_tmpdir};

	}
	else {
		print("suxmovie, tmpdir, missing tmpdir,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$suxmovie->{_verbose} = $verbose;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' verbose=' . $suxmovie->{_verbose};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' verbose=' . $suxmovie->{_verbose};

	}
	else {
		print("suxmovie, verbose, missing verbose,\n");
	}
}

=head2 sub wclip 

subs wclip or high_clip

=cut

sub wclip {

	my ( $self, $wclip ) = @_;
	if ( $wclip ne $empty_string ) {

		$suxmovie->{_wclip} = $wclip;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' wclip=' . $suxmovie->{_wclip};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' wclip=' . $suxmovie->{_wclip};

	}
	else {
		print("xmovie, wclip, missing wclip,\n");
	}
}

=head2 sub white 


=cut

sub white {

	my ( $self, $white ) = @_;
	if ( $white ne $empty_string ) {

		$suxmovie->{_white} = $white;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' white=' . $suxmovie->{_white};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' white=' . $suxmovie->{_white};

	}
	else {
		print("xmovie, white, missing white,\n");
	}
}

=head2 sub whue 


=cut

sub whue {

	my ( $self, $whue ) = @_;
	if ( $whue ne $empty_string ) {

		$suxmovie->{_whue} = $whue;
		$suxmovie->{_note} = $suxmovie->{_note} . ' whue=' . $suxmovie->{_whue};
		$suxmovie->{_Step} = $suxmovie->{_Step} . ' whue=' . $suxmovie->{_whue};

	}
	else {
		print("xmovie, whue, missing whue,\n");
	}
}

=head2 sub width 


=cut

sub width {

	my ( $self, $width ) = @_;
	if ( $width ne $empty_string ) {

		$suxmovie->{_width} = $width;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' width=' . $suxmovie->{_width};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' width=' . $suxmovie->{_width};

	}
	else {
		print("xmovie, width, missing width,\n");
	}
}

=head2 sub windowtitle 


=cut

sub windowtitle {

	my ( $self, $windowtitle ) = @_;
	if ( $windowtitle ne $empty_string ) {

		$suxmovie->{_windowtitle} = $windowtitle;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' windowtitle=' . $suxmovie->{_windowtitle};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' windowtitle=' . $suxmovie->{_windowtitle};

	}
	else {
		print("xmovie, windowtitle, missing windowtitle,\n");
	}
}

=head2 sub wperc 


=cut

sub wperc {

	my ( $self, $wperc ) = @_;
	if ( $wperc ne $empty_string ) {

		$suxmovie->{_wperc} = $wperc;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' wperc=' . $suxmovie->{_wperc};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' wperc=' . $suxmovie->{_wperc};

	}
	else {
		print("xmovie, wperc, missing wperc,\n");
	}
}

=head2 sub x1beg 


=cut

sub x1beg {

	my ( $self, $x1beg ) = @_;
	if ( $x1beg ne $empty_string ) {

		$suxmovie->{_x1beg} = $x1beg;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' x1beg=' . $suxmovie->{_x1beg};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' x1beg=' . $suxmovie->{_x1beg};

	}
	else {
		print("xmovie, x1beg, missing x1beg,\n");
	}
}

=head2 sub x1end 


=cut

sub x1end {

	my ( $self, $x1end ) = @_;
	if ( $x1end ne $empty_string ) {

		$suxmovie->{_x1end} = $x1end;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' x1end=' . $suxmovie->{_x1end};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' x1end=' . $suxmovie->{_x1end};

	}
	else {
		print("xmovie, x1end, missing x1end,\n");
	}
}

=head2 sub x2beg 


=cut

sub x2beg {

	my ( $self, $x2beg ) = @_;
	if ( $x2beg ne $empty_string ) {

		$suxmovie->{_x2beg} = $x2beg;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' x2beg=' . $suxmovie->{_x2beg};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' x2beg=' . $suxmovie->{_x2beg};

	}
	else {
		print("xmovie, x2beg, missing x2beg,\n");
	}
}

=head2 sub x2end 


=cut

sub x2end {

	my ( $self, $x2end ) = @_;
	if ( $x2end ne $empty_string ) {

		$suxmovie->{_x2end} = $x2end;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' x2end=' . $suxmovie->{_x2end};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' x2end=' . $suxmovie->{_x2end};

	}
	else {
		print("xmovie, x2end, missing x2end,\n");
	}
}

=head2 sub x_label 


=cut

sub x_label {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$suxmovie->{_label2} = $label2;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' label2=' . $suxmovie->{_label2};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' label2=' . $suxmovie->{_label2};

	}
	else {
		print("suxmovie, x_label, missing label2,\n");
	}
}

=head2 sub y_label 


=cut

sub y_label {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$suxmovie->{_label1} = $label1;
		$suxmovie->{_note} =
			$suxmovie->{_note} . ' label1=' . $suxmovie->{_label1};
		$suxmovie->{_Step} =
			$suxmovie->{_Step} . ' label1=' . $suxmovie->{_label1};

	}
	else {
		print("suxmovie, y_label, missing label1,\n");
	}
}
=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 50;

	return ($max_index);
}

1;
