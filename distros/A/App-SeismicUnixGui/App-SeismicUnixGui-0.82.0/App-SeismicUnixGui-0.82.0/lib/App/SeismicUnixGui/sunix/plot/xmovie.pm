package App::SeismicUnixGui::sunix::plot::xmovie;

=head1 DOCUMENTATION

=head2 SYNOPSIS

PACKAGE NAME:  XMOVIE - image one or more frames of a uniformly sampled function f(x1,x2)
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

my $xmovie = {
	_axesColor   => '',
	_bclip       => '',
	_bhue        => '',
	_bperc       => '',
	_bright      => '',
	_clip        => '',
	_cmap        => '',
	_d1          => '',
	_d2          => '',
	_dframe      => '',
	_f1          => '',
	_f2          => '',
	_fframe      => '',
	_grid1       => '',
	_grid2       => '',
	_gridColor   => '',
	_height      => '',
	_idm         => '',
	_interp      => '',
	_label1      => '',
	_label2      => '',
	_labelFont   => '',
	_loop        => '',
	_n1          => '',
	_n2          => '',
	_nTic1       => '',
	_nTic2       => '',
	_perc        => '',
	_sat         => '',
	_sleep       => '',
	_style       => '',
	_title       => '',
	_titleColor  => '',
	_titleFont   => '',
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

	$xmovie->{_Step} = 'xmovie' . $xmovie->{_Step};
	return ( $xmovie->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$xmovie->{_note} = 'xmovie' . $xmovie->{_note};
	return ( $xmovie->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$xmovie->{_axesColor}   = '';
	$xmovie->{_bclip}       = '';
	$xmovie->{_bhue}        = '';
	$xmovie->{_bperc}       = '';
	$xmovie->{_bright}      = '';
	$xmovie->{_clip}        = '';
	$xmovie->{_cmap}        = '';
	$xmovie->{_d1}          = '';
	$xmovie->{_d2}          = '';
	$xmovie->{_dframe}      = '';
	$xmovie->{_f1}          = '';
	$xmovie->{_f2}          = '';
	$xmovie->{_fframe}      = '';
	$xmovie->{_grid1}       = '';
	$xmovie->{_grid2}       = '';
	$xmovie->{_gridColor}   = '';
	$xmovie->{_height}      = '';
	$xmovie->{_idm}         = '';
	$xmovie->{_interp}      = '';
	$xmovie->{_label1}      = '';
	$xmovie->{_label2}      = '';
	$xmovie->{_labelFont}   = '';
	$xmovie->{_loop}        = '';
	$xmovie->{_n1}          = '';
	$xmovie->{_n2}          = '';
	$xmovie->{_nTic1}       = '';
	$xmovie->{_nTic2}       = '';
	$xmovie->{_perc}        = '';
	$xmovie->{_sat}         = '';
	$xmovie->{_sleep}       = '';
	$xmovie->{_style}       = '';
	$xmovie->{_title}       = '';
	$xmovie->{_titleColor}  = '';
	$xmovie->{_titleFont}   = '';
	$xmovie->{_verbose}     = '';
	$xmovie->{_wclip}       = '';
	$xmovie->{_white}       = '';
	$xmovie->{_whue}        = '';
	$xmovie->{_width}       = '';
	$xmovie->{_windowtitle} = '';
	$xmovie->{_wperc}       = '';
	$xmovie->{_x1beg}       = '';
	$xmovie->{_x1end}       = '';
	$xmovie->{_x2beg}       = '';
	$xmovie->{_x2end}       = '';
	$xmovie->{_Step}        = '';
	$xmovie->{_note}        = '';
}

=head2 sub axesColor 


=cut

sub axesColor {

	my ( $self, $axesColor ) = @_;
	if ( $axesColor ne $empty_string ) {

		$xmovie->{_axesColor} = $axesColor;
		$xmovie->{_note} =
			$xmovie->{_note} . ' axesColor=' . $xmovie->{_axesColor};
		$xmovie->{_Step} =
			$xmovie->{_Step} . ' axesColor=' . $xmovie->{_axesColor};

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

		$xmovie->{_bclip} = $bclip;
		$xmovie->{_note}  = $xmovie->{_note} . ' bclip=' . $xmovie->{_bclip};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' bclip=' . $xmovie->{_bclip};

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

		$xmovie->{_bhue} = $bhue;
		$xmovie->{_note} = $xmovie->{_note} . ' bhue=' . $xmovie->{_bhue};
		$xmovie->{_Step} = $xmovie->{_Step} . ' bhue=' . $xmovie->{_bhue};

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

		$xmovie->{_bperc} = $bperc;
		$xmovie->{_note}  = $xmovie->{_note} . ' bperc=' . $xmovie->{_bperc};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' bperc=' . $xmovie->{_bperc};

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

		$xmovie->{_bright} = $bright;
		$xmovie->{_note}   = $xmovie->{_note} . ' bright=' . $xmovie->{_bright};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' bright=' . $xmovie->{_bright};

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

		$xmovie->{_clip} = $clip;
		$xmovie->{_note} = $xmovie->{_note} . ' clip=' . $xmovie->{_clip};
		$xmovie->{_Step} = $xmovie->{_Step} . ' clip=' . $xmovie->{_clip};

	}
	else {
		print("xmovie, clip, missing clip,\n");
	}
}

=head2 sub cmap 


=cut

sub cmap {

	my ( $self, $cmap ) = @_;
	if ( $cmap ne $empty_string ) {

		$xmovie->{_cmap} = $cmap;
		$xmovie->{_note} = $xmovie->{_note} . ' cmap=' . $xmovie->{_cmap};
		$xmovie->{_Step} = $xmovie->{_Step} . ' cmap=' . $xmovie->{_cmap};

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

		$xmovie->{_d1}   = $d1;
		$xmovie->{_note} = $xmovie->{_note} . ' d1=' . $xmovie->{_d1};
		$xmovie->{_Step} = $xmovie->{_Step} . ' d1=' . $xmovie->{_d1};

	}
	else {
		print("xmovie, d1, missing d1,\n");
	}
}

=head2 sub d2 


=cut

sub d2 {

	my ( $self, $d2 ) = @_;
	if ( $d2 ne $empty_string ) {

		$xmovie->{_d2}   = $d2;
		$xmovie->{_note} = $xmovie->{_note} . ' d2=' . $xmovie->{_d2};
		$xmovie->{_Step} = $xmovie->{_Step} . ' d2=' . $xmovie->{_d2};

	}
	else {
		print("xmovie, d2, missing d2,\n");
	}
}

=head2 sub dframe 


=cut

sub dframe {

	my ( $self, $dframe ) = @_;
	if ( $dframe ne $empty_string ) {

		$xmovie->{_dframe} = $dframe;
		$xmovie->{_note}   = $xmovie->{_note} . ' dframe=' . $xmovie->{_dframe};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' dframe=' . $xmovie->{_dframe};

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

		$xmovie->{_f1}   = $f1;
		$xmovie->{_note} = $xmovie->{_note} . ' f1=' . $xmovie->{_f1};
		$xmovie->{_Step} = $xmovie->{_Step} . ' f1=' . $xmovie->{_f1};

	}
	else {
		print("xmovie, f1, missing f1,\n");
	}
}

=head2 sub f2 


=cut

sub f2 {

	my ( $self, $f2 ) = @_;
	if ( $f2 ne $empty_string ) {

		$xmovie->{_f2}   = $f2;
		$xmovie->{_note} = $xmovie->{_note} . ' f2=' . $xmovie->{_f2};
		$xmovie->{_Step} = $xmovie->{_Step} . ' f2=' . $xmovie->{_f2};

	}
	else {
		print("xmovie, f2, missing f2,\n");
	}
}

=head2 sub fframe 


=cut

sub fframe {

	my ( $self, $fframe ) = @_;
	if ( $fframe ne $empty_string ) {

		$xmovie->{_fframe} = $fframe;
		$xmovie->{_note}   = $xmovie->{_note} . ' fframe=' . $xmovie->{_fframe};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' fframe=' . $xmovie->{_fframe};

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

		$xmovie->{_grid1} = $grid1;
		$xmovie->{_note}  = $xmovie->{_note} . ' grid1=' . $xmovie->{_grid1};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' grid1=' . $xmovie->{_grid1};

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

		$xmovie->{_grid2} = $grid2;
		$xmovie->{_note}  = $xmovie->{_note} . ' grid2=' . $xmovie->{_grid2};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' grid2=' . $xmovie->{_grid2};

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

		$xmovie->{_gridColor} = $gridColor;
		$xmovie->{_note} =
			$xmovie->{_note} . ' gridColor=' . $xmovie->{_gridColor};
		$xmovie->{_Step} =
			$xmovie->{_Step} . ' gridColor=' . $xmovie->{_gridColor};

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

		$xmovie->{_height} = $height;
		$xmovie->{_note}   = $xmovie->{_note} . ' height=' . $xmovie->{_height};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' height=' . $xmovie->{_height};

	}
	else {
		print("xmovie, height, missing height,\n");
	}
}

=head2 sub hiclip 

subs hiclip or wclip or high_clip

=cut

sub hiclip {

	my ( $self, $wclip ) = @_;
	if ( $wclip ne $empty_string ) {

		$xmovie->{_wclip} = $wclip;
		$xmovie->{_note}  = $xmovie->{_note} . ' wclip=' . $xmovie->{_wclip};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' wclip=' . $xmovie->{_wclip};

	}
	else {
		print("xmovie, hiclip, missing wclip,\n");
	}
}

=head2 sub high_clip 

subs hiclip or wclip or high_clip

=cut

sub high_clip {

	my ( $self, $wclip ) = @_;
	if ( $wclip ne $empty_string ) {

		$xmovie->{_wclip} = $wclip;
		$xmovie->{_note}  = $xmovie->{_note} . ' wclip=' . $xmovie->{_wclip};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' wclip=' . $xmovie->{_wclip};

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

		$xmovie->{_idm}  = $idm;
		$xmovie->{_note} = $xmovie->{_note} . ' idm=' . $xmovie->{_idm};
		$xmovie->{_Step} = $xmovie->{_Step} . ' idm=' . $xmovie->{_idm};

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

		$xmovie->{_interp} = $interp;
		$xmovie->{_note}   = $xmovie->{_note} . ' interp=' . $xmovie->{_interp};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' interp=' . $xmovie->{_interp};

	}
	else {
		print("xmovie, interp, missing interp,\n");
	}
}

=head2 sub label1 

ylabel or label1

=cut

sub label1 {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$xmovie->{_label1} = $label1;
		$xmovie->{_note}   = $xmovie->{_note} . ' label1=' . $xmovie->{_label1};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' label1=' . $xmovie->{_label1};

	}
	else {
		print("xmovie, label1, missing label1,\n");
	}
}

=head2 sub label2 

xlabel or label2


=cut

sub label2 {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$xmovie->{_label2} = $label2;
		$xmovie->{_note}   = $xmovie->{_note} . ' label2=' . $xmovie->{_label2};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' label2=' . $xmovie->{_label2};

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

		$xmovie->{_labelFont} = $labelFont;
		$xmovie->{_note} =
			$xmovie->{_note} . ' labelFont=' . $xmovie->{_labelFont};
		$xmovie->{_Step} =
			$xmovie->{_Step} . ' labelFont=' . $xmovie->{_labelFont};

	}
	else {
		print("xmovie, labelFont, missing labelFont,\n");
	}
}


