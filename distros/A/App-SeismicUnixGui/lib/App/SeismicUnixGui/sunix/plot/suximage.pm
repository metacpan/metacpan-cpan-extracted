package App::SeismicUnixGui::sunix::plot::suximage;

=head1 DOCUMENTATION

=head2 SYNOPSIS

SUXIMAGE also inherits parameters from XIMAGE (See below)

 PERL PROGRAM NAME:  SUXIMAGE - X-windows IMAGE plot of a segy data set	                
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE$new_dt_s

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUXIMAGE - X-windows IMAGE plot of a segy data set	                

 suximage infile= [optional parameters] | ...  (direct I/O)            
  or					                		
 suximage <stdin [optional parameters] | ...	(sequential I/O)        

 Optional parameters:						 	

 infile=NULL SU data to be ploted, default stdin with sequential access
             if 'infile' provided, su data read by (fast) direct access

	      with ftr,dtr and n2 suximage will pass a subset of data   
	      to the plotting program-ximage:                           
 ftr=1       First trace to be plotted                                 
 dtr=1       Trace increment to be plotted                             
 n2=tr.ntr   (Max) number of traces to be plotted (ntr is an alias for n2)
	      Priority: first try to read from parameter line;		
		        if not provided, check trace header tr.ntr;     
		        if still not provided, figure it out using ftello

 d1=tr.d1 or tr.dt/10^6	sampling interval in the fast dimension	
   =.004 for seismic 		(if not set)				
   =1.0 for nonseismic		(if not set)				

 d2=tr.d2		sampling interval in the slow dimension	        
   =1.0 		(if not set or was set to 0)		        

 key=			key for annotating d2 (slow dimension)		
 			If annotation is not at proper increment, try	
 			setting d2; only first trace's key value is read

 f1=tr.f1 or tr.delrt/10^3 or 0.0  first sample in the fast dimension	

 f2=tr.f2 or tr.tracr or tr.tracl  first sample in the slow dimension	
   =1.0 for seismic		    (if not set)			
   =d2 for nonseismic		    (if not set)			

 verbose=0             =1 to print some useful information		

 tmpdir=	 	if non-empty, use the value as a directory path	
		 	prefix for storing temporary files; else if the	
	         	the CWP_TMPDIR environment variable is set use	
	         	its value for the path; else use tmpfile()	

 Note that for seismic time domain data, the "fast dimension" is	
 time and the "slow dimension" is usually trace number or range.	
 Also note that "foreign" data tapes may have something unexpected	
 in the d2,f2 fields, use segyclean to clear these if you can afford	
 the processing time or use d2= f2= to override the header values if	
 not.									

 See the ximage selfdoc for the remaining parameters.		        


 Credits:

	CWP: Dave Hale and Zhiming Li (ximage, etc.)
	   Jack Cohen and John Stockwell (suximage, etc.)
	MTU: David Forel, June 2004, added key for annotating d2
      ConocoPhillips: Zhaobo Meng, Dec 2004, added direct I/O

 Notes:

      When provide ftr and dtr and infile, suximage can be used to plot 
      multi-dimensional volumes efficiently.  For example, for a Offset-CDP
      dataset with 32 offsets, the command line
      suximage infile=volume3d.su ftr=1 dtr=32 ... &
      will display the zero-offset common offset data with ranrom access.  
      It is highly recommend to use infile= to view large datasets, since
      using stdin only allows sequential access, which is very slow for 
      large datasets.

	When the number of traces isn't known, we need to count
	the traces for ximage.  You can make this value "known"
	either by getparring n2 or by having the ntr field set
	in the trace header.  A getparred value takes precedence
	over the value in the trace header.

	When we must compute ntr, we don't allocate a 2-d array,
	but just content ourselves with copying trace by trace from
	the data "file" to the pipe into the plotting program.
	Although we could use tr.data, we allocate a trace buffer
	for code clarity.
	

 The parameters of the following seismic unix programs
 also applies to the current package suximage

XIMAGE - X IMAGE plot of a uniformly-sampled function f(x1,x2)     	
									
 ximage n1= [optional parameters] <binaryfile			        
									
 X Functionality:							
 Button 1	Zoom with rubberband box				
 Button 2	Show mouse (x1,x2) coordinates while pressed		
 q or Q key	Quit							
 s key		Save current mouse (x1,x2) location to file		
 p or P key	Plot current window with pswigb (only from disk files)	
 a or page up keys		enhance clipping by 10%			
 c or page down keys		reduce clipping by 10%			
 up,down,left,right keys	move zoom window by half width/height	
 i or +(keypad) 		zoom in by factor 2 			
 o or -(keypad) 		zoom out by factor 2 			
									
 ... change colormap interactively					
 r	     install next RGB - colormap				
 R	     install previous RGB - colormap				
 h	     install next HSV - colormap				
 H	     install previous HSV - colormap				
 H	     install previous HSV - colormap				
 (Move mouse cursor out and back into window for r,R,h,H to take effect)
 									
 Required Parameters:			#				
 n1			 number of samples in 1st (fast) dimension	
									
 Optional Parameters:							
 d1=1.0		 sampling interval in 1st dimension		
 f1=0.0		 first sample in 1st dimension			
 n2=all		 number of samples in 2nd (slow) dimension	
 d2=1.0		 sampling interval in 2nd dimension		
 f2=0.0		 first sample in 2nd dimension			
 mpicks=/dev/tty	 file to save mouse picks in			
 perc=100.0		 percentile used to determine clip		
 clip=(perc percentile) clip used to determine bclip and wclip		
 bperc=perc		 percentile for determining black clip value	
 wperc=100.0-perc	 percentile for determining white clip value	
 bclip=clip		 data values outside of [bclip,wclip] are clipped
 wclip=-clip		 data values outside of [bclip,wclip] are clipped
 balance=0		 bclip & wclip individually			
			 =1 set them to the same abs value		
			   if specified via perc (avoids colorbar skew)	
 cmap=hsv'n' or rgb'm'	'n' is a number from 0 to 13		
				'm' is a number from 0 to 11		
				cmap=rgb0 is equal to cmap=gray		
				cmap=hsv1 is equal to cmap=hue		
				(compatibility to older versions)	
 legend=0	        =1 display the color scale			
 units=		unit label for legend				
 legendfont=times_roman10    font name for title			
 verbose=1		=1 for info printed on stderr (0 for no info)	
 xbox=50		x in pixels of upper left corner of window	
 ybox=50		y in pixels of upper left corner of window	
 wbox=550		width in pixels of window			
 hbox=700		height in pixels of window			
 lwidth=16		colorscale (legend) width in pixels		
 lheight=hbox/3	colorscale (legend) height in pixels		
 lx=3			colorscale (legend) x-position in pixels	
 ly=(hbox-lheight)/3   colorscale (legend) y-position in pixels	
 x1beg=x1min		value at which axis 1 begins			
 x1end=x1max		value at which axis 1 ends			
 d1num=0.0		numbered tic interval on axis 1 (0.0 for automatic)
 f1num=x1min		first numbered tic on axis 1 (used if d1num not 0.0)
 n1tic=1		number of tics per numbered tic on axis 1	
 grid1=none		grid lines on axis 1 - none, dot, dash, or solid
 label1=		label on axis 1					
 x2beg=x2min		value at which axis 2 begins			
 x2end=x2max		value at which axis 2 ends			
 d2num=0.0		numbered tic interval on axis 2 (0.0 for automatic)
 f2num=x2min		first numbered tic on axis 2 (used if d2num not 0.0)
 n2tic=1		number of tics per numbered tic on axis 2	
 grid2=none		grid lines on axis 2 - none, dot, dash, or solid
 label2=		label on axis 2					
 labelfont=Erg14	font name for axes labels			
 title=		title of plot					
 titlefont=Rom22	font name for title				
 windowtitle=ximage	title on window					
 labelcolor=blue	color for axes labels				
 titlecolor=red	color for title					
 gridcolor=blue	color for grid lines				
 style=seismic	$        normal (axis 1 horizontal, axis 2 vertical) or  
			seismic (axis 1 vertical, axis 2 horizontal)	
 blank=0		This indicates what portion of the lower range  
			to blank out (make the background color).  The  
			value should range from 0 to 1.			
 plotfile=plotfile.ps  filename for interactive ploting (P)  		
 curve=curve1,curve2,...  file(s) containing points to draw curve(s)   
 npair=n1,n2,n2,...            number(s) of pairs in each file         
 curvecolor=color1,color2,...  color(s) for curve(s)                   
 blockinterp=0       whether to use block interpolation (0=no, 1=yes)
 curvewidth

 NOTES:								
 The curve file is an ascii file with the points  specified as x1 x2	
 pairs separated by a space, one pair to a line.  A "vector" of curve
 files and curv$e colors may be specified as curvefile=file1,file2,etc. 
 and curvecolor=color1,color2,etc, and the number of pairs of values   
 in each file as npair=npair1,npair2,... .
 
 JML:9-1-19                     curvefile=file1,file2,file3 fails
