package App::SeismicUnixGui::sunix::plot::pswigp;

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
 PSWIGP - PostScript WIGgle-trace plot of f(x1,x2) via Polygons	

 Best for few traces.  Use PSWIGB (Bitmap version) for many traces.	



 pswigp n1= [optional parameters] <binaryfile >postscriptfile		



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

 gridcolor=black        color of grid					

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

 curvecolor=color1,color2,etc, and the number of pairs of values	

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

use App::SeismicUnixGui::misc::SeismicUnix
  qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';

=head2 instantiation of packages

=cut

my $get              = L_SU_global_constants->new();
my $Project          = Project_config->new();
my $DATA_SEISMIC_SU  = $Project->DATA_SEISMIC_SU();
my $DATA_SEISMIC_BIN = $Project->DATA_SEISMIC_BIN();
my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $var          = $get->var();
my $on           = $var->{_on};
my $off          = $var->{_off};
my $true         = $var->{_true};
my $false        = $var->{_false};
my $empty_string = $var->{_empty_string};

=head2 Encapsulated
hash of private variables

=cut

my $pswigp = {
	_axescolor  => '',
	_axeswidth  => '',
	_backcolor  => '',
	_bias       => '',
	_clip       => '',
	_curve      => '',
	_curvecolor => '',
	_curvedash  => '',
	_curvefile  => '',
	_curvewidth => '',
	_d1         => '',
	_d1num      => '',
	_d2         => '',
	_d2num      => '',
	_f1         => '',
	_f1num      => '',
	_f2         => '',
	_f2num      => '',
	_fill       => '',
	_grid1      => '',
	_grid2      => '',
	_gridcolor  => '',
	_gridwidth  => '',
	_hbox       => '',
	_label1     => '',
	_label2     => '',
	_labelfont  => '',
	_labelsize  => '',
	_linewidth  => '',
	_n1         => '',
	_n1tic      => '',
	_n2         => '',
	_n2tic      => '',
	_npair      => '',
	_perc       => '',
	_style      => '',
	_ticwidth   => '',
	_title      => '',
	_titlecolor => '',
	_titlefont  => '',
	_titlesize  => '',
	_tracecolor => '',
	_verbose    => '',
	_wbox       => '',
	_x1beg      => '',
	_x1end      => '',
	_x2         => '',
	_x2beg      => '',
	_x2end      => '',
	_xbox       => '',
	_xcur       => '',
	_ybox       => '',
	_Step       => '',
	_note       => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$pswigp->{_Step} = 'pswigp' . $pswigp->{_Step};
	return ( $pswigp->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$pswigp->{_note} = 'pswigp' . $pswigp->{_note};
	return ( $pswigp->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$pswigp->{_axescolor}  = '';
	$pswigp->{_axeswidth}  = '';
	$pswigp->{_backcolor}  = '';
	$pswigp->{_bias}       = '';
	$pswigp->{_clip}       = '';
	$pswigp->{_curve}      = '';
	$pswigp->{_curvecolor} = '';
	$pswigp->{_curvedash}  = '';
	$pswigp->{_curvefile}  = '';
	$pswigp->{_curvewidth} = '';
	$pswigp->{_d1}         = '';
	$pswigp->{_d1num}      = '';
	$pswigp->{_d2}         = '';
	$pswigp->{_d2num}      = '';
	$pswigp->{_f1}         = '';
	$pswigp->{_f1num}      = '';
	$pswigp->{_f2}         = '';
	$pswigp->{_f2num}      = '';
	$pswigp->{_fill}       = '';
	$pswigp->{_grid1}      = '';
	$pswigp->{_grid2}      = '';
	$pswigp->{_gridcolor}  = '';
	$pswigp->{_gridwidth}  = '';
	$pswigp->{_hbox}       = '';
	$pswigp->{_label1}     = '';
	$pswigp->{_label2}     = '';
	$pswigp->{_labelfont}  = '';
	$pswigp->{_labelsize}  = '';
	$pswigp->{_linewidth}  = '';
	$pswigp->{_n1}         = '';
	$pswigp->{_n1tic}      = '';
	$pswigp->{_n2}         = '';
	$pswigp->{_n2tic}      = '';
	$pswigp->{_npair}      = '';
	$pswigp->{_perc}       = '';
	$pswigp->{_style}      = '';
	$pswigp->{_ticwidth}   = '';
	$pswigp->{_title}      = '';
	$pswigp->{_titlecolor} = '';
	$pswigp->{_titlefont}  = '';
	$pswigp->{_titlesize}  = '';
	$pswigp->{_tracecolor} = '';
	$pswigp->{_verbose}    = '';
	$pswigp->{_wbox}       = '';
	$pswigp->{_x1beg}      = '';
	$pswigp->{_x1end}      = '';
	$pswigp->{_x2}         = '';
	$pswigp->{_x2beg}      = '';
	$pswigp->{_x2end}      = '';
	$pswigp->{_xbox}       = '';
	$pswigp->{_xcur}       = '';
	$pswigp->{_ybox}       = '';
	$pswigp->{_Step}       = '';
	$pswigp->{_note}       = '';
}

=head2 sub axescolor 


=cut

sub axescolor {

	my ( $self, $axescolor ) = @_;
	if ( $axescolor ne $empty_string ) {

		$pswigp->{_axescolor} = $axescolor;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' axescolor=' . $pswigp->{_axescolor};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' axescolor=' . $pswigp->{_axescolor};

	}
	else {
		print("pswigp, axescolor, missing axescolor,\n");
	}
}

=head2 sub axeswidth 


=cut

sub axeswidth {

	my ( $self, $axeswidth ) = @_;
	if ( $axeswidth ne $empty_string ) {

		$pswigp->{_axeswidth} = $axeswidth;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' axeswidth=' . $pswigp->{_axeswidth};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' axeswidth=' . $pswigp->{_axeswidth};

	}
	else {
		print("pswigp, axeswidth, missing axeswidth,\n");
	}
}

=head2 sub backcolor 


=cut

sub backcolor {

	my ( $self, $backcolor ) = @_;
	if ( $backcolor ne $empty_string ) {

		$pswigp->{_backcolor} = $backcolor;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' backcolor=' . $pswigp->{_backcolor};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' backcolor=' . $pswigp->{_backcolor};

	}
	else {
		print("pswigp, backcolor, missing backcolor,\n");
	}
}

=head2 sub bias 


=cut

sub bias {

	my ( $self, $bias ) = @_;
	if ( $bias ne $empty_string ) {

		$pswigp->{_bias} = $bias;
		$pswigp->{_note} = $pswigp->{_note} . ' bias=' . $pswigp->{_bias};
		$pswigp->{_Step} = $pswigp->{_Step} . ' bias=' . $pswigp->{_bias};

	}
	else {
		print("pswigp, bias, missing bias,\n");
	}
}

=head2 sub clip 


=cut

sub clip {

	my ( $self, $clip ) = @_;
	if ( $clip ne $empty_string ) {

		$pswigp->{_clip} = $clip;
		$pswigp->{_note} = $pswigp->{_note} . ' clip=' . $pswigp->{_clip};
		$pswigp->{_Step} = $pswigp->{_Step} . ' clip=' . $pswigp->{_clip};

	}
	else {
		print("pswigp, clip, missing clip,\n");
	}
}

=head2 sub curve 


=cut

sub curve {

	my ( $self, $curve ) = @_;
	if ( $curve ne $empty_string ) {

		$pswigp->{_curve} = $curve;
		$pswigp->{_note}  = $pswigp->{_note} . ' curve=' . $pswigp->{_curve};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' curve=' . $pswigp->{_curve};

	}
	else {
		print("pswigp, curve, missing curve,\n");
	}
}

=head2 sub curvecolor 


=cut

sub curvecolor {

	my ( $self, $curvecolor ) = @_;
	if ( $curvecolor ne $empty_string ) {

		$pswigp->{_curvecolor} = $curvecolor;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' curvecolor=' . $pswigp->{_curvecolor};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' curvecolor=' . $pswigp->{_curvecolor};

	}
	else {
		print("pswigp, curvecolor, missing curvecolor,\n");
	}
}

=head2 sub curvedash 


=cut

sub curvedash {

	my ( $self, $curvedash ) = @_;
	if ( $curvedash ne $empty_string ) {

		$pswigp->{_curvedash} = $curvedash;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' curvedash=' . $pswigp->{_curvedash};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' curvedash=' . $pswigp->{_curvedash};

	}
	else {
		print("pswigp, curvedash, missing curvedash,\n");
	}
}

=head2 sub curvefile 


=cut

sub curvefile {

	my ( $self, $curvefile ) = @_;
	if ( $curvefile ne $empty_string ) {

		$pswigp->{_curvefile} = $curvefile;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' curvefile=' . $pswigp->{_curvefile};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' curvefile=' . $pswigp->{_curvefile};

	}
	else {
		print("pswigp, curvefile, missing curvefile,\n");
	}
}

=head2 sub curvewidth 


=cut

sub curvewidth {

	my ( $self, $curvewidth ) = @_;
	if ( $curvewidth ne $empty_string ) {

		$pswigp->{_curvewidth} = $curvewidth;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' curvewidth=' . $pswigp->{_curvewidth};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' curvewidth=' . $pswigp->{_curvewidth};

	}
	else {
		print("pswigp, curvewidth, missing curvewidth,\n");
	}
}

=head2 sub d1 


=cut

sub d1 {

	my ( $self, $d1 ) = @_;
	if ( $d1 ne $empty_string ) {

		$pswigp->{_d1}   = $d1;
		$pswigp->{_note} = $pswigp->{_note} . ' d1=' . $pswigp->{_d1};
		$pswigp->{_Step} = $pswigp->{_Step} . ' d1=' . $pswigp->{_d1};

	}
	else {
		print("pswigp, d1, missing d1,\n");
	}
}

=head2 sub d1num 


=cut

sub d1num {

	my ( $self, $d1num ) = @_;
	if ( $d1num ne $empty_string ) {

		$pswigp->{_d1num} = $d1num;
		$pswigp->{_note}  = $pswigp->{_note} . ' d1num=' . $pswigp->{_d1num};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' d1num=' . $pswigp->{_d1num};

	}
	else {
		print("pswigp, d1num, missing d1num,\n");
	}
}

=head2 sub d2 


=cut

sub d2 {

	my ( $self, $d2 ) = @_;
	if ( $d2 ne $empty_string ) {

		$pswigp->{_d2}   = $d2;
		$pswigp->{_note} = $pswigp->{_note} . ' d2=' . $pswigp->{_d2};
		$pswigp->{_Step} = $pswigp->{_Step} . ' d2=' . $pswigp->{_d2};

	}
	else {
		print("pswigp, d2, missing d2,\n");
	}
}

=head2 sub d2num 


=cut

sub d2num {

	my ( $self, $d2num ) = @_;
	if ( $d2num ne $empty_string ) {

		$pswigp->{_d2num} = $d2num;
		$pswigp->{_note}  = $pswigp->{_note} . ' d2num=' . $pswigp->{_d2num};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' d2num=' . $pswigp->{_d2num};

	}
	else {
		print("pswigp, d2num, missing d2num,\n");
	}
}

=head2 sub f1 


=cut

sub f1 {

	my ( $self, $f1 ) = @_;
	if ( $f1 ne $empty_string ) {

		$pswigp->{_f1}   = $f1;
		$pswigp->{_note} = $pswigp->{_note} . ' f1=' . $pswigp->{_f1};
		$pswigp->{_Step} = $pswigp->{_Step} . ' f1=' . $pswigp->{_f1};

	}
	else {
		print("pswigp, f1, missing f1,\n");
	}
}

=head2 sub f1num 


=cut

sub f1num {

	my ( $self, $f1num ) = @_;
	if ( $f1num ne $empty_string ) {

		$pswigp->{_f1num} = $f1num;
		$pswigp->{_note}  = $pswigp->{_note} . ' f1num=' . $pswigp->{_f1num};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' f1num=' . $pswigp->{_f1num};

	}
	else {
		print("pswigp, f1num, missing f1num,\n");
	}
}

=head2 sub f2 


=cut

sub f2 {

	my ( $self, $f2 ) = @_;
	if ( $f2 ne $empty_string ) {

		$pswigp->{_f2}   = $f2;
		$pswigp->{_note} = $pswigp->{_note} . ' f2=' . $pswigp->{_f2};
		$pswigp->{_Step} = $pswigp->{_Step} . ' f2=' . $pswigp->{_f2};

	}
	else {
		print("pswigp, f2, missing f2,\n");
	}
}

=head2 sub f2num 


=cut

sub f2num {

	my ( $self, $f2num ) = @_;
	if ( $f2num ne $empty_string ) {

		$pswigp->{_f2num} = $f2num;
		$pswigp->{_note}  = $pswigp->{_note} . ' f2num=' . $pswigp->{_f2num};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' f2num=' . $pswigp->{_f2num};

	}
	else {
		print("pswigp, f2num, missing f2num,\n");
	}
}

=head2 sub fill 


=cut

sub fill {

	my ( $self, $fill ) = @_;
	if ( $fill ne $empty_string ) {

		$pswigp->{_fill} = $fill;
		$pswigp->{_note} = $pswigp->{_note} . ' fill=' . $pswigp->{_fill};
		$pswigp->{_Step} = $pswigp->{_Step} . ' fill=' . $pswigp->{_fill};

	}
	else {
		print("pswigp, fill, missing fill,\n");
	}
}

=head2 sub grid1 


=cut

sub grid1 {

	my ( $self, $grid1 ) = @_;
	if ( $grid1 ne $empty_string ) {

		$pswigp->{_grid1} = $grid1;
		$pswigp->{_note}  = $pswigp->{_note} . ' grid1=' . $pswigp->{_grid1};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' grid1=' . $pswigp->{_grid1};

	}
	else {
		print("pswigp, grid1, missing grid1,\n");
	}
}

=head2 sub grid2 


=cut

sub grid2 {

	my ( $self, $grid2 ) = @_;
	if ( $grid2 ne $empty_string ) {

		$pswigp->{_grid2} = $grid2;
		$pswigp->{_note}  = $pswigp->{_note} . ' grid2=' . $pswigp->{_grid2};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' grid2=' . $pswigp->{_grid2};

	}
	else {
		print("pswigp, grid2, missing grid2,\n");
	}
}

=head2 sub gridcolor 


=cut

sub gridcolor {

	my ( $self, $gridcolor ) = @_;
	if ( $gridcolor ne $empty_string ) {

		$pswigp->{_gridcolor} = $gridcolor;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' gridcolor=' . $pswigp->{_gridcolor};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' gridcolor=' . $pswigp->{_gridcolor};

	}
	else {
		print("pswigp, gridcolor, missing gridcolor,\n");
	}
}

=head2 sub gridwidth 


=cut

sub gridwidth {

	my ( $self, $gridwidth ) = @_;
	if ( $gridwidth ne $empty_string ) {

		$pswigp->{_gridwidth} = $gridwidth;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' gridwidth=' . $pswigp->{_gridwidth};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' gridwidth=' . $pswigp->{_gridwidth};

	}
	else {
		print("pswigp, gridwidth, missing gridwidth,\n");
	}
}

=head2 sub hbox 


=cut

sub hbox {

	my ( $self, $hbox ) = @_;
	if ( $hbox ne $empty_string ) {

		$pswigp->{_hbox} = $hbox;
		$pswigp->{_note} = $pswigp->{_note} . ' hbox=' . $pswigp->{_hbox};
		$pswigp->{_Step} = $pswigp->{_Step} . ' hbox=' . $pswigp->{_hbox};

	}
	else {
		print("pswigp, hbox, missing hbox,\n");
	}
}

=head2 sub label1 


=cut

sub label1 {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$pswigp->{_label1} = $label1;
		$pswigp->{_note}   = $pswigp->{_note} . ' label1=' . $pswigp->{_label1};
		$pswigp->{_Step}   = $pswigp->{_Step} . ' label1=' . $pswigp->{_label1};

	}
	else {
		print("pswigp, label1, missing label1,\n");
	}
}

=head2 sub label2 


=cut

sub label2 {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$pswigp->{_label2} = $label2;
		$pswigp->{_note}   = $pswigp->{_note} . ' label2=' . $pswigp->{_label2};
		$pswigp->{_Step}   = $pswigp->{_Step} . ' label2=' . $pswigp->{_label2};

	}
	else {
		print("pswigp, label2, missing label2,\n");
	}
}

