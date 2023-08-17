package App::SeismicUnixGui::sunix::plot::xwigb;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  XWIGB - X WIGgle-trace plot of f(x1,x2) via Bitmap			
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

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
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $xwigb = {
    _bias        => '',
    _clip        => '',
    _curve       => '',
    _curvecolor  => '',
    _curvefile   => '',
    _d1          => '',
    _d1num       => '',
    _d2          => '',
    _d2num       => '',
    _endian      => '',
    _f1          => '',
    _f1num       => '',
    _f2          => '',
    _f2num       => '',
    _grid1       => '',
    _grid2       => '',
    _gridcolor   => '',
    _hbox        => '',
    _interp      => '',
    _label2      => '',
    _labelcolor  => '',
    _labelfont   => '',
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
    _va          => '',
    _verbose     => '',
    _wbox        => '',
    _wigclip     => '',
    _windowtitle => '',
    _wt          => '',
    _x1beg       => '',
    _x1end       => '',
    _x2          => '',
    _x2beg       => '',
    _x2end       => '',
    _xbox        => '',
    _xcur        => '',
    _ybox        => '',
    _Step        => '',
    _note        => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

    $xwigb->{_Step} = 'xwigb' . $xwigb->{_Step};
    return ( $xwigb->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $xwigb->{_note} = 'xwigb' . $xwigb->{_note};
    return ( $xwigb->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $xwigb->{_bias}        = '';
    $xwigb->{_clip}        = '';
    $xwigb->{_curve}       = '';
    $xwigb->{_curvecolor}  = '';
    $xwigb->{_curvefile}   = '';
    $xwigb->{_d1}          = '';
    $xwigb->{_d1num}       = '';
    $xwigb->{_d2}          = '';
    $xwigb->{_d2num}       = '';
    $xwigb->{_endian}      = '';
    $xwigb->{_f1}          = '';
    $xwigb->{_f1num}       = '';
    $xwigb->{_f2}          = '';
    $xwigb->{_f2num}       = '';
    $xwigb->{_grid1}       = '';
    $xwigb->{_grid2}       = '';
    $xwigb->{_gridcolor}   = '';
    $xwigb->{_hbox}        = '';
    $xwigb->{_interp}      = '';
    $xwigb->{_label2}      = '';
    $xwigb->{_labelcolor}  = '';
    $xwigb->{_labelfont}   = '';
    $xwigb->{_mpicks}      = '';
    $xwigb->{_n1}          = '';
    $xwigb->{_n1tic}       = '';
    $xwigb->{_n2}          = '';
    $xwigb->{_n2tic}       = '';
    $xwigb->{_npair}       = '';
    $xwigb->{_perc}        = '';
    $xwigb->{_plotfile}    = '';
    $xwigb->{_style}       = '';
    $xwigb->{_title}       = '';
    $xwigb->{_titlecolor}  = '';
    $xwigb->{_titlefont}   = '';
    $xwigb->{_va}          = '';
    $xwigb->{_verbose}     = '';
    $xwigb->{_wbox}        = '';
    $xwigb->{_wigclip}     = '';
    $xwigb->{_windowtitle} = '';
    $xwigb->{_wt}          = '';
    $xwigb->{_x1beg}       = '';
    $xwigb->{_x1end}       = '';
    $xwigb->{_x2}          = '';
    $xwigb->{_x2beg}       = '';
    $xwigb->{_x2end}       = '';
    $xwigb->{_xbox}        = '';
    $xwigb->{_xcur}        = '';
    $xwigb->{_ybox}        = '';
    $xwigb->{_Step}        = '';
    $xwigb->{_note}        = '';
}

=head2 sub bias 


=cut

sub bias {

    my ( $self, $bias ) = @_;
    if ( $bias ne $empty_string ) {

        $xwigb->{_bias} = $bias;
        $xwigb->{_note} = $xwigb->{_note} . ' bias=' . $xwigb->{_bias};
        $xwigb->{_Step} = $xwigb->{_Step} . ' bias=' . $xwigb->{_bias};

    }
    else {
        print("xwigb, bias, missing bias,\n");
    }
}

=head2 sub clip 


=cut

sub clip {

    my ( $self, $clip ) = @_;
    if ( $clip ne $empty_string ) {

        $xwigb->{_clip} = $clip;
        $xwigb->{_note} = $xwigb->{_note} . ' clip=' . $xwigb->{_clip};
        $xwigb->{_Step} = $xwigb->{_Step} . ' clip=' . $xwigb->{_clip};

    }
    else {
        print("xwigb, clip, missing clip,\n");
    }
}

=head2 sub curve 


=cut

sub curve {

    my ( $self, $curve ) = @_;
    if ( $curve ne $empty_string ) {

        $xwigb->{_curve} = $curve;
        $xwigb->{_note}  = $xwigb->{_note} . ' curve=' . $xwigb->{_curve};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' curve=' . $xwigb->{_curve};

    }
    else {
        print("xwigb, curve, missing curve,\n");
    }
}

=head2 sub curvecolor 


=cut

sub curvecolor {

    my ( $self, $curvecolor ) = @_;
    if ( $curvecolor ne $empty_string ) {

        $xwigb->{_curvecolor} = $curvecolor;
        $xwigb->{_note} =
          $xwigb->{_note} . ' curvecolor=' . $xwigb->{_curvecolor};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' curvecolor=' . $xwigb->{_curvecolor};

    }
    else {
        print("xwigb, curvecolor, missing curvecolor,\n");
    }
}

=head2 sub curvefile 


=cut

sub curvefile {

    my ( $self, $curvefile ) = @_;
    if ( $curvefile ne $empty_string ) {

        $xwigb->{_curvefile} = $curvefile;
        $xwigb->{_note} =
          $xwigb->{_note} . ' curvefile=' . $xwigb->{_curvefile};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' curvefile=' . $xwigb->{_curvefile};

    }
    else {
        print("xwigb, curvefile, missing curvefile,\n");
    }
}

=head2 sub d1 


=cut

sub d1 {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $xwigb->{_d1}   = $d1;
        $xwigb->{_note} = $xwigb->{_note} . ' d1=' . $xwigb->{_d1};
        $xwigb->{_Step} = $xwigb->{_Step} . ' d1=' . $xwigb->{_d1};

    }
    else {
        print("xwigb, d1, missing d1,\n");
    }
}

=head2 sub d1num 


=cut

sub d1num {

    my ( $self, $d1num ) = @_;
    if ( $d1num ne $empty_string ) {

        $xwigb->{_d1num} = $d1num;
        $xwigb->{_note}  = $xwigb->{_note} . ' d1num=' . $xwigb->{_d1num};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' d1num=' . $xwigb->{_d1num};

    }
    else {
        print("xwigb, d1num, missing d1num,\n");
    }
}

=head2 sub d2 


=cut

sub d2 {

    my ( $self, $d2 ) = @_;
    if ( $d2 ne $empty_string ) {

        $xwigb->{_d2}   = $d2;
        $xwigb->{_note} = $xwigb->{_note} . ' d2=' . $xwigb->{_d2};
        $xwigb->{_Step} = $xwigb->{_Step} . ' d2=' . $xwigb->{_d2};

    }
    else {
        print("xwigb, d2, missing d2,\n");
    }
}

=head2 sub d2num 


=cut

sub d2num {

    my ( $self, $d2num ) = @_;
    if ( $d2num ne $empty_string ) {

        $xwigb->{_d2num} = $d2num;
        $xwigb->{_note}  = $xwigb->{_note} . ' d2num=' . $xwigb->{_d2num};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' d2num=' . $xwigb->{_d2num};

    }
    else {
        print("xwigb, d2num, missing d2num,\n");
    }
}

=head2 sub endian 


=cut

sub endian {

    my ( $self, $endian ) = @_;
    if ( $endian ne $empty_string ) {

        $xwigb->{_endian} = $endian;
        $xwigb->{_note}   = $xwigb->{_note} . ' endian=' . $xwigb->{_endian};
        $xwigb->{_Step}   = $xwigb->{_Step} . ' endian=' . $xwigb->{_endian};

    }
    else {
        print("xwigb, endian, missing endian,\n");
    }
}

=head2 sub f1 


=cut

sub f1 {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $xwigb->{_f1}   = $f1;
        $xwigb->{_note} = $xwigb->{_note} . ' f1=' . $xwigb->{_f1};
        $xwigb->{_Step} = $xwigb->{_Step} . ' f1=' . $xwigb->{_f1};

    }
    else {
        print("xwigb, f1, missing f1,\n");
    }
}

