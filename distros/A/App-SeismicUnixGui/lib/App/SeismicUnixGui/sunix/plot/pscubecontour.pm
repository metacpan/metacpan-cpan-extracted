package App::SeismicUnixGui::sunix::plot::pscubecontour;

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR: Juan Lorenzo (Perl module only)

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 PSCCONTOUR - PostScript Contour plot of a data CUBE		        



 pscubecontour n1= 

 	n2= 

 	n3= [optional parameters] 

 	<binaryfile >postscriptfile	

 	

    or					

    				

 pscubecontour n1= 

 	n2= 

	 n3= 

	 front= 

	 side= 

	 top= [optional parameters] >postscriptfile



 Data formats supported:						

	1. Entire cube read from stdin (n1*n2*n3 floats) [default format]

	2. Faces read from stdin (n1*n2 floats for front, followed by n1*n3

	   floats for side, and n2*n3 floats for top) [specify faces=1]	

	3. Faces read from separate data files [specify filenames]	



 Required Parameters:							

 n1=                     number of samples in 1st (fastest) dimension	

 n2=                     number of samples in 2nd dimension		

 n3=                     number of samples in 3rd (slowest) dimension	



 Optional Parameters:							

 front=                  name of file containing front panel		

 side=                   name of file containing side panel		

 top=                    name of file containing top panel		

 faces=0                =1 to read faces from stdin (data format 2)	

 d1=1.0                 sampling interval in 1st dimension		

 f1=0.0                 first sample in 1st dimension			

 d2=1.0                 sampling interval in 2nd dimension		

 f2=0.0                 first sample in 2nd dimension			

 d3=1.0                 sampling interval in 3rd dimension		

 f3=0.0                 first sample in 3rd dimension			

 d1s=1.0                factor by which to scale d1 before imaging	

 d2s=1.0                factor by which to scale d2 before imaging	

 d3s=1.0                factor by which to scale d3 before imaging	

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

 size1=4.0              size in inches of 1st axes (vertical)		

 size2=4.0              size in inches of 2nd axes (horizontal)	

 size3=3.0              size in inches of 3rd axes (projected)		

 angle=45               projection angle of cube in degrees (0<angle<90)

                        (angle between 2nd axis and projected 3rd axis)

 x1end=x1max            value at which axis 1 ends			

 d1num=0.0              numbered tic interval on axis 1 (0.0 for automatic)

 f1num=x1min            first numbered tic on axis 1 (used if d1num not 0.0)

 n1tic=1                number of tics per numbered tic on axis 1	

 grid1=none             grid lines on axis 1 - none, dot, dash, or solid

 label1=                label on axis 1				

 x2beg=x2min            value at which axis 2 begins			

 d2num=0.0              numbered tic interval on axis 2 (0.0 for automatic)

 f2num=x2min            first numbered tic on axis 2 (used if d2num not 0.0)

 n2tic=1                number of tics per numbered tic on axis 2	

 grid2=none             grid lines on axis 2 - none, dot, dash, or solid

 label2=                label on axis 2				

 x3end=x3max            value at which axis 3 ends			

 d3num=0.0              numbered tic interval on axis 3 (0.0 for automatic)

 f3num=x3min            first numbered tic on axis 3 (used if d3num not 0.0)

 n3tic=1                number of tics per numbered tic on axis 3	

 grid3=none             grid lines on axis 3 - none, dot, dash, or solid

 label3=                label on axis 3				

 labelfont=Helvetica    font name for axes labels			

 labelsize=18           font size for axes labels			

 title=                 title of plot					

 titlefont=Helvetica-Bold font name for title				

 titlesize=24           font size for title				

 titlecolor=black       color of title					

 labelcfont=Helvetica-Bold font name for contour labels		

 labelcsize=6           font size of contour labels   			

 labelccolor=black      color of contour labels   			

 axescolor=black        color of axes					

 gridcolor=black        color of grid					



 All color specifications may also be made in X Window style Hex format

 example:   axescolor=#255						



 Note: The values of x1beg=x1min, x2end=x2max and x3beg=x3min cannot   

 be changed.								



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







 (Original codes pscontour and pscube)



 Author:  Craig Artley, Colorado School of Mines, 03/12/93

 NOTE:  Original written by Zhiming Li & Dave Hale, CSM, 07/01/90

	  Completely rewritten, the code now bears more similarity to

	  psimage than the previous pscube.  Faces of cube now rendered

	  as three separate images, rather than as a single image.  The

	  output no longer suffers from stretching artifacts, and the

	  code is simpler.  -Craig

 MODIFIED:  Craig Artley, Colorado School of Mines, 12/17/93

 	  Added color options.



 PSCCONTOUR: mashed together from pscube and pscontour 

 to generate 3d contour plots by Claudia Vanelle, Institute of Geophysics,

 University of Hamburg, Germany somewhen in 2000



 PSCUBE was "merged" with PSCONTOUR to create PSCUBECONTOUR 

 by Claudia Vanelle, Applied Geophysics Group Hamburg

 somewhen in 2000



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