=head2 sub labelfont 


=cut

sub labelfont {

	my ( $self, $labelfont ) = @_;
	if ( $labelfont ne $empty_string ) {

		$pswigp->{_labelfont} = $labelfont;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' labelfont=' . $pswigp->{_labelfont};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' labelfont=' . $pswigp->{_labelfont};

	}
	else {
		print("pswigp, labelfont, missing labelfont,\n");
	}
}

=head2 sub labelsize 


=cut

sub labelsize {

	my ( $self, $labelsize ) = @_;
	if ( $labelsize ne $empty_string ) {

		$pswigp->{_labelsize} = $labelsize;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' labelsize=' . $pswigp->{_labelsize};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' labelsize=' . $pswigp->{_labelsize};

	}
	else {
		print("pswigp, labelsize, missing labelsize,\n");
	}
}

=head2 sub linewidth 


=cut

sub linewidth {

	my ( $self, $linewidth ) = @_;
	if ( $linewidth ne $empty_string ) {

		$pswigp->{_linewidth} = $linewidth;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' linewidth=' . $pswigp->{_linewidth};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' linewidth=' . $pswigp->{_linewidth};

	}
	else {
		print("pswigp, linewidth, missing linewidth,\n");
	}
}

=head2 sub n1 


=cut

sub n1 {

	my ( $self, $n1 ) = @_;
	if ( $n1 ne $empty_string ) {

		$pswigp->{_n1}   = $n1;
		$pswigp->{_note} = $pswigp->{_note} . ' n1=' . $pswigp->{_n1};
		$pswigp->{_Step} = $pswigp->{_Step} . ' n1=' . $pswigp->{_n1};

	}
	else {
		print("pswigp, n1, missing n1,\n");
	}
}

