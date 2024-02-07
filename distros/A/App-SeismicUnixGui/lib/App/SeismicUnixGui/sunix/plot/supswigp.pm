 package App::SeismicUnixGui::sunix::plot::supswigp;

=head1 DOCUMENTATION

=head2 SYNOPSIS

PERL PROGRAM NAME:  supswigp - PostScript Bit-mapped WIGgle plot of a segy data set	
AUTHOR: Juan Lorenzo (Perl module only)
DATE:   
DESCRIPTION:
Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

 supswigp - PostScript Bit-mapped WIGgle plot of a segy data set	

 supswigp <stdin [optional parameters] >				

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
	   Jack Cohen and John Stockwell (supswigp, etc.)
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
	
	
supswigp inherits all the properties of PSWIGP

PSWIGP - PostScript WIGgle-trace plot of f(x1,x2) via Polygons	
 Best for few traces.  Use PSWIGB (Bitmap version) for many traces.	

 pswigp n1= [optional parameters] <binaryfile >postscriptfile		

 Required Parameters:							
 n1                     number of samples in 1st (fast) dimension	

 Optional Parameters:							
 d1=1.0                 sampling interval in 1st dimension		
 f1=0.0                 first sample in 1st dimension			
 n2=all                 number of samples in 2| ...nd (slow) dimension	
 d2=1.0                 sampling interval in 2nd dimension		
 f2=0.0                 first sample in 2nd dimension			
 x2=f2,f2+d2,...        array of sampled values in 2nd dimension	
 bias=0.0               data value corresponding to location along axis 2
 perc=100.0             percentile for determining clip		
 clip=(perc percentile) data values < bias+clip and > bias-clip are clipped
 xcur=1.0               wiggle excursion in traces corresponding to clip
 fill=1			=0 for no fill;				
				>0 for pos. fill;			
				<0 for neg. fill			
                               =2 for pos. fill solid, neg. fill grey  
                               =-2for neg. fill solid, pos. fill grey  
                       SHADING: 2<=abs(fill)<=5  2=lightgrey 5=black   
 linewidth=1.0         linewidth in points (0.0 for thinest visible line)
 tracecolor=black       color of traces; should contrast with background
 backcolor=none         color of background; none means no background	
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
 gridcolor=black        color of grid			| ...		
 axeswidth=1            width (in points) of axes			
 ticwidth=axeswidth     width (in points) of tic marks		
 gridwidth=axeswidth    width (in points) of grid lines		
 style=seismic          normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)	

 curve=curve1,curve2,...  file(s) containing points to draw curve(s)   
 npair=n1,n2,n2,...            number(s) of pairs in each file         
 curvecolor=black,..    color of curve(s)                              
 curvewidth=axeswidth   width (in points) of curve(s)                  
 curvedash=0            solid curve(s), dash indices 1,...,11 produce  
                        curve(s) with various dash styles              

 Note:  linewidth=0.0 produces the thinest possible line on the output.	
 device.  Thus the result is device-dependent, put generally looks the	
 best for seismic traces.						

 The curve file is an ascii file with the points specified as x1 x2 pairs,
 one pair to a line.  A "vector" of curve files and curve colors may 
 be specified as curvefile=file1,file2,etc. and similarly		
 curvecolor=color1,color2,etc, and the number | ...of pairs of values	
 in each file as npair=npair1,npair2,... .                             

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

VERSION = '0.0.2'; 02.09.23 Only redirection allowed.

=cut


