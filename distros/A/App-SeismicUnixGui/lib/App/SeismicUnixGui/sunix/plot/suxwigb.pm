package App::SeismicUnixGui::sunix::plot::suxwigb;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  SUXWIGB - X-windows Bit-mapped WIGgle plot of a segy data set		
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 This program also can use XWIGB parameters (see below)

 SUXWIGB - X-windows Bit-mapped WIGgle plot of a segy data set		
 This is a modified suxwigb that uses the depth or coordinate scaling	
 when such values are used as keys.					

 suxwigb <stdin [optional parameters] | ...				

 Optional parameters:							
 key=(keyword)		if set, the values of x2 are set from header field
			specified by keyword				
 n2=tr.ntr or number of traces in the data set (ntr is an alias for n2)
 d1=tr.d1 or tr.dt/10^6	sampling interval in the fast dimension 
   =.004 for seismic		(if not set)				
   =1.0 for nonseismic		(if not set)				
 d2=tr.d2			sampling interval in the slow dimension 
   =1.0			(if not set)				
 f1=tr.f1 or tr.delrt/10^3 or 0.0  first sample in the fast dimension	
 f2=tr.f2 or tr.tracr or tr.tracl  first sample in the slow dimension	
   =1.0 for seismic		    (if not set)			
   =d2 for nonseismic		    (if not set)			

 style=seismic		 normal (axis 1 horizontal, axis 2 vertical) or 
			 vsp (same as normal with axis 2 reversed)	
			 Note: vsp requires use of a keyword		
 verbose=0              =1 to print some useful information		


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

 If key=keyword is set, then the values of x2 are taken from the header
 field represented by the keyword (for example key=offset, will show	
 traces in true offset). This permit unequally spaced traces to be plotted.
 Type	 sukeyword -o	to see the complete list of SU keywords.	

 This program is really just a wrapper for the plotting program: xwigb	
 See the xwigb selfdoc for the remaining parameters.			


 Credits:

	CWP: Dave Hale and Zhiming Li (xwigb, etc.)
	   Jack Cohen and John Stockwell (suxwigb, etc.)
	Delphi: Alexander Koek, added support for irregularly spaced traces

	Modified by Brian Zook, Southwest Research Institute, to honor
	 scale factors, added vsp style

 Notes:
	When the number of traces isn't known, we need to count
	the traces for xwigb.  You can make this value "known"
	either by getparring n2 or by having the ntr field set
	in the trace header.  A getparred value takes precedence
	over the value in the trace header.

	When we must compute ntr, we don't allocate a 2-d array,
	but just content ourselves with copying trace by trace from
	the data "file" to the pipe into the plotting program.
	Although we could use tr.data, we allocate a trace buffer
	for code clarity.
	
