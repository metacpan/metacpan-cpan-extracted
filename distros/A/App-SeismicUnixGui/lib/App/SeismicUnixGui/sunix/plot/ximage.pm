package App::SeismicUnixGui::sunix::plot::ximage;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  XIMAGE - X IMAGE plot of a uniformly-sampled function f(x1,x2)     	
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

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

 Required Parameters:							
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
 cmap=hsv\'n\' or rgb\'m\'	\'n\' is a number from 0 to 13		
				\'m\' is a number from 0 to 11		
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
 style=seismic	        normal (axis 1 horizontal, axis 2 vertical) or  
			seismic (axis 1 vertical, axis 2 horizontal)	
 blank=0		This indicates what portion of the lower range  
			to blank out (make the background color).  The  
			value should range from 0 to 1.			
 plotfile=plotfile.ps  filename for interactive ploting (P)  		
 curve=curve1,curve2,...  file(s) containing points to draw curve(s)   
 npair=n1,n2,n2,...            number(s) of pairs in each file         
 curvecolor=color1,color2,...  color(s) for curve(s)                   
 blockinterp=0       whether to use block interpolation (0=no, 1=yes)  


 NOTES:								
 The curve file is an ascii file with the points  specified as x1 x2	
 pairs separated by a space, one pair to a line.  A "vector" of curve
 files and curve colors may be specified as curvefile=file1,file2,etc. 
 and curvecolor=color1,color2,etc, and the number of pairs of values   
 in each file as npair=npair1,npair2,... .                             


 Author:  Dave Hale, Colorado School of Mines, 08/09/90

 Stewart A. Levin, Mobil - Added ps print option

 Brian Zook, Southwest Research Institute, 6/27/96, added blank option

 Toralf Foerster, Baltic Sea Research Institute, 9/15/96, new colormaps

 Berend Scheffers, Delft, colorbar (legend)

 Brian K. Macy, Phillips Petroleum, 11/27/98, added curve plotting option
 
 G.Klein, GEOMAR Kiel, 2004-03-12, added cursor scrolling and
                                   interactive change of zoom and clipping.
 
 Zhaobo Meng, ConocoPhillips, 12/02/04, added amplitude display
 
 Garry Perratt, Geocon, 08/04/05, modified perc handling to center colorbar if balance==1.

INTL2B_block - blocky interpolation of a 2-D array of bytes

intl2b_block		blocky interpolation of a 2-D array of bytes

Function Prototype:
void intl2b_block(int nxin, float dxin, float fxin,
	int nyin, float dyin, float fyin, unsigned char *zin,
	int nxout, float dxout, float fxout,
	int nyout, float dyout, float fyout, unsigned char *zout);

Input:
nxin		number of x samples input (fast dimension of zin)
dxin		x sampling interval input
fxin		first x sample input
nyin		number of y samples input (slow dimension of zin)
dyin		y sampling interval input
fyin		first y sample input
zin		array[nyin][nxin] of input samples (see notes)
nxout		number of x samples output (fast dimension of zout)
dxout		x sampling interval output
fxout		first x sample output
nyout		number of y samples output (slow dimension of zout)
dyout		y sampling interval output
fyout		first y sample output

Output:
zout		array[nyout][nxout] of output samples (see notes)

Notes:
The arrays zin and zout must passed as pointers to the first element of
a two-dimensional contiguous array of unsigned char values.

Constant extrapolation of zin is used to compute zout for
output x and y outside the range of input x and y.