use Moose;
our $VERSION = '0.0.2';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

	my $get					= L_SU_global_constants->new();

	my $var				= $get->var();
	my $empty_string    	= $var->{_empty_string};


	my $supswigp		= {
    _absclip                                   => '',
    _bias                                      => '',
    _box_width_inch                            => '',
    _box_height_inch                           => '',
    _box_X0_inch                               => '',
    _box_Y0_inch                               => '',
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

    $supswigp->{_Step} = 'supswigp' . $supswigp->{_Step};
    return ( $supswigp->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $supswigp->{_note} = 'supswigp' . $supswigp->{_note};
    return ( $supswigp->{_note} );

}

=head2 sub clear

 50 + 43 personalized  params
clear global variables from the memory

=cut

sub clear {

    $supswigp->{_d1}                                        = '';
    $supswigp->{_d2}                                        = '';
    $supswigp->{_f1}                                        = '';
    $supswigp->{_f2}                                        = '';
    $supswigp->{_key}                                       = '';
    $supswigp->{_n2}                                        = '';
    $supswigp->{_style}                                     = '';
    $supswigp->{_tmpdir}                                    = '';
    $supswigp->{_absclip}                                   = '';
    $supswigp->{_bias}                                      = '';
    $supswigp->{_box_width_inch}                                 = '';
    $supswigp->{_box_height_inch}                                = '';
    $supswigp->{_box_X0_inch}                                    = '';
    $supswigp->{_box_Y0_inch}                                    = '';
    $supswigp->{_clip}                                      = '';
    $supswigp->{_cmap}                                      = '';
    $supswigp->{_curve}                                     = '';
    $supswigp->{_curvecolor}                                = '';
    $supswigp->{_curvefile}                                 = '';
    $supswigp->{_ftr}                                       = '';
    $supswigp->{_d1}                                        = '';
    $supswigp->{_d1num}                                     = '';
    $supswigp->{_dt}                                        = '';
    $supswigp->{_d2}                                        = '';
    $supswigp->{_dx}                                        = '';
    $supswigp->{_dx_major_divisions}                        = '';
    $supswigp->{_dy_major_divisions}                        = '';
    $supswigp->{_dt_major_divisions}                        = '';
    $supswigp->{_d2num}                                     = '';
    $supswigp->{_dtr}                                       = '';
    $supswigp->{_endian}                                    = '';
    $supswigp->{_f1num}                                     = '';
    $supswigp->{_f1}                                        = '';
    $supswigp->{_first_y}                                   = '';
    $supswigp->{_first_time_sample_value}                   = '';
    $supswigp->{_f2}                                        = '';
    $supswigp->{_first_x}                                   = '';
    $supswigp->{_first_distance_sample_value}               = '';
    $supswigp->{_first_distance_tick_num}                   = '';
    $supswigp->{_f1num}                                     = '';
    $supswigp->{_first_time_tick_num}                       = '';
    $supswigp->{_f2num}                                     = '';
    $supswigp->{_grid1}                                     = '';
    $supswigp->{_grid2}                                     = '';
    $supswigp->{_gridcolor}                                 = '';
    $supswigp->{_hbox}                                      = '';
    $supswigp->{_headerword}                                = '';
    $supswigp->{_hiclip}                                    = '';
    $supswigp->{_interp}                                    = '';
    $supswigp->{_key}                                       = '';
    $supswigp->{_label2}                                    = '';
    $supswigp->{_labelfont}                                 = '';
    $supswigp->{_labelcolor}                                = '';
    $supswigp->{_label1}                                    = '';
    $supswigp->{_label2}                                    = '';
    $supswigp->{_loclip}                                    = '';
    $supswigp->{_mpicks}                                    = '';
    $supswigp->{_n1}                                        = '';
    $supswigp->{_n1tic}                                     = '';
    $supswigp->{_num_minor_ticks_betw_major_time_ticks}     = '';
    $supswigp->{_n2}                                        = '';
    $supswigp->{_n2tic}                                     = '';
    $supswigp->{_npair}                                     = '';
    $supswigp->{_num_minor_ticks_betw_major_distance_ticks} = '';
    $supswigp->{_percent}                                   = '';
    $supswigp->{_plotfile}                                  = '';
    $supswigp->{_orientation}                               = '';
    $supswigp->{_perc}                                      = '';
    $supswigp->{_picks}                                     = '';
    $supswigp->{_shading}                                   = '';
    $supswigp->{_style}                                     = '';
    $supswigp->{_tend_s}                                    = '';
    $supswigp->{_tstart_s}                                  = '';
    $supswigp->{_tmpdir}                                    = '';
    $supswigp->{_trace_inc}                                 = '';
    $supswigp->{_trace_inc_m}                               = '';
    $supswigp->{_title}                                     = '';
    $supswigp->{_titlefont}                                 = '';
    $supswigp->{_titlecolor}                                = '';
    $supswigp->{_va}                                        = '';
    $supswigp->{_verbose}                                   = '';
    $supswigp->{_wbox}                                      = '';
    $supswigp->{_wigclip}                                   = '';
    $supswigp->{_wt}                                        = '';
    $supswigp->{_windowtitle}                               = '';
    $supswigp->{_x2beg}                                     = '';
    $supswigp->{_xstart_m}                                  = '';
    $supswigp->{_x2end}                                     = '';
    $supswigp->{_xend_m}                                    = '';
    $supswigp->{_xcur}                                      = '';
    $supswigp->{_x2}                                        = '';
    $supswigp->{_x1beg}                                     = '';
    $supswigp->{_xbox}                                      = '';
    $supswigp->{_x1end}                                     = '';
    $supswigp->{_xlabel}                                    = '';
    $supswigp->{_x_tick_increment}                          = '';
    $supswigp->{_xcur}                                      = '';
    $supswigp->{_ylabel}                                    = '';
    $supswigp->{_y_tick_increment}                          = '';
    $supswigp->{_ybox}                                      = '';
    $supswigp->{_verbose}                                   = '';
    $supswigp->{_Step}                                      = '';
    $supswigp->{_note}                                      = '';
}

=head2 sub absclip 

 define min and max plotting values
 define min and max plotting values
 
=cut

sub absclip {

    my ( $self, $absclip ) = @_;
    if ( $absclip ne $empty_string ) {

        $supswigp->{_absclip} = $absclip;
        $supswigp->{_note} =
          $supswigp->{_note} . ' clip=' . $supswigp->{_absclip};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' clip=' . $supswigp->{_absclip};

    }
    else {
        print("supswigp,missing absclip,\n");
    }
}

=head2 sub bclip 


=cut

sub bclip {

    my ( $self, $bclip ) = @_;
    if ( $bclip ne $empty_string ) {

        $supswigp->{_bclip} = $bclip;
        $supswigp->{_note} =
          $supswigp->{_note} . ' bclip=' . $supswigp->{_bclip};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' bclip=' . $supswigp->{_bclip};

    }
    else {
        print("supswigp, bclip, missing bclip,\n");
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

        $supswigp->{_bias} = $bias;
        $supswigp->{_note} = $supswigp->{_note} . ' bias=' . $supswigp->{_bias};
        $supswigp->{_Step} = $supswigp->{_Step} . ' bias=' . $supswigp->{_bias};

    }
    else {
        print("supswigp,missing bias,\n");
    }
}

=head2 sub box_X0_inch


=cut

sub box_X0_inch {

    my ( $self, $xbox ) = @_;
    if ( $xbox ne $empty_string ) {

        $supswigp->{_xbox} = $xbox;
        $supswigp->{_note} = $supswigp->{_note} . ' xbox=' . $supswigp->{_xbox};
        $supswigp->{_Step} = $supswigp->{_Step} . ' xbox=' . $supswigp->{_xbox};

    }
    else {
        print("supswigp,box_X0_inch ,missing  xbox\n");
    }
}

=head2 sub box_Y0_inch


=cut

sub box_Y0_inch {

    my ( $self, $ybox ) = @_;
    if ( $ybox ne $empty_string ) {

        $supswigp->{_ybox} = $ybox;
        $supswigp->{_note} = $supswigp->{_note} . ' ybox=' . $supswigp->{_ybox};
        $supswigp->{_Step} = $supswigp->{_Step} . ' ybox=' . $supswigp->{_ybox};

    }
    else {
        print("supswigp,box_Y0_inch ,missing  ybox\n");
    }
}

=head2 sub box_height_inch


=cut

sub box_height_inch {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $supswigp->{_hbox} = $hbox;
        $supswigp->{_note} = $supswigp->{_note} . ' hbox=' . $supswigp->{_hbox};
        $supswigp->{_Step} = $supswigp->{_Step} . ' hbox=' . $supswigp->{_hbox};

    }
    else {
        print("supswigp,box_height_inch,missing hbox,\n");
    }
}

=head2 sub box_width_inch


=cut

sub box_width_inch {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $supswigp->{_wbox} = $wbox;
        $supswigp->{_note} = $supswigp->{_note} . ' wbox=' . $supswigp->{_wbox};
        $supswigp->{_Step} = $supswigp->{_Step} . ' wbox=' . $supswigp->{_wbox};

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

        $supswigp->{_clip} = $clip;
        $supswigp->{_note} = $supswigp->{_note} . ' clip=' . $supswigp->{_clip};
        $supswigp->{_Step} = $supswigp->{_Step} . ' clip=' . $supswigp->{_clip};

    }
    else {
        print("supswigp,missing clip,\n");
    }
}

