package App::SeismicUnixGui::sunix::plot::xgraph;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PERL PROGRAM NAME:  XGRAPH - X GRAPHer							
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 SEISMIC UNIX NOTES

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
 reverse=0              =1 to reverse sequence of plotting curves	", 

 Optional resource parameters (defaults taken from resource database):	
 windowtitle=      	 title on window				
 width=                 width in pixels of window			
 height=                height in pixels of window			
 nTic1=                 number of tics per numbered tic on axis 1	
 grid1=                 grid lines on axis 1 - none, dot, dash, or solid
 label1=                label on axis 1				
 nTic2=                 number of tics per numbered tic on axis 2	
 grid2=                 grid lines on axis 2 - none, dot, dash, or solid
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

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my $xgraph = {
	_axesColor   => '',
	_box_X0      => '',
	_box_Y0      => '',
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
	_Step        => '',
	_note        => '',
};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	if (   $xgraph->{_box_X0} ne $empty_string
		&& $xgraph->{_box_Y0} ne $empty_string
		&& $xgraph->{_height} ne $empty_string
		&& $xgraph->{_width} ne $empty_string
		)
	{
		$xgraph->{_geometry} =
			  '-geometry ' . $xgraph->{_width} . 'x'
			. $xgraph->{_height} . '+'
			. $xgraph->{_box_X0} . '+'
			. $xgraph->{_box_Y0};
			
		$xgraph->{_Step} = 'xgraph' . $xgraph->{_Step}.' '.$xgraph->{_geometry} ;	
	}
	else {
#		print("xgraph,missing parameters, NADA\n");
		$xgraph->{_Step} = 'xgraph' . $xgraph->{_Step};
	}

	return ( $xgraph->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$xgraph->{_note} = 'xgraph' . $xgraph->{_note};
	return ( $xgraph->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$xgraph->{_axesColor}   = '';
	$xgraph->{_box_X0}      = '';
	$xgraph->{_box_Y0}      = '';
	$xgraph->{_d1}          = '';
	$xgraph->{_d2}          = '';
	$xgraph->{_f1}          = '';
	$xgraph->{_f2}          = '';
	$xgraph->{_grid1}       = '';
	$xgraph->{_grid2}       = '';
	$xgraph->{_gridColor}   = '';
	$xgraph->{_height}      = '';
	$xgraph->{_label1}      = '';
	$xgraph->{_label2}      = '';
	$xgraph->{_labelFont}   = '';
	$xgraph->{_linecolor}   = '';
	$xgraph->{_linewidth}   = '';
	$xgraph->{_mark}        = '';
	$xgraph->{_marksize}    = '';
	$xgraph->{_n}           = '';
	$xgraph->{_nTic1}       = '';
	$xgraph->{_nTic2}       = '';
	$xgraph->{_nplot}       = '';
	$xgraph->{_pairs}       = '';
	$xgraph->{_reverse}     = '';
	$xgraph->{_style}       = '';
	$xgraph->{_title}       = '';
	$xgraph->{_titleColor}  = '';
	$xgraph->{_titleFont}   = '';
	$xgraph->{_width}       = '';
	$xgraph->{_windowtitle} = '';
	$xgraph->{_x1beg}       = '';
	$xgraph->{_x1end}       = '';
	$xgraph->{_x2beg}       = '';
	$xgraph->{_x2end}       = '';
	$xgraph->{_Step}        = '';
	$xgraph->{_note}        = '';
}

=head2 sub axesColor 


=cut

sub axesColor {

	my ( $self, $axesColor ) = @_;
	if ( $axesColor ne $empty_string ) {

		$xgraph->{_axesColor} = $axesColor;
		$xgraph->{_note} =
			$xgraph->{_note} . ' axesColor=' . $xgraph->{_axesColor};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' axesColor=' . $xgraph->{_axesColor};

	}
	else {
		print("xgraph, axesColor, missing axesColor,\n");
	}
}

=head2 sub axes_style 

normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)

=cut

