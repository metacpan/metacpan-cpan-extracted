 package App::SeismicUnixGui::sunix::plot::supswigb;

=head1 DOCUMENTATION

=head2 SYNOPSIS

PACKAGE NAME:  SUPSWIGB - PostScript Bit-mapped WIGgle plot of a segy data set	
AUTHOR: Juan Lorenzo
DATE:   
DESCRIPTION:
Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 SUPSWIGB - PostScript Bit-mapped WIGgle plot of a segy data set	

 supswigb <stdin [optional parameters] > 				

 Optional parameters:						 	
 key=(keyword)		if set, the values of x2 are set from header field
			specified by keyword				
 n2=tr.ntr or number of traces in the data set	(ntr is an alias for n2)
 d1=tr.d1 or tr.dt/10^6	sampling interval in the fast dimension	
   =.004 for seismic 		(if not set)				
   =1.0 for nonseismic		(if not set)				
 d2=tr.d2			sampling interval in the slow dimension	
   =1.0 			(if not set)				
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
 Type   sukeyword -o   to see the complete list of SU keywords.	

 This program is really just a wrapper for the plotting program: pswigb
 See the pswigb selfdoc for the remaining parameters.			

 Trace header fields accessed: ns, ntr, tracr, tracl, delrt, trid,     
	dt, d1, d2, f1, f2, keyword (if set)				

 Credits:

	CWP: Dave Hale and Zhiming Li (pswigb, etc.)
	   Jack Cohen and John Stockwell (supswigb, etc.)
      Delphi: Alexander Koek, added support for irregularly spaced traces 

	Modified by Brian Zook, Southwest Research Institute, to honor
	 scale factors, added vsp style

 Notes:
	When the number of traces isn't known, we need to count
	the traces for pswigb.  You can make this value "known"
	either by getparring n2 or by having the ntr field set
	in the trace header.  A getparred value takes precedence
	over the value in the trace header.

	When we must compute ntr, we don't allocate a 2-d array,
	but just content ourselves with copying trace by trace from
	the data "file" to the pipe into the plotting program.
	Although we could use tr.data, we allocate a trace buffer
	for code clarity.
	
	
SUPSWIGB inherits all the properties of PSWIGB

PSWIGB - PostScript WIGgle-trace plot of f(x1,x2) via Bitmap		
 Best for many traces.  Use PSWIGP (Polygon version) for few traces.	

 pswigb n1= [optional parameters] <binaryfile >postscriptfile		

 Required Parameters:							
 n1                     number of samples in 1st (fast) dimension	

 Optional Parameters:							
 d1=1.0                 sampling interval in 1st dimension		
 f1=0.0                 first sample in 1st dimension			
 n2=all                 number of samples in 2nd (slow) dimension	
 d2=1.0                 sampling interval in 2nd dimension		
 f2=0.0                 first sample in 2nd dimension			
 x2=f2,f2+d2,...        array of sampled values in 2nd dimension	
 bias=0.0               data value corresponding to location along axis 2
 perc=100.0             percentile for determining clip		
 clip=(perc percentile) data values < bias+clip and > bias-clip are clipped
 xcur=1.0               wiggle excursion in traces corresponding to clip
 wt=1                   =0 for no wiggle-trace; =1 for wiggle-trace	
 va=1                   =0 for no variable-area; =1 for variable-area fill
                        =2 for variable area, solid/grey fill          
                        SHADING: 2<= va <=5  va=2 lightgrey, va=5 black", 
 nbpi=72                number of bits per inch at which to rasterize	
 verbose=1              =1 for info printed on stderr (0 for no info)	
 xbox=1.5               offset in inches of left side of axes box	
 ybox=1.5               offset in inches of bottom side of axes box	
 wbox=6.0               width in inches of axes box			
 hbox=8.0               height in inches of axes box			
 x1beg=x1min            value at which axis 1 begins			
 x1end=x1max            value at which axis 1 ends			
 d1num=0.0              numbered tic interval on axis 1 (0.0 for automatic)
 f1num=x1min            first numbered tic on axis 1 (used if d1num not 0.0)
 n1tic=1                number of tics per numbered tic on axis 1	
 grid1=none             grid lines on axis 1 - none, dot, dash, or solid
 label1=                label on axis 1				
 x2beg=x2min            value at which axis 2 begins			
 x2end=x2max            value at which axis 2 ends			
 d2num=0.0              numbered tic interval on axis 2 (0.0 for automatic)
 f2num=x2min            first numbered tic on axis 2 (used if d2num not 0.0)
 n2tic=1                number of tics per numbered tic on axis 2	
 grid2=none             grid lines on axis 2 - none, dot, dash, or solid
 label2=                label on axis 2				
 labelfont=Helvetica    font name for axes labels			
 labelsize=18           font size for axes labels			
 title=                 title of plot					
 titlefont=Helvetica-Bold font name for title				
 titlesize=24           font size for title				
 titlecolor=black       color of title					
 axescolor=black        color of axes					
 gridcolor=black        color of grid					
 axeswidth=1            width (in points) of axes			
 ticwidth=axeswidth     width (in points) of tic marks		
 gridwidth=axeswidth    width (in points) of grid lines		
 style=seismic          normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)	
 interp=0		 no display interpolation			
			 =1 use 8 point sinc interpolation		
 curve=curve1,curve2,...  file(s) containing points to draw curve(s)   
 npair=n1,n2,n2,...            number(s) of pairs in each file         
 curvecolor=black,..    color of curve(s)                              
 curvewidth=axeswidth   width (in points) of curve(s)                  
 curvedash=0            solid curve(s), dash indices 1,...,11 produce  
                        curve(s) with various dash styles              

 Notes: 								
 The interp option may be useful for high nbpi values, however, it	
 tacitly assumes that the data are purely oscillatory.	Non-oscillatory	
 data will not be represented correctly when this option is set.	

 The curve file is an ascii file with the points specified as x1 x2	
 pairs, one pair to a line.  A "vector" of curve files and curve	
 colors may be specified as curvefile=file1,file2,etc. and 		
 curvecolor=color1,color2,etc, and the number of pairs of values in each
 file as npair=npair1,npair2,... .					

 All color specifications may also be made in X Window style Hex format
 example:   axescolor=#255						

 Legal font names are:							
 AvantGarde-Book AvantGarde-BookOblique AvantGarde-Demi AvantGarde-DemiOblique"
 Bookman-Demi Bookman-DemiItalic Bookman-Light Bookman-LightItalic 
 Courier Courier-Bold Courier-BoldOblique Courier-Oblique 
 Helvetica Helvetica-Bold Helvetica-BoldOblique Helvetica-Oblique 
 Helvetica-Narrow Helvetica-Narrow-Bold Helvetica-Narrow-BoldOblique 
 Helvetica-Narrow-Oblique NewCentrySchlbk-Bold"
 NewCenturySchlbk-BoldItalic NewCenturySchlbk-Roman Palatino-Bold  
 Palatino-BoldItalic Palatino-Italics Palatino-Roman 
 SanSerif-Bold SanSerif-BoldItalic SanSerif-Roman 
 Symbol Times-Bold Times-BoldItalic 
 Times-Roman Times-Italic ZapfChancery-MediumItalic 