=head2 sub cmap 
 define min and max plotting values

=cut

sub cmap {

    my ( $self, $cmap ) = @_;
    if ( $cmap ne $empty_string ) {

        $supswigp->{_cmap} = $cmap;
        $supswigp->{_note} = $supswigp->{_note} . ' cmap=' . $supswigp->{_cmap};
        $supswigp->{_Step} = $supswigp->{_Step} . ' cmap=' . $supswigp->{_cmap};

    }
    else {
        print("supswigp,cmap, missing cmap,\n");
    }
}

=head2 sub curve 


=cut

sub curve {

    my ( $self, $curve ) = @_;
    if ( $curve ne $empty_string ) {

        $supswigp->{_curve} = $curve;
        $supswigp->{_note} =
          $supswigp->{_note} . ' curve=' . $supswigp->{_curve};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' curve=' . $supswigp->{_curve};

    }
    else {
        print("supswigp,missing curve,\n");
    }
}

=head2 sub curvecolor 


=cut

sub curvecolor {

    my ( $self, $curvecolor ) = @_;
    if ( $curvecolor ne $empty_string ) {

        $supswigp->{_curvecolor} = $curvecolor;
        $supswigp->{_note} =
          $supswigp->{_note} . ' curvecolor=' . $supswigp->{_curvecolor};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' curvecolor=' . $supswigp->{_curvecolor};

    }
    else {
        print("supswigp,missing curvecolor,\n");
    }
}

=head2 sub curvefile 


=cut

sub curvefile {

    my ( $self, $curvefile ) = @_;
    if ( $curvefile ne $empty_string ) {

        $supswigp->{_curvefile} = $curvefile;
        $supswigp->{_note} =
          $supswigp->{_note} . ' curvefile=' . $supswigp->{_curvefile};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' curvefile=' . $supswigp->{_curvefile};

    }
    else {
        print("supswigp,missing curvefile,\n");
    }
}

=head2 sub d1 

 increment in fast dimension
 usually time and equal to dt

=cut

sub d1 {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $supswigp->{_d1}   = $d1;
        $supswigp->{_note} = $supswigp->{_note} . ' d1=' . $supswigp->{_d1};
        $supswigp->{_Step} = $supswigp->{_Step} . ' d1=' . $supswigp->{_d1};

    }
    else {
        print("supswigp, d1, missing d1,\n");
    }
}

=head2 subs d1 and dt

 increment in fast dimension
 usually time and equal to dt 

=cut 

