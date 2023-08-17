package App::SeismicUnixGui::sunix::plot::psgraph;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 PSGRAPH - PostScript GRAPHer						

 Graphs n[i] pairs of (x,y) coordinates, for i = 1 to nplot.		



 psgraph n= [optional parameters] <binaryfile >postscriptfile		



 Required Parameters:							

 n                      array containing number of points per plot	



 Data formats supported:						

	1.a. x1,y1,x2,y2,...,xn,yn					

	  b. x1,x2,...,xn,y1,y2,...,yn (must set pairs=0)		

	2.   y1,y2,...,yn (must give non-zero d1[]=)			

	3.   x1,x2,...,xn (must give non-zero d2[]=)			

	4.   nil (must give non-zero d1[]= and non-zero d2[]=)		

  The formats may be repeated and mixed in any order, but if		

  formats 2-4 are used, the d1 and d2 arrays must be specified including

  d1[]=0.0 d2[]=0.0 entries for any internal occurences of format 1.	

  Similarly, the pairs array must contain place-keeping entries for	

  plots of formats 2-4 if they are mixed with both formats 1.a and 1.b.

  Also, if formats 2-4 are used with non-zero f1[] or f2[] entries, then

  the corresponding array(s) must be fully specified including f1[]=0.0

  and/or f2[]=0.0 entries for any internal occurences of format 1 or	

  formats 2-4 where the zero entries are desired.			



  Available colors are all the common ones and many more. The complete	

  list of 68 colors is in the file $CWPROOT/src/psplot/basic.c.	



 Optional Parameters:							

 nplot=number of n's    number of plots				

 d1=0.0,...             x sampling intervals (0.0 if x coordinates input)

 f1=0.0,...             first x values (not used if x coordinates input)

 d2=0.0,...             y sampling intervals (0.0 if y coordinates input)

 f2=0.0,...             first y values (not used if y coordinates input)

 pairs=1,...            =1 for data pairs in format 1.a, =0 for format 1.b

 linewidth=1.0,...      line widths (in points) (0.0 for no lines)	

 linegray=0.0,...       line gray levels (black=0.0 to white=1.0)	

 linecolor=none,...     line colors; none means use linegray		

                        Typical use: linecolor=red,yellow,blue,...	

 lineon=1.0,...         length of line segments for dashed lines (in points)

 lineoff=0.0,...        spacing between dashes (0.0 for solid line)	

 mark=0,1,2,3,...       indices of marks used to represent plotted points

 marksize=0.0,0.0,...   size of marks (0.0 for no marks)		

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

 style=normal           normal (axis 1 horizontal, axis 2 vertical) or	

                        seismic (axis 1 vertical, axis 2 horizontal)	

 reverse=0              =1 to reverse sequence of plotting curves      ",             /* JGHACK

 Note:	n1 and n2 are acceptable aliases for n and nplot, respectively.	



 mark index:                                                           

 1. asterisk                                                           

 2. x-cross                                                            

 3. open triangle                                                      

 4. open square                                                        

 5. open circle                                                        

 6. solid triangle                                                     

 7. solid square                                                       

 8. solid circle                                                       



 All color specifications may also be made in X Window style Hex format

 example:   axescolor=#255						



 Example:								

 psgraph n=50,100,20 d1=2.5,1,0.33 <datafile >psfile			

  plots three curves with equally spaced x values in one plot frame	

  x1-coordinates are x1(i) = f1+i*d1 for i = 1 to n (f1=0 by default)	

  number of x2's and then x2-coordinates for each curve are read	

  sequentially from datafile.						



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

=head2 User's notes (Juan Lorenzo)
untested

=cut


=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';


=head2 Import packages

=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