=head2 CHANGES and their DATES

V0.0.2 supswigb <stdin [optional parameters] > (JML for SeismicUnixGui 2.8.23)	

=cut

 use Moose;
our $VERSION = '0.0.2';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

	my $get					= L_SU_global_constants->new();

	my $var				= $get->var();
	my $empty_string    	= $var->{_empty_string};


	my $supswigb		= {
    _absclip                                   => '',
    _bias                                      => '',
    _box_width_inch                                 => '',
    _box_height_inch                                => '',
    _box_X0_inch                                    => '',
    _box_Y0_inch                                    => '',
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
    _nbpi									   => '',
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

    $supswigb->{_Step} = 'supswigb' . $supswigb->{_Step};
    return ( $supswigb->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $supswigb->{_note} = 'supswigb' . $supswigb->{_note};
    return ( $supswigb->{_note} );

}

=head2 sub clear

 50 + 43 personalized  params
clear global variables from the memory

=cut

sub clear {

    $supswigb->{_d1}                                        = '';
    $supswigb->{_d2}                                        = '';
    $supswigb->{_f1}                                        = '';
    $supswigb->{_f2}                                        = '';
    $supswigb->{_key}                                       = '';
    $supswigb->{_n2}                                        = '';
    $supswigb->{_style}                                     = '';
    $supswigb->{_tmpdir}                                    = '';
    $supswigb->{_absclip}                                   = '';
    $supswigb->{_bias}                                      = '';
    $supswigb->{_box_width_inch}                                 = '';
    $supswigb->{_box_height_inch}                                = '';
    $supswigb->{_box_X0_inch}                                    = '';
    $supswigb->{_box_Y0_inch}                                    = '';
    $supswigb->{_clip}                                      = '';
    $supswigb->{_cmap}                                      = '';
    $supswigb->{_curve}                                     = '';
    $supswigb->{_curvecolor}                                = '';
    $supswigb->{_curvefile}                                 = '';
    $supswigb->{_ftr}                                       = '';
    $supswigb->{_d1}                                        = '';
    $supswigb->{_d1num}                                     = '';
    $supswigb->{_dt}                                        = '';
    $supswigb->{_d2}                                        = '';
    $supswigb->{_dx}                                        = '';
    $supswigb->{_dx_major_divisions}                        = '';
    $supswigb->{_dy_major_divisions}                        = '';
    $supswigb->{_dt_major_divisions}                        = '';
    $supswigb->{_d2num}                                     = '';
    $supswigb->{_dtr}                                       = '';
    $supswigb->{_endian}                                    = '';
    $supswigb->{_f1num}                                     = '';
    $supswigb->{_f1}                                        = '';
    $supswigb->{_first_y}                                   = '';
    $supswigb->{_first_time_sample_value}                   = '';
    $supswigb->{_f2}                                        = '';
    $supswigb->{_first_x}                                   = '';
    $supswigb->{_first_distance_sample_value}               = '';
    $supswigb->{_first_distance_tick_num}                   = '';
    $supswigb->{_f1num}                                     = '';
    $supswigb->{_first_time_tick_num}                       = '';
    $supswigb->{_f2num}                                     = '';
    $supswigb->{_grid1}                                     = '';
    $supswigb->{_grid2}                                     = '';
    $supswigb->{_gridcolor}                                 = '';
    $supswigb->{_hbox}                                      = '';
    $supswigb->{_headerword}                                = '';
    $supswigb->{_hiclip}                                    = '';
    $supswigb->{_interp}                                    = '';
    $supswigb->{_key}                                       = '';
    $supswigb->{_label2}                                    = '';
    $supswigb->{_labelfont}                                 = '';
    $supswigb->{_labelcolor}                                = '';
    $supswigb->{_label1}                                    = '';
    $supswigb->{_label2}                                    = '';
    $supswigb->{_loclip}                                    = '';
    $supswigb->{_mpicks}                                    = '';
    $supswigb->{_n1}                                        = '';
    $supswigb->{_n1tic}                                     = '';
    $supswigb->{_num_minor_ticks_betw_major_time_ticks}     = '';
    $supswigb->{_n2}                                        = '';
    $supswigb->{_n2tic}                                     = '';
    $supswigb->{_npair}                                     = '';
    $supswigb->{_num_minor_ticks_betw_major_distance_ticks} = '';
    $supswigb->{_percent}                                   = '';
    $supswigb->{_plotfile}                                  = '';
    $supswigb->{_orientation}                               = '';
    $supswigb->{_perc}                                      = '';
    $supswigb->{_picks}                                     = '';
    $supswigb->{_shading}                                   = '';
    $supswigb->{_style}                                     = '';
    $supswigb->{_tend_s}                                    = '';
    $supswigb->{_tstart_s}                                  = '';
    $supswigb->{_tmpdir}                                    = '';
    $supswigb->{_trace_inc}                                 = '';
    $supswigb->{_trace_inc_m}                               = '';
    $supswigb->{_title}                                     = '';
    $supswigb->{_titlefont}                                 = '';
    $supswigb->{_titlecolor}                                = '';
    $supswigb->{_va}                                        = '';
    $supswigb->{_verbose}                                   = '';
    $supswigb->{_wbox}                                      = '';
    $supswigb->{_wigclip}                                   = '';
    $supswigb->{_wt}                                        = '';
    $supswigb->{_windowtitle}                               = '';
    $supswigb->{_x2beg}                                     = '';
    $supswigb->{_xstart_m}                                  = '';
    $supswigb->{_x2end}                                     = '';
    $supswigb->{_xend_m}                                    = '';
    $supswigb->{_xcur}                                      = '';
    $supswigb->{_x2}                                        = '';
    $supswigb->{_x1beg}                                     = '';
    $supswigb->{_xbox}                                      = '';
    $supswigb->{_x1end}                                     = '';
    $supswigb->{_xlabel}                                    = '';
    $supswigb->{_x_tick_increment}                          = '';
    $supswigb->{_xcur}                                      = '';
    $supswigb->{_ylabel}                                    = '';
    $supswigb->{_y_tick_increment}                          = '';
    $supswigb->{_ybox}                                      = '';
    $supswigb->{_verbose}                                   = '';
    $supswigb->{_Step}                                      = '';
    $supswigb->{_note}                                      = '';
}

=head2 sub absclip 

 define min and max plotting values
 define min and max plotting values
 
=cut

sub absclip {

    my ( $self, $absclip ) = @_;
    if ( $absclip ne $empty_string ) {

        $supswigb->{_absclip} = $absclip;
        $supswigb->{_note} =
          $supswigb->{_note} . ' clip=' . $supswigb->{_absclip};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' clip=' . $supswigb->{_absclip};

    }
    else {
        print("supswigb,missing absclip,\n");
    }
}

=head2 sub bclip 


=cut

sub bclip {

    my ( $self, $bclip ) = @_;
    if ( $bclip ne $empty_string ) {

        $supswigb->{_bclip} = $bclip;
        $supswigb->{_note} =
          $supswigb->{_note} . ' bclip=' . $supswigb->{_bclip};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' bclip=' . $supswigb->{_bclip};

    }
    else {
        print("supswigb, bclip, missing bclip,\n");
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

        $supswigb->{_bias} = $bias;
        $supswigb->{_note} = $supswigb->{_note} . ' bias=' . $supswigb->{_bias};
        $supswigb->{_Step} = $supswigb->{_Step} . ' bias=' . $supswigb->{_bias};

    }
    else {
        print("supswigb,missing bias,\n");
    }
}

=head2 sub box_X0_inch


=cut

sub box_X0_inch {

    my ( $self, $xbox ) = @_;
    if ( $xbox ne $empty_string ) {

        $supswigb->{_xbox} = $xbox;
        $supswigb->{_note} = $supswigb->{_note} . ' xbox=' . $supswigb->{_xbox};
        $supswigb->{_Step} = $supswigb->{_Step} . ' xbox=' . $supswigb->{_xbox};

    }
    else {
        print("supswigb,box_X0_inch ,missing  xbox\n");
    }
}

=head2 sub box_Y0_inch


=cut

sub box_Y0_inch {

    my ( $self, $ybox ) = @_;
    if ( $ybox ne $empty_string ) {

        $supswigb->{_ybox} = $ybox;
        $supswigb->{_note} = $supswigb->{_note} . ' ybox=' . $supswigb->{_ybox};
        $supswigb->{_Step} = $supswigb->{_Step} . ' ybox=' . $supswigb->{_ybox};

    }
    else {
        print("supswigb,box_Y0_inch ,missing  ybox\n");
    }
}

=head2 sub box_height_inch


=cut

sub box_height_inch {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $supswigb->{_hbox} = $hbox;
        $supswigb->{_note} = $supswigb->{_note} . ' hbox=' . $supswigb->{_hbox};
        $supswigb->{_Step} = $supswigb->{_Step} . ' hbox=' . $supswigb->{_hbox};

    }
    else {
        print("supswigb,box_height_inch,missing hbox,\n");
    }
}

