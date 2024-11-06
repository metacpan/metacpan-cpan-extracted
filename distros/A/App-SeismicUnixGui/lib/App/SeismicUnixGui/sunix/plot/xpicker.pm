package App::SeismicUnixGui::sunix::plot::xpicker;

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
 XPICKER - X wiggle-trace plot of f(x1,x2) via Bitmap with PICKing	



 xpicker n1= [optional parameters] <binaryfile				



 X Menu functionality:							

    Pick Filename Window	default is pick_file			

    Load		load an existing Pick Filename			

    Save		save to Pick Filename				

    View only/Pick	default is View, click to enable Picking	

    Add/Delete		default is Add, click to delete picks		

    Cross off/on	default is Cross off, click to enable Crosshairs



 In View mode:								

    a or page up keys          enhance clipping by 10%                 

    c or page down keys        reduce clipping by 10%                  

    up,down,left,right keys    move zoom window by half width/height   

    i or +(keypad)             zoom in by factor 2                     

    o or -(keypad)             zoom out by factor 2                    

    l 				lock the zoom while moving the coursor	

    u 				unlock the zoom 			



 Notes:								

	Menu selections and toggles ("clicks") are made with button 1	

	Pick selections are made with button 3				

	Edit a pick selection by dragging it with button 3 down	or	

	by making a new pick on that trace				

	Reaching the window limits while moving within changes the zoom	

	factor in this direction. The use of zoom locking(l) disables it



 Other X Mouse functionality:						

 Mouse Button 1	Zoom with rubberbox				

 Mouse Button 2	Show mouse (x1,x2) coordinates while pressed	



 The following keys are active in View Only mode:			



 Required Parameters:							

 n1=		number of samples in 1st (fast) dimension		



 Optional Parameters:							

 mpicks=pick_file	name of output (input) pick file		

 d1=1.0		sampling interval in 1st dimension		

 f1=d1		  first sample in 1st dimension				

 n2=all		 number of samples in 2nd (slow) dimension	

 d2=1.0		 sampling interval in 2nd dimension		

 f2=d2		  first sample in 2nd dimension				

 x2=f2,f2+d2,...	array of sampled values in 2nd dimension	

 bias=0.0	       data value corresponding to location along axis 2

 perc=100.0	     percentile for determining clip			

 clip=(perc percentile) data values < bias+clip and > bias-clip are clipped

 xcur=1.0	       wiggle excursion in traces corresponding to clip	

 wt=1		   =0 for no wiggle-trace; =1 for wiggle-trace		

 va=1		   =0 for no variable-area; =1 for variable-area fill	

                        =2 for variable area, solid/grey fill          

                        SHADING: 2<=va<=5  va=2 light grey, va=5 black 

 verbose=1	      =1 for info printed on stderr (0 for no info)	

 xbox=50		x in pixels of upper left corner of window	

 ybox=50		y in pixels of upper left corner of window	

 wbox=550	      	width in pixels of window			

 hbox=700		height in pixels of window			

 x1beg=x1min		value at which axis 1 begins			

 x1end=x1max		value at which axis 1 ends			

 d1num=0.0		 numbered tic interval on axis 1 (0.0 for automatic)

 f1num=x1min		first numbered tic on axis 1 (used if d1num not 0.0)

 n1tic=1		number of tics per numbered tic on axis 1	

 grid1=none		grid lines on axis 1 - none, dot, dash, or solid

 label1=		label on axis 1					

 x2beg=x2min		value at which axis 2 begins			

 x2end=x2max		value at which axis 2 ends			

 d2num=0.0		 numbered tic interval on axis 2 (0.0 for automatic)

 f2num=x2min		first numbered tic on axis 2 (used if d2num not 0.0)

 n2tic=1		number of tics per numbered tic on axis 2	

 grid2=none		grid lines on axis 2 - none, dot, dash, or solid 

 label2=		label on axis 2					

 labelfont=Erg14	font name for axes labels			

 title=		title of plot					

 titlefont=Rom22	font name for title				

 labelcolor=blue	color for axes labels				

 titlecolor=red	color for title					

 gridcolor=blue	color for grid lines				

 style=seismic		normal (axis 1 horizontal, axis 2 vertical) or	

 		    	seismic (axis 1 vertical, axis 2 horizontal)	

 endian=		=0 little endian, =1 big endian			

 interp=0		no sinc interpolation				

			=1 perform sinc interpolation			

 x2file=		file of "acceptable" x2 values		

 x1x2=1		save picks in the order (x1,x2) 		

 			=0 save picks in the order (x2,x1) 		



 Notes:								

 Xpicker will try to detect the endian value of the X-display and will	

 set it to the right value. If it gets obviously wrong information the 

 endian value will be set to the endian value of the machine that is	

 given at compile time as the value of CWPENDIAN defined in cwp.h	

 and set via the compile time flag ENDIANFLAG in Makefile.config.	



 The only time that you might want to change the value of the endian   

 variable is if you are viewing traces on a machine with a different   

 byte order than the machine you are creating the traces on AND if for 

 some reason the automaic detection of the display byte order fails.   

 Set endian to that of the machine you	are viewing the traces on.	



 The interp flag is useful for making better quality wiggle trace for	

 making plots from screen dumps. However, this flag assumes that the	

 data are purely oscillatory. This option may not be appropriate for all

 data sets.								



 If the x2file=  option is set, then the values from the specified file

 will define the set of "acceptable" values of x2 for xpicker to	

 output. The format is a single column of ASCII values. The number of  

 specified values is arbitrary.					



 Such a file can be built from an SU data set via:			

     sugethw < sudata key=offset output=geom > x2example 		



 If the value of x2file= is not set, then				

 xpicker will use the values specified via: x2=.,.,.,. or those that are", 

 computed from the values of f2=  and d2= as being the "acceptible

 values.								



 See the selfdoc of  suxpicker  for information on using key fields from

 the SU trace headers directly. 					







 Author:  Dave Hale, Colorado School of Mines, 08/09/90

 with picking by Wenying Cai of University of Utah.

 Endian stuff by Morten Pedersen and John Stockwell of CWP.

 Interp stuff by Tony Kocurko of Memorial University of Newfoundland

 Modified to include acceptable values by Bill Lutter of the

     Department of Geology, University of Wisconsin 10/96

 MODIFIED:  P. Michaels, Boise State Univeristy  29 December 2000

            Added solid/grey color scheme for peaks/troughs

 

 G.Klein, IFG Kiel University, 2003-09-29, added cursor scrolling and

            interactive change of zoom and clipping.



 NOTES:

 Interactive picker improved to allow x-axis of picks to be

 coordinated with "key=header" parameter set in driver routine

 suxpicker. Multiple picks per trace are now allowed.



  Input:

  The command line of suxpicker is unchanged.  The parameter"key=header"

  set in  suxpicker controls a) trace x-axis  displayed via xpicker and

  b) the header values in the first column of a pick file either read in

     or written out from xpicker c) header values expected in optional file

      or written out from xpicker c) header values expected in optional file

     x2file= which reads into xpicker allowable trace x-axis values.



   a) example command line:  suxpicker key=offset < shot10.plotpik



   b) pick file format:

	x-axis_value_1 time_1

	x-axis_value_2 time_2  

	x-axis_value_3 time_3

	etc.

	x-axis_value_n time_n



	pick file example:

         1000.000000 0.500000

         2000.000000 1.000000

         3000.000000 1.500000

         4000.000000 2.000000

         5000.000000 2.500000



  c)  format of optional file x2file=:

    	   header_value_1

 	   header_value_2

	   etc.

	   header_val_m



       If file "x2file=" exists in directory from which suxpicker is

      invoked, then these trace header x-axis values are the only allowable

      x-axis pick values used in the pick "add" or "delete" menu operation.

      Header values do not need to be sorted or 1 to 1 with input traces.

      Further, pick file x-axis values can be read into xpicker via load

      operation without having to match key_pickx1_val x-axis values and

      can also be rewritten out an output pickfile.  As indicated, only

      the "add" and "delete" pick operations are influenced by existence

       of this file.



      Offset header values for "x2file=" can be generated by the

      command line:



      sugethw < su_segyfile key=offset output=geom >  x2examplefile=



      Output: Only change is in format of pick_file (format described above).

      If x2file= file exists then x-axis value of added picks

      will be forced to nearest allowable trace x-axis value (input values

      of x2file= file). If x2file= is not set, then the values of x2 

      that are either assigned uniformly to the traces via f2 and d2,

      or by the vector of values of x2=.,.,.,.    will be the "acceptable"

      values.



    Strategy:

   a) malloc() and realloc() used to dynamically allocate memory

	  for array of x-axis value read in from optional file

	  x2file=.  This is done in function read_keyval().



	  b) The pick file dimensions are set in main program via malloc()

	  and then initialized (*apick)[i].picked = FALSE) in function

	  init_picks().  The pick file is declared as pick_t **apick, in

	  order to use realloc() as needed in functions load_picks where the

	  pick file is read in and edit_picks where picks are added.  The

	  call to realloc() and further initializing is performed in

	  function realloc_picks().



	  c) If x2file= file exists the mouse derived x-axis value

	  for a pick to be added is checked against allowable x-axis values

	  to find the closest match via function add_pick called from

	  edit_picks.  If the pick is to be deleted, first a search is done

	  to find the closest x-axis value, then the existing pick values

	  are searched to find the closest radial value (x**2 + t**2) via

	  function del_pick() invoked from edit_picks.



	  d) Code modifications are limited to above mentioned functions,

	  except for additional parameters passed to functions edit_picks,

	  load_picks, save_picks, and check_buttons.

 



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