=head2 sub f1num 


=cut

sub f1num {

    my ( $self, $f1num ) = @_;
    if ( $f1num ne $empty_string ) {

        $xwigb->{_f1num} = $f1num;
        $xwigb->{_note}  = $xwigb->{_note} . ' f1num=' . $xwigb->{_f1num};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' f1num=' . $xwigb->{_f1num};

    }
    else {
        print("xwigb, f1num, missing f1num,\n");
    }
}

=head2 sub f2 


=cut

sub f2 {

    my ( $self, $f2 ) = @_;
    if ( $f2 ne $empty_string ) {

        $xwigb->{_f2}   = $f2;
        $xwigb->{_note} = $xwigb->{_note} . ' f2=' . $xwigb->{_f2};
        $xwigb->{_Step} = $xwigb->{_Step} . ' f2=' . $xwigb->{_f2};

    }
    else {
        print("xwigb, f2, missing f2,\n");
    }
}

=head2 sub f2num 


=cut

sub f2num {

    my ( $self, $f2num ) = @_;
    if ( $f2num ne $empty_string ) {

        $xwigb->{_f2num} = $f2num;
        $xwigb->{_note}  = $xwigb->{_note} . ' f2num=' . $xwigb->{_f2num};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' f2num=' . $xwigb->{_f2num};

    }
    else {
        print("xwigb, f2num, missing f2num,\n");
    }
}