This program also can use XWIGB parameters	
XWIGB - X WIGgle-trace plot of f(x1,x2) via Bitmap			

 xwigb n1= [optional parameters] <binaryfile   	   

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
    l 				lock the zoom while moving the coursor	
    u 				unlock the zoom 			
 1,2,...,9	Zoom/Move factor of the window size			

 Notes:								
	Reaching the window limits while moving within changes the zoom	
	factor in this direction. The use of zoom locking(l) disables it

 Required Parameters:							
 n1			 number of samples in 1st (fast) dimension	

 Optional Parameters:							
 d1=1.0		 sampling interval in 1st dimension		
 f1=0.0		 first sample in 1st dimension			
 n2=all		 number of samples in 2nd (slow) dimension	
 d2=1.0		 sampling interval in 2nd dimension		
 f2=0.0		 first sample in 2nd dimension			
 x2=f2,f2+d2,...	 array of sampled values in 2nd dimension	
 mpicks=/dev/tty	 file to save mouse picks in			
 bias=0.0		 data value corresponding to location along axis 2
 perc=100.0		 percentile for determining clip		
 clip=(perc percentile) data values < bias+clip and > bias-clip are clipped
 xcur=1.0		 wiggle excursion in traces corresponding to clip
 wt=1			 =0 for no wiggle-trace; =1 for wiggle-trace	
 va=1			 =0 for no variable-area; =1 for variable-area fill
                        =2 for variable area, solid/grey fill          
                        SHADING: 2<=va<=5  va=2 light grey, va=5 black 
 verbose=0		 =1 for info printed on stderr (0 for no info)	
 xbox=50		 x in pixels of upper left corner of window	
 ybox=50		 y in pixels of upper left corner of window	
 wbox=550		 width in pixels of window			
 hbox=700		 height in pixels of window			
 x1beg=x1min		 value at which axis 1 begins			
 x1end=x1max		 value at which axis 1 ends			
 d1num=0.0		 numbered tic interval on axis 1 (0.0 for automatic)
 f1num=x1min		 first numbered tic on axis 1 (used if d1num not 0.0)
 n1tic=1		 number of tics per numbered tic on axis 1	
 grid1=none		 grid lines on axis 1 - none, dot, dash, or solid
 x2beg=x2min		 value at which axis 2 begins			
 x2end=x2max		 value at which axis 2 ends			
 d2num=0.0		 numbered tic interval on axis 2 (0.0 for automatic)
 f2num=x2min		 first numbered tic on axis 2 (used if d2num not 0.0)
 n2tic=1		 number of tics per numbered tic on axis 2	
 grid2=none		 grid lines on axis 2 - none, dot, dash, or solid
 label2=		 label on axis 2				
 labelfont=Erg14	 font name for axes labels			
 title=		 title of plot					
 titlefont=Rom22	 font name for title				
 windowtitle=xwigb	 title on window				
 labelcolor=blue	 color for axes labels				
 titlecolor=red	 color for title				
 gridcolor=blue	 color for grid lines				
 style=seismic		 normal (axis 1 horizontal, axis 2 vertical) or 
			 seismic (axis 1 vertical, axis 2 horizontal)	
 endian=		 =0 little endian =1 big endian			
 interp=0		 no interpolation in display			
			 =1 use 8 point sinc interpolation		
 wigclip=0		 If 0, the plot box is expanded to accommodate	
			 the larger wiggles created by xcur>1.	If this 
			 flag is non-zero, the extra-large wiggles are	
			 are clipped at the boundary of the plot box.	
 plotfile=plotfile.ps   filename for interactive ploting (P)  		
 curve=curve1,curve2,...  file(s) containing points to draw curve(s)   
 npair=n1,n2,n2,...            number(s) of pairs in each file         
 curvecolor=color1,color2,...  color(s) for curve(s)                   

 Notes:								
 Xwigb will try to detect the endian value of the X-display and will	
 set it to the right value. If it gets obviously wrong information the 
 endian value will be set to the endian value of the machine that is	
 given at compile time as the value of CWPENDIAN defined in cwp.h	
 and set via the compile time flag ENDIANFLAG in Makefile.config.	

 The only time that you might want to change the value of the endian	
 variable is if you are viewing traces on a machine with a different	
 byte order than the machine you are creating the traces on AND if for 
 some reason the automaic detection of the display byte order fails.	
 Set endian to that of the machine you are viewing the traces on.	

 The interp flag is useful for making better quality wiggle trace for	
 making plots from screen dumps. However, this flag assumes that the	
 data are purely oscillatory. This option may not be appropriate for all
 data sets.								

 The curve file is an ascii file with the points specified as x1 x2    
 pairs, separated by a space, one pair to a line.  A "vector" of curve
 files and curve colors may be specified as curvefile=file1,file2,etc. 
 and curvecolor=color1,color2,etc, and the number of pairs of values   
 in each file as npair=npair1,npair2,... .                             


 AUTHOR:  Dave Hale, Colorado School of Mines, 08/09/90

 Endian stuff by: 
    Morten Wendell Pedersen, Aarhus University (visiting CSM, June 1995)
  & John Stockwell, Colorado School of Mines, 5 June 1995

 Stewart A. Levin, Mobil - Added ps print option
 John Stockwell - Added optional sinc interpolation
 Stewart A. Levin, Mobil - protect title, labels in pswigb call

 Brian J. Zook, SwRI - Added style=normal and wigclip flag

 Brian K. Macy, Phillips Petroleum, 11/27/98, added curve plotting option
 Curve plotting notes:
 MODIFIED:  P. Michaels, Boise State Univeristy  29 December 2000
            Added solid/grey color scheme for peaks/troughs
 
 G.Klein, IFG Kiel University, 2002-09-29, added cursor scrolling and
            interactive change of zoom and clipping.
          IFM-GEOMAR Kiel, 2004-03-12, added zoom locking 
          IFM-GEOMAR Kiel, 2004-03-25, interactive plotting fixed 	

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.2';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suxwigb = {
    _absclip                                   => '',
    _bias                                      => '',
    _box_width                                 => '',
    _box_height                                => '',
    _box_X0                                    => '',
    _box_Y0                                    => '',
    _clip                                      => '',
    _cmap                                      => '',
    _curve                                     => '',
    _curvecolor                                => '',
    _curvefile                                 => '',
    _ftr                                       => '',
    _d1                                        => '',
    _d1num                                     => '',
    _dt                                        => '',
    _d2                                        => '',
    _dx                                        => '',
    _dx_major_divisions                        => '',
    _dy_major_divisions                        => '',
    _dt_major_divisions                        => '',
    _d2num                                     => '',
    _dtr                                       => '',
    _endian                                    => '',
    _f1num                                     => '',
    _f1                                        => '',
    _first_y                                   => '',
    _first_time_sample_value                   => '',
    _f2                                        => '',
    _first_x                                   => '',
    _first_distance_sample_value               => '',
    _first_distance_tick_num                   => '',
    _f1num                                     => '',
    _first_time_tick_num                       => '',
    _f2num                                     => '',
    _grid1                                     => '',
    _grid2                                     => '',
    _gridcolor                                 => '',
    _hbox                                      => '',
    _headerword                                => '',
    _hiclip                                    => '',
    _interp                                    => '',
    _key                                       => '',
    _label2                                    => '',
    _labelfont                                 => '',
    _labelcolor                                => '',
    _label1                                    => '',
    _label2                                    => '',
    _loclip                                    => '',
    _mpicks                                    => '',
    _n1                                        => '',
    _n1tic                                     => '',
    _num_minor_ticks_betw_major_time_ticks     => '',
    _n2                                        => '',
    _n2tic                                     => '',
    _npair                                     => '',
    _num_minor_ticks_betw_major_distance_ticks => '',
    _percent                                   => '',
    _plotfile                                  => '',
    _orientation                               => '',
    _perc                                      => '',
    _picks                                     => '',
    _shading                                   => '',
    _style                                     => '',
    _tend_s                                    => '',
    _tstart_s                                  => '',
    _tmpdir                                    => '',
    _trace_inc                                 => '',
    _trace_inc_m                               => '',
    _title                                     => '',
    _titlefont                                 => '',
    _titlecolor                                => '',
    _va                                        => '',
    _verbose                                   => '',
    _wbox                                      => '',
    _wigclip                                   => '',
    _wt                                        => '',
    _windowtitle                               => '',
    _x2beg                                     => '',
    _xstart_m                                  => '',
    _x2end                                     => '',
    _xend_m                                    => '',
    _xcur                                      => '',
    _x2                                        => '',
    _x1beg                                     => '',
    _xbox                                      => '',
    _x1end                                     => '',
    _xlabel                                    => '',
    _x_tick_increment                          => '',
    _xcur                                      => '',
    _ylabel                                    => '',
    _y_tick_increment                          => '',
    _ybox                                      => '',
    _Step                                      => '',
    _note                                      => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $suxwigb->{_Step} = 'suxwigb' . $suxwigb->{_Step};
    return ( $suxwigb->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suxwigb->{_note} = 'suxwigb' . $suxwigb->{_note};
    return ( $suxwigb->{_note} );

}

=head2 sub clear

 50 + 43 personalized  params
clear global variables from the memory

=cut