Perl wrapper automatically substitutes with: curve=file1,file2,file3


SUXIMAGE - X-windows IMAGE plot of a segy data set	                
									
 suximage infile= [optional parameters] | ...  (direct I/O)            
  or					                		
 suximage <stdin [optional parameters] | ...	(sequential I/O)        
									
 Optional parameters:						 	
									
 infile=NULL SU data to be ploted, default stdin with sequential access
             if 'infile' provided, su data read by (fast) direct access
									
	      with ftr,dtr and n2 suximage will pass a subset of data   
	      to the plotting program-ximage:                           
 ftr=1       First trace to be plotted                                 
 dtr=1       Trace increment to be plotted                             
 n2=tr.ntr   (Max) number of traces to be plotted (ntr is an alias for n2)
	      Priority: first try to read from parameter line;		
		        if not provided, check trace header tr.ntr;     
		        if still not provided, figure it out using ftello
									
 d1=tr.d1 or tr.dt/10^6	sampling interval in the fast dimension	
   =.004 for seismic 		(if not set)				
   =1.0 for nonseismic		(if not set)				
 							        	
 d2=tr.d2		sampling interval in the slow dimension	        
   =1.0 		(if not set or was set to 0)		        
									
 key=			key for annotating d2 (slow dimension)		
 			If annotation is not at proper increment, try	
 			setting d2; only first trace's key value is read
 							        	
 f1=tr.f1 or tr.delrt/10^3 or 0.0  first sample in the fast dimension	
 							        	
 f2=tr.f2 or tr.tracr or tr.tracl  first sample in the slow dimension	
   =1.0 for seismic		    (if not set)			
   =d2 for nonseismic		    (if not set)			
 							        	
 verbose=0             =1 to print some useful information		
									
 tmpdir=	 	if non-empty, use the value as a directory path	
		 	prefix for storing temporary files; else if the	
	         	the CWP_TMPDIR environment variable is set use	
	         	its value for the path; else use tmpfile()	
 									
 Note that for seismic time domain data, the "fast dimension" is	
 time and the "slow dimension" is usually trace number or range.	
 Also note that "foreign" data tapes may have something unexpected	
 in the d2,f2 fields, use segyclean to clear these if you can afford	
 the processing time or use d2= f2= to override the header values if
 not.									
									
 See the ximage selfdoc for the remaining parameters.

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suximage = {
    _balance     => '',
    _bclip       => '',
    _blank       => '',
    _blockinterp => '',
    _bperc       => '',
    _clip        => '',
    _cmap        => '',
    _curve       => '',
    _curvecolor  => '',
    _curvefile   => '',
    _curvewidth	 => '',
    _d1          => '',
    _d1num       => '',
    _d2          => '',
    _d2num       => '',
    _dtr         => '',
    _f1          => '',
    _f1num       => '',
    _f2          => '',
    _f2num       => '',
    _grid1       => '',
    _grid2       => '',
    _gridcolor   => '',
    _hbox        => '',
    _infile      => '',
    _key         => '',
    _label1      => '',
    _label2      => '',
    _labelcolor  => '',
    _labelfont   => '',
    _legend      => '',
    _legendfont  => '',
    _lheight     => '',
    _lwidth      => '',
    _lx          => '',
    _ly          => '',
    _mpicks      => '',
    _n1          => '',
    _n1tic       => '',
    _n2          => '',
    _n2tic       => '',
    _npair       => '',
    _perc        => '',
    _plotfile    => '',
    _style       => '',
    _title       => '',
    _titlecolor  => '',
    _titlefont   => '',
    _tmpdir      => '',
    _units       => '',
    _verbose     => '',
    _wbox        => '',
    _wclip       => '',
    _windowtitle => '',
    _wperc       => '',
    _x1beg       => '',
    _x1end       => '',
    _x2beg       => '',
    _x2end       => '',
    _xbox        => '',
    _ybox        => '',
    _Step        => '',
    _note        => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suximage->{_Step} = 'suximage' . $suximage->{_Step};
    return ( $suximage->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suximage->{_note} = 'suximage' . $suximage->{_note};
    return ( $suximage->{_note} );

}

=head2 sub clear

 56 +2 items
 
=cut

sub clear {

    $suximage->{_balance}     = '';
    $suximage->{_bclip}       = '';
    $suximage->{_blank}       = '';
    $suximage->{_blockinterp} = '';
    $suximage->{_bperc}       = '';
    $suximage->{_clip}        = '';
    $suximage->{_cmap}        = '';
    $suximage->{_curve}       = '';
    $suximage->{_curvecolor}  = '';
    $suximage->{_curvefile}   = '';
    $suximage->{_curvewidth}  = '';    
    $suximage->{_d1}          = '';
    $suximage->{_d1num}       = '';
    $suximage->{_d2}          = '';
    $suximage->{_d2num}       = '';
    $suximage->{_dtr}         = '';
    $suximage->{_f1}          = '';
    $suximage->{_f1num}       = '';
    $suximage->{_f2}          = '';
    $suximage->{_f2num}       = '';
    $suximage->{_ftr}         = '';
    $suximage->{_grid1}       = '';
    $suximage->{_grid2}       = '';
    $suximage->{_gridcolor}   = '';
    $suximage->{_hbox}        = '';
    $suximage->{_infile}      = '';
    $suximage->{_key}         = '';
    $suximage->{_label1}      = '';
    $suximage->{_label2}      = '';
    $suximage->{_labelcolor}  = '';
    $suximage->{_labelfont}   = '';
    $suximage->{_legend}      = '';
    $suximage->{_legendfont}  = '';
    $suximage->{_lheight}     = '';
    $suximage->{_lwidth}      = '';
    $suximage->{_lx}          = '';
    $suximage->{_ly}          = '';
    $suximage->{_mpicks}      = '';
    $suximage->{_n1}          = '';
    $suximage->{_n1tic}       = '';
    $suximage->{_n2}          = '';
    $suximage->{_n2tic}       = '';
    $suximage->{_npair}       = '';
    $suximage->{_perc}        = '';
    $suximage->{_plotfile}    = '';
    $suximage->{_style}       = '';
    $suximage->{_title}       = '';
    $suximage->{_titlecolor}  = '';
    $suximage->{_titlefont}   = '';
    $suximage->{_tmpdir}      = '';
    $suximage->{_units}       = '';
    $suximage->{_verbose}     = '';
    $suximage->{_wbox}        = '';
    $suximage->{_wclip}       = '';
    $suximage->{_windowtitle} = '';
    $suximage->{_wperc}       = '';
    $suximage->{_x1beg}       = '';
    $suximage->{_x1end}       = '';
    $suximage->{_x2beg}       = '';
    $suximage->{_x2end}       = '';
    $suximage->{_xbox}        = '';
    $suximage->{_ybox}        = '';
    $suximage->{_Step}        = '';
    $suximage->{_note}        = '';
}

=head2 sub dtr 


=cut

sub dtr {

    my ( $self, $dtr ) = @_;
    if ( $dtr ne $empty_string ) {

        $suximage->{_dtr}  = $dtr;
        $suximage->{_note} = $suximage->{_note} . ' dtr=' . $suximage->{_dtr};
        $suximage->{_Step} = $suximage->{_Step} . ' dtr=' . $suximage->{_dtr};

    }
    else {
        print("suximage, dtr, missing dtr,\n");
    }
}

=head2 sub ftr 


=cut

sub ftr {

    my ( $self, $ftr ) = @_;
    if ( $ftr ne $empty_string ) {

        $suximage->{_ftr}  = $ftr;
        $suximage->{_note} = $suximage->{_note} . ' ftr=' . $suximage->{_ftr};
        $suximage->{_Step} = $suximage->{_Step} . ' ftr=' . $suximage->{_ftr};

    }
    else {
        print("suximage, ftr, missing ftr,\n");
    }
}

=head2 sub headerword 

same as key


=cut

sub headerword {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suximage->{_key}  = $key;
        $suximage->{_note} = $suximage->{_note} . ' key=' . $suximage->{_key};
        $suximage->{_Step} = $suximage->{_Step} . ' key=' . $suximage->{_key};

    }
    else {
        print("suximage, key, missing key,\n");
    }
}

