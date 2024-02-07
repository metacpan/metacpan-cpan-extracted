package App::SeismicUnixGui::sunix::plot::pscontour;

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
 PSCONTOUR - PostScript CONTOURing of a two-dimensional function f(x1,x2)



 pscontour n1= [optional parameters] <binaryfile >postscriptfile	



 Required Parameters:							

 n1                     number of samples in 1st (fast) dimension	



 Optional Parameters:							

 d1=1.0                 sampling interval in 1st dimension		

 f1=d1                  first sample in 1st dimension			

 x1=f1,f1+d1,...        array of monotonic sampled values in 1st dimension

 n2=all                 number of samples in 2nd (slow) dimension	

 d2=1.0                 sampling interval in 2nd dimension		

 f2=d2                  first sample in 2nd dimension			

 x2=f2,f2+d2,...        array of monotonic sampled values in 2nd dimension

 nc=5                   number of contour values			

 dc=(zmax-zmin)/nc      contour interval				

 fc=min+dc              first contour					

 c=fc,fc+dc,...         array of contour values			

 cwidth=1.0,...         array of contour line widths			

 cgray=0.0,...          array of contour grays (0.0=black to 1.0=white)

 ccolor=none,...        array of contour colors; none means use cgray	

 cdash=0.0,...          array of dash spacings (0.0 for solid)		

 labelcf=1              first labeled contour (1,2,3,...)

 labelcper=1            label every labelcper-th contour		

 nlabelc=nc             number of labeled contours (0 no contour label)

 nplaces=6              number of decimal places in contour label      

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

 labelcfont=Helvetica-Bold font name for contour labels		

 labelcsize=6           font size of contour labels   			

 labelccolor=black      color of contour labels   			

 titlecolor=black       color of title					

 axescolor=black        color of axes					

 gridcolor=black        color of grid					

 axeswidth=1            width (in points) of axes			

 ticwidth=axeswidth     width (in points) of tic marks		

 gridwidth=axeswidth    width (in points) of grid lines		

 style=seismic          normal (axis 1 horizontal, axis 2 vertical) or	

                        seismic (axis 1 vertical, axis 2 horizontal)	



 Note.									

 The line width of unlabeled contours is designed as a quarter of that	

 of labeled contours. 							



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

 type:   sudoc pscontour    for more information			





Notes:



 For nice even-numbered contours, use the parameters  fc and dc



 Example: if the range of the z values of a data set range between

 approximately -1000 and +1000, then use fc=-1000 nc=10 and dc=100

 to get contours spaced by even 100's.







 AUTHOR:  Dave Hale, Colorado School of Mines, 05/29/90

 MODIFIED:  Craig Artley, Colorado School of Mines, 08/30/91

            BoundingBox moved to top of PostScript output

 MODIFIED:  Zhenyue Liu, Colorado School of Mines, 08/26/93

	      Values are labeled on contours  

 MODIFIED:  Craig Artley, Colorado School of Mines, 12/16/93

            Added color options (Courtesy of Dave Hale, Advance Geophysical).

 Modified: Morten Wendell Pedersen, Aarhus University, 23/3-97

           Added ticwidth,axeswidth, gridwidth parameters 





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