sub clear {

    $suxwigb->{_d1}                                        = '';
    $suxwigb->{_d2}                                        = '';
    $suxwigb->{_f1}                                        = '';
    $suxwigb->{_f2}                                        = '';
    $suxwigb->{_key}                                       = '';
    $suxwigb->{_n2}                                        = '';
    $suxwigb->{_style}                                     = '';
    $suxwigb->{_tmpdir}                                    = '';
    $suxwigb->{_absclip}                                   = '';
    $suxwigb->{_bias}                                      = '';
    $suxwigb->{_box_width}                                 = '';
    $suxwigb->{_box_height}                                = '';
    $suxwigb->{_box_X0}                                    = '';
    $suxwigb->{_box_Y0}                                    = '';
    $suxwigb->{_clip}                                      = '';
    $suxwigb->{_cmap}                                      = '';
    $suxwigb->{_curve}                                     = '';
    $suxwigb->{_curvecolor}                                = '';
    $suxwigb->{_curvefile}                                 = '';
    $suxwigb->{_ftr}                                       = '';
    $suxwigb->{_d1}                                        = '';
    $suxwigb->{_d1num}                                     = '';
    $suxwigb->{_dt}                                        = '';
    $suxwigb->{_d2}                                        = '';
    $suxwigb->{_dx}                                        = '';
    $suxwigb->{_dx_major_divisions}                        = '';
    $suxwigb->{_dy_major_divisions}                        = '';
    $suxwigb->{_dt_major_divisions}                        = '';
    $suxwigb->{_d2num}                                     = '';
    $suxwigb->{_dtr}                                       = '';
    $suxwigb->{_endian}                                    = '';
    $suxwigb->{_f1num}                                     = '';
    $suxwigb->{_f1}                                        = '';
    $suxwigb->{_first_y}                                   = '';
    $suxwigb->{_first_time_sample_value}                   = '';
    $suxwigb->{_f2}                                        = '';
    $suxwigb->{_first_x}                                   = '';
    $suxwigb->{_first_distance_sample_value}               = '';
    $suxwigb->{_first_distance_tick_num}                   = '';
    $suxwigb->{_f1num}                                     = '';
    $suxwigb->{_first_time_tick_num}                       = '';
    $suxwigb->{_f2num}                                     = '';
    $suxwigb->{_grid1}                                     = '';
    $suxwigb->{_grid2}                                     = '';
    $suxwigb->{_gridcolor}                                 = '';
    $suxwigb->{_hbox}                                      = '';
    $suxwigb->{_headerword}                                = '';
    $suxwigb->{_hiclip}                                    = '';
    $suxwigb->{_interp}                                    = '';
    $suxwigb->{_key}                                       = '';
    $suxwigb->{_label2}                                    = '';
    $suxwigb->{_labelfont}                                 = '';
    $suxwigb->{_labelcolor}                                = '';
    $suxwigb->{_label1}                                    = '';
    $suxwigb->{_label2}                                    = '';
    $suxwigb->{_loclip}                                    = '';
    $suxwigb->{_mpicks}                                    = '';
    $suxwigb->{_n1}                                        = '';
    $suxwigb->{_n1tic}                                     = '';
    $suxwigb->{_num_minor_ticks_betw_major_time_ticks}     = '';
    $suxwigb->{_n2}                                        = '';
    $suxwigb->{_n2tic}                                     = '';
    $suxwigb->{_npair}                                     = '';
    $suxwigb->{_num_minor_ticks_betw_major_distance_ticks} = '';
    $suxwigb->{_percent}                                   = '';
    $suxwigb->{_plotfile}                                  = '';
    $suxwigb->{_orientation}                               = '';
    $suxwigb->{_perc}                                      = '';
    $suxwigb->{_picks}                                     = '';
    $suxwigb->{_shading}                                   = '';
    $suxwigb->{_style}                                     = '';
    $suxwigb->{_tend_s}                                    = '';
    $suxwigb->{_tstart_s}                                  = '';
    $suxwigb->{_tmpdir}                                    = '';
    $suxwigb->{_trace_inc}                                 = '';
    $suxwigb->{_trace_inc_m}                               = '';
    $suxwigb->{_title}                                     = '';
    $suxwigb->{_titlefont}                                 = '';
    $suxwigb->{_titlecolor}                                = '';
    $suxwigb->{_va}                                        = '';
    $suxwigb->{_verbose}                                   = '';
    $suxwigb->{_wbox}                                      = '';
    $suxwigb->{_wigclip}                                   = '';
    $suxwigb->{_wt}                                        = '';
    $suxwigb->{_windowtitle}                               = '';
    $suxwigb->{_x2beg}                                     = '';
    $suxwigb->{_xstart_m}                                  = '';
    $suxwigb->{_x2end}                                     = '';
    $suxwigb->{_xend_m}                                    = '';
    $suxwigb->{_xcur}                                      = '';
    $suxwigb->{_x2}                                        = '';
    $suxwigb->{_x1beg}                                     = '';
    $suxwigb->{_xbox}                                      = '';
    $suxwigb->{_x1end}                                     = '';
    $suxwigb->{_xlabel}                                    = '';
    $suxwigb->{_x_tick_increment}                          = '';
    $suxwigb->{_xcur}                                      = '';
    $suxwigb->{_ylabel}                                    = '';
    $suxwigb->{_y_tick_increment}                          = '';
    $suxwigb->{_ybox}                                      = '';
    $suxwigb->{_verbose}                                   = '';
    $suxwigb->{_Step}                                      = '';
    $suxwigb->{_note}                                      = '';
}

=head2 sub absclip 

 define min and max plotting values
 define min and max plotting values
 
=cut

sub absclip {

    my ( $self, $absclip ) = @_;
    if ( $absclip ne $empty_string ) {

        $suxwigb->{_absclip} = $absclip;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' clip=' . $suxwigb->{_absclip};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' clip=' . $suxwigb->{_absclip};

    }
    else {
        print("suxwigb,missing absclip,\n");
    }
}

=head2 sub bclip 


=cut

sub bclip {

    my ( $self, $bclip ) = @_;
    if ( $bclip ne $empty_string ) {

        $suxwigb->{_bclip} = $bclip;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' bclip=' . $suxwigb->{_bclip};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' bclip=' . $suxwigb->{_bclip};

    }
    else {
        print("suxwigb, bclip, missing bclip,\n");
    }
}

=head2 sub bias 

G. Bonot 091718
Only shows data to the right (along axis 2) of each sample data value. Data accounts for
the right side of waveform amplitude and is adjusted on input 

=cut

sub bias {

    my ( $self, $bias ) = @_;
    if ( $bias ne $empty_string ) {

        $suxwigb->{_bias} = $bias;
        $suxwigb->{_note} = $suxwigb->{_note} . ' bias=' . $suxwigb->{_bias};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' bias=' . $suxwigb->{_bias};

    }
    else {
        print("suxwigb,missing bias,\n");
    }
}

=head2 sub box_X0


=cut

sub box_X0 {

    my ( $self, $xbox ) = @_;
    if ( $xbox ne $empty_string ) {

        $suxwigb->{_xbox} = $xbox;
        $suxwigb->{_note} = $suxwigb->{_note} . ' xbox=' . $suxwigb->{_xbox};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' xbox=' . $suxwigb->{_xbox};

    }
    else {
        print("suxwigb,box_X0 ,missing  xbox\n");
    }
}

=head2 sub box_Y0


=cut

sub box_Y0 {

    my ( $self, $ybox ) = @_;
    if ( $ybox ne $empty_string ) {

        $suxwigb->{_ybox} = $ybox;
        $suxwigb->{_note} = $suxwigb->{_note} . ' ybox=' . $suxwigb->{_ybox};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' ybox=' . $suxwigb->{_ybox};

    }
    else {
        print("suxwigb,box_Y0 ,missing  ybox\n");
    }
}

=head2 sub box_height


=cut

sub box_height {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $suxwigb->{_hbox} = $hbox;
        $suxwigb->{_note} = $suxwigb->{_note} . ' hbox=' . $suxwigb->{_hbox};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' hbox=' . $suxwigb->{_hbox};

    }
    else {
        print("suxwigb,box_height,missing hbox,\n");
    }
}

=head2 sub box_width


=cut

sub box_width {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $suxwigb->{_wbox} = $wbox;
        $suxwigb->{_note} = $suxwigb->{_note} . ' wbox=' . $suxwigb->{_wbox};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' wbox=' . $suxwigb->{_wbox};

    }
    else {
        print("box_width wbox,\n");
    }
}

=head2 sub clip

 define min and max plotting values

=cut

sub clip {

    my ( $self, $clip ) = @_;
    if ( $clip ne $empty_string ) {

        $suxwigb->{_clip} = $clip;
        $suxwigb->{_note} = $suxwigb->{_note} . ' clip=' . $suxwigb->{_clip};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' clip=' . $suxwigb->{_clip};

    }
    else {
        print("suxwigb,missing clip,\n");
    }
}

=head2 sub cmap 
 define min and max plotting values

=cut

sub cmap {

    my ( $self, $cmap ) = @_;
    if ( $cmap ne $empty_string ) {

        $suxwigb->{_cmap} = $cmap;
        $suxwigb->{_note} = $suxwigb->{_note} . ' cmap=' . $suxwigb->{_cmap};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' cmap=' . $suxwigb->{_cmap};

    }
    else {
        print("suxwigb,cmap, missing cmap,\n");
    }
}