sub dt {

    my ( $self, $d1 ) = @_;

    if ( $d1 ne $empty_string ) {

        $supswigp->{_d1}   = $d1;
        $supswigp->{_note} = $supswigp->{_note} . ' d1=' . $supswigp->{_d1};
        $supswigp->{_Step} = $supswigp->{_Step} . ' d1=' . $supswigp->{_d1};

    }
    else {
        print("supswigp, dt, missing d1,\n");
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

        $supswigp->{_d1num} = $d1num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' d1num=' . $supswigp->{_d1num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' d1num=' . $supswigp->{_d1num};

    }
    else {
        print("supswigp,dt_major_divisions,missing d1num,\n");
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

        $supswigp->{_d2}   = $d2;
        $supswigp->{_note} = $supswigp->{_note} . ' d2=' . $supswigp->{_d2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' d2=' . $supswigp->{_d2};

    }
    else {
        print("supswigp, dx, missing d2,\n");
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

        $supswigp->{_d1num} = $d1num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' d1num=' . $supswigp->{_d1num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' d1num=' . $supswigp->{_d1num};

    }
    else {
        print("supswigp,dy_major_divisions,missing d1num,\n");
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

        $supswigp->{_d1num} = $d1num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' d1num=' . $supswigp->{_d1num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' d1num=' . $supswigp->{_d1num};

    }
    else {
        print("supswigp,missing d1num,\n");
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

        $supswigp->{_d2}   = $d2;
        $supswigp->{_note} = $supswigp->{_note} . ' d2=' . $supswigp->{_d2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' d2=' . $supswigp->{_d2};

    }
    else {
        print("supswigp, d2, missing d2,\n");
    }
}

=head2 subs d2num  dx_major_divisions and x_tick_increment

 numbered tick increments along x axis 
 usually in m and only for display

=cut

sub d2num {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $supswigp->{_d2num} = $d2num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' d2num=' . $supswigp->{_d2num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' d2num=' . $supswigp->{_d2num};

    }
    else {
        print("supswigp,d2num, missing d2num,\n");
    }
}

=head2 sub endian 


=cut

sub endian {

    my ( $self, $endian ) = @_;
    if ( $endian ne $empty_string ) {

        $supswigp->{_endian} = $endian;
        $supswigp->{_note} =
          $supswigp->{_note} . ' endian=' . $supswigp->{_endian};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' endian=' . $supswigp->{_endian};

    }
    else {
        print("supswigp,missing endian,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut

sub f1 {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $supswigp->{_f1}   = $f1;
        $supswigp->{_note} = $supswigp->{_note} . ' f1=' . $supswigp->{_f1};
        $supswigp->{_Step} = $supswigp->{_Step} . ' f1=' . $supswigp->{_f1};

    }
    else {
        print("supswigp, f1, missing f1,\n");
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

        $supswigp->{_f1num} = $f1num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' f1num=' . $supswigp->{_f1num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' f1num=' . $supswigp->{_f1num};

    }
    else {
        print("supswigp,missing f1num,\n");
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

        $supswigp->{_f2}   = $f2;
        $supswigp->{_note} = $supswigp->{_note} . ' f2=' . $supswigp->{_f2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' f2=' . $supswigp->{_f2};

    }
    else {
        print("supswigp, f2, missing f2,\n");
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

        $supswigp->{_f2num} = $f2num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' f2num=' . $supswigp->{_f2num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' f2num=' . $supswigp->{_f2num};

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

        $supswigp->{_f2}   = $f2;
        $supswigp->{_note} = $supswigp->{_note} . ' f2=' . $supswigp->{_f2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' f2=' . $supswigp->{_f2};

    }
    else {
        print("supswigp, first_distance_sample_value, missing f2,\n");
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

        $supswigp->{_f2num} = $f2num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' f2num=' . $supswigp->{_f2num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' f2num=' . $supswigp->{_f2num};

    }
    else {
        print("supswigp,missing first_distance_tick_num,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut 

sub first_time_sample_value {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $supswigp->{_f1}   = $f1;
        $supswigp->{_note} = $supswigp->{_note} . ' f1=' . $supswigp->{_f1};
        $supswigp->{_Step} = $supswigp->{_Step} . ' f1=' . $supswigp->{_f1};

    }
    else {
        print("supswigp, first_time_sample_value, missing f1,\n");
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

        $supswigp->{_f1num} = $f1num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' f1num=' . $supswigp->{_f1num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' f1num=' . $supswigp->{_f1num};

    }
    else {
        print("supswigp, first_time_tick_num, missing first_time_tick_num\n");
    }
}

=head2 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)

=cut

sub first_x {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $supswigp->{_f2}   = $f2;
        $supswigp->{_note} = $supswigp->{_note} . ' f2=' . $supswigp->{_f2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' f2=' . $supswigp->{_f2};

    }
    else {
        print("supswigp, first_x, missing f2,\n");
    }
}

=head2 subs f1, first_time_sample_value and first_y 

 value of the first sample tihat is used

=cut 

sub first_y {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $supswigp->{_f1}   = $f1;
        $supswigp->{_note} = $supswigp->{_note} . ' f1=' . $supswigp->{_f1};
        $supswigp->{_Step} = $supswigp->{_Step} . ' f1=' . $supswigp->{_f1};

    }
    else {
        print("supswigp, first_y, missing f1,\n");
    }
}

=head2 sub ftr 


=cut 

sub ftr {

    my ( $self, $ftr ) = @_;
    if ( $ftr ne $empty_string ) {

        $supswigp->{_f1}   = $ftr;
        $supswigp->{_note} = $supswigp->{_note} . 'supswigp' . $supswigp->{_ftr};
        $supswigp->{_Step} = $supswigp->{_Step} . 'supswigp' . $supswigp->{_ftr};

    }
    else {
        print("supswigp, first_y, missing f1,\n");
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

        $supswigp->{_grid1} = $grid1;
        $supswigp->{_note} =
          $supswigp->{_note} . ' grid1=' . $supswigp->{_grid1};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' grid1=' . $supswigp->{_grid1};

    }
    else {
        print("supswigp,missing grid1,\n");
    }
}

=head2 sub grid2 

   A. Sivil 091718
   Adds grid lines above x axis as either a dot, dash or a solid line
   
=cut

sub grid2 {

    my ( $self, $grid2 ) = @_;
    if ( $grid2 ne $empty_string ) {

        $supswigp->{_grid2} = $grid2;
        $supswigp->{_note} =
          $supswigp->{_note} . ' grid2=' . $supswigp->{_grid2};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' grid2=' . $supswigp->{_grid2};

    }
    else {
        print("supswigp,missing grid2,\n");
    }
}

=head2 sub gridcolor 


=cut

sub gridcolor {

    my ( $self, $gridcolor ) = @_;
    if ( $gridcolor ne $empty_string ) {

        $supswigp->{_gridcolor} = $gridcolor;
        $supswigp->{_note} =
          $supswigp->{_note} . ' gridcolor=' . $supswigp->{_gridcolor};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' gridcolor=' . $supswigp->{_gridcolor};

    }
    else {
        print("supswigp,missing gridcolor,\n");
    }
}

=head2 sub hbox 


=cut

sub hbox {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $supswigp->{_hbox} = $hbox;
        $supswigp->{_note} = $supswigp->{_note} . ' hbox=' . $supswigp->{_hbox};
        $supswigp->{_Step} = $supswigp->{_Step} . ' hbox=' . $supswigp->{_hbox};

    }
    else {
        print("supswigp,missing hbox,\n");
    }
}

=head2 sub headerword 


=cut

sub headerword {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigp->{_key}  = $key;
        $supswigp->{_note} = $supswigp->{_note} . ' key=' . $supswigp->{_key};
        $supswigp->{_Step} = $supswigp->{_Step} . ' key=' . $supswigp->{_key};

    }
    else {
        print("supswigp, headerword, missing key,\n");
    }
}

=head2 sub header_word 


=cut

sub header_word {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigp->{_key}  = $key;
        $supswigp->{_note} = $supswigp->{_note} . ' key=' . $supswigp->{_key};
        $supswigp->{_Step} = $supswigp->{_Step} . ' key=' . $supswigp->{_key};

    }
    else {
        print("supswigp, header_word, missing key,\n");
    }
}

=head2 sub hiclip 


=cut

sub hiclip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigp->{_key}  = $key;
        $supswigp->{_note} = $supswigp->{_note} . ' bclip=' . $supswigp->{_key};
        $supswigp->{_Step} = $supswigp->{_Step} . ' bclip=' . $supswigp->{_key};

    }
    else {
        print("supswigp, hiclip, missing key,\n");
    }
}

=head2 sub hi_clip 


=cut

sub hi_clip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigp->{_key}  = $key;
        $supswigp->{_note} = $supswigp->{_note} . ' bclip=' . $supswigp->{_key};
        $supswigp->{_Step} = $supswigp->{_Step} . ' bclip=' . $supswigp->{_key};

    }
    else {
        print("supswigp, hi_clip, missing key,\n");
    }
}

=head2 sub interp 


=cut

sub interp {

    my ( $self, $interp ) = @_;
    if ( $interp ne $empty_string ) {

        $supswigp->{_interp} = $interp;
        $supswigp->{_note} =
          $supswigp->{_note} . ' interp=' . $supswigp->{_interp};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' interp=' . $supswigp->{_interp};

    }
    else {
        print("supswigp,missing interp,\n");
    }
}

=head2 sub key 


=cut

sub key {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigp->{_key}  = $key;
        $supswigp->{_note} = $supswigp->{_note} . ' key=' . $supswigp->{_key};
        $supswigp->{_Step} = $supswigp->{_Step} . ' key=' . $supswigp->{_key};

    }
    else {
        print("supswigp, key, missing key,\n");
    }
}

=head2 sub label1 

=cut

sub label1 {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $supswigp->{_label1} = $label1;
        $supswigp->{_note} =
          $supswigp->{_note} . ' label1=' . $supswigp->{_label1};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' label1=' . $supswigp->{_label1};

    }
    else {
        print("supswigp,missing label1,\n");
    }
}

=head2 sub label2 

   A. Sivil 091718
   Adds label above x axis in top-right corner

=cut

sub label2 {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $supswigp->{_label2} = $label2;
        $supswigp->{_note} =
          $supswigp->{_note} . ' label2=' . $supswigp->{_label2};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' label2=' . $supswigp->{_label2};

    }
    else {
        print("supswigp,missing label2,\n");
    }
}

=head2 sub labelcolor 


=cut

sub labelcolor {

    my ( $self, $labelcolor ) = @_;
    if ( $labelcolor ne $empty_string ) {

        $supswigp->{_labelcolor} = $labelcolor;
        $supswigp->{_note} =
          $supswigp->{_note} . ' labelcolor=' . $supswigp->{_labelcolor};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' labelcolor=' . $supswigp->{_labelcolor};

    }
    else {
        print("supswigp,missing labelcolor,\n");
    }
}

=head2 sub labelfont 

   A. Sivil 091718
   Changes font for label

=cut

sub labelfont {

    my ( $self, $labelfont ) = @_;
    if ( $labelfont ne $empty_string ) {

        $supswigp->{_labelfont} = $labelfont;
        $supswigp->{_note} =
          $supswigp->{_note} . ' labelfont=' . $supswigp->{_labelfont};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' labelfont=' . $supswigp->{_labelfont};

    }
    else {
        print("supswigp,missing labelfont,\n");
    }
}

=head2 sub lo_clip 


=cut

sub lo_clip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigp->{_key}  = $key;
        $supswigp->{_note} = $supswigp->{_note} . ' wclip=' . $supswigp->{_key};
        $supswigp->{_Step} = $supswigp->{_Step} . ' wclip=' . $supswigp->{_key};

    }
    else {
        print("supswigp, lo_clip, missing key,\n");
    }
}

=head2 sub loclip 


=cut

sub loclip {

    my ( $self, $key ) = @_;
    if ( $key ne $empty_string ) {

        $supswigp->{_key}  = $key;
        $supswigp->{_note} = $supswigp->{_note} . ' wclip=' . $supswigp->{_key};
        $supswigp->{_Step} = $supswigp->{_Step} . ' wclip=' . $supswigp->{_key};

    }
    else {
        print("supswigp, loclip, missing key,\n");
    }
}

=head2 sub mpicks 

G. Bonot 091718
Input a file name to which your mouse clicks are to be saved. No visible change observed in xwigb

=cut

sub mpicks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        $supswigp->{_mpicks} = $mpicks;
        $supswigp->{_note} =
          $supswigp->{_note} . ' mpicks=' . $supswigp->{_mpicks};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' mpicks=' . $supswigp->{_mpicks};

    }
    else {
        print("supswigp,missing mpicks,\n");
    }
}