=head2 sub loclip 

subs bclip or loclip or low_clip

=cut

sub loclip {

	my ( $self, $bclip) = @_;
	if ( $bclip ne $empty_string ) {

		$xmovie->{_bclip} = $bclip;
		$xmovie->{_note}  = $xmovie->{_note} . ' bclip=' . $xmovie->{_bclip};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' bclip=' . $xmovie->{_bclip};

	}
	else {
		print("xmovie, loclip, missing bclip,\n");
	}
}


=head2 sub low_clip 

subs bclip or loclip or low_clip

=cut

sub low_clip {

	my ( $self, $bclip) = @_;
	if ( $bclip ne $empty_string ) {

		$xmovie->{_bclip} = $bclip;
		$xmovie->{_note}  = $xmovie->{_note} . ' bclip=' . $xmovie->{_bclip};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' bclip=' . $xmovie->{_bclip};

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

		$xmovie->{_loop} = $loop;
		$xmovie->{_note} = $xmovie->{_note} . ' loop=' . $xmovie->{_loop};
		$xmovie->{_Step} = $xmovie->{_Step} . ' loop=' . $xmovie->{_loop};

	}
	else {
		print("xmovie, loop, missing loop,\n");
	}
}

=head2 sub n1 


=cut

sub n1 {

	my ( $self, $n1 ) = @_;
	if ( $n1 ne $empty_string ) {

		$xmovie->{_n1}   = $n1;
		$xmovie->{_note} = $xmovie->{_note} . ' n1=' . $xmovie->{_n1};
		$xmovie->{_Step} = $xmovie->{_Step} . ' n1=' . $xmovie->{_n1};

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

		$xmovie->{_n2}   = $n2;
		$xmovie->{_note} = $xmovie->{_note} . ' n2=' . $xmovie->{_n2};
		$xmovie->{_Step} = $xmovie->{_Step} . ' n2=' . $xmovie->{_n2};

	}
	else {
		print("xmovie, n2, missing n2,\n");
	}
}