=head2 sub curve 


=cut

sub curve {

    my ( $self, $curve ) = @_;
    if ( $curve ne $empty_string ) {

        $suxwigb->{_curve} = $curve;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' curve=' . $suxwigb->{_curve};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' curve=' . $suxwigb->{_curve};

    }
    else {
        print("suxwigb,missing curve,\n");
    }
}

=head2 sub curvecolor 


=cut

sub curvecolor {

    my ( $self, $curvecolor ) = @_;
    if ( $curvecolor ne $empty_string ) {

        $suxwigb->{_curvecolor} = $curvecolor;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' curvecolor=' . $suxwigb->{_curvecolor};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' curvecolor=' . $suxwigb->{_curvecolor};

    }
    else {
        print("suxwigb,missing curvecolor,\n");
    }
}

=head2 sub curvefile 


=cut

sub curvefile {

    my ( $self, $curvefile ) = @_;
    if ( $curvefile ne $empty_string ) {

        $suxwigb->{_curvefile} = $curvefile;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' curvefile=' . $suxwigb->{_curvefile};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' curvefile=' . $suxwigb->{_curvefile};

    }
    else {
        print("suxwigb,missing curvefile,\n");
    }
}

=head2 sub d1 

 increment in fast dimension
 usually time and equal to dt

=cut

sub d1 {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $suxwigb->{_d1}   = $d1;
        $suxwigb->{_note} = $suxwigb->{_note} . ' d1=' . $suxwigb->{_d1};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' d1=' . $suxwigb->{_d1};

    }
    else {
        print("suxwigb, d1, missing d1,\n");
    }
}

=head2 subs d1 and dt

 increment in fast dimension
 usually time and equal to dt 

=cut 

sub dt {

    my ( $self, $d1 ) = @_;

    if ( $d1 ne $empty_string ) {

        $suxwigb->{_d1}   = $d1;
        $suxwigb->{_note} = $suxwigb->{_note} . ' d1=' . $suxwigb->{_d1};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' d1=' . $suxwigb->{_d1};

    }
    else {
        print("suxwigb, dt, missing d1,\n");
    }
}

=head2 sub dt_major_divisions 

subs d1num, y_tick_increment dy_major_divisions dt_major_divisions

 numbered tick increments along x axis 
 usually in m and only for display 
 
 Kenny Lau
 16 Sept 2018
 Changes the interval between ticks

=cut

sub dt_major_divisions {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $suxwigb->{_d1num} = $d1num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' d1num=' . $suxwigb->{_d1num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' d1num=' . $suxwigb->{_d1num};

    }
    else {
        print("suxwigb,dt_major_divisions,missing d1num,\n");
    }

}

=head2 subs trace_inc trace_inc_m, dx and d2

 increment in fast dimension
 usually time and equal to dt

     only the first trace is read in
     if an increment is not 1 between traces
     you should indicate here
     
     distance increment between traces

=cut