sub axes_style {

	my ( $self, $style ) = @_;
	if ( $style ne $empty_string ) {

		$xgraph->{_style} = $style;
		$xgraph->{_note}  = $xgraph->{_note} . ' style=' . $xgraph->{_style};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' style=' . $xgraph->{_style};

	}
	else {
		print("xgraph, axes_style, missing axes_style,\n");
	}
}

=head2 sub box_X0 

 number of pixels right from top
 left corner of screen

=cut

sub box_X0 {

	my ( $self, $box_X0 ) = @_;
	if ( $box_X0 ne $empty_string ) {

		$xgraph->{_box_X0} = $box_X0;
		$xgraph->{_note}   = $xgraph->{_note} . ' box_X0=' . $xgraph->{_box_X0};

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

		$xgraph->{_box_Y0} = $box_Y0;
		$xgraph->{_note}   = $xgraph->{_note} . ' box_Y0=' . $xgraph->{_box_Y0};

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
	if ( $height ne $empty_string ) {

		$xgraph->{_height} = $height;
		$xgraph->{_note}   = $xgraph->{_note} . ' height=' . $xgraph->{_height};

	}
	else {
		print("xgraph, box_height, missing box_height,\n");
	}
}

=head2 sub box_width 


=cut

sub box_width {

	my ( $self, $width ) = @_;
	if ( $width ne $empty_string ) {

		$xgraph->{_width} = $width;
		$xgraph->{_note}  = $xgraph->{_note} . ' width=' . $xgraph->{_width};

	}
	else {
		print("xgraph, box_width, missing box_width,\n");
	}
}

=head2 sub d1 


=cut

sub d1 {

	my ( $self, $d1 ) = @_;
	if ( $d1 ne $empty_string ) {

		$xgraph->{_d1}   = $d1;
		$xgraph->{_note} = $xgraph->{_note} . ' d1=' . $xgraph->{_d1};
		$xgraph->{_Step} = $xgraph->{_Step} . ' d1=' . $xgraph->{_d1};

	}
	else {
		print("xgraph, d1, missing d1,\n");
	}
}

=head2 sub d2 


=cut

sub d2 {

	my ( $self, $d2 ) = @_;
	if ( $d2 ne $empty_string ) {

		$xgraph->{_d2}   = $d2;
		$xgraph->{_note} = $xgraph->{_note} . ' d2=' . $xgraph->{_d2};
		$xgraph->{_Step} = $xgraph->{_Step} . ' d2=' . $xgraph->{_d2};

	}
	else {
		print("xgraph, d2, missing d2,\n");
	}
}


=head2 sub dt 


=cut

sub dt {

    my ( $self, $d1 ) = @_;
    if ($d1) {

        $xgraph->{_d1}   = $d1;
        $xgraph->{_note} = $xgraph->{_note} . ' d1=' . $xgraph->{_d1};
        $xgraph->{_Step} = $xgraph->{_Step} . ' d1=' . $xgraph->{_d1};

    }
    else {
        print("xgraph, dt, missing dt,\n");
    }
}

=head2 sub dx 

=cut

sub dx {

    my ( $self, $d1 ) = @_;
    if ( $d1 ne $empty_string ) {

        $xgraph->{_d1}   = $d1;
        $xgraph->{_note} = $xgraph->{_note} . ' d1=' . $xgraph->{_d1};
        $xgraph->{_Step} = $xgraph->{_Step} . ' d1=' . $xgraph->{_d1};

    }
    else {
        print("xgraph, dx, missing dx,\n");
    }
}

=head2 sub f1 


=cut

sub f1 {

	my ( $self, $f1 ) = @_;
	if ( $f1 ne $empty_string ) {

		$xgraph->{_f1}   = $f1;
		$xgraph->{_note} = $xgraph->{_note} . ' f1=' . $xgraph->{_f1};
		$xgraph->{_Step} = $xgraph->{_Step} . ' f1=' . $xgraph->{_f1};

	}
	else {
		print("xgraph, f1, missing f1,\n");
	}
}

=head2 sub f2 


=cut

sub f2 {

	my ( $self, $f2 ) = @_;
	if ( $f2 ne $empty_string ) {

		$xgraph->{_f2}   = $f2;
		$xgraph->{_note} = $xgraph->{_note} . ' f2=' . $xgraph->{_f2};
		$xgraph->{_Step} = $xgraph->{_Step} . ' f2=' . $xgraph->{_f2};

	}
	else {
		print("xgraph, f2, missing f2,\n");
	}
}


=head2 sub first_tick_num_time 


=cut

sub first_tick_num_time {

    my ( $self, $f1 ) = @_;
    if ( $f1 ne $empty_string ) {

        $xgraph->{_f1}   = $f1;
        $xgraph->{_note} = $xgraph->{_note} . ' f1=' . $xgraph->{_f1};
        $xgraph->{_Step} = $xgraph->{_Step} . ' f1=' . $xgraph->{_f1};

    }
    else {
        print("xgraph, first_tick_num_time, missing f1,\n");
    }
}



=head2 sub first_tick_number_x 


=cut

sub first_tick_number_x {

    my ( $self, $f2 ) = @_;
    if ($f2) {

        $xgraph->{_f2}   = $f2;
        $xgraph->{_note} = $xgraph->{_note} . ' f2=' . $xgraph->{_f2};
        $xgraph->{_Step} = $xgraph->{_Step} . ' f2=' . $xgraph->{_f2};

    }
    else {
        print("xgraph, first_tick_number_x, missing f2,\n");
    }
}


=head2 sub format 


=cut

sub format {

	my ( $self, $pairs ) = @_;
	if ( $pairs ne $empty_string ) {

		$xgraph->{_pairs} = $pairs;
		$xgraph->{_note}  = $xgraph->{_note} . ' pairs=' . $xgraph->{_pairs};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' pairs=' . $xgraph->{_pairs};

	}
	else {
		print("xgraph, format, missing format,\n");
	}
}

=head2 sub geometry

  low-level layout not commented in 
  seismic unix notes

=cut

sub geometry {

	my ( $self, $geometry ) = @_;
	if ( $geometry ne $empty_string ) {

		$xgraph->{_geometry} = $geometry;
		$xgraph->{_note} =
			$xgraph->{_note} . ' -geometry ' . $xgraph->{_geometry};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' -geometry ' . $xgraph->{_geometry};

		# print("xgraph, geometry:$geometry\n");

	}
	else {
		print("xgraph, geometry, missing geometry,\n");
	}
}

=head2 sub grid1 

grid lines on axis 1 - none, dot, dash, or solid

=cut

sub grid1 {

	my ( $self, $grid1 ) = @_;
	if ( $grid1 ne $empty_string ) {

		$xgraph->{_grid1} = $grid1;
		$xgraph->{_note}  = $xgraph->{_note} . ' grid1=' . $xgraph->{_grid1};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' grid1=' . $xgraph->{_grid1};

	}
	else {
		print("xgraph, grid1, missing grid1,\n");
	}
}

=head2 sub grid1_type 

grid lines on axis 1 - none, dot, dash, or solid

=cut

sub grid1_type {

	my ( $self, $grid1 ) = @_;
	if ( $grid1 ne $empty_string ) {

		$xgraph->{_grid1} = $grid1;
		$xgraph->{_note}  = $xgraph->{_note} . ' grid1=' . $xgraph->{_grid1};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' grid1=' . $xgraph->{_grid1};

	}
	else {
		print("xgraph, grid1_type, missing grid1_type,\n");
	}
}

=head2 sub grid2 

grid lines on axis 2 - none, dot, dash, or solid

=cut

sub grid2 {

	my ( $self, $grid2 ) = @_;
	if ( $grid2 ne $empty_string ) {

		$xgraph->{_grid2} = $grid2;
		$xgraph->{_note}  = $xgraph->{_note} . ' grid2=' . $xgraph->{_grid2};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' grid2=' . $xgraph->{_grid2};

	}
	else {
		print("xgraph, grid2, missing grid2,\n");
	}
}

=head2 sub grid2_type 

grid lines on axis 2 - none, dot, dash, or solid

=cut

sub grid2_type {

	my ( $self, $grid2 ) = @_;
	if ( $grid2 ne $empty_string ) {

		$xgraph->{_grid2} = $grid2;
		$xgraph->{_note}  = $xgraph->{_note} . ' grid2=' . $xgraph->{_grid2};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' grid2=' . $xgraph->{_grid2};

	}
	else {
		print("xgraph, grid2_type, missing grid2_type,\n");
	}
}

=head2 sub gridColor 


=cut

sub gridColor {

	my ( $self, $gridColor ) = @_;
	if ( $gridColor ne $empty_string ) {

		$xgraph->{_gridColor} = $gridColor;
		$xgraph->{_note} =
			$xgraph->{_note} . ' gridColor=' . $xgraph->{_gridColor};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' gridColor=' . $xgraph->{_gridColor};

	}
	else {
		print("xgraph, gridColor, missing gridColor,\n");
	}
}

=head2 sub height 


=cut

sub height {

	my ( $self, $height ) = @_;
	if ( $height ne $empty_string ) {

		$xgraph->{_height} = $height;
		$xgraph->{_note}   = $xgraph->{_note} . ' height=' . $xgraph->{_height};
		$xgraph->{_Step}   = $xgraph->{_Step} . ' height=' . $xgraph->{_height};

	}
	else {
		print("xgraph, height, missing height,\n");
	}
}

=head2 sub label1 

 label on axis 1

=cut

sub label1 {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$xgraph->{_label1} = $label1;
		$xgraph->{_note}   = $xgraph->{_note} . ' label1=' . $xgraph->{_label1};
		$xgraph->{_Step}   = $xgraph->{_Step} . ' label1=' . $xgraph->{_label1};

	}
	else {
		print("xgraph, label1, missing label1,\n");
	}
}