=head2 sub box_width_inch


=cut

sub box_width_inch {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $supswigb->{_wbox} = $wbox;
        $supswigb->{_note} = $supswigb->{_note} . ' wbox=' . $supswigb->{_wbox};
        $supswigb->{_Step} = $supswigb->{_Step} . ' wbox=' . $supswigb->{_wbox};

    }
    else {
        print("box_width_inch wbox,\n");
    }
}

=head2 sub clip

 define min and max plotting values

=cut

sub clip {

    my ( $self, $clip ) = @_;
    if ( $clip ne $empty_string ) {

        $supswigb->{_clip} = $clip;
        $supswigb->{_note} = $supswigb->{_note} . ' clip=' . $supswigb->{_clip};
        $supswigb->{_Step} = $supswigb->{_Step} . ' clip=' . $supswigb->{_clip};

    }
    else {
        print("supswigb,missing clip,\n");
    }
}

=head2 sub cmap 
 define min and max plotting values

=cut

sub cmap {

    my ( $self, $cmap ) = @_;
    if ( $cmap ne $empty_string ) {

        $supswigb->{_cmap} = $cmap;
        $supswigb->{_note} = $supswigb->{_note} . ' cmap=' . $supswigb->{_cmap};
        $supswigb->{_Step} = $supswigb->{_Step} . ' cmap=' . $supswigb->{_cmap};

    }
    else {
        print("supswigb,cmap, missing cmap,\n");
    }
}

=head2 sub curve 


=cut

sub curve {

    my ( $self, $curve ) = @_;
    if ( $curve ne $empty_string ) {

        $supswigb->{_curve} = $curve;
        $supswigb->{_note} =
          $supswigb->{_note} . ' curve=' . $supswigb->{_curve};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' curve=' . $supswigb->{_curve};

    }
    else {
        print("supswigb,missing curve,\n");
    }
}

=head2 sub curvecolor 


=cut

sub curvecolor {

    my ( $self, $curvecolor ) = @_;
    if ( $curvecolor ne $empty_string ) {

        $supswigb->{_curvecolor} = $curvecolor;
        $supswigb->{_note} =
          $supswigb->{_note} . ' curvecolor=' . $supswigb->{_curvecolor};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' curvecolor=' . $supswigb->{_curvecolor};

    }
    else {
        print("supswigb,missing curvecolor,\n");
    }
}

=head2 sub curvefile 


=cut

sub curvefile {

    my ( $self, $curvefile ) = @_;
    if ( $curvefile ne $empty_string ) {

        $supswigb->{_curvefile} = $curvefile;
        $supswigb->{_note} =
          $supswigb->{_note} . ' curvefile=' . $supswigb->{_curvefile};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' curvefile=' . $supswigb->{_curvefile};

    }
    else {
        print("supswigb,missing curvefile,\n");
    }
}

=head2 sub d1 

 increment in fast dimension
 usually time and equal to dt

=cut

sub d1 {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $supswigb->{_d1}   = $d1;
        $supswigb->{_note} = $supswigb->{_note} . ' d1=' . $supswigb->{_d1};
        $supswigb->{_Step} = $supswigb->{_Step} . ' d1=' . $supswigb->{_d1};

    }
    else {
        print("supswigb, d1, missing d1,\n");
    }
}

=head2 subs d1 and dt

 increment in fast dimension
 usually time and equal to dt 

=cut 