my $pscontour = {
	_axescolor   => '',
	_axeswidth   => '',
	_c           => '',
	_ccolor      => '',
	_cdash       => '',
	_cgray       => '',
	_cwidth      => '',
	_d1          => '',
	_d1num       => '',
	_d2          => '',
	_d2num       => '',
	_dc          => '',
	_f1          => '',
	_f1num       => '',
	_f2          => '',
	_f2num       => '',
	_fc          => '',
	_grid1       => '',
	_grid2       => '',
	_gridcolor   => '',
	_gridwidth   => '',
	_hbox        => '',
	_label1      => '',
	_label2      => '',
	_labelccolor => '',
	_labelcf     => '',
	_labelcfont  => '',
	_labelcper   => '',
	_labelcsize  => '',
	_labelfont   => '',
	_labelsize   => '',
	_n1          => '',
	_n1tic       => '',
	_n2          => '',
	_n2tic       => '',
	_nc          => '',
	_nlabelc     => '',
	_nplaces     => '',
	_style       => '',
	_ticwidth    => '',
	_title       => '',
	_titlecolor  => '',
	_titlefont   => '',
	_titlesize   => '',
	_wbox        => '',
	_x1          => '',
	_x1beg       => '',
	_x1end       => '',
	_x2          => '',
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

	$pscontour->{_Step} = 'pscontour' . $pscontour->{_Step};
	return ( $pscontour->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$pscontour->{_note} = 'pscontour' . $pscontour->{_note};
	return ( $pscontour->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$pscontour->{_axescolor}   = '';
	$pscontour->{_axeswidth}   = '';
	$pscontour->{_c}           = '';
	$pscontour->{_ccolor}      = '';
	$pscontour->{_cdash}       = '';
	$pscontour->{_cgray}       = '';
	$pscontour->{_cwidth}      = '';
	$pscontour->{_d1}          = '';
	$pscontour->{_d1num}       = '';
	$pscontour->{_d2}          = '';
	$pscontour->{_d2num}       = '';
	$pscontour->{_dc}          = '';
	$pscontour->{_f1}          = '';
	$pscontour->{_f1num}       = '';
	$pscontour->{_f2}          = '';
	$pscontour->{_f2num}       = '';
	$pscontour->{_fc}          = '';
	$pscontour->{_grid1}       = '';
	$pscontour->{_grid2}       = '';
	$pscontour->{_gridcolor}   = '';
	$pscontour->{_gridwidth}   = '';
	$pscontour->{_hbox}        = '';
	$pscontour->{_label1}      = '';
	$pscontour->{_label2}      = '';
	$pscontour->{_labelccolor} = '';
	$pscontour->{_labelcf}     = '';
	$pscontour->{_labelcfont}  = '';
	$pscontour->{_labelcper}   = '';
	$pscontour->{_labelcsize}  = '';
	$pscontour->{_labelfont}   = '';
	$pscontour->{_labelsize}   = '';
	$pscontour->{_n1}          = '';
	$pscontour->{_n1tic}       = '';
	$pscontour->{_n2}          = '';
	$pscontour->{_n2tic}       = '';
	$pscontour->{_nc}          = '';
	$pscontour->{_nlabelc}     = '';
	$pscontour->{_nplaces}     = '';
	$pscontour->{_style}       = '';
	$pscontour->{_ticwidth}    = '';
	$pscontour->{_title}       = '';
	$pscontour->{_titlecolor}  = '';
	$pscontour->{_titlefont}   = '';
	$pscontour->{_titlesize}   = '';
	$pscontour->{_wbox}        = '';
	$pscontour->{_x1}          = '';
	$pscontour->{_x1beg}       = '';
	$pscontour->{_x1end}       = '';
	$pscontour->{_x2}          = '';
	$pscontour->{_x2beg}       = '';
	$pscontour->{_x2end}       = '';
	$pscontour->{_xbox}        = '';
	$pscontour->{_ybox}        = '';
	$pscontour->{_Step}        = '';
	$pscontour->{_note}        = '';
}

=head2 sub axescolor 


=cut

sub axescolor {

	my ( $self, $axescolor ) = @_;
	if ( $axescolor ne $empty_string ) {

		$pscontour->{_axescolor} = $axescolor;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' axescolor=' . $pscontour->{_axescolor};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' axescolor=' . $pscontour->{_axescolor};

	}
	else {
		print("pscontour, axescolor, missing axescolor,\n");
	}
}

=head2 sub axeswidth 


=cut

sub axeswidth {

	my ( $self, $axeswidth ) = @_;
	if ( $axeswidth ne $empty_string ) {

		$pscontour->{_axeswidth} = $axeswidth;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' axeswidth=' . $pscontour->{_axeswidth};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' axeswidth=' . $pscontour->{_axeswidth};

	}
	else {
		print("pscontour, axeswidth, missing axeswidth,\n");
	}
}

=head2 sub c 


=cut

sub c {

	my ( $self, $c ) = @_;
	if ( $c ne $empty_string ) {

		$pscontour->{_c}    = $c;
		$pscontour->{_note} = $pscontour->{_note} . ' c=' . $pscontour->{_c};
		$pscontour->{_Step} = $pscontour->{_Step} . ' c=' . $pscontour->{_c};

	}
	else {
		print("pscontour, c, missing c,\n");
	}
}

=head2 sub ccolor 


=cut

sub ccolor {

	my ( $self, $ccolor ) = @_;
	if ( $ccolor ne $empty_string ) {

		$pscontour->{_ccolor} = $ccolor;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' ccolor=' . $pscontour->{_ccolor};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' ccolor=' . $pscontour->{_ccolor};

	}
	else {
		print("pscontour, ccolor, missing ccolor,\n");
	}
}

=head2 sub cdash 


=cut

sub cdash {

	my ( $self, $cdash ) = @_;
	if ( $cdash ne $empty_string ) {

		$pscontour->{_cdash} = $cdash;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' cdash=' . $pscontour->{_cdash};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' cdash=' . $pscontour->{_cdash};

	}
	else {
		print("pscontour, cdash, missing cdash,\n");
	}
}

=head2 sub cgray 


=cut

sub cgray {

	my ( $self, $cgray ) = @_;
	if ( $cgray ne $empty_string ) {

		$pscontour->{_cgray} = $cgray;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' cgray=' . $pscontour->{_cgray};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' cgray=' . $pscontour->{_cgray};

	}
	else {
		print("pscontour, cgray, missing cgray,\n");
	}
}

=head2 sub cwidth 


=cut

sub cwidth {

	my ( $self, $cwidth ) = @_;
	if ( $cwidth ne $empty_string ) {

		$pscontour->{_cwidth} = $cwidth;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' cwidth=' . $pscontour->{_cwidth};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' cwidth=' . $pscontour->{_cwidth};

	}
	else {
		print("pscontour, cwidth, missing cwidth,\n");
	}
}

=head2 sub d1 


=cut

sub d1 {

	my ( $self, $d1 ) = @_;
	if ( $d1 ne $empty_string ) {

		$pscontour->{_d1}   = $d1;
		$pscontour->{_note} = $pscontour->{_note} . ' d1=' . $pscontour->{_d1};
		$pscontour->{_Step} = $pscontour->{_Step} . ' d1=' . $pscontour->{_d1};

	}
	else {
		print("pscontour, d1, missing d1,\n");
	}
}

=head2 sub d1num 


=cut

sub d1num {

	my ( $self, $d1num ) = @_;
	if ( $d1num ne $empty_string ) {

		$pscontour->{_d1num} = $d1num;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' d1num=' . $pscontour->{_d1num};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' d1num=' . $pscontour->{_d1num};

	}
	else {
		print("pscontour, d1num, missing d1num,\n");
	}
}

=head2 sub d2 


=cut

sub d2 {

	my ( $self, $d2 ) = @_;
	if ( $d2 ne $empty_string ) {

		$pscontour->{_d2}   = $d2;
		$pscontour->{_note} = $pscontour->{_note} . ' d2=' . $pscontour->{_d2};
		$pscontour->{_Step} = $pscontour->{_Step} . ' d2=' . $pscontour->{_d2};

	}
	else {
		print("pscontour, d2, missing d2,\n");
	}
}

=head2 sub d2num 


=cut

sub d2num {

	my ( $self, $d2num ) = @_;
	if ( $d2num ne $empty_string ) {

		$pscontour->{_d2num} = $d2num;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' d2num=' . $pscontour->{_d2num};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' d2num=' . $pscontour->{_d2num};

	}
	else {
		print("pscontour, d2num, missing d2num,\n");
	}
}

=head2 sub dc 


=cut

sub dc {

	my ( $self, $dc ) = @_;
	if ( $dc ne $empty_string ) {

		$pscontour->{_dc}   = $dc;
		$pscontour->{_note} = $pscontour->{_note} . ' dc=' . $pscontour->{_dc};
		$pscontour->{_Step} = $pscontour->{_Step} . ' dc=' . $pscontour->{_dc};

	}
	else {
		print("pscontour, dc, missing dc,\n");
	}
}

=head2 sub f1 


=cut

sub f1 {

	my ( $self, $f1 ) = @_;
	if ( $f1 ne $empty_string ) {

		$pscontour->{_f1}   = $f1;
		$pscontour->{_note} = $pscontour->{_note} . ' f1=' . $pscontour->{_f1};
		$pscontour->{_Step} = $pscontour->{_Step} . ' f1=' . $pscontour->{_f1};

	}
	else {
		print("pscontour, f1, missing f1,\n");
	}
}

=head2 sub f1num 


=cut

sub f1num {

	my ( $self, $f1num ) = @_;
	if ( $f1num ne $empty_string ) {

		$pscontour->{_f1num} = $f1num;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' f1num=' . $pscontour->{_f1num};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' f1num=' . $pscontour->{_f1num};

	}
	else {
		print("pscontour, f1num, missing f1num,\n");
	}
}

=head2 sub f2 


=cut

sub f2 {

	my ( $self, $f2 ) = @_;
	if ( $f2 ne $empty_string ) {

		$pscontour->{_f2}   = $f2;
		$pscontour->{_note} = $pscontour->{_note} . ' f2=' . $pscontour->{_f2};
		$pscontour->{_Step} = $pscontour->{_Step} . ' f2=' . $pscontour->{_f2};

	}
	else {
		print("pscontour, f2, missing f2,\n");
	}
}

=head2 sub f2num 


=cut

sub f2num {

	my ( $self, $f2num ) = @_;
	if ( $f2num ne $empty_string ) {

		$pscontour->{_f2num} = $f2num;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' f2num=' . $pscontour->{_f2num};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' f2num=' . $pscontour->{_f2num};

	}
	else {
		print("pscontour, f2num, missing f2num,\n");
	}
}

=head2 sub fc 


=cut

sub fc {

	my ( $self, $fc ) = @_;
	if ( $fc ne $empty_string ) {

		$pscontour->{_fc}   = $fc;
		$pscontour->{_note} = $pscontour->{_note} . ' fc=' . $pscontour->{_fc};
		$pscontour->{_Step} = $pscontour->{_Step} . ' fc=' . $pscontour->{_fc};

	}
	else {
		print("pscontour, fc, missing fc,\n");
	}
}

=head2 sub grid1 


=cut

sub grid1 {

	my ( $self, $grid1 ) = @_;
	if ( $grid1 ne $empty_string ) {

		$pscontour->{_grid1} = $grid1;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' grid1=' . $pscontour->{_grid1};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' grid1=' . $pscontour->{_grid1};

	}
	else {
		print("pscontour, grid1, missing grid1,\n");
	}
}

=head2 sub grid2 


=cut

sub grid2 {

	my ( $self, $grid2 ) = @_;
	if ( $grid2 ne $empty_string ) {

		$pscontour->{_grid2} = $grid2;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' grid2=' . $pscontour->{_grid2};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' grid2=' . $pscontour->{_grid2};

	}
	else {
		print("pscontour, grid2, missing grid2,\n");
	}
}

=head2 sub gridcolor 


=cut

sub gridcolor {

	my ( $self, $gridcolor ) = @_;
	if ( $gridcolor ne $empty_string ) {

		$pscontour->{_gridcolor} = $gridcolor;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' gridcolor=' . $pscontour->{_gridcolor};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' gridcolor=' . $pscontour->{_gridcolor};

	}
	else {
		print("pscontour, gridcolor, missing gridcolor,\n");
	}
}

=head2 sub gridwidth 


=cut

sub gridwidth {

	my ( $self, $gridwidth ) = @_;
	if ( $gridwidth ne $empty_string ) {

		$pscontour->{_gridwidth} = $gridwidth;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' gridwidth=' . $pscontour->{_gridwidth};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' gridwidth=' . $pscontour->{_gridwidth};

	}
	else {
		print("pscontour, gridwidth, missing gridwidth,\n");
	}
}

=head2 sub hbox 


=cut

sub hbox {

	my ( $self, $hbox ) = @_;
	if ( $hbox ne $empty_string ) {

		$pscontour->{_hbox} = $hbox;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' hbox=' . $pscontour->{_hbox};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' hbox=' . $pscontour->{_hbox};

	}
	else {
		print("pscontour, hbox, missing hbox,\n");
	}
}

=head2 sub label1 


=cut

sub label1 {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$pscontour->{_label1} = $label1;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' label1=' . $pscontour->{_label1};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' label1=' . $pscontour->{_label1};

	}
	else {
		print("pscontour, label1, missing label1,\n");
	}
}

=head2 sub label2 


=cut

sub label2 {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$pscontour->{_label2} = $label2;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' label2=' . $pscontour->{_label2};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' label2=' . $pscontour->{_label2};

	}
	else {
		print("pscontour, label2, missing label2,\n");
	}
}