sub dx {

    my ( $self, $d2 ) = @_;
    if ( $d2 ne $empty_string ) {

        $suxwigb->{_d2}   = $d2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' d2=' . $suxwigb->{_d2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' d2=' . $suxwigb->{_d2};

    }
    else {
        print("suxwigb, dx, missing d2,\n");
    }
}

=head2 sub dy_major_divisions 

subs d1num, y_tick_increment dy_major_divisions dt_major_divisions

 numbered tick increments along x axis 
 usually in m and only for display 
 
 Kenny Lau
 16 Sept 2018
 Changes the interval between ticks

=cut

sub dy_major_divisions {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $suxwigb->{_d1num} = $d1num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' d1num=' . $suxwigb->{_d1num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' d1num=' . $suxwigb->{_d1num};

    }
    else {
        print("suxwigb,dy_major_divisions,missing d1num,\n");
    }

}

=head2 sub d1num 

subs d1num, y_tick_increment dy_major_divisions dt_major_divisions

 numbered tick increments along x axis 
 usually in m and only for display 
 
 Kenny Lau
 16 Sept 2018
 Changes the interval between ticks

=cut

sub d1num {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $suxwigb->{_d1num} = $d1num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' d1num=' . $suxwigb->{_d1num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' d1num=' . $suxwigb->{_d1num};

    }
    else {
        print("suxwigb,missing d1num,\n");
    }
}

=head2 subs trace_inc trace_inc_m, dx and d2

 increment in fast dimension
 usually time and equal to dt

     only the first trace is read in
     if an increment is not 1 between traces
     you should indicate here
     
     distance increment between traces

=cut

sub d2 {

    my ( $self, $d2 ) = @_;
    if ( $d2 ne $empty_string ) {

        $suxwigb->{_d2}   = $d2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' d2=' . $suxwigb->{_d2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' d2=' . $suxwigb->{_d2};

    }
    else {
        print("suxwigb, d2, missing d2,\n");
    }
}

=head2 subs d2num  dx_major_divisions and x_tick_increment

 numbered tick increments along x axis 
 usually in m and only for display

=cut

sub d2num {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $suxwigb->{_d2num} = $d2num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' d2num=' . $suxwigb->{_d2num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' d2num=' . $suxwigb->{_d2num};

    }
    else {
        print("suxwigb,d2num, missing d2num,\n");
    }
}

=head2 sub endian 


=cut

sub endian {

    my ( $self, $endian ) = @_;
    if ( $endian ne $empty_string ) {

        $suxwigb->{_endian} = $endian;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' endian=' . $suxwigb->{_endian};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' endian=' . $suxwigb->{_endian};

    }
    else {
        print("suxwigb,missing endian,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut

sub f1 {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $suxwigb->{_f1}   = $f1;
        $suxwigb->{_note} = $suxwigb->{_note} . ' f1=' . $suxwigb->{_f1};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' f1=' . $suxwigb->{_f1};

    }
    else {
        print("suxwigb, f1, missing f1,\n");
    }
}

=head2 sub f1num 

subs f1num and first_time_tick_num 

 first number at the first tick
 
  Kenny Lau
 16 Sept 2018
 Changes the first number at the first tick

=cut

sub f1num {

    my ( $self, $f1num ) = @_;
    if ( $f1num ne $empty_string ) {

        $suxwigb->{_f1num} = $f1num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' f1num=' . $suxwigb->{_f1num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' f1num=' . $suxwigb->{_f1num};

    }
    else {
        print("suxwigb,missing f1num,\n");
    }
}

=head2 sub f2 


 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)
 
 G. Bonot 091718
 Shifts first sample data to right by amount input
 i.e., f2=5 makes data befin at 5 on the x axis.

=cut

sub f2 {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $suxwigb->{_f2}   = $f2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' f2=' . $suxwigb->{_f2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' f2=' . $suxwigb->{_f2};

    }
    else {
        print("suxwigb, f2, missing f2,\n");
    }
}

=head2 sub f2num 
subs f2num and first_distance_tick_num 

 first number at the first tick
 
 GTL18
 First number of x axis. Not incremental; only represents the 
 single first vale. X- axis increments ( d2num not equal to 0)
 must be created to use this feature; strictly for visual representation

=cut

sub f2num {

    my ( $self, $f2num ) = @_;
    if ( $f2num ne $empty_string ) {

        $suxwigb->{_f2num} = $f2num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' f2num=' . $suxwigb->{_f2num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' f2num=' . $suxwigb->{_f2num};

    }
    else {
        print("xwigb,missing f2num,\n");
    }
}

=head2 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)

=cut

sub first_distance_sample_value {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $suxwigb->{_f2}   = $f2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' f2=' . $suxwigb->{_f2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' f2=' . $suxwigb->{_f2};

    }
    else {
        print("suxwigb, first_distance_sample_value, missing f2,\n");
    }
}

=head2 sub first_distance_tick_num 
subs f2num and first_distance_tick_num 

 first number at the first tick
 
 GTL18
 First number of x axis. Not incremental; only represents the 
 single first vale. X- axis increments ( d2num not equal to 0)
 must be created to use this feature; strictly for visual representation

=cut

sub first_distance_tick_num {

    my ( $self, $f2num ) = @_;
    if ( $f2num ne $empty_string ) {

        $suxwigb->{_f2num} = $f2num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' f2num=' . $suxwigb->{_f2num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' f2num=' . $suxwigb->{_f2num};

    }
    else {
        print("suxwigb,missing first_distance_tick_num,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut 

sub first_time_sample_value {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $suxwigb->{_f1}   = $f1;
        $suxwigb->{_note} = $suxwigb->{_note} . ' f1=' . $suxwigb->{_f1};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' f1=' . $suxwigb->{_f1};

    }
    else {
        print("suxwigb, first_time_sample_value, missing f1,\n");
    }
}

=head2 sub first_time_tick_num 

subs f1num and first_time_tick_num 

 first number at the first tick
 
  Kenny Lau
 16 Sept 2018
 Changes the first number at the first tick

=cut

sub first_time_tick_num {

    my ( $self, $f1num ) = @_;
    if ( $f1num ne $empty_string ) {

        $suxwigb->{_f1num} = $f1num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' f1num=' . $suxwigb->{_f1num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' f1num=' . $suxwigb->{_f1num};

    }
    else {
        print("suxwigb, first_time_tick_num, missing first_time_tick_num\n");
    }
}

=head2 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)

=cut

sub first_x {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $suxwigb->{_f2}   = $f2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' f2=' . $suxwigb->{_f2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' f2=' . $suxwigb->{_f2};

    }
    else {
        print("suxwigb, first_x, missing f2,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut 

sub first_y {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $suxwigb->{_f1}   = $f1;
        $suxwigb->{_note} = $suxwigb->{_note} . ' f1=' . $suxwigb->{_f1};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' f1=' . $suxwigb->{_f1};

    }
    else {
        print("suxwigb, first_y, missing f1,\n");
    }
}

=head2 sub ftr 


=cut 

sub ftr {

    my ( $self, $ftr ) = @_;
    if ( $ftr ne $empty_string ) {

        $suxwigb->{_f1}   = $ftr;
        $suxwigb->{_note} = $suxwigb->{_note} . 'suxwigb' . $suxwigb->{_ftr};
        $suxwigb->{_Step} = $suxwigb->{_Step} . 'suxwigb' . $suxwigb->{_ftr};

    }
    else {
        print("suxwigb, first_y, missing f1,\n");
    }
}

=head2 sub grid1 

 Kenny Lau
 16 Sept 2018
 Changes the type of line on the first axis


=cut

sub grid1 {

    my ( $self, $grid1 ) = @_;
    if ( $grid1 ne $empty_string ) {

        $suxwigb->{_grid1} = $grid1;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' grid1=' . $suxwigb->{_grid1};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' grid1=' . $suxwigb->{_grid1};

    }
    else {
        print("suxwigb,missing grid1,\n");
    }
}

=head2 sub grid2 

   A. Sivil 091718
   Adds grid lines above x axis as either a dot, dash or a solid line
   
=cut

sub grid2 {

    my ( $self, $grid2 ) = @_;
    if ( $grid2 ne $empty_string ) {

        $suxwigb->{_grid2} = $grid2;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' grid2=' . $suxwigb->{_grid2};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' grid2=' . $suxwigb->{_grid2};

    }
    else {
        print("suxwigb,missing grid2,\n");
    }
}

=head2 sub gridcolor 


=cut

sub gridcolor {

    my ( $self, $gridcolor ) = @_;
    if ( $gridcolor ne $empty_string ) {

        $suxwigb->{_gridcolor} = $gridcolor;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' gridcolor=' . $suxwigb->{_gridcolor};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' gridcolor=' . $suxwigb->{_gridcolor};

    }
    else {
        print("suxwigb,missing gridcolor,\n");
    }
}

=head2 sub hbox 


=cut

sub hbox {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $suxwigb->{_hbox} = $hbox;
        $suxwigb->{_note} = $suxwigb->{_note} . ' hbox=' . $suxwigb->{_hbox};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' hbox=' . $suxwigb->{_hbox};

    }
    else {
        print("suxwigb,missing hbox,\n");
    }
}

=head2 sub headerword 


=cut

sub headerword {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suxwigb->{_key}  = $key;
        $suxwigb->{_note} = $suxwigb->{_note} . ' key=' . $suxwigb->{_key};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' key=' . $suxwigb->{_key};

    }
    else {
        print("suxwigb, headerword, missing key,\n");
    }
}

=head2 sub header_word 


=cut

sub header_word {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suxwigb->{_key}  = $key;
        $suxwigb->{_note} = $suxwigb->{_note} . ' key=' . $suxwigb->{_key};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' key=' . $suxwigb->{_key};

    }
    else {
        print("suxwigb, header_word, missing key,\n");
    }
}

=head2 sub hiclip 


=cut

sub hiclip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suxwigb->{_key}  = $key;
        $suxwigb->{_note} = $suxwigb->{_note} . ' bclip=' . $suxwigb->{_key};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' bclip=' . $suxwigb->{_key};

    }
    else {
        print("suxwigb, hiclip, missing key,\n");
    }
}

=head2 sub hi_clip 


=cut

sub hi_clip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suxwigb->{_key}  = $key;
        $suxwigb->{_note} = $suxwigb->{_note} . ' bclip=' . $suxwigb->{_key};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' bclip=' . $suxwigb->{_key};

    }
    else {
        print("suxwigb, hi_clip, missing key,\n");
    }
}

=head2 sub interp 


=cut

sub interp {

    my ( $self, $interp ) = @_;
    if ( $interp ne $empty_string ) {

        $suxwigb->{_interp} = $interp;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' interp=' . $suxwigb->{_interp};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' interp=' . $suxwigb->{_interp};

    }
    else {
        print("suxwigb,missing interp,\n");
    }
}

=head2 sub key 


=cut

sub key {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suxwigb->{_key}  = $key;
        $suxwigb->{_note} = $suxwigb->{_note} . ' key=' . $suxwigb->{_key};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' key=' . $suxwigb->{_key};

    }
    else {
        print("suxwigb, key, missing key,\n");
    }
}

=head2 sub label1 

=cut

sub label1 {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $suxwigb->{_label1} = $label1;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' label1=' . $suxwigb->{_label1};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' label1=' . $suxwigb->{_label1};

    }
    else {
        print("suxwigb,missing label1,\n");
    }
}