=head2 sub infile 


=cut

sub infile {

    my ( $self, $infile ) = @_;
    if ( $infile ne $empty_string ) {

        $suximage->{_infile} = $infile;
        $suximage->{_note} =
          $suximage->{_note} . ' infile=' . $suximage->{_infile};
        $suximage->{_Step} =
          $suximage->{_Step} . ' infile=' . $suximage->{_infile};

    }
    else {
        print("suximage, infile, missing infile,\n");
    }
}

=head2 sub key 

headerword is equivalent

=cut

sub key {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suximage->{_key}  = $key;
        $suximage->{_note} = $suximage->{_note} . ' key=' . $suximage->{_key};
        $suximage->{_Step} = $suximage->{_Step} . ' key=' . $suximage->{_key};

    }
    else {
        print("suximage, key, missing key,\n");
    }
}

=head2 sub absclip

determine the absolute clip for data

=cut

sub absclip {
    my ( $variable, $clip ) = @_;
    $suximage->{_clip} = $clip if defined($clip);
    $suximage->{_Step} = $suximage->{_Step} . ' clip=' . $suximage->{_clip};
    $suximage->{_note} = $suximage->{_note};
}

=head2 sub balance 


=cut

sub balance {

    my ( $self, $balance ) = @_;
    if ( $balance ne $empty_string ) {

        $suximage->{_balance} = $balance;
        $suximage->{_note} =
          $suximage->{_note} . ' balance=' . $suximage->{_balance};
        $suximage->{_Step} =
          $suximage->{_Step} . ' balance=' . $suximage->{_balance};

    }
    else {
        print("suximage, balance, missing balance,\n");
    }
}

=head2 sub bclip 

 subs loclip bclip

=cut

sub bclip {

    my ( $self, $bclip ) = @_;
    if ( $bclip ne $empty_string ) {

        $suximage->{_bclip} = $bclip;
        $suximage->{_note} =
          $suximage->{_note} . ' bclip=' . $suximage->{_bclip};
        $suximage->{_Step} =
          $suximage->{_Step} . ' bclip=' . $suximage->{_bclip};

    }
    else {
        print("suximage, bclip, missing bclip,\n");
    }
}

=head2 sub blank 


=cut

sub blank {

    my ( $self, $blank ) = @_;
    if ( $blank ne $empty_string ) {

        $suximage->{_blank} = $blank;
        $suximage->{_note} =
          $suximage->{_note} . ' blank=' . $suximage->{_blank};
        $suximage->{_Step} =
          $suximage->{_Step} . ' blank=' . $suximage->{_blank};

    }
    else {
        print("suximage, blank, missing blank,\n");
    }
}

=head2 sub blockinterp 


=cut

sub blockinterp {

    my ( $self, $blockinterp ) = @_;
    if ( $blockinterp ne $empty_string ) {

        $suximage->{_blockinterp} = $blockinterp;
        $suximage->{_note} =
          $suximage->{_note} . ' blockinterp=' . $suximage->{_blockinterp};
        $suximage->{_Step} =
          $suximage->{_Step} . ' blockinterp=' . $suximage->{_blockinterp};

    }
    else {
        print("suximage, blockinterp, missing blockinterp,\n");
    }
}

=head2 sub box_X0


=cut

sub box_X0 {

    my ( $self, $xbox ) = @_;
    if ( $xbox ne $empty_string ) {

        $suximage->{_xbox} = $xbox;
        $suximage->{_note} =
          $suximage->{_note} . ' xbox=' . $suximage->{_xbox};
        $suximage->{_Step} =
          $suximage->{_Step} . ' xbox=' . $suximage->{_xbox};

    }
    else {
        print("suximage, wbox, missing box_X0,\n");
    }
}

=head2 sub box_Y0


=cut

sub box_Y0 {

    my ( $self, $ybox ) = @_;
    if ( $ybox ne $empty_string ) {

        $suximage->{_ybox} = $ybox;
        $suximage->{_note} =
          $suximage->{_note} . ' ybox=' . $suximage->{_ybox};
        $suximage->{_Step} =
          $suximage->{_Step} . ' ybox=' . $suximage->{_ybox};

    }
    else {
        print("suximage, box_Y0, missing box_Y0,\n");
    }
}

=head2 sub box_height 


=cut

sub box_height {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $suximage->{_hbox} = $hbox;
        $suximage->{_note} =
          $suximage->{_note} . ' hbox=' . $suximage->{_hbox};
        $suximage->{_Step} =
          $suximage->{_Step} . ' hbox=' . $suximage->{_hbox};

    }
    else {
        print("suximage, hbox, missing box_height,\n");
    }
}

=head2 sub box_width 


=cut

sub box_width {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $suximage->{_wbox} = $wbox;
        $suximage->{_note} =
          $suximage->{_note} . ' wbox=' . $suximage->{_wbox};
        $suximage->{_Step} =
          $suximage->{_Step} . ' wbox=' . $suximage->{_wbox};

    }
    else {
        print("suximage, wbox, missing box_width,\n");
    }
}

=head2 sub bperc 


=cut

sub bperc {

    my ( $self, $bperc ) = @_;
    if ( $bperc ne $empty_string ) {

        $suximage->{_bperc} = $bperc;
        $suximage->{_note} =
          $suximage->{_note} . ' bperc=' . $suximage->{_bperc};
        $suximage->{_Step} =
          $suximage->{_Step} . ' bperc=' . $suximage->{_bperc};

    }
    else {
        print("suximage, bperc, missing bperc,\n");
    }
}

=head2 sub clip 

determine the absolute clip for data

=cut

sub clip {

    my ( $self, $clip ) = @_;
    if ( $clip ne $empty_string ) {

        $suximage->{_clip} = $clip;
        $suximage->{_note} =
          $suximage->{_note} . ' clip=' . $suximage->{_clip};
        $suximage->{_Step} =
          $suximage->{_Step} . ' clip=' . $suximage->{_clip};

    }
    else {
        print("suximage, clip, missing clip,\n");
    }
}

=head2 sub cmap 


=cut

sub cmap {

    my ( $self, $cmap ) = @_;
    if ( $cmap ne $empty_string ) {

        $suximage->{_cmap} = $cmap;
        $suximage->{_note} =
          $suximage->{_note} . ' cmap=' . $suximage->{_cmap};
        $suximage->{_Step} =
          $suximage->{_Step} . ' cmap=' . $suximage->{_cmap};

    }
    else {
        print("suximage, cmap, missing cmap,\n");
    }
}

=head2 sub curve 


=cut

sub curve {

    my ( $self, $curve ) = @_;
    if ( $curve ne $empty_string ) {

        $suximage->{_curve} = $curve;
        $suximage->{_note} =
          $suximage->{_note} . ' curve=' . $suximage->{_curve};
        $suximage->{_Step} =
          $suximage->{_Step} . ' curve=' . $suximage->{_curve};
    }
    else {
        print("suximage, curve, missing curve,\n");
    }
}

=head2 sub curvecolor 

 color of curves

=cut

sub curvecolor {

    my ( $self, $curvecolor ) = @_;
    if ( $curvecolor ne $empty_string ) {

        $suximage->{_curvecolor} = $curvecolor;
        $suximage->{_note} =
          $suximage->{_note} . ' curvecolor=' . $suximage->{_curvecolor};
        $suximage->{_Step} =
          $suximage->{_Step} . ' curvecolor=' . $suximage->{_curvecolor};

    }
    else {
        print("suximage, curvecolor, missing curvecolor,\n");
    }
}