=head2 sub n1tic 


=cut

sub n1tic {

	my ( $self, $n1tic ) = @_;
	if ( $n1tic ne $empty_string ) {

		$pswigp->{_n1tic} = $n1tic;
		$pswigp->{_note}  = $pswigp->{_note} . ' n1tic=' . $pswigp->{_n1tic};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' n1tic=' . $pswigp->{_n1tic};

	}
	else {
		print("pswigp, n1tic, missing n1tic,\n");
	}
}

=head2 sub n2 


=cut

sub n2 {

	my ( $self, $n2 ) = @_;
	if ( $n2 ne $empty_string ) {

		$pswigp->{_n2}   = $n2;
		$pswigp->{_note} = $pswigp->{_note} . ' n2=' . $pswigp->{_n2};
		$pswigp->{_Step} = $pswigp->{_Step} . ' n2=' . $pswigp->{_n2};

	}
	else {
		print("pswigp, n2, missing n2,\n");
	}
}

=head2 sub n2tic 


=cut

sub n2tic {

	my ( $self, $n2tic ) = @_;
	if ( $n2tic ne $empty_string ) {

		$pswigp->{_n2tic} = $n2tic;
		$pswigp->{_note}  = $pswigp->{_note} . ' n2tic=' . $pswigp->{_n2tic};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' n2tic=' . $pswigp->{_n2tic};

	}
	else {
		print("pswigp, n2tic, missing n2tic,\n");
	}
}