Author:  James Gunning, CSIRO Petroleum 1999. Hacked from
intl2b() by Dave Hale, Colorado School of Mines, c. 1989-1991
=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $ximage = {
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
    _d1          => '',
    _d1num       => '',
    _d2          => '',
    _d2num       => '',
    _f1          => '',
    _f1num       => '',
    _f2          => '',
    _f2num       => '',
    _grid1       => '',
    _grid2       => '',
    _gridcolor   => '',
    _hbox        => '',
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

    $ximage->{_Step} = 'ximage' . $ximage->{_Step};
    return ( $ximage->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $ximage->{_note} = 'ximage' . $ximage->{_note};
    return ( $ximage->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $ximage->{_balance}     = '';
    $ximage->{_bclip}       = '';
    $ximage->{_blank}       = '';
    $ximage->{_blockinterp} = '';
    $ximage->{_bperc}       = '';
    $ximage->{_clip}        = '';
    $ximage->{_cmap}        = '';
    $ximage->{_curve}       = '';
    $ximage->{_curvecolor}  = '';
    $ximage->{_curvefile}   = '';
    $ximage->{_d1}          = '';
    $ximage->{_d1num}       = '';
    $ximage->{_d2}          = '';
    $ximage->{_d2num}       = '';
    $ximage->{_f1}          = '';
    $ximage->{_f1num}       = '';
    $ximage->{_f2}          = '';
    $ximage->{_f2num}       = '';
    $ximage->{_grid1}       = '';
    $ximage->{_grid2}       = '';
    $ximage->{_gridcolor}   = '';
    $ximage->{_hbox}        = '';
    $ximage->{_label1}      = '';
    $ximage->{_label2}      = '';
    $ximage->{_labelcolor}  = '';
    $ximage->{_labelfont}   = '';
    $ximage->{_legend}      = '';
    $ximage->{_legendfont}  = '';
    $ximage->{_lheight}     = '';
    $ximage->{_lwidth}      = '';
    $ximage->{_lx}          = '';
    $ximage->{_ly}          = '';
    $ximage->{_mpicks}      = '';
    $ximage->{_n1}          = '';
    $ximage->{_n1tic}       = '';
    $ximage->{_n2}          = '';
    $ximage->{_n2tic}       = '';
    $ximage->{_npair}       = '';
    $ximage->{_perc}        = '';
    $ximage->{_plotfile}    = '';
    $ximage->{_style}       = '';
    $ximage->{_title}       = '';
    $ximage->{_titlecolor}  = '';
    $ximage->{_titlefont}   = '';
    $ximage->{_units}       = '';
    $ximage->{_verbose}     = '';
    $ximage->{_wbox}        = '';
    $ximage->{_wclip}       = '';
    $ximage->{_windowtitle} = '';
    $ximage->{_wperc}       = '';
    $ximage->{_x1beg}       = '';
    $ximage->{_x1end}       = '';
    $ximage->{_x2beg}       = '';
    $ximage->{_x2end}       = '';
    $ximage->{_xbox}        = '';
    $ximage->{_ybox}        = '';
    $ximage->{_Step}        = '';
    $ximage->{_note}        = '';
}

=head2 sub absclip 


=cut

sub absclip {

    my ( $self, $clip ) = @_;
    if ( $clip ne $empty_string ) {

        $ximage->{_clip} = $clip;
        $ximage->{_note} = $ximage->{_note} . ' clip=' . $ximage->{_clip};
        $ximage->{_Step} = $ximage->{_Step} . ' clip=' . $ximage->{_clip};

    }
    else {
        print("ximage, absclip, missing clip,\n");
    }
}

=head2 sub balance 


=cut

sub balance {

    my ( $self, $balance ) = @_;
    if ( $balance ne $empty_string ) {

        $ximage->{_balance} = $balance;
        $ximage->{_note} =
          $ximage->{_note} . ' balance=' . $ximage->{_balance};
        $ximage->{_Step} =
          $ximage->{_Step} . ' balance=' . $ximage->{_balance};

    }
    else {
        print("ximage, balance, missing balance,\n");
    }
}

=head2 sub bclip 


=cut

sub bclip {

    my ( $self, $bclip ) = @_;
    if ( $bclip ne $empty_string ) {

        $ximage->{_bclip} = $bclip;
        $ximage->{_note}  = $ximage->{_note} . ' bclip=' . $ximage->{_bclip};
        $ximage->{_Step}  = $ximage->{_Step} . ' bclip=' . $ximage->{_bclip};

    }
    else {
        print("ximage, bclip, missing bclip,\n");
    }
}

=head2 sub blank 


=cut

sub blank {

    my ( $self, $blank ) = @_;
    if ( $blank ne $empty_string ) {

        $ximage->{_blank} = $blank;
        $ximage->{_note}  = $ximage->{_note} . ' blank=' . $ximage->{_blank};
        $ximage->{_Step}  = $ximage->{_Step} . ' blank=' . $ximage->{_blank};

    }
    else {
        print("ximage, blank, missing blank,\n");
    }
}

=head2 sub blockinterp 


=cut

sub blockinterp {

    my ( $self, $blockinterp ) = @_;
    if ( $blockinterp ne $empty_string ) {

        $ximage->{_blockinterp} = $blockinterp;
        $ximage->{_note} =
          $ximage->{_note} . ' blockinterp=' . $ximage->{_blockinterp};
        $ximage->{_Step} =
          $ximage->{_Step} . ' blockinterp=' . $ximage->{_blockinterp};

    }
    else {
        print("ximage, blockinterp, missing blockinterp,\n");
    }
}

=head2 sub box_X0


=cut

sub box_X0 {

    my ( $self, $xbox ) = @_;
    if ($xbox) {

        $ximage->{_xbox} = $xbox;
        $ximage->{_note} = $ximage->{_note} . ' xbox=' . $ximage->{_xbox};
        $ximage->{_Step} = $ximage->{_Step} . ' xbox=' . $ximage->{_xbox};

    }
    else {
        print("ximage, wbox, missing box_X0,\n");
    }
}

=head2 sub box_Y0


=cut

sub box_Y0 {

    my ( $self, $ybox ) = @_;
    if ($ybox) {

        $ximage->{_ybox} = $ybox;
        $ximage->{_note} = $ximage->{_note} . ' ybox=' . $ximage->{_ybox};
        $ximage->{_Step} = $ximage->{_Step} . ' ybox=' . $ximage->{_ybox};

    }
    else {
        print("ximage, box_Y0, missing box_Y0,\n");
    }
}

=head2 sub box_height 


=cut

sub box_height {

    my ( $self, $hbox ) = @_;
    if ($hbox) {

        $ximage->{_hbox} = $hbox;
        $ximage->{_note} = $ximage->{_note} . ' hbox=' . $ximage->{_hbox};
        $ximage->{_Step} = $ximage->{_Step} . ' hbox=' . $ximage->{_hbox};

    }
    else {
        print("ximage, hbox, missing box_height,\n");
    }
}

=head2 sub box_width 


=cut

sub box_width {

    my ( $self, $wbox ) = @_;
    if ($wbox) {

        $ximage->{_wbox} = $wbox;
        $ximage->{_note} = $ximage->{_note} . ' wbox=' . $ximage->{_wbox};
        $ximage->{_Step} = $ximage->{_Step} . ' wbox=' . $ximage->{_wbox};

    }
    else {
        print("ximage, wbox, missing box_width,\n");
    }
}

=head2 sub bperc 


=cut

sub bperc {

    my ( $self, $bperc ) = @_;
    if ( $bperc ne $empty_string ) {

        $ximage->{_bperc} = $bperc;
        $ximage->{_note}  = $ximage->{_note} . ' bperc=' . $ximage->{_bperc};
        $ximage->{_Step}  = $ximage->{_Step} . ' bperc=' . $ximage->{_bperc};

    }
    else {
        print("ximage, bperc, missing bperc,\n");
    }
}

=head2 sub clip 

determine the absolute clip for data

=cut

sub clip {

    my ( $self, $clip ) = @_;
    if ( $clip ne $empty_string ) {

        $ximage->{_clip} = $clip;
        $ximage->{_note} = $ximage->{_note} . ' clip=' . $ximage->{_clip};
        $ximage->{_Step} = $ximage->{_Step} . ' clip=' . $ximage->{_clip};

    }
    else {
        print("ximage, clip, missing clip,\n");
    }
}

=head2 sub cmap 


=cut

sub cmap {

    my ( $self, $cmap ) = @_;
    if ( $cmap ne $empty_string ) {

        $ximage->{_cmap} = $cmap;
        $ximage->{_note} = $ximage->{_note} . ' cmap=' . $ximage->{_cmap};
        $ximage->{_Step} = $ximage->{_Step} . ' cmap=' . $ximage->{_cmap};

    }
    else {
        print("ximage, cmap, missing cmap,\n");
    }
}

=head2 sub curve 


=cut

sub curve {

    my ( $self, $curve ) = @_;
    if ( $curve ne $empty_string ) {

        $ximage->{_curve} = $curve;
        $ximage->{_note}  = $ximage->{_note} . ' curve=' . $ximage->{_curve};
        $ximage->{_Step}  = $ximage->{_Step} . ' curve=' . $ximage->{_curve};

    }
    else {
        print("ximage, curve, missing curve,\n");
    }
}

=head2 sub curvecolor 


=cut

sub curvecolor {

    my ( $self, $curvecolor ) = @_;
    if ( $curvecolor ne $empty_string ) {

        $ximage->{_curvecolor} = $curvecolor;
        $ximage->{_note} =
          $ximage->{_note} . ' curvecolor=' . $ximage->{_curvecolor};
        $ximage->{_Step} =
          $ximage->{_Step} . ' curvecolor=' . $ximage->{_curvecolor};

    }
    else {
        print("ximage, curvecolor, missing curvecolor,\n");
    }
}

=head2 sub curvefile 


=cut

sub curvefile {

    my ( $self, $curvefile ) = @_;
    if ( $curvefile ne $empty_string ) {

        $ximage->{_curvefile} = $curvefile;
        $ximage->{_note} =
          $ximage->{_note} . ' curvefile=' . $ximage->{_curvefile};
        $ximage->{_Step} =
          $ximage->{_Step} . ' curvefile=' . $ximage->{_curvefile};

    }
    else {
        print("ximage, curvefile, missing curvefile,\n");
    }
}

=head2 sub d1 


 subs d1 and dt and dz

 increment in fast dimension
 usually time and equal to dt


=cut

sub d1 {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $ximage->{_d1}   = $d1;
        $ximage->{_note} = $ximage->{_note} . ' d1=' . $ximage->{_d1};
        $ximage->{_Step} = $ximage->{_Step} . ' d1=' . $ximage->{_d1};

    }
    else {
        print("ximage, d1, missing d1,\n");
    }
}

=head2 sub d1num 


  subs d1num , y_tick_increment dy_major_divisions dt_major_divisions

  numbered tick interval in fast dimension(t)


=cut

sub d1num {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $ximage->{_d1num} = $d1num;
        $ximage->{_note}  = $ximage->{_note} . ' d1num=' . $ximage->{_d1num};
        $ximage->{_Step}  = $ximage->{_Step} . ' d1num=' . $ximage->{_d1num};

    }
    else {
        print("ximage, d1num, missing d1num,\n");
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

        $ximage->{_d2}   = $d2;
        $ximage->{_note} = $ximage->{_note} . ' d2=' . $ximage->{_d2};
        $ximage->{_Step} = $ximage->{_Step} . ' d2=' . $ximage->{_d2};

    }
    else {
        print("ximage, d2, missing d2,\n");
    }
}