sub dt {

    my ( $self, $d1 ) = @_;

    if ( $d1 ne $empty_string ) {

        $supswigb->{_d1}   = $d1;
        $supswigb->{_note} = $supswigb->{_note} . ' d1=' . $supswigb->{_d1};
        $supswigb->{_Step} = $supswigb->{_Step} . ' d1=' . $supswigb->{_d1};

    }
    else {
        print("supswigb, dt, missing d1,\n");
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

        $supswigb->{_d1num} = $d1num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' d1num=' . $supswigb->{_d1num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' d1num=' . $supswigb->{_d1num};

    }
    else {
        print("supswigb,dt_major_divisions,missing d1num,\n");
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

        $supswigb->{_d2}   = $d2;
        $supswigb->{_note} = $supswigb->{_note} . ' d2=' . $supswigb->{_d2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' d2=' . $supswigb->{_d2};

    }
    else {
        print("supswigb, dx, missing d2,\n");
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

        $supswigb->{_d1num} = $d1num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' d1num=' . $supswigb->{_d1num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' d1num=' . $supswigb->{_d1num};

    }
    else {
        print("supswigb,dy_major_divisions,missing d1num,\n");
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

        $supswigb->{_d1num} = $d1num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' d1num=' . $supswigb->{_d1num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' d1num=' . $supswigb->{_d1num};

    }
    else {
        print("supswigb,missing d1num,\n");
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

        $supswigb->{_d2}   = $d2;
        $supswigb->{_note} = $supswigb->{_note} . ' d2=' . $supswigb->{_d2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' d2=' . $supswigb->{_d2};

    }
    else {
        print("supswigb, d2, missing d2,\n");
    }
}

=head2 subs d2num  dx_major_divisions and x_tick_increment

 numbered tick increments along x axis 
 usually in m and only for display

=cut

sub d2num {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $supswigb->{_d2num} = $d2num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' d2num=' . $supswigb->{_d2num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' d2num=' . $supswigb->{_d2num};

    }
    else {
        print("supswigb,d2num, missing d2num,\n");
    }
}

=head2 sub endian 


=cut

sub endian {

    my ( $self, $endian ) = @_;
    if ( $endian ne $empty_string ) {

        $supswigb->{_endian} = $endian;
        $supswigb->{_note} =
          $supswigb->{_note} . ' endian=' . $supswigb->{_endian};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' endian=' . $supswigb->{_endian};

    }
    else {
        print("supswigb,missing endian,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut

sub f1 {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $supswigb->{_f1}   = $f1;
        $supswigb->{_note} = $supswigb->{_note} . ' f1=' . $supswigb->{_f1};
        $supswigb->{_Step} = $supswigb->{_Step} . ' f1=' . $supswigb->{_f1};

    }
    else {
        print("supswigb, f1, missing f1,\n");
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

        $supswigb->{_f1num} = $f1num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' f1num=' . $supswigb->{_f1num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' f1num=' . $supswigb->{_f1num};

    }
    else {
        print("supswigb,missing f1num,\n");
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

        $supswigb->{_f2}   = $f2;
        $supswigb->{_note} = $supswigb->{_note} . ' f2=' . $supswigb->{_f2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' f2=' . $supswigb->{_f2};

    }
    else {
        print("supswigb, f2, missing f2,\n");
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

        $supswigb->{_f2num} = $f2num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' f2num=' . $supswigb->{_f2num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' f2num=' . $supswigb->{_f2num};

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

        $supswigb->{_f2}   = $f2;
        $supswigb->{_note} = $supswigb->{_note} . ' f2=' . $supswigb->{_f2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' f2=' . $supswigb->{_f2};

    }
    else {
        print("supswigb, first_distance_sample_value, missing f2,\n");
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

        $supswigb->{_f2num} = $f2num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' f2num=' . $supswigb->{_f2num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' f2num=' . $supswigb->{_f2num};

    }
    else {
        print("supswigb,missing first_distance_tick_num,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut 

sub first_time_sample_value {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $supswigb->{_f1}   = $f1;
        $supswigb->{_note} = $supswigb->{_note} . ' f1=' . $supswigb->{_f1};
        $supswigb->{_Step} = $supswigb->{_Step} . ' f1=' . $supswigb->{_f1};

    }
    else {
        print("supswigb, first_time_sample_value, missing f1,\n");
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

        $supswigb->{_f1num} = $f1num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' f1num=' . $supswigb->{_f1num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' f1num=' . $supswigb->{_f1num};

    }
    else {
        print("supswigb, first_time_tick_num, missing first_time_tick_num\n");
    }
}

=head2 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)

=cut

sub first_x {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $supswigb->{_f2}   = $f2;
        $supswigb->{_note} = $supswigb->{_note} . ' f2=' . $supswigb->{_f2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' f2=' . $supswigb->{_f2};

    }
    else {
        print("supswigb, first_x, missing f2,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut 

sub first_y {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $supswigb->{_f1}   = $f1;
        $supswigb->{_note} = $supswigb->{_note} . ' f1=' . $supswigb->{_f1};
        $supswigb->{_Step} = $supswigb->{_Step} . ' f1=' . $supswigb->{_f1};

    }
    else {
        print("supswigb, first_y, missing f1,\n");
    }
}

=head2 sub ftr 


=cut 

sub ftr {

    my ( $self, $ftr ) = @_;
    if ( $ftr ne $empty_string ) {

        $supswigb->{_f1}   = $ftr;
        $supswigb->{_note} = $supswigb->{_note} . 'supswigb' . $supswigb->{_ftr};
        $supswigb->{_Step} = $supswigb->{_Step} . 'supswigb' . $supswigb->{_ftr};

    }
    else {
        print("supswigb, first_y, missing f1,\n");
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

        $supswigb->{_grid1} = $grid1;
        $supswigb->{_note} =
          $supswigb->{_note} . ' grid1=' . $supswigb->{_grid1};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' grid1=' . $supswigb->{_grid1};

    }
    else {
        print("supswigb,missing grid1,\n");
    }
}

=head2 sub grid2 

   A. Sivil 091718
   Adds grid lines above x axis as either a dot, dash or a solid line
   
=cut

sub grid2 {

    my ( $self, $grid2 ) = @_;
    if ( $grid2 ne $empty_string ) {

        $supswigb->{_grid2} = $grid2;
        $supswigb->{_note} =
          $supswigb->{_note} . ' grid2=' . $supswigb->{_grid2};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' grid2=' . $supswigb->{_grid2};

    }
    else {
        print("supswigb,missing grid2,\n");
    }
}

=head2 sub gridcolor 


=cut

sub gridcolor {

    my ( $self, $gridcolor ) = @_;
    if ( $gridcolor ne $empty_string ) {

        $supswigb->{_gridcolor} = $gridcolor;
        $supswigb->{_note} =
          $supswigb->{_note} . ' gridcolor=' . $supswigb->{_gridcolor};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' gridcolor=' . $supswigb->{_gridcolor};

    }
    else {
        print("supswigb,missing gridcolor,\n");
    }
}

=head2 sub hbox 


=cut

sub hbox {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $supswigb->{_hbox} = $hbox;
        $supswigb->{_note} = $supswigb->{_note} . ' hbox=' . $supswigb->{_hbox};
        $supswigb->{_Step} = $supswigb->{_Step} . ' hbox=' . $supswigb->{_hbox};

    }
    else {
        print("supswigb,missing hbox,\n");
    }
}

=head2 sub headerword 


=cut

sub headerword {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigb->{_key}  = $key;
        $supswigb->{_note} = $supswigb->{_note} . ' key=' . $supswigb->{_key};
        $supswigb->{_Step} = $supswigb->{_Step} . ' key=' . $supswigb->{_key};

    }
    else {
        print("supswigb, headerword, missing key,\n");
    }
}

=head2 sub header_word 


=cut

sub header_word {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigb->{_key}  = $key;
        $supswigb->{_note} = $supswigb->{_note} . ' key=' . $supswigb->{_key};
        $supswigb->{_Step} = $supswigb->{_Step} . ' key=' . $supswigb->{_key};

    }
    else {
        print("supswigb, header_word, missing key,\n");
    }
}

=head2 sub hiclip 


=cut

sub hiclip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigb->{_key}  = $key;
        $supswigb->{_note} = $supswigb->{_note} . ' bclip=' . $supswigb->{_key};
        $supswigb->{_Step} = $supswigb->{_Step} . ' bclip=' . $supswigb->{_key};

    }
    else {
        print("supswigb, hiclip, missing key,\n");
    }
}

=head2 sub hi_clip 


=cut

sub hi_clip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigb->{_key}  = $key;
        $supswigb->{_note} = $supswigb->{_note} . ' bclip=' . $supswigb->{_key};
        $supswigb->{_Step} = $supswigb->{_Step} . ' bclip=' . $supswigb->{_key};

    }
    else {
        print("supswigb, hi_clip, missing key,\n");
    }
}

=head2 sub interp 


=cut

sub interp {

    my ( $self, $interp ) = @_;
    if ( $interp ne $empty_string ) {

        $supswigb->{_interp} = $interp;
        $supswigb->{_note} =
          $supswigb->{_note} . ' interp=' . $supswigb->{_interp};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' interp=' . $supswigb->{_interp};

    }
    else {
        print("supswigb,missing interp,\n");
    }
}

=head2 sub key 


=cut

sub key {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigb->{_key}  = $key;
        $supswigb->{_note} = $supswigb->{_note} . ' key=' . $supswigb->{_key};
        $supswigb->{_Step} = $supswigb->{_Step} . ' key=' . $supswigb->{_key};

    }
    else {
        print("supswigb, key, missing key,\n");
    }
}

=head2 sub label1 

=cut

sub label1 {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $supswigb->{_label1} = $label1;
        $supswigb->{_note} =
          $supswigb->{_note} . ' label1=' . $supswigb->{_label1};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' label1=' . $supswigb->{_label1};

    }
    else {
        print("supswigb,missing label1,\n");
    }
}

=head2 sub label2 

   A. Sivil 091718
   Adds label above x axis in top-right corner

=cut

sub label2 {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $supswigb->{_label2} = $label2;
        $supswigb->{_note} =
          $supswigb->{_note} . ' label2=' . $supswigb->{_label2};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' label2=' . $supswigb->{_label2};

    }
    else {
        print("supswigb,missing label2,\n");
    }
}

=head2 sub labelcolor 


=cut

sub labelcolor {

    my ( $self, $labelcolor ) = @_;
    if ( $labelcolor ne $empty_string ) {

        $supswigb->{_labelcolor} = $labelcolor;
        $supswigb->{_note} =
          $supswigb->{_note} . ' labelcolor=' . $supswigb->{_labelcolor};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' labelcolor=' . $supswigb->{_labelcolor};

    }
    else {
        print("supswigb,missing labelcolor,\n");
    }
}

=head2 sub labelfont 

   A. Sivil 091718
   Changes font for label

=cut

sub labelfont {

    my ( $self, $labelfont ) = @_;
    if ( $labelfont ne $empty_string ) {

        $supswigb->{_labelfont} = $labelfont;
        $supswigb->{_note} =
          $supswigb->{_note} . ' labelfont=' . $supswigb->{_labelfont};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' labelfont=' . $supswigb->{_labelfont};

    }
    else {
        print("supswigb,missing labelfont,\n");
    }
}

=head2 sub lo_clip 


=cut

sub lo_clip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigb->{_key}  = $key;
        $supswigb->{_note} = $supswigb->{_note} . ' wclip=' . $supswigb->{_key};
        $supswigb->{_Step} = $supswigb->{_Step} . ' wclip=' . $supswigb->{_key};

    }
    else {
        print("supswigb, lo_clip, missing key,\n");
    }
}

=head2 sub loclip 


=cut

sub loclip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigb->{_key}  = $key;
        $supswigb->{_note} = $supswigb->{_note} . ' wclip=' . $supswigb->{_key};
        $supswigb->{_Step} = $supswigb->{_Step} . ' wclip=' . $supswigb->{_key};

    }
    else {
        print("supswigb, loclip, missing key,\n");
    }
}

=head2 sub mpicks 

G. Bonot 091718
Input a file name to which your mouse clicks are to be saved. No visible change observed in xwigb

=cut

sub mpicks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        $supswigb->{_mpicks} = $mpicks;
        $supswigb->{_note} =
          $supswigb->{_note} . ' mpicks=' . $supswigb->{_mpicks};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' mpicks=' . $supswigb->{_mpicks};

    }
    else {
        print("supswigb,missing mpicks,\n");
    }
}