=head2 sub label2 

   A. Sivil 091718
   Adds label above x axis in top-right corner

=cut

sub label2 {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $suxwigb->{_label2} = $label2;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' label2=' . $suxwigb->{_label2};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' label2=' . $suxwigb->{_label2};

    }
    else {
        print("suxwigb,missing label2,\n");
    }
}

=head2 sub labelcolor 


=cut

sub labelcolor {

    my ( $self, $labelcolor ) = @_;
    if ( $labelcolor ne $empty_string ) {

        $suxwigb->{_labelcolor} = $labelcolor;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' labelcolor=' . $suxwigb->{_labelcolor};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' labelcolor=' . $suxwigb->{_labelcolor};

    }
    else {
        print("suxwigb,missing labelcolor,\n");
    }
}

=head2 sub labelfont 

   A. Sivil 091718
   Changes font for label

=cut

sub labelfont {

    my ( $self, $labelfont ) = @_;
    if ( $labelfont ne $empty_string ) {

        $suxwigb->{_labelfont} = $labelfont;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' labelfont=' . $suxwigb->{_labelfont};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' labelfont=' . $suxwigb->{_labelfont};

    }
    else {
        print("suxwigb,missing labelfont,\n");
    }
}

=head2 sub lo_clip 


=cut

sub lo_clip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suxwigb->{_key}  = $key;
        $suxwigb->{_note} = $suxwigb->{_note} . ' wclip=' . $suxwigb->{_key};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' wclip=' . $suxwigb->{_key};

    }
    else {
        print("suxwigb, lo_clip, missing key,\n");
    }
}

=head2 sub loclip 


=cut

sub loclip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $suxwigb->{_key}  = $key;
        $suxwigb->{_note} = $suxwigb->{_note} . ' wclip=' . $suxwigb->{_key};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' wclip=' . $suxwigb->{_key};

    }
    else {
        print("suxwigb, loclip, missing key,\n");
    }
}

=head2 sub mpicks 

G. Bonot 091718
Input a file name to which your mouse clicks are to be saved. No visible change observed in xwigb

=cut

sub mpicks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        $suxwigb->{_mpicks} = $mpicks;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' mpicks=' . $suxwigb->{_mpicks};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' mpicks=' . $suxwigb->{_mpicks};

    }
    else {
        print("suxwigb,missing mpicks,\n");
    }
}

=head2 sub n1 

=cut

sub n1 {

    my ( $self, $n1 ) = @_;
    if ( $n1 ne $empty_string ) {

        $suxwigb->{_n1}   = $n1;
        $suxwigb->{_note} = $suxwigb->{_note} . ' n1=' . $suxwigb->{_n1};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' n1=' . $suxwigb->{_n1};

    }
    else {
        print("suxwigb,missing n1,\n");
    }
}

=head2 sub n1tic 

subs n1tic and num_minor_ticks_betw_time_ticks

 n1tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)
   
  Kenny Lau
 16 Sept 2018
 Breaks down one tick into X number of minor ticks 

=cut

sub n1tic {

    my ( $self, $n1tic ) = @_;
    if ( $n1tic ne $empty_string ) {

        $suxwigb->{_n1tic} = $n1tic;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' n1tic=' . $suxwigb->{_n1tic};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' n1tic=' . $suxwigb->{_n1tic};

    }
    else {
        print("suxwigb,missing n1tic,\n");
    }
}

=head2 sub n2 


=cut

sub n2 {

    my ( $self, $n2 ) = @_;
    if ( $n2 ne $empty_string ) {

        $suxwigb->{_n2}   = $n2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' n2=' . $suxwigb->{_n2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' n2=' . $suxwigb->{_n2};

    }
    else {
        print("suxwigb, n2, missing n2,\n");
    }
}

=head2 ssubs n2tic and num_minor_ticks_betw_distance_ticks

 n2tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)

   A. Sivil 091718
   Adds minor ticks between each numbered tick on axis 1   

=cut

sub n2tic {

    my ( $self, $n2tic ) = @_;
    if ( $n2tic ne $empty_string ) {

        $suxwigb->{_n2tic} = $n2tic;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' n2tic=' . $suxwigb->{_n2tic};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' n2tic=' . $suxwigb->{_n2tic};

    }
    else {
        print("suxwigb,missing n2tic,\n");
    }
}

=head2 sub npair 


=cut

sub npair {

    my ( $self, $npair ) = @_;
    if ( $npair ne $empty_string ) {

        $suxwigb->{_npair} = $npair;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' npair=' . $suxwigb->{_npair};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' npair=' . $suxwigb->{_npair};

    }
    else {
        print("suxwigb,missing npair,\n");
    }
}

=head2 ssubs n2tic and num_minor_ticks_betw_distance_ticks

 n2tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)

   A. Sivil 091718
   Adds minor ticks between each numbered tick on axis 1   

=cut

sub num_minor_ticks_betw_distance_ticks {

    my ( $self, $n2tic ) = @_;
    if ( $n2tic ne $empty_string ) {

        $suxwigb->{_n2tic} = $n2tic;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' n2tic=' . $suxwigb->{_n2tic};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' n2tic=' . $suxwigb->{_n2tic};

    }
    else {
        print("suxwigb,num_minor_ticks_betw_distance_ticks, missing n2tic,\n");
    }
}

=head2 sub num_minor_ticks_betw_time_ticks 

subs n1tic and num_minor_ticks_betw_time_ticks

 n1tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)
   
  Kenny Lau
 16 Sept 2018
 Breaks down one tick into X number of minor ticks 

=cut

sub num_minor_ticks_betw_time_ticks {

    my ( $self, $n1tic ) = @_;
    if ( $n1tic ne $empty_string ) {

        $suxwigb->{_n1tic} = $n1tic;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' n1tic=' . $suxwigb->{_n1tic};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' n1tic=' . $suxwigb->{_n1tic};

    }
    else {
        print("suxwigb, num_minor_ticks_betw_time_ticks, missing n1tic,\n");
    }
}

=head2 sub orientation 

  seismic style of plotting (time axis pointing down)
  versus mathematical ( y axis up)

=cut

sub orientation {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $suxwigb->{_style} = $style;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' style=' . $suxwigb->{_style};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' style=' . $suxwigb->{_style};

    }
    else {
        print("suxwigb, orientation, missing style,\n");
    }
}

=head2 sub perc 


=cut

sub perc {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $suxwigb->{_perc} = $perc;
        $suxwigb->{_note} = $suxwigb->{_note} . ' perc=' . $suxwigb->{_perc};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' perc=' . $suxwigb->{_perc};

    }
    else {
        print("suxwigb,missing perc,\n");
    }
}

=head2 sub percent 


=cut

sub percent {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $suxwigb->{_perc} = $perc;
        $suxwigb->{_note} = $suxwigb->{_note} . ' perc=' . $suxwigb->{_perc};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' perc=' . $suxwigb->{_perc};

    }
    else {
        print("suxwigb,percent, missing perc,\n");
    }
}