=head2 sub curvefile 

 name of ascii file containing plotting points

=cut

sub curvefile {

    my ( $self, $curvefile ) = @_;
    if ( $curvefile ne $empty_string ) {

        $suximage->{_curvefile} = $curvefile;
        $suximage->{_note} =
          $suximage->{_note} . ' curve=' . $suximage->{_curvefile};
        $suximage->{_Step} =
          $suximage->{_Step} . ' curve=' . $suximage->{_curvefile};
    }
    else {
        print("suximage, curvefile, missing curvefile,\n");
    }
}

=head2 sub curvewidth 

 name of ascii file containing plotting points

=cut

sub curvewidth {

    my ( $self, $curvewidth ) = @_;
    if ( $curvewidth ne $empty_string ) {

        $suximage->{_curvewidth} = $curvewidth;
        $suximage->{_note} =
          $suximage->{_note} . ' curvewidth=' . $suximage->{_curvewidth};
        $suximage->{_Step} =
          $suximage->{_Step} . ' curvewidth=' . $suximage->{_curvewidth};

    }
    else {
        print("suximage, curvewidth, missing curvewidth,\n");
    }
}

=head2 sub d1 

 subs d1 and dt and dz and dt_s

 increment in fast dimension
 usually time and equal to dt

=cut

sub d1 {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $suximage->{_d1}   = $d1;
        $suximage->{_note} = $suximage->{_note} . ' d1=' . $suximage->{_d1};
        $suximage->{_Step} = $suximage->{_Step} . ' d1=' . $suximage->{_d1};

    }
    else {
        print("suximage, d1, missing d1,\n");
    }
}

=head2 sub d1num 

  subs d1num , y_tick_increment dy_major_divisions dt_major_divisions

  numbered tick interval in fast dimension(t)

=cut

sub d1num {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $suximage->{_d1num} = $d1num;
        $suximage->{_note} =
          $suximage->{_note} . ' d1num=' . $suximage->{_d1num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' d1num=' . $suximage->{_d1num};

    }
    else {
        print("suximage, d1num, missing d1num,\n");
    }
}

=head2 sub d2 

	subs d2 and trace_in
	
     only the first trace is read in
     if an increment is not 1 between traces
     you should indicate here

=cut

sub d2 {

    my ( $self, $d2 ) = @_;
    if ( $d2 ne $empty_string ) {

        $suximage->{_d2}   = $d2;
        $suximage->{_note} = $suximage->{_note} . ' d2=' . $suximage->{_d2};
        $suximage->{_Step} = $suximage->{_Step} . ' d2=' . $suximage->{_d2};

    }
    else {
        print("suximage, d2, missing d2,\n");
    }
}

=head2 sub  dt_major_divisions

  subs d1num , y_tick_increment dy_major_divisions dt_major_divisions

  numbered tick interval in fast dimension(t)

=cut

sub dt_major_divisions {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $suximage->{_d1num} = $d1num;
        $suximage->{_note} =
          $suximage->{_note} . ' d1num=' . $suximage->{_d1num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' d1num=' . $suximage->{_d1num};

    }
    else {
        print("suximage, dt_major_divisions, missing dt_major_divisions,\n");
    }
}

=head2 sub dx 

     only the first trace is read in
     if an increment is not 1 between traces
     you should indicate here

=cut

sub dx {

    my ( $self, $d2 ) = @_;
    if ( $d2 ne $empty_string ) {

        $suximage->{_d2}   = $d2;
        $suximage->{_note} = $suximage->{_note} . ' d2=' . $suximage->{_d2};
        $suximage->{_Step} = $suximage->{_Step} . ' d2=' . $suximage->{_d2};

    }
    else {
        print("suximage, dx, missing dx,\n");
    }
}

=head2 sub  dy_major_divisions

  subs d1num , y_tick_increment dy_major_divisions dt_major_divisions

  numbered tick interval in fast dimension(t)

=cut

sub dy_major_divisions {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $suximage->{_d1num} = $d1num;
        $suximage->{_note} =
          $suximage->{_note} . ' d1num=' . $suximage->{_d1num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' d1num=' . $suximage->{_d1num};

    }
    else {
        print("suximage, dy_major_divisions, missing dy_major_divisions,\n");
    }
}

=head2  sub d2num

	subs d2num  dx_major_divisions and x_tick_increment
    numbered tick interval

=cut

sub d2num {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $suximage->{_d2num} = $d2num;
        $suximage->{_note} =
          $suximage->{_note} . ' d2num=' . $suximage->{_d2num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' d2num=' . $suximage->{_d2num};

    }
    else {
        print("suximage, d2num, missing d2num,\n");
    }
}

=head2 sub dt 

 subs d1 and dt and dz and dt_s

 increment in fast dimension
 usually time and equal to dt

=cut

sub dt {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $suximage->{_d1}   = $d1;
        $suximage->{_note} = $suximage->{_note} . ' d1=' . $suximage->{_d1};
        $suximage->{_Step} = $suximage->{_Step} . ' d1=' . $suximage->{_d1};

    }
    else {
        print("suximage, dt, missing dt,\n");
    }
}

=head2 sub dt_s 

 subs d1 and dt and dz and dt_s

 increment in fast dimension
 usually time and equal to dt

=cut

sub dt_s {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $suximage->{_d1}   = $d1;
        $suximage->{_note} = $suximage->{_note} . ' d1=' . $suximage->{_d1};
        $suximage->{_Step} = $suximage->{_Step} . ' d1=' . $suximage->{_d1};

    }
    else {
        print("suximage, dt_s, missing dt_s,\n");
    }
}

=head2 sub dx_major_divisions

 	subs d2num  dx_major_divisions and x_tick_increment
	numbered tick interval

=cut

sub dx_major_divisions {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $suximage->{_d2num} = $d2num;
        $suximage->{_note} =
          $suximage->{_note} . ' d2num=' . $suximage->{_d2num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' d2num=' . $suximage->{_d2num};

    }
    else {
        print("suximage, dx_major_divisions, missing dx_major_divisions,\n");
    }
}

=head2 sub dy_minor_divisions 

 subs dy_minor_divisions n1tic and num_minor_ticks_betw_time_ticks 

 n1tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)	


=cut

sub dy_minor_divisions {

    my ( $self, $n1tic ) = @_;
    if ( $n1tic ne $empty_string ) {

        $suximage->{_n1tic} = $n1tic;
        $suximage->{_note} =
          $suximage->{_note} . ' n1tic=' . $suximage->{_n1tic};
        $suximage->{_Step} =
          $suximage->{_Step} . ' n1tic=' . $suximage->{_n1tic};

    }
    else {
        print("suximage, dy_minor_divisions, missing dy_minor_divisions,\n");
    }
}

=head2 sub dz 

 subs d1 and dt and dz and dt_s

 increment in fast dimension
 usually time and equal to dt

=cut

sub dz {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $suximage->{_d1}   = $d1;
        $suximage->{_note} = $suximage->{_note} . ' d1=' . $suximage->{_d1};
        $suximage->{_Step} = $suximage->{_Step} . ' d1=' . $suximage->{_d1};

    }
    else {
        print("suximage, dz, missing dz,\n");
    }
}

=head2 sub f1 

subs f1, first_time_sample_value and first_y

 value of the first sample tihat is use

=cut

sub f1 {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $suximage->{_f1}   = $f1;
        $suximage->{_note} = $suximage->{_note} . ' f1=' . $suximage->{_f1};
        $suximage->{_Step} = $suximage->{_Step} . ' f1=' . $suximage->{_f1};

    }
    else {
        print("suximage, f1, missing f1,\n");
    }
}

=head2 sub f1num 

subs f1num first_time_tick_num

   first tick number in the
   fast dimension (e.g., time)
$f1num >=  0 && 

=cut

sub f1num {

    my ( $self, $f1num ) = @_;
    if ( $f1num ne $empty_string ) {

        $suximage->{_f1num} = $f1num;
        $suximage->{_note} =
          $suximage->{_note} . ' f1num=' . $suximage->{_f1num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' f1num=' . $suximage->{_f1num};

    }
    else {
        print("suximage, f1num, missing f1num,\n");
    }
}

=head2 sub f2 

 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)

