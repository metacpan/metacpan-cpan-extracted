package App::SeismicUnixGui::sunix::plot::suxgraph;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME: suxgraph.pm 							

AUTHOR: Juan Lorenzo (Perl module only)
 DATE:  Jan 25, 2018 
 DESCRIPTION: package for sunix module suxgraph
 Version: 1.0.0 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

=head2
		
 SUXGRAPH inherits use of parameters from XGRAPH (see below)
 
 SUXGRAPH - X-windows GRAPH plot of a segy data set			
 									
 suxgraph <stdin [optional parameters] | ...				
 									
 Optional parameters: 							
 (see xgraph selfdoc for optional parametes)				
 									
 nplot= number of traces (ntr is an acceptable alias for nplot) 	
 									
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
 									
 See the xgraph selfdoc for the remaining parameters.			
 									
 On NeXT:     suxgraph < infile [optional parameters]  | open  


 XGRAPH - X GRAPHer							
 Graphs n[i] pairs of (x,y) coordinates, for i = 1 to nplot.		
 									
 xgraph n= [optional parameters] <binaryfile 				
 									
 X Functionality:                                                      
 q or Q key    Quit                                                    
 									
 Required Parameters:							
 n                      array containing number of points per plot	
 									
 Optional Parameters:							
 nplot=number of n's    number of plots				
 d1=0.0,...             x sampling intervals (0.0 if x coordinates input)
 f1=0.0,...             first x values (not used if x coordinates input)
 d2=0.0,...             y sampling intervals (0.0 if y coordinates input)
 f2=0.0,...             first y values (not used if y coordinates input)
 pairs=1,...            =1 for data pairs in format 1.a, =0 for format 1.b
 linewidth=1,1,...      line widths in pixels (0 for no lines)		
 linecolor=2,3,...      line colors (black=0, white=1, 2,3,4 = RGB, ...)
 mark=0,1,2,3,...       indices of marks used to represent plotted points
 marksize=0,0,...       size of marks in pixels (0 for no marks)	
 x1beg=x1min            value at which axis 1 begins			
 x1end=x1max            value at which axis 1 ends			
 x2beg=x2min            value at which axis 2 begins			
 x2end=x2max            value at which axis 2 ends			
 reverse=0              =1 to reverse sequence of plotting curves	
 									
 Optional resource parameters (defaults taken from resource database):	

 windowtitle=      	 title on window				

 wbox or
 width=                 width in pixels of window			

 hbox or
 height=                height in pixels of window			

 nTic1=                 number of tics per numbered tic on axis 1	
 grid1=                 grid lines on axis 1 - none, dot, dash, or solid

 y_label or
 label1=                label on axis 1				
 nTic2=                 number of tics per numbered tic on axis 2	
 grid2=                 grid lines onwidth axis 2 - none, dot, dash, or solid

 xlabel or
 label2=                label on axis 2				

 labelFont=             font name for axes labels			

 title=                 title of plot					

 titleFont=             font name for title				
 titleColor=            color for title				
 axesColor=             color for axes					
 gridColor=             color for grid lines				

 style=                 normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)	
									
 Data formats supported:						
 	1.a. x1,y1,x2,y2,...,xn,yn					
 	  b. x1,x2,...,xn,y1,y2,...,yn					
 	2. y1,y2,...,yn (must give non-zero d1[]=)			
 	3. x1,x2,...,xn (must give non-zero d2[]=)			
 	4. nil (must give non-zero d1[]= and non-zero d2[]=)		
   The formats may be repeated and mixed in any order, but if		
   formats 2-4 are used, the d1 and d2 arrays must be specified including
   d1[]=0.0 d2[]=0.0 entries for any internal occurences of format 1.	
   Similarly, the pairs array must contain place-keeping entries for	
   plots of formats 2-4 if they are mixed with both formats 1.a and 1.b.
   Also, if formats 2-4 are used with non-zero f1[] or f2[] entries, then
   the corresponding array(s) must be fully specified including f1[]=0.0
   and/or f2[]=0.0 entries for any internal occurences of format 1 or	
   formats 2-4 where the zero entries are desired.			
 mark index:                                                           
 1. asterisk                                                           
 2. x-cross                                                            
 3. open triangle                                                      
 4. open square                                                        
 5. open circle                                                        
 6. solid triangle                                                     
 7. solid square                                                       
 8. solid circle                                                       
 									
 Note:	n1 and n2 are acceptable aliases for n and nplot, respectively.	
 									
 Example:								
 xgraph n=50,100,20 d1=2.5,1,0.33 <datafile				
   plots three curves with equally spaced x values in one plot frame	
   x1-coordinates are x1(i) = f1+i*d1 for i = 1 to n (f1=0 by default)	
   number of x2's and then x2-coordinates for each curve are read	
   sequentially from datafile.			