=head2 sub picks

 automatically generates a pick file
 
=cut

sub picks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        # print("suxwigb, picks, file_name is: $mpicks\n");

        $suxwigb->{_mpicks} = $mpicks;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' mpicks=' . $suxwigb->{_mpicks};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' mpicks=' . $suxwigb->{_mpicks};

    }
    else {
        print("suxwigb,picks, missing mpicks,\n");
    }
}

=head2 sub plotfile 


=cut

sub plotfile {

    my ( $self, $plotfile ) = @_;
    if ( $plotfile ne $empty_string ) {

        $suxwigb->{_plotfile} = $plotfile;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' plotfile=' . $suxwigb->{_plotfile};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' plotfile=' . $suxwigb->{_plotfile};

    }
    else {
        print("suxwigb,missing plotfile,\n");
    }
}

=head2 sub shading 
  plot data using a variable area scheme
  also sub shading
  Rachel Gnieski 091718
  Plot data using a variable area scheme: Should change the shading of the plot
  background by inputting a value between 2 and 5 but could not get it to function

=cut

sub shading {

    my ( $self, $va ) = @_;
    if ( $va ne $empty_string ) {

        $suxwigb->{_va}   = $va;
        $suxwigb->{_note} = $suxwigb->{_note} . ' va=' . $suxwigb->{_va};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' va=' . $suxwigb->{_va};

    }
    else {
        print("suxwigb,shading, missing va\n");
    }
}

=head2 sub style 

  seismic style of plotting (time axis pointing down)
  versus mathematical ( y axis up)

=cut

sub style {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $suxwigb->{_style} = $style;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' style=' . $suxwigb->{_style};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' style=' . $suxwigb->{_style};

    }
    else {
        print("suxwigb, style, missing style,\n");
    }
}

=head2 sub title 

 allows for a default graph title ($on) or
 a user-defined title

=cut

sub title {

    my ( $self, $title ) = @_;
    if ( $title ne $empty_string ) {

        $suxwigb->{_title} = $title;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' title=' . $suxwigb->{_title};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' title=' . $suxwigb->{_title};

    }
    else {
        print("suxwigb,missing title,\n");
    }
}

=head2 sub titlecolor 

 allows for a default graph title ($on) or
 a user-defined title

=cut

sub titlecolor {

    my ( $self, $titlecolor ) = @_;
    if ( $titlecolor ne $empty_string ) {

        $suxwigb->{_titlecolor} = $titlecolor;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' titlecolor=' . $suxwigb->{_titlecolor};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' titlecolor=' . $suxwigb->{_titlecolor};

    }
    else {
        print("suxwigb,missing titlecolor,\n");
    }
}

=head2 sub titlefont 


=cut

sub titlefont {

    my ( $self, $titlefont ) = @_;
    if ( $titlefont ne $empty_string ) {

        $suxwigb->{_titlefont} = $titlefont;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' titlefont=' . $suxwigb->{_titlefont};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' titlefont=' . $suxwigb->{_titlefont};

    }
    else {
        print("suxwigb,missing titlefont,\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ( $tmpdir ne $empty_string ) {

        $suxwigb->{_tmpdir} = $tmpdir;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' tmpdir=' . $suxwigb->{_tmpdir};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' tmpdir=' . $suxwigb->{_tmpdir};

    }
    else {
        print("suxwigb, tmpdir, missing tmpdir,\n");
    }
}

=head2 subs trace_inc trace_inc_m, dx and d2

 increment in fast dimension
 usually time and equal to dt

     only the first trace is read in
     if an increment is not 1 between traces
     you should indicate here
     
     distance increment between traces

=cut

sub trace_inc {

    my ( $self, $d2 ) = @_;
    if ( $d2 ne $empty_string ) {

        $suxwigb->{_d2}   = $d2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' d2=' . $suxwigb->{_d2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' d2=' . $suxwigb->{_d2};

    }
    else {
        print("suxwigb, trace_inc, missing d2,\n");
    }
}

=head2 subs trace_inc trace_inc_m, dx and d2

 increment in fast dimension
 usually time and equal to dt

     only the first trace is read in
     if an increment is not 1 between traces
     you should indicate here
     
     distance increment between traces

=cut

sub trace_inc_m {

    my ( $self, $d2 ) = @_;
    if ( $d2 ne $empty_string ) {

        $suxwigb->{_d2}   = $d2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' d2=' . $suxwigb->{_d2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' d2=' . $suxwigb->{_d2};

    }
    else {
        print("suxwigb, trace_inc_m, missing d2,\n");
    }
}

=head2 sub tend_s 

minimum value of yaxis (time usually) in seconds

=cut

sub tend_s {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $suxwigb->{_x1end} = $x1end;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' x1end=' . $suxwigb->{_x1end};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' x1end=' . $suxwigb->{_x1end};

    }
    else {
        print("suxwigb,tend_s, missing x1end,\n");
    }
}

=head2 sub tstart_s 

  minimum value of yaxis (time usually) in seconds

=cut

sub tstart_s {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $suxwigb->{_x1beg} = $x1beg;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' x1beg=' . $suxwigb->{_x1beg};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' x1beg=' . $suxwigb->{_x1beg};

    }
    else {
        print("suxwigb,tstart_s, missing x1beg,\n");
    }
}

=head2 sub va 
  plot data using a variable area scheme
  also sub shading
  Rachel Gnieski 091718
  Plot data using a variable area scheme: Should change the shading of the plot
  background by inputting a value between 2 and 5 but could not get it to function

=cut

sub va {

    my ( $self, $va ) = @_;
    if ( $va ne $empty_string ) {

        $suxwigb->{_va}   = $va;
        $suxwigb->{_note} = $suxwigb->{_note} . ' va=' . $suxwigb->{_va};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' va=' . $suxwigb->{_va};

    }
    else {
        print("suxwigb,missing va,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $suxwigb->{_verbose} = $verbose;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' verbose=' . $suxwigb->{_verbose};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' verbose=' . $suxwigb->{_verbose};

    }
    else {
        print("suxwigb, verbose, missing verbose,\n");
    }
}

=head2 sub wbox 


=cut

sub wbox {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $suxwigb->{_wbox} = $wbox;
        $suxwigb->{_note} = $suxwigb->{_note} . ' wbox=' . $suxwigb->{_wbox};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' wbox=' . $suxwigb->{_wbox};

    }
    else {
        print("suxwigb,missing wbox,\n");
    }
}

=head2 sub wclip 


=cut

sub wclip {

    my ( $self, $wclip ) = @_;
    if ( $wclip ne $empty_string ) {

        $suxwigb->{_wclip} = $wclip;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' wclip=' . $suxwigb->{_wclip};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' wclip=' . $suxwigb->{_wclip};

    }
    else {
        print("suxwigb, wclip, missing wclip,\n");
    }
}

=head2 sub wigclip 


=cut

sub wigclip {

    my ( $self, $wigclip ) = @_;
    if ( $wigclip ne $empty_string ) {

        $suxwigb->{_wigclip} = $wigclip;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' wigclip=' . $suxwigb->{_wigclip};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' wigclip=' . $suxwigb->{_wigclip};

    }
    else {
        print("suxwigb,missing wigclip,\n");
    }
}

=head2 sub windowtitle 


=cut

sub windowtitle {

    my ( $self, $windowtitle ) = @_;
    if ( $windowtitle ne $empty_string ) {

        $suxwigb->{_windowtitle} = $windowtitle;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' windowtitle=' . $suxwigb->{_windowtitle};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' windowtitle=' . $suxwigb->{_windowtitle};

    }
    else {
        print("suxwigb,missing windowtitle,\n");
    }
}

=head2 sub wt 


=cut

sub wt {

    my ( $self, $wt ) = @_;
    if ( $wt ne $empty_string ) {

        $suxwigb->{_wt}   = $wt;
        $suxwigb->{_note} = $suxwigb->{_note} . ' wt=' . $suxwigb->{_wt};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' wt=' . $suxwigb->{_wt};

    }
    else {
        print("suxwigb,missing wt,\n");
    }
}

=head2 sub x1beg 

  minimum value of yaxis (time usually) in seconds

=cut

sub x1beg {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $suxwigb->{_x1beg} = $x1beg;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' x1beg=' . $suxwigb->{_x1beg};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' x1beg=' . $suxwigb->{_x1beg};

    }
    else {
        print("suxwigb,missing x1beg,\n");
    }
}