=head2 sub n1 

=cut

sub n1 {

    my ( $self, $n1 ) = @_;
    if ( $n1 ne $empty_string ) {

        $supswigp->{_n1}   = $n1;
        $supswigp->{_note} = $supswigp->{_note} . ' n1=' . $supswigp->{_n1};
        $supswigp->{_Step} = $supswigp->{_Step} . ' n1=' . $supswigp->{_n1};

    }
    else {
        print("supswigp,missing n1,\n");
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

        $supswigp->{_n1tic} = $n1tic;
        $supswigp->{_note} =
          $supswigp->{_note} . ' n1tic=' . $supswigp->{_n1tic};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' n1tic=' . $supswigp->{_n1tic};

    }
    else {
        print("supswigp,missing n1tic,\n");
    }
}

=head2 sub n2 


=cut

sub n2 {

    my ( $self, $n2 ) = @_;
    if ( $n2 ne $empty_string ) {

        $supswigp->{_n2}   = $n2;
        $supswigp->{_note} = $supswigp->{_note} . ' n2=' . $supswigp->{_n2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' n2=' . $supswigp->{_n2};

    }
    else {
        print("supswigp, n2, missing n2,\n");
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

        $supswigp->{_n2tic} = $n2tic;
        $supswigp->{_note} =
          $supswigp->{_note} . ' n2tic=' . $supswigp->{_n2tic};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' n2tic=' . $supswigp->{_n2tic};

    }
    else {
        print("supswigp,missing n2tic,\n");
    }
}


=head2 sub npair 


=cut

sub npair {

    my ( $self, $npair ) = @_;
    if ( $npair ne $empty_string ) {

        $supswigp->{_npair} = $npair;
        $supswigp->{_note} =
          $supswigp->{_note} . ' npair=' . $supswigp->{_npair};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' npair=' . $supswigp->{_npair};

    }
    else {
        print("supswigp,missing npair,\n");
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

        $supswigp->{_n2tic} = $n2tic;
        $supswigp->{_note} =
          $supswigp->{_note} . ' n2tic=' . $supswigp->{_n2tic};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' n2tic=' . $supswigp->{_n2tic};

    }
    else {
        print("supswigp,num_minor_ticks_betw_distance_ticks, missing n2tic,\n");
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

        $supswigp->{_n1tic} = $n1tic;
        $supswigp->{_note} =
          $supswigp->{_note} . ' n1tic=' . $supswigp->{_n1tic};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' n1tic=' . $supswigp->{_n1tic};

    }
    else {
        print("supswigp, num_minor_ticks_betw_time_ticks, missing n1tic,\n");
    }
}

=head2 sub orientation 

  seismic style of plotting (time axis pointing down)
  versus mathematical ( y axis up)

=cut

sub orientation {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $supswigp->{_style} = $style;
        $supswigp->{_note} =
          $supswigp->{_note} . ' style=' . $supswigp->{_style};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' style=' . $supswigp->{_style};

    }
    else {
        print("supswigp, orientation, missing style,\n");
    }
}

=head2 sub perc 


=cut

sub perc {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $supswigp->{_perc} = $perc;
        $supswigp->{_note} = $supswigp->{_note} . ' perc=' . $supswigp->{_perc};
        $supswigp->{_Step} = $supswigp->{_Step} . ' perc=' . $supswigp->{_perc};

    }
    else {
        print("supswigp,missing perc,\n");
    }
}

=head2 sub percent 


=cut

sub percent {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $supswigp->{_perc} = $perc;
        $supswigp->{_note} = $supswigp->{_note} . ' perc=' . $supswigp->{_perc};
        $supswigp->{_Step} = $supswigp->{_Step} . ' perc=' . $supswigp->{_perc};

    }
    else {
        print("supswigp,percent, missing perc,\n");
    }
}