=head2 sub labelccolor 


=cut

sub labelccolor {

	my ( $self, $labelccolor ) = @_;
	if ( $labelccolor ne $empty_string ) {

		$pscontour->{_labelccolor} = $labelccolor;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' labelccolor=' . $pscontour->{_labelccolor};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' labelccolor=' . $pscontour->{_labelccolor};

	}
	else {
		print("pscontour, labelccolor, missing labelccolor,\n");
	}
}

=head2 sub labelcf 


=cut

sub labelcf {

	my ( $self, $labelcf ) = @_;
	if ( $labelcf ne $empty_string ) {

		$pscontour->{_labelcf} = $labelcf;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' labelcf=' . $pscontour->{_labelcf};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' labelcf=' . $pscontour->{_labelcf};

	}
	else {
		print("pscontour, labelcf, missing labelcf,\n");
	}
}

=head2 sub labelcfont 


=cut

sub labelcfont {

	my ( $self, $labelcfont ) = @_;
	if ( $labelcfont ne $empty_string ) {

		$pscontour->{_labelcfont} = $labelcfont;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' labelcfont=' . $pscontour->{_labelcfont};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' labelcfont=' . $pscontour->{_labelcfont};

	}
	else {
		print("pscontour, labelcfont, missing labelcfont,\n");
	}
}