=head2 sub  dt_major_divisions

  subs d1num , y_tick_increment dy_major_divisions dt_major_divisions

  numbered tick interval in fast dimension(t)

=cut

sub dt_major_divisions {

    my ( $self, $d1num ) = @_;
    if ($d1num) {

        $ximage->{_d1num} = $d1num;
        $ximage->{_note}  = $ximage->{_note} . ' d1num=' . $ximage->{_d1num};
        $ximage->{_Step}  = $ximage->{_Step} . ' d1num=' . $ximage->{_d1num};

    }
    else {
        print("ximage, dt_major_divisions, missing dt_major_divisions,\n");
    }
}

=head2 sub dx 

     only the first trace is read in
     if an increment is not 1 between traces
     you should indicate here

=cut

sub dx {

    my ( $self, $d2 ) = @_;
    if ($d2) {

        $ximage->{_d2}   = $d2;
        $ximage->{_note} = $ximage->{_note} . ' d2=' . $ximage->{_d2};
        $ximage->{_Step} = $ximage->{_Step} . ' d2=' . $ximage->{_d2};

    }
    else {
        print("ximage, dx, missing dx,\n");
    }
}

=head2 sub  dy_major_divisions

  subs d1num , y_tick_increment dy_major_divisions dt_major_divisions

  numbered tick interval in fast dimension(t)

=cut

sub dy_major_divisions {

    my ( $self, $d1num ) = @_;
    if ($d1num) {

        $ximage->{_d1num} = $d1num;
        $ximage->{_note}  = $ximage->{_note} . ' d1num=' . $ximage->{_d1num};
        $ximage->{_Step}  = $ximage->{_Step} . ' d1num=' . $ximage->{_d1num};

    }
    else {
        print("ximage, dy_major_divisions, missing dy_major_divisions,\n");
    }
}

=head2 sub d2num 

	subs d2num  dx_major_divisions and x_tick_increment
    numbered tick interval


=cut

sub d2num {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $ximage->{_d2num} = $d2num;
        $ximage->{_note}  = $ximage->{_note} . ' d2num=' . $ximage->{_d2num};
        $ximage->{_Step}  = $ximage->{_Step} . ' d2num=' . $ximage->{_d2num};

    }
    else {
        print("ximage, d2num, missing d2num,\n");
    }
}

=head2 sub dt 

 subs d1 and dt and dz

 increment in fast dimension
 usually time and equal to dt

=cut

sub dt {

    my ( $self, $d1 ) = @_;
    if ($d1) {

        $ximage->{_d1}   = $d1;
        $ximage->{_note} = $ximage->{_note} . ' d1=' . $ximage->{_d1};
        $ximage->{_Step} = $ximage->{_Step} . ' d1=' . $ximage->{_d1};

    }
    else {
        print("ximage, dt, missing dt,\n");
    }
}

=head2 sub dx_major_divisions

 	subs d2num  dx_major_divisions and x_tick_increment
	numbered tick interval

=cut

sub dx_major_divisions {

    my ( $self, $d2num ) = @_;
    if ($d2num) {

        $ximage->{_d2num} = $d2num;
        $ximage->{_note}  = $ximage->{_note} . ' d2num=' . $ximage->{_d2num};
        $ximage->{_Step}  = $ximage->{_Step} . ' d2num=' . $ximage->{_d2num};

    }
    else {
        print("ximage, dx_major_divisions, missing dx_major_divisions,\n");
    }
}

=head2 sub dy_minor_divisions 

 subs dy_minor_divisions n1tic and num_minor_ticks_betw_time_ticks 

 n1tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)	


=cut