=head2 sub n1 

=cut

sub n1 {

    my ( $self, $n1 ) = @_;
    if ( $n1 ne $empty_string ) {

        $supswigb->{_n1}   = $n1;
        $supswigb->{_note} = $supswigb->{_note} . ' n1=' . $supswigb->{_n1};
        $supswigb->{_Step} = $supswigb->{_Step} . ' n1=' . $supswigb->{_n1};

    }
    else {
        print("supswigb,missing n1,\n");
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

        $supswigb->{_n1tic} = $n1tic;
        $supswigb->{_note} =
          $supswigb->{_note} . ' n1tic=' . $supswigb->{_n1tic};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' n1tic=' . $supswigb->{_n1tic};

    }
    else {
        print("supswigb,missing n1tic,\n");
    }
}

=head2 sub n2 


=cut

sub n2 {

    my ( $self, $n2 ) = @_;
    if ( $n2 ne $empty_string ) {

        $supswigb->{_n2}   = $n2;
        $supswigb->{_note} = $supswigb->{_note} . ' n2=' . $supswigb->{_n2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' n2=' . $supswigb->{_n2};

    }
    else {
        print("supswigb, n2, missing n2,\n");
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

        $supswigb->{_n2tic} = $n2tic;
        $supswigb->{_note} =
          $supswigb->{_note} . ' n2tic=' . $supswigb->{_n2tic};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' n2tic=' . $supswigb->{_n2tic};

    }
    else {
        print("supswigb,missing n2tic,\n");
    }
}

=head2 sub nbpi   

=cut

sub nbpi {

    my ( $self, $nbpi) = @_;
    
    if ( $nbpi eq $empty_string ) {

        $supswigb->{_nbpi} = $nbpi;
        $supswigb->{_note} =
          $supswigb->{_note} . ' nbpi=' . $supswigb->{_nbpi};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' nbpi=' . $supswigb->{_nbpi};

    }
    else {
        print("supswigb,missing nbpi,\n");
    }
}

=head2 sub npair 


=cut

sub npair {

    my ( $self, $npair ) = @_;
    if ( $npair ne $empty_string ) {

        $supswigb->{_npair} = $npair;
        $supswigb->{_note} =
          $supswigb->{_note} . ' npair=' . $supswigb->{_npair};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' npair=' . $supswigb->{_npair};

    }
    else {
        print("supswigb,missing npair,\n");
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

        $supswigb->{_n2tic} = $n2tic;
        $supswigb->{_note} =
          $supswigb->{_note} . ' n2tic=' . $supswigb->{_n2tic};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' n2tic=' . $supswigb->{_n2tic};

    }
    else {
        print("supswigb,num_minor_ticks_betw_distance_ticks, missing n2tic,\n");
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

        $supswigb->{_n1tic} = $n1tic;
        $supswigb->{_note} =
          $supswigb->{_note} . ' n1tic=' . $supswigb->{_n1tic};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' n1tic=' . $supswigb->{_n1tic};

    }
    else {
        print("supswigb, num_minor_ticks_betw_time_ticks, missing n1tic,\n");
    }
}

=head2 sub orientation 

  seismic style of plotting (time axis pointing down)
  versus mathematical ( y axis up)

=cut

sub orientation {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $supswigb->{_style} = $style;
        $supswigb->{_note} =
          $supswigb->{_note} . ' style=' . $supswigb->{_style};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' style=' . $supswigb->{_style};

    }
    else {
        print("supswigb, orientation, missing style,\n");
    }
}