=head2 sub grid1 


=cut

sub grid1 {

    my ( $self, $grid1 ) = @_;
    if ( $grid1 ne $empty_string ) {

        $xwigb->{_grid1} = $grid1;
        $xwigb->{_note}  = $xwigb->{_note} . ' grid1=' . $xwigb->{_grid1};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' grid1=' . $xwigb->{_grid1};

    }
    else {
        print("xwigb, grid1, missing grid1,\n");
    }
}

=head2 sub grid2 


=cut

sub grid2 {

    my ( $self, $grid2 ) = @_;
    if ( $grid2 ne $empty_string ) {

        $xwigb->{_grid2} = $grid2;
        $xwigb->{_note}  = $xwigb->{_note} . ' grid2=' . $xwigb->{_grid2};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' grid2=' . $xwigb->{_grid2};

    }
    else {
        print("xwigb, grid2, missing grid2,\n");
    }
}

=head2 sub gridcolor 


=cut

sub gridcolor {

    my ( $self, $gridcolor ) = @_;
    if ( $gridcolor ne $empty_string ) {

        $xwigb->{_gridcolor} = $gridcolor;
        $xwigb->{_note} =
          $xwigb->{_note} . ' gridcolor=' . $xwigb->{_gridcolor};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' gridcolor=' . $xwigb->{_gridcolor};

    }
    else {
        print("xwigb, gridcolor, missing gridcolor,\n");
    }
}

=head2 sub hbox 


=cut

sub hbox {

    my ( $self, $hbox ) = @_;
    if ( $hbox ne $empty_string ) {

        $xwigb->{_hbox} = $hbox;
        $xwigb->{_note} = $xwigb->{_note} . ' hbox=' . $xwigb->{_hbox};
        $xwigb->{_Step} = $xwigb->{_Step} . ' hbox=' . $xwigb->{_hbox};

    }
    else {
        print("xwigb, hbox, missing hbox,\n");
    }
}

=head2 sub interp 


=cut

sub interp {

    my ( $self, $interp ) = @_;
    if ( $interp ne $empty_string ) {

        $xwigb->{_interp} = $interp;
        $xwigb->{_note}   = $xwigb->{_note} . ' interp=' . $xwigb->{_interp};
        $xwigb->{_Step}   = $xwigb->{_Step} . ' interp=' . $xwigb->{_interp};

    }
    else {
        print("xwigb, interp, missing interp,\n");
    }
}

=head2 sub label2 


=cut

sub label2 {

    my ( $self, $label2 ) = @_;
    if ( $label2 ne $empty_string ) {

        $xwigb->{_label2} = $label2;
        $xwigb->{_note}   = $xwigb->{_note} . ' label2=' . $xwigb->{_label2};
        $xwigb->{_Step}   = $xwigb->{_Step} . ' label2=' . $xwigb->{_label2};

    }
    else {
        print("xwigb, label2, missing label2,\n");
    }
}

=head2 sub labelcolor 


=cut