=head2 sub labelcper 


=cut

sub labelcper {

	my ( $self, $labelcper ) = @_;
	if ( $labelcper ne $empty_string ) {

		$pscontour->{_labelcper} = $labelcper;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' labelcper=' . $pscontour->{_labelcper};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' labelcper=' . $pscontour->{_labelcper};

	}
	else {
		print("pscontour, labelcper, missing labelcper,\n");
	}
}

=head2 sub labelcsize 


=cut

sub labelcsize {

	my ( $self, $labelcsize ) = @_;
	if ( $labelcsize ne $empty_string ) {

		$pscontour->{_labelcsize} = $labelcsize;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' labelcsize=' . $pscontour->{_labelcsize};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' labelcsize=' . $pscontour->{_labelcsize};

	}
	else {
		print("pscontour, labelcsize, missing labelcsize,\n");
	}
}

=head2 sub labelfont 


=cut

sub labelfont {

	my ( $self, $labelfont ) = @_;
	if ( $labelfont ne $empty_string ) {

		$pscontour->{_labelfont} = $labelfont;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' labelfont=' . $pscontour->{_labelfont};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' labelfont=' . $pscontour->{_labelfont};

	}
	else {
		print("pscontour, labelfont, missing labelfont,\n");
	}
}

=head2 sub labelsize 