=head2 sub label2 

  label on axis 2

=cut

sub label2 {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$xgraph->{_label2} = $label2;
		$xgraph->{_note}   = $xgraph->{_note} . ' label2=' . $xgraph->{_label2};
		$xgraph->{_Step}   = $xgraph->{_Step} . ' label2=' . $xgraph->{_label2};

	}
	else {
		print("xgraph, label2, missing label2,\n");
	}
}

=head2 sub labelFont 


=cut

sub labelFont {

	my ( $self, $labelFont ) = @_;
	if ( $labelFont ne $empty_string ) {

		$xgraph->{_labelFont} = $labelFont;
		$xgraph->{_note} =
			$xgraph->{_note} . ' labelFont=' . $xgraph->{_labelFont};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' labelFont=' . $xgraph->{_labelFont};

	}
	else {
		print("xgraph, labelFont, missing labelFont,\n");
	}
}

=head2 sub line_color 


=cut

sub line_color {

	my ( $self, $linecolor ) = @_;
	if ( $linecolor ne $empty_string ) {

		$xgraph->{_linecolor} = $linecolor;
		$xgraph->{_note} =
			$xgraph->{_note} . ' linecolor=' . $xgraph->{_linecolor};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' linecolor=' . $xgraph->{_linecolor};

	}
	else {
		print("xgraph, line_color, missing line_color,\n");
	}
}