sub labelcolor {

    my ( $self, $labelcolor ) = @_;
    if ( $labelcolor ne $empty_string ) {

        $xwigb->{_labelcolor} = $labelcolor;
        $xwigb->{_note} =
          $xwigb->{_note} . ' labelcolor=' . $xwigb->{_labelcolor};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' labelcolor=' . $xwigb->{_labelcolor};

    }
    else {
        print("xwigb, labelcolor, missing labelcolor,\n");
    }
}

=head2 sub labelfont 


=cut

sub labelfont {

    my ( $self, $labelfont ) = @_;
    if ( $labelfont ne $empty_string ) {

        $xwigb->{_labelfont} = $labelfont;
        $xwigb->{_note} =
          $xwigb->{_note} . ' labelfont=' . $xwigb->{_labelfont};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' labelfont=' . $xwigb->{_labelfont};

    }
    else {
        print("xwigb, labelfont, missing labelfont,\n");
    }
}

=head2 sub mpicks 


=cut

sub mpicks {

    my ( $self, $mpicks ) = @_;
    if ( $mpicks ne $empty_string ) {

        $xwigb->{_mpicks} = $mpicks;
        $xwigb->{_note}   = $xwigb->{_note} . ' mpicks=' . $xwigb->{_mpicks};
        $xwigb->{_Step}   = $xwigb->{_Step} . ' mpicks=' . $xwigb->{_mpicks};

    }
    else {
        print("xwigb, mpicks, missing mpicks,\n");
    }
}

=head2 sub n1 


=cut

sub n1 {

    my ( $self, $n1 ) = @_;
    if ( $n1 ne $empty_string ) {

        $xwigb->{_n1}   = $n1;
        $xwigb->{_note} = $xwigb->{_note} . ' n1=' . $xwigb->{_n1};
        $xwigb->{_Step} = $xwigb->{_Step} . ' n1=' . $xwigb->{_n1};

    }
    else {
        print("xwigb, n1, missing n1,\n");
    }
}

=head2 sub n1tic 


=cut

sub n1tic {

    my ( $self, $n1tic ) = @_;
    if ( $n1tic ne $empty_string ) {

        $xwigb->{_n1tic} = $n1tic;
        $xwigb->{_note}  = $xwigb->{_note} . ' n1tic=' . $xwigb->{_n1tic};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' n1tic=' . $xwigb->{_n1tic};

    }
    else {
        print("xwigb, n1tic, missing n1tic,\n");
    }
}

=head2 sub n2 


=cut

sub n2 {

    my ( $self, $n2 ) = @_;
    if ( $n2 ne $empty_string ) {

        $xwigb->{_n2}   = $n2;
        $xwigb->{_note} = $xwigb->{_note} . ' n2=' . $xwigb->{_n2};
        $xwigb->{_Step} = $xwigb->{_Step} . ' n2=' . $xwigb->{_n2};

    }
    else {
        print("xwigb, n2, missing n2,\n");
    }
}

=head2 sub n2tic 


=cut

sub n2tic {

    my ( $self, $n2tic ) = @_;
    if ( $n2tic ne $empty_string ) {

        $xwigb->{_n2tic} = $n2tic;
        $xwigb->{_note}  = $xwigb->{_note} . ' n2tic=' . $xwigb->{_n2tic};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' n2tic=' . $xwigb->{_n2tic};

    }
    else {
        print("xwigb, n2tic, missing n2tic,\n");
    }
}

=head2 sub npair 


=cut

sub npair {

    my ( $self, $npair ) = @_;
    if ( $npair ne $empty_string ) {

        $xwigb->{_npair} = $npair;
        $xwigb->{_note}  = $xwigb->{_note} . ' npair=' . $xwigb->{_npair};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' npair=' . $xwigb->{_npair};

    }
    else {
        print("xwigb, npair, missing npair,\n");
    }
}

=head2 sub perc 


=cut

sub perc {

    my ( $self, $perc ) = @_;
    if ( $perc ne $empty_string ) {

        $xwigb->{_perc} = $perc;
        $xwigb->{_note} = $xwigb->{_note} . ' perc=' . $xwigb->{_perc};
        $xwigb->{_Step} = $xwigb->{_Step} . ' perc=' . $xwigb->{_perc};

    }
    else {
        print("xwigb, perc, missing perc,\n");
    }
}

=head2 sub plotfile 


=cut