=head2 sub npair 


=cut

sub npair {

	my ( $self, $npair ) = @_;
	if ( $npair ne $empty_string ) {

		$pswigp->{_npair} = $npair;
		$pswigp->{_note}  = $pswigp->{_note} . ' npair=' . $pswigp->{_npair};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' npair=' . $pswigp->{_npair};

	}
	else {
		print("pswigp, npair, missing npair,\n");
	}
}

=head2 sub perc 


=cut

sub perc {

	my ( $self, $perc ) = @_;
	if ( $perc ne $empty_string ) {

		$pswigp->{_perc} = $perc;
		$pswigp->{_note} = $pswigp->{_note} . ' perc=' . $pswigp->{_perc};
		$pswigp->{_Step} = $pswigp->{_Step} . ' perc=' . $pswigp->{_perc};

	}
	else {
		print("pswigp, perc, missing perc,\n");
	}
}

=head2 sub style 


=cut

sub style {

	my ( $self, $style ) = @_;
	if ( $style ne $empty_string ) {

		$pswigp->{_style} = $style;
		$pswigp->{_note}  = $pswigp->{_note} . ' style=' . $pswigp->{_style};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' style=' . $pswigp->{_style};

	}
	else {
		print("pswigp, style, missing style,\n");
	}
}

=head2 sub ticwidth 


