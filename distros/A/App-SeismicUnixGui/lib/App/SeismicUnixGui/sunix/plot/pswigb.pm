package App::SeismicUnixGui::sunix::plot::pswigb;

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

my $pswigb			= {
	_axescolor					=> '',
	_axeswidth					=> '',
	_bias					=> '',
	_clip					=> '',
	_curve					=> '',
	_curvecolor					=> '',
	_curvedash					=> '',
	_curvefile					=> '',
	_curvewidth					=> '',
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
	_interp					=> '',
	_label1					=> '',
	_label2					=> '',
	_labelfont					=> '',
	_labelsize					=> '',
	_n1					=> '',
	_n1tic					=> '',
	_n2					=> '',
	_n2tic					=> '',
	_nbpi					=> '',
	_npair					=> '',
	_perc					=> '',
	_style					=> '',
	_ticwidth					=> '',
	_title					=> '',
	_titlecolor					=> '',
	_titlefont					=> '',
	_titlesize					=> '',
	_va					=> '',
	_verbose					=> '',
	_wbox					=> '',
	_wt					=> '',
	_x1beg					=> '',
	_x1end					=> '',
	_x2					=> '',
	_x2beg					=> '',
	_x2end					=> '',
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

	$pswigb->{_Step}     = 'pswigb'.$pswigb->{_Step};
	return ( $pswigb->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$pswigb->{_note}     = 'pswigb'.$pswigb->{_note};
	return ( $pswigb->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$pswigb->{_axescolor}			= '';
		$pswigb->{_axeswidth}			= '';
		$pswigb->{_bias}			= '';
		$pswigb->{_clip}			= '';
		$pswigb->{_curve}			= '';
		$pswigb->{_curvecolor}			= '';
		$pswigb->{_curvedash}			= '';
		$pswigb->{_curvefile}			= '';
		$pswigb->{_curvewidth}			= '';
		$pswigb->{_d1}			= '';
		$pswigb->{_d1num}			= '';
		$pswigb->{_d2}			= '';
		$pswigb->{_d2num}			= '';
		$pswigb->{_f1}			= '';
		$pswigb->{_f1num}			= '';
		$pswigb->{_f2}			= '';
		$pswigb->{_f2num}			= '';
		$pswigb->{_grid1}			= '';
		$pswigb->{_grid2}			= '';
		$pswigb->{_gridcolor}			= '';
		$pswigb->{_gridwidth}			= '';
		$pswigb->{_hbox}			= '';
		$pswigb->{_interp}			= '';
		$pswigb->{_label1}			= '';
		$pswigb->{_label2}			= '';
		$pswigb->{_labelfont}			= '';
		$pswigb->{_labelsize}			= '';
		$pswigb->{_n1}			= '';
		$pswigb->{_n1tic}			= '';
		$pswigb->{_n2}			= '';
		$pswigb->{_n2tic}			= '';
		$pswigb->{_nbpi}			= '';
		$pswigb->{_npair}			= '';
		$pswigb->{_perc}			= '';
		$pswigb->{_style}			= '';
		$pswigb->{_ticwidth}			= '';
		$pswigb->{_title}			= '';
		$pswigb->{_titlecolor}			= '';
		$pswigb->{_titlefont}			= '';
		$pswigb->{_titlesize}			= '';
		$pswigb->{_va}			= '';
		$pswigb->{_verbose}			= '';
		$pswigb->{_wbox}			= '';
		$pswigb->{_wt}			= '';
		$pswigb->{_x1beg}			= '';
		$pswigb->{_x1end}			= '';
		$pswigb->{_x2}			= '';
		$pswigb->{_x2beg}			= '';
		$pswigb->{_x2end}			= '';
		$pswigb->{_xbox}			= '';
		$pswigb->{_xcur}			= '';
		$pswigb->{_ybox}			= '';
		$pswigb->{_Step}			= '';
		$pswigb->{_note}			= '';
 }


=head2 sub axescolor 


=cut

 sub axescolor {

	my ( $self,$axescolor )		= @_;
	if ( $axescolor ne $empty_string ) {

		$pswigb->{_axescolor}		= $axescolor;
		$pswigb->{_note}		= $pswigb->{_note}.' axescolor='.$pswigb->{_axescolor};
		$pswigb->{_Step}		= $pswigb->{_Step}.' axescolor='.$pswigb->{_axescolor};

	} else { 
		print("pswigb, axescolor, missing axescolor,\n");
	 }
 }


=head2 sub axeswidth 


=cut

 sub axeswidth {

	my ( $self,$axeswidth )		= @_;
	if ( $axeswidth ne $empty_string ) {

		$pswigb->{_axeswidth}		= $axeswidth;
		$pswigb->{_note}		= $pswigb->{_note}.' axeswidth='.$pswigb->{_axeswidth};
		$pswigb->{_Step}		= $pswigb->{_Step}.' axeswidth='.$pswigb->{_axeswidth};

	} else { 
		print("pswigb, axeswidth, missing axeswidth,\n");
	 }
 }


=head2 sub bias 


=cut

 sub bias {

	my ( $self,$bias )		= @_;
	if ( $bias ne $empty_string ) {

		$pswigb->{_bias}		= $bias;
		$pswigb->{_note}		= $pswigb->{_note}.' bias='.$pswigb->{_bias};
		$pswigb->{_Step}		= $pswigb->{_Step}.' bias='.$pswigb->{_bias};

	} else { 
		print("pswigb, bias, missing bias,\n");
	 }
 }


=head2 sub clip 


=cut

 sub clip {

	my ( $self,$clip )		= @_;
	if ( $clip ne $empty_string ) {

		$pswigb->{_clip}		= $clip;
		$pswigb->{_note}		= $pswigb->{_note}.' clip='.$pswigb->{_clip};
		$pswigb->{_Step}		= $pswigb->{_Step}.' clip='.$pswigb->{_clip};

	} else { 
		print("pswigb, clip, missing clip,\n");
	 }
 }


=head2 sub curve 


=cut

 sub curve {

	my ( $self,$curve )		= @_;
	if ( $curve ne $empty_string ) {

		$pswigb->{_curve}		= $curve;
		$pswigb->{_note}		= $pswigb->{_note}.' curve='.$pswigb->{_curve};
		$pswigb->{_Step}		= $pswigb->{_Step}.' curve='.$pswigb->{_curve};

	} else { 
		print("pswigb, curve, missing curve,\n");
	 }
 }


=head2 sub curvecolor 


=cut

 sub curvecolor {

	my ( $self,$curvecolor )		= @_;
	if ( $curvecolor ne $empty_string ) {

		$pswigb->{_curvecolor}		= $curvecolor;
		$pswigb->{_note}		= $pswigb->{_note}.' curvecolor='.$pswigb->{_curvecolor};
		$pswigb->{_Step}		= $pswigb->{_Step}.' curvecolor='.$pswigb->{_curvecolor};

	} else { 
		print("pswigb, curvecolor, missing curvecolor,\n");
	 }
 }


=head2 sub curvedash 


=cut

 sub curvedash {

	my ( $self,$curvedash )		= @_;
	if ( $curvedash ne $empty_string ) {

		$pswigb->{_curvedash}		= $curvedash;
		$pswigb->{_note}		= $pswigb->{_note}.' curvedash='.$pswigb->{_curvedash};
		$pswigb->{_Step}		= $pswigb->{_Step}.' curvedash='.$pswigb->{_curvedash};

	} else { 
		print("pswigb, curvedash, missing curvedash,\n");
	 }
 }


=head2 sub curvefile 


=cut

 sub curvefile {

	my ( $self,$curvefile )		= @_;
	if ( $curvefile ne $empty_string ) {

		$pswigb->{_curvefile}		= $curvefile;
		$pswigb->{_note}		= $pswigb->{_note}.' curvefile='.$pswigb->{_curvefile};
		$pswigb->{_Step}		= $pswigb->{_Step}.' curvefile='.$pswigb->{_curvefile};

	} else { 
		print("pswigb, curvefile, missing curvefile,\n");
	 }
 }


=head2 sub curvewidth 


=cut

 sub curvewidth {

	my ( $self,$curvewidth )		= @_;
	if ( $curvewidth ne $empty_string ) {

		$pswigb->{_curvewidth}		= $curvewidth;
		$pswigb->{_note}		= $pswigb->{_note}.' curvewidth='.$pswigb->{_curvewidth};
		$pswigb->{_Step}		= $pswigb->{_Step}.' curvewidth='.$pswigb->{_curvewidth};

	} else { 
		print("pswigb, curvewidth, missing curvewidth,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$pswigb->{_d1}		= $d1;
		$pswigb->{_note}		= $pswigb->{_note}.' d1='.$pswigb->{_d1};
		$pswigb->{_Step}		= $pswigb->{_Step}.' d1='.$pswigb->{_d1};

	} else { 
		print("pswigb, d1, missing d1,\n");
	 }
 }


=head2 sub d1num 


=cut

 sub d1num {

	my ( $self,$d1num )		= @_;
	if ( $d1num ne $empty_string ) {

		$pswigb->{_d1num}		= $d1num;
		$pswigb->{_note}		= $pswigb->{_note}.' d1num='.$pswigb->{_d1num};
		$pswigb->{_Step}		= $pswigb->{_Step}.' d1num='.$pswigb->{_d1num};

	} else { 
		print("pswigb, d1num, missing d1num,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$pswigb->{_d2}		= $d2;
		$pswigb->{_note}		= $pswigb->{_note}.' d2='.$pswigb->{_d2};
		$pswigb->{_Step}		= $pswigb->{_Step}.' d2='.$pswigb->{_d2};

	} else { 
		print("pswigb, d2, missing d2,\n");
	 }
 }


=head2 sub d2num 


=cut

 sub d2num {

	my ( $self,$d2num )		= @_;
	if ( $d2num ne $empty_string ) {

		$pswigb->{_d2num}		= $d2num;
		$pswigb->{_note}		= $pswigb->{_note}.' d2num='.$pswigb->{_d2num};
		$pswigb->{_Step}		= $pswigb->{_Step}.' d2num='.$pswigb->{_d2num};

	} else { 
		print("pswigb, d2num, missing d2num,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$pswigb->{_f1}		= $f1;
		$pswigb->{_note}		= $pswigb->{_note}.' f1='.$pswigb->{_f1};
		$pswigb->{_Step}		= $pswigb->{_Step}.' f1='.$pswigb->{_f1};

	} else { 
		print("pswigb, f1, missing f1,\n");
	 }
 }


=head2 sub f1num 


=cut

 sub f1num {

	my ( $self,$f1num )		= @_;
	if ( $f1num ne $empty_string ) {

		$pswigb->{_f1num}		= $f1num;
		$pswigb->{_note}		= $pswigb->{_note}.' f1num='.$pswigb->{_f1num};
		$pswigb->{_Step}		= $pswigb->{_Step}.' f1num='.$pswigb->{_f1num};

	} else { 
		print("pswigb, f1num, missing f1num,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$pswigb->{_f2}		= $f2;
		$pswigb->{_note}		= $pswigb->{_note}.' f2='.$pswigb->{_f2};
		$pswigb->{_Step}		= $pswigb->{_Step}.' f2='.$pswigb->{_f2};

	} else { 
		print("pswigb, f2, missing f2,\n");
	 }
 }


=head2 sub f2num 


=cut

 sub f2num {

	my ( $self,$f2num )		= @_;
	if ( $f2num ne $empty_string ) {

		$pswigb->{_f2num}		= $f2num;
		$pswigb->{_note}		= $pswigb->{_note}.' f2num='.$pswigb->{_f2num};
		$pswigb->{_Step}		= $pswigb->{_Step}.' f2num='.$pswigb->{_f2num};

	} else { 
		print("pswigb, f2num, missing f2num,\n");
	 }
 }


=head2 sub grid1 


=cut

 sub grid1 {

	my ( $self,$grid1 )		= @_;
	if ( $grid1 ne $empty_string ) {

		$pswigb->{_grid1}		= $grid1;
		$pswigb->{_note}		= $pswigb->{_note}.' grid1='.$pswigb->{_grid1};
		$pswigb->{_Step}		= $pswigb->{_Step}.' grid1='.$pswigb->{_grid1};

	} else { 
		print("pswigb, grid1, missing grid1,\n");
	 }
 }


=head2 sub grid2 


=cut

 sub grid2 {

	my ( $self,$grid2 )		= @_;
	if ( $grid2 ne $empty_string ) {

		$pswigb->{_grid2}		= $grid2;
		$pswigb->{_note}		= $pswigb->{_note}.' grid2='.$pswigb->{_grid2};
		$pswigb->{_Step}		= $pswigb->{_Step}.' grid2='.$pswigb->{_grid2};

	} else { 
		print("pswigb, grid2, missing grid2,\n");
	 }
 }


=head2 sub gridcolor 


=cut

 sub gridcolor {

	my ( $self,$gridcolor )		= @_;
	if ( $gridcolor ne $empty_string ) {

		$pswigb->{_gridcolor}		= $gridcolor;
		$pswigb->{_note}		= $pswigb->{_note}.' gridcolor='.$pswigb->{_gridcolor};
		$pswigb->{_Step}		= $pswigb->{_Step}.' gridcolor='.$pswigb->{_gridcolor};

	} else { 
		print("pswigb, gridcolor, missing gridcolor,\n");
	 }
 }


=head2 sub gridwidth 


=cut

 sub gridwidth {

	my ( $self,$gridwidth )		= @_;
	if ( $gridwidth ne $empty_string ) {

		$pswigb->{_gridwidth}		= $gridwidth;
		$pswigb->{_note}		= $pswigb->{_note}.' gridwidth='.$pswigb->{_gridwidth};
		$pswigb->{_Step}		= $pswigb->{_Step}.' gridwidth='.$pswigb->{_gridwidth};

	} else { 
		print("pswigb, gridwidth, missing gridwidth,\n");
	 }
 }


=head2 sub hbox 


=cut

 sub hbox {

	my ( $self,$hbox )		= @_;
	if ( $hbox ne $empty_string ) {

		$pswigb->{_hbox}		= $hbox;
		$pswigb->{_note}		= $pswigb->{_note}.' hbox='.$pswigb->{_hbox};
		$pswigb->{_Step}		= $pswigb->{_Step}.' hbox='.$pswigb->{_hbox};

	} else { 
		print("pswigb, hbox, missing hbox,\n");
	 }
 }


=head2 sub interp 


=cut

 sub interp {

	my ( $self,$interp )		= @_;
	if ( $interp ne $empty_string ) {

		$pswigb->{_interp}		= $interp;
		$pswigb->{_note}		= $pswigb->{_note}.' interp='.$pswigb->{_interp};
		$pswigb->{_Step}		= $pswigb->{_Step}.' interp='.$pswigb->{_interp};

	} else { 
		print("pswigb, interp, missing interp,\n");
	 }
 }


=head2 sub label1 


=cut

 sub label1 {

	my ( $self,$label1 )		= @_;
	if ( $label1 ne $empty_string ) {

		$pswigb->{_label1}		= $label1;
		$pswigb->{_note}		= $pswigb->{_note}.' label1='.$pswigb->{_label1};
		$pswigb->{_Step}		= $pswigb->{_Step}.' label1='.$pswigb->{_label1};

	} else { 
		print("pswigb, label1, missing label1,\n");
	 }
 }


=head2 sub label2 


=cut

 sub label2 {

	my ( $self,$label2 )		= @_;
	if ( $label2 ne $empty_string ) {

		$pswigb->{_label2}		= $label2;
		$pswigb->{_note}		= $pswigb->{_note}.' label2='.$pswigb->{_label2};
		$pswigb->{_Step}		= $pswigb->{_Step}.' label2='.$pswigb->{_label2};

	} else { 
		print("pswigb, label2, missing label2,\n");
	 }
 }


=head2 sub labelfont 


=cut

 sub labelfont {

	my ( $self,$labelfont )		= @_;
	if ( $labelfont ne $empty_string ) {

		$pswigb->{_labelfont}		= $labelfont;
		$pswigb->{_note}		= $pswigb->{_note}.' labelfont='.$pswigb->{_labelfont};
		$pswigb->{_Step}		= $pswigb->{_Step}.' labelfont='.$pswigb->{_labelfont};

	} else { 
		print("pswigb, labelfont, missing labelfont,\n");
	 }
 }


=head2 sub labelsize 


=cut

 sub labelsize {

	my ( $self,$labelsize )		= @_;
	if ( $labelsize ne $empty_string ) {

		$pswigb->{_labelsize}		= $labelsize;
		$pswigb->{_note}		= $pswigb->{_note}.' labelsize='.$pswigb->{_labelsize};
		$pswigb->{_Step}		= $pswigb->{_Step}.' labelsize='.$pswigb->{_labelsize};

	} else { 
		print("pswigb, labelsize, missing labelsize,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$pswigb->{_n1}		= $n1;
		$pswigb->{_note}		= $pswigb->{_note}.' n1='.$pswigb->{_n1};
		$pswigb->{_Step}		= $pswigb->{_Step}.' n1='.$pswigb->{_n1};

	} else { 
		print("pswigb, n1, missing n1,\n");
	 }
 }


=head2 sub n1tic 


=cut

 sub n1tic {

	my ( $self,$n1tic )		= @_;
	if ( $n1tic ne $empty_string ) {

		$pswigb->{_n1tic}		= $n1tic;
		$pswigb->{_note}		= $pswigb->{_note}.' n1tic='.$pswigb->{_n1tic};
		$pswigb->{_Step}		= $pswigb->{_Step}.' n1tic='.$pswigb->{_n1tic};

	} else { 
		print("pswigb, n1tic, missing n1tic,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$pswigb->{_n2}		= $n2;
		$pswigb->{_note}		= $pswigb->{_note}.' n2='.$pswigb->{_n2};
		$pswigb->{_Step}		= $pswigb->{_Step}.' n2='.$pswigb->{_n2};

	} else { 
		print("pswigb, n2, missing n2,\n");
	 }
 }


=head2 sub n2tic 


=cut

 sub n2tic {

	my ( $self,$n2tic )		= @_;
	if ( $n2tic ne $empty_string ) {

		$pswigb->{_n2tic}		= $n2tic;
		$pswigb->{_note}		= $pswigb->{_note}.' n2tic='.$pswigb->{_n2tic};
		$pswigb->{_Step}		= $pswigb->{_Step}.' n2tic='.$pswigb->{_n2tic};

	} else { 
		print("pswigb, n2tic, missing n2tic,\n");
	 }
 }


=head2 sub nbpi 


=cut

 sub nbpi {

	my ( $self,$nbpi )		= @_;
	if ( $nbpi ne $empty_string ) {

		$pswigb->{_nbpi}		= $nbpi;
		$pswigb->{_note}		= $pswigb->{_note}.' nbpi='.$pswigb->{_nbpi};
		$pswigb->{_Step}		= $pswigb->{_Step}.' nbpi='.$pswigb->{_nbpi};

	} else { 
		print("pswigb, nbpi, missing nbpi,\n");
	 }
 }


=head2 sub npair 


=cut

 sub npair {

	my ( $self,$npair )		= @_;
	if ( $npair ne $empty_string ) {

		$pswigb->{_npair}		= $npair;
		$pswigb->{_note}		= $pswigb->{_note}.' npair='.$pswigb->{_npair};
		$pswigb->{_Step}		= $pswigb->{_Step}.' npair='.$pswigb->{_npair};

	} else { 
		print("pswigb, npair, missing npair,\n");
	 }
 }


=head2 sub perc 


=cut

 sub perc {

	my ( $self,$perc )		= @_;
	if ( $perc ne $empty_string ) {

		$pswigb->{_perc}		= $perc;
		$pswigb->{_note}		= $pswigb->{_note}.' perc='.$pswigb->{_perc};
		$pswigb->{_Step}		= $pswigb->{_Step}.' perc='.$pswigb->{_perc};

	} else { 
		print("pswigb, perc, missing perc,\n");
	 }
 }


=head2 sub style 


=cut

 sub style {

	my ( $self,$style )		= @_;
	if ( $style ne $empty_string ) {

		$pswigb->{_style}		= $style;
		$pswigb->{_note}		= $pswigb->{_note}.' style='.$pswigb->{_style};
		$pswigb->{_Step}		= $pswigb->{_Step}.' style='.$pswigb->{_style};

	} else { 
		print("pswigb, style, missing style,\n");
	 }
 }


=head2 sub ticwidth 


=cut

 sub ticwidth {

	my ( $self,$ticwidth )		= @_;
	if ( $ticwidth ne $empty_string ) {

		$pswigb->{_ticwidth}		= $ticwidth;
		$pswigb->{_note}		= $pswigb->{_note}.' ticwidth='.$pswigb->{_ticwidth};
		$pswigb->{_Step}		= $pswigb->{_Step}.' ticwidth='.$pswigb->{_ticwidth};

	} else { 
		print("pswigb, ticwidth, missing ticwidth,\n");
	 }
 }


=head2 sub title 


=cut

 sub title {

	my ( $self,$title )		= @_;
	if ( $title ne $empty_string ) {

		$pswigb->{_title}		= $title;
		$pswigb->{_note}		= $pswigb->{_note}.' title='.$pswigb->{_title};
		$pswigb->{_Step}		= $pswigb->{_Step}.' title='.$pswigb->{_title};

	} else { 
		print("pswigb, title, missing title,\n");
	 }
 }


=head2 sub titlecolor 


=cut

 sub titlecolor {

	my ( $self,$titlecolor )		= @_;
	if ( $titlecolor ne $empty_string ) {

		$pswigb->{_titlecolor}		= $titlecolor;
		$pswigb->{_note}		= $pswigb->{_note}.' titlecolor='.$pswigb->{_titlecolor};
		$pswigb->{_Step}		= $pswigb->{_Step}.' titlecolor='.$pswigb->{_titlecolor};

	} else { 
		print("pswigb, titlecolor, missing titlecolor,\n");
	 }
 }


=head2 sub titlefont 


=cut

 sub titlefont {

	my ( $self,$titlefont )		= @_;
	if ( $titlefont ne $empty_string ) {

		$pswigb->{_titlefont}		= $titlefont;
		$pswigb->{_note}		= $pswigb->{_note}.' titlefont='.$pswigb->{_titlefont};
		$pswigb->{_Step}		= $pswigb->{_Step}.' titlefont='.$pswigb->{_titlefont};

	} else { 
		print("pswigb, titlefont, missing titlefont,\n");
	 }
 }


=head2 sub titlesize 


=cut

 sub titlesize {

	my ( $self,$titlesize )		= @_;
	if ( $titlesize ne $empty_string ) {

		$pswigb->{_titlesize}		= $titlesize;
		$pswigb->{_note}		= $pswigb->{_note}.' titlesize='.$pswigb->{_titlesize};
		$pswigb->{_Step}		= $pswigb->{_Step}.' titlesize='.$pswigb->{_titlesize};

	} else { 
		print("pswigb, titlesize, missing titlesize,\n");
	 }
 }


=head2 sub va 


=cut

 sub va {

	my ( $self,$va )		= @_;
	if ( $va ne $empty_string ) {

		$pswigb->{_va}		= $va;
		$pswigb->{_note}		= $pswigb->{_note}.' va='.$pswigb->{_va};
		$pswigb->{_Step}		= $pswigb->{_Step}.' va='.$pswigb->{_va};

	} else { 
		print("pswigb, va, missing va,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$pswigb->{_verbose}		= $verbose;
		$pswigb->{_note}		= $pswigb->{_note}.' verbose='.$pswigb->{_verbose};
		$pswigb->{_Step}		= $pswigb->{_Step}.' verbose='.$pswigb->{_verbose};

	} else { 
		print("pswigb, verbose, missing verbose,\n");
	 }
 }


=head2 sub wbox 


=cut

 sub wbox {

	my ( $self,$wbox )		= @_;
	if ( $wbox ne $empty_string ) {

		$pswigb->{_wbox}		= $wbox;
		$pswigb->{_note}		= $pswigb->{_note}.' wbox='.$pswigb->{_wbox};
		$pswigb->{_Step}		= $pswigb->{_Step}.' wbox='.$pswigb->{_wbox};

	} else { 
		print("pswigb, wbox, missing wbox,\n");
	 }
 }


=head2 sub wt 


=cut

 sub wt {

	my ( $self,$wt )		= @_;
	if ( $wt ne $empty_string ) {

		$pswigb->{_wt}		= $wt;
		$pswigb->{_note}		= $pswigb->{_note}.' wt='.$pswigb->{_wt};
		$pswigb->{_Step}		= $pswigb->{_Step}.' wt='.$pswigb->{_wt};

	} else { 
		print("pswigb, wt, missing wt,\n");
	 }
 }


=head2 sub x1beg 


=cut

 sub x1beg {

	my ( $self,$x1beg )		= @_;
	if ( $x1beg ne $empty_string ) {

		$pswigb->{_x1beg}		= $x1beg;
		$pswigb->{_note}		= $pswigb->{_note}.' x1beg='.$pswigb->{_x1beg};
		$pswigb->{_Step}		= $pswigb->{_Step}.' x1beg='.$pswigb->{_x1beg};

	} else { 
		print("pswigb, x1beg, missing x1beg,\n");
	 }
 }


=head2 sub x1end 


=cut

 sub x1end {

	my ( $self,$x1end )		= @_;
	if ( $x1end ne $empty_string ) {

		$pswigb->{_x1end}		= $x1end;
		$pswigb->{_note}		= $pswigb->{_note}.' x1end='.$pswigb->{_x1end};
		$pswigb->{_Step}		= $pswigb->{_Step}.' x1end='.$pswigb->{_x1end};

	} else { 
		print("pswigb, x1end, missing x1end,\n");
	 }
 }


=head2 sub x2 


=cut

 sub x2 {

	my ( $self,$x2 )		= @_;
	if ( $x2 ne $empty_string ) {

		$pswigb->{_x2}		= $x2;
		$pswigb->{_note}		= $pswigb->{_note}.' x2='.$pswigb->{_x2};
		$pswigb->{_Step}		= $pswigb->{_Step}.' x2='.$pswigb->{_x2};

	} else { 
		print("pswigb, x2, missing x2,\n");
	 }
 }


=head2 sub x2beg 


=cut

 sub x2beg {

	my ( $self,$x2beg )		= @_;
	if ( $x2beg ne $empty_string ) {

		$pswigb->{_x2beg}		= $x2beg;
		$pswigb->{_note}		= $pswigb->{_note}.' x2beg='.$pswigb->{_x2beg};
		$pswigb->{_Step}		= $pswigb->{_Step}.' x2beg='.$pswigb->{_x2beg};

	} else { 
		print("pswigb, x2beg, missing x2beg,\n");
	 }
 }


=head2 sub x2end 


=cut

 sub x2end {

	my ( $self,$x2end )		= @_;
	if ( $x2end ne $empty_string ) {

		$pswigb->{_x2end}		= $x2end;
		$pswigb->{_note}		= $pswigb->{_note}.' x2end='.$pswigb->{_x2end};
		$pswigb->{_Step}		= $pswigb->{_Step}.' x2end='.$pswigb->{_x2end};

	} else { 
		print("pswigb, x2end, missing x2end,\n");
	 }
 }


=head2 sub xbox 


=cut

 sub xbox {

	my ( $self,$xbox )		= @_;
	if ( $xbox ne $empty_string ) {

		$pswigb->{_xbox}		= $xbox;
		$pswigb->{_note}		= $pswigb->{_note}.' xbox='.$pswigb->{_xbox};
		$pswigb->{_Step}		= $pswigb->{_Step}.' xbox='.$pswigb->{_xbox};

	} else { 
		print("pswigb, xbox, missing xbox,\n");
	 }
 }


=head2 sub xcur 


=cut

 sub xcur {

	my ( $self,$xcur )		= @_;
	if ( $xcur ne $empty_string ) {

		$pswigb->{_xcur}		= $xcur;
		$pswigb->{_note}		= $pswigb->{_note}.' xcur='.$pswigb->{_xcur};
		$pswigb->{_Step}		= $pswigb->{_Step}.' xcur='.$pswigb->{_xcur};

	} else { 
		print("pswigb, xcur, missing xcur,\n");
	 }
 }


=head2 sub ybox 


=cut

 sub ybox {

	my ( $self,$ybox )		= @_;
	if ( $ybox ne $empty_string ) {

		$pswigb->{_ybox}		= $ybox;
		$pswigb->{_note}		= $pswigb->{_note}.' ybox='.$pswigb->{_ybox};
		$pswigb->{_Step}		= $pswigb->{_Step}.' ybox='.$pswigb->{_ybox};

	} else { 
		print("pswigb, ybox, missing ybox,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 51;

    return($max_index);
}
 
 
1;