sub plotfile {

    my ( $self, $plotfile ) = @_;
    if ( $plotfile ne $empty_string ) {

        $xwigb->{_plotfile} = $plotfile;
        $xwigb->{_note} =
          $xwigb->{_note} . ' plotfile=' . $xwigb->{_plotfile};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' plotfile=' . $xwigb->{_plotfile};

    }
    else {
        print("xwigb, plotfile, missing plotfile,\n");
    }
}

=head2 sub style 


=cut

sub style {

    my ( $self, $style ) = @_;
    if ( $style ne $empty_string ) {

        $xwigb->{_style} = $style;
        $xwigb->{_note}  = $xwigb->{_note} . ' style=' . $xwigb->{_style};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' style=' . $xwigb->{_style};

    }
    else {
        print("xwigb, style, missing style,\n");
    }
}

=head2 sub title 


=cut

sub title {

    my ( $self, $title ) = @_;
    if ( $title ne $empty_string ) {

        $xwigb->{_title} = $title;
        $xwigb->{_note}  = $xwigb->{_note} . ' title=' . $xwigb->{_title};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' title=' . $xwigb->{_title};

    }
    else {
        print("xwigb, title, missing title,\n");
    }
}

=head2 sub titlecolor 


=cut

sub titlecolor {

    my ( $self, $titlecolor ) = @_;
    if ( $titlecolor ne $empty_string ) {

        $xwigb->{_titlecolor} = $titlecolor;
        $xwigb->{_note} =
          $xwigb->{_note} . ' titlecolor=' . $xwigb->{_titlecolor};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' titlecolor=' . $xwigb->{_titlecolor};

    }
    else {
        print("xwigb, titlecolor, missing titlecolor,\n");
    }
}

=head2 sub titlefont 


=cut

sub titlefont {

    my ( $self, $titlefont ) = @_;
    if ( $titlefont ne $empty_string ) {

        $xwigb->{_titlefont} = $titlefont;
        $xwigb->{_note} =
          $xwigb->{_note} . ' titlefont=' . $xwigb->{_titlefont};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' titlefont=' . $xwigb->{_titlefont};

    }
    else {
        print("xwigb, titlefont, missing titlefont,\n");
    }
}

=head2 sub va 


=cut

sub va {

    my ( $self, $va ) = @_;
    if ( $va ne $empty_string ) {

        $xwigb->{_va}   = $va;
        $xwigb->{_note} = $xwigb->{_note} . ' va=' . $xwigb->{_va};
        $xwigb->{_Step} = $xwigb->{_Step} . ' va=' . $xwigb->{_va};

    }
    else {
        print("xwigb, va, missing va,\n");
    }
}

=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $xwigb->{_verbose} = $verbose;
        $xwigb->{_note}    = $xwigb->{_note} . ' verbose=' . $xwigb->{_verbose};
        $xwigb->{_Step}    = $xwigb->{_Step} . ' verbose=' . $xwigb->{_verbose};

    }
    else {
        print("xwigb, verbose, missing verbose,\n");
    }
}

=head2 sub wbox 


=cut

sub wbox {

    my ( $self, $wbox ) = @_;
    if ( $wbox ne $empty_string ) {

        $xwigb->{_wbox} = $wbox;
        $xwigb->{_note} = $xwigb->{_note} . ' wbox=' . $xwigb->{_wbox};
        $xwigb->{_Step} = $xwigb->{_Step} . ' wbox=' . $xwigb->{_wbox};

    }
    else {
        print("xwigb, wbox, missing wbox,\n");
    }
}

=head2 sub wigclip 


=cut

sub wigclip {

    my ( $self, $wigclip ) = @_;
    if ( $wigclip ne $empty_string ) {

        $xwigb->{_wigclip} = $wigclip;
        $xwigb->{_note}    = $xwigb->{_note} . ' wigclip=' . $xwigb->{_wigclip};
        $xwigb->{_Step}    = $xwigb->{_Step} . ' wigclip=' . $xwigb->{_wigclip};

    }
    else {
        print("xwigb, wigclip, missing wigclip,\n");
    }
}

=head2 sub windowtitle 


=cut

sub windowtitle {

    my ( $self, $windowtitle ) = @_;
    if ( $windowtitle ne $empty_string ) {

        $xwigb->{_windowtitle} = $windowtitle;
        $xwigb->{_note} =
          $xwigb->{_note} . ' windowtitle=' . $xwigb->{_windowtitle};
        $xwigb->{_Step} =
          $xwigb->{_Step} . ' windowtitle=' . $xwigb->{_windowtitle};

    }
    else {
        print("xwigb, windowtitle, missing windowtitle,\n");
    }
}