=head2 sub linecolor 


=cut

sub linecolor {

	my ( $self, $linecolor ) = @_;
	if ( $linecolor ne $empty_string ) {

		$xgraph->{_linecolor} = $linecolor;
		$xgraph->{_note} =
			$xgraph->{_note} . ' linecolor=' . $xgraph->{_linecolor};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' linecolor=' . $xgraph->{_linecolor};

	}
	else {
		print("xgraph, line_color, missing line_color,\n");
	}
}

=head2 sub line_width 

 line widths in pixels (0 for no lines)

=cut

sub line_width {

	my ( $self, $linewidth ) = @_;
	if ( $linewidth ne $empty_string ) {

		$xgraph->{_linewidth} = $linewidth;
		$xgraph->{_note} =
			$xgraph->{_note} . ' linewidth=' . $xgraph->{_linewidth};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' linewidth=' . $xgraph->{_linewidth};

	}
	else {
		print("xgraph, line_widths, missing line_widths,\n");
	}
}

=head2 sub line_widths 

 line widths in pixels (0 for no lines)

=cut

sub line_widths {

	my ( $self, $linewidth ) = @_;
	if ( $linewidth ne $empty_string ) {

		# print("1. xgraph, line_widths, $linewidth\n");
		$xgraph->{_linewidth} = $linewidth;
		$xgraph->{_note} =
			$xgraph->{_note} . ' linewidth=' . $xgraph->{_linewidth};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' linewidth=' . $xgraph->{_linewidth};
		# print("2. xgraph, line_widths, $linewidth\n");

	}
	else {
		print("xgraph, line_widths, missing line_widths,\n");
	}
}