sub dy_minor_divisions {

    my ( $self, $n1tic ) = @_;
    if ($n1tic) {

        $ximage->{_n1tic} = $n1tic;
        $ximage->{_note}  = $ximage->{_note} . ' n1tic=' . $ximage->{_n1tic};
        $ximage->{_Step}  = $ximage->{_Step} . ' n1tic=' . $ximage->{_n1tic};

    }
    else {
        print("ximage, dy_minor_divisions, missing dy_minor_divisions,\n");
    }
}

=head2 sub dz 

 subs d1 and dt and dz

 increment in fast dimension
 usually time and equal to dt

=cut

sub dz {

    my ( $self, $d1 ) = @_;
    if ($d1) {

        $ximage->{_d1}   = $d1;
        $ximage->{_note} = $ximage->{_note} . ' d1=' . $ximage->{_d1};
        $ximage->{_Step} = $ximage->{_Step} . ' d1=' . $ximage->{_d1};

    }
    else {
        print("ximage, dz, missing dz,\n");
    }
}

=head2 sub f1 

subs f1, first_time_sample_value and first_y

 value of the first sample tihat is use

=cut

sub f1 {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $ximage->{_f1}   = $f1;
        $ximage->{_note} = $ximage->{_note} . ' f1=' . $ximage->{_f1};
        $ximage->{_Step} = $ximage->{_Step} . ' f1=' . $ximage->{_f1};

    }
    else {
        print("ximage, f1, missing f1,\n");
    }
}

=head2 sub f1num 

subs f1num first_time_tick_num

   first tick number in the
   fast dimension (e.g., time)

=cut

sub f1num {

    my ( $self, $f1num ) = @_;
    if ( $f1num ne $empty_string ) {

        $ximage->{_f1num} = $f1num;
        $ximage->{_note}  = $ximage->{_note} . ' f1num=' . $ximage->{_f1num};
        $ximage->{_Step}  = $ximage->{_Step} . ' f1num=' . $ximage->{_f1num};

    }
    else {
        print("ximage, f1num, missing f1num,\n");
    }
}

=head2 sub f2 

 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)

=cut

sub f2 {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $ximage->{_f2}   = $f2;
        $ximage->{_note} = $ximage->{_note} . ' f2=' . $ximage->{_f2};
        $ximage->{_Step} = $ximage->{_Step} . ' f2=' . $ximage->{_f2};

    }
    else {
        print("ximage, f2, missing f2,\n");
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

        $ximage->{_f2num} = $f2num;
        $ximage->{_note}  = $ximage->{_note} . ' f2num=' . $ximage->{_f2num};
        $ximage->{_Step}  = $ximage->{_Step} . ' f2num=' . $ximage->{_f2num};

    }
    else {
        print("ximage, f2num, missing f2num,\n");
    }
}

=head2 sub first_distance_sample_value  

 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)

=cut

sub first_distance_sample_value {

    my ( $self, $f2 ) = @_;
    if ($f2) {

        $ximage->{_f2}   = $f2;
        $ximage->{_note} = $ximage->{_note} . ' f2=' . $ximage->{_f2};
        $ximage->{_Step} = $ximage->{_Step} . ' f2=' . $ximage->{_f2};

    }
    else {
        print(
"ximage, first_distance_sample_value , missing first_distance_sample_value ,\n"
        );
    }
}

=head2 sub first_x  

 subs f2 and first_distance_sample_value first_x

 value of the first sample tihat is used

 first value in the second dimension (X)

=cut

sub first_x {

    my ( $self, $f2 ) = @_;
    if ($f2) {

        $ximage->{_f2}   = $f2;
        $ximage->{_note} = $ximage->{_note} . ' f2=' . $ximage->{_f2};
        $ximage->{_Step} = $ximage->{_Step} . ' f2=' . $ximage->{_f2};

    }
    else {
        print("ximage, first_x , missing first_x ,\n");
    }
}

=head2 sub first_distance_tick_num

	subs f2num first_distance_tick_num

   first tick number in the
   slow dimension (distance)

=cut

sub first_distance_tick_num {
    my ( $variable, $f2num ) = @_;
    if ($f2num) {
        $ximage->{_f2num} = $f2num;
        $ximage->{_Step}  = $ximage->{_Step} . ' f2num=' . $ximage->{_f2num};
        $ximage->{_note}  = $ximage->{_note} . ' f2num=' . $ximage->{_f2num};
    }
}

=head2 sub first_tick_number_x 

subs f2num first_tick_number_x

   first tick number in the
   slow dimension (e.g., distance)

=cut

sub first_tick_number_x {

    my ( $self, $f2num ) = @_;
    if ($f2num) {

        $ximage->{_f2num} = $f2num;
        $ximage->{_note}  = $ximage->{_note} . ' f2num=' . $ximage->{_f2num};
        $ximage->{_Step}  = $ximage->{_Step} . ' f2num=' . $ximage->{_f2num};

    }
    else {
        print("ximage, first_tick_number_x, missing first_tick_number_x,\n");
    }
}

=head2 sub first_time_sample_value 

subs f1, first_time_sample_value and first_y

 value of the first sample tihat is use

=cut

sub first_time_sample_value {

    my ( $self, $f1 ) = @_;
    if ($f1) {

        $ximage->{_f1}   = $f1;
        $ximage->{_note} = $ximage->{_note} . ' f1=' . $ximage->{_f1};
        $ximage->{_Step} = $ximage->{_Step} . ' f1=' . $ximage->{_f1};

    }
    else {
        print(
"ximage, first_time_sample_value, missing first_time_sample_value,\n"
        );
    }
}

=head2 sub first_time_tick_num 

subs f1num first_time_tick_num

   first tick number in the
   fast dimension (e.g., time)

=cut

sub first_time_tick_num {

    my ( $self, $f1num ) = @_;
    if ($f1num) {

        $ximage->{_f1num} = $f1num;
        $ximage->{_note}  = $ximage->{_note} . ' f1num=' . $ximage->{_f1num};
        $ximage->{_Step}  = $ximage->{_Step} . ' f1num=' . $ximage->{_f1num};

    }
    else {
        print("ximage, first_time_tick_num, missing first_time_tick_num,\n");
    }
}

=head2 sub first_y 

subs f1, first_time_sample_value and first_y

 value of the first sample that is used

=cut