=cut

sub labelsize {

	my ( $self, $labelsize ) = @_;
	if ( $labelsize ne $empty_string ) {

		$pscontour->{_labelsize} = $labelsize;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' labelsize=' . $pscontour->{_labelsize};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' labelsize=' . $pscontour->{_labelsize};

	}
	else {
		print("pscontour, labelsize, missing labelsize,\n");
	}
}

=head2 sub n1 


=cut

sub n1 {

	my ( $self, $n1 ) = @_;
	if ( $n1 ne $empty_string ) {

		$pscontour->{_n1}   = $n1;
		$pscontour->{_note} = $pscontour->{_note} . ' n1=' . $pscontour->{_n1};
		$pscontour->{_Step} = $pscontour->{_Step} . ' n1=' . $pscontour->{_n1};

	}
	else {
		print("pscontour, n1, missing n1,\n");
	}
}

=head2 sub n1tic 


=cut

sub n1tic {

	my ( $self, $n1tic ) = @_;
	if ( $n1tic ne $empty_string ) {

		$pscontour->{_n1tic} = $n1tic;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' n1tic=' . $pscontour->{_n1tic};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' n1tic=' . $pscontour->{_n1tic};

	}
	else {
		print("pscontour, n1tic, missing n1tic,\n");
	}
}

=head2 sub n2 


=cut