=head2 sub linewidth 

 line widths in pixels (0 for no lines

=cut

sub linewidth {

	my ( $self, $linewidth ) = @_;
	if ( $linewidth ne $empty_string ) {

		$xgraph->{_linewidth} = $linewidth;
		$xgraph->{_note} =
			$xgraph->{_note} . ' linewidth=' . $xgraph->{_linewidth};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' linewidth=' . $xgraph->{_linewidth};

	}
	else {
		print("xgraph, linewidth, missing linewidth,\n");
	}
}

=head2 sub mark 


=cut

sub mark {

	my ( $self, $mark ) = @_;
	if ( $mark ne $empty_string ) {

		$xgraph->{_mark} = $mark;
		$xgraph->{_note} = $xgraph->{_note} . ' mark=' . $xgraph->{_mark};
		$xgraph->{_Step} = $xgraph->{_Step} . ' mark=' . $xgraph->{_mark};

	}
	else {
		print("xgraph, mark, missing mark,\n");
	}
}

=head2 sub mark_indices 

indices of marks used to represent plotted points

=cut

sub mark_indices {

	my ( $self, $mark ) = @_;
	if ( $mark ne $empty_string ) {

		$xgraph->{_mark} = $mark;
		$xgraph->{_note} = $xgraph->{_note} . ' mark=' . $xgraph->{_mark};
		$xgraph->{_Step} = $xgraph->{_Step} . ' mark=' . $xgraph->{_mark};

	}
	else {
		print("xgraph, mark_indices, missing mark_indices,\n");
	}
}

=head2 sub marksize 


=cut

sub marksize {

	my ( $self, $marksize ) = @_;
	if ( $marksize ne $empty_string ) {

		$xgraph->{_marksize} = $marksize;
		$xgraph->{_note} =
			$xgraph->{_note} . ' marksize=' . $xgraph->{_marksize};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' marksize=' . $xgraph->{_marksize};

	}
	else {
		print("xgraph, marksize, missing marksize,\n");
	}
}

=head2 sub mark_size_pix 

 size of marks in pixels (0 for no marks)

=cut

sub mark_size_pix {

	my ( $self, $marksize ) = @_;
	if ( $marksize ne $empty_string ) {

		$xgraph->{_marksize} = $marksize;
		$xgraph->{_note} =
			$xgraph->{_note} . ' marksize=' . $xgraph->{_marksize};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' marksize=' . $xgraph->{_marksize};

	}
	else {
		print("xgraph, mark_size_pix, missing mark_size_pix,\n");
	}
}

=head2 sub n 


=cut

sub n {

	my ( $self, $n ) = @_;
	if ( $n ne $empty_string ) {

		$xgraph->{_n}    = $n;
		$xgraph->{_note} = $xgraph->{_note} . ' n=' . $xgraph->{_n};
		$xgraph->{_Step} = $xgraph->{_Step} . ' n=' . $xgraph->{_n};

	}
	else {
		print("xgraph, n, missing n,\n");
	}
}

=head2 sub num_points 


=cut

sub num_points {

	my ( $self, $n ) = @_;
	if ( $n ne $empty_string ) {

		$xgraph->{_n}    = $n;
		$xgraph->{_note} = $xgraph->{_note} . ' n=' . $xgraph->{_n};
		$xgraph->{_Step} = $xgraph->{_Step} . ' n=' . $xgraph->{_n};

	}
	else {
		print("xgraph, num_points, missing num_points,\n");
	}
}

=head2 sub nTic1 


=cut

sub nTic1 {

	my ( $self, $nTic1 ) = @_;
	if ( $nTic1 ne $empty_string ) {

		$xgraph->{_nTic1} = $nTic1;
		$xgraph->{_note}  = $xgraph->{_note} . ' nTic1=' . $xgraph->{_nTic1};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' nTic1=' . $xgraph->{_nTic1};

	}
	else {
		print("xgraph, nTic1, missing nTic1,\n");
	}
}

=head2 sub nTic2 


=cut

sub nTic2 {

	my ( $self, $nTic2 ) = @_;
	if ( $nTic2 ne $empty_string ) {

		$xgraph->{_nTic2} = $nTic2;
		$xgraph->{_note}  = $xgraph->{_note} . ' nTic2=' . $xgraph->{_nTic2};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' nTic2=' . $xgraph->{_nTic2};

	}
	else {
		print("xgraph, nTic2, missing nTic2,\n");
	}
}

=head2 sub nplot 


=cut

sub nplot {

	my ( $self, $nplot ) = @_;
	if ( $nplot ne $empty_string ) {

		$xgraph->{_nplot} = $nplot;
		$xgraph->{_note}  = $xgraph->{_note} . ' nplot=' . $xgraph->{_nplot};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' nplot=' . $xgraph->{_nplot};

	}
	else {
		print("xgraph, nplot, missing nplot,\n");
	}
}

=head2 sub num_minor_ticks_betw_distance_ticks 


=cut

sub num_minor_ticks_betw_distance_ticks {

    my ( $self, $nTic2 ) = @_;
    if ($nTic2) {

        $xgraph->{_nTic2} = $nTic2;
        $xgraph->{_note} =
          $xgraph->{_note} . ' nTic2=' . $xgraph->{_nTic2};
        $xgraph->{_Step} =
          $xgraph->{_Step} . ' nTic2=' . $xgraph->{_nTic2};

    }
    else {
        print(
            "xgraph, num_minor_ticks_betw_distance_ticks, missing nTic2,\n");
    }
}

=head2 sub num_minor_ticks_betw_time_ticks 


=cut

sub num_minor_ticks_betw_time_ticks {

    my ( $self, $nTic1 ) = @_;
    if ($nTic1) {

        $xgraph->{_nTic1} = $nTic1;
        $xgraph->{_note} =
          $xgraph->{_note} . ' nTic1=' . $xgraph->{_nTic1};
        $xgraph->{_Step} =
          $xgraph->{_Step} . ' nTic1=' . $xgraph->{_nTic1};

    }
    else {
        print("xgraph, num_minor_ticks_betw_time_ticks, missing nTic1,\n");
    }
}


=head2 sub orientation 

normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)