=head2 sub perc 


=cut

sub perc {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $supswigb->{_perc} = $perc;
        $supswigb->{_note} = $supswigb->{_note} . ' perc=' . $supswigb->{_perc};
        $supswigb->{_Step} = $supswigb->{_Step} . ' perc=' . $supswigb->{_perc};

    }
    else {
        print("supswigb,missing perc,\n");
    }
}

=head2 sub percent 


=cut

sub percent {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $supswigb->{_perc} = $perc;
        $supswigb->{_note} = $supswigb->{_note} . ' perc=' . $supswigb->{_perc};
        $supswigb->{_Step} = $supswigb->{_Step} . ' perc=' . $supswigb->{_perc};

    }
    else {
        print("supswigb,percent, missing perc,\n");
    }
}

=head2 sub picks

 automatically generates a pick file
 
=cut

sub picks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        # print("supswigb, picks, file_name is: $mpicks\n");

        $supswigb->{_mpicks} = $mpicks;
        $supswigb->{_note} =
          $supswigb->{_note} . ' mpicks=' . $supswigb->{_mpicks};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' mpicks=' . $supswigb->{_mpicks};

    }
    else {
        print("supswigb,picks, missing mpicks,\n");
    }
}

=head2 sub plotfile 


=cut

sub plotfile {

    my ( $self, $plotfile ) = @_;
    if ( $plotfile ne $empty_string ) {

        $supswigb->{_plotfile} = $plotfile;
        $supswigb->{_note} =
          $supswigb->{_note} . ' plotfile=' . $supswigb->{_plotfile};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' plotfile=' . $supswigb->{_plotfile};

    }
    else {
        print("supswigb,missing plotfile,\n");
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

        $supswigb->{_va}   = $va;
        $supswigb->{_note} = $supswigb->{_note} . ' va=' . $supswigb->{_va};
        $supswigb->{_Step} = $supswigb->{_Step} . ' va=' . $supswigb->{_va};

    }
    else {
        print("supswigb,shading, missing va\n");
    }
}

=head2 sub style 

  seismic style of plotting (time axis pointing down)
  versus mathematical ( y axis up)

=cut

sub style {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $supswigb->{_style} = $style;
        $supswigb->{_note} =
          $supswigb->{_note} . ' style=' . $supswigb->{_style};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' style=' . $supswigb->{_style};

    }
    else {
        print("supswigb, style, missing style,\n");
    }
}

=head2 sub title 

 allows for a default graph title ($on) or
 a user-defined title

=cut

sub title {

    my ( $self, $title ) = @_;
    if ( $title ne $empty_string ) {

        $supswigb->{_title} = $title;
        $supswigb->{_note} =
          $supswigb->{_note} . ' title=' . $supswigb->{_title};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' title=' . $supswigb->{_title};

    }
    else {
        print("supswigb,missing title,\n");
    }
}

=head2 sub titlecolor 

 allows for a default graph title ($on) or
 a user-defined title

=cut

sub titlecolor {

    my ( $self, $titlecolor ) = @_;
    if ( $titlecolor ne $empty_string ) {

        $supswigb->{_titlecolor} = $titlecolor;
        $supswigb->{_note} =
          $supswigb->{_note} . ' titlecolor=' . $supswigb->{_titlecolor};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' titlecolor=' . $supswigb->{_titlecolor};

    }
    else {
        print("supswigb,missing titlecolor,\n");
    }
}

=head2 sub titlefont 


=cut

sub titlefont {

    my ( $self, $titlefont ) = @_;
    if ( $titlefont ne $empty_string ) {

        $supswigb->{_titlefont} = $titlefont;
        $supswigb->{_note} =
          $supswigb->{_note} . ' titlefont=' . $supswigb->{_titlefont};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' titlefont=' . $supswigb->{_titlefont};

    }
    else {
        print("supswigb,missing titlefont,\n");
    }
}

=head2 sub titlesize 


=cut