sub n2 {

	my ( $self, $n2 ) = @_;
	if ( $n2 ne $empty_string ) {

		$pscontour->{_n2}   = $n2;
		$pscontour->{_note} = $pscontour->{_note} . ' n2=' . $pscontour->{_n2};
		$pscontour->{_Step} = $pscontour->{_Step} . ' n2=' . $pscontour->{_n2};

	}
	else {
		print("pscontour, n2, missing n2,\n");
	}
}

=head2 sub n2tic 


=cut

sub n2tic {

	my ( $self, $n2tic ) = @_;
	if ( $n2tic ne $empty_string ) {

		$pscontour->{_n2tic} = $n2tic;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' n2tic=' . $pscontour->{_n2tic};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' n2tic=' . $pscontour->{_n2tic};

	}
	else {
		print("pscontour, n2tic, missing n2tic,\n");
	}
}

=head2 sub nc 


=cut

sub nc {

	my ( $self, $nc ) = @_;
	if ( $nc ne $empty_string ) {

		$pscontour->{_nc}   = $nc;
		$pscontour->{_note} = $pscontour->{_note} . ' nc=' . $pscontour->{_nc};
		$pscontour->{_Step} = $pscontour->{_Step} . ' nc=' . $pscontour->{_nc};

	}
	else {
		print("pscontour, nc, missing nc,\n");
	}
}

=head2 sub nlabelc 


=cut

sub nlabelc {

	my ( $self, $nlabelc ) = @_;
	if ( $nlabelc ne $empty_string ) {

		$pscontour->{_nlabelc} = $nlabelc;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' nlabelc=' . $pscontour->{_nlabelc};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' nlabelc=' . $pscontour->{_nlabelc};

	}
	else {
		print("pscontour, nlabelc, missing nlabelc,\n");
	}
}

=head2 sub nplaces 


=cut

sub nplaces {

	my ( $self, $nplaces ) = @_;
	if ( $nplaces ne $empty_string ) {

		$pscontour->{_nplaces} = $nplaces;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' nplaces=' . $pscontour->{_nplaces};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' nplaces=' . $pscontour->{_nplaces};

	}
	else {
		print("pscontour, nplaces, missing nplaces,\n");
	}
}

=head2 sub style 


=cut

sub style {

	my ( $self, $style ) = @_;
	if ( $style ne $empty_string ) {

		$pscontour->{_style} = $style;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' style=' . $pscontour->{_style};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' style=' . $pscontour->{_style};

	}
	else {
		print("pscontour, style, missing style,\n");
	}
}

=head2 sub ticwidth 


=cut

sub ticwidth {

	my ( $self, $ticwidth ) = @_;
	if ( $ticwidth ne $empty_string ) {

		$pscontour->{_ticwidth} = $ticwidth;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' ticwidth=' . $pscontour->{_ticwidth};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' ticwidth=' . $pscontour->{_ticwidth};

	}
	else {
		print("pscontour, ticwidth, missing ticwidth,\n");
	}
}

=head2 sub title 


=cut

sub title {

	my ( $self, $title ) = @_;
	if ( $title ne $empty_string ) {

		$pscontour->{_title} = $title;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' title=' . $pscontour->{_title};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' title=' . $pscontour->{_title};

	}
	else {
		print("pscontour, title, missing title,\n");
	}
}

=head2 sub titlecolor 


=cut

sub titlecolor {

	my ( $self, $titlecolor ) = @_;
	if ( $titlecolor ne $empty_string ) {

		$pscontour->{_titlecolor} = $titlecolor;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' titlecolor=' . $pscontour->{_titlecolor};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' titlecolor=' . $pscontour->{_titlecolor};

	}
	else {
		print("pscontour, titlecolor, missing titlecolor,\n");
	}
}

=head2 sub titlefont 


=cut

sub titlefont {

	my ( $self, $titlefont ) = @_;
	if ( $titlefont ne $empty_string ) {

		$pscontour->{_titlefont} = $titlefont;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' titlefont=' . $pscontour->{_titlefont};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' titlefont=' . $pscontour->{_titlefont};

	}
	else {
		print("pscontour, titlefont, missing titlefont,\n");
	}
}

=head2 sub titlesize 


=cut