my $xpicker			= {
	_bias					=> '',
	_clip					=> '',
	_d1					=> '',
	_d1num					=> '',
	_d2					=> '',
	_d2num					=> '',
	_endian					=> '',
	_f1					=> '',
	_f1num					=> '',
	_f2					=> '',
	_f2num					=> '',
	_grid1					=> '',
	_grid2					=> '',
	_gridcolor					=> '',
	_hbox					=> '',
	_interp					=> '',
	_key					=> '',
	_label1					=> '',
	_label2					=> '',
	_labelcolor					=> '',
	_labelfont					=> '',
	_mpicks					=> '',
	_n1					=> '',
	_n1tic					=> '',
	_n2					=> '',
	_n2tic					=> '',
	_perc					=> '',
	_picked					=> '',
	_style					=> '',
	_title					=> '',
	_titlecolor					=> '',
	_titlefont					=> '',
	_va					=> '',
	_verbose					=> '',
	_wbox					=> '',
	_wt					=> '',
	_x1beg					=> '',
	_x1end					=> '',
	_x1x2					=> '',
	_x2					=> '',
	_x2beg					=> '',
	_x2end					=> '',
	_x2file					=> '',
	_xbox					=> '',
	_xcur					=> '',
	_ybox					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$xpicker->{_Step}     = 'xpicker'.$xpicker->{_Step};
	return ( $xpicker->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$xpicker->{_note}     = 'xpicker'.$xpicker->{_note};
	return ( $xpicker->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$xpicker->{_bias}			= '';
		$xpicker->{_clip}			= '';
		$xpicker->{_d1}			= '';
		$xpicker->{_d1num}			= '';
		$xpicker->{_d2}			= '';
		$xpicker->{_d2num}			= '';
		$xpicker->{_endian}			= '';
		$xpicker->{_f1}			= '';
		$xpicker->{_f1num}			= '';
		$xpicker->{_f2}			= '';
		$xpicker->{_f2num}			= '';
		$xpicker->{_grid1}			= '';
		$xpicker->{_grid2}			= '';
		$xpicker->{_gridcolor}			= '';
		$xpicker->{_hbox}			= '';
		$xpicker->{_interp}			= '';
		$xpicker->{_key}			= '';
		$xpicker->{_label1}			= '';
		$xpicker->{_label2}			= '';
		$xpicker->{_labelcolor}			= '';
		$xpicker->{_labelfont}			= '';
		$xpicker->{_mpicks}			= '';
		$xpicker->{_n1}			= '';
		$xpicker->{_n1tic}			= '';
		$xpicker->{_n2}			= '';
		$xpicker->{_n2tic}			= '';
		$xpicker->{_perc}			= '';
		$xpicker->{_picked}			= '';
		$xpicker->{_style}			= '';
		$xpicker->{_title}			= '';
		$xpicker->{_titlecolor}			= '';
		$xpicker->{_titlefont}			= '';
		$xpicker->{_va}			= '';
		$xpicker->{_verbose}			= '';
		$xpicker->{_wbox}			= '';
		$xpicker->{_wt}			= '';
		$xpicker->{_x1beg}			= '';
		$xpicker->{_x1end}			= '';
		$xpicker->{_x1x2}			= '';
		$xpicker->{_x2}			= '';
		$xpicker->{_x2beg}			= '';
		$xpicker->{_x2end}			= '';
		$xpicker->{_x2file}			= '';
		$xpicker->{_xbox}			= '';
		$xpicker->{_xcur}			= '';
		$xpicker->{_ybox}			= '';
		$xpicker->{_Step}			= '';
		$xpicker->{_note}			= '';
 }


=head2 sub bias 


=cut

 sub bias {

	my ( $self,$bias )		= @_;
	if ( $bias ne $empty_string ) {

		$xpicker->{_bias}		= $bias;
		$xpicker->{_note}		= $xpicker->{_note}.' bias='.$xpicker->{_bias};
		$xpicker->{_Step}		= $xpicker->{_Step}.' bias='.$xpicker->{_bias};

	} else { 
		print("xpicker, bias, missing bias,\n");
	 }
 }


=head2 sub clip 


=cut

 sub clip {

	my ( $self,$clip )		= @_;
	if ( $clip ne $empty_string ) {

		$xpicker->{_clip}		= $clip;
		$xpicker->{_note}		= $xpicker->{_note}.' clip='.$xpicker->{_clip};
		$xpicker->{_Step}		= $xpicker->{_Step}.' clip='.$xpicker->{_clip};

	} else { 
		print("xpicker, clip, missing clip,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$xpicker->{_d1}		= $d1;
		$xpicker->{_note}		= $xpicker->{_note}.' d1='.$xpicker->{_d1};
		$xpicker->{_Step}		= $xpicker->{_Step}.' d1='.$xpicker->{_d1};

	} else { 
		print("xpicker, d1, missing d1,\n");
	 }
 }


=head2 sub d1num 


=cut

 sub d1num {

	my ( $self,$d1num )		= @_;
	if ( $d1num ne $empty_string ) {

		$xpicker->{_d1num}		= $d1num;
		$xpicker->{_note}		= $xpicker->{_note}.' d1num='.$xpicker->{_d1num};
		$xpicker->{_Step}		= $xpicker->{_Step}.' d1num='.$xpicker->{_d1num};

	} else { 
		print("xpicker, d1num, missing d1num,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$xpicker->{_d2}		= $d2;
		$xpicker->{_note}		= $xpicker->{_note}.' d2='.$xpicker->{_d2};
		$xpicker->{_Step}		= $xpicker->{_Step}.' d2='.$xpicker->{_d2};

	} else { 
		print("xpicker, d2, missing d2,\n");
	 }
 }


=head2 sub d2num 


=cut

 sub d2num {

	my ( $self,$d2num )		= @_;
	if ( $d2num ne $empty_string ) {

		$xpicker->{_d2num}		= $d2num;
		$xpicker->{_note}		= $xpicker->{_note}.' d2num='.$xpicker->{_d2num};
		$xpicker->{_Step}		= $xpicker->{_Step}.' d2num='.$xpicker->{_d2num};

	} else { 
		print("xpicker, d2num, missing d2num,\n");
	 }
 }


=head2 sub endian 


=cut

 sub endian {

	my ( $self,$endian )		= @_;
	if ( $endian ne $empty_string ) {

		$xpicker->{_endian}		= $endian;
		$xpicker->{_note}		= $xpicker->{_note}.' endian='.$xpicker->{_endian};
		$xpicker->{_Step}		= $xpicker->{_Step}.' endian='.$xpicker->{_endian};

	} else { 
		print("xpicker, endian, missing endian,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$xpicker->{_f1}		= $f1;
		$xpicker->{_note}		= $xpicker->{_note}.' f1='.$xpicker->{_f1};
		$xpicker->{_Step}		= $xpicker->{_Step}.' f1='.$xpicker->{_f1};

	} else { 
		print("xpicker, f1, missing f1,\n");
	 }
 }


=head2 sub f1num 


=cut

 sub f1num {

	my ( $self,$f1num )		= @_;
	if ( $f1num ne $empty_string ) {

		$xpicker->{_f1num}		= $f1num;
		$xpicker->{_note}		= $xpicker->{_note}.' f1num='.$xpicker->{_f1num};
		$xpicker->{_Step}		= $xpicker->{_Step}.' f1num='.$xpicker->{_f1num};

	} else { 
		print("xpicker, f1num, missing f1num,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$xpicker->{_f2}		= $f2;
		$xpicker->{_note}		= $xpicker->{_note}.' f2='.$xpicker->{_f2};
		$xpicker->{_Step}		= $xpicker->{_Step}.' f2='.$xpicker->{_f2};

	} else { 
		print("xpicker, f2, missing f2,\n");
	 }
 }


=head2 sub f2num 


=cut

 sub f2num {

	my ( $self,$f2num )		= @_;
	if ( $f2num ne $empty_string ) {

		$xpicker->{_f2num}		= $f2num;
		$xpicker->{_note}		= $xpicker->{_note}.' f2num='.$xpicker->{_f2num};
		$xpicker->{_Step}		= $xpicker->{_Step}.' f2num='.$xpicker->{_f2num};

	} else { 
		print("xpicker, f2num, missing f2num,\n");
	 }
 }


=head2 sub grid1 


=cut

 sub grid1 {

	my ( $self,$grid1 )		= @_;
	if ( $grid1 ne $empty_string ) {

		$xpicker->{_grid1}		= $grid1;
		$xpicker->{_note}		= $xpicker->{_note}.' grid1='.$xpicker->{_grid1};
		$xpicker->{_Step}		= $xpicker->{_Step}.' grid1='.$xpicker->{_grid1};

	} else { 
		print("xpicker, grid1, missing grid1,\n");
	 }
 }


=head2 sub grid2 


=cut

 sub grid2 {

	my ( $self,$grid2 )		= @_;
	if ( $grid2 ne $empty_string ) {

		$xpicker->{_grid2}		= $grid2;
		$xpicker->{_note}		= $xpicker->{_note}.' grid2='.$xpicker->{_grid2};
		$xpicker->{_Step}		= $xpicker->{_Step}.' grid2='.$xpicker->{_grid2};

	} else { 
		print("xpicker, grid2, missing grid2,\n");
	 }
 }


=head2 sub gridcolor 


=cut

 sub gridcolor {

	my ( $self,$gridcolor )		= @_;
	if ( $gridcolor ne $empty_string ) {

		$xpicker->{_gridcolor}		= $gridcolor;
		$xpicker->{_note}		= $xpicker->{_note}.' gridcolor='.$xpicker->{_gridcolor};
		$xpicker->{_Step}		= $xpicker->{_Step}.' gridcolor='.$xpicker->{_gridcolor};

	} else { 
		print("xpicker, gridcolor, missing gridcolor,\n");
	 }
 }


=head2 sub hbox 


=cut

 sub hbox {

	my ( $self,$hbox )		= @_;
	if ( $hbox ne $empty_string ) {

		$xpicker->{_hbox}		= $hbox;
		$xpicker->{_note}		= $xpicker->{_note}.' hbox='.$xpicker->{_hbox};
		$xpicker->{_Step}		= $xpicker->{_Step}.' hbox='.$xpicker->{_hbox};

	} else { 
		print("xpicker, hbox, missing hbox,\n");
	 }
 }


=head2 sub interp 


=cut

 sub interp {

	my ( $self,$interp )		= @_;
	if ( $interp ne $empty_string ) {

		$xpicker->{_interp}		= $interp;
		$xpicker->{_note}		= $xpicker->{_note}.' interp='.$xpicker->{_interp};
		$xpicker->{_Step}		= $xpicker->{_Step}.' interp='.$xpicker->{_interp};

	} else { 
		print("xpicker, interp, missing interp,\n");
	 }
 }


=head2 sub key 


=cut

 sub key {

	my ( $self,$key )		= @_;
	if ( $key ne $empty_string ) {

		$xpicker->{_key}		= $key;
		$xpicker->{_note}		= $xpicker->{_note}.' key='.$xpicker->{_key};
		$xpicker->{_Step}		= $xpicker->{_Step}.' key='.$xpicker->{_key};

	} else { 
		print("xpicker, key, missing key,\n");
	 }
 }


=head2 sub label1 


=cut

 sub label1 {

	my ( $self,$label1 )		= @_;
	if ( $label1 ne $empty_string ) {

		$xpicker->{_label1}		= $label1;
		$xpicker->{_note}		= $xpicker->{_note}.' label1='.$xpicker->{_label1};
		$xpicker->{_Step}		= $xpicker->{_Step}.' label1='.$xpicker->{_label1};

	} else { 
		print("xpicker, label1, missing label1,\n");
	 }
 }


=head2 sub label2 


=cut

 sub label2 {

	my ( $self,$label2 )		= @_;
	if ( $label2 ne $empty_string ) {

		$xpicker->{_label2}		= $label2;
		$xpicker->{_note}		= $xpicker->{_note}.' label2='.$xpicker->{_label2};
		$xpicker->{_Step}		= $xpicker->{_Step}.' label2='.$xpicker->{_label2};

	} else { 
		print("xpicker, label2, missing label2,\n");
	 }
 }


=head2 sub labelcolor 


=cut

 sub labelcolor {

	my ( $self,$labelcolor )		= @_;
	if ( $labelcolor ne $empty_string ) {

		$xpicker->{_labelcolor}		= $labelcolor;
		$xpicker->{_note}		= $xpicker->{_note}.' labelcolor='.$xpicker->{_labelcolor};
		$xpicker->{_Step}		= $xpicker->{_Step}.' labelcolor='.$xpicker->{_labelcolor};

	} else { 
		print("xpicker, labelcolor, missing labelcolor,\n");
	 }
 }


=head2 sub labelfont 


=cut

 sub labelfont {

	my ( $self,$labelfont )		= @_;
	if ( $labelfont ne $empty_string ) {

		$xpicker->{_labelfont}		= $labelfont;
		$xpicker->{_note}		= $xpicker->{_note}.' labelfont='.$xpicker->{_labelfont};
		$xpicker->{_Step}		= $xpicker->{_Step}.' labelfont='.$xpicker->{_labelfont};

	} else { 
		print("xpicker, labelfont, missing labelfont,\n");
	 }
 }


=head2 sub mpicks 


=cut

 sub mpicks {

	my ( $self,$mpicks )		= @_;
	if ( $mpicks ne $empty_string ) {

		$xpicker->{_mpicks}		= $mpicks;
		$xpicker->{_note}		= $xpicker->{_note}.' mpicks='.$xpicker->{_mpicks};
		$xpicker->{_Step}		= $xpicker->{_Step}.' mpicks='.$xpicker->{_mpicks};

	} else { 
		print("xpicker, mpicks, missing mpicks,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$xpicker->{_n1}		= $n1;
		$xpicker->{_note}		= $xpicker->{_note}.' n1='.$xpicker->{_n1};
		$xpicker->{_Step}		= $xpicker->{_Step}.' n1='.$xpicker->{_n1};

	} else { 
		print("xpicker, n1, missing n1,\n");
	 }
 }


=head2 sub n1tic 


=cut

 sub n1tic {

	my ( $self,$n1tic )		= @_;
	if ( $n1tic ne $empty_string ) {

		$xpicker->{_n1tic}		= $n1tic;
		$xpicker->{_note}		= $xpicker->{_note}.' n1tic='.$xpicker->{_n1tic};
		$xpicker->{_Step}		= $xpicker->{_Step}.' n1tic='.$xpicker->{_n1tic};

	} else { 
		print("xpicker, n1tic, missing n1tic,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$xpicker->{_n2}		= $n2;
		$xpicker->{_note}		= $xpicker->{_note}.' n2='.$xpicker->{_n2};
		$xpicker->{_Step}		= $xpicker->{_Step}.' n2='.$xpicker->{_n2};

	} else { 
		print("xpicker, n2, missing n2,\n");
	 }
 }


=head2 sub n2tic 


=cut

 sub n2tic {

	my ( $self,$n2tic )		= @_;
	if ( $n2tic ne $empty_string ) {

		$xpicker->{_n2tic}		= $n2tic;
		$xpicker->{_note}		= $xpicker->{_note}.' n2tic='.$xpicker->{_n2tic};
		$xpicker->{_Step}		= $xpicker->{_Step}.' n2tic='.$xpicker->{_n2tic};

	} else { 
		print("xpicker, n2tic, missing n2tic,\n");
	 }
 }


=head2 sub perc 


=cut

 sub perc {

	my ( $self,$perc )		= @_;
	if ( $perc ne $empty_string ) {

		$xpicker->{_perc}		= $perc;
		$xpicker->{_note}		= $xpicker->{_note}.' perc='.$xpicker->{_perc};
		$xpicker->{_Step}		= $xpicker->{_Step}.' perc='.$xpicker->{_perc};

	} else { 
		print("xpicker, perc, missing perc,\n");
	 }
 }


=head2 sub picked 


=cut

 sub picked {

	my ( $self,$picked )		= @_;
	if ( $picked ne $empty_string ) {

		$xpicker->{_picked}		= $picked;
		$xpicker->{_note}		= $xpicker->{_note}.' picked='.$xpicker->{_picked};
		$xpicker->{_Step}		= $xpicker->{_Step}.' picked='.$xpicker->{_picked};

	} else { 
		print("xpicker, picked, missing picked,\n");
	 }
 }


=head2 sub style 


=cut

 sub style {

	my ( $self,$style )		= @_;
	if ( $style ne $empty_string ) {

		$xpicker->{_style}		= $style;
		$xpicker->{_note}		= $xpicker->{_note}.' style='.$xpicker->{_style};
		$xpicker->{_Step}		= $xpicker->{_Step}.' style='.$xpicker->{_style};

	} else { 
		print("xpicker, style, missing style,\n");
	 }
 }


=head2 sub title 


=cut

 sub title {

	my ( $self,$title )		= @_;
	if ( $title ne $empty_string ) {

		$xpicker->{_title}		= $title;
		$xpicker->{_note}		= $xpicker->{_note}.' title='.$xpicker->{_title};
		$xpicker->{_Step}		= $xpicker->{_Step}.' title='.$xpicker->{_title};

	} else { 
		print("xpicker, title, missing title,\n");
	 }
 }


=head2 sub titlecolor 


=cut

 sub titlecolor {

	my ( $self,$titlecolor )		= @_;
	if ( $titlecolor ne $empty_string ) {

		$xpicker->{_titlecolor}		= $titlecolor;
		$xpicker->{_note}		= $xpicker->{_note}.' titlecolor='.$xpicker->{_titlecolor};
		$xpicker->{_Step}		= $xpicker->{_Step}.' titlecolor='.$xpicker->{_titlecolor};

	} else { 
		print("xpicker, titlecolor, missing titlecolor,\n");
	 }
 }


=head2 sub titlefont 


=cut

 sub titlefont {

	my ( $self,$titlefont )		= @_;
	if ( $titlefont ne $empty_string ) {

		$xpicker->{_titlefont}		= $titlefont;
		$xpicker->{_note}		= $xpicker->{_note}.' titlefont='.$xpicker->{_titlefont};
		$xpicker->{_Step}		= $xpicker->{_Step}.' titlefont='.$xpicker->{_titlefont};

	} else { 
		print("xpicker, titlefont, missing titlefont,\n");
	 }
 }


=head2 sub va 


=cut

 sub va {

	my ( $self,$va )		= @_;
	if ( $va ne $empty_string ) {

		$xpicker->{_va}		= $va;
		$xpicker->{_note}		= $xpicker->{_note}.' va='.$xpicker->{_va};
		$xpicker->{_Step}		= $xpicker->{_Step}.' va='.$xpicker->{_va};

	} else { 
		print("xpicker, va, missing va,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$xpicker->{_verbose}		= $verbose;
		$xpicker->{_note}		= $xpicker->{_note}.' verbose='.$xpicker->{_verbose};
		$xpicker->{_Step}		= $xpicker->{_Step}.' verbose='.$xpicker->{_verbose};

	} else { 
		print("xpicker, verbose, missing verbose,\n");
	 }
 }


=head2 sub wbox 


=cut

 sub wbox {

	my ( $self,$wbox )		= @_;
	if ( $wbox ne $empty_string ) {

		$xpicker->{_wbox}		= $wbox;
		$xpicker->{_note}		= $xpicker->{_note}.' wbox='.$xpicker->{_wbox};
		$xpicker->{_Step}		= $xpicker->{_Step}.' wbox='.$xpicker->{_wbox};

	} else { 
		print("xpicker, wbox, missing wbox,\n");
	 }
 }


=head2 sub wt 


=cut

 sub wt {

	my ( $self,$wt )		= @_;
	if ( $wt ne $empty_string ) {

		$xpicker->{_wt}		= $wt;
		$xpicker->{_note}		= $xpicker->{_note}.' wt='.$xpicker->{_wt};
		$xpicker->{_Step}		= $xpicker->{_Step}.' wt='.$xpicker->{_wt};

	} else { 
		print("xpicker, wt, missing wt,\n");
	 }
 }


=head2 sub x1beg 


=cut

 sub x1beg {

	my ( $self,$x1beg )		= @_;
	if ( $x1beg ne $empty_string ) {

		$xpicker->{_x1beg}		= $x1beg;
		$xpicker->{_note}		= $xpicker->{_note}.' x1beg='.$xpicker->{_x1beg};
		$xpicker->{_Step}		= $xpicker->{_Step}.' x1beg='.$xpicker->{_x1beg};

	} else { 
		print("xpicker, x1beg, missing x1beg,\n");
	 }
 }


=head2 sub x1end 


=cut

 sub x1end {

	my ( $self,$x1end )		= @_;
	if ( $x1end ne $empty_string ) {

		$xpicker->{_x1end}		= $x1end;
		$xpicker->{_note}		= $xpicker->{_note}.' x1end='.$xpicker->{_x1end};
		$xpicker->{_Step}		= $xpicker->{_Step}.' x1end='.$xpicker->{_x1end};

	} else { 
		print("xpicker, x1end, missing x1end,\n");
	 }
 }


=head2 sub x1x2 


=cut

 sub x1x2 {

	my ( $self,$x1x2 )		= @_;
	if ( $x1x2 ne $empty_string ) {

		$xpicker->{_x1x2}		= $x1x2;
		$xpicker->{_note}		= $xpicker->{_note}.' x1x2='.$xpicker->{_x1x2};
		$xpicker->{_Step}		= $xpicker->{_Step}.' x1x2='.$xpicker->{_x1x2};

	} else { 
		print("xpicker, x1x2, missing x1x2,\n");
	 }
 }


=head2 sub x2 


=cut

 sub x2 {

	my ( $self,$x2 )		= @_;
	if ( $x2 ne $empty_string ) {

		$xpicker->{_x2}		= $x2;
		$xpicker->{_note}		= $xpicker->{_note}.' x2='.$xpicker->{_x2};
		$xpicker->{_Step}		= $xpicker->{_Step}.' x2='.$xpicker->{_x2};

	} else { 
		print("xpicker, x2, missing x2,\n");
	 }
 }


=head2 sub x2beg 


=cut

 sub x2beg {

	my ( $self,$x2beg )		= @_;
	if ( $x2beg ne $empty_string ) {

		$xpicker->{_x2beg}		= $x2beg;
		$xpicker->{_note}		= $xpicker->{_note}.' x2beg='.$xpicker->{_x2beg};
		$xpicker->{_Step}		= $xpicker->{_Step}.' x2beg='.$xpicker->{_x2beg};

	} else { 
		print("xpicker, x2beg, missing x2beg,\n");
	 }
 }


=head2 sub x2end 


=cut

 sub x2end {

	my ( $self,$x2end )		= @_;
	if ( $x2end ne $empty_string ) {

		$xpicker->{_x2end}		= $x2end;
		$xpicker->{_note}		= $xpicker->{_note}.' x2end='.$xpicker->{_x2end};
		$xpicker->{_Step}		= $xpicker->{_Step}.' x2end='.$xpicker->{_x2end};

	} else { 
		print("xpicker, x2end, missing x2end,\n");
	 }
 }


=head2 sub x2file 


=cut

 sub x2file {

	my ( $self,$x2file )		= @_;
	if ( $x2file ne $empty_string ) {

		$xpicker->{_x2file}		= $x2file;
		$xpicker->{_note}		= $xpicker->{_note}.' x2file='.$xpicker->{_x2file};
		$xpicker->{_Step}		= $xpicker->{_Step}.' x2file='.$xpicker->{_x2file};

	} else { 
		print("xpicker, x2file, missing x2file,\n");
	 }
 }


=head2 sub xbox 


=cut

 sub xbox {

	my ( $self,$xbox )		= @_;
	if ( $xbox ne $empty_string ) {

		$xpicker->{_xbox}		= $xbox;
		$xpicker->{_note}		= $xpicker->{_note}.' xbox='.$xpicker->{_xbox};
		$xpicker->{_Step}		= $xpicker->{_Step}.' xbox='.$xpicker->{_xbox};

	} else { 
		print("xpicker, xbox, missing xbox,\n");
	 }
 }


=head2 sub xcur 


=cut

 sub xcur {

	my ( $self,$xcur )		= @_;
	if ( $xcur ne $empty_string ) {

		$xpicker->{_xcur}		= $xcur;
		$xpicker->{_note}		= $xpicker->{_note}.' xcur='.$xpicker->{_xcur};
		$xpicker->{_Step}		= $xpicker->{_Step}.' xcur='.$xpicker->{_xcur};

	} else { 
		print("xpicker, xcur, missing xcur,\n");
	 }
 }


=head2 sub ybox 


=cut

 sub ybox {

	my ( $self,$ybox )		= @_;
	if ( $ybox ne $empty_string ) {

		$xpicker->{_ybox}		= $ybox;
		$xpicker->{_note}		= $xpicker->{_note}.' ybox='.$xpicker->{_ybox};
		$xpicker->{_Step}		= $xpicker->{_Step}.' ybox='.$xpicker->{_ybox};

	} else { 
		print("xpicker, ybox, missing ybox,\n");
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