sub titlesize {

    my ( $self, $titlesize ) = @_;
    if ( $titlesize ne $empty_string ) {

        $supswigb->{_titlesize} = $titlesize;
        $supswigb->{_note} =
          $supswigb->{_note} . ' titlesize=' . $supswigb->{_titlesize};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' titlesize=' . $supswigb->{_titlesize};

    }
    else {
        print("supswigb,missing titlesize,\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ( $tmpdir ne $empty_string ) {

        $supswigb->{_tmpdir} = $tmpdir;
        $supswigb->{_note} =
          $supswigb->{_note} . ' tmpdir=' . $supswigb->{_tmpdir};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' tmpdir=' . $supswigb->{_tmpdir};

    }
    else {
        print("supswigb, tmpdir, missing tmpdir,\n");
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

        $supswigb->{_d2}   = $d2;
        $supswigb->{_note} = $supswigb->{_note} . ' d2=' . $supswigb->{_d2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' d2=' . $supswigb->{_d2};

    }
    else {
        print("supswigb, trace_inc, missing d2,\n");
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

        $supswigb->{_d2}   = $d2;
        $supswigb->{_note} = $supswigb->{_note} . ' d2=' . $supswigb->{_d2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' d2=' . $supswigb->{_d2};

    }
    else {
        print("supswigb, trace_inc_m, missing d2,\n");
    }
}

=head2 sub tend_s 

minimum value of yaxis (time usually) in seconds

=cut

sub tend_s {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $supswigb->{_x1end} = $x1end;
        $supswigb->{_note} =
          $supswigb->{_note} . ' x1end=' . $supswigb->{_x1end};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' x1end=' . $supswigb->{_x1end};

    }
    else {
        print("supswigb,tend_s, missing x1end,\n");
    }
}

=head2 sub tstart_s 

  minimum value of yaxis (time usually) in seconds

=cut

sub tstart_s {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $supswigb->{_x1beg} = $x1beg;
        $supswigb->{_note} =
          $supswigb->{_note} . ' x1beg=' . $supswigb->{_x1beg};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' x1beg=' . $supswigb->{_x1beg};

    }
    else {
        print("supswigb,tstart_s, missing x1beg,\n");
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

        $supswigb->{_va}   = $va;
        $supswigb->{_note} = $supswigb->{_note} . ' va=' . $supswigb->{_va};
        $supswigb->{_Step} = $supswigb->{_Step} . ' va=' . $supswigb->{_va};

    }
    else {
        print("supswigb,missing va,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $supswigb->{_verbose} = $verbose;
        $supswigb->{_note} =
          $supswigb->{_note} . ' verbose=' . $supswigb->{_verbose};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' verbose=' . $supswigb->{_verbose};

    }
    else {
        print("supswigb, verbose, missing verbose,\n");
    }
}

=head2 sub wbox 


=cut

sub wbox {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $supswigb->{_wbox} = $wbox;
        $supswigb->{_note} = $supswigb->{_note} . ' wbox=' . $supswigb->{_wbox};
        $supswigb->{_Step} = $supswigb->{_Step} . ' wbox=' . $supswigb->{_wbox};

    }
    else {
        print("supswigb,missing wbox,\n");
    }
}

=head2 sub wclip 


=cut

sub wclip {

    my ( $self, $wclip ) = @_;
    if ( $wclip ne $empty_string ) {

        $supswigb->{_wclip} = $wclip;
        $supswigb->{_note} =
          $supswigb->{_note} . ' wclip=' . $supswigb->{_wclip};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' wclip=' . $supswigb->{_wclip};

    }
    else {
        print("supswigb, wclip, missing wclip,\n");
    }
}

=head2 sub wigclip 


=cut

sub wigclip {

    my ( $self, $wigclip ) = @_;
    if ( $wigclip ne $empty_string ) {

        $supswigb->{_wigclip} = $wigclip;
        $supswigb->{_note} =
          $supswigb->{_note} . ' wigclip=' . $supswigb->{_wigclip};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' wigclip=' . $supswigb->{_wigclip};

    }
    else {
        print("supswigb,missing wigclip,\n");
    }
}

=head2 sub windowtitle 


=cut

sub windowtitle {

    my ( $self, $windowtitle ) = @_;
    if ( $windowtitle ne $empty_string ) {

        $supswigb->{_windowtitle} = $windowtitle;
        $supswigb->{_note} =
          $supswigb->{_note} . ' windowtitle=' . $supswigb->{_windowtitle};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' windowtitle=' . $supswigb->{_windowtitle};

    }
    else {
        print("supswigb,missing windowtitle,\n");
    }
}

=head2 sub wt 


=cut

sub wt {

    my ( $self, $wt ) = @_;
    if ( $wt ne $empty_string ) {

        $supswigb->{_wt}   = $wt;
        $supswigb->{_note} = $supswigb->{_note} . ' wt=' . $supswigb->{_wt};
        $supswigb->{_Step} = $supswigb->{_Step} . ' wt=' . $supswigb->{_wt};

    }
    else {
        print("supswigb,missing wt,\n");
    }
}

=head2 sub x1beg 

  minimum value of yaxis (time usually) in seconds

=cut

sub x1beg {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $supswigb->{_x1beg} = $x1beg;
        $supswigb->{_note} =
          $supswigb->{_note} . ' x1beg=' . $supswigb->{_x1beg};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' x1beg=' . $supswigb->{_x1beg};

    }
    else {
        print("supswigb,missing x1beg,\n");
    }
}

=head2 sub x1end 

minimum value of yaxis (time usually) in seconds

=cut

sub x1end {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $supswigb->{_x1end} = $x1end;
        $supswigb->{_note} =
          $supswigb->{_note} . ' x1end=' . $supswigb->{_x1end};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' x1end=' . $supswigb->{_x1end};

    }
    else {
        print("supswigb,missing x1end,\n");
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

        $supswigb->{_x2}   = $x2;
        $supswigb->{_note} = $supswigb->{_note} . ' x2=' . $supswigb->{_x2};
        $supswigb->{_Step} = $supswigb->{_Step} . ' x2=' . $supswigb->{_x2};

    }
    else {
        print("supswigb,missing x2,\n");
    }
}

=head2 sub x2beg 

 minimum value of x axis (time usually) in seconds
 First value shown on x axis GTL18
 

=cut

sub x2beg {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $supswigb->{_x2beg} = $x2beg;
        $supswigb->{_note} =
          $supswigb->{_note} . ' x2beg=' . $supswigb->{_x2beg};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' x2beg=' . $supswigb->{_x2beg};

    }
    else {
        print("supswigb,missing x2beg,\n");
    }
}

=head2 sub x2end 
  
  max value of xaxis (distance or traces, usually) in seconds
  Last value for data shown on x axis GTL18

=cut

sub x2end {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $supswigb->{_x2end} = $x2end;
        $supswigb->{_note} =
          $supswigb->{_note} . ' x2end=' . $supswigb->{_x2end};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' x2end=' . $supswigb->{_x2end};

    }
    else {
        print("supswigb,missing x2end,\n");
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

        $supswigb->{_xbox} = $xbox;
        $supswigb->{_note} = $supswigb->{_note} . ' xbox=' . $supswigb->{_xbox};
        $supswigb->{_Step} = $supswigb->{_Step} . ' xbox=' . $supswigb->{_xbox};

    }
    else {
        print("supswigb,missing xbox,\n");
    }
}

=head2 sub xcur 

how many adjacent wiggles can be overploted

=cut