use App::SeismicUnixGui::misc::SeismicUnix qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $psgraph			= {
	_axescolor					=> '',
	_axeswidth					=> '',
	_d1					=> '',
	_d1num					=> '',
	_d2					=> '',
	_d2num					=> '',
	_f1					=> '',
	_f1num					=> '',
	_f2					=> '',
	_f2num					=> '',
	_grid1					=> '',
	_grid2					=> '',
	_gridcolor					=> '',
	_gridwidth					=> '',
	_hbox					=> '',
	_i					=> '',
	_label1					=> '',
	_label2					=> '',
	_labelfont					=> '',
	_labelsize					=> '',
	_linecolor					=> '',
	_linegray					=> '',
	_lineoff					=> '',
	_lineon					=> '',
	_linewidth					=> '',
	_mark					=> '',
	_marksize					=> '',
	_n					=> '',
	_n1tic					=> '',
	_n2tic					=> '',
	_nplot					=> '',
	_pairs					=> '',
	_reverse					=> '',
	_style					=> '',
	_ticwidth					=> '',
	_title					=> '',
	_titlecolor					=> '',
	_titlefont					=> '',
	_titlesize					=> '',
	_wbox					=> '',
	_x1beg					=> '',
	_x1end					=> '',
	_x2beg					=> '',
	_x2end					=> '',
	_xbox					=> '',
	_ybox					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$psgraph->{_Step}     = 'psgraph'.$psgraph->{_Step};
	return ( $psgraph->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$psgraph->{_note}     = 'psgraph'.$psgraph->{_note};
	return ( $psgraph->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$psgraph->{_axescolor}			= '';
		$psgraph->{_axeswidth}			= '';
		$psgraph->{_d1}			= '';
		$psgraph->{_d1num}			= '';
		$psgraph->{_d2}			= '';
		$psgraph->{_d2num}			= '';
		$psgraph->{_f1}			= '';
		$psgraph->{_f1num}			= '';
		$psgraph->{_f2}			= '';
		$psgraph->{_f2num}			= '';
		$psgraph->{_grid1}			= '';
		$psgraph->{_grid2}			= '';
		$psgraph->{_gridcolor}			= '';
		$psgraph->{_gridwidth}			= '';
		$psgraph->{_hbox}			= '';
		$psgraph->{_i}			= '';
		$psgraph->{_label1}			= '';
		$psgraph->{_label2}			= '';
		$psgraph->{_labelfont}			= '';
		$psgraph->{_labelsize}			= '';
		$psgraph->{_linecolor}			= '';
		$psgraph->{_linegray}			= '';
		$psgraph->{_lineoff}			= '';
		$psgraph->{_lineon}			= '';
		$psgraph->{_linewidth}			= '';
		$psgraph->{_mark}			= '';
		$psgraph->{_marksize}			= '';
		$psgraph->{_n}			= '';
		$psgraph->{_n1tic}			= '';
		$psgraph->{_n2tic}			= '';
		$psgraph->{_nplot}			= '';
		$psgraph->{_pairs}			= '';
		$psgraph->{_reverse}			= '';
		$psgraph->{_style}			= '';
		$psgraph->{_ticwidth}			= '';
		$psgraph->{_title}			= '';
		$psgraph->{_titlecolor}			= '';
		$psgraph->{_titlefont}			= '';
		$psgraph->{_titlesize}			= '';
		$psgraph->{_wbox}			= '';
		$psgraph->{_x1beg}			= '';
		$psgraph->{_x1end}			= '';
		$psgraph->{_x2beg}			= '';
		$psgraph->{_x2end}			= '';
		$psgraph->{_xbox}			= '';
		$psgraph->{_ybox}			= '';
		$psgraph->{_Step}			= '';
		$psgraph->{_note}			= '';
 }


=head2 sub axescolor 


=cut

 sub axescolor {

	my ( $self,$axescolor )		= @_;
	if ( $axescolor ne $empty_string ) {

		$psgraph->{_axescolor}		= $axescolor;
		$psgraph->{_note}		= $psgraph->{_note}.' axescolor='.$psgraph->{_axescolor};
		$psgraph->{_Step}		= $psgraph->{_Step}.' axescolor='.$psgraph->{_axescolor};

	} else { 
		print("psgraph, axescolor, missing axescolor,\n");
	 }
 }


=head2 sub axeswidth 


=cut

 sub axeswidth {

	my ( $self,$axeswidth )		= @_;
	if ( $axeswidth ne $empty_string ) {

		$psgraph->{_axeswidth}		= $axeswidth;
		$psgraph->{_note}		= $psgraph->{_note}.' axeswidth='.$psgraph->{_axeswidth};
		$psgraph->{_Step}		= $psgraph->{_Step}.' axeswidth='.$psgraph->{_axeswidth};

	} else { 
		print("psgraph, axeswidth, missing axeswidth,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$psgraph->{_d1}		= $d1;
		$psgraph->{_note}		= $psgraph->{_note}.' d1='.$psgraph->{_d1};
		$psgraph->{_Step}		= $psgraph->{_Step}.' d1='.$psgraph->{_d1};

	} else { 
		print("psgraph, d1, missing d1,\n");
	 }
 }


=head2 sub d1num 


=cut

 sub d1num {

	my ( $self,$d1num )		= @_;
	if ( $d1num ne $empty_string ) {

		$psgraph->{_d1num}		= $d1num;
		$psgraph->{_note}		= $psgraph->{_note}.' d1num='.$psgraph->{_d1num};
		$psgraph->{_Step}		= $psgraph->{_Step}.' d1num='.$psgraph->{_d1num};

	} else { 
		print("psgraph, d1num, missing d1num,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$psgraph->{_d2}		= $d2;
		$psgraph->{_note}		= $psgraph->{_note}.' d2='.$psgraph->{_d2};
		$psgraph->{_Step}		= $psgraph->{_Step}.' d2='.$psgraph->{_d2};

	} else { 
		print("psgraph, d2, missing d2,\n");
	 }
 }


=head2 sub d2num 


=cut

 sub d2num {

	my ( $self,$d2num )		= @_;
	if ( $d2num ne $empty_string ) {

		$psgraph->{_d2num}		= $d2num;
		$psgraph->{_note}		= $psgraph->{_note}.' d2num='.$psgraph->{_d2num};
		$psgraph->{_Step}		= $psgraph->{_Step}.' d2num='.$psgraph->{_d2num};

	} else { 
		print("psgraph, d2num, missing d2num,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$psgraph->{_f1}		= $f1;
		$psgraph->{_note}		= $psgraph->{_note}.' f1='.$psgraph->{_f1};
		$psgraph->{_Step}		= $psgraph->{_Step}.' f1='.$psgraph->{_f1};

	} else { 
		print("psgraph, f1, missing f1,\n");
	 }
 }


=head2 sub f1num 


=cut

 sub f1num {

	my ( $self,$f1num )		= @_;
	if ( $f1num ne $empty_string ) {

		$psgraph->{_f1num}		= $f1num;
		$psgraph->{_note}		= $psgraph->{_note}.' f1num='.$psgraph->{_f1num};
		$psgraph->{_Step}		= $psgraph->{_Step}.' f1num='.$psgraph->{_f1num};

	} else { 
		print("psgraph, f1num, missing f1num,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$psgraph->{_f2}		= $f2;
		$psgraph->{_note}		= $psgraph->{_note}.' f2='.$psgraph->{_f2};
		$psgraph->{_Step}		= $psgraph->{_Step}.' f2='.$psgraph->{_f2};

	} else { 
		print("psgraph, f2, missing f2,\n");
	 }
 }


=head2 sub f2num 


=cut

 sub f2num {

	my ( $self,$f2num )		= @_;
	if ( $f2num ne $empty_string ) {

		$psgraph->{_f2num}		= $f2num;
		$psgraph->{_note}		= $psgraph->{_note}.' f2num='.$psgraph->{_f2num};
		$psgraph->{_Step}		= $psgraph->{_Step}.' f2num='.$psgraph->{_f2num};

	} else { 
		print("psgraph, f2num, missing f2num,\n");
	 }
 }


=head2 sub grid1 


=cut

 sub grid1 {

	my ( $self,$grid1 )		= @_;
	if ( $grid1 ne $empty_string ) {

		$psgraph->{_grid1}		= $grid1;
		$psgraph->{_note}		= $psgraph->{_note}.' grid1='.$psgraph->{_grid1};
		$psgraph->{_Step}		= $psgraph->{_Step}.' grid1='.$psgraph->{_grid1};

	} else { 
		print("psgraph, grid1, missing grid1,\n");
	 }
 }


=head2 sub grid2 


=cut

 sub grid2 {

	my ( $self,$grid2 )		= @_;
	if ( $grid2 ne $empty_string ) {

		$psgraph->{_grid2}		= $grid2;
		$psgraph->{_note}		= $psgraph->{_note}.' grid2='.$psgraph->{_grid2};
		$psgraph->{_Step}		= $psgraph->{_Step}.' grid2='.$psgraph->{_grid2};

	} else { 
		print("psgraph, grid2, missing grid2,\n");
	 }
 }


=head2 sub gridcolor 


=cut

 sub gridcolor {

	my ( $self,$gridcolor )		= @_;
	if ( $gridcolor ne $empty_string ) {

		$psgraph->{_gridcolor}		= $gridcolor;
		$psgraph->{_note}		= $psgraph->{_note}.' gridcolor='.$psgraph->{_gridcolor};
		$psgraph->{_Step}		= $psgraph->{_Step}.' gridcolor='.$psgraph->{_gridcolor};

	} else { 
		print("psgraph, gridcolor, missing gridcolor,\n");
	 }
 }


=head2 sub gridwidth 


=cut

 sub gridwidth {

	my ( $self,$gridwidth )		= @_;
	if ( $gridwidth ne $empty_string ) {

		$psgraph->{_gridwidth}		= $gridwidth;
		$psgraph->{_note}		= $psgraph->{_note}.' gridwidth='.$psgraph->{_gridwidth};
		$psgraph->{_Step}		= $psgraph->{_Step}.' gridwidth='.$psgraph->{_gridwidth};

	} else { 
		print("psgraph, gridwidth, missing gridwidth,\n");
	 }
 }


=head2 sub hbox 


=cut

 sub hbox {

	my ( $self,$hbox )		= @_;
	if ( $hbox ne $empty_string ) {

		$psgraph->{_hbox}		= $hbox;
		$psgraph->{_note}		= $psgraph->{_note}.' hbox='.$psgraph->{_hbox};
		$psgraph->{_Step}		= $psgraph->{_Step}.' hbox='.$psgraph->{_hbox};

	} else { 
		print("psgraph, hbox, missing hbox,\n");
	 }
 }


=head2 sub i 


=cut

 sub i {

	my ( $self,$i )		= @_;
	if ( $i ne $empty_string ) {

		$psgraph->{_i}		= $i;
		$psgraph->{_note}		= $psgraph->{_note}.' i='.$psgraph->{_i};
		$psgraph->{_Step}		= $psgraph->{_Step}.' i='.$psgraph->{_i};

	} else { 
		print("psgraph, i, missing i,\n");
	 }
 }


=head2 sub label1 


=cut

 sub label1 {

	my ( $self,$label1 )		= @_;
	if ( $label1 ne $empty_string ) {

		$psgraph->{_label1}		= $label1;
		$psgraph->{_note}		= $psgraph->{_note}.' label1='.$psgraph->{_label1};
		$psgraph->{_Step}		= $psgraph->{_Step}.' label1='.$psgraph->{_label1};

	} else { 
		print("psgraph, label1, missing label1,\n");
	 }
 }


=head2 sub label2 


=cut

 sub label2 {

	my ( $self,$label2 )		= @_;
	if ( $label2 ne $empty_string ) {

		$psgraph->{_label2}		= $label2;
		$psgraph->{_note}		= $psgraph->{_note}.' label2='.$psgraph->{_label2};
		$psgraph->{_Step}		= $psgraph->{_Step}.' label2='.$psgraph->{_label2};

	} else { 
		print("psgraph, label2, missing label2,\n");
	 }
 }


=head2 sub labelfont 


=cut

 sub labelfont {

	my ( $self,$labelfont )		= @_;
	if ( $labelfont ne $empty_string ) {

		$psgraph->{_labelfont}		= $labelfont;
		$psgraph->{_note}		= $psgraph->{_note}.' labelfont='.$psgraph->{_labelfont};
		$psgraph->{_Step}		= $psgraph->{_Step}.' labelfont='.$psgraph->{_labelfont};

	} else { 
		print("psgraph, labelfont, missing labelfont,\n");
	 }
 }


=head2 sub labelsize 


=cut

 sub labelsize {

	my ( $self,$labelsize )		= @_;
	if ( $labelsize ne $empty_string ) {

		$psgraph->{_labelsize}		= $labelsize;
		$psgraph->{_note}		= $psgraph->{_note}.' labelsize='.$psgraph->{_labelsize};
		$psgraph->{_Step}		= $psgraph->{_Step}.' labelsize='.$psgraph->{_labelsize};

	} else { 
		print("psgraph, labelsize, missing labelsize,\n");
	 }
 }


=head2 sub linecolor 


=cut

 sub linecolor {

	my ( $self,$linecolor )		= @_;
	if ( $linecolor ne $empty_string ) {

		$psgraph->{_linecolor}		= $linecolor;
		$psgraph->{_note}		= $psgraph->{_note}.' linecolor='.$psgraph->{_linecolor};
		$psgraph->{_Step}		= $psgraph->{_Step}.' linecolor='.$psgraph->{_linecolor};

	} else { 
		print("psgraph, linecolor, missing linecolor,\n");
	 }
 }


=head2 sub linegray 


=cut

 sub linegray {

	my ( $self,$linegray )		= @_;
	if ( $linegray ne $empty_string ) {

		$psgraph->{_linegray}		= $linegray;
		$psgraph->{_note}		= $psgraph->{_note}.' linegray='.$psgraph->{_linegray};
		$psgraph->{_Step}		= $psgraph->{_Step}.' linegray='.$psgraph->{_linegray};

	} else { 
		print("psgraph, linegray, missing linegray,\n");
	 }
 }


=head2 sub lineoff 


=cut

 sub lineoff {

	my ( $self,$lineoff )		= @_;
	if ( $lineoff ne $empty_string ) {

		$psgraph->{_lineoff}		= $lineoff;
		$psgraph->{_note}		= $psgraph->{_note}.' lineoff='.$psgraph->{_lineoff};
		$psgraph->{_Step}		= $psgraph->{_Step}.' lineoff='.$psgraph->{_lineoff};

	} else { 
		print("psgraph, lineoff, missing lineoff,\n");
	 }
 }


=head2 sub lineon 


=cut

 sub lineon {

	my ( $self,$lineon )		= @_;
	if ( $lineon ne $empty_string ) {

		$psgraph->{_lineon}		= $lineon;
		$psgraph->{_note}		= $psgraph->{_note}.' lineon='.$psgraph->{_lineon};
		$psgraph->{_Step}		= $psgraph->{_Step}.' lineon='.$psgraph->{_lineon};

	} else { 
		print("psgraph, lineon, missing lineon,\n");
	 }
 }


=head2 sub linewidth 


=cut

 sub linewidth {

	my ( $self,$linewidth )		= @_;
	if ( $linewidth ne $empty_string ) {

		$psgraph->{_linewidth}		= $linewidth;
		$psgraph->{_note}		= $psgraph->{_note}.' linewidth='.$psgraph->{_linewidth};
		$psgraph->{_Step}		= $psgraph->{_Step}.' linewidth='.$psgraph->{_linewidth};

	} else { 
		print("psgraph, linewidth, missing linewidth,\n");
	 }
 }


=head2 sub mark 


=cut

 sub mark {

	my ( $self,$mark )		= @_;
	if ( $mark ne $empty_string ) {

		$psgraph->{_mark}		= $mark;
		$psgraph->{_note}		= $psgraph->{_note}.' mark='.$psgraph->{_mark};
		$psgraph->{_Step}		= $psgraph->{_Step}.' mark='.$psgraph->{_mark};

	} else { 
		print("psgraph, mark, missing mark,\n");
	 }
 }


=head2 sub marksize 


=cut

 sub marksize {

	my ( $self,$marksize )		= @_;
	if ( $marksize ne $empty_string ) {

		$psgraph->{_marksize}		= $marksize;
		$psgraph->{_note}		= $psgraph->{_note}.' marksize='.$psgraph->{_marksize};
		$psgraph->{_Step}		= $psgraph->{_Step}.' marksize='.$psgraph->{_marksize};

	} else { 
		print("psgraph, marksize, missing marksize,\n");
	 }
 }


=head2 sub n 


=cut

 sub n {

	my ( $self,$n )		= @_;
	if ( $n ne $empty_string ) {

		$psgraph->{_n}		= $n;
		$psgraph->{_note}		= $psgraph->{_note}.' n='.$psgraph->{_n};
		$psgraph->{_Step}		= $psgraph->{_Step}.' n='.$psgraph->{_n};

	} else { 
		print("psgraph, n, missing n,\n");
	 }
 }


=head2 sub n1tic 


=cut

 sub n1tic {

	my ( $self,$n1tic )		= @_;
	if ( $n1tic ne $empty_string ) {

		$psgraph->{_n1tic}		= $n1tic;
		$psgraph->{_note}		= $psgraph->{_note}.' n1tic='.$psgraph->{_n1tic};
		$psgraph->{_Step}		= $psgraph->{_Step}.' n1tic='.$psgraph->{_n1tic};

	} else { 
		print("psgraph, n1tic, missing n1tic,\n");
	 }
 }


=head2 sub n2tic 


=cut

 sub n2tic {

	my ( $self,$n2tic )		= @_;
	if ( $n2tic ne $empty_string ) {

		$psgraph->{_n2tic}		= $n2tic;
		$psgraph->{_note}		= $psgraph->{_note}.' n2tic='.$psgraph->{_n2tic};
		$psgraph->{_Step}		= $psgraph->{_Step}.' n2tic='.$psgraph->{_n2tic};

	} else { 
		print("psgraph, n2tic, missing n2tic,\n");
	 }
 }


=head2 sub nplot 


=cut

 sub nplot {

	my ( $self,$nplot )		= @_;
	if ( $nplot ne $empty_string ) {

		$psgraph->{_nplot}		= $nplot;
		$psgraph->{_note}		= $psgraph->{_note}.' nplot='.$psgraph->{_nplot};
		$psgraph->{_Step}		= $psgraph->{_Step}.' nplot='.$psgraph->{_nplot};

	} else { 
		print("psgraph, nplot, missing nplot,\n");
	 }
 }


=head2 sub pairs 


=cut

 sub pairs {

	my ( $self,$pairs )		= @_;
	if ( $pairs ne $empty_string ) {

		$psgraph->{_pairs}		= $pairs;
		$psgraph->{_note}		= $psgraph->{_note}.' pairs='.$psgraph->{_pairs};
		$psgraph->{_Step}		= $psgraph->{_Step}.' pairs='.$psgraph->{_pairs};

	} else { 
		print("psgraph, pairs, missing pairs,\n");
	 }
 }


=head2 sub reverse 


=cut

 sub reverse {

	my ( $self,$reverse )		= @_;
	if ( $reverse ne $empty_string ) {

		$psgraph->{_reverse}		= $reverse;
		$psgraph->{_note}		= $psgraph->{_note}.' reverse='.$psgraph->{_reverse};
		$psgraph->{_Step}		= $psgraph->{_Step}.' reverse='.$psgraph->{_reverse};

	} else { 
		print("psgraph, reverse, missing reverse,\n");
	 }
 }


=head2 sub style 


=cut

 sub style {

	my ( $self,$style )		= @_;
	if ( $style ne $empty_string ) {

		$psgraph->{_style}		= $style;
		$psgraph->{_note}		= $psgraph->{_note}.' style='.$psgraph->{_style};
		$psgraph->{_Step}		= $psgraph->{_Step}.' style='.$psgraph->{_style};

	} else { 
		print("psgraph, style, missing style,\n");
	 }
 }


=head2 sub ticwidth 


=cut

 sub ticwidth {

	my ( $self,$ticwidth )		= @_;
	if ( $ticwidth ne $empty_string ) {

		$psgraph->{_ticwidth}		= $ticwidth;
		$psgraph->{_note}		= $psgraph->{_note}.' ticwidth='.$psgraph->{_ticwidth};
		$psgraph->{_Step}		= $psgraph->{_Step}.' ticwidth='.$psgraph->{_ticwidth};

	} else { 
		print("psgraph, ticwidth, missing ticwidth,\n");
	 }
 }


=head2 sub title 


=cut

 sub title {

	my ( $self,$title )		= @_;
	if ( $title ne $empty_string ) {

		$psgraph->{_title}		= $title;
		$psgraph->{_note}		= $psgraph->{_note}.' title='.$psgraph->{_title};
		$psgraph->{_Step}		= $psgraph->{_Step}.' title='.$psgraph->{_title};

	} else { 
		print("psgraph, title, missing title,\n");
	 }
 }


=head2 sub titlecolor 


=cut

 sub titlecolor {

	my ( $self,$titlecolor )		= @_;
	if ( $titlecolor ne $empty_string ) {

		$psgraph->{_titlecolor}		= $titlecolor;
		$psgraph->{_note}		= $psgraph->{_note}.' titlecolor='.$psgraph->{_titlecolor};
		$psgraph->{_Step}		= $psgraph->{_Step}.' titlecolor='.$psgraph->{_titlecolor};

	} else { 
		print("psgraph, titlecolor, missing titlecolor,\n");
	 }
 }


=head2 sub titlefont 


=cut

 sub titlefont {

	my ( $self,$titlefont )		= @_;
	if ( $titlefont ne $empty_string ) {

		$psgraph->{_titlefont}		= $titlefont;
		$psgraph->{_note}		= $psgraph->{_note}.' titlefont='.$psgraph->{_titlefont};
		$psgraph->{_Step}		= $psgraph->{_Step}.' titlefont='.$psgraph->{_titlefont};

	} else { 
		print("psgraph, titlefont, missing titlefont,\n");
	 }
 }


=head2 sub titlesize 


=cut

 sub titlesize {

	my ( $self,$titlesize )		= @_;
	if ( $titlesize ne $empty_string ) {

		$psgraph->{_titlesize}		= $titlesize;
		$psgraph->{_note}		= $psgraph->{_note}.' titlesize='.$psgraph->{_titlesize};
		$psgraph->{_Step}		= $psgraph->{_Step}.' titlesize='.$psgraph->{_titlesize};

	} else { 
		print("psgraph, titlesize, missing titlesize,\n");
	 }
 }


=head2 sub wbox 


=cut

 sub wbox {

	my ( $self,$wbox )		= @_;
	if ( $wbox ne $empty_string ) {

		$psgraph->{_wbox}		= $wbox;
		$psgraph->{_note}		= $psgraph->{_note}.' wbox='.$psgraph->{_wbox};
		$psgraph->{_Step}		= $psgraph->{_Step}.' wbox='.$psgraph->{_wbox};

	} else { 
		print("psgraph, wbox, missing wbox,\n");
	 }
 }


=head2 sub x1beg 


=cut

 sub x1beg {

	my ( $self,$x1beg )		= @_;
	if ( $x1beg ne $empty_string ) {

		$psgraph->{_x1beg}		= $x1beg;
		$psgraph->{_note}		= $psgraph->{_note}.' x1beg='.$psgraph->{_x1beg};
		$psgraph->{_Step}		= $psgraph->{_Step}.' x1beg='.$psgraph->{_x1beg};

	} else { 
		print("psgraph, x1beg, missing x1beg,\n");
	 }
 }


=head2 sub x1end 


=cut

 sub x1end {

	my ( $self,$x1end )		= @_;
	if ( $x1end ne $empty_string ) {

		$psgraph->{_x1end}		= $x1end;
		$psgraph->{_note}		= $psgraph->{_note}.' x1end='.$psgraph->{_x1end};
		$psgraph->{_Step}		= $psgraph->{_Step}.' x1end='.$psgraph->{_x1end};

	} else { 
		print("psgraph, x1end, missing x1end,\n");
	 }
 }


=head2 sub x2beg 


=cut

 sub x2beg {

	my ( $self,$x2beg )		= @_;
	if ( $x2beg ne $empty_string ) {

		$psgraph->{_x2beg}		= $x2beg;
		$psgraph->{_note}		= $psgraph->{_note}.' x2beg='.$psgraph->{_x2beg};
		$psgraph->{_Step}		= $psgraph->{_Step}.' x2beg='.$psgraph->{_x2beg};

	} else { 
		print("psgraph, x2beg, missing x2beg,\n");
	 }
 }


=head2 sub x2end 


=cut

 sub x2end {

	my ( $self,$x2end )		= @_;
	if ( $x2end ne $empty_string ) {

		$psgraph->{_x2end}		= $x2end;
		$psgraph->{_note}		= $psgraph->{_note}.' x2end='.$psgraph->{_x2end};
		$psgraph->{_Step}		= $psgraph->{_Step}.' x2end='.$psgraph->{_x2end};

	} else { 
		print("psgraph, x2end, missing x2end,\n");
	 }
 }


=head2 sub xbox 


=cut

 sub xbox {

	my ( $self,$xbox )		= @_;
	if ( $xbox ne $empty_string ) {

		$psgraph->{_xbox}		= $xbox;
		$psgraph->{_note}		= $psgraph->{_note}.' xbox='.$psgraph->{_xbox};
		$psgraph->{_Step}		= $psgraph->{_Step}.' xbox='.$psgraph->{_xbox};

	} else { 
		print("psgraph, xbox, missing xbox,\n");
	 }
 }


=head2 sub ybox 


=cut

 sub ybox {

	my ( $self,$ybox )		= @_;
	if ( $ybox ne $empty_string ) {

		$psgraph->{_ybox}		= $ybox;
		$psgraph->{_note}		= $psgraph->{_note}.' ybox='.$psgraph->{_ybox};
		$psgraph->{_Step}		= $psgraph->{_Step}.' ybox='.$psgraph->{_ybox};

	} else { 
		print("psgraph, ybox, missing ybox,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 45;

    return($max_index);
}
 
 
1;