=cut

sub ticwidth {

	my ( $self, $ticwidth ) = @_;
	if ( $ticwidth ne $empty_string ) {

		$pswigp->{_ticwidth} = $ticwidth;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' ticwidth=' . $pswigp->{_ticwidth};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' ticwidth=' . $pswigp->{_ticwidth};

	}
	else {
		print("pswigp, ticwidth, missing ticwidth,\n");
	}
}

=head2 sub title 


=cut

sub title {

	my ( $self, $title ) = @_;
	if ( $title ne $empty_string ) {

		$pswigp->{_title} = $title;
		$pswigp->{_note}  = $pswigp->{_note} . ' title=' . $pswigp->{_title};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' title=' . $pswigp->{_title};

	}
	else {
		print("pswigp, title, missing title,\n");
	}
}

=head2 sub titlecolor 


=cut

sub titlecolor {

	my ( $self, $titlecolor ) = @_;
	if ( $titlecolor ne $empty_string ) {

		$pswigp->{_titlecolor} = $titlecolor;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' titlecolor=' . $pswigp->{_titlecolor};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' titlecolor=' . $pswigp->{_titlecolor};

	}
	else {
		print("pswigp, titlecolor, missing titlecolor,\n");
	}
}

=head2 sub titlefont 


=cut

sub titlefont {

	my ( $self, $titlefont ) = @_;
	if ( $titlefont ne $empty_string ) {

		$pswigp->{_titlefont} = $titlefont;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' titlefont=' . $pswigp->{_titlefont};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' titlefont=' . $pswigp->{_titlefont};

	}
	else {
		print("pswigp, titlefont, missing titlefont,\n");
	}
}