my $pscubecontour = {
	_angle       => '',
	_axescolor   => '',
	_c           => '',
	_ccolor      => '',
	_cdash       => '',
	_cgray       => '',
	_cwidth      => '',
	_d1          => '',
	_d1num       => '',
	_d1s         => '',
	_d2          => '',
	_d2num       => '',
	_d2s         => '',
	_d3          => '',
	_d3num       => '',
	_d3s         => '',
	_dc          => '',
	_f1          => '',
	_f1num       => '',
	_f2          => '',
	_f2num       => '',
	_f3          => '',
	_f3num       => '',
	_faces       => '',
	_fc          => '',
	_front       => '',
	_grid1       => '',
	_grid2       => '',
	_grid3       => '',
	_gridcolor   => '',
	_label1      => '',
	_label2      => '',
	_label3      => '',
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
	_n3          => '',
	_n3tic       => '',
	_nc          => '',
	_nlabelc     => '',
	_nplaces     => '',
	_side        => '',
	_size1       => '',
	_size2       => '',
	_size3       => '',
	_title       => '',
	_titlecolor  => '',
	_titlefont   => '',
	_titlesize   => '',
	_top         => '',
	_x1beg       => '',
	_x1end       => '',
	_x2beg       => '',
	_x3end       => '',
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

	$pscubecontour->{_Step} = 'pscubecontour' . $pscubecontour->{_Step};
	return ( $pscubecontour->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$pscubecontour->{_note} = 'pscubecontour' . $pscubecontour->{_note};
	return ( $pscubecontour->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$pscubecontour->{_angle}       = '';
	$pscubecontour->{_axescolor}   = '';
	$pscubecontour->{_c}           = '';
	$pscubecontour->{_ccolor}      = '';
	$pscubecontour->{_cdash}       = '';
	$pscubecontour->{_cgray}       = '';
	$pscubecontour->{_cwidth}      = '';
	$pscubecontour->{_d1}          = '';
	$pscubecontour->{_d1num}       = '';
	$pscubecontour->{_d1s}         = '';
	$pscubecontour->{_d2}          = '';
	$pscubecontour->{_d2num}       = '';
	$pscubecontour->{_d2s}         = '';
	$pscubecontour->{_d3}          = '';
	$pscubecontour->{_d3num}       = '';
	$pscubecontour->{_d3s}         = '';
	$pscubecontour->{_dc}          = '';
	$pscubecontour->{_f1}          = '';
	$pscubecontour->{_f1num}       = '';
	$pscubecontour->{_f2}          = '';
	$pscubecontour->{_f2num}       = '';
	$pscubecontour->{_f3}          = '';
	$pscubecontour->{_f3num}       = '';
	$pscubecontour->{_faces}       = '';
	$pscubecontour->{_fc}          = '';
	$pscubecontour->{_front}       = '';
	$pscubecontour->{_grid1}       = '';
	$pscubecontour->{_grid2}       = '';
	$pscubecontour->{_grid3}       = '';
	$pscubecontour->{_gridcolor}   = '';
	$pscubecontour->{_label1}      = '';
	$pscubecontour->{_label2}      = '';
	$pscubecontour->{_label3}      = '';
	$pscubecontour->{_labelccolor} = '';
	$pscubecontour->{_labelcf}     = '';
	$pscubecontour->{_labelcfont}  = '';
	$pscubecontour->{_labelcper}   = '';
	$pscubecontour->{_labelcsize}  = '';
	$pscubecontour->{_labelfont}   = '';
	$pscubecontour->{_labelsize}   = '';
	$pscubecontour->{_n1}          = '';
	$pscubecontour->{_n1tic}       = '';
	$pscubecontour->{_n2}          = '';
	$pscubecontour->{_n2tic}       = '';
	$pscubecontour->{_n3}          = '';
	$pscubecontour->{_n3tic}       = '';
	$pscubecontour->{_nc}          = '';
	$pscubecontour->{_nlabelc}     = '';
	$pscubecontour->{_nplaces}     = '';
	$pscubecontour->{_side}        = '';
	$pscubecontour->{_size1}       = '';
	$pscubecontour->{_size2}       = '';
	$pscubecontour->{_size3}       = '';
	$pscubecontour->{_title}       = '';
	$pscubecontour->{_titlecolor}  = '';
	$pscubecontour->{_titlefont}   = '';
	$pscubecontour->{_titlesize}   = '';
	$pscubecontour->{_top}         = '';
	$pscubecontour->{_x1beg}       = '';
	$pscubecontour->{_x1end}       = '';
	$pscubecontour->{_x2beg}       = '';
	$pscubecontour->{_x3end}       = '';
	$pscubecontour->{_xbox}        = '';
	$pscubecontour->{_ybox}        = '';
	$pscubecontour->{_Step}        = '';
	$pscubecontour->{_note}        = '';
}

=head2 sub angle 


=cut

sub angle {

	my ( $self, $angle ) = @_;
	if ( $angle ne $empty_string ) {

		$pscubecontour->{_angle} = $angle;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' angle=' . $pscubecontour->{_angle};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' angle=' . $pscubecontour->{_angle};

	}
	else {
		print("pscubecontour, angle, missing angle,\n");
	}
}

=head2 sub axescolor 


=cut

sub axescolor {

	my ( $self, $axescolor ) = @_;
	if ( $axescolor ne $empty_string ) {

		$pscubecontour->{_axescolor} = $axescolor;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' axescolor='
		  . $pscubecontour->{_axescolor};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' axescolor='
		  . $pscubecontour->{_axescolor};

	}
	else {
		print("pscubecontour, axescolor, missing axescolor,\n");
	}
}

=head2 sub c 


=cut

sub c {

	my ( $self, $c ) = @_;
	if ( $c ne $empty_string ) {

		$pscubecontour->{_c} = $c;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' c=' . $pscubecontour->{_c};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' c=' . $pscubecontour->{_c};

	}
	else {
		print("pscubecontour, c, missing c,\n");
	}
}

=head2 sub ccolor 


=cut

sub ccolor {

	my ( $self, $ccolor ) = @_;
	if ( $ccolor ne $empty_string ) {

		$pscubecontour->{_ccolor} = $ccolor;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' ccolor=' . $pscubecontour->{_ccolor};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' ccolor=' . $pscubecontour->{_ccolor};

	}
	else {
		print("pscubecontour, ccolor, missing ccolor,\n");
	}
}

=head2 sub cdash 


=cut

sub cdash {

	my ( $self, $cdash ) = @_;
	if ( $cdash ne $empty_string ) {

		$pscubecontour->{_cdash} = $cdash;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' cdash=' . $pscubecontour->{_cdash};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' cdash=' . $pscubecontour->{_cdash};

	}
	else {
		print("pscubecontour, cdash, missing cdash,\n");
	}
}

=head2 sub cgray 


=cut

sub cgray {

	my ( $self, $cgray ) = @_;
	if ( $cgray ne $empty_string ) {

		$pscubecontour->{_cgray} = $cgray;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' cgray=' . $pscubecontour->{_cgray};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' cgray=' . $pscubecontour->{_cgray};

	}
	else {
		print("pscubecontour, cgray, missing cgray,\n");
	}
}

=head2 sub cwidth 


=cut

sub cwidth {

	my ( $self, $cwidth ) = @_;
	if ( $cwidth ne $empty_string ) {

		$pscubecontour->{_cwidth} = $cwidth;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' cwidth=' . $pscubecontour->{_cwidth};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' cwidth=' . $pscubecontour->{_cwidth};

	}
	else {
		print("pscubecontour, cwidth, missing cwidth,\n");
	}
}

=head2 sub d1 


=cut

sub d1 {

	my ( $self, $d1 ) = @_;
	if ( $d1 ne $empty_string ) {

		$pscubecontour->{_d1} = $d1;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d1=' . $pscubecontour->{_d1};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d1=' . $pscubecontour->{_d1};

	}
	else {
		print("pscubecontour, d1, missing d1,\n");
	}
}

=head2 sub d1num 


=cut

sub d1num {

	my ( $self, $d1num ) = @_;
	if ( $d1num ne $empty_string ) {

		$pscubecontour->{_d1num} = $d1num;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d1num=' . $pscubecontour->{_d1num};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d1num=' . $pscubecontour->{_d1num};

	}
	else {
		print("pscubecontour, d1num, missing d1num,\n");
	}
}

=head2 sub d1s 


=cut

sub d1s {

	my ( $self, $d1s ) = @_;
	if ( $d1s ne $empty_string ) {

		$pscubecontour->{_d1s} = $d1s;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d1s=' . $pscubecontour->{_d1s};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d1s=' . $pscubecontour->{_d1s};

	}
	else {
		print("pscubecontour, d1s, missing d1s,\n");
	}
}

=head2 sub d2 


=cut

sub d2 {

	my ( $self, $d2 ) = @_;
	if ( $d2 ne $empty_string ) {

		$pscubecontour->{_d2} = $d2;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d2=' . $pscubecontour->{_d2};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d2=' . $pscubecontour->{_d2};

	}
	else {
		print("pscubecontour, d2, missing d2,\n");
	}
}

=head2 sub d2num 


=cut

sub d2num {

	my ( $self, $d2num ) = @_;
	if ( $d2num ne $empty_string ) {

		$pscubecontour->{_d2num} = $d2num;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d2num=' . $pscubecontour->{_d2num};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d2num=' . $pscubecontour->{_d2num};

	}
	else {
		print("pscubecontour, d2num, missing d2num,\n");
	}
}

=head2 sub d2s 


=cut

sub d2s {

	my ( $self, $d2s ) = @_;
	if ( $d2s ne $empty_string ) {

		$pscubecontour->{_d2s} = $d2s;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d2s=' . $pscubecontour->{_d2s};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d2s=' . $pscubecontour->{_d2s};

	}
	else {
		print("pscubecontour, d2s, missing d2s,\n");
	}
}

=head2 sub d3 


=cut

sub d3 {

	my ( $self, $d3 ) = @_;
	if ( $d3 ne $empty_string ) {

		$pscubecontour->{_d3} = $d3;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d3=' . $pscubecontour->{_d3};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d3=' . $pscubecontour->{_d3};

	}
	else {
		print("pscubecontour, d3, missing d3,\n");
	}
}

=head2 sub d3num 


=cut

sub d3num {

	my ( $self, $d3num ) = @_;
	if ( $d3num ne $empty_string ) {

		$pscubecontour->{_d3num} = $d3num;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d3num=' . $pscubecontour->{_d3num};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d3num=' . $pscubecontour->{_d3num};

	}
	else {
		print("pscubecontour, d3num, missing d3num,\n");
	}
}

=head2 sub d3s 


=cut

sub d3s {

	my ( $self, $d3s ) = @_;
	if ( $d3s ne $empty_string ) {

		$pscubecontour->{_d3s} = $d3s;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' d3s=' . $pscubecontour->{_d3s};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' d3s=' . $pscubecontour->{_d3s};

	}
	else {
		print("pscubecontour, d3s, missing d3s,\n");
	}
}

=head2 sub dc 


=cut

sub dc {

	my ( $self, $dc ) = @_;
	if ( $dc ne $empty_string ) {

		$pscubecontour->{_dc} = $dc;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' dc=' . $pscubecontour->{_dc};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' dc=' . $pscubecontour->{_dc};

	}
	else {
		print("pscubecontour, dc, missing dc,\n");
	}
}

=head2 sub f1 


=cut

sub f1 {

	my ( $self, $f1 ) = @_;
	if ( $f1 ne $empty_string ) {

		$pscubecontour->{_f1} = $f1;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' f1=' . $pscubecontour->{_f1};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' f1=' . $pscubecontour->{_f1};

	}
	else {
		print("pscubecontour, f1, missing f1,\n");
	}
}

=head2 sub f1num 


=cut

sub f1num {

	my ( $self, $f1num ) = @_;
	if ( $f1num ne $empty_string ) {

		$pscubecontour->{_f1num} = $f1num;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' f1num=' . $pscubecontour->{_f1num};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' f1num=' . $pscubecontour->{_f1num};

	}
	else {
		print("pscubecontour, f1num, missing f1num,\n");
	}
}

=head2 sub f2 


=cut

sub f2 {

	my ( $self, $f2 ) = @_;
	if ( $f2 ne $empty_string ) {

		$pscubecontour->{_f2} = $f2;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' f2=' . $pscubecontour->{_f2};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' f2=' . $pscubecontour->{_f2};

	}
	else {
		print("pscubecontour, f2, missing f2,\n");
	}
}

=head2 sub f2num 


=cut

sub f2num {

	my ( $self, $f2num ) = @_;
	if ( $f2num ne $empty_string ) {

		$pscubecontour->{_f2num} = $f2num;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' f2num=' . $pscubecontour->{_f2num};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' f2num=' . $pscubecontour->{_f2num};

	}
	else {
		print("pscubecontour, f2num, missing f2num,\n");
	}
}

=head2 sub f3 


=cut

sub f3 {

	my ( $self, $f3 ) = @_;
	if ( $f3 ne $empty_string ) {

		$pscubecontour->{_f3} = $f3;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' f3=' . $pscubecontour->{_f3};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' f3=' . $pscubecontour->{_f3};

	}
	else {
		print("pscubecontour, f3, missing f3,\n");
	}
}

=head2 sub f3num 


=cut

sub f3num {

	my ( $self, $f3num ) = @_;
	if ( $f3num ne $empty_string ) {

		$pscubecontour->{_f3num} = $f3num;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' f3num=' . $pscubecontour->{_f3num};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' f3num=' . $pscubecontour->{_f3num};

	}
	else {
		print("pscubecontour, f3num, missing f3num,\n");
	}
}

=head2 sub faces 


=cut

sub faces {

	my ( $self, $faces ) = @_;
	if ( $faces ne $empty_string ) {

		$pscubecontour->{_faces} = $faces;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' faces=' . $pscubecontour->{_faces};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' faces=' . $pscubecontour->{_faces};

	}
	else {
		print("pscubecontour, faces, missing faces,\n");
	}
}

=head2 sub fc 


=cut

sub fc {

	my ( $self, $fc ) = @_;
	if ( $fc ne $empty_string ) {

		$pscubecontour->{_fc} = $fc;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' fc=' . $pscubecontour->{_fc};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' fc=' . $pscubecontour->{_fc};

	}
	else {
		print("pscubecontour, fc, missing fc,\n");
	}
}

=head2 sub front 


=cut

sub front {

	my ( $self, $front ) = @_;
	if ( $front ne $empty_string ) {

		$pscubecontour->{_front} = $front;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' front=' . $pscubecontour->{_front};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' front=' . $pscubecontour->{_front};

	}
	else {
		print("pscubecontour, front, missing front,\n");
	}
}

=head2 sub grid1 


=cut

sub grid1 {

	my ( $self, $grid1 ) = @_;
	if ( $grid1 ne $empty_string ) {

		$pscubecontour->{_grid1} = $grid1;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' grid1=' . $pscubecontour->{_grid1};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' grid1=' . $pscubecontour->{_grid1};

	}
	else {
		print("pscubecontour, grid1, missing grid1,\n");
	}
}

=head2 sub grid2 


=cut

sub grid2 {

	my ( $self, $grid2 ) = @_;
	if ( $grid2 ne $empty_string ) {

		$pscubecontour->{_grid2} = $grid2;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' grid2=' . $pscubecontour->{_grid2};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' grid2=' . $pscubecontour->{_grid2};

	}
	else {
		print("pscubecontour, grid2, missing grid2,\n");
	}
}

=head2 sub grid3 


=cut

sub grid3 {

	my ( $self, $grid3 ) = @_;
	if ( $grid3 ne $empty_string ) {

		$pscubecontour->{_grid3} = $grid3;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' grid3=' . $pscubecontour->{_grid3};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' grid3=' . $pscubecontour->{_grid3};

	}
	else {
		print("pscubecontour, grid3, missing grid3,\n");
	}
}

=head2 sub gridcolor 


=cut

sub gridcolor {

	my ( $self, $gridcolor ) = @_;
	if ( $gridcolor ne $empty_string ) {

		$pscubecontour->{_gridcolor} = $gridcolor;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' gridcolor='
		  . $pscubecontour->{_gridcolor};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' gridcolor='
		  . $pscubecontour->{_gridcolor};

	}
	else {
		print("pscubecontour, gridcolor, missing gridcolor,\n");
	}
}

=head2 sub label1 


=cut

sub label1 {

	my ( $self, $label1 ) = @_;
	if ( $label1 ne $empty_string ) {

		$pscubecontour->{_label1} = $label1;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' label1=' . $pscubecontour->{_label1};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' label1=' . $pscubecontour->{_label1};

	}
	else {
		print("pscubecontour, label1, missing label1,\n");
	}
}

=head2 sub label2 


=cut

sub label2 {

	my ( $self, $label2 ) = @_;
	if ( $label2 ne $empty_string ) {

		$pscubecontour->{_label2} = $label2;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' label2=' . $pscubecontour->{_label2};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' label2=' . $pscubecontour->{_label2};

	}
	else {
		print("pscubecontour, label2, missing label2,\n");
	}
}

=head2 sub label3 


=cut

sub label3 {

	my ( $self, $label3 ) = @_;
	if ( $label3 ne $empty_string ) {

		$pscubecontour->{_label3} = $label3;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' label3=' . $pscubecontour->{_label3};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' label3=' . $pscubecontour->{_label3};

	}
	else {
		print("pscubecontour, label3, missing label3,\n");
	}
}

=head2 sub labelccolor 


=cut

sub labelccolor {

	my ( $self, $labelccolor ) = @_;
	if ( $labelccolor ne $empty_string ) {

		$pscubecontour->{_labelccolor} = $labelccolor;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' labelccolor='
		  . $pscubecontour->{_labelccolor};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' labelccolor='
		  . $pscubecontour->{_labelccolor};

	}
	else {
		print("pscubecontour, labelccolor, missing labelccolor,\n");
	}
}

=head2 sub labelcf 


=cut

sub labelcf {

	my ( $self, $labelcf ) = @_;
	if ( $labelcf ne $empty_string ) {

		$pscubecontour->{_labelcf} = $labelcf;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' labelcf=' . $pscubecontour->{_labelcf};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' labelcf=' . $pscubecontour->{_labelcf};

	}
	else {
		print("pscubecontour, labelcf, missing labelcf,\n");
	}
}

=head2 sub labelcfont 


=cut

sub labelcfont {

	my ( $self, $labelcfont ) = @_;
	if ( $labelcfont ne $empty_string ) {

		$pscubecontour->{_labelcfont} = $labelcfont;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' labelcfont='
		  . $pscubecontour->{_labelcfont};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' labelcfont='
		  . $pscubecontour->{_labelcfont};

	}
	else {
		print("pscubecontour, labelcfont, missing labelcfont,\n");
	}
}

=head2 sub labelcper 


=cut

sub labelcper {

	my ( $self, $labelcper ) = @_;
	if ( $labelcper ne $empty_string ) {

		$pscubecontour->{_labelcper} = $labelcper;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' labelcper='
		  . $pscubecontour->{_labelcper};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' labelcper='
		  . $pscubecontour->{_labelcper};

	}
	else {
		print("pscubecontour, labelcper, missing labelcper,\n");
	}
}

=head2 sub labelcsize 


=cut

sub labelcsize {

	my ( $self, $labelcsize ) = @_;
	if ( $labelcsize ne $empty_string ) {

		$pscubecontour->{_labelcsize} = $labelcsize;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' labelcsize='
		  . $pscubecontour->{_labelcsize};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' labelcsize='
		  . $pscubecontour->{_labelcsize};

	}
	else {
		print("pscubecontour, labelcsize, missing labelcsize,\n");
	}
}

=head2 sub labelfont 


=cut

sub labelfont {

	my ( $self, $labelfont ) = @_;
	if ( $labelfont ne $empty_string ) {

		$pscubecontour->{_labelfont} = $labelfont;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' labelfont='
		  . $pscubecontour->{_labelfont};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' labelfont='
		  . $pscubecontour->{_labelfont};

	}
	else {
		print("pscubecontour, labelfont, missing labelfont,\n");
	}
}

=head2 sub labelsize 


=cut

sub labelsize {

	my ( $self, $labelsize ) = @_;
	if ( $labelsize ne $empty_string ) {

		$pscubecontour->{_labelsize} = $labelsize;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' labelsize='
		  . $pscubecontour->{_labelsize};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' labelsize='
		  . $pscubecontour->{_labelsize};

	}
	else {
		print("pscubecontour, labelsize, missing labelsize,\n");
	}
}

=head2 sub n1 


=cut

sub n1 {

	my ( $self, $n1 ) = @_;
	if ( $n1 ne $empty_string ) {

		$pscubecontour->{_n1} = $n1;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' n1=' . $pscubecontour->{_n1};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' n1=' . $pscubecontour->{_n1};

	}
	else {
		print("pscubecontour, n1, missing n1,\n");
	}
}

=head2 sub n1tic 


=cut

sub n1tic {

	my ( $self, $n1tic ) = @_;
	if ( $n1tic ne $empty_string ) {

		$pscubecontour->{_n1tic} = $n1tic;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' n1tic=' . $pscubecontour->{_n1tic};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' n1tic=' . $pscubecontour->{_n1tic};

	}
	else {
		print("pscubecontour, n1tic, missing n1tic,\n");
	}
}

=head2 sub n2 


=cut

sub n2 {

	my ( $self, $n2 ) = @_;
	if ( $n2 ne $empty_string ) {

		$pscubecontour->{_n2} = $n2;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' n2=' . $pscubecontour->{_n2};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' n2=' . $pscubecontour->{_n2};

	}
	else {
		print("pscubecontour, n2, missing n2,\n");
	}
}

=head2 sub n2tic 


=cut

sub n2tic {

	my ( $self, $n2tic ) = @_;
	if ( $n2tic ne $empty_string ) {

		$pscubecontour->{_n2tic} = $n2tic;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' n2tic=' . $pscubecontour->{_n2tic};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' n2tic=' . $pscubecontour->{_n2tic};

	}
	else {
		print("pscubecontour, n2tic, missing n2tic,\n");
	}
}

=head2 sub n3 


=cut

sub n3 {

	my ( $self, $n3 ) = @_;
	if ( $n3 ne $empty_string ) {

		$pscubecontour->{_n3} = $n3;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' n3=' . $pscubecontour->{_n3};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' n3=' . $pscubecontour->{_n3};

	}
	else {
		print("pscubecontour, n3, missing n3,\n");
	}
}

=head2 sub n3tic 


=cut

sub n3tic {

	my ( $self, $n3tic ) = @_;
	if ( $n3tic ne $empty_string ) {

		$pscubecontour->{_n3tic} = $n3tic;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' n3tic=' . $pscubecontour->{_n3tic};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' n3tic=' . $pscubecontour->{_n3tic};

	}
	else {
		print("pscubecontour, n3tic, missing n3tic,\n");
	}
}

=head2 sub nc 


=cut

sub nc {

	my ( $self, $nc ) = @_;
	if ( $nc ne $empty_string ) {

		$pscubecontour->{_nc} = $nc;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' nc=' . $pscubecontour->{_nc};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' nc=' . $pscubecontour->{_nc};

	}
	else {
		print("pscubecontour, nc, missing nc,\n");
	}
}

=head2 sub nlabelc 


=cut

sub nlabelc {

	my ( $self, $nlabelc ) = @_;
	if ( $nlabelc ne $empty_string ) {

		$pscubecontour->{_nlabelc} = $nlabelc;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' nlabelc=' . $pscubecontour->{_nlabelc};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' nlabelc=' . $pscubecontour->{_nlabelc};

	}
	else {
		print("pscubecontour, nlabelc, missing nlabelc,\n");
	}
}

=head2 sub nplaces 


=cut

sub nplaces {

	my ( $self, $nplaces ) = @_;
	if ( $nplaces ne $empty_string ) {

		$pscubecontour->{_nplaces} = $nplaces;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' nplaces=' . $pscubecontour->{_nplaces};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' nplaces=' . $pscubecontour->{_nplaces};

	}
	else {
		print("pscubecontour, nplaces, missing nplaces,\n");
	}
}

=head2 sub side 


=cut

sub side {

	my ( $self, $side ) = @_;
	if ( $side ne $empty_string ) {

		$pscubecontour->{_side} = $side;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' side=' . $pscubecontour->{_side};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' side=' . $pscubecontour->{_side};

	}
	else {
		print("pscubecontour, side, missing side,\n");
	}
}

=head2 sub size1 


=cut

sub size1 {

	my ( $self, $size1 ) = @_;
	if ( $size1 ne $empty_string ) {

		$pscubecontour->{_size1} = $size1;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' size1=' . $pscubecontour->{_size1};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' size1=' . $pscubecontour->{_size1};

	}
	else {
		print("pscubecontour, size1, missing size1,\n");
	}
}

=head2 sub size2 


=cut

sub size2 {

	my ( $self, $size2 ) = @_;
	if ( $size2 ne $empty_string ) {

		$pscubecontour->{_size2} = $size2;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' size2=' . $pscubecontour->{_size2};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' size2=' . $pscubecontour->{_size2};

	}
	else {
		print("pscubecontour, size2, missing size2,\n");
	}
}

=head2 sub size3 


=cut

sub size3 {

	my ( $self, $size3 ) = @_;
	if ( $size3 ne $empty_string ) {

		$pscubecontour->{_size3} = $size3;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' size3=' . $pscubecontour->{_size3};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' size3=' . $pscubecontour->{_size3};

	}
	else {
		print("pscubecontour, size3, missing size3,\n");
	}
}

=head2 sub title 


=cut

sub title {

	my ( $self, $title ) = @_;
	if ( $title ne $empty_string ) {

		$pscubecontour->{_title} = $title;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' title=' . $pscubecontour->{_title};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' title=' . $pscubecontour->{_title};

	}
	else {
		print("pscubecontour, title, missing title,\n");
	}
}

=head2 sub titlecolor 


=cut

sub titlecolor {

	my ( $self, $titlecolor ) = @_;
	if ( $titlecolor ne $empty_string ) {

		$pscubecontour->{_titlecolor} = $titlecolor;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' titlecolor='
		  . $pscubecontour->{_titlecolor};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' titlecolor='
		  . $pscubecontour->{_titlecolor};

	}
	else {
		print("pscubecontour, titlecolor, missing titlecolor,\n");
	}
}

=head2 sub titlefont 


=cut

sub titlefont {

	my ( $self, $titlefont ) = @_;
	if ( $titlefont ne $empty_string ) {

		$pscubecontour->{_titlefont} = $titlefont;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' titlefont='
		  . $pscubecontour->{_titlefont};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' titlefont='
		  . $pscubecontour->{_titlefont};

	}
	else {
		print("pscubecontour, titlefont, missing titlefont,\n");
	}
}

=head2 sub titlesize 


=cut

sub titlesize {

	my ( $self, $titlesize ) = @_;
	if ( $titlesize ne $empty_string ) {

		$pscubecontour->{_titlesize} = $titlesize;
		$pscubecontour->{_note} =
			$pscubecontour->{_note}
		  . ' titlesize='
		  . $pscubecontour->{_titlesize};
		$pscubecontour->{_Step} =
			$pscubecontour->{_Step}
		  . ' titlesize='
		  . $pscubecontour->{_titlesize};

	}
	else {
		print("pscubecontour, titlesize, missing titlesize,\n");
	}
}

=head2 sub top 


=cut

sub top {

	my ( $self, $top ) = @_;
	if ( $top ne $empty_string ) {

		$pscubecontour->{_top} = $top;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' top=' . $pscubecontour->{_top};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' top=' . $pscubecontour->{_top};

	}
	else {
		print("pscubecontour, top, missing top,\n");
	}
}

=head2 sub x1beg 


=cut

sub x1beg {

	my ( $self, $x1beg ) = @_;
	if ( $x1beg ne $empty_string ) {

		$pscubecontour->{_x1beg} = $x1beg;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' x1beg=' . $pscubecontour->{_x1beg};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' x1beg=' . $pscubecontour->{_x1beg};

	}
	else {
		print("pscubecontour, x1beg, missing x1beg,\n");
	}
}

=head2 sub x1end 


=cut

sub x1end {

	my ( $self, $x1end ) = @_;
	if ( $x1end ne $empty_string ) {

		$pscubecontour->{_x1end} = $x1end;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' x1end=' . $pscubecontour->{_x1end};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' x1end=' . $pscubecontour->{_x1end};

	}
	else {
		print("pscubecontour, x1end, missing x1end,\n");
	}
}

=head2 sub x2beg 


=cut

sub x2beg {

	my ( $self, $x2beg ) = @_;
	if ( $x2beg ne $empty_string ) {

		$pscubecontour->{_x2beg} = $x2beg;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' x2beg=' . $pscubecontour->{_x2beg};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' x2beg=' . $pscubecontour->{_x2beg};

	}
	else {
		print("pscubecontour, x2beg, missing x2beg,\n");
	}
}

=head2 sub x3end 


=cut

sub x3end {

	my ( $self, $x3end ) = @_;
	if ( $x3end ne $empty_string ) {

		$pscubecontour->{_x3end} = $x3end;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' x3end=' . $pscubecontour->{_x3end};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' x3end=' . $pscubecontour->{_x3end};

	}
	else {
		print("pscubecontour, x3end, missing x3end,\n");
	}
}

=head2 sub xbox 


=cut

sub xbox {

	my ( $self, $xbox ) = @_;
	if ( $xbox ne $empty_string ) {

		$pscubecontour->{_xbox} = $xbox;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' xbox=' . $pscubecontour->{_xbox};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' xbox=' . $pscubecontour->{_xbox};

	}
	else {
		print("pscubecontour, xbox, missing xbox,\n");
	}
}

=head2 sub ybox 


=cut

sub ybox {

	my ( $self, $ybox ) = @_;
	if ( $ybox ne $empty_string ) {

		$pscubecontour->{_ybox} = $ybox;
		$pscubecontour->{_note} =
		  $pscubecontour->{_note} . ' ybox=' . $pscubecontour->{_ybox};
		$pscubecontour->{_Step} =
		  $pscubecontour->{_Step} . ' ybox=' . $pscubecontour->{_ybox};

	}
	else {
		print("pscubecontour, ybox, missing ybox,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 63;

	return ($max_index);
}

1;