=cut

sub orientation {

	my ( $self, $style ) = @_;
	if ( $style ne $empty_string ) {

		$xgraph->{_style} = $style;
		$xgraph->{_note}  = $xgraph->{_note} . ' style=' . $xgraph->{_style};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' style=' . $xgraph->{_style};

	}
	else {
		print("xgraph, orientation, missing orientation,\n");
	}
}

=head2 sub pairs 


=cut

sub pairs {

	my ( $self, $pairs ) = @_;
	if ( $pairs ne $empty_string ) {

		$xgraph->{_pairs} = $pairs;
		$xgraph->{_note}  = $xgraph->{_note} . ' pairs=' . $xgraph->{_pairs};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' pairs=' . $xgraph->{_pairs};

	}
	else {
		print("xgraph, pairs, missing pairs,\n");
	}
}

=head2 sub reverse 


=cut

sub reverse {

	my ( $self, $reverse ) = @_;
	if ( $reverse ne $empty_string ) {

		$xgraph->{_reverse} = $reverse;
		$xgraph->{_note} =
			$xgraph->{_note} . ' reverse=' . $xgraph->{_reverse};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' reverse=' . $xgraph->{_reverse};

	}
	else {
		print("xgraph, reverse, missing reverse,\n");
	}
}

=head2 sub style 