=head2 sub wt 


=cut

sub wt {

    my ( $self, $wt ) = @_;
    if ( $wt ne $empty_string ) {

        $xwigb->{_wt}   = $wt;
        $xwigb->{_note} = $xwigb->{_note} . ' wt=' . $xwigb->{_wt};
        $xwigb->{_Step} = $xwigb->{_Step} . ' wt=' . $xwigb->{_wt};

    }
    else {
        print("xwigb, wt, missing wt,\n");
    }
}

=head2 sub x1beg 


=cut

sub x1beg {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $xwigb->{_x1beg} = $x1beg;
        $xwigb->{_note}  = $xwigb->{_note} . ' x1beg=' . $xwigb->{_x1beg};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' x1beg=' . $xwigb->{_x1beg};

    }
    else {
        print("xwigb, x1beg, missing x1beg,\n");
    }
}

=head2 sub x1end 


=cut

sub x1end {

    my ( $self, $x1end ) = @_;
    if ( $x1end ne $empty_string ) {

        $xwigb->{_x1end} = $x1end;
        $xwigb->{_note}  = $xwigb->{_note} . ' x1end=' . $xwigb->{_x1end};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' x1end=' . $xwigb->{_x1end};

    }
    else {
        print("xwigb, x1end, missing x1end,\n");
    }
}

=head2 sub x2 


=cut

sub x2 {

    my ( $self, $x2 ) = @_;
    if ( $x2 ne $empty_string ) {

        $xwigb->{_x2}   = $x2;
        $xwigb->{_note} = $xwigb->{_note} . ' x2=' . $xwigb->{_x2};
        $xwigb->{_Step} = $xwigb->{_Step} . ' x2=' . $xwigb->{_x2};

    }
    else {
        print("xwigb, x2, missing x2,\n");
    }
}

=head2 sub x2beg 


=cut

sub x2beg {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $xwigb->{_x2beg} = $x2beg;
        $xwigb->{_note}  = $xwigb->{_note} . ' x2beg=' . $xwigb->{_x2beg};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' x2beg=' . $xwigb->{_x2beg};

    }
    else {
        print("xwigb, x2beg, missing x2beg,\n");
    }
}

=head2 sub x2end 


=cut

sub x2end {

    my ( $self, $x2end ) = @_;
    if ( $x2end ne $empty_string ) {

        $xwigb->{_x2end} = $x2end;
        $xwigb->{_note}  = $xwigb->{_note} . ' x2end=' . $xwigb->{_x2end};
        $xwigb->{_Step}  = $xwigb->{_Step} . ' x2end=' . $xwigb->{_x2end};

    }
    else {
        print("xwigb, x2end, missing x2end,\n");
    }
}

=head2 sub xbox 


=cut

sub xbox {

    my ( $self, $xbox ) = @_;
    if ( $xbox ne $empty_string ) {

        $xwigb->{_xbox} = $xbox;
        $xwigb->{_note} = $xwigb->{_note} . ' xbox=' . $xwigb->{_xbox};
        $xwigb->{_Step} = $xwigb->{_Step} . ' xbox=' . $xwigb->{_xbox};

    }
    else {
        print("xwigb, xbox, missing xbox,\n");
    }
}

=head2 sub xcur 


=cut

sub xcur {

    my ( $self, $xcur ) = @_;
    if ( $xcur ne $empty_string ) {

        $xwigb->{_xcur} = $xcur;
        $xwigb->{_note} = $xwigb->{_note} . ' xcur=' . $xwigb->{_xcur};
        $xwigb->{_Step} = $xwigb->{_Step} . ' xcur=' . $xwigb->{_xcur};

    }
    else {
        print("xwigb, xcur, missing xcur,\n");
    }
}

=head2 sub ybox 


=cut

sub ybox {

    my ( $self, $ybox ) = @_;
    if ( $ybox ne $empty_string ) {

        $xwigb->{_ybox} = $ybox;
        $xwigb->{_note} = $xwigb->{_note} . ' ybox=' . $xwigb->{_ybox};
        $xwigb->{_Step} = $xwigb->{_Step} . ' ybox=' . $xwigb->{_ybox};

    }
    else {
        print("xwigb, ybox, missing ybox,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 47;

    return ($max_index);
}

1;