=head2 sub picks

 automatically generates a pick file
 
=cut

sub picks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        # print("supswigp, picks, file_name is: $mpicks\n");

        $supswigp->{_mpicks} = $mpicks;
        $supswigp->{_note} =
          $supswigp->{_note} . ' mpicks=' . $supswigp->{_mpicks};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' mpicks=' . $supswigp->{_mpicks};

    }
    else {
        print("supswigp,picks, missing mpicks,\n");
    }
}

=head2 sub plotfile 


=cut

sub plotfile {

    my ( $self, $plotfile ) = @_;
    if ( $plotfile ne $empty_string ) {

        $supswigp->{_plotfile} = $plotfile;
        $supswigp->{_note} =
          $supswigp->{_note} . ' plotfile=' . $supswigp->{_plotfile};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' plotfile=' . $supswigp->{_plotfile};

    }
    else {
        print("supswigp,missing plotfile,\n");
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

        $supswigp->{_va}   = $va;
        $supswigp->{_note} = $supswigp->{_note} . ' va=' . $supswigp->{_va};
        $supswigp->{_Step} = $supswigp->{_Step} . ' va=' . $supswigp->{_va};

    }
    else {
        print("supswigp,shading, missing va\n");
    }
}

=head2 sub style 

  seismic style of plotting (time axis pointing down)
  versus mathematical ( y axis up)

=cut

sub style {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $supswigp->{_style} = $style;
        $supswigp->{_note} =
          $supswigp->{_note} . ' style=' . $supswigp->{_style};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' style=' . $supswigp->{_style};

    }
    else {
        print("supswigp, style, missing style,\n");
    }
}

=head2 sub title 

 allows for a default graph title ($on) or
 a user-defined title

=cut

sub title {

    my ( $self, $title ) = @_;
    if ( $title ne $empty_string ) {

        $supswigp->{_title} = $title;
        $supswigp->{_note} =
          $supswigp->{_note} . ' title=' . $supswigp->{_title};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' title=' . $supswigp->{_title};

    }
    else {
        print("supswigp,missing title,\n");
    }
}

=head2 sub titlecolor 

 allows for a default graph title ($on) or
 a user-defined title

=cut

sub titlecolor {

    my ( $self, $titlecolor ) = @_;
    if ( $titlecolor ne $empty_string ) {

        $supswigp->{_titlecolor} = $titlecolor;
        $supswigp->{_note} =
          $supswigp->{_note} . ' titlecolor=' . $supswigp->{_titlecolor};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' titlecolor=' . $supswigp->{_titlecolor};

    }
    else {
        print("supswigp,missing titlecolor,\n");
    }
}

=head2 sub titlefont 


=cut

sub titlefont {

    my ( $self, $titlefont ) = @_;
    if ( $titlefont ne $empty_string ) {

        $supswigp->{_titlefont} = $titlefont;
        $supswigp->{_note} =
          $supswigp->{_note} . ' titlefont=' . $supswigp->{_titlefont};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' titlefont=' . $supswigp->{_titlefont};

    }
    else {
        print("supswigp,missing titlefont,\n");
    }
}

=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ( $tmpdir ne $empty_string ) {

        $supswigp->{_tmpdir} = $tmpdir;
        $supswigp->{_note} =
          $supswigp->{_note} . ' tmpdir=' . $supswigp->{_tmpdir};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' tmpdir=' . $supswigp->{_tmpdir};

    }
    else {
        print("supswigp, tmpdir, missing tmpdir,\n");
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

        $supswigp->{_d2}   = $d2;
        $supswigp->{_note} = $supswigp->{_note} . ' d2=' . $supswigp->{_d2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' d2=' . $supswigp->{_d2};

    }
    else {
        print("supswigp, trace_inc, missing d2,\n");
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

        $supswigp->{_d2}   = $d2;
        $supswigp->{_note} = $supswigp->{_note} . ' d2=' . $supswigp->{_d2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' d2=' . $supswigp->{_d2};

    }
    else {
        print("supswigp, trace_inc_m, missing d2,\n");
    }
}

=head2 sub tend_s 

minimum value of yaxis (time usually) in seconds

=cut

sub tend_s {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $supswigp->{_x1end} = $x1end;
        $supswigp->{_note} =
          $supswigp->{_note} . ' x1end=' . $supswigp->{_x1end};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' x1end=' . $supswigp->{_x1end};

    }
    else {
        print("supswigp,tend_s, missing x1end,\n");
    }
}

=head2 sub tstart_s 

  minimum value of yaxis (time usually) in seconds

=cut

sub tstart_s {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $supswigp->{_x1beg} = $x1beg;
        $supswigp->{_note} =
          $supswigp->{_note} . ' x1beg=' . $supswigp->{_x1beg};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' x1beg=' . $supswigp->{_x1beg};

    }
    else {
        print("supswigp,tstart_s, missing x1beg,\n");
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

        $supswigp->{_va}   = $va;
        $supswigp->{_note} = $supswigp->{_note} . ' va=' . $supswigp->{_va};
        $supswigp->{_Step} = $supswigp->{_Step} . ' va=' . $supswigp->{_va};

    }
    else {
        print("supswigp,missing va,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $supswigp->{_verbose} = $verbose;
        $supswigp->{_note} =
          $supswigp->{_note} . ' verbose=' . $supswigp->{_verbose};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' verbose=' . $supswigp->{_verbose};

    }
    else {
        print("supswigp, verbose, missing verbose,\n");
    }
}

=head2 sub wbox 


=cut

sub wbox {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $supswigp->{_wbox} = $wbox;
        $supswigp->{_note} = $supswigp->{_note} . ' wbox=' . $supswigp->{_wbox};
        $supswigp->{_Step} = $supswigp->{_Step} . ' wbox=' . $supswigp->{_wbox};

    }
    else {
        print("supswigp,missing wbox,\n");
    }
}

=head2 sub wclip 


=cut

sub wclip {

    my ( $self, $wclip ) = @_;
    if ( $wclip ne $empty_string ) {

        $supswigp->{_wclip} = $wclip;
        $supswigp->{_note} =
          $supswigp->{_note} . ' wclip=' . $supswigp->{_wclip};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' wclip=' . $supswigp->{_wclip};

    }
    else {
        print("supswigp, wclip, missing wclip,\n");
    }
}

=head2 sub wigclip 


=cut

