package App::SeismicUnixGui::sunix::plot::xcontour;

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
 XCONTOUR - X CONTOUR plot of f(x1,x2) via vector plot call		



 xcontour n1= [optional parameters] <binaryfile [>psplotfile]		



 X Functionality:							

 Button 1	Zoom with rubberband box				

 Button 2	Show mouse (x1,x2) coordinates while pressed		

 q or Q key	Quit 							

 s key		Save current mouse (x1,x2) location to file		

 p or P key	Plot current window with pswigb	(only from disk files)	



 Required Parameters:							

 n1                     number of samples in 1st (fast) dimension	



 Optional Parameters:							

 d1=1.0                 sampling interval in 1st dimension		

 f1=0.0                 first sample in 1st dimension			

 x1=f1,f1+d1,...        array of sampled values in 1nd dimension	

 n2=all                 number of samples in 2nd (slow) dimension	

 d2=1.0                 sampling interval in 2nd dimension		

 f2=0.0                 first sample in 2nd dimension			

 x2=f2,f2+d2,...        array of sampled values in 2nd dimension	

 mpicks=/dev/tty        file to save mouse picks in			

 verbose=1              =1 for info printed on stderr (0 for no info)	

 nc=5                   number of contour values                       

 dc=(zmax-zmin)/nc      contour interval                               

 fc=min+dc              first contour                                  

 c=fc,fc+dc,...         array of contour values                        

 cwidth=1.0,...         array of contour line widths                   

 ccolor=none,...        array of contour colors; none means use cgray  

 cdash=0.0,...          array of dash spacings (0.0 for solid)         

 labelcf=1              first labeled contour (1,2,3,...)              

 labelcper=1            label every labelcper-th contour               

 nlabelc=nc             number of labeled contours (0 no contour label)

 nplaces=6              number of decimal places in contour labeling	

 xbox=50                x in pixels of upper left corner of window	

 ybox=50                y in pixels of upper left corner of window	

 wbox=550               width in pixels of window			

 hbox=700               height in pixels of window			

 x1beg=x1min            value at which axis 1 begins			

 x1end=x1max            value at which axis 1 ends			

 d1num=0.0              numbered tic interval on axis 1 (0.0 for automatic)

 f1num=x1min            first numbered tic on axis 1 (used if d1num not 0.0)

 n1tic=1                number of tics per numbered tic on axis 1	

 grid1=none             grid lines on axis 1 - none, dot, dash, or solid

 x2beg=x2min            value at which axis 2 begins			

 x2end=x2max            value at which axis 2 ends			

 d2num=0.0              numbered tic interval on axis 2 (0.0 for automatic)

 f2num=x2min            first numbered tic on axis 2 (used if d2num not 0.0)

 n2tic=1                number of tics per numbered tic on axis 2	

 grid2=none             grid lines on axis 2 - none, dot, dash, or solid

 label2=                label on axis 2				

 labelfont=Erg14        font name for axes labels			

 title=                 title of plot					

 titlefont=Rom22        font name for title				

 windowtitle=xwigb      title on window				

 labelcolor=blue        color for axes labels				

 titlecolor=red         color for title				

 gridcolor=blue         color for grid lines				

 labelccolor=black      color of contour labels                        ",   

 labelcfont=fixed       font name for contour labels                   

 style=seismic		 normal (axis 1 horizontal, axis 2 vertical) or	

			 seismic (axis 1 vertical, axis 2 horizontal)	





 Notes:								

 For some reason the contour might slight differ from ones generated   

 by pscontour (propably due to the pixel nature of the plot            

 coordinates)                                                          



 The line width of unlabeled contours is designed as a quarter of that	

 of labeled contours. 							





 Author: Morten Wendell Pedersen, Aarhus University 



 All the coding is based on snippets taken from xwigb, ximage and pscontour

 All I have done is put the parts together and put in some bugs ;-)



 So credits should go to the authors of these packages... 



 Caveats and Notes:

 The code has been developed under Linux 1.3.20/Xfree 3.1.2E (X11 6.1)

 with gcc-2.7.0 But hopefully it should work on other platforms as well



 Since all the contours are drawn by Vector plot call's everytime the

 Window is exposed, the exposing can be darn slow 

 OOPS This should be history... Now I keep my window content with backing

 store so I won't have to redraw my window unless I really have to...



 Portability Question: I guess I should check if the display supports

 backingstore and redraw if it doesn't (see DoesBackingStore(3) )

 I have to be able to use CWBackingStore==Always (other values can be

 NonUseful and WhenMapped



 Since I put the contour labels everytime I draw one contour level the area 

 that contains the label will be crossed by the the next contour lines...

 (this bug also seems to be present in pscontour)

 To fix this I have to redraw all the labels after been through all

 the contour calls

 Right now I can't see a way to fix this without actually to through

 the entire label positioning again....Overkill I would say



 

 The relative short length of the contour segments will propably mask the

 cdash settings

 which means it is disposable (but I know how to draw dashed lines :)

 A way of fixing this could be to get all connected point and then use

 XDrawlines or XDrawSegments... just an idea...No idea if it'll work. 



 I think there is a bug in xContour since my plot coordinates increase

 North and west ward instead of south and eastward



   I need to check the Self Doc so if the right parameters are described

   (I have been through it a couple of times but....)



   All functions need a heavy cleanup for unused variables

   I suppose there is a couple of memory leaks due to missing free'ing of

 numerous pointers (especially fonts,GC's & colors could be a problem...



   I have to browse through the internal pscontour call... basically what

 I have done is just putting pscontour instead of pswigb... Instead of

 repositioning the input file  pointer (which doesnt work with pipes) one

 should consider the use of temporary file

   or write your zoombox to pscontour (...how one does that?)



  Wish List:

   The use of cgray's unused until now... I guess I'll need to allocate

 a gray Colormap  -> meaning that the code not will run at other display

 than 8 bit Pseudocolor :( (with the use of present version of the colormap

 library (code in $CWPROOT/src/xplot/lib ) )



  The format of contour label should be open for the user.. 

  

  It could be nice if one could choose to have a pixmap (like ximage )

 underlying  the contours... this should be defined either by the input

 data  or by a seperate file

  eg useful for viewing traveltime contours on top a plot of the velocity

 field



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

use App::SeismicUnixGui::misc::SeismicUnix qw($go $in $off $on $out $ps $to $suffix_ascii $suffix_bin $suffix_ps $suffix_segy $suffix_su);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';


=head2 instantiation of packages

=cut

my $get					= L_SU_global_constants->new();
my $Project				= Project_config->new();
my $DATA_SEISMIC_SU		= $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN	= $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT	= $Project->DATA_SEISMIC_TXT();

my $PS_SEISMIC      	= $Project->PS_SEISMIC();

my $var				= $get->var();
my $on				= $var->{_on};
my $off				= $var->{_off};
my $true			= $var->{_true};
my $false			= $var->{_false};
my $empty_string	= $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $xcontour			= {
	_CWBackingStore					=> '',
	_c					=> '',
	_ccolor					=> '',
	_cdash					=> '',
	_cwidth					=> '',
	_d1					=> '',
	_d1num					=> '',
	_d2					=> '',
	_d2num					=> '',
	_dc					=> '',
	_f1					=> '',
	_f1num					=> '',
	_f2					=> '',
	_f2num					=> '',
	_fc					=> '',
	_grid1					=> '',
	_grid2					=> '',
	_gridcolor					=> '',
	_hbox					=> '',
	_label2					=> '',
	_labelccolor					=> '',
	_labelcf					=> '',
	_labelcfont					=> '',
	_labelcolor					=> '',
	_labelcper					=> '',
	_labelfont					=> '',
	_mpicks					=> '',
	_n1					=> '',
	_n1tic					=> '',
	_n2					=> '',
	_n2tic					=> '',
	_nc					=> '',
	_nlabelc					=> '',
	_nplaces					=> '',
	_style					=> '',
	_title					=> '',
	_titlecolor					=> '',
	_titlefont					=> '',
	_verbose					=> '',
	_wbox					=> '',
	_windowtitle					=> '',
	_x1					=> '',
	_x1beg					=> '',
	_x1end					=> '',
	_x2					=> '',
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

	$xcontour->{_Step}     = 'xcontour'.$xcontour->{_Step};
	return ( $xcontour->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$xcontour->{_note}     = 'xcontour'.$xcontour->{_note};
	return ( $xcontour->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$xcontour->{_CWBackingStore}			= '';
		$xcontour->{_c}			= '';
		$xcontour->{_ccolor}			= '';
		$xcontour->{_cdash}			= '';
		$xcontour->{_cwidth}			= '';
		$xcontour->{_d1}			= '';
		$xcontour->{_d1num}			= '';
		$xcontour->{_d2}			= '';
		$xcontour->{_d2num}			= '';
		$xcontour->{_dc}			= '';
		$xcontour->{_f1}			= '';
		$xcontour->{_f1num}			= '';
		$xcontour->{_f2}			= '';
		$xcontour->{_f2num}			= '';
		$xcontour->{_fc}			= '';
		$xcontour->{_grid1}			= '';
		$xcontour->{_grid2}			= '';
		$xcontour->{_gridcolor}			= '';
		$xcontour->{_hbox}			= '';
		$xcontour->{_label2}			= '';
		$xcontour->{_labelccolor}			= '';
		$xcontour->{_labelcf}			= '';
		$xcontour->{_labelcfont}			= '';
		$xcontour->{_labelcolor}			= '';
		$xcontour->{_labelcper}			= '';
		$xcontour->{_labelfont}			= '';
		$xcontour->{_mpicks}			= '';
		$xcontour->{_n1}			= '';
		$xcontour->{_n1tic}			= '';
		$xcontour->{_n2}			= '';
		$xcontour->{_n2tic}			= '';
		$xcontour->{_nc}			= '';
		$xcontour->{_nlabelc}			= '';
		$xcontour->{_nplaces}			= '';
		$xcontour->{_style}			= '';
		$xcontour->{_title}			= '';
		$xcontour->{_titlecolor}			= '';
		$xcontour->{_titlefont}			= '';
		$xcontour->{_verbose}			= '';
		$xcontour->{_wbox}			= '';
		$xcontour->{_windowtitle}			= '';
		$xcontour->{_x1}			= '';
		$xcontour->{_x1beg}			= '';
		$xcontour->{_x1end}			= '';
		$xcontour->{_x2}			= '';
		$xcontour->{_x2beg}			= '';
		$xcontour->{_x2end}			= '';
		$xcontour->{_xbox}			= '';
		$xcontour->{_ybox}			= '';
		$xcontour->{_Step}			= '';
		$xcontour->{_note}			= '';
 }


=head2 sub CWBackingStore 


=cut

 sub CWBackingStore {

	my ( $self,$CWBackingStore )		= @_;
	if ( $CWBackingStore ne $empty_string ) {

		$xcontour->{_CWBackingStore}		= $CWBackingStore;
		$xcontour->{_note}		= $xcontour->{_note}.' CWBackingStore='.$xcontour->{_CWBackingStore};
		$xcontour->{_Step}		= $xcontour->{_Step}.' CWBackingStore='.$xcontour->{_CWBackingStore};

	} else { 
		print("xcontour, CWBackingStore, missing CWBackingStore,\n");
	 }
 }


=head2 sub c 


=cut

 sub c {

	my ( $self,$c )		= @_;
	if ( $c ne $empty_string ) {

		$xcontour->{_c}		= $c;
		$xcontour->{_note}		= $xcontour->{_note}.' c='.$xcontour->{_c};
		$xcontour->{_Step}		= $xcontour->{_Step}.' c='.$xcontour->{_c};

	} else { 
		print("xcontour, c, missing c,\n");
	 }
 }


=head2 sub ccolor 


=cut

 sub ccolor {

	my ( $self,$ccolor )		= @_;
	if ( $ccolor ne $empty_string ) {

		$xcontour->{_ccolor}		= $ccolor;
		$xcontour->{_note}		= $xcontour->{_note}.' ccolor='.$xcontour->{_ccolor};
		$xcontour->{_Step}		= $xcontour->{_Step}.' ccolor='.$xcontour->{_ccolor};

	} else { 
		print("xcontour, ccolor, missing ccolor,\n");
	 }
 }


=head2 sub cdash 


=cut

 sub cdash {

	my ( $self,$cdash )		= @_;
	if ( $cdash ne $empty_string ) {

		$xcontour->{_cdash}		= $cdash;
		$xcontour->{_note}		= $xcontour->{_note}.' cdash='.$xcontour->{_cdash};
		$xcontour->{_Step}		= $xcontour->{_Step}.' cdash='.$xcontour->{_cdash};

	} else { 
		print("xcontour, cdash, missing cdash,\n");
	 }
 }


=head2 sub cwidth 


=cut

 sub cwidth {

	my ( $self,$cwidth )		= @_;
	if ( $cwidth ne $empty_string ) {

		$xcontour->{_cwidth}		= $cwidth;
		$xcontour->{_note}		= $xcontour->{_note}.' cwidth='.$xcontour->{_cwidth};
		$xcontour->{_Step}		= $xcontour->{_Step}.' cwidth='.$xcontour->{_cwidth};

	} else { 
		print("xcontour, cwidth, missing cwidth,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$xcontour->{_d1}		= $d1;
		$xcontour->{_note}		= $xcontour->{_note}.' d1='.$xcontour->{_d1};
		$xcontour->{_Step}		= $xcontour->{_Step}.' d1='.$xcontour->{_d1};

	} else { 
		print("xcontour, d1, missing d1,\n");
	 }
 }


=head2 sub d1num 


=cut

 sub d1num {

	my ( $self,$d1num )		= @_;
	if ( $d1num ne $empty_string ) {

		$xcontour->{_d1num}		= $d1num;
		$xcontour->{_note}		= $xcontour->{_note}.' d1num='.$xcontour->{_d1num};
		$xcontour->{_Step}		= $xcontour->{_Step}.' d1num='.$xcontour->{_d1num};

	} else { 
		print("xcontour, d1num, missing d1num,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$xcontour->{_d2}		= $d2;
		$xcontour->{_note}		= $xcontour->{_note}.' d2='.$xcontour->{_d2};
		$xcontour->{_Step}		= $xcontour->{_Step}.' d2='.$xcontour->{_d2};

	} else { 
		print("xcontour, d2, missing d2,\n");
	 }
 }


=head2 sub d2num 


=cut

 sub d2num {

	my ( $self,$d2num )		= @_;
	if ( $d2num ne $empty_string ) {

		$xcontour->{_d2num}		= $d2num;
		$xcontour->{_note}		= $xcontour->{_note}.' d2num='.$xcontour->{_d2num};
		$xcontour->{_Step}		= $xcontour->{_Step}.' d2num='.$xcontour->{_d2num};

	} else { 
		print("xcontour, d2num, missing d2num,\n");
	 }
 }


=head2 sub dc 


=cut

 sub dc {

	my ( $self,$dc )		= @_;
	if ( $dc ne $empty_string ) {

		$xcontour->{_dc}		= $dc;
		$xcontour->{_note}		= $xcontour->{_note}.' dc='.$xcontour->{_dc};
		$xcontour->{_Step}		= $xcontour->{_Step}.' dc='.$xcontour->{_dc};

	} else { 
		print("xcontour, dc, missing dc,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$xcontour->{_f1}		= $f1;
		$xcontour->{_note}		= $xcontour->{_note}.' f1='.$xcontour->{_f1};
		$xcontour->{_Step}		= $xcontour->{_Step}.' f1='.$xcontour->{_f1};

	} else { 
		print("xcontour, f1, missing f1,\n");
	 }
 }


=head2 sub f1num 


=cut

 sub f1num {

	my ( $self,$f1num )		= @_;
	if ( $f1num ne $empty_string ) {

		$xcontour->{_f1num}		= $f1num;
		$xcontour->{_note}		= $xcontour->{_note}.' f1num='.$xcontour->{_f1num};
		$xcontour->{_Step}		= $xcontour->{_Step}.' f1num='.$xcontour->{_f1num};

	} else { 
		print("xcontour, f1num, missing f1num,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$xcontour->{_f2}		= $f2;
		$xcontour->{_note}		= $xcontour->{_note}.' f2='.$xcontour->{_f2};
		$xcontour->{_Step}		= $xcontour->{_Step}.' f2='.$xcontour->{_f2};

	} else { 
		print("xcontour, f2, missing f2,\n");
	 }
 }


=head2 sub f2num 


=cut

 sub f2num {

	my ( $self,$f2num )		= @_;
	if ( $f2num ne $empty_string ) {

		$xcontour->{_f2num}		= $f2num;
		$xcontour->{_note}		= $xcontour->{_note}.' f2num='.$xcontour->{_f2num};
		$xcontour->{_Step}		= $xcontour->{_Step}.' f2num='.$xcontour->{_f2num};

	} else { 
		print("xcontour, f2num, missing f2num,\n");
	 }
 }


=head2 sub fc 


=cut

 sub fc {

	my ( $self,$fc )		= @_;
	if ( $fc ne $empty_string ) {

		$xcontour->{_fc}		= $fc;
		$xcontour->{_note}		= $xcontour->{_note}.' fc='.$xcontour->{_fc};
		$xcontour->{_Step}		= $xcontour->{_Step}.' fc='.$xcontour->{_fc};

	} else { 
		print("xcontour, fc, missing fc,\n");
	 }
 }


=head2 sub grid1 


=cut

 sub grid1 {

	my ( $self,$grid1 )		= @_;
	if ( $grid1 ne $empty_string ) {

		$xcontour->{_grid1}		= $grid1;
		$xcontour->{_note}		= $xcontour->{_note}.' grid1='.$xcontour->{_grid1};
		$xcontour->{_Step}		= $xcontour->{_Step}.' grid1='.$xcontour->{_grid1};

	} else { 
		print("xcontour, grid1, missing grid1,\n");
	 }
 }


=head2 sub grid2 


=cut

 sub grid2 {

	my ( $self,$grid2 )		= @_;
	if ( $grid2 ne $empty_string ) {

		$xcontour->{_grid2}		= $grid2;
		$xcontour->{_note}		= $xcontour->{_note}.' grid2='.$xcontour->{_grid2};
		$xcontour->{_Step}		= $xcontour->{_Step}.' grid2='.$xcontour->{_grid2};

	} else { 
		print("xcontour, grid2, missing grid2,\n");
	 }
 }


=head2 sub gridcolor 


=cut

 sub gridcolor {

	my ( $self,$gridcolor )		= @_;
	if ( $gridcolor ne $empty_string ) {

		$xcontour->{_gridcolor}		= $gridcolor;
		$xcontour->{_note}		= $xcontour->{_note}.' gridcolor='.$xcontour->{_gridcolor};
		$xcontour->{_Step}		= $xcontour->{_Step}.' gridcolor='.$xcontour->{_gridcolor};

	} else { 
		print("xcontour, gridcolor, missing gridcolor,\n");
	 }
 }


=head2 sub hbox 


=cut

 sub hbox {

	my ( $self,$hbox )		= @_;
	if ( $hbox ne $empty_string ) {

		$xcontour->{_hbox}		= $hbox;
		$xcontour->{_note}		= $xcontour->{_note}.' hbox='.$xcontour->{_hbox};
		$xcontour->{_Step}		= $xcontour->{_Step}.' hbox='.$xcontour->{_hbox};

	} else { 
		print("xcontour, hbox, missing hbox,\n");
	 }
 }


=head2 sub label2 


=cut

 sub label2 {

	my ( $self,$label2 )		= @_;
	if ( $label2 ne $empty_string ) {

		$xcontour->{_label2}		= $label2;
		$xcontour->{_note}		= $xcontour->{_note}.' label2='.$xcontour->{_label2};
		$xcontour->{_Step}		= $xcontour->{_Step}.' label2='.$xcontour->{_label2};

	} else { 
		print("xcontour, label2, missing label2,\n");
	 }
 }


=head2 sub labelccolor 


=cut

 sub labelccolor {

	my ( $self,$labelccolor )		= @_;
	if ( $labelccolor ne $empty_string ) {

		$xcontour->{_labelccolor}		= $labelccolor;
		$xcontour->{_note}		= $xcontour->{_note}.' labelccolor='.$xcontour->{_labelccolor};
		$xcontour->{_Step}		= $xcontour->{_Step}.' labelccolor='.$xcontour->{_labelccolor};

	} else { 
		print("xcontour, labelccolor, missing labelccolor,\n");
	 }
 }


=head2 sub labelcf 


=cut

 sub labelcf {

	my ( $self,$labelcf )		= @_;
	if ( $labelcf ne $empty_string ) {

		$xcontour->{_labelcf}		= $labelcf;
		$xcontour->{_note}		= $xcontour->{_note}.' labelcf='.$xcontour->{_labelcf};
		$xcontour->{_Step}		= $xcontour->{_Step}.' labelcf='.$xcontour->{_labelcf};

	} else { 
		print("xcontour, labelcf, missing labelcf,\n");
	 }
 }


=head2 sub labelcfont 


=cut

 sub labelcfont {

	my ( $self,$labelcfont )		= @_;
	if ( $labelcfont ne $empty_string ) {

		$xcontour->{_labelcfont}		= $labelcfont;
		$xcontour->{_note}		= $xcontour->{_note}.' labelcfont='.$xcontour->{_labelcfont};
		$xcontour->{_Step}		= $xcontour->{_Step}.' labelcfont='.$xcontour->{_labelcfont};

	} else { 
		print("xcontour, labelcfont, missing labelcfont,\n");
	 }
 }


=head2 sub labelcolor 


=cut

 sub labelcolor {

	my ( $self,$labelcolor )		= @_;
	if ( $labelcolor ne $empty_string ) {

		$xcontour->{_labelcolor}		= $labelcolor;
		$xcontour->{_note}		= $xcontour->{_note}.' labelcolor='.$xcontour->{_labelcolor};
		$xcontour->{_Step}		= $xcontour->{_Step}.' labelcolor='.$xcontour->{_labelcolor};

	} else { 
		print("xcontour, labelcolor, missing labelcolor,\n");
	 }
 }


=head2 sub labelcper 


=cut

 sub labelcper {

	my ( $self,$labelcper )		= @_;
	if ( $labelcper ne $empty_string ) {

		$xcontour->{_labelcper}		= $labelcper;
		$xcontour->{_note}		= $xcontour->{_note}.' labelcper='.$xcontour->{_labelcper};
		$xcontour->{_Step}		= $xcontour->{_Step}.' labelcper='.$xcontour->{_labelcper};

	} else { 
		print("xcontour, labelcper, missing labelcper,\n");
	 }
 }


=head2 sub labelfont 


=cut

 sub labelfont {

	my ( $self,$labelfont )		= @_;
	if ( $labelfont ne $empty_string ) {

		$xcontour->{_labelfont}		= $labelfont;
		$xcontour->{_note}		= $xcontour->{_note}.' labelfont='.$xcontour->{_labelfont};
		$xcontour->{_Step}		= $xcontour->{_Step}.' labelfont='.$xcontour->{_labelfont};

	} else { 
		print("xcontour, labelfont, missing labelfont,\n");
	 }
 }


=head2 sub mpicks 


=cut

 sub mpicks {

	my ( $self,$mpicks )		= @_;
	if ( $mpicks ne $empty_string ) {

		$xcontour->{_mpicks}		= $mpicks;
		$xcontour->{_note}		= $xcontour->{_note}.' mpicks='.$xcontour->{_mpicks};
		$xcontour->{_Step}		= $xcontour->{_Step}.' mpicks='.$xcontour->{_mpicks};

	} else { 
		print("xcontour, mpicks, missing mpicks,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$xcontour->{_n1}		= $n1;
		$xcontour->{_note}		= $xcontour->{_note}.' n1='.$xcontour->{_n1};
		$xcontour->{_Step}		= $xcontour->{_Step}.' n1='.$xcontour->{_n1};

	} else { 
		print("xcontour, n1, missing n1,\n");
	 }
 }


=head2 sub n1tic 


=cut

 sub n1tic {

	my ( $self,$n1tic )		= @_;
	if ( $n1tic ne $empty_string ) {

		$xcontour->{_n1tic}		= $n1tic;
		$xcontour->{_note}		= $xcontour->{_note}.' n1tic='.$xcontour->{_n1tic};
		$xcontour->{_Step}		= $xcontour->{_Step}.' n1tic='.$xcontour->{_n1tic};

	} else { 
		print("xcontour, n1tic, missing n1tic,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$xcontour->{_n2}		= $n2;
		$xcontour->{_note}		= $xcontour->{_note}.' n2='.$xcontour->{_n2};
		$xcontour->{_Step}		= $xcontour->{_Step}.' n2='.$xcontour->{_n2};

	} else { 
		print("xcontour, n2, missing n2,\n");
	 }
 }


=head2 sub n2tic 


=cut

 sub n2tic {

	my ( $self,$n2tic )		= @_;
	if ( $n2tic ne $empty_string ) {

		$xcontour->{_n2tic}		= $n2tic;
		$xcontour->{_note}		= $xcontour->{_note}.' n2tic='.$xcontour->{_n2tic};
		$xcontour->{_Step}		= $xcontour->{_Step}.' n2tic='.$xcontour->{_n2tic};

	} else { 
		print("xcontour, n2tic, missing n2tic,\n");
	 }
 }


=head2 sub nc 


=cut

 sub nc {

	my ( $self,$nc )		= @_;
	if ( $nc ne $empty_string ) {

		$xcontour->{_nc}		= $nc;
		$xcontour->{_note}		= $xcontour->{_note}.' nc='.$xcontour->{_nc};
		$xcontour->{_Step}		= $xcontour->{_Step}.' nc='.$xcontour->{_nc};

	} else { 
		print("xcontour, nc, missing nc,\n");
	 }
 }


=head2 sub nlabelc 


=cut

 sub nlabelc {

	my ( $self,$nlabelc )		= @_;
	if ( $nlabelc ne $empty_string ) {

		$xcontour->{_nlabelc}		= $nlabelc;
		$xcontour->{_note}		= $xcontour->{_note}.' nlabelc='.$xcontour->{_nlabelc};
		$xcontour->{_Step}		= $xcontour->{_Step}.' nlabelc='.$xcontour->{_nlabelc};

	} else { 
		print("xcontour, nlabelc, missing nlabelc,\n");
	 }
 }


=head2 sub nplaces 


=cut

 sub nplaces {

	my ( $self,$nplaces )		= @_;
	if ( $nplaces ne $empty_string ) {

		$xcontour->{_nplaces}		= $nplaces;
		$xcontour->{_note}		= $xcontour->{_note}.' nplaces='.$xcontour->{_nplaces};
		$xcontour->{_Step}		= $xcontour->{_Step}.' nplaces='.$xcontour->{_nplaces};

	} else { 
		print("xcontour, nplaces, missing nplaces,\n");
	 }
 }


=head2 sub style 


=cut

 sub style {

	my ( $self,$style )		= @_;
	if ( $style ne $empty_string ) {

		$xcontour->{_style}		= $style;
		$xcontour->{_note}		= $xcontour->{_note}.' style='.$xcontour->{_style};
		$xcontour->{_Step}		= $xcontour->{_Step}.' style='.$xcontour->{_style};

	} else { 
		print("xcontour, style, missing style,\n");
	 }
 }


=head2 sub title 


=cut

 sub title {

	my ( $self,$title )		= @_;
	if ( $title ne $empty_string ) {

		$xcontour->{_title}		= $title;
		$xcontour->{_note}		= $xcontour->{_note}.' title='.$xcontour->{_title};
		$xcontour->{_Step}		= $xcontour->{_Step}.' title='.$xcontour->{_title};

	} else { 
		print("xcontour, title, missing title,\n");
	 }
 }


=head2 sub titlecolor 


=cut

 sub titlecolor {

	my ( $self,$titlecolor )		= @_;
	if ( $titlecolor ne $empty_string ) {

		$xcontour->{_titlecolor}		= $titlecolor;
		$xcontour->{_note}		= $xcontour->{_note}.' titlecolor='.$xcontour->{_titlecolor};
		$xcontour->{_Step}		= $xcontour->{_Step}.' titlecolor='.$xcontour->{_titlecolor};

	} else { 
		print("xcontour, titlecolor, missing titlecolor,\n");
	 }
 }


=head2 sub titlefont 


=cut

 sub titlefont {

	my ( $self,$titlefont )		= @_;
	if ( $titlefont ne $empty_string ) {

		$xcontour->{_titlefont}		= $titlefont;
		$xcontour->{_note}		= $xcontour->{_note}.' titlefont='.$xcontour->{_titlefont};
		$xcontour->{_Step}		= $xcontour->{_Step}.' titlefont='.$xcontour->{_titlefont};

	} else { 
		print("xcontour, titlefont, missing titlefont,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$xcontour->{_verbose}		= $verbose;
		$xcontour->{_note}		= $xcontour->{_note}.' verbose='.$xcontour->{_verbose};
		$xcontour->{_Step}		= $xcontour->{_Step}.' verbose='.$xcontour->{_verbose};

	} else { 
		print("xcontour, verbose, missing verbose,\n");
	 }
 }


=head2 sub wbox 


=cut

 sub wbox {

	my ( $self,$wbox )		= @_;
	if ( $wbox ne $empty_string ) {

		$xcontour->{_wbox}		= $wbox;
		$xcontour->{_note}		= $xcontour->{_note}.' wbox='.$xcontour->{_wbox};
		$xcontour->{_Step}		= $xcontour->{_Step}.' wbox='.$xcontour->{_wbox};

	} else { 
		print("xcontour, wbox, missing wbox,\n");
	 }
 }


=head2 sub windowtitle 


=cut

 sub windowtitle {

	my ( $self,$windowtitle )		= @_;
	if ( $windowtitle ne $empty_string ) {

		$xcontour->{_windowtitle}		= $windowtitle;
		$xcontour->{_note}		= $xcontour->{_note}.' windowtitle='.$xcontour->{_windowtitle};
		$xcontour->{_Step}		= $xcontour->{_Step}.' windowtitle='.$xcontour->{_windowtitle};

	} else { 
		print("xcontour, windowtitle, missing windowtitle,\n");
	 }
 }


=head2 sub x1 


=cut

 sub x1 {

	my ( $self,$x1 )		= @_;
	if ( $x1 ne $empty_string ) {

		$xcontour->{_x1}		= $x1;
		$xcontour->{_note}		= $xcontour->{_note}.' x1='.$xcontour->{_x1};
		$xcontour->{_Step}		= $xcontour->{_Step}.' x1='.$xcontour->{_x1};

	} else { 
		print("xcontour, x1, missing x1,\n");
	 }
 }


=head2 sub x1beg 


=cut

 sub x1beg {

	my ( $self,$x1beg )		= @_;
	if ( $x1beg ne $empty_string ) {

		$xcontour->{_x1beg}		= $x1beg;
		$xcontour->{_note}		= $xcontour->{_note}.' x1beg='.$xcontour->{_x1beg};
		$xcontour->{_Step}		= $xcontour->{_Step}.' x1beg='.$xcontour->{_x1beg};

	} else { 
		print("xcontour, x1beg, missing x1beg,\n");
	 }
 }


=head2 sub x1end 


=cut

 sub x1end {

	my ( $self,$x1end )		= @_;
	if ( $x1end ne $empty_string ) {

		$xcontour->{_x1end}		= $x1end;
		$xcontour->{_note}		= $xcontour->{_note}.' x1end='.$xcontour->{_x1end};
		$xcontour->{_Step}		= $xcontour->{_Step}.' x1end='.$xcontour->{_x1end};

	} else { 
		print("xcontour, x1end, missing x1end,\n");
	 }
 }


=head2 sub x2 


=cut

 sub x2 {

	my ( $self,$x2 )		= @_;
	if ( $x2 ne $empty_string ) {

		$xcontour->{_x2}		= $x2;
		$xcontour->{_note}		= $xcontour->{_note}.' x2='.$xcontour->{_x2};
		$xcontour->{_Step}		= $xcontour->{_Step}.' x2='.$xcontour->{_x2};

	} else { 
		print("xcontour, x2, missing x2,\n");
	 }
 }


=head2 sub x2beg 


=cut

 sub x2beg {

	my ( $self,$x2beg )		= @_;
	if ( $x2beg ne $empty_string ) {

		$xcontour->{_x2beg}		= $x2beg;
		$xcontour->{_note}		= $xcontour->{_note}.' x2beg='.$xcontour->{_x2beg};
		$xcontour->{_Step}		= $xcontour->{_Step}.' x2beg='.$xcontour->{_x2beg};

	} else { 
		print("xcontour, x2beg, missing x2beg,\n");
	 }
 }


=head2 sub x2end 


=cut

 sub x2end {

	my ( $self,$x2end )		= @_;
	if ( $x2end ne $empty_string ) {

		$xcontour->{_x2end}		= $x2end;
		$xcontour->{_note}		= $xcontour->{_note}.' x2end='.$xcontour->{_x2end};
		$xcontour->{_Step}		= $xcontour->{_Step}.' x2end='.$xcontour->{_x2end};

	} else { 
		print("xcontour, x2end, missing x2end,\n");
	 }
 }


=head2 sub xbox 


=cut

 sub xbox {

	my ( $self,$xbox )		= @_;
	if ( $xbox ne $empty_string ) {

		$xcontour->{_xbox}		= $xbox;
		$xcontour->{_note}		= $xcontour->{_note}.' xbox='.$xcontour->{_xbox};
		$xcontour->{_Step}		= $xcontour->{_Step}.' xbox='.$xcontour->{_xbox};

	} else { 
		print("xcontour, xbox, missing xbox,\n");
	 }
 }


=head2 sub ybox 


=cut

 sub ybox {

	my ( $self,$ybox )		= @_;
	if ( $ybox ne $empty_string ) {

		$xcontour->{_ybox}		= $ybox;
		$xcontour->{_note}		= $xcontour->{_note}.' ybox='.$xcontour->{_ybox};
		$xcontour->{_Step}		= $xcontour->{_Step}.' ybox='.$xcontour->{_ybox};

	} else { 
		print("xcontour, ybox, missing ybox,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 47;

    return($max_index);
}
 
 
1;