sub first_y {

    my ( $self, $f1 ) = @_;
    if ($f1) {

        $ximage->{_f1}   = $f1;
        $ximage->{_note} = $ximage->{_note} . ' f1=' . $ximage->{_f1};
        $ximage->{_Step} = $ximage->{_Step} . ' f1=' . $ximage->{_f1};

    }
    else {
        print("ximage, first_y, missing first_y,\n");
    }
}

=head2 sub grid1 


=cut

sub grid1 {

    my ( $self, $grid1 ) = @_;
    if ( $grid1 ne $empty_string ) {

        $ximage->{_grid1} = $grid1;
        $ximage->{_note}  = $ximage->{_note} . ' grid1=' . $ximage->{_grid1};
        $ximage->{_Step}  = $ximage->{_Step} . ' grid1=' . $ximage->{_grid1};

    }
    else {
        print("ximage, grid1, missing grid1,\n");
    }
}

=head2 sub grid2 


=cut

sub grid2 {

    my ( $self, $grid2 ) = @_;
    if ( $grid2 ne $empty_string ) {

        $ximage->{_grid2} = $grid2;
        $ximage->{_note}  = $ximage->{_note} . ' grid2=' . $ximage->{_grid2};
        $ximage->{_Step}  = $ximage->{_Step} . ' grid2=' . $ximage->{_grid2};

    }
    else {
        print("ximage, grid2, missing grid2,\n");
    }
}

=head2 sub gridcolor 


=cut

sub gridcolor {

    my ( $self, $gridcolor ) = @_;
    if ( $gridcolor ne $empty_string ) {

        $ximage->{_gridcolor} = $gridcolor;
        $ximage->{_note} =
          $ximage->{_note} . ' gridcolor=' . $ximage->{_gridcolor};
        $ximage->{_Step} =
          $ximage->{_Step} . ' gridcolor=' . $ximage->{_gridcolor};

    }
    else {
        print("ximage, gridcolor, missing gridcolor,\n");
    }
}

=head2 sub hbox 


=cut

sub hbox {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $ximage->{_hbox} = $hbox;
        $ximage->{_note} = $ximage->{_note} . ' hbox=' . $ximage->{_hbox};
        $ximage->{_Step} = $ximage->{_Step} . ' hbox=' . $ximage->{_hbox};

    }
    else {
        print("ximage, hbox, missing hbox,\n");
    }
}

=head2 sub hilip 

 subs hiclip wclip

=cut

sub hiclip {

    my ( $self, $wclip ) = @_;
    if ($wclip) {

        $ximage->{_wclip} = $wclip;
        $ximage->{_note}  = $ximage->{_note} . ' wclip=' . $ximage->{_wclip};
        $ximage->{_Step}  = $ximage->{_Step} . ' wclip=' . $ximage->{_wclip};

    }
    else {
        print("ximage, hilip, missing hilip,\n");
    }
}

=head2 sub label1 

subs xlabel or label2  ylabel or label1

=cut

sub label1 {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $ximage->{_label1} = $label1;
        $ximage->{_note}   = $ximage->{_note} . ' label1=' . $ximage->{_label1};
        $ximage->{_Step}   = $ximage->{_Step} . ' label1=' . $ximage->{_label1};

    }
    else {
        print("ximage, label1, missing label1,\n");
    }
}

=head2 sub label2 

subs xlabel or label2  ylabel or label1

=cut

sub label2 {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $ximage->{_label2} = $label2;
        $ximage->{_note}   = $ximage->{_note} . ' label2=' . $ximage->{_label2};
        $ximage->{_Step}   = $ximage->{_Step} . ' label2=' . $ximage->{_label2};

    }
    else {
        print("ximage, label2, missing label2,\n");
    }
}

=head2 sub labelcolor 


=cut

sub labelcolor {

    my ( $self, $labelcolor ) = @_;
    if ( $labelcolor ne $empty_string ) {

        $ximage->{_labelcolor} = $labelcolor;
        $ximage->{_note} =
          $ximage->{_note} . ' labelcolor=' . $ximage->{_labelcolor};
        $ximage->{_Step} =
          $ximage->{_Step} . ' labelcolor=' . $ximage->{_labelcolor};

    }
    else {
        print("ximage, labelcolor, missing labelcolor,\n");
    }
}

=head2 sub labelfont 


=cut

sub labelfont {

    my ( $self, $labelfont ) = @_;
    if ( $labelfont ne $empty_string ) {

        $ximage->{_labelfont} = $labelfont;
        $ximage->{_note} =
          $ximage->{_note} . ' labelfont=' . $ximage->{_labelfont};
        $ximage->{_Step} =
          $ximage->{_Step} . ' labelfont=' . $ximage->{_labelfont};

    }
    else {
        print("ximage, labelfont, missing labelfont,\n");
    }
}

=head2 sub legend 


=cut

sub legend {

    my ( $self, $legend ) = @_;
    if ( $legend ne $empty_string ) {

        $ximage->{_legend} = $legend;
        $ximage->{_note}   = $ximage->{_note} . ' legend=' . $ximage->{_legend};
        $ximage->{_Step}   = $ximage->{_Step} . ' legend=' . $ximage->{_legend};

    }
    else {
        print("ximage, legend, missing legend,\n");
    }
}

=head2 sub legendfont 


=cut

sub legendfont {

    my ( $self, $legendfont ) = @_;
    if ( $legendfont ne $empty_string ) {

        $ximage->{_legendfont} = $legendfont;
        $ximage->{_note} =
          $ximage->{_note} . ' legendfont=' . $ximage->{_legendfont};
        $ximage->{_Step} =
          $ximage->{_Step} . ' legendfont=' . $ximage->{_legendfont};

    }
    else {
        print("ximage, legendfont, missing legendfont,\n");
    }
}

=head2 sub lheight 


=cut

sub lheight {

    my ( $self, $lheight ) = @_;
    if ( $lheight ne $empty_string ) {

        $ximage->{_lheight} = $lheight;
        $ximage->{_note} =
          $ximage->{_note} . ' lheight=' . $ximage->{_lheight};
        $ximage->{_Step} =
          $ximage->{_Step} . ' lheight=' . $ximage->{_lheight};

    }
    else {
        print("ximage, lheight, missing lheight,\n");
    }
}