=cut

sub f2 {

    my ( $self, $f2 ) = @_;
    if ( $f2 || $f2 == 0 || $f2 == 0.0 && $f2 ne $empty_string ) {

        $suximage->{_f2}   = $f2;
        $suximage->{_note} = $suximage->{_note} . ' f2=' . $suximage->{_f2};
        $suximage->{_Step} = $suximage->{_Step} . ' f2=' . $suximage->{_f2};

    }
    else {
        print("suximage, f2, missing f2,\n");
    }
}

=head2 sub f2num 

subs f2num first_tick_number_x

   first tick number in the
   slow dimension (e.g., distance)

=cut

sub f2num {

    my ( $self, $f2num ) = @_;
    if ( $f2num ne $empty_string ) {

        $suximage->{_f2num} = $f2num;
        $suximage->{_note} =
          $suximage->{_note} . ' f2num=' . $suximage->{_f2num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' f2num=' . $suximage->{_f2num};

    }
    else {
        print("suximage, f2num, missing f2num,\n");
    }
}

=head2 sub first_distance_sample_value  

 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)
$f2 >=0  && 

=cut

sub first_distance_sample_value {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $suximage->{_f2}   = $f2;
        $suximage->{_note} = $suximage->{_note} . ' f2=' . $suximage->{_f2};
        $suximage->{_Step} = $suximage->{_Step} . ' f2=' . $suximage->{_f2};

    }
    else {
        print(
"suximage, first_distance_sample_value , missing first_distance_sample_value ,\n"
        );
    }
}

=head2 sub first_x  

 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)
 
 $f2 >=0  && 

=cut

sub first_x {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $suximage->{_f2}   = $f2;
        $suximage->{_note} = $suximage->{_note} . ' f2=' . $suximage->{_f2};
        $suximage->{_Step} = $suximage->{_Step} . ' f2=' . $suximage->{_f2};

    }
    else {
        print("suximage, first_x , missing first_x ,\n");
    }
}

=head2 sub first_distance_tick_num

	subs f2num first_distance_tick_num

   first tick number in the
   slow dimension (distance)
   $f2num >=0  && 
   

=cut

sub first_distance_tick_num {
    my ( $variable, $f2num ) = @_;
    if ( $f2num ne $empty_string ) {
        $suximage->{_f2num} = $f2num;
        $suximage->{_Step} =
          $suximage->{_Step} . ' f2num=' . $suximage->{_f2num};
        $suximage->{_note} =
          $suximage->{_note} . ' f2num=' . $suximage->{_f2num};
    }
}

=head2 sub first_tick_number_x 

subs f2num first_tick_number_x

   first tick number in the
   slow dimension (e.g., distance)
 $f2num >=0  && 

=cut

sub first_tick_number_x {

    my ( $self, $f2num ) = @_;
    if ( $f2num ne $empty_string ) {

        $suximage->{_f2num} = $f2num;
        $suximage->{_note} =
          $suximage->{_note} . ' f2num=' . $suximage->{_f2num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' f2num=' . $suximage->{_f2num};

    }
    else {
        print("suximage, first_tick_number_x, missing first_tick_number_x,\n");
    }
}

=head2 sub first_time_sample_value 

subs f1, first_time_sample_value and first_y

 value of the first sample tihat is use
 $f1 >=0  && 

=cut

sub first_time_sample_value {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $suximage->{_f1}   = $f1;
        $suximage->{_note} = $suximage->{_note} . ' f1=' . $suximage->{_f1};
        $suximage->{_Step} = $suximage->{_Step} . ' f1=' . $suximage->{_f1};

    }
    else {
        print(
"suximage, first_time_sample_value, missing first_time_sample_value,\n"
        );
    }
}

=head2 sub first_time_tick_num 

subs f1num first_time_tick_num

   first tick number in the
   fast dimension (e.g., time)
   
 $f1num >=0  && 

=cut

sub first_time_tick_num {

    my ( $self, $f1num ) = @_;
    if ( $f1num ne $empty_string ) {

        $suximage->{_f1num} = $f1num;
        $suximage->{_note} =
          $suximage->{_note} . ' f1num=' . $suximage->{_f1num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' f1num=' . $suximage->{_f1num};

    }
    else {
        print("suximage, first_time_tick_num, missing first_time_tick_num,\n");
    }
}

=head2 sub first_y 

subs f1, first_time_sample_value and first_y

 value of the first sample that is used
 $f1 >=0  && 

=cut

sub first_y {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $suximage->{_f1}   = $f1;
        $suximage->{_note} = $suximage->{_note} . ' f1=' . $suximage->{_f1};
        $suximage->{_Step} = $suximage->{_Step} . ' f1=' . $suximage->{_f1};

    }
    else {
        print("suximage, first_y, missing first_y,\n");
    }
}

=head2 sub grid1 


=cut

sub grid1 {

    my ( $self, $grid1 ) = @_;
    if ( $grid1 ne $empty_string ) {

        $suximage->{_grid1} = $grid1;
        $suximage->{_note} =
          $suximage->{_note} . ' grid1=' . $suximage->{_grid1};
        $suximage->{_Step} =
          $suximage->{_Step} . ' grid1=' . $suximage->{_grid1};

    }
    else {
        print("suximage, grid1, missing grid1,\n");
    }
}

=head2 sub grid2 


=cut

sub grid2 {

    my ( $self, $grid2 ) = @_;
    if ( $grid2 ne $empty_string ) {

        $suximage->{_grid2} = $grid2;
        $suximage->{_note} =
          $suximage->{_note} . ' grid2=' . $suximage->{_grid2};
        $suximage->{_Step} =
          $suximage->{_Step} . ' grid2=' . $suximage->{_grid2};

    }
    else {
        print("suximage, grid2, missing grid2,\n");
    }
}

=head2 sub gridcolor 


=cut

sub gridcolor {

    my ( $self, $gridcolor ) = @_;
    if ( $gridcolor ne $empty_string ) {

        $suximage->{_gridcolor} = $gridcolor;
        $suximage->{_note} =
          $suximage->{_note} . ' gridcolor=' . $suximage->{_gridcolor};
        $suximage->{_Step} =
          $suximage->{_Step} . ' gridcolor=' . $suximage->{_gridcolor};

    }
    else {
        print("suximage, gridcolor, missing gridcolor,\n");
    }
}

=head2 sub hbox 


=cut

sub hbox {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $suximage->{_hbox} = $hbox;
        $suximage->{_note} =
          $suximage->{_note} . ' hbox=' . $suximage->{_hbox};
        $suximage->{_Step} =
          $suximage->{_Step} . ' hbox=' . $suximage->{_hbox};

    }
    else {
        print("suximage, hbox, missing hbox,\n");
    }
}

=head2 sub hiclip

 subs hiclip or wclip

=cut

sub hiclip {

    my ( $self, $wclip ) = @_;

    # print("1. suximage, hiclip,$wclip,\n");
    if ( $wclip ne $empty_string ) {

        # print("2. suximage, loclip,$wclip,\n");
        $suximage->{_wclip} = $wclip;
        $suximage->{_note} =
          $suximage->{_note} . ' wclip=' . $suximage->{_wclip};
        $suximage->{_Step} =
          $suximage->{_Step} . ' wclip=' . $suximage->{_wclip};

    }
    else {
        print("suximage, hiclip, missing hiclip,\n");
    }
}

=head2 sub label1 

subs xlabel or label2  ylabel or labe1

=cut

sub label1 {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $suximage->{_label1} = $label1;
        $suximage->{_note} =
          $suximage->{_note} . ' label1=' . $suximage->{_label1};
        $suximage->{_Step} =
          $suximage->{_Step} . ' label1=' . $suximage->{_label1};

    }
    else {
        print("suximage, label1, missing label1,\n");
    }
}

=head2 sub label2 

subs xlabel or label2  ylabel or labe1

=cut