normal (axis 1 horizontal, axis 2 vertical) or	
                        seismic (axis 1 vertical, axis 2 horizontal)

=cut

sub style {

	my ( $self, $style ) = @_;
	if ( $style ne $empty_string ) {

		$xgraph->{_style} = $style;
		$xgraph->{_note}  = $xgraph->{_note} . ' style=' . $xgraph->{_style};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' style=' . $xgraph->{_style};

	}
	else {
		print("xgraph, style, missing style,\n");
	}
}

=head2 sub title 

title for plot

=cut

sub title {

	my ( $self, $title ) = @_;
	if ( $title ne $empty_string ) {

		$xgraph->{_title} = $title;
		$xgraph->{_note}  = $xgraph->{_note} . ' title=' . $xgraph->{_title};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' title=' . $xgraph->{_title};

	}
	else {
		print("xgraph, title, missing title,\n");
	}
}

=head2 sub titleColor 


=cut

sub titleColor {

	my ( $self, $titleColor ) = @_;
	if ( $titleColor ne $empty_string ) {

		$xgraph->{_titleColor} = $titleColor;
		$xgraph->{_note} =
			$xgraph->{_note} . ' titleColor=' . $xgraph->{_titleColor};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' titleColor=' . $xgraph->{_titleColor};

	}
	else {
		print("xgraph, titleColor, missing titleColor,\n");
	}
}

=head2 sub titleFont 


=cut

sub titleFont {

	my ( $self, $titleFont ) = @_;
	if ( $titleFont ne $empty_string ) {

		$xgraph->{_titleFont} = $titleFont;
		$xgraph->{_note} =
			$xgraph->{_note} . ' titleFont=' . $xgraph->{_titleFont};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' titleFont=' . $xgraph->{_titleFont};

	}
	else {
		print("xgraph, titleFont, missing titleFont,\n");
	}
}

=head2 sub width 


=cut

sub width {

	my ( $self, $width ) = @_;
	if ( $width ne $empty_string ) {

		$xgraph->{_width} = $width;
		$xgraph->{_note}  = $xgraph->{_note} . ' width=' . $xgraph->{_width};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' width=' . $xgraph->{_width};

	}
	else {
		print("xgraph, width, missing width,\n");
	}
}

=head2 sub windowtitle 


=cut

sub windowtitle {

	my ( $self, $windowtitle ) = @_;
	if ( $windowtitle ne $empty_string ) {

		$xgraph->{_windowtitle} = $windowtitle;
		$xgraph->{_note} =
			$xgraph->{_note} . ' windowtitle=' . $xgraph->{_windowtitle};
		$xgraph->{_Step} =
			$xgraph->{_Step} . ' windowtitle=' . $xgraph->{_windowtitle};

	}
	else {
		print("xgraph, windowtitle, missing windowtitle,\n");
	}
}

=head2 sub x1_min 

value at which axis 1 begins

=cut

sub x1_min {

	my ( $self, $x1beg ) = @_;
	if ( $x1beg ne $empty_string ) {

		$xgraph->{_x1beg} = $x1beg;
		$xgraph->{_note}  = $xgraph->{_note} . ' x1beg=' . $xgraph->{_x1beg};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' x1beg=' . $xgraph->{_x1beg};

	}
	else {
		print("xgraph, x1_min, missing x1_min,\n");
	}
}

=head2 sub x1_max 

value at which axis 1 ends

=cut

sub x1_max {

	my ( $self, $x1end ) = @_;
	if ( $x1end ne $empty_string ) {

		$xgraph->{_x1end} = $x1end;
		$xgraph->{_note}  = $xgraph->{_note} . ' x1end=' . $xgraph->{_x1end};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' x1end=' . $xgraph->{_x1end};

	}
	else {
		print("xgraph, x1_max, missing x1_max,\n");
	}
}