=cut 

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $suxgraph = {

    _tmpdir  => '',
    _verbose => '',
    _Step    => '',
    _note    => '',
    _n2      => '',
    _verbose => '',
    _tmpdir  => '',
    # following come from xgraph
    _axesColor   => '',
    _d1          => '',
    _d2          => '',
    _f1          => '',
    _f2          => '',
    _grid1       => '',
    _grid2       => '',
    _gridColor   => '',
    _height      => '',
    _label1      => '',
    _label2      => '',
    _labelFont   => '',
    _linecolor   => '',
    _linewidth   => '',
    _mark        => '',
    _marksize    => '',
    _n           => '',
    _nTic1       => '',
    _nTic2       => '',
    _nplot       => '',
    _pairs       => '',
    _reverse     => '',
    _style       => '',
    _title       => '',
    _titleColor  => '',
    _titleFont   => '',
    _width       => '',
    _windowtitle => '',
    _x1beg       => '',
    _x1end       => '',
    _x2beg       => '',
    _x2end       => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	if (   $suxgraph->{_box_X0} ne $empty_string
		&& $suxgraph->{_box_Y0} ne $empty_string
		&& $suxgraph->{_height} ne $empty_string
		&& $suxgraph->{_width} ne $empty_string
		)
	{
		$suxgraph->{_geometry} =
			  '-geometry ' . $suxgraph->{_width} . 'x'
			. $suxgraph->{_height} . '+'
			. $suxgraph->{_box_X0} . '+'
			. $suxgraph->{_box_Y0};
			
		$suxgraph->{_Step} = 'suxgraph' . $suxgraph->{_Step}.' '.$suxgraph->{_geometry} ;	
	}
	else {
		print("xgraph,missing parameters, NADA\n");
		$suxgraph->{_Step} = 'suxgraph' . $suxgraph->{_Step};
	}

	return ( $suxgraph->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

    $suxgraph->{_note} = 'suxgraph' . $suxgraph->{_note};
    return ( $suxgraph->{_note} );

}

=head2 sub clear

=cut

sub clear {

    $suxgraph->{_nplot}   = '';
    $suxgraph->{_tmpdir}  = '';
    $suxgraph->{_verbose} = '';
    $suxgraph->{_Step}    = '';
    $suxgraph->{_note}    = '';
    $suxgraph->{_box_X0}  = 0;
    $suxgraph->{_box_Y0}  = 0;
    $suxgraph->{_note}    = '';

    # following come from xgraph
    $suxgraph->{_axesColor}   = '';
    $suxgraph->{_d1}          = '';
    $suxgraph->{_d2}          = '';
    $suxgraph->{_f1}          = '';
    $suxgraph->{_f2}          = '';
    $suxgraph->{_grid1}       = '';
    $suxgraph->{_grid2}       = '';
    $suxgraph->{_gridColor}   = '';
    $suxgraph->{_height}      = '';
    $suxgraph->{_label1}      = '';
    $suxgraph->{_label2}      = '';
    $suxgraph->{_labelFont}   = '';
    $suxgraph->{_linecolor}   = '';
    $suxgraph->{_linewidth}   = '';
    $suxgraph->{_mark}        = '';
    $suxgraph->{_marksize}    = '';
    $suxgraph->{_n}           = '';
    $suxgraph->{_nTic1}       = '';
    $suxgraph->{_nTic2}       = '';
    $suxgraph->{_nplot}       = '';
    $suxgraph->{_pairs}       = '';
    $suxgraph->{_reverse}     = '';
    $suxgraph->{_style}       = '';
    $suxgraph->{_title}       = '';
    $suxgraph->{_titleColor}  = '';
    $suxgraph->{_titleFont}   = '';
    $suxgraph->{_width}       = '';
    $suxgraph->{_windowtitle} = '';
    $suxgraph->{_x1beg}       = '';
    $suxgraph->{_x1end}       = '';
    $suxgraph->{_x2beg}       = '';
    $suxgraph->{_x2end}       = '';
}


=head2 sub verbose 


=cut

sub verbose {

    my ( $self, $verbose ) = @_;
    if ( $verbose ne $empty_string ) {

        $suxgraph->{_verbose} = $verbose;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' verbose=' . $suxgraph->{_verbose};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' verbose=' . $suxgraph->{_verbose};

    }
    else {
        print("suxgraph, verbose, missing verbose,\n");
    }
}

=pod
 	from here down files come from xgraph
=cut

=head2 sub axesColor 


=cut

sub axesColor {

    my ( $self, $axesColor ) = @_;
    if ($axesColor) {

        $suxgraph->{_axesColor} = $axesColor;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' axesColor=' . $suxgraph->{_axesColor};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' axesColor=' . $suxgraph->{_axesColor};

    }
    else {
        print("suxgraph, axesColor, missing axesColor,\n");
    }
}

=head2 sub axes_style 

normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)