sub label2 {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $suximage->{_label2} = $label2;
        $suximage->{_note} =
          $suximage->{_note} . ' label2=' . $suximage->{_label2};
        $suximage->{_Step} =
          $suximage->{_Step} . ' label2=' . $suximage->{_label2};

    }
    else {
        print("suximage, label2, missing label2,\n");
    }
}

=head2 sub labelcolor 


=cut

sub labelcolor {

    my ( $self, $labelcolor ) = @_;
    if ( $labelcolor ne $empty_string ) {

        $suximage->{_labelcolor} = $labelcolor;
        $suximage->{_note} =
          $suximage->{_note} . ' labelcolor=' . $suximage->{_labelcolor};
        $suximage->{_Step} =
          $suximage->{_Step} . ' labelcolor=' . $suximage->{_labelcolor};

    }
    else {
        print("suximage, labelcolor, missing labelcolor,\n");
    }
}

=head2 sub labelfont 


=cut

sub labelfont {

    my ( $self, $labelfont ) = @_;
    if ( $labelfont ne $empty_string ) {

        $suximage->{_labelfont} = $labelfont;
        $suximage->{_note} =
          $suximage->{_note} . ' labelfont=' . $suximage->{_labelfont};
        $suximage->{_Step} =
          $suximage->{_Step} . ' labelfont=' . $suximage->{_labelfont};

    }
    else {
        print("suximage, labelfont, missing labelfont,\n");
    }
}

=head2 sub legend 


=cut

sub legend {

    my ( $self, $legend ) = @_;
    if ( $legend ne $empty_string ) {

        $suximage->{_legend} = $legend;
        $suximage->{_note} =
          $suximage->{_note} . ' legend=' . $suximage->{_legend};
        $suximage->{_Step} =
          $suximage->{_Step} . ' legend=' . $suximage->{_legend};

    }
    else {
        print("suximage, legend, missing legend,\n");
    }
}

=head2 sub legendfont 


=cut

sub legendfont {

    my ( $self, $legendfont ) = @_;
    if ( $legendfont ne $empty_string ) {

        $suximage->{_legendfont} = $legendfont;
        $suximage->{_note} =
          $suximage->{_note} . ' legendfont=' . $suximage->{_legendfont};
        $suximage->{_Step} =
          $suximage->{_Step} . ' legendfont=' . $suximage->{_legendfont};

    }
    else {
        print("suximage, legendfont, missing legendfont,\n");
    }
}

=head2 sub lheight 


=cut

sub lheight {

    my ( $self, $lheight ) = @_;
    if ( $lheight ne $empty_string ) {

        $suximage->{_lheight} = $lheight;
        $suximage->{_note} =
          $suximage->{_note} . ' lheight=' . $suximage->{_lheight};
        $suximage->{_Step} =
          $suximage->{_Step} . ' lheight=' . $suximage->{_lheight};

    }
    else {
        print("suximage, lheight, missing lheight,\n");
    }
}

=head2 sub loclip 

	subs loclip bclip

=cut

sub loclip {

    my ( $self, $bclip ) = @_;

    # print("suximage, loclip, $bclip,\n");

    # $wclip >= 0  &&
    if ( $bclip ne $empty_string ) {

        $suximage->{_bclip} = $bclip;
        $suximage->{_note} =
          $suximage->{_note} . ' bclip=' . $suximage->{_bclip};
        $suximage->{_Step} =
          $suximage->{_Step} . ' bclip=' . $suximage->{_bclip};
    }
    else {
        print("suximage, loclip, missing loclip,\n");
    }
}

=head2 sub lwidth 


=cut

sub lwidth {

    my ( $self, $lwidth ) = @_;
    if ( $lwidth ne $empty_string ) {

        $suximage->{_lwidth} = $lwidth;
        $suximage->{_note} =
          $suximage->{_note} . ' lwidth=' . $suximage->{_lwidth};
        $suximage->{_Step} =
          $suximage->{_Step} . ' lwidth=' . $suximage->{_lwidth};

    }
    else {
        print("suximage, lwidth, missing lwidth,\n");
    }
}

=head2 sub lx 


=cut

sub lx {

    my ( $self, $lx ) = @_;
    if ( $lx ne $empty_string ) {

        $suximage->{_lx}   = $lx;
        $suximage->{_note} = $suximage->{_note} . ' lx=' . $suximage->{_lx};
        $suximage->{_Step} = $suximage->{_Step} . ' lx=' . $suximage->{_lx};

    }
    else {
        print("suximage, lx, missing lx,\n");
    }
}

=head2 sub ly 


=cut

sub ly {

    my ( $self, $ly ) = @_;
    if ( $ly ne $empty_string ) {

        $suximage->{_ly}   = $ly;
        $suximage->{_note} = $suximage->{_note} . ' ly=' . $suximage->{_ly};
        $suximage->{_Step} = $suximage->{_Step} . ' ly=' . $suximage->{_ly};

    }
    else {
        print("suximage, ly, missing ly,\n");
    }
}

=head2 sub mpicks 

 sub mpicks picks
    automatically generates a pick file

=cut

sub mpicks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        $suximage->{_mpicks} = $mpicks;
        $suximage->{_note} =
          $suximage->{_note} . ' mpicks=' . $suximage->{_mpicks};
        $suximage->{_Step} =
          $suximage->{_Step} . ' mpicks=' . $suximage->{_mpicks};

    }
    else {
        print("suximage, mpicks, missing mpicks,\n");
    }
}

=head2 sub n1 

n1			 number of samples in 1st (fast) dimension	


=cut

sub n1 {

    my ( $self, $n1 ) = @_;
    if ( $n1 ne $empty_string ) {

        $suximage->{_n1}   = $n1;
        $suximage->{_note} = $suximage->{_note} . ' n1=' . $suximage->{_n1};
        $suximage->{_Step} = $suximage->{_Step} . ' n1=' . $suximage->{_n1};

    }
    else {
        print("suximage, n1, missing n1,\n");
    }
}

=head2 sub n1tic 

 subs dy_minor_divisions n1tic and num_minor_ticks_betw_time_ticks 

 n1tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)	


=cut

sub n1tic {

    my ( $self, $n1tic ) = @_;
    if ( $n1tic ne $empty_string ) {

        $suximage->{_n1tic} = $n1tic;
        $suximage->{_note} =
          $suximage->{_note} . ' n1tic=' . $suximage->{_n1tic};
        $suximage->{_Step} =
          $suximage->{_Step} . ' n1tic=' . $suximage->{_n1tic};

    }
    else {
        print("suximage, n1tic, missing n1tic,\n");
    }
}

=head2 sub n2 


=cut

sub n2 {

    my ( $self, $n2 ) = @_;
    if ( $n2 ne $empty_string ) {

        $suximage->{_n2}   = $n2;
        $suximage->{_note} = $suximage->{_note} . ' n2=' . $suximage->{_n2};
        $suximage->{_Step} = $suximage->{_Step} . ' n2=' . $suximage->{_n2};

    }
    else {
        print("suximage, n2, missing n2,\n");
    }
}

=head2 sub n2tic 

subs n2tic and num_minor_ticks_betw_distance_ticks

 n2tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)	


=cut

sub n2tic {

    my ( $self, $n2tic ) = @_;
    if ( $n2tic ne $empty_string ) {

        $suximage->{_n2tic} = $n2tic;
        $suximage->{_note} =
          $suximage->{_note} . ' n2tic=' . $suximage->{_n2tic};
        $suximage->{_Step} =
          $suximage->{_Step} . ' n2tic=' . $suximage->{_n2tic};

    }
    else {
        print("suximage, n2tic, missing n2tic,\n");
    }
}

=head2 sub npair 

 number of T-Vel pairs

=cut

sub npair {

    my ( $self, $npair ) = @_;
    if ( $npair ne $empty_string ) {

        $suximage->{_npair} = $npair;
        $suximage->{_note} =
          $suximage->{_note} . ' npair=' . $suximage->{_npair};
        $suximage->{_Step} =
          $suximage->{_Step} . ' npair=' . $suximage->{_npair};

    }
    else {
        print("suximage, npair, missing npair,\n");
    }
}

=head2 sub num_minor_ticks_betw_distance_ticks 

subs n2tic and num_minor_ticks_betw_distance_ticks

 n2tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)	


=cut