sub wigclip {

    my ( $self, $wigclip ) = @_;
    if ( $wigclip ne $empty_string ) {

        $supswigp->{_wigclip} = $wigclip;
        $supswigp->{_note} =
          $supswigp->{_note} . ' wigclip=' . $supswigp->{_wigclip};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' wigclip=' . $supswigp->{_wigclip};

    }
    else {
        print("supswigp,missing wigclip,\n");
    }
}

=head2 sub windowtitle 


=cut

sub windowtitle {

    my ( $self, $windowtitle ) = @_;
    if ( $windowtitle ne $empty_string ) {

        $supswigp->{_windowtitle} = $windowtitle;
        $supswigp->{_note} =
          $supswigp->{_note} . ' windowtitle=' . $supswigp->{_windowtitle};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' windowtitle=' . $supswigp->{_windowtitle};

    }
    else {
        print("supswigp,missing windowtitle,\n");
    }
}

=head2 sub wt 


=cut

sub wt {

    my ( $self, $wt ) = @_;
    if ( $wt ne $empty_string ) {

        $supswigp->{_wt}   = $wt;
        $supswigp->{_note} = $supswigp->{_note} . ' wt=' . $supswigp->{_wt};
        $supswigp->{_Step} = $supswigp->{_Step} . ' wt=' . $supswigp->{_wt};

    }
    else {
        print("supswigp,missing wt,\n");
    }
}

=head2 sub x1beg 

  minimum value of yaxis (time usually) in seconds

=cut

sub x1beg {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $supswigp->{_x1beg} = $x1beg;
        $supswigp->{_note} =
          $supswigp->{_note} . ' x1beg=' . $supswigp->{_x1beg};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' x1beg=' . $supswigp->{_x1beg};

    }
    else {
        print("supswigp,missing x1beg,\n");
    }
}

=head2 sub x1end 

minimum value of yaxis (time usually) in seconds

=cut

sub x1end {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $supswigp->{_x1end} = $x1end;
        $supswigp->{_note} =
          $supswigp->{_note} . ' x1end=' . $supswigp->{_x1end};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' x1end=' . $supswigp->{_x1end};

    }
    else {
        print("supswigp,missing x1end,\n");
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

        $supswigp->{_x2}   = $x2;
        $supswigp->{_note} = $supswigp->{_note} . ' x2=' . $supswigp->{_x2};
        $supswigp->{_Step} = $supswigp->{_Step} . ' x2=' . $supswigp->{_x2};

    }
    else {
        print("supswigp,missing x2,\n");
    }
}

=head2 sub x2beg 

 minimum value of x axis (time usually) in seconds
 First value shown on x axis GTL18
 

=cut

sub x2beg {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $supswigp->{_x2beg} = $x2beg;
        $supswigp->{_note} =
          $supswigp->{_note} . ' x2beg=' . $supswigp->{_x2beg};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' x2beg=' . $supswigp->{_x2beg};

    }
    else {
        print("supswigp,missing x2beg,\n");
    }
}

=head2 sub x2end 
  
  max value of xaxis (distance or traces, usually) in seconds
  Last value for data shown on x axis GTL18

=cut

sub x2end {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $supswigp->{_x2end} = $x2end;
        $supswigp->{_note} =
          $supswigp->{_note} . ' x2end=' . $supswigp->{_x2end};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' x2end=' . $supswigp->{_x2end};

    }
    else {
        print("supswigp,missing x2end,\n");
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

        $supswigp->{_xbox} = $xbox;
        $supswigp->{_note} = $supswigp->{_note} . ' xbox=' . $supswigp->{_xbox};
        $supswigp->{_Step} = $supswigp->{_Step} . ' xbox=' . $supswigp->{_xbox};

    }
    else {
        print("supswigp,missing xbox,\n");
    }
}

=head2 sub xcur 

how many adjacent wiggles can be overploted

=cut

sub xcur {

    my ( $self, $xcur ) = @_;
    if ( $xcur ne $empty_string ) {

        $supswigp->{_xcur} = $xcur;
        $supswigp->{_note} = $supswigp->{_note} . ' xcur=' . $supswigp->{_xcur};
        $supswigp->{_Step} = $supswigp->{_Step} . ' xcur=' . $supswigp->{_xcur};

    }
    else {
        print("supswigp,missing xcur,\n");
    }
}

=head2 sub xend_m 

 
=cut

sub xend_m {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $supswigp->{_x2end} = $x2end;
        $supswigp->{_note} =
          $supswigp->{_note} . ' x2end=' . $supswigp->{_x2end};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' x2end=' . $supswigp->{_x2end};

    }
    else {
        print("supswigp,xend_m, missing x2end,\n");
    }
}

=head2 subs xlabel or label2 ylabel or label1


=cut

sub xlabel {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $supswigp->{_label2} = $label2;
        $supswigp->{_note} =
          $supswigp->{_note} . ' label2=' . $supswigp->{_label2};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' label2=' . $supswigp->{_label2};

    }
    else {
        print("supswigp, xlabelmissing label2,\n");
    }
}

=head2 sub xstart_m 

 
=cut

sub xstart_m {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $supswigp->{_x2beg} = $x2beg;
        $supswigp->{_note} =
          $supswigp->{_note} . ' x2beg=' . $supswigp->{_x2beg};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' x2beg=' . $supswigp->{_x2beg};

    }
    else {
        print("supswigp,xstart_m, missing x2beg,\n");
    }
}

=head2 subs d2num  dx_major_divisions and x_tick_increment

 numbered tick increments along x axis 
 usually in m and only for display

=cut

sub x_tick_increment {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $supswigp->{_d2num} = $d2num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' d2num=' . $supswigp->{_d2num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' d2num=' . $supswigp->{_d2num};

    }
    else {
        print("supswigp,d2num, missing d2num,\n");
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

        $supswigp->{_ybox} = $ybox;
        $supswigp->{_note} = $supswigp->{_note} . ' ybox=' . $supswigp->{_ybox};
        $supswigp->{_Step} = $supswigp->{_Step} . ' ybox=' . $supswigp->{_ybox};

    }
    else {
        print("supswigp,missing ybox,\n");
    }
}

=head2 subs ylabel or label1


=cut