=cut

sub axes_style {

    my ( $self, $style ) = @_;
    if ($style) {

        $suxgraph->{_style} = $style;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' style=' . $suxgraph->{_style};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' style=' . $suxgraph->{_style};

    }
    else {
        print("suxgraph, axes_style, missing axes_style,\n");
    }
}



=head2 sub box_X0 

 number of pixels right from top
 left corner of screen

=cut

sub box_X0 {

	my ( $self, $box_X0 ) = @_;
	if ( $box_X0 ne $empty_string ) {

		$suxgraph->{_box_X0} = $box_X0;
		$suxgraph->{_note}   = $suxgraph->{_note} . ' box_X0=' . $suxgraph->{_box_X0};

	}
	else {
		print("xgraph, box_box_X0, missing box_box_X0,\n");
	}
}

=head2 sub box_Y0

number of pixels down from top
left corner of screen

=cut

sub box_Y0 {

	my ( $self, $box_Y0 ) = @_;
	if ( $box_Y0 ne $empty_string ) {

		$suxgraph->{_box_Y0} = $box_Y0;
		$suxgraph->{_note}   = $suxgraph->{_note} . ' box_Y0=' . $suxgraph->{_box_Y0};

	}
	else {
		print("xgraph, box_$box_Y0, missing box_$box_Y0,\n");
	}
}


=head2 sub box_height 

 height in pixels of window

=cut

sub box_height {

    my ( $self, $height ) = @_;
    if ($height) {

        $suxgraph->{_height} = $height;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' height=' . $suxgraph->{_height};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' height=' . $suxgraph->{_height};

    }
    else {
        print("suxgraph, box_height, missing box_height,\n");
    }
}

=head2 sub box_width 


=cut

sub box_width {

    my ( $self, $width ) = @_;
    if ($width) {

        $suxgraph->{_width} = $width;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' width=' . $suxgraph->{_width};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' width=' . $suxgraph->{_width};

    }
    else {
        print("suxgraph, box_width, missing box_width,\n");
    }
}

=head2 sub d1 


=cut

sub d1 {

    my ( $self, $d1 ) = @_;
    if ($d1) {

        $suxgraph->{_d1}   = $d1;
        $suxgraph->{_note} = $suxgraph->{_note} . ' d1=' . $suxgraph->{_d1};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' d1=' . $suxgraph->{_d1};

    }
    else {
        print("suxgraph, d1, missing d1,\n");
    }
}

=head2 sub d2 


=cut

sub d2 {

    my ( $self, $d2 ) = @_;
    if ($d2) {

        $suxgraph->{_d2}   = $d2;
        $suxgraph->{_note} = $suxgraph->{_note} . ' d2=' . $suxgraph->{_d2};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' d2=' . $suxgraph->{_d2};

    }
    else {
        print("suxgraph, d2, missing d2,\n");
    }
}

=head2 sub dt 


=cut

sub dt {

    my ( $self, $d1 ) = @_;
    if ($d1) {

        $suxgraph->{_d1}   = $d1;
        $suxgraph->{_note} = $suxgraph->{_note} . ' d1=' . $suxgraph->{_d1};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' d1=' . $suxgraph->{_d1};

    }
    else {
        print("suxgraph, dt, missing dt,\n");
    }
}

=head2 sub dx 


=cut

sub dx {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $suxgraph->{_d1}   = $d1;
        $suxgraph->{_note} = $suxgraph->{_note} . ' d1=' . $suxgraph->{_d1};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' d1=' . $suxgraph->{_d1};

    }
    else {
        print("suxgraph, dx, missing dx,\n");
    }
}

=head2 sub dy 


=cut

sub dy {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $suxgraph->{_d1}   = $d1;
        $suxgraph->{_note} = $suxgraph->{_note} . ' d1=' . $suxgraph->{_d1};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' d1=' . $suxgraph->{_d1};

    }
    else {
        print("suxgraph, dy, missing d1,\n");
    }
}

=head2 sub f1 


=cut

sub f1 {

    my ( $self, $f1 ) = @_;
    if ($f1) {

        $suxgraph->{_f1}   = $f1;
        $suxgraph->{_note} = $suxgraph->{_note} . ' f1=' . $suxgraph->{_f1};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' f1=' . $suxgraph->{_f1};

    }
    else {
        print("suxgraph, f1, missing f1,\n");
    }
}

=head2 sub f2 


=cut

sub f2 {

    my ( $self, $f2 ) = @_;
    if ($f2) {

        $suxgraph->{_f2}   = $f2;
        $suxgraph->{_note} = $suxgraph->{_note} . ' f2=' . $suxgraph->{_f2};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' f2=' . $suxgraph->{_f2};

    }
    else {
        print("suxgraph, f2, missing f2,\n");
    }
}

=head2 sub first_tick_number_x 


=cut