=head2 sub lwidth 


=cut

sub lwidth {

    my ( $self, $lwidth ) = @_;
    if ( $lwidth ne $empty_string ) {

        $ximage->{_lwidth} = $lwidth;
        $ximage->{_note}   = $ximage->{_note} . ' lwidth=' . $ximage->{_lwidth};
        $ximage->{_Step}   = $ximage->{_Step} . ' lwidth=' . $ximage->{_lwidth};

    }
    else {
        print("ximage, lwidth, missing lwidth,\n");
    }
}

=head2 sub loclip 

	subs loclip bclip

=cut

sub loclip {

    my ( $self, $bclip ) = @_;
    if ($bclip) {

        $ximage->{_bclip} = $bclip;
        $ximage->{_note}  = $ximage->{_note} . ' bclip=' . $ximage->{_bclip};
        $ximage->{_Step}  = $ximage->{_Step} . ' bclip=' . $ximage->{_bclip};

    }
    else {
        print("ximage, lolip, missing lolip,\n");
    }
}

=head2 sub lx 


=cut

sub lx {

    my ( $self, $lx ) = @_;
    if ( $lx ne $empty_string ) {

        $ximage->{_lx}   = $lx;
        $ximage->{_note} = $ximage->{_note} . ' lx=' . $ximage->{_lx};
        $ximage->{_Step} = $ximage->{_Step} . ' lx=' . $ximage->{_lx};

    }
    else {
        print("ximage, lx, missing lx,\n");
    }
}

=head2 sub ly 


=cut

sub ly {

    my ( $self, $ly ) = @_;
    if ( $ly ne $empty_string ) {

        $ximage->{_ly}   = $ly;
        $ximage->{_note} = $ximage->{_note} . ' ly=' . $ximage->{_ly};
        $ximage->{_Step} = $ximage->{_Step} . ' ly=' . $ximage->{_ly};

    }
    else {
        print("ximage, ly, missing ly,\n");
    }
}

=head2 sub mpicks 

 sub mpicks picks
    automatically generates a pick file

=cut

sub mpicks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        $ximage->{_mpicks} = $mpicks;
        $ximage->{_note}   = $ximage->{_note} . ' mpicks=' . $ximage->{_mpicks};
        $ximage->{_Step}   = $ximage->{_Step} . ' mpicks=' . $ximage->{_mpicks};

    }
    else {
        print("ximage, mpicks, missing mpicks,\n");
    }
}

=head2 sub n1 

n1			 number of samples in 1st (fast) dimension	


=cut

sub n1 {

    my ( $self, $n1 ) = @_;
    if ( $n1 ne $empty_string ) {

        $ximage->{_n1}   = $n1;
        $ximage->{_note} = $ximage->{_note} . ' n1=' . $ximage->{_n1};
        $ximage->{_Step} = $ximage->{_Step} . ' n1=' . $ximage->{_n1};

    }
    else {
        print("ximage, n1, missing n1,\n");
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

        $ximage->{_n1tic} = $n1tic;
        $ximage->{_note}  = $ximage->{_note} . ' n1tic=' . $ximage->{_n1tic};
        $ximage->{_Step}  = $ximage->{_Step} . ' n1tic=' . $ximage->{_n1tic};

    }
    else {
        print("ximage, n1tic, missing n1tic,\n");
    }
}

=head2 sub n2 


=cut

sub n2 {

    my ( $self, $n2 ) = @_;
    if ( $n2 ne $empty_string ) {

        $ximage->{_n2}   = $n2;
        $ximage->{_note} = $ximage->{_note} . ' n2=' . $ximage->{_n2};
        $ximage->{_Step} = $ximage->{_Step} . ' n2=' . $ximage->{_n2};

    }
    else {
        print("ximage, n2, missing n2,\n");
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

        $ximage->{_n2tic} = $n2tic;
        $ximage->{_note}  = $ximage->{_note} . ' n2tic=' . $ximage->{_n2tic};
        $ximage->{_Step}  = $ximage->{_Step} . ' n2tic=' . $ximage->{_n2tic};

    }
    else {
        print("ximage, n2tic, missing n2tic,\n");
    }
}

=head2 sub npair 

 number of T-Vel pairs

=cut

sub npair {

    my ( $self, $npair ) = @_;
    if ( $npair ne $empty_string ) {

        $ximage->{_npair} = $npair;
        $ximage->{_note}  = $ximage->{_note} . ' npair=' . $ximage->{_npair};
        $ximage->{_Step}  = $ximage->{_Step} . ' npair=' . $ximage->{_npair};

    }
    else {
        print("ximage, npair, missing npair,\n");
    }
}

=head2 sub num_minor_ticks_betw_distance_ticks 

subs n2tic and num_minor_ticks_betw_distance_ticks

 n2tic=1 number of minor ticks shwon between each
   of the numbered ticks on axis 1 (usually time and pointing down)	


=cut