=head2 sub x1end 

minimum value of yaxis (time usually) in seconds

=cut

sub x1end {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $suxwigb->{_x1end} = $x1end;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' x1end=' . $suxwigb->{_x1end};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' x1end=' . $suxwigb->{_x1end};

    }
    else {
        print("suxwigb,missing x1end,\n");
    }
}

=head2 sub x2 

G. Bonot 091718
Lists array of values in the second dimension; displays one isolated sample value
in different of the input value


=cut

sub x2 {

    my ( $self, $x2 ) = @_;
    if ( $x2 ne $empty_string ) {

        $suxwigb->{_x2}   = $x2;
        $suxwigb->{_note} = $suxwigb->{_note} . ' x2=' . $suxwigb->{_x2};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' x2=' . $suxwigb->{_x2};

    }
    else {
        print("suxwigb,missing x2,\n");
    }
}

=head2 sub x2beg 

 minimum value of x axis (time usually) in seconds
 First value shown on x axis GTL18
 

=cut

sub x2beg {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $suxwigb->{_x2beg} = $x2beg;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' x2beg=' . $suxwigb->{_x2beg};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' x2beg=' . $suxwigb->{_x2beg};

    }
    else {
        print("suxwigb,missing x2beg,\n");
    }
}

=head2 sub x2end 
  
  max value of xaxis (distance or traces, usually) in seconds
  Last value for data shown on x axis GTL18

=cut

sub x2end {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $suxwigb->{_x2end} = $x2end;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' x2end=' . $suxwigb->{_x2end};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' x2end=' . $suxwigb->{_x2end};

    }
    else {
        print("suxwigb,missing x2end,\n");
    }
}

=head2 sub xbox 

  Rachel Gnieski 091718
  x pixels fo the upper corner of the window: Changing this value determines where the 
  graph will open up on the screen based on the horizontal row of pixels

=cut

sub xbox {

    my ( $self, $xbox ) = @_;
    if ( $xbox ne $empty_string ) {

        $suxwigb->{_xbox} = $xbox;
        $suxwigb->{_note} = $suxwigb->{_note} . ' xbox=' . $suxwigb->{_xbox};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' xbox=' . $suxwigb->{_xbox};

    }
    else {
        print("suxwigb,missing xbox,\n");
    }
}

=head2 sub xcur 

how many adjacent wiggles can be overploted

=cut

sub xcur {

    my ( $self, $xcur ) = @_;
    if ( $xcur ne $empty_string ) {

        $suxwigb->{_xcur} = $xcur;
        $suxwigb->{_note} = $suxwigb->{_note} . ' xcur=' . $suxwigb->{_xcur};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' xcur=' . $suxwigb->{_xcur};

    }
    else {
        print("suxwigb,missing xcur,\n");
    }
}

=head2 sub xend_m 

 
=cut

sub xend_m {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $suxwigb->{_x2end} = $x2end;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' x2end=' . $suxwigb->{_x2end};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' x2end=' . $suxwigb->{_x2end};

    }
    else {
        print("suxwigb,xend_m, missing x2end,\n");
    }
}

=head2 subs xlabel or label2 ylabel or label1


=cut

sub xlabel {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $suxwigb->{_label2} = $label2;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' label2=' . $suxwigb->{_label2};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' label2=' . $suxwigb->{_label2};

    }
    else {
        print("suxwigb, xlabelmissing label2,\n");
    }
}

=head2 sub xstart_m 

 
=cut

sub xstart_m {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $suxwigb->{_x2beg} = $x2beg;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' x2beg=' . $suxwigb->{_x2beg};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' x2beg=' . $suxwigb->{_x2beg};

    }
    else {
        print("suxwigb,xstart_m, missing x2beg,\n");
    }
}

=head2 subs d2num  dx_major_divisions and x_tick_increment

 numbered tick increments along x axis 
 usually in m and only for display

=cut

sub x_tick_increment {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $suxwigb->{_d2num} = $d2num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' d2num=' . $suxwigb->{_d2num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' d2num=' . $suxwigb->{_d2num};

    }
    else {
        print("suxwigb,d2num, missing d2num,\n");
    }
}

=head2 sub ybox 

  Rachel Gnieski 091718
  y pixels for the upper left corner of the window. Changing this value determines
  where the graph will open up on the screen based on the vertical column of pixes.

=cut

sub ybox {

    my ( $self, $ybox ) = @_;
    if ( $ybox ne $empty_string ) {

        $suxwigb->{_ybox} = $ybox;
        $suxwigb->{_note} = $suxwigb->{_note} . ' ybox=' . $suxwigb->{_ybox};
        $suxwigb->{_Step} = $suxwigb->{_Step} . ' ybox=' . $suxwigb->{_ybox};

    }
    else {
        print("suxwigb,missing ybox,\n");
    }
}

=head2 subs ylabel or label1


=cut

sub ylabel {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $suxwigb->{_label1} = $label1;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' label1=' . $suxwigb->{_label1};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' label1=' . $suxwigb->{_label1};

    }
    else {
        print("suxwigb, ylabel, missing label1,\n");
    }
}

=head2 sub y_tick_increment 

subs d1num, y_tick_increment dy_major_divisions dt_major_divisions

 numbered tick increments along x axis 
 usually in m and only for display 
 
 Kenny Lau
 16 Sept 2018
 Changes the interval between ticks

=cut

sub y_tick_increment {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $suxwigb->{_d1num} = $d1num;
        $suxwigb->{_note} =
          $suxwigb->{_note} . ' d1num=' . $suxwigb->{_d1num};
        $suxwigb->{_Step} =
          $suxwigb->{_Step} . ' d1num=' . $suxwigb->{_d1num};

    }
    else {
        print("suxwigb,y_tick_increment,missing d1num,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 51;

    return ($max_index);
}

1;