sub first_tick_number_x {

    my ( $self, $f2 ) = @_;
    if ($f2) {

        $suxgraph->{_f2}   = $f2;
        $suxgraph->{_note} = $suxgraph->{_note} . ' f2=' . $suxgraph->{_f2};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' f2=' . $suxgraph->{_f2};

    }
    else {
        print("suxgraph, first_tick_number_x, missing f2,\n");
    }
}

=head2 sub first_tick_num_time 


=cut

sub first_time_tick_num {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $suxgraph->{_f1}   = $f1;
        $suxgraph->{_note} = $suxgraph->{_note} . ' f1=' . $suxgraph->{_f1};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' f1=' . $suxgraph->{_f1};

    }
    else {
        print("suxgraph, first_tick_num_time, missing f1,\n");
    }
}

=head2 sub format 


=cut

sub format {

    my ( $self, $pairs ) = @_;
    if ($pairs) {

        $suxgraph->{_pairs} = $pairs;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' pairs=' . $suxgraph->{_pairs};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' pairs=' . $suxgraph->{_pairs};

    }
    else {
        print("suxgraph, format, missing format,\n");
    }
}

=head2 sub geometry

  low-level layout not commented in 
  seismic unix notes

=cut

sub geometry {

    my ( $self, $geometry ) = @_;
    if ($geometry) {

        $suxgraph->{_geometry} = $geometry;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' -geometry ' . $suxgraph->{_geometry};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' -geometry ' . $suxgraph->{_geometry};

        # print("suxgraph, geometry:$geometry\n");

    }
    else {
        print("suxgraph, geometry, missing geometry,\n");
    }
}

=head2 sub grid1 

grid lines on axis 1 - none, dot, dash, or solid

=cut