=head2 sub titlesize 


=cut

sub titlesize {

	my ( $self, $titlesize ) = @_;
	if ( $titlesize ne $empty_string ) {

		$pswigp->{_titlesize} = $titlesize;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' titlesize=' . $pswigp->{_titlesize};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' titlesize=' . $pswigp->{_titlesize};

	}
	else {
		print("pswigp, titlesize, missing titlesize,\n");
	}
}

=head2 sub tracecolor 


=cut

sub tracecolor {

	my ( $self, $tracecolor ) = @_;
	if ( $tracecolor ne $empty_string ) {

		$pswigp->{_tracecolor} = $tracecolor;
		$pswigp->{_note} =
		  $pswigp->{_note} . ' tracecolor=' . $pswigp->{_tracecolor};
		$pswigp->{_Step} =
		  $pswigp->{_Step} . ' tracecolor=' . $pswigp->{_tracecolor};

	}
	else {
		print("pswigp, tracecolor, missing tracecolor,\n");
	}
}

=head2 sub verbose 


=cut

sub verbose {

	my ( $self, $verbose ) = @_;
	if ( $verbose ne $empty_string ) {

		$pswigp->{_verbose} = $verbose;
		$pswigp->{_note} = $pswigp->{_note} . ' verbose=' . $pswigp->{_verbose};
		$pswigp->{_Step} = $pswigp->{_Step} . ' verbose=' . $pswigp->{_verbose};

	}
	else {
		print("pswigp, verbose, missing verbose,\n");
	}
}

=head2 sub wbox 


=cut

sub wbox {

	my ( $self, $wbox ) = @_;
	if ( $wbox ne $empty_string ) {

		$pswigp->{_wbox} = $wbox;
		$pswigp->{_note} = $pswigp->{_note} . ' wbox=' . $pswigp->{_wbox};
		$pswigp->{_Step} = $pswigp->{_Step} . ' wbox=' . $pswigp->{_wbox};

	}
	else {
		print("pswigp, wbox, missing wbox,\n");
	}
}