=head2 sub nTic1 


=cut

sub nTic1 {

	my ( $self, $nTic1 ) = @_;
	if ( $nTic1 ne $empty_string ) {

		$xmovie->{_nTic1} = $nTic1;
		$xmovie->{_note}  = $xmovie->{_note} . ' nTic1=' . $xmovie->{_nTic1};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' nTic1=' . $xmovie->{_nTic1};

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

		$xmovie->{_nTic2} = $nTic2;
		$xmovie->{_note}  = $xmovie->{_note} . ' nTic2=' . $xmovie->{_nTic2};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' nTic2=' . $xmovie->{_nTic2};

	}
	else {
		print("xmovie, nTic2, missing nTic2,\n");
	}
}

=head2 sub perc 


=cut

sub perc {

	my ( $self, $perc ) = @_;
	if ( $perc ne $empty_string ) {

		$xmovie->{_perc} = $perc;
		$xmovie->{_note} = $xmovie->{_note} . ' perc=' . $xmovie->{_perc};
		$xmovie->{_Step} = $xmovie->{_Step} . ' perc=' . $xmovie->{_perc};

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

		$xmovie->{_sat}  = $sat;
		$xmovie->{_note} = $xmovie->{_note} . ' sat=' . $xmovie->{_sat};
		$xmovie->{_Step} = $xmovie->{_Step} . ' sat=' . $xmovie->{_sat};

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

		$xmovie->{_sleep} = $sleep;
		$xmovie->{_note}  = $xmovie->{_note} . ' sleep=' . $xmovie->{_sleep};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' sleep=' . $xmovie->{_sleep};

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

		$xmovie->{_style} = $style;
		$xmovie->{_note}  = $xmovie->{_note} . ' style=' . $xmovie->{_style};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' style=' . $xmovie->{_style};

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

		$xmovie->{_title} = $title;
		$xmovie->{_note}  = $xmovie->{_note} . ' title=' . $xmovie->{_title};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' title=' . $xmovie->{_title};

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

		$xmovie->{_titleColor} = $titleColor;
		$xmovie->{_note} =
			$xmovie->{_note} . ' titleColor=' . $xmovie->{_titleColor};
		$xmovie->{_Step} =
			$xmovie->{_Step} . ' titleColor=' . $xmovie->{_titleColor};

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

		$xmovie->{_titleFont} = $titleFont;
		$xmovie->{_note} =
			$xmovie->{_note} . ' titleFont=' . $xmovie->{_titleFont};
		$xmovie->{_Step} =
			$xmovie->{_Step} . ' titleFont=' . $xmovie->{_titleFont};

	}
	else {
		print("xmovie, titleFont, missing titleFont,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$xmovie->{_verbose} = $verbose;
		$xmovie->{_note} = $xmovie->{_note} . ' verbose=' . $xmovie->{_verbose};
		$xmovie->{_Step} = $xmovie->{_Step} . ' verbose=' . $xmovie->{_verbose};

	}
	else {
		print("xmovie, verbose, missing verbose,\n");
	}
}

=head2 sub wclip 

subs hiclip or wclip or high_clip

=cut

sub wclip {

	my ( $self, $wclip ) = @_;
	if ( $wclip ne $empty_string ) {

		$xmovie->{_wclip} = $wclip;
		$xmovie->{_note}  = $xmovie->{_note} . ' wclip=' . $xmovie->{_wclip};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' wclip=' . $xmovie->{_wclip};

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

		$xmovie->{_white} = $white;
		$xmovie->{_note}  = $xmovie->{_note} . ' white=' . $xmovie->{_white};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' white=' . $xmovie->{_white};

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

		$xmovie->{_whue} = $whue;
		$xmovie->{_note} = $xmovie->{_note} . ' whue=' . $xmovie->{_whue};
		$xmovie->{_Step} = $xmovie->{_Step} . ' whue=' . $xmovie->{_whue};

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

		$xmovie->{_width} = $width;
		$xmovie->{_note}  = $xmovie->{_note} . ' width=' . $xmovie->{_width};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' width=' . $xmovie->{_width};

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

		$xmovie->{_windowtitle} = $windowtitle;
		$xmovie->{_note} =
			$xmovie->{_note} . ' windowtitle=' . $xmovie->{_windowtitle};
		$xmovie->{_Step} =
			$xmovie->{_Step} . ' windowtitle=' . $xmovie->{_windowtitle};

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

		$xmovie->{_wperc} = $wperc;
		$xmovie->{_note}  = $xmovie->{_note} . ' wperc=' . $xmovie->{_wperc};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' wperc=' . $xmovie->{_wperc};

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

		$xmovie->{_x1beg} = $x1beg;
		$xmovie->{_note}  = $xmovie->{_note} . ' x1beg=' . $xmovie->{_x1beg};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' x1beg=' . $xmovie->{_x1beg};

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

		$xmovie->{_x1end} = $x1end;
		$xmovie->{_note}  = $xmovie->{_note} . ' x1end=' . $xmovie->{_x1end};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' x1end=' . $xmovie->{_x1end};

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

		$xmovie->{_x2beg} = $x2beg;
		$xmovie->{_note}  = $xmovie->{_note} . ' x2beg=' . $xmovie->{_x2beg};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' x2beg=' . $xmovie->{_x2beg};

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

		$xmovie->{_x2end} = $x2end;
		$xmovie->{_note}  = $xmovie->{_note} . ' x2end=' . $xmovie->{_x2end};
		$xmovie->{_Step}  = $xmovie->{_Step} . ' x2end=' . $xmovie->{_x2end};

	}
	else {
		print("xmovie, x2end, missing x2end,\n");
	}
}

=head2 sub xlabel 

xlabel or label2


=cut

sub xlabel {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$xmovie->{_label2} = $label2;
		$xmovie->{_note}   = $xmovie->{_note} . ' label2=' . $xmovie->{_label2};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' label2=' . $xmovie->{_label2};

	}
	else {
		print("xmovie, xlabel, missing label2,\n");
	}
}

=head2 sub label1 


ylabel or label1

=cut

sub ylabel {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$xmovie->{_label1} = $label1;
		$xmovie->{_note}   = $xmovie->{_note} . ' label1=' . $xmovie->{_label1};
		$xmovie->{_Step}   = $xmovie->{_Step} . ' label1=' . $xmovie->{_label1};

	}
	else {
		print("xmovie, ylabel, missing label1,\n");
	}
}


=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 44;

	return ($max_index);
}

1;