sub num_minor_ticks_betw_distance_ticks {

    my ( $self, $n2tic ) = @_;
    if ($n2tic) {

        $ximage->{_n2tic} = $n2tic;
        $ximage->{_note}  = $ximage->{_note} . ' n2tic=' . $ximage->{_n2tic};
        $ximage->{_Step}  = $ximage->{_Step} . ' n2tic=' . $ximage->{_n2tic};

    }
    else {
        print(
"ximage, num_minor_ticks_betw_distance_ticks, missing num_minor_ticks_betw_distance_ticks,\n"
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
    if ($n1tic) {

        $ximage->{_n1tic} = $n1tic;
        $ximage->{_note}  = $ximage->{_note} . ' n1tic=' . $ximage->{_n1tic};
        $ximage->{_Step}  = $ximage->{_Step} . ' n1tic=' . $ximage->{_n1tic};

    }
    else {
        print(
"ximage, num_minor_ticks_betw_time_ticks, missing num_minor_ticks_betw_time_ticks,\n"
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
    if ($style) {

        $ximage->{_style} = $style;
        $ximage->{_note}  = $ximage->{_note} . ' style=' . $ximage->{_style};
        $ximage->{_Step}  = $ximage->{_Step} . ' style=' . $ximage->{_style};

    }
    else {
        print("ximage, orientation, missing orientation,\n");
    }
}

=head2 sub perc 


=cut

sub perc {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $ximage->{_perc} = $perc;
        $ximage->{_note} = $ximage->{_note} . ' perc=' . $ximage->{_perc};
        $ximage->{_Step} = $ximage->{_Step} . ' perc=' . $ximage->{_perc};

    }
    else {
        print("ximage, perc, missing perc,\n");
    }
}

=head2 sub plotfile 


=cut

sub plotfile {

    my ( $self, $plotfile ) = @_;
    if ( $plotfile ne $empty_string ) {

        $ximage->{_plotfile} = $plotfile;
        $ximage->{_note} =
          $ximage->{_note} . ' plotfile=' . $ximage->{_plotfile};
        $ximage->{_Step} =
          $ximage->{_Step} . ' plotfile=' . $ximage->{_plotfile};

    }
    else {
        print("ximage, plotfile, missing plotfile,\n");
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

        $ximage->{_style} = $style;
        $ximage->{_note}  = $ximage->{_note} . ' style=' . $ximage->{_style};
        $ximage->{_Step}  = $ximage->{_Step} . ' style=' . $ximage->{_style};

    }
    else {
        print("ximage, style, missing style,\n");
    }
}

=head2 sub tend_s 

subs x1end and tend_s

  minimum value of yaxis (time usually) in seconds

=cut

sub tend_s {

    my ( $self, $x1end ) = @_;
    if ($x1end) {

        $ximage->{_x1end} = $x1end;
        $ximage->{_note}  = $ximage->{_note} . ' x1end=' . $ximage->{_x1end};
        $ximage->{_Step}  = $ximage->{_Step} . ' x1end=' . $ximage->{_x1end};

    }
    else {
        print("ximage, tend_s, missing tend_s,\n");
    }
}

=head2 sub title 

 sub title allows for a  graph title  at the top of the 
 window 


=cut

sub title {

    my ( $self, $title ) = @_;
    if ( $title ne $empty_string ) {

        $ximage->{_title} = $title;
        $ximage->{_note}  = $ximage->{_note} . ' title=' . $ximage->{_title};
        $ximage->{_Step}  = $ximage->{_Step} . ' title=' . $ximage->{_title};

    }
    else {
        print("ximage, title, missing title,\n");
    }
}

=head2 sub titlecolor 


=cut

sub titlecolor {

    my ( $self, $titlecolor ) = @_;
    if ( $titlecolor ne $empty_string ) {

        $ximage->{_titlecolor} = $titlecolor;
        $ximage->{_note} =
          $ximage->{_note} . ' titlecolor=' . $ximage->{_titlecolor};
        $ximage->{_Step} =
          $ximage->{_Step} . ' titlecolor=' . $ximage->{_titlecolor};

    }
    else {
        print("ximage, titlecolor, missing titlecolor,\n");
    }
}

=head2 sub titlefont 


=cut

sub titlefont {

    my ( $self, $titlefont ) = @_;
    if ( $titlefont ne $empty_string ) {

        $ximage->{_titlefont} = $titlefont;
        $ximage->{_note} =
          $ximage->{_note} . ' titlefont=' . $ximage->{_titlefont};
        $ximage->{_Step} =
          $ximage->{_Step} . ' titlefont=' . $ximage->{_titlefont};

    }
    else {
        print("ximage, titlefont, missing titlefont,\n");
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
    if ($d2) {

        $ximage->{_d2}   = $d2;
        $ximage->{_note} = $ximage->{_note} . ' d2=' . $ximage->{_d2};
        $ximage->{_Step} = $ximage->{_Step} . ' d2=' . $ximage->{_d2};

    }
    else {
        print("ximage, trace_inc, missing trace_inc,\n");
    }
}

=head2 sub tstart_s 

subs x1beg and tstart_s

  minimum value of yaxis (time usually) in seconds

=cut

sub tstart_s {

    my ( $self, $x1beg ) = @_;
    if ($x1beg) {

        $ximage->{_x1beg} = $x1beg;
        $ximage->{_note}  = $ximage->{_note} . ' x1beg=' . $ximage->{_x1beg};
        $ximage->{_Step}  = $ximage->{_Step} . ' x1beg=' . $ximage->{_x1beg};

    }
    else {
        print("ximage, tstart_s, missing tstart_s,\n");
    }
}

=head2 sub units 


=cut

sub units {

    my ( $self, $units ) = @_;
    if ( $units ne $empty_string ) {

        $ximage->{_units} = $units;
        $ximage->{_note}  = $ximage->{_note} . ' units=' . $ximage->{_units};
        $ximage->{_Step}  = $ximage->{_Step} . ' units=' . $ximage->{_units};

    }
    else {
        print("ximage, units, missing units,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $ximage->{_verbose} = $verbose;
        $ximage->{_note} =
          $ximage->{_note} . ' verbose=' . $ximage->{_verbose};
        $ximage->{_Step} =
          $ximage->{_Step} . ' verbose=' . $ximage->{_verbose};

    }
    else {
        print("ximage, verbose, missing verbose,\n");
    }
}

=head2 sub wbox 


=cut

sub wbox {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $ximage->{_wbox} = $wbox;
        $ximage->{_note} = $ximage->{_note} . ' wbox=' . $ximage->{_wbox};
        $ximage->{_Step} = $ximage->{_Step} . ' wbox=' . $ximage->{_wbox};

    }
    else {
        print("ximage, wbox, missing wbox,\n");
    }
}

=head2 sub wclip 


=cut

sub wclip {

    my ( $self, $wclip ) = @_;
    if ( $wclip ne $empty_string ) {

        $ximage->{_wclip} = $wclip;
        $ximage->{_note}  = $ximage->{_note} . ' wclip=' . $ximage->{_wclip};
        $ximage->{_Step}  = $ximage->{_Step} . ' wclip=' . $ximage->{_wclip};

    }
    else {
        print("ximage, wclip, missing wclip,\n");
    }
}

=head2 sub windowtitle 


=cut

sub windowtitle {

    my ( $self, $windowtitle ) = @_;
    if ( $windowtitle ne $empty_string ) {

        $ximage->{_windowtitle} = $windowtitle;
        $ximage->{_note} =
          $ximage->{_note} . ' windowtitle=' . $ximage->{_windowtitle};
        $ximage->{_Step} =
          $ximage->{_Step} . ' windowtitle=' . $ximage->{_windowtitle};

    }
    else {
        print("ximage, windowtitle, missing windowtitle,\n");
    }
}

=head2 sub wperc 


=cut

sub wperc {

    my ( $self, $wperc ) = @_;
    if ( $wperc ne $empty_string ) {

        $ximage->{_wperc} = $wperc;
        $ximage->{_note}  = $ximage->{_note} . ' wperc=' . $ximage->{_wperc};
        $ximage->{_Step}  = $ximage->{_Step} . ' wperc=' . $ximage->{_wperc};

    }
    else {
        print("ximage, wperc, missing wperc,\n");
    }
}

=head2 sub x1beg 

subs x1beg and tstart_s

  minimum value of yaxis (time usually) in seconds

=cut

sub x1beg {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $ximage->{_x1beg} = $x1beg;
        $ximage->{_note}  = $ximage->{_note} . ' x1beg=' . $ximage->{_x1beg};
        $ximage->{_Step}  = $ximage->{_Step} . ' x1beg=' . $ximage->{_x1beg};

    }
    else {
        print("ximage, x1beg, missing x1beg,\n");
    }
}

=head2 sub x1end 

subs x1end and tend_s

  minimum value of yaxis (time usually) in seconds


=cut

sub x1end {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $ximage->{_x1end} = $x1end;
        $ximage->{_note}  = $ximage->{_note} . ' x1end=' . $ximage->{_x1end};
        $ximage->{_Step}  = $ximage->{_Step} . ' x1end=' . $ximage->{_x1end};

    }
    else {
        print("ximage, x1end, missing x1end,\n");
    }
}

=head2 sub x2beg 

  subs x2beg and 

  minimum value of yaxis (time usually) in seconds

=cut

sub x2beg {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $ximage->{_x2beg} = $x2beg;
        $ximage->{_note}  = $ximage->{_note} . ' x2beg=' . $ximage->{_x2beg};
        $ximage->{_Step}  = $ximage->{_Step} . ' x2beg=' . $ximage->{_x2beg};

    }
    else {
        print("ximage, x2beg, missing x2beg,\n");
    }
}

=head2 sub x2end 

subs x2end and xend_m

  minimum value of yaxis (time usually) in seconds

=cut

sub x2end {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $ximage->{_x2end} = $x2end;
        $ximage->{_note}  = $ximage->{_note} . ' x2end=' . $ximage->{_x2end};
        $ximage->{_Step}  = $ximage->{_Step} . ' x2end=' . $ximage->{_x2end};

    }
    else {
        print("ximage, x2end, missing x2end,\n");
    }
}