sub num_minor_ticks_betw_distance_ticks {

    my ( $self, $n2tic ) = @_;
    if ( $n2tic ne $empty_string ) {

        $suximage->{_n2tic} = $n2tic;
        $suximage->{_note} =
          $suximage->{_note} . ' n2tic=' . $suximage->{_n2tic};
        $suximage->{_Step} =
          $suximage->{_Step} . ' n2tic=' . $suximage->{_n2tic};

    }
    else {
        print(
"suximage, num_minor_ticks_betw_distance_ticks, missing num_minor_ticks_betw_distance_ticks,\n"
        );
    }
}

=head2 sub num_minor_ticks_betw_time_ticks 

 subs dy_minor_divisions n1tic and num_minor_ticks_betw_time_ticks

 n1tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)	


=cut

sub num_minor_ticks_betw_time_ticks {

    my ( $self, $n1tic ) = @_;
    if ( $n1tic ne $empty_string ) {

        $suximage->{_n1tic} = $n1tic;
        $suximage->{_note} =
          $suximage->{_note} . ' n1tic=' . $suximage->{_n1tic};
        $suximage->{_Step} =
          $suximage->{_Step} . ' n1tic=' . $suximage->{_n1tic};

    }
    else {
        print(
"suximage, num_minor_ticks_betw_time_ticks, missing num_minor_ticks_betw_time_ticks,\n"
        );
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

        $suximage->{_style} = $style;
        $suximage->{_note} =
          $suximage->{_note} . ' style=' . $suximage->{_style};
        $suximage->{_Step} =
          $suximage->{_Step} . ' style=' . $suximage->{_style};

    }
    else {
        print("suximage, orientation, missing orientation,\n");
    }
}

=head2 sub perc 

 subs perc percent4clip percentile used to determine clip

=cut

sub perc {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $suximage->{_perc} = $perc;
        $suximage->{_note} =
          $suximage->{_note} . ' perc=' . $suximage->{_perc};
        $suximage->{_Step} =
          $suximage->{_Step} . ' perc=' . $suximage->{_perc};

    }
    else {
        print("suximage, perc, missing perc,\n");
    }
}

=head2 sub percent4clip

 subs perc percent4clip percentile used to determine clip

=cut

sub percent4clip {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $suximage->{_perc} = $perc;
        $suximage->{_note} =
          $suximage->{_note} . ' perc=' . $suximage->{_perc};
        $suximage->{_Step} =
          $suximage->{_Step} . ' perc=' . $suximage->{_perc};

    }
    else {
        print("suximage, percent4clip, missing percent4clip,\n");
    }
}

=head2 sub picks 

 sub mpicks picks
    automatically generates a pick file

=cut

sub picks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        $suximage->{_mpicks} = $mpicks;
        $suximage->{_note} =
          $suximage->{_note} . ' mpicks=' . $suximage->{_mpicks};
        $suximage->{_Step} =
          $suximage->{_Step} . ' mpicks=' . $suximage->{_mpicks};

    }
    else {
        print("suximage, picks, missing picks,\n");
    }
}

=head2 sub plotfile 


=cut

sub plotfile {

    my ( $self, $plotfile ) = @_;
    if ( $plotfile ne $empty_string ) {

        $suximage->{_plotfile} = $plotfile;
        $suximage->{_note} =
          $suximage->{_note} . ' plotfile=' . $suximage->{_plotfile};
        $suximage->{_Step} =
          $suximage->{_Step} . ' plotfile=' . $suximage->{_plotfile};

    }
    else {
        print("suximage, plotfile, missing plotfile,\n");
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

        $suximage->{_style} = $style;
        $suximage->{_note} =
          $suximage->{_note} . ' style=' . $suximage->{_style};
        $suximage->{_Step} =
          $suximage->{_Step} . ' style=' . $suximage->{_style};

    }
    else {
        print("suximage, style, missing style,\n");
    }
}

=head2 sub tend_s 

subs x1end and tend_s

  minimum value of yaxis (time usually) in seconds

=cut

sub tend_s {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $suximage->{_x1end} = $x1end;
        $suximage->{_note} =
          $suximage->{_note} . ' x1end=' . $suximage->{_x1end};
        $suximage->{_Step} =
          $suximage->{_Step} . ' x1end=' . $suximage->{_x1end};

    }
    else {
        print("suximage, tend_s, missing tend_s,\n");
    }
}

=head2 sub title 

 sub title allows for a  graph title  at the top of the 
 window 

=cut

sub title {

    my ( $self, $title ) = @_;
    if ( $title ne $empty_string ) {

        $suximage->{_title} = $title;
        $suximage->{_note} =
          $suximage->{_note} . ' title=' . $suximage->{_title};
        $suximage->{_Step} =
          $suximage->{_Step} . ' title=' . $suximage->{_title};

    }
    else {
        print("suximage, title, missing title,\n");
    }
}

=head2 sub titlecolor 


=cut

sub titlecolor {

    my ( $self, $titlecolor ) = @_;
    if ( $titlecolor ne $empty_string ) {

        $suximage->{_titlecolor} = $titlecolor;
        $suximage->{_note} =
          $suximage->{_note} . ' titlecolor=' . $suximage->{_titlecolor};
        $suximage->{_Step} =
          $suximage->{_Step} . ' titlecolor=' . $suximage->{_titlecolor};

    }
    else {
        print("suximage, titlecolor, missing titlecolor,\n");
    }
}

=head2 sub titlefont 


=cut

sub titlefont {

    my ( $self, $titlefont ) = @_;
    if ( $titlefont ne $empty_string ) {

        $suximage->{_titlefont} = $titlefont;
        $suximage->{_note} =
          $suximage->{_note} . ' titlefont=' . $suximage->{_titlefont};
        $suximage->{_Step} =
          $suximage->{_Step} . ' titlefont=' . $suximage->{_titlefont};

    }
    else {
        print("suximage, titlefont, missing titlefont,\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ( $tmpdir ne $empty_string ) {

        $suximage->{_tmpdir} = $tmpdir;
        $suximage->{_note} =
          $suximage->{_note} . ' tmpdir=' . $suximage->{_tmpdir};
        $suximage->{_Step} =
          $suximage->{_Step} . ' tmpdir=' . $suximage->{_tmpdir};

    }
    else {
        print("suximage, tmpdir, missing tmpdir,\n");
    }
}

=head2 sub trace_inc 

	subs d2 and trace_inc
	
     only the first trace is read in
     if an increment is not 1 between traces
     you should indicate here

=cut

sub trace_inc {

    my ( $self, $d2 ) = @_;
    if ( $d2 ne $empty_string ) {

        $suximage->{_d2}   = $d2;
        $suximage->{_note} = $suximage->{_note} . ' d2=' . $suximage->{_d2};
        $suximage->{_Step} = $suximage->{_Step} . ' d2=' . $suximage->{_d2};

    }
    else {
        print("suximage, trace_inc, missing trace_inc,\n");
    }
}

=head2 sub tstart_s 

subs x1beg and tstart_s

  minimum value of yaxis (time usually) in seconds
  
 $x1beg >=0 && 

=cut

sub tstart_s {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $suximage->{_x1beg} = $x1beg;
        $suximage->{_note} =
          $suximage->{_note} . ' x1beg=' . $suximage->{_x1beg};
        $suximage->{_Step} =
          $suximage->{_Step} . ' x1beg=' . $suximage->{_x1beg};

    }
    else {
        print("suximage, tstart_s, missing tstart_s,\n");
    }
}

=head2 sub units 


=cut

sub units {

    my ( $self, $units ) = @_;
    if ( $units ne $empty_string ) {

        $suximage->{_units} = $units;
        $suximage->{_note} =
          $suximage->{_note} . ' units=' . $suximage->{_units};
        $suximage->{_Step} =
          $suximage->{_Step} . ' units=' . $suximage->{_units};

    }
    else {
        print("suximage, units, missing units,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $suximage->{_verbose} = $verbose;
        $suximage->{_note} =
          $suximage->{_note} . ' verbose=' . $suximage->{_verbose};
        $suximage->{_Step} =
          $suximage->{_Step} . ' verbose=' . $suximage->{_verbose};

    }
    else {
        print("suximage, verbose, missing verbose,\n");
    }
}

=head2 sub wbox 


=cut

sub wbox {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $suximage->{_wbox} = $wbox;
        $suximage->{_note} =
          $suximage->{_note} . ' wbox=' . $suximage->{_wbox};
        $suximage->{_Step} =
          $suximage->{_Step} . ' wbox=' . $suximage->{_wbox};

    }
    else {
        print("suximage, wbox, missing wbox,\n");
    }
}