sub xcur {

    my ( $self, $xcur ) = @_;
    if ( $xcur ne $empty_string ) {

        $supswigb->{_xcur} = $xcur;
        $supswigb->{_note} = $supswigb->{_note} . ' xcur=' . $supswigb->{_xcur};
        $supswigb->{_Step} = $supswigb->{_Step} . ' xcur=' . $supswigb->{_xcur};

    }
    else {
        print("supswigb,missing xcur,\n");
    }
}

=head2 sub xend_m 

 
=cut

sub xend_m {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $supswigb->{_x2end} = $x2end;
        $supswigb->{_note} =
          $supswigb->{_note} . ' x2end=' . $supswigb->{_x2end};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' x2end=' . $supswigb->{_x2end};

    }
    else {
        print("supswigb,xend_m, missing x2end,\n");
    }
}

=head2 subs xlabel or label2 ylabel or label1


=cut

sub xlabel {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $supswigb->{_label2} = $label2;
        $supswigb->{_note} =
          $supswigb->{_note} . ' label2=' . $supswigb->{_label2};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' label2=' . $supswigb->{_label2};

    }
    else {
        print("supswigb, xlabelmissing label2,\n");
    }
}

=head2 sub xstart_m 

 
=cut

sub xstart_m {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $supswigb->{_x2beg} = $x2beg;
        $supswigb->{_note} =
          $supswigb->{_note} . ' x2beg=' . $supswigb->{_x2beg};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' x2beg=' . $supswigb->{_x2beg};

    }
    else {
        print("supswigb,xstart_m, missing x2beg,\n");
    }
}

=head2 subs d2num  dx_major_divisions and x_tick_increment

 numbered tick increments along x axis 
 usually in m and only for display

=cut

sub x_tick_increment {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $supswigb->{_d2num} = $d2num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' d2num=' . $supswigb->{_d2num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' d2num=' . $supswigb->{_d2num};

    }
    else {
        print("supswigb,d2num, missing d2num,\n");
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

        $supswigb->{_ybox} = $ybox;
        $supswigb->{_note} = $supswigb->{_note} . ' ybox=' . $supswigb->{_ybox};
        $supswigb->{_Step} = $supswigb->{_Step} . ' ybox=' . $supswigb->{_ybox};

    }
    else {
        print("supswigb,missing ybox,\n");
    }
}

=head2 subs ylabel or label1


=cut

sub ylabel {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $supswigb->{_label1} = $label1;
        $supswigb->{_note} =
          $supswigb->{_note} . ' label1=' . $supswigb->{_label1};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' label1=' . $supswigb->{_label1};

    }
    else {
        print("supswigb, ylabel, missing label1,\n");
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

        $supswigb->{_d1num} = $d1num;
        $supswigb->{_note} =
          $supswigb->{_note} . ' d1num=' . $supswigb->{_d1num};
        $supswigb->{_Step} =
          $supswigb->{_Step} . ' d1num=' . $supswigb->{_d1num};

    }
    else {
        print("supswigb,y_tick_increment,missing d1num,\n");
    }
}


=head2 sub axescolor 


=cut

 sub axescolor {

	my ( $self,$axescolor )		= @_;
	if ( $axescolor ne $empty_string ) {

		$supswigb->{_axescolor}		= $axescolor;
		$supswigb->{_note}		= $supswigb->{_note}.' axescolor='.$supswigb->{_axescolor};
		$supswigb->{_Step}		= $supswigb->{_Step}.' axescolor='.$supswigb->{_axescolor};

	} else { 
		print("pswigb, axescolor, missing axescolor,\n");
	 }
 }


=head2 sub axeswidth 


=cut

 sub axeswidth {

	my ( $self,$axeswidth )		= @_;
	if ( $axeswidth ne $empty_string ) {

		$supswigb->{_axeswidth}		= $axeswidth;
		$supswigb->{_note}		= $supswigb->{_note}.' axeswidth='.$supswigb->{_axeswidth};
		$supswigb->{_Step}		= $supswigb->{_Step}.' axeswidth='.$supswigb->{_axeswidth};

	} else { 
		print("pswigb, axeswidth, missing axeswidth,\n");
	 }
 }





=head2 sub curvedash 


=cut

 sub curvedash {

	my ( $self,$curvedash )		= @_;
	if ( $curvedash ne $empty_string ) {

		$supswigb->{_curvedash}		= $curvedash;
		$supswigb->{_note}		= $supswigb->{_note}.' curvedash='.$supswigb->{_curvedash};
		$supswigb->{_Step}		= $supswigb->{_Step}.' curvedash='.$supswigb->{_curvedash};

	} else { 
		print("pswigb, curvedash, missing curvedash,\n");
	 }
 }





=head2 sub curvewidth 


=cut

 sub curvewidth {

	my ( $self,$curvewidth )		= @_;
	if ( $curvewidth ne $empty_string ) {

		$supswigb->{_curvewidth}		= $curvewidth;
		$supswigb->{_note}		= $supswigb->{_note}.' curvewidth='.$supswigb->{_curvewidth};
		$supswigb->{_Step}		= $supswigb->{_Step}.' curvewidth='.$supswigb->{_curvewidth};

	} else { 
		print("pswigb, curvewidth, missing curvewidth,\n");
	 }
 }


#


=head2 sub gridwidth 


=cut

 sub gridwidth {

	my ( $self,$gridwidth )		= @_;
	if ( $gridwidth ne $empty_string ) {

		$supswigb->{_gridwidth}		= $gridwidth;
		$supswigb->{_note}		= $supswigb->{_note}.' gridwidth='.$supswigb->{_gridwidth};
		$supswigb->{_Step}		= $supswigb->{_Step}.' gridwidth='.$supswigb->{_gridwidth};

	} else { 
		print("pswigb, gridwidth, missing gridwidth,\n");
	 }
 }





=head2 sub labelsize 


=cut

 sub labelsize {

	my ( $self,$labelsize )		= @_;
	if ( $labelsize ne $empty_string ) {

		$supswigb->{_labelsize}		= $labelsize;
		$supswigb->{_note}		= $supswigb->{_note}.' labelsize='.$supswigb->{_labelsize};
		$supswigb->{_Step}		= $supswigb->{_Step}.' labelsize='.$supswigb->{_labelsize};

	} else { 
		print("pswigb, labelsize, missing labelsize,\n");
	 }
 }





=head2 sub ticwidth 


=cut

 sub ticwidth {

	my ( $self,$ticwidth )		= @_;
	if ( $ticwidth ne $empty_string ) {

		$supswigb->{_ticwidth}		= $ticwidth;
		$supswigb->{_note}		= $supswigb->{_note}.' ticwidth='.$supswigb->{_ticwidth};
		$supswigb->{_Step}		= $supswigb->{_Step}.' ticwidth='.$supswigb->{_ticwidth};

	} else { 
		print("pswigb, ticwidth, missing ticwidth,\n");
	 }
 }



=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 61;

    return ($max_index);
}

1;