=head2 sub xbox 


=cut

sub xbox {

    my ( $self, $xbox ) = @_;
    if ( $xbox ne $empty_string ) {

        $ximage->{_xbox} = $xbox;
        $ximage->{_note} = $ximage->{_note} . ' xbox=' . $ximage->{_xbox};
        $ximage->{_Step} = $ximage->{_Step} . ' xbox=' . $ximage->{_xbox};

    }
    else {
        print("ximage, xbox, missing xbox,\n");
    }
}

=head2 sub xend_m 

 subs x2end and xend_m

  minimum value of yaxis (time usually) in seconds

=cut

sub xend_m {

    my ( $self, $x2end ) = @_;
    if ($x2end) {

        $ximage->{_x2end} = $x2end;
        $ximage->{_note}  = $ximage->{_note} . ' x2end=' . $ximage->{_x2end};
        $ximage->{_Step}  = $ximage->{_Step} . ' x2end=' . $ximage->{_x2end};

    }
    else {
        print("ximage, xend_m, missing xend_m,\n");
    }
}

=head2 sub xlabel 

subs xlabel or label2  ylabel or label1

=cut

sub xlabel {

    my ( $self, $label2 ) = @_;
    if ($label2) {

        $ximage->{_label2} = $label2;
        $ximage->{_note}   = $ximage->{_note} . ' label2=' . $ximage->{_label2};
        $ximage->{_Step}   = $ximage->{_Step} . ' label2=' . $ximage->{_label2};

    }
    else {
        print("ximage, xlabel, missing xlabel,\n");
    }
}

=head2 sub xstart_m 

  subs x2beg and xstart_m

  minimum value of yaxis (time usually) in seconds

=cut

sub xstart_m {

    my ( $self, $x2beg ) = @_;
    if ($x2beg) {

        $ximage->{_x2beg} = $x2beg;
        $ximage->{_note}  = $ximage->{_note} . ' x2beg=' . $ximage->{_x2beg};
        $ximage->{_Step}  = $ximage->{_Step} . ' x2beg=' . $ximage->{_x2beg};

    }
    else {
        print("ximage, xstart_m, missing xstart_m,\n");
    }
}

=head2 sub x_tick_increment

 	subs d2num  dx_major_divisions and x_tick_increment
	numbered tick interval

=cut

sub x_tick_increment {

    my ( $self, $d2num ) = @_;
    if ($d2num) {

        $ximage->{_d2num} = $d2num;
        $ximage->{_note}  = $ximage->{_note} . ' d2num=' . $ximage->{_d2num};
        $ximage->{_Step}  = $ximage->{_Step} . ' d2num=' . $ximage->{_d2num};

    }
    else {
        print("ximage, dx_major_divisions, missing dx_major_divisions,\n");
    }
}

=head2 sub ybox 


=cut

sub ybox {

    my ( $self, $ybox ) = @_;
    if ( $ybox ne $empty_string ) {

        $ximage->{_ybox} = $ybox;
        $ximage->{_note} = $ximage->{_note} . ' ybox=' . $ximage->{_ybox};
        $ximage->{_Step} = $ximage->{_Step} . ' ybox=' . $ximage->{_ybox};

    }
    else {
        print("ximage, ybox, missing ybox,\n");
    }
}

=head2 sub ylabel

subs xlabel or label2  ylabel or label1

=cut

sub ylabel {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $ximage->{_label1} = $label1;
        $ximage->{_note}   = $ximage->{_note} . ' label1=' . $ximage->{_label1};
        $ximage->{_Step}   = $ximage->{_Step} . ' label1=' . $ximage->{_label1};

    }
    else {
        print("ximage, ylabel, missing ylabel,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 55;

    return ($max_index);
}

1;