sub ylabel {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $supswigp->{_label1} = $label1;
        $supswigp->{_note} =
          $supswigp->{_note} . ' label1=' . $supswigp->{_label1};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' label1=' . $supswigp->{_label1};

    }
    else {
        print("supswigp, ylabel, missing label1,\n");
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

        $supswigp->{_d1num} = $d1num;
        $supswigp->{_note} =
          $supswigp->{_note} . ' d1num=' . $supswigp->{_d1num};
        $supswigp->{_Step} =
          $supswigp->{_Step} . ' d1num=' . $supswigp->{_d1num};

    }
    else {
        print("supswigp,y_tick_increment,missing d1num,\n");
    }
}

=head2 sub axescolor 


=cut

 sub axescolor {

	my ( $self,$axescolor )		= @_;
	if ( $axescolor ne $empty_string ) {

		$supswigp->{_axescolor}		= $axescolor;
		$supswigp->{_note}		= $supswigp->{_note}.' axescolor='.$supswigp->{_axescolor};
		$supswigp->{_Step}		= $supswigp->{_Step}.' axescolor='.$supswigp->{_axescolor};

	} else { 
		print("pswigp, axescolor, missing axescolor,\n");
	 }
 }


=head2 sub axeswidth 


=cut

 sub axeswidth {

	my ( $self,$axeswidth )		= @_;
	if ( $axeswidth ne $empty_string ) {

		$supswigp->{_axeswidth}		= $axeswidth;
		$supswigp->{_note}		= $supswigp->{_note}.' axeswidth='.$supswigp->{_axeswidth};
		$supswigp->{_Step}		= $supswigp->{_Step}.' axeswidth='.$supswigp->{_axeswidth};

	} else { 
		print("pswigp, axeswidth, missing axeswidth,\n");
	 }
 }


=head2 sub backcolor 


=cut

 sub backcolor {

	my ( $self,$backcolor )		= @_;
	if ( $backcolor ne $empty_string ) {

		$supswigp->{_backcolor}		= $backcolor;
		$supswigp->{_note}		= $supswigp->{_note}.' backcolor='.$supswigp->{_backcolor};
		$supswigp->{_Step}		= $supswigp->{_Step}.' backcolor='.$supswigp->{_backcolor};

	} else { 
		print("pswigp, backcolor, missing backcolor,\n");
	 }
 }



=head2 sub curvedash 


=cut

 sub curvedash {

	my ( $self,$curvedash )		= @_;
	if ( $curvedash ne $empty_string ) {

		$supswigp->{_curvedash}		= $curvedash;
		$supswigp->{_note}		= $supswigp->{_note}.' curvedash='.$supswigp->{_curvedash};
		$supswigp->{_Step}		= $supswigp->{_Step}.' curvedash='.$supswigp->{_curvedash};

	} else { 
		print("pswigp, curvedash, missing curvedash,\n");
	 }
 }



=head2 sub fill 


=cut

 sub fill {

	my ( $self,$fill )		= @_;
	if ( $fill ne $empty_string ) {

		$supswigp->{_fill}		= $fill;
		$supswigp->{_note}		= $supswigp->{_note}.' fill='.$supswigp->{_fill};
		$supswigp->{_Step}		= $supswigp->{_Step}.' fill='.$supswigp->{_fill};

	} else { 
		print("pswigp, fill, missing fill,\n");
	 }
 }


=head2 sub gridwidth 


=cut

 sub gridwidth {

	my ( $self,$gridwidth )		= @_;
	if ( $gridwidth ne $empty_string ) {

		$supswigp->{_gridwidth}		= $gridwidth;
		$supswigp->{_note}		= $supswigp->{_note}.' gridwidth='.$supswigp->{_gridwidth};
		$supswigp->{_Step}		= $supswigp->{_Step}.' gridwidth='.$supswigp->{_gridwidth};

	} else { 
		print("pswigp, gridwidth, missing gridwidth,\n");
	 }
 }



=head2 sub labelsize 


=cut

 sub labelsize {

	my ( $self,$labelsize )		= @_;
	if ( $labelsize ne $empty_string ) {

		$supswigp->{_labelsize}		= $labelsize;
		$supswigp->{_note}		= $supswigp->{_note}.' labelsize='.$supswigp->{_labelsize};
		$supswigp->{_Step}		= $supswigp->{_Step}.' labelsize='.$supswigp->{_labelsize};

	} else { 
		print("pswigp, labelsize, missing labelsize,\n");
	 }
 }


=head2 sub linewidth 


=cut

 sub linewidth {

	my ( $self,$linewidth )		= @_;
	if ( $linewidth ne $empty_string ) {

		$supswigp->{_linewidth}		= $linewidth;
		$supswigp->{_note}		= $supswigp->{_note}.' linewidth='.$supswigp->{_linewidth};
		$supswigp->{_Step}		= $supswigp->{_Step}.' linewidth='.$supswigp->{_linewidth};

	} else { 
		print("pswigp, linewidth, missing linewidth,\n");
	 }
 }



=head2 sub ticwidth 


=cut

 sub ticwidth {

	my ( $self,$ticwidth )		= @_;
	if ( $ticwidth ne $empty_string ) {

		$supswigp->{_ticwidth}		= $ticwidth;
		$supswigp->{_note}		= $supswigp->{_note}.' ticwidth='.$supswigp->{_ticwidth};
		$supswigp->{_Step}		= $supswigp->{_Step}.' ticwidth='.$supswigp->{_ticwidth};

	} else { 
		print("pswigp, ticwidth, missing ticwidth,\n");
	 }
 }



=head2 sub titlesize 


=cut

 sub titlesize {

	my ( $self,$titlesize )		= @_;
	if ( $titlesize ne $empty_string ) {

		$supswigp->{_titlesize}		= $titlesize;
		$supswigp->{_note}		= $supswigp->{_note}.' titlesize='.$supswigp->{_titlesize};
		$supswigp->{_Step}		= $supswigp->{_Step}.' titlesize='.$supswigp->{_titlesize};

	} else { 
		print("pswigp, titlesize, missing titlesize,\n");
	 }
 }


=head2 sub tracecolor 


=cut

 sub tracecolor {

	my ( $self,$tracecolor )		= @_;
	if ( $tracecolor ne $empty_string ) {

		$supswigp->{_tracecolor}		= $tracecolor;
		$supswigp->{_note}		= $supswigp->{_note}.' tracecolor='.$supswigp->{_tracecolor};
		$supswigp->{_Step}		= $supswigp->{_Step}.' tracecolor='.$supswigp->{_tracecolor};

	} else { 
		print("pswigp, tracecolor, missing tracecolor,\n");
	 }
 }



=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 53;

    return ($max_index);
}

1;