sub grid1 {

    my ( $self, $grid1 ) = @_;
    if ($grid1) {

        $suxgraph->{_grid1} = $grid1;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' grid1=' . $suxgraph->{_grid1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' grid1=' . $suxgraph->{_grid1};

    }
    else {
        print("suxgraph, grid1, missing grid1,\n");
    }
}

=head2 sub grid1_type 

grid lines on axis 1 - none, dot, dash, or solid

=cut

sub grid1_type {

    my ( $self, $grid1 ) = @_;
    if ($grid1) {

        $suxgraph->{_grid1} = $grid1;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' grid1=' . $suxgraph->{_grid1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' grid1=' . $suxgraph->{_grid1};

    }
    else {
        print("suxgraph, grid1_type, missing grid1_type,\n");
    }
}

=head2 sub grid2 

grid lines on axis 2 - none, dot, dash, or solid

=cut

sub grid2 {

    my ( $self, $grid2 ) = @_;
    if ($grid2) {

        $suxgraph->{_grid2} = $grid2;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' grid2=' . $suxgraph->{_grid2};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' grid2=' . $suxgraph->{_grid2};

    }
    else {
        print("suxgraph, grid2, missing grid2,\n");
    }
}

=head2 sub grid2_type 

grid lines on axis 2 - none, dot, dash, or solid

=cut

sub grid2_type {

    my ( $self, $grid2 ) = @_;
    if ($grid2) {

        $suxgraph->{_grid2} = $grid2;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' grid2=' . $suxgraph->{_grid2};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' grid2=' . $suxgraph->{_grid2};

    }
    else {
        print("suxgraph, grid2_type, missing grid2_type,\n");
    }
}

=head2 sub gridColor 


=cut

sub gridColor {

    my ( $self, $gridColor ) = @_;
    if ($gridColor) {

        $suxgraph->{_gridColor} = $gridColor;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' gridColor=' . $suxgraph->{_gridColor};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' gridColor=' . $suxgraph->{_gridColor};

    }
    else {
        print("suxgraph, gridColor, missing gridColor,\n");
    }
}

=head2 sub height 


=cut

sub height {

    my ( $self, $height ) = @_;
    if ($height) {

        $suxgraph->{_height} = $height;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' height=' . $suxgraph->{_height};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' height=' . $suxgraph->{_height};

    }
    else {
        print("suxgraph, height, missing height,\n");
    }
}

=head2 sub label1 

 label on axis 1

=cut

sub label1 {

    my ( $self, $label1 ) = @_;
    if ($label1) {

        $suxgraph->{_label1} = $label1;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' label1=' . $suxgraph->{_label1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' label1=' . $suxgraph->{_label1};

    }
    else {
        print("suxgraph, label1, missing label1,\n");
    }
}

=head2 sub label2 

  label on axis 2

=cut

sub label2 {

    my ( $self, $label2 ) = @_;
    if ($label2) {

        $suxgraph->{_label2} = $label2;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' label2=' . $suxgraph->{_label2};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' label2=' . $suxgraph->{_label2};

    }
    else {
        print("suxgraph, label2, missing label2,\n");
    }
}

=head2 sub labelFont 


=cut

sub labelFont {

    my ( $self, $labelFont ) = @_;
    if ($labelFont) {

        $suxgraph->{_labelFont} = $labelFont;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' labelFont=' . $suxgraph->{_labelFont};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' labelFont=' . $suxgraph->{_labelFont};

    }
    else {
        print("suxgraph, labelFont, missing labelFont,\n");
    }
}

=head2 sub line_color 


=cut

sub line_color {

    my ( $self, $linecolor ) = @_;
    if ($linecolor) {

        $suxgraph->{_linecolor} = $linecolor;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' linecolor=' . $suxgraph->{_linecolor};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' linecolor=' . $suxgraph->{_linecolor};

    }
    else {
        print("suxgraph, line_color, missing line_color,\n");
    }
}

=head2 sub linecolor 


=cut

sub linecolor {

    my ( $self, $linecolor ) = @_;
    if ($linecolor) {

        $suxgraph->{_linecolor} = $linecolor;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' linecolor=' . $suxgraph->{_linecolor};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' linecolor=' . $suxgraph->{_linecolor};

    }
    else {
        print("suxgraph, line_color, missing line_color,\n");
    }
}

=head2 sub line_width 

 line widths in pixels (0 for no lines)

=cut

sub line_width {

    my ( $self, $linewidth ) = @_;
    if ($linewidth) {

        $suxgraph->{_linewidth} = $linewidth;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' linewidth=' . $suxgraph->{_linewidth};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' linewidth=' . $suxgraph->{_linewidth};

    }
    else {
        print("suxgraph, line_widths, missing line_widths,\n");
    }
}

=head2 sub line_widths 

 line widths in pixels (0 for no lines)

=cut

sub line_widths {

    my ( $self, $linewidth ) = @_;
    if ($linewidth) {

        $suxgraph->{_linewidth} = $linewidth;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' linewidth=' . $suxgraph->{_linewidth};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' linewidth=' . $suxgraph->{_linewidth};

    }
    else {
        print("suxgraph, line_widths, missing line_widths,\n");
    }
}

=head2 sub linewidth 

 line widths in pixels (0 for no lines

=cut

sub linewidth {

    my ( $self, $linewidth ) = @_;
    if ($linewidth) {

        $suxgraph->{_linewidth} = $linewidth;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' linewidth=' . $suxgraph->{_linewidth};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' linewidth=' . $suxgraph->{_linewidth};

    }
    else {
        print("suxgraph, linewidth, missing linewidth,\n");
    }
}

=head2 sub mark 


=cut

sub mark {

    my ( $self, $mark ) = @_;
    if ($mark) {

        $suxgraph->{_mark} = $mark;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' mark=' . $suxgraph->{_mark};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' mark=' . $suxgraph->{_mark};

    }
    else {
        print("suxgraph, mark, missing mark,\n");
    }
}

=head2 sub mark_indices 

indices of marks used to represent plotted points

=cut

sub mark_indices {

    my ( $self, $mark ) = @_;
    if ($mark) {

        $suxgraph->{_mark} = $mark;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' mark=' . $suxgraph->{_mark};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' mark=' . $suxgraph->{_mark};

    }
    else {
        print("suxgraph, mark_indices, missing mark_indices,\n");
    }
}

=head2 sub marksize 


=cut

sub marksize {

    my ( $self, $marksize ) = @_;
    if ($marksize) {

        $suxgraph->{_marksize} = $marksize;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' marksize=' . $suxgraph->{_marksize};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' marksize=' . $suxgraph->{_marksize};

    }
    else {
        print("suxgraph, marksize, missing marksize,\n");
    }
}

=head2 sub mark_size_pix 

 size of marks in pixels (0 for no marks)

=cut

sub mark_size_pix {

    my ( $self, $marksize ) = @_;
    if ($marksize) {

        $suxgraph->{_marksize} = $marksize;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' marksize=' . $suxgraph->{_marksize};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' marksize=' . $suxgraph->{_marksize};

    }
    else {
        print("suxgraph, mark_size_pix, missing mark_size_pix,\n");
    }
}

=head2 sub n 


=cut

sub n {

    my ( $self, $n ) = @_;
    if ($n) {

        $suxgraph->{_n}    = $n;
        $suxgraph->{_note} = $suxgraph->{_note} . ' n=' . $suxgraph->{_n};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' n=' . $suxgraph->{_n};

    }
    else {
        print("suxgraph, n, missing n,\n");
    }
}


=head2 sub n1 


=cut

sub n1 {

    my ( $self, $n ) = @_;
    if ($n) {

        $suxgraph->{_n}    = $n;
        $suxgraph->{_note} = $suxgraph->{_note} . ' n=' . $suxgraph->{_n};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' n=' . $suxgraph->{_n};

    }
    else {
        print("suxgraph, n1, missing n1,\n");
    }
}



=head2 sub num_traces 

 alias for nplot
 
=cut

sub num_traces {

    my ( $self, $nplot ) = @_;
    if ( $nplot ne $empty_string ) {

        $suxgraph->{_nplot} = $nplot;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' nplot=' . $suxgraph->{_nplot};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' nplot=' . $suxgraph->{_nplot};

    }
    else {
        print("suxgraph, num_traces, missing num_traces,\n");
    }
}


=head2 sub num_minor_ticks_betw_distance_ticks 


=cut

sub num_minor_ticks_betw_distance_ticks {

    my ( $self, $nTic2 ) = @_;
    if ($nTic2) {

        $suxgraph->{_nTic2} = $nTic2;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' nTic2=' . $suxgraph->{_nTic2};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' nTic2=' . $suxgraph->{_nTic2};

    }
    else {
        print(
            "suxgraph, num_minor_ticks_betw_distance_ticks, missing nTic2,\n");
    }
}

=head2 sub num_minor_ticks_betw_time_ticks 


=cut

sub num_minor_ticks_betw_time_ticks {

    my ( $self, $nTic1 ) = @_;
    if ($nTic1) {

        $suxgraph->{_nTic1} = $nTic1;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' nTic1=' . $suxgraph->{_nTic1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' nTic1=' . $suxgraph->{_nTic1};

    }
    else {
        print("suxgraph, num_minor_ticks_betw_time_ticks, missing nTic1,\n");
    }
}

=head2 sub num_points 


=cut

sub num_points {

    my ( $self, $n ) = @_;
    if ($n) {

        $suxgraph->{_n}    = $n;
        $suxgraph->{_note} = $suxgraph->{_note} . ' n=' . $suxgraph->{_n};
        $suxgraph->{_Step} = $suxgraph->{_Step} . ' n=' . $suxgraph->{_n};

    }
    else {
        print("suxgraph, num_points, missing num_points,\n");
    }
}

=head2 sub nTic1 


=cut

sub nTic1 {

    my ( $self, $nTic1 ) = @_;
    if ($nTic1) {

        $suxgraph->{_nTic1} = $nTic1;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' nTic1=' . $suxgraph->{_nTic1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' nTic1=' . $suxgraph->{_nTic1};

    }
    else {
        print("suxgraph, nTic1, missing nTic1,\n");
    }
}

=head2 sub nTic2 


=cut

sub nTic2 {

    my ( $self, $nTic2 ) = @_;
    if ($nTic2) {

        $suxgraph->{_nTic2} = $nTic2;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' nTic2=' . $suxgraph->{_nTic2};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' nTic2=' . $suxgraph->{_nTic2};

    }
    else {
        print("suxgraph, nTic2, missing nTic2,\n");
    }
}

=head2 sub n2 


=cut

sub n2 {

    my ( $self, $nplot ) = @_;
    if ($nplot) {

        $suxgraph->{_nplot} = $nplot;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' nplot=' . $suxgraph->{_nplot};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' nplot=' . $suxgraph->{_nplot};

    }
    else {
        print("suxgraph, n2, missing n2,\n");
    }
}

=head2 sub nplot 


=cut

sub nplot {

    my ( $self, $nplot ) = @_;
    if ($nplot) {

        $suxgraph->{_nplot} = $nplot;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' nplot=' . $suxgraph->{_nplot};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' nplot=' . $suxgraph->{_nplot};

    }
    else {
        print("suxgraph, nplot, missing nplot,\n");
    }
}

=head2 sub orientation 

  can be seismic type RHS
  or normal type LHS
normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)

=cut

sub orientation {

    my ( $self, $style ) = @_;
    if ($style) {

        $suxgraph->{_style} = $style;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' style=' . $suxgraph->{_style};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' style=' . $suxgraph->{_style};

    }
    else {
        print("suxgraph, orientation, missing orientation,\n");
    }
}

=head2 sub pairs 


=cut

sub pairs {

    my ( $self, $pairs ) = @_;
    if ($pairs) {

        $suxgraph->{_pairs} = $pairs;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' pairs=' . $suxgraph->{_pairs};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' pairs=' . $suxgraph->{_pairs};

    }
    else {
        print("suxgraph, pairs, missing pairs,\n");
    }
}

=head2 sub reverse 


=cut

sub reverse {

    my ( $self, $reverse ) = @_;
    if ($reverse) {

        $suxgraph->{_reverse} = $reverse;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' reverse=' . $suxgraph->{_reverse};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' reverse=' . $suxgraph->{_reverse};

    }
    else {
        print("suxgraph, reverse, missing reverse,\n");
    }
}

=head2 sub style 

  can be seismic type RHS
  or normal type LHS
  
   normal (axis 1 horizontal, axis 2 vertical) or	
   seismic (axis 1 vertical, axis 2 horizontal)

 normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)

=cut

sub style {

    my ( $self, $style ) = @_;
    if ($style) {

        $suxgraph->{_style} = $style;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' style=' . $suxgraph->{_style};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' style=' . $suxgraph->{_style};

    }
    else {
        print("suxgraph, style, missing style,\n");
    }
}

=head2 sub title 

title for plot

=cut

sub title {

    my ( $self, $title ) = @_;
    if ($title) {

        $suxgraph->{_title} = $title;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' title=' . $suxgraph->{_title};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' title=' . $suxgraph->{_title};

    }
    else {
        print("suxgraph, title, missing title,\n");
    }
}

=head2 sub titleColor 


=cut

sub titleColor {

    my ( $self, $titleColor ) = @_;
    if ($titleColor) {

        $suxgraph->{_titleColor} = $titleColor;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' titleColor=' . $suxgraph->{_titleColor};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' titleColor=' . $suxgraph->{_titleColor};

    }
    else {
        print("suxgraph, titleColor, missing titleColor,\n");
    }
}

=head2 sub titleFont 


=cut

sub titleFont {

    my ( $self, $titleFont ) = @_;
    if ($titleFont) {

        $suxgraph->{_titleFont} = $titleFont;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' titleFont=' . $suxgraph->{_titleFont};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' titleFont=' . $suxgraph->{_titleFont};

    }
    else {
        print("suxgraph, titleFont, missing titleFont,\n");
    }
}


=head2 sub tmpdir 


=cut

sub tmpdir {

    my ( $self, $tmpdir ) = @_;
    if ( $tmpdir ne $empty_string ) {

        $suxgraph->{_tmpdir} = $tmpdir;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' tmpdir=' . $suxgraph->{_tmpdir};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' tmpdir=' . $suxgraph->{_tmpdir};

    }
    else {
        print("suxgraph, tmpdir, missing tmpdir,\n");
    }
}

=head2 sub width 


=cut

sub width {

    my ( $self, $width ) = @_;
    if ($width) {

        $suxgraph->{_width} = $width;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' width=' . $suxgraph->{_width};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' width=' . $suxgraph->{_width};

    }
    else {
        print("suxgraph, width, missing width,\n");
    }
}

=head2 sub windowtitle 


=cut

sub windowtitle {

    my ( $self, $windowtitle ) = @_;
    if ($windowtitle) {

        $suxgraph->{_windowtitle} = $windowtitle;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' windowtitle=' . $suxgraph->{_windowtitle};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' windowtitle=' . $suxgraph->{_windowtitle};

    }
    else {
        print("suxgraph, windowtitle, missing windowtitle,\n");
    }
}

=head2 sub x1_min 

value at which axis 1 begins

=cut

sub x1_min {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $suxgraph->{_x1beg} = $x1beg;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x1beg=' . $suxgraph->{_x1beg};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x1beg=' . $suxgraph->{_x1beg};

    }
    else {
        print("suxgraph, x1_min, missing x1_min,\n");
    }
}

=head2 sub x1_max 

value at which axis 1 ends

=cut

sub x1_max {

    my ( $self, $x1end ) = @_;
    if ($x1end) {

        $suxgraph->{_x1end} = $x1end;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x1end=' . $suxgraph->{_x1end};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x1end=' . $suxgraph->{_x1end};

    }
    else {
        print("suxgraph, x1_max, missing x1_max,\n");
    }
}

=head2 sub x1beg 

value at which axis 1 begins

=cut

sub x1beg {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $suxgraph->{_x1beg} = $x1beg;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x1beg=' . $suxgraph->{_x1beg};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x1beg=' . $suxgraph->{_x1beg};

    }
    else {
        print("suxgraph, x1beg, missing x1beg,\n");
    }
}

=head2 sub x1end 

value at which axis 1 ends

=cut

sub x1end {

    my ( $self, $x1end ) = @_;
    if ($x1end) {

        $suxgraph->{_x1end} = $x1end;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x1end=' . $suxgraph->{_x1end};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x1end=' . $suxgraph->{_x1end};

    }
    else {
        print("suxgraph, x1end, missing x1end,\n");
    }
}

=head2 sub x_label 

  label on axis 1

=cut

sub x_label {

    my ( $self, $label1 ) = @_;
    if ($label1) {

        $suxgraph->{_label1} = $label1;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' label1=' . $suxgraph->{_label1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' label1=' . $suxgraph->{_label1};

    }
    else {
        print("suxgraph, x_label, missing x_label,\n");
    }
}

=head2 sub x2beg 

value at which axis 2 begins

=cut

sub x2beg {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $suxgraph->{_x2beg} = $x2beg;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x2beg=' . $suxgraph->{_x2beg};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x2beg=' . $suxgraph->{_x2beg};

    }
    else {
        print("suxgraph, x2beg, missing x2beg,\n");
    }
}

=head2 sub x2_min 

value at which axis 2 begins

=cut

sub x2_min {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $suxgraph->{_x2beg} = $x2beg;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x2beg=' . $suxgraph->{_x2beg};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x2beg=' . $suxgraph->{_x2beg};

    }
    else {
        print("suxgraph, x2_min, missing x2_min,\n");
    }
}

=head2 sub x2_max 

value at which axis 2 ends

=cut

sub x2_max {

    my ( $self, $x2end ) = @_;
    if ($x2end) {

        $suxgraph->{_x2end} = $x2end;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x2end=' . $suxgraph->{_x2end};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x2end=' . $suxgraph->{_x2end};

    }
    else {
        print("suxgraph, x2_max, missing x2_max,\n");
    }
}

=head2 sub x2end 

value at which axis 2 ends

=cut

sub x2end {

    my ( $self, $x2end ) = @_;
    if ($x2end) {

        $suxgraph->{_x2end} = $x2end;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x2end=' . $suxgraph->{_x2end};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x2end=' . $suxgraph->{_x2end};

    }
    else {
        print("suxgraph, x2end, missing x2end,\n");
    }
}

=head2 sub x_end_m 

value at which axis 2 ends

=cut

sub x_end_m {

    my ( $self, $x2end ) = @_;
    if ($x2end) {

        $suxgraph->{_x2end} = $x2end;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x2end=' . $suxgraph->{_x2end};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x2end=' . $suxgraph->{_x2end};

    }
    else {
        print("suxgraph, x_end_m, missing x_end_m,\n");
    }
}

=head2 sub xlabel 

value at which axis 2 begins

=cut

sub xlabel {

    my ( $self, $label1 ) = @_;
    if ( $label1 ne $empty_string ) {

        $suxgraph->{_label1} = $label1;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' label1=' . $suxgraph->{_label1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' label1=' . $suxgraph->{_label1};

    }
    else {
        print("suxgraph, xlabel, missing label2,\n");
    }
}

=head2 sub x_grid_lines 

grid lines on axis 2 - none, dot, dash, or solid

=cut

sub x_grid_lines {

    my ( $self, $grid2 ) = @_;
    if ($grid2) {

        $suxgraph->{_grid2} = $grid2;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' grid2=' . $suxgraph->{_grid2};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' grid2=' . $suxgraph->{_grid2};

    }
    else {
        print("suxgraph, x_grid_lines, missing grid2,\n");
    }
}

=head2 sub x_start_m 

value at which axis 2 begins

=cut

sub x_start_m {

    my ( $self, $x2beg ) = @_;
    if ( $x2beg ne $empty_string ) {

        $suxgraph->{_x2beg} = $x2beg;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x2beg=' . $suxgraph->{_x2beg};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x2beg=' . $suxgraph->{_x2beg};

    }
    else {
        print("suxgraph, x_start_m, missing x2beg,\n");
    }
}

=head2 sub y_end_s 

value at which axis 1 ends

=cut

sub y_end_s {

    my ( $self, $x1end ) = @_;
    if ($x1end) {

        $suxgraph->{_x1end} = $x1end;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x1end=' . $suxgraph->{_x1end};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x1end=' . $suxgraph->{_x1end};

    }
    else {
        print("suxgraph, y_end_s, missing y_end_s,\n");
    }
}



=head2 sub y_grid_lines 

grid lines on axis 1 - none, dot, dash, or solid

=cut

sub y_grid_lines {

    my ( $self, $grid1 ) = @_;
    if ($grid1) {

        $suxgraph->{_grid1} = $grid1;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' grid1=' . $suxgraph->{_grid1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' grid1=' . $suxgraph->{_grid1};

    }
    else {
        print("suxgraph, y_grid_lines, missing grid1,\n");
    }
}

=head2 sub y_label 

value at which axis 1 begins

=cut

sub y_label {

    my ( $self, $y_label ) = @_;
    if ( $y_label ne $empty_string ) {

        $suxgraph->{_label1} = $y_label;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' label1=' . $suxgraph->{_label1};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' label1=' . $suxgraph->{_label1};

    }
    else {
        print("suxgraph, y_label, missing label1,\n");
    }
}

=head2 sub y_start_s_s 

value at which axis 1 begins

=cut

sub y_start_s {

    my ( $self, $x1beg ) = @_;
    if ( $x1beg ne $empty_string ) {

        $suxgraph->{_x1beg} = $x1beg;
        $suxgraph->{_note} =
          $suxgraph->{_note} . ' x1beg=' . $suxgraph->{_x1beg};
        $suxgraph->{_Step} =
          $suxgraph->{_Step} . ' x1beg=' . $suxgraph->{_x1beg};

    }
    else {
        print("suxgraph, y_start_s, missing x1beg,\n");
    }
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
    my ($self) = @_;
    my $max_index = 40;

    return ($max_index);
}
1;