=head2 sub x1beg 


=cut

sub x1beg {

	my ( $self, $x1beg ) = @_;
	if ( $x1beg ne $empty_string ) {

		$pswigp->{_x1beg} = $x1beg;
		$pswigp->{_note}  = $pswigp->{_note} . ' x1beg=' . $pswigp->{_x1beg};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' x1beg=' . $pswigp->{_x1beg};

	}
	else {
		print("pswigp, x1beg, missing x1beg,\n");
	}
}

=head2 sub x1end 


=cut

sub x1end {

	my ( $self, $x1end ) = @_;
	if ( $x1end ne $empty_string ) {

		$pswigp->{_x1end} = $x1end;
		$pswigp->{_note}  = $pswigp->{_note} . ' x1end=' . $pswigp->{_x1end};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' x1end=' . $pswigp->{_x1end};

	}
	else {
		print("pswigp, x1end, missing x1end,\n");
	}
}

=head2 sub x2 


=cut

sub x2 {

	my ( $self, $x2 ) = @_;
	if ( $x2 ne $empty_string ) {

		$pswigp->{_x2}   = $x2;
		$pswigp->{_note} = $pswigp->{_note} . ' x2=' . $pswigp->{_x2};
		$pswigp->{_Step} = $pswigp->{_Step} . ' x2=' . $pswigp->{_x2};

	}
	else {
		print("pswigp, x2, missing x2,\n");
	}
}

=head2 sub x2beg 


=cut

sub x2beg {

	my ( $self, $x2beg ) = @_;
	if ( $x2beg ne $empty_string ) {

		$pswigp->{_x2beg} = $x2beg;
		$pswigp->{_note}  = $pswigp->{_note} . ' x2beg=' . $pswigp->{_x2beg};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' x2beg=' . $pswigp->{_x2beg};

	}
	else {
		print("pswigp, x2beg, missing x2beg,\n");
	}
}

=head2 sub x2end 


=cut

sub x2end {

	my ( $self, $x2end ) = @_;
	if ( $x2end ne $empty_string ) {

		$pswigp->{_x2end} = $x2end;
		$pswigp->{_note}  = $pswigp->{_note} . ' x2end=' . $pswigp->{_x2end};
		$pswigp->{_Step}  = $pswigp->{_Step} . ' x2end=' . $pswigp->{_x2end};

	}
	else {
		print("pswigp, x2end, missing x2end,\n");
	}
}

=head2 sub xbox 


=cut

sub xbox {

	my ( $self, $xbox ) = @_;
	if ( $xbox ne $empty_string ) {

		$pswigp->{_xbox} = $xbox;
		$pswigp->{_note} = $pswigp->{_note} . ' xbox=' . $pswigp->{_xbox};
		$pswigp->{_Step} = $pswigp->{_Step} . ' xbox=' . $pswigp->{_xbox};

	}
	else {
		print("pswigp, xbox, missing xbox,\n");
	}
}

=head2 sub xcur 


=cut

sub xcur {

	my ( $self, $xcur ) = @_;
	if ( $xcur ne $empty_string ) {

		$pswigp->{_xcur} = $xcur;
		$pswigp->{_note} = $pswigp->{_note} . ' xcur=' . $pswigp->{_xcur};
		$pswigp->{_Step} = $pswigp->{_Step} . ' xcur=' . $pswigp->{_xcur};

	}
	else {
		print("pswigp, xcur, missing xcur,\n");
	}
}

=head2 sub ybox 


=cut

sub ybox {

	my ( $self, $ybox ) = @_;
	if ( $ybox ne $empty_string ) {

		$pswigp->{_ybox} = $ybox;
		$pswigp->{_note} = $pswigp->{_note} . ' ybox=' . $pswigp->{_ybox};
		$pswigp->{_Step} = $pswigp->{_Step} . ' ybox=' . $pswigp->{_ybox};

	}
	else {
		print("pswigp, ybox, missing ybox,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 52;

	return ($max_index);
}

1;