=head2 sub wclip 

	subs hiclip wclip

=cut

sub wclip {

    my ( $self, $wclip ) = @_;

    # print("1. suximage, wclip,$wclip,\n");
    if ( $wclip ne $empty_string ) {
        print("2. suximage, wclip,$wclip,\n");
        $suximage->{_wclip} = $wclip;
        $suximage->{_note} =
          $suximage->{_note} . ' wclip=' . $suximage->{_wclip};
        $suximage->{_Step} =
          $suximage->{_Step} . ' wclip=' . $suximage->{_wclip};

    }
    else {
        print("suximage, wclip, missing wclip,\n");
    }
}

=head2 sub windowtitle 


=cut

sub windowtitle {

    my ( $self, $windowtitle ) = @_;
    if ( $windowtitle ne $empty_string ) {

        $suximage->{_windowtitle} = $windowtitle;
        $suximage->{_note} =
          $suximage->{_note} . ' windowtitle=' . $suximage->{_windowtitle};
        $suximage->{_Step} =
          $suximage->{_Step} . ' windowtitle=' . $suximage->{_windowtitle};

    }
    else {
        print("suximage, windowtitle, missing windowtitle,\n");
    }
}

=head2 sub wperc 


=cut

sub wperc {

    my ( $self, $wperc ) = @_;
    if ( $wperc ne $empty_string ) {

        $suximage->{_wperc} = $wperc;
        $suximage->{_note} =
          $suximage->{_note} . ' wperc=' . $suximage->{_wperc};
        $suximage->{_Step} =
          $suximage->{_Step} . ' wperc=' . $suximage->{_wperc};

    }
    else {
        print("suximage, wperc, missing wperc,\n");
    }
}

=head2 sub x1beg 

subs x1beg and tstart_s

  minimum value of yaxis (time usually) in seconds
  
 $x1beg >=0 && 

=cut

sub x1beg {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $suximage->{_x1beg} = $x1beg;
        $suximage->{_note} =
          $suximage->{_note} . ' x1beg=' . $suximage->{_x1beg};
        $suximage->{_Step} =
          $suximage->{_Step} . ' x1beg=' . $suximage->{_x1beg};

    }
    else {
        print("suximage, x1beg, missing x1beg,\n");
    }
}

=head2 sub x1end 

subs x1end and tend_s

  minimum value of yaxis (time usually) in seconds

=cut

sub x1end {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $suximage->{_x1end} = $x1end;
        $suximage->{_note} =
          $suximage->{_note} . ' x1end=' . $suximage->{_x1end};
        $suximage->{_Step} =
          $suximage->{_Step} . ' x1end=' . $suximage->{_x1end};

    }
    else {
        print("suximage, x1end, missing x1end,\n");
    }
}

=head2 sub x2end 

 subs x2end and xend_m

  minimum value of yaxis (time usually) in seconds

=cut

sub x2end {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $suximage->{_x2end} = $x2end;
        $suximage->{_note} =
          $suximage->{_note} . ' x2end=' . $suximage->{_x2end};
        $suximage->{_Step} =
          $suximage->{_Step} . ' x2end=' . $suximage->{_x2end};

    }
    else {
        print("suximage, x2end, missing x2end,\n");
    }
}

=head2 sub xbox 


=cut

sub xbox {

    my ( $self, $xbox ) = @_;
    if ( $xbox ne $empty_string ) {

        $suximage->{_xbox} = $xbox;
        $suximage->{_note} =
          $suximage->{_note} . ' xbox=' . $suximage->{_xbox};
        $suximage->{_Step} =
          $suximage->{_Step} . ' xbox=' . $suximage->{_xbox};

    }
    else {
        print("suximage, xbox, missing xbox,\n");
    }
}

=head2 sub x2beg 

  subs x2beg and 

  minimum value of yaxis (time usually) in seconds
  
 $x2beg >=0 && 

=cut

sub x2beg {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $suximage->{_x2beg} = $x2beg;
        $suximage->{_note} =
          $suximage->{_note} . ' x2beg=' . $suximage->{_x2beg};
        $suximage->{_Step} =
          $suximage->{_Step} . ' x2beg=' . $suximage->{_x2beg};

    }
    else {
        print("suximage, x2beg, missing x2beg,\n");
    }
}

=head2 sub xend_m 

 subs x2end and xend_m

  minimum value of yaxis (time usually) in seconds

=cut

sub xend_m {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $suximage->{_x2end} = $x2end;
        $suximage->{_note} =
          $suximage->{_note} . ' x2end=' . $suximage->{_x2end};
        $suximage->{_Step} =
          $suximage->{_Step} . ' x2end=' . $suximage->{_x2end};

    }
    else {
        print("suximage, xend_m, missing xend_m,\n");
    }
}

=head2 sub xlabel 

subs xlabel or label2  ylabel or labe1

=cut

sub xlabel {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $suximage->{_label2} = $label2;
        $suximage->{_note} =
          $suximage->{_note} . ' label2=' . $suximage->{_label2};
        $suximage->{_Step} =
          $suximage->{_Step} . ' label2=' . $suximage->{_label2};

    }
    else {
        print("suximage, xlabel, missing xlabel,\n");
    }
}

=head2 sub xstart_m 

  subs x2beg and xstart_m

  minimum value of yaxis (time usually) in seconds
  
 $x2beg >=0 && 

=cut

sub xstart_m {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $suximage->{_x2beg} = $x2beg;
        $suximage->{_note} =
          $suximage->{_note} . ' x2beg=' . $suximage->{_x2beg};
        $suximage->{_Step} =
          $suximage->{_Step} . ' x2beg=' . $suximage->{_x2beg};

    }
    else {
        print("suximage, xstart_m, missing xstart_m,\n");
    }
}

=head2 sub x_tick_increment

 	subs d2num  dx_major_divisions and x_tick_increment
	numbered tick interval

=cut

sub x_tick_increment {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $suximage->{_d2num} = $d2num;
        $suximage->{_note} =
          $suximage->{_note} . ' d2num=' . $suximage->{_d2num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' d2num=' . $suximage->{_d2num};

    }
    else {
        print("suximage, x_tick_increment, missing x_tick_increment\n");
    }
}

=head2 sub ybox 


=cut

sub ybox {

    my ( $self, $ybox ) = @_;
    if ( $ybox ne $empty_string ) {

        $suximage->{_ybox} = $ybox;
        $suximage->{_note} =
          $suximage->{_note} . ' ybox=' . $suximage->{_ybox};
        $suximage->{_Step} =
          $suximage->{_Step} . ' ybox=' . $suximage->{_ybox};

    }
    else {
        print("suximage, ybox, missing ybox,\n");
    }
}

=head2 sub ylabel 

subs xlabel or label2  ylabel or labe1

=cut

sub ylabel {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $suximage->{_label1} = $label1;
        $suximage->{_note} =
          $suximage->{_note} . ' label1=' . $suximage->{_label1};
        $suximage->{_Step} =
          $suximage->{_Step} . ' label1=' . $suximage->{_label1};

    }
    else {
        print("suximage, ylabel, missing ylabel,\n");
    }
}

=head2 sub y_tick_increment 

  subs d1num , y_tick_increment dy_major_divisions dt_major_divisions

  numbered tick interval in fast dimension(t)

=cut

sub y_tick_increment {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $suximage->{_d1num} = $d1num;
        $suximage->{_note} =
          $suximage->{_note} . ' d1num=' . $suximage->{_d1num};
        $suximage->{_Step} =
          $suximage->{_Step} . ' d1num=' . $suximage->{_d1num};

    }
    else {
        print("suximage, y_tick_increment, missing y_tick_increment,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;

    # index=60
    my $max_index = 58;

    return ($max_index);
}

1;