sub titlesize {

	my ( $self, $titlesize ) = @_;
	if ( $titlesize ne $empty_string ) {

		$pscontour->{_titlesize} = $titlesize;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' titlesize=' . $pscontour->{_titlesize};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' titlesize=' . $pscontour->{_titlesize};

	}
	else {
		print("pscontour, titlesize, missing titlesize,\n");
	}
}

=head2 sub wbox 


=cut

sub wbox {

	my ( $self, $wbox ) = @_;
	if ( $wbox ne $empty_string ) {

		$pscontour->{_wbox} = $wbox;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' wbox=' . $pscontour->{_wbox};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' wbox=' . $pscontour->{_wbox};

	}
	else {
		print("pscontour, wbox, missing wbox,\n");
	}
}

=head2 sub x1 


=cut

sub x1 {

	my ( $self, $x1 ) = @_;
	if ( $x1 ne $empty_string ) {

		$pscontour->{_x1}   = $x1;
		$pscontour->{_note} = $pscontour->{_note} . ' x1=' . $pscontour->{_x1};
		$pscontour->{_Step} = $pscontour->{_Step} . ' x1=' . $pscontour->{_x1};

	}
	else {
		print("pscontour, x1, missing x1,\n");
	}
}

=head2 sub x1beg 


=cut

sub x1beg {

	my ( $self, $x1beg ) = @_;
	if ( $x1beg ne $empty_string ) {

		$pscontour->{_x1beg} = $x1beg;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' x1beg=' . $pscontour->{_x1beg};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' x1beg=' . $pscontour->{_x1beg};

	}
	else {
		print("pscontour, x1beg, missing x1beg,\n");
	}
}

=head2 sub x1end 


=cut

sub x1end {

	my ( $self, $x1end ) = @_;
	if ( $x1end ne $empty_string ) {

		$pscontour->{_x1end} = $x1end;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' x1end=' . $pscontour->{_x1end};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' x1end=' . $pscontour->{_x1end};

	}
	else {
		print("pscontour, x1end, missing x1end,\n");
	}
}

=head2 sub x2 


=cut

sub x2 {

	my ( $self, $x2 ) = @_;
	if ( $x2 ne $empty_string ) {

		$pscontour->{_x2}   = $x2;
		$pscontour->{_note} = $pscontour->{_note} . ' x2=' . $pscontour->{_x2};
		$pscontour->{_Step} = $pscontour->{_Step} . ' x2=' . $pscontour->{_x2};

	}
	else {
		print("pscontour, x2, missing x2,\n");
	}
}

=head2 sub x2beg 


=cut

sub x2beg {

	my ( $self, $x2beg ) = @_;
	if ( $x2beg ne $empty_string ) {

		$pscontour->{_x2beg} = $x2beg;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' x2beg=' . $pscontour->{_x2beg};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' x2beg=' . $pscontour->{_x2beg};

	}
	else {
		print("pscontour, x2beg, missing x2beg,\n");
	}
}

=head2 sub x2end 


=cut

sub x2end {

	my ( $self, $x2end ) = @_;
	if ( $x2end ne $empty_string ) {

		$pscontour->{_x2end} = $x2end;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' x2end=' . $pscontour->{_x2end};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' x2end=' . $pscontour->{_x2end};

	}
	else {
		print("pscontour, x2end, missing x2end,\n");
	}
}

=head2 sub xbox 


=cut

sub xbox {

	my ( $self, $xbox ) = @_;
	if ( $xbox ne $empty_string ) {

		$pscontour->{_xbox} = $xbox;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' xbox=' . $pscontour->{_xbox};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' xbox=' . $pscontour->{_xbox};

	}
	else {
		print("pscontour, xbox, missing xbox,\n");
	}
}

=head2 sub ybox 


=cut

sub ybox {

	my ( $self, $ybox ) = @_;
	if ( $ybox ne $empty_string ) {

		$pscontour->{_ybox} = $ybox;
		$pscontour->{_note} =
		  $pscontour->{_note} . ' ybox=' . $pscontour->{_ybox};
		$pscontour->{_Step} =
		  $pscontour->{_Step} . ' ybox=' . $pscontour->{_ybox};

	}
	else {
		print("pscontour, ybox, missing ybox,\n");
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