=head2 sub x1beg 

value at which axis 1 begins

=cut

sub x1beg {

	my ( $self, $x1beg ) = @_;
	if ( $x1beg ne $empty_string ) {

		$xgraph->{_x1beg} = $x1beg;
		$xgraph->{_note}  = $xgraph->{_note} . ' x1beg=' . $xgraph->{_x1beg};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' x1beg=' . $xgraph->{_x1beg};

	}
	else {
		print("xgraph, x1beg, missing x1beg,\n");
	}
}

=head2 sub x1end 

value at which axis 1 ends

=cut

sub x1end {

	my ( $self, $x1end ) = @_;
	if ( $x1end ne $empty_string ) {

		$xgraph->{_x1end} = $x1end;
		$xgraph->{_note}  = $xgraph->{_note} . ' x1end=' . $xgraph->{_x1end};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' x1end=' . $xgraph->{_x1end};

	}
	else {
		print("xgraph, x1end, missing x1end,\n");
	}
}

=head2 sub x_label 

  label on axis 2

=cut

sub x_label {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$xgraph->{_label1} = $label2;
		$xgraph->{_note}   = $xgraph->{_note} . ' label2=' . $xgraph->{_label2};
		$xgraph->{_Step}   = $xgraph->{_Step} . ' label2=' . $xgraph->{_label2};

	}
	else {
		print("xgraph, x_label, missing x_label,\n");
	}
}

=head2 sub x2beg 

value at which axis 2 begins

=cut

sub x2beg {

	my ( $self, $x2beg ) = @_;
	if ( $x2beg ne $empty_string ) {

		$xgraph->{_x2beg} = $x2beg;
		$xgraph->{_note}  = $xgraph->{_note} . ' x2beg=' . $xgraph->{_x2beg};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' x2beg=' . $xgraph->{_x2beg};

	}
	else {
		print("xgraph, x2beg, missing x2beg,\n");
	}
}

=head2 sub x2_min 

value at which axis 2 begins

=cut

sub x2_min {

	my ( $self, $x2beg ) = @_;
	if ( $x2beg ne $empty_string ) {

		$xgraph->{_x2beg} = $x2beg;
		$xgraph->{_note}  = $xgraph->{_note} . ' x2beg=' . $xgraph->{_x2beg};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' x2beg=' . $xgraph->{_x2beg};

	}
	else {
		print("xgraph, x2_min, missing x2_min,\n");
	}
}

=head2 sub x2_max 

value at which axis 2 ends

=cut

sub x2_max {

	my ( $self, $x2end ) = @_;
	if ( $x2end ne $empty_string ) {

		$xgraph->{_x2end} = $x2end;
		$xgraph->{_note}  = $xgraph->{_note} . ' x2end=' . $xgraph->{_x2end};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' x2end=' . $xgraph->{_x2end};

	}
	else {
		print("xgraph, x2_max, missing x2_max,\n");
	}
}

=head2 sub x2end 

value at which axis 2 ends

=cut

sub x2end {

	my ( $self, $x2end ) = @_;
	if ( $x2end ne $empty_string ) {

		$xgraph->{_x2end} = $x2end;
		$xgraph->{_note}  = $xgraph->{_note} . ' x2end=' . $xgraph->{_x2end};
		$xgraph->{_Step}  = $xgraph->{_Step} . ' x2end=' . $xgraph->{_x2end};

	}
	else {
		print("xgraph, x2end, missing x2end,\n");
	}
}

=head2 sub y_label 

 label on axis 1

=cut

sub y_label {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$xgraph->{_label1} = $label1;
		$xgraph->{_note}   = $xgraph->{_note} . ' label1=' . $xgraph->{_label1};
		$xgraph->{_Step}   = $xgraph->{_Step} . ' label1=' . $xgraph->{_label1};

	}
	else {
		print("xgraph, y_label, missing y_label,\n");
	}
}

=head2 sub get_max_index
 
max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 34;

	return ($max_index);
}

1;
