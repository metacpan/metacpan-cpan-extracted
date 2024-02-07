package App::SeismicUnixGui::sunix::plot::pscube;

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
 PSCUBE - PostScript image plot with Legend of a data CUBE       



 pscube n1= 

	 n2= 

	 n3= [optional parameters] <binaryfile >postscriptfile

	 

 

 	or

    									

 pscube n1= 

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

 perc=100.0             percentile used to determine clip		

 clip=(perc percentile) clip used to determine bclip and wclip		

 bperc=perc             percentile for determining black clip value	

 wperc=100.0-perc       percentile for determining white clip value	

 bclip=clip             data values outside of [bclip,wclip] are clipped

 wclip=-clip            data values outside of [bclip,wclip] are clipped

 brgb=0.0,0.0,0.0       red, green, blue values corresponding to black	

 wrgb=1.0,1.0,1.0       red, green, blue values corresponding to white	

 bhls=0.0,0.0,0.0       hue, lightness, saturation corresponding to black

 whls=0.0,1.0,0.0       hue, lightness, saturation corresponding to white

 bps=12                 bits per sample for color plots, either 12 or 24

 d1s=1.0                factor by which to scale d1 before imaging	

 d2s=1.0                factor by which to scale d2 before imaging	

 d3s=1.0                factor by which to scale d3 before imaging	

 verbose=1              =1 for info printed on stderr (0 for no info)	

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

 axescolor=black        color of axes					

 gridcolor=black        color of grid					

 legend=0               =1 display the color scale                     

                        if equals 1, resize xbox,ybox,width,height          

 lstyle=vertleft       Vertical, axis label on left side               

                        =vertright (Vertical, axis label on right side)

                        =horibottom (Horizontal, axis label on bottom) 

 units=                 unit label for legend                          

 legendfont=times_roman10    font name for title                       

 following are defaults for lstyle=0. They are changed for other lstyles

 lwidth=1.2             colorscale (legend) width in inches            

 lheight=height/3       colorscale (legend) height in inches           

 lx=1.0                 colorscale (legend) x-position in inches       

 ly=(height-lheight)/2+xybox    colorscale (legend) y-position in pixels

 lbeg= lmin or wclip-5*perc    value at which legend axis begins       

 lend= lmax or bclip+5*perc    value at which legend axis ends         

 ldnum=0.0      numbered tic interval on legend axis (0.0 for automatic)

 lfnum=lmin     first numbered tic on legend axis (used if d1num not 0.0)

 lntic=1        number of tics per numbered tic on legend axis 

 lgrid=none     grid lines on legend axis - none, dot, dash, or solid



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

 Note: The values of x1beg=x1min, x2end=x2max and x3beg=x3min cannot   

 be changed.								



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

my $pscube			= {
	_angle					=> '',
	_axescolor					=> '',
	_bclip					=> '',
	_bhls					=> '',
	_bperc					=> '',
	_bps					=> '',
	_brgb					=> '',
	_clip					=> '',
	_d1					=> '',
	_d1num					=> '',
	_d1s					=> '',
	_d2					=> '',
	_d2num					=> '',
	_d2s					=> '',
	_d3					=> '',
	_d3num					=> '',
	_d3s					=> '',
	_f1					=> '',
	_f1num					=> '',
	_f2					=> '',
	_f2num					=> '',
	_f3					=> '',
	_f3num					=> '',
	_faces					=> '',
	_front					=> '',
	_grid1					=> '',
	_grid2					=> '',
	_grid3					=> '',
	_gridcolor					=> '',
	_label1					=> '',
	_label2					=> '',
	_label3					=> '',
	_labelfont					=> '',
	_labelsize					=> '',
	_lbeg					=> '',
	_ldnum					=> '',
	_legend					=> '',
	_legendfont					=> '',
	_lend					=> '',
	_lfnum					=> '',
	_lgrid					=> '',
	_lheight					=> '',
	_lntic					=> '',
	_lstyle					=> '',
	_lwidth					=> '',
	_lx					=> '',
	_ly					=> '',
	_n1					=> '',
	_n1tic					=> '',
	_n2					=> '',
	_n2tic					=> '',
	_n3					=> '',
	_n3tic					=> '',
	_perc					=> '',
	_side					=> '',
	_size1					=> '',
	_size2					=> '',
	_size3					=> '',
	_title					=> '',
	_titlecolor					=> '',
	_titlefont					=> '',
	_titlesize					=> '',
	_top					=> '',
	_units					=> '',
	_verbose					=> '',
	_wclip					=> '',
	_whls					=> '',
	_wperc					=> '',
	_wrgb					=> '',
	_x1beg					=> '',
	_x1end					=> '',
	_x2beg					=> '',
	_x3end					=> '',
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

	$pscube->{_Step}     = 'pscube'.$pscube->{_Step};
	return ( $pscube->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$pscube->{_note}     = 'pscube'.$pscube->{_note};
	return ( $pscube->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$pscube->{_angle}			= '';
		$pscube->{_axescolor}			= '';
		$pscube->{_bclip}			= '';
		$pscube->{_bhls}			= '';
		$pscube->{_bperc}			= '';
		$pscube->{_bps}			= '';
		$pscube->{_brgb}			= '';
		$pscube->{_clip}			= '';
		$pscube->{_d1}			= '';
		$pscube->{_d1num}			= '';
		$pscube->{_d1s}			= '';
		$pscube->{_d2}			= '';
		$pscube->{_d2num}			= '';
		$pscube->{_d2s}			= '';
		$pscube->{_d3}			= '';
		$pscube->{_d3num}			= '';
		$pscube->{_d3s}			= '';
		$pscube->{_f1}			= '';
		$pscube->{_f1num}			= '';
		$pscube->{_f2}			= '';
		$pscube->{_f2num}			= '';
		$pscube->{_f3}			= '';
		$pscube->{_f3num}			= '';
		$pscube->{_faces}			= '';
		$pscube->{_front}			= '';
		$pscube->{_grid1}			= '';
		$pscube->{_grid2}			= '';
		$pscube->{_grid3}			= '';
		$pscube->{_gridcolor}			= '';
		$pscube->{_label1}			= '';
		$pscube->{_label2}			= '';
		$pscube->{_label3}			= '';
		$pscube->{_labelfont}			= '';
		$pscube->{_labelsize}			= '';
		$pscube->{_lbeg}			= '';
		$pscube->{_ldnum}			= '';
		$pscube->{_legend}			= '';
		$pscube->{_legendfont}			= '';
		$pscube->{_lend}			= '';
		$pscube->{_lfnum}			= '';
		$pscube->{_lgrid}			= '';
		$pscube->{_lheight}			= '';
		$pscube->{_lntic}			= '';
		$pscube->{_lstyle}			= '';
		$pscube->{_lwidth}			= '';
		$pscube->{_lx}			= '';
		$pscube->{_ly}			= '';
		$pscube->{_n1}			= '';
		$pscube->{_n1tic}			= '';
		$pscube->{_n2}			= '';
		$pscube->{_n2tic}			= '';
		$pscube->{_n3}			= '';
		$pscube->{_n3tic}			= '';
		$pscube->{_perc}			= '';
		$pscube->{_side}			= '';
		$pscube->{_size1}			= '';
		$pscube->{_size2}			= '';
		$pscube->{_size3}			= '';
		$pscube->{_title}			= '';
		$pscube->{_titlecolor}			= '';
		$pscube->{_titlefont}			= '';
		$pscube->{_titlesize}			= '';
		$pscube->{_top}			= '';
		$pscube->{_units}			= '';
		$pscube->{_verbose}			= '';
		$pscube->{_wclip}			= '';
		$pscube->{_whls}			= '';
		$pscube->{_wperc}			= '';
		$pscube->{_wrgb}			= '';
		$pscube->{_x1beg}			= '';
		$pscube->{_x1end}			= '';
		$pscube->{_x2beg}			= '';
		$pscube->{_x3end}			= '';
		$pscube->{_xbox}			= '';
		$pscube->{_ybox}			= '';
		$pscube->{_Step}			= '';
		$pscube->{_note}			= '';
 }


=head2 sub angle 


=cut

 sub angle {

	my ( $self,$angle )		= @_;
	if ( $angle ne $empty_string ) {

		$pscube->{_angle}		= $angle;
		$pscube->{_note}		= $pscube->{_note}.' angle='.$pscube->{_angle};
		$pscube->{_Step}		= $pscube->{_Step}.' angle='.$pscube->{_angle};

	} else { 
		print("pscube, angle, missing angle,\n");
	 }
 }


=head2 sub axescolor 


=cut

 sub axescolor {

	my ( $self,$axescolor )		= @_;
	if ( $axescolor ne $empty_string ) {

		$pscube->{_axescolor}		= $axescolor;
		$pscube->{_note}		= $pscube->{_note}.' axescolor='.$pscube->{_axescolor};
		$pscube->{_Step}		= $pscube->{_Step}.' axescolor='.$pscube->{_axescolor};

	} else { 
		print("pscube, axescolor, missing axescolor,\n");
	 }
 }


=head2 sub bclip 


=cut

 sub bclip {

	my ( $self,$bclip )		= @_;
	if ( $bclip ne $empty_string ) {

		$pscube->{_bclip}		= $bclip;
		$pscube->{_note}		= $pscube->{_note}.' bclip='.$pscube->{_bclip};
		$pscube->{_Step}		= $pscube->{_Step}.' bclip='.$pscube->{_bclip};

	} else { 
		print("pscube, bclip, missing bclip,\n");
	 }
 }


=head2 sub bhls 


=cut

 sub bhls {

	my ( $self,$bhls )		= @_;
	if ( $bhls ne $empty_string ) {

		$pscube->{_bhls}		= $bhls;
		$pscube->{_note}		= $pscube->{_note}.' bhls='.$pscube->{_bhls};
		$pscube->{_Step}		= $pscube->{_Step}.' bhls='.$pscube->{_bhls};

	} else { 
		print("pscube, bhls, missing bhls,\n");
	 }
 }


=head2 sub bperc 


=cut

 sub bperc {

	my ( $self,$bperc )		= @_;
	if ( $bperc ne $empty_string ) {

		$pscube->{_bperc}		= $bperc;
		$pscube->{_note}		= $pscube->{_note}.' bperc='.$pscube->{_bperc};
		$pscube->{_Step}		= $pscube->{_Step}.' bperc='.$pscube->{_bperc};

	} else { 
		print("pscube, bperc, missing bperc,\n");
	 }
 }


=head2 sub bps 


=cut

 sub bps {

	my ( $self,$bps )		= @_;
	if ( $bps ne $empty_string ) {

		$pscube->{_bps}		= $bps;
		$pscube->{_note}		= $pscube->{_note}.' bps='.$pscube->{_bps};
		$pscube->{_Step}		= $pscube->{_Step}.' bps='.$pscube->{_bps};

	} else { 
		print("pscube, bps, missing bps,\n");
	 }
 }


=head2 sub brgb 


=cut

 sub brgb {

	my ( $self,$brgb )		= @_;
	if ( $brgb ne $empty_string ) {

		$pscube->{_brgb}		= $brgb;
		$pscube->{_note}		= $pscube->{_note}.' brgb='.$pscube->{_brgb};
		$pscube->{_Step}		= $pscube->{_Step}.' brgb='.$pscube->{_brgb};

	} else { 
		print("pscube, brgb, missing brgb,\n");
	 }
 }


=head2 sub clip 


=cut

 sub clip {

	my ( $self,$clip )		= @_;
	if ( $clip ne $empty_string ) {

		$pscube->{_clip}		= $clip;
		$pscube->{_note}		= $pscube->{_note}.' clip='.$pscube->{_clip};
		$pscube->{_Step}		= $pscube->{_Step}.' clip='.$pscube->{_clip};

	} else { 
		print("pscube, clip, missing clip,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$pscube->{_d1}		= $d1;
		$pscube->{_note}		= $pscube->{_note}.' d1='.$pscube->{_d1};
		$pscube->{_Step}		= $pscube->{_Step}.' d1='.$pscube->{_d1};

	} else { 
		print("pscube, d1, missing d1,\n");
	 }
 }


=head2 sub d1num 


=cut

 sub d1num {

	my ( $self,$d1num )		= @_;
	if ( $d1num ne $empty_string ) {

		$pscube->{_d1num}		= $d1num;
		$pscube->{_note}		= $pscube->{_note}.' d1num='.$pscube->{_d1num};
		$pscube->{_Step}		= $pscube->{_Step}.' d1num='.$pscube->{_d1num};

	} else { 
		print("pscube, d1num, missing d1num,\n");
	 }
 }


=head2 sub d1s 


=cut

 sub d1s {

	my ( $self,$d1s )		= @_;
	if ( $d1s ne $empty_string ) {

		$pscube->{_d1s}		= $d1s;
		$pscube->{_note}		= $pscube->{_note}.' d1s='.$pscube->{_d1s};
		$pscube->{_Step}		= $pscube->{_Step}.' d1s='.$pscube->{_d1s};

	} else { 
		print("pscube, d1s, missing d1s,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$pscube->{_d2}		= $d2;
		$pscube->{_note}		= $pscube->{_note}.' d2='.$pscube->{_d2};
		$pscube->{_Step}		= $pscube->{_Step}.' d2='.$pscube->{_d2};

	} else { 
		print("pscube, d2, missing d2,\n");
	 }
 }


=head2 sub d2num 


=cut

 sub d2num {

	my ( $self,$d2num )		= @_;
	if ( $d2num ne $empty_string ) {

		$pscube->{_d2num}		= $d2num;
		$pscube->{_note}		= $pscube->{_note}.' d2num='.$pscube->{_d2num};
		$pscube->{_Step}		= $pscube->{_Step}.' d2num='.$pscube->{_d2num};

	} else { 
		print("pscube, d2num, missing d2num,\n");
	 }
 }


=head2 sub d2s 


=cut

 sub d2s {

	my ( $self,$d2s )		= @_;
	if ( $d2s ne $empty_string ) {

		$pscube->{_d2s}		= $d2s;
		$pscube->{_note}		= $pscube->{_note}.' d2s='.$pscube->{_d2s};
		$pscube->{_Step}		= $pscube->{_Step}.' d2s='.$pscube->{_d2s};

	} else { 
		print("pscube, d2s, missing d2s,\n");
	 }
 }


=head2 sub d3 


=cut

 sub d3 {

	my ( $self,$d3 )		= @_;
	if ( $d3 ne $empty_string ) {

		$pscube->{_d3}		= $d3;
		$pscube->{_note}		= $pscube->{_note}.' d3='.$pscube->{_d3};
		$pscube->{_Step}		= $pscube->{_Step}.' d3='.$pscube->{_d3};

	} else { 
		print("pscube, d3, missing d3,\n");
	 }
 }


=head2 sub d3num 


=cut

 sub d3num {

	my ( $self,$d3num )		= @_;
	if ( $d3num ne $empty_string ) {

		$pscube->{_d3num}		= $d3num;
		$pscube->{_note}		= $pscube->{_note}.' d3num='.$pscube->{_d3num};
		$pscube->{_Step}		= $pscube->{_Step}.' d3num='.$pscube->{_d3num};

	} else { 
		print("pscube, d3num, missing d3num,\n");
	 }
 }


=head2 sub d3s 


=cut

 sub d3s {

	my ( $self,$d3s )		= @_;
	if ( $d3s ne $empty_string ) {

		$pscube->{_d3s}		= $d3s;
		$pscube->{_note}		= $pscube->{_note}.' d3s='.$pscube->{_d3s};
		$pscube->{_Step}		= $pscube->{_Step}.' d3s='.$pscube->{_d3s};

	} else { 
		print("pscube, d3s, missing d3s,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$pscube->{_f1}		= $f1;
		$pscube->{_note}		= $pscube->{_note}.' f1='.$pscube->{_f1};
		$pscube->{_Step}		= $pscube->{_Step}.' f1='.$pscube->{_f1};

	} else { 
		print("pscube, f1, missing f1,\n");
	 }
 }


=head2 sub f1num 


=cut

 sub f1num {

	my ( $self,$f1num )		= @_;
	if ( $f1num ne $empty_string ) {

		$pscube->{_f1num}		= $f1num;
		$pscube->{_note}		= $pscube->{_note}.' f1num='.$pscube->{_f1num};
		$pscube->{_Step}		= $pscube->{_Step}.' f1num='.$pscube->{_f1num};

	} else { 
		print("pscube, f1num, missing f1num,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$pscube->{_f2}		= $f2;
		$pscube->{_note}		= $pscube->{_note}.' f2='.$pscube->{_f2};
		$pscube->{_Step}		= $pscube->{_Step}.' f2='.$pscube->{_f2};

	} else { 
		print("pscube, f2, missing f2,\n");
	 }
 }


=head2 sub f2num 


=cut

 sub f2num {

	my ( $self,$f2num )		= @_;
	if ( $f2num ne $empty_string ) {

		$pscube->{_f2num}		= $f2num;
		$pscube->{_note}		= $pscube->{_note}.' f2num='.$pscube->{_f2num};
		$pscube->{_Step}		= $pscube->{_Step}.' f2num='.$pscube->{_f2num};

	} else { 
		print("pscube, f2num, missing f2num,\n");
	 }
 }


=head2 sub f3 


=cut

 sub f3 {

	my ( $self,$f3 )		= @_;
	if ( $f3 ne $empty_string ) {

		$pscube->{_f3}		= $f3;
		$pscube->{_note}		= $pscube->{_note}.' f3='.$pscube->{_f3};
		$pscube->{_Step}		= $pscube->{_Step}.' f3='.$pscube->{_f3};

	} else { 
		print("pscube, f3, missing f3,\n");
	 }
 }


=head2 sub f3num 


=cut

 sub f3num {

	my ( $self,$f3num )		= @_;
	if ( $f3num ne $empty_string ) {

		$pscube->{_f3num}		= $f3num;
		$pscube->{_note}		= $pscube->{_note}.' f3num='.$pscube->{_f3num};
		$pscube->{_Step}		= $pscube->{_Step}.' f3num='.$pscube->{_f3num};

	} else { 
		print("pscube, f3num, missing f3num,\n");
	 }
 }


=head2 sub faces 


=cut

 sub faces {

	my ( $self,$faces )		= @_;
	if ( $faces ne $empty_string ) {

		$pscube->{_faces}		= $faces;
		$pscube->{_note}		= $pscube->{_note}.' faces='.$pscube->{_faces};
		$pscube->{_Step}		= $pscube->{_Step}.' faces='.$pscube->{_faces};

	} else { 
		print("pscube, faces, missing faces,\n");
	 }
 }


=head2 sub front 


=cut

 sub front {

	my ( $self,$front )		= @_;
	if ( $front ne $empty_string ) {

		$pscube->{_front}		= $front;
		$pscube->{_note}		= $pscube->{_note}.' front='.$pscube->{_front};
		$pscube->{_Step}		= $pscube->{_Step}.' front='.$pscube->{_front};

	} else { 
		print("pscube, front, missing front,\n");
	 }
 }


=head2 sub grid1 


=cut

 sub grid1 {

	my ( $self,$grid1 )		= @_;
	if ( $grid1 ne $empty_string ) {

		$pscube->{_grid1}		= $grid1;
		$pscube->{_note}		= $pscube->{_note}.' grid1='.$pscube->{_grid1};
		$pscube->{_Step}		= $pscube->{_Step}.' grid1='.$pscube->{_grid1};

	} else { 
		print("pscube, grid1, missing grid1,\n");
	 }
 }


=head2 sub grid2 


=cut

 sub grid2 {

	my ( $self,$grid2 )		= @_;
	if ( $grid2 ne $empty_string ) {

		$pscube->{_grid2}		= $grid2;
		$pscube->{_note}		= $pscube->{_note}.' grid2='.$pscube->{_grid2};
		$pscube->{_Step}		= $pscube->{_Step}.' grid2='.$pscube->{_grid2};

	} else { 
		print("pscube, grid2, missing grid2,\n");
	 }
 }


=head2 sub grid3 


=cut

 sub grid3 {

	my ( $self,$grid3 )		= @_;
	if ( $grid3 ne $empty_string ) {

		$pscube->{_grid3}		= $grid3;
		$pscube->{_note}		= $pscube->{_note}.' grid3='.$pscube->{_grid3};
		$pscube->{_Step}		= $pscube->{_Step}.' grid3='.$pscube->{_grid3};

	} else { 
		print("pscube, grid3, missing grid3,\n");
	 }
 }


=head2 sub gridcolor 


=cut

 sub gridcolor {

	my ( $self,$gridcolor )		= @_;
	if ( $gridcolor ne $empty_string ) {

		$pscube->{_gridcolor}		= $gridcolor;
		$pscube->{_note}		= $pscube->{_note}.' gridcolor='.$pscube->{_gridcolor};
		$pscube->{_Step}		= $pscube->{_Step}.' gridcolor='.$pscube->{_gridcolor};

	} else { 
		print("pscube, gridcolor, missing gridcolor,\n");
	 }
 }


=head2 sub label1 


=cut

 sub label1 {

	my ( $self,$label1 )		= @_;
	if ( $label1 ne $empty_string ) {

		$pscube->{_label1}		= $label1;
		$pscube->{_note}		= $pscube->{_note}.' label1='.$pscube->{_label1};
		$pscube->{_Step}		= $pscube->{_Step}.' label1='.$pscube->{_label1};

	} else { 
		print("pscube, label1, missing label1,\n");
	 }
 }


=head2 sub label2 


=cut

 sub label2 {

	my ( $self,$label2 )		= @_;
	if ( $label2 ne $empty_string ) {

		$pscube->{_label2}		= $label2;
		$pscube->{_note}		= $pscube->{_note}.' label2='.$pscube->{_label2};
		$pscube->{_Step}		= $pscube->{_Step}.' label2='.$pscube->{_label2};

	} else { 
		print("pscube, label2, missing label2,\n");
	 }
 }


=head2 sub label3 


=cut

 sub label3 {

	my ( $self,$label3 )		= @_;
	if ( $label3 ne $empty_string ) {

		$pscube->{_label3}		= $label3;
		$pscube->{_note}		= $pscube->{_note}.' label3='.$pscube->{_label3};
		$pscube->{_Step}		= $pscube->{_Step}.' label3='.$pscube->{_label3};

	} else { 
		print("pscube, label3, missing label3,\n");
	 }
 }


=head2 sub labelfont 


=cut

 sub labelfont {

	my ( $self,$labelfont )		= @_;
	if ( $labelfont ne $empty_string ) {

		$pscube->{_labelfont}		= $labelfont;
		$pscube->{_note}		= $pscube->{_note}.' labelfont='.$pscube->{_labelfont};
		$pscube->{_Step}		= $pscube->{_Step}.' labelfont='.$pscube->{_labelfont};

	} else { 
		print("pscube, labelfont, missing labelfont,\n");
	 }
 }


=head2 sub labelsize 


=cut

 sub labelsize {

	my ( $self,$labelsize )		= @_;
	if ( $labelsize ne $empty_string ) {

		$pscube->{_labelsize}		= $labelsize;
		$pscube->{_note}		= $pscube->{_note}.' labelsize='.$pscube->{_labelsize};
		$pscube->{_Step}		= $pscube->{_Step}.' labelsize='.$pscube->{_labelsize};

	} else { 
		print("pscube, labelsize, missing labelsize,\n");
	 }
 }


=head2 sub lbeg 


=cut

 sub lbeg {

	my ( $self,$lbeg )		= @_;
	if ( $lbeg ne $empty_string ) {

		$pscube->{_lbeg}		= $lbeg;
		$pscube->{_note}		= $pscube->{_note}.' lbeg='.$pscube->{_lbeg};
		$pscube->{_Step}		= $pscube->{_Step}.' lbeg='.$pscube->{_lbeg};

	} else { 
		print("pscube, lbeg, missing lbeg,\n");
	 }
 }


=head2 sub ldnum 


=cut

 sub ldnum {

	my ( $self,$ldnum )		= @_;
	if ( $ldnum ne $empty_string ) {

		$pscube->{_ldnum}		= $ldnum;
		$pscube->{_note}		= $pscube->{_note}.' ldnum='.$pscube->{_ldnum};
		$pscube->{_Step}		= $pscube->{_Step}.' ldnum='.$pscube->{_ldnum};

	} else { 
		print("pscube, ldnum, missing ldnum,\n");
	 }
 }


=head2 sub legend 


=cut

 sub legend {

	my ( $self,$legend )		= @_;
	if ( $legend ne $empty_string ) {

		$pscube->{_legend}		= $legend;
		$pscube->{_note}		= $pscube->{_note}.' legend='.$pscube->{_legend};
		$pscube->{_Step}		= $pscube->{_Step}.' legend='.$pscube->{_legend};

	} else { 
		print("pscube, legend, missing legend,\n");
	 }
 }


=head2 sub legendfont 


=cut

 sub legendfont {

	my ( $self,$legendfont )		= @_;
	if ( $legendfont ne $empty_string ) {

		$pscube->{_legendfont}		= $legendfont;
		$pscube->{_note}		= $pscube->{_note}.' legendfont='.$pscube->{_legendfont};
		$pscube->{_Step}		= $pscube->{_Step}.' legendfont='.$pscube->{_legendfont};

	} else { 
		print("pscube, legendfont, missing legendfont,\n");
	 }
 }


=head2 sub lend 


=cut

 sub lend {

	my ( $self,$lend )		= @_;
	if ( $lend ne $empty_string ) {

		$pscube->{_lend}		= $lend;
		$pscube->{_note}		= $pscube->{_note}.' lend='.$pscube->{_lend};
		$pscube->{_Step}		= $pscube->{_Step}.' lend='.$pscube->{_lend};

	} else { 
		print("pscube, lend, missing lend,\n");
	 }
 }


=head2 sub lfnum 


=cut

 sub lfnum {

	my ( $self,$lfnum )		= @_;
	if ( $lfnum ne $empty_string ) {

		$pscube->{_lfnum}		= $lfnum;
		$pscube->{_note}		= $pscube->{_note}.' lfnum='.$pscube->{_lfnum};
		$pscube->{_Step}		= $pscube->{_Step}.' lfnum='.$pscube->{_lfnum};

	} else { 
		print("pscube, lfnum, missing lfnum,\n");
	 }
 }


=head2 sub lgrid 


=cut

 sub lgrid {

	my ( $self,$lgrid )		= @_;
	if ( $lgrid ne $empty_string ) {

		$pscube->{_lgrid}		= $lgrid;
		$pscube->{_note}		= $pscube->{_note}.' lgrid='.$pscube->{_lgrid};
		$pscube->{_Step}		= $pscube->{_Step}.' lgrid='.$pscube->{_lgrid};

	} else { 
		print("pscube, lgrid, missing lgrid,\n");
	 }
 }


=head2 sub lheight 


=cut

 sub lheight {

	my ( $self,$lheight )		= @_;
	if ( $lheight ne $empty_string ) {

		$pscube->{_lheight}		= $lheight;
		$pscube->{_note}		= $pscube->{_note}.' lheight='.$pscube->{_lheight};
		$pscube->{_Step}		= $pscube->{_Step}.' lheight='.$pscube->{_lheight};

	} else { 
		print("pscube, lheight, missing lheight,\n");
	 }
 }


=head2 sub lntic 


=cut

 sub lntic {

	my ( $self,$lntic )		= @_;
	if ( $lntic ne $empty_string ) {

		$pscube->{_lntic}		= $lntic;
		$pscube->{_note}		= $pscube->{_note}.' lntic='.$pscube->{_lntic};
		$pscube->{_Step}		= $pscube->{_Step}.' lntic='.$pscube->{_lntic};

	} else { 
		print("pscube, lntic, missing lntic,\n");
	 }
 }


=head2 sub lstyle 


=cut

 sub lstyle {

	my ( $self,$lstyle )		= @_;
	if ( $lstyle ne $empty_string ) {

		$pscube->{_lstyle}		= $lstyle;
		$pscube->{_note}		= $pscube->{_note}.' lstyle='.$pscube->{_lstyle};
		$pscube->{_Step}		= $pscube->{_Step}.' lstyle='.$pscube->{_lstyle};

	} else { 
		print("pscube, lstyle, missing lstyle,\n");
	 }
 }


=head2 sub lwidth 


=cut

 sub lwidth {

	my ( $self,$lwidth )		= @_;
	if ( $lwidth ne $empty_string ) {

		$pscube->{_lwidth}		= $lwidth;
		$pscube->{_note}		= $pscube->{_note}.' lwidth='.$pscube->{_lwidth};
		$pscube->{_Step}		= $pscube->{_Step}.' lwidth='.$pscube->{_lwidth};

	} else { 
		print("pscube, lwidth, missing lwidth,\n");
	 }
 }


=head2 sub lx 


=cut

 sub lx {

	my ( $self,$lx )		= @_;
	if ( $lx ne $empty_string ) {

		$pscube->{_lx}		= $lx;
		$pscube->{_note}		= $pscube->{_note}.' lx='.$pscube->{_lx};
		$pscube->{_Step}		= $pscube->{_Step}.' lx='.$pscube->{_lx};

	} else { 
		print("pscube, lx, missing lx,\n");
	 }
 }


=head2 sub ly 


=cut

 sub ly {

	my ( $self,$ly )		= @_;
	if ( $ly ne $empty_string ) {

		$pscube->{_ly}		= $ly;
		$pscube->{_note}		= $pscube->{_note}.' ly='.$pscube->{_ly};
		$pscube->{_Step}		= $pscube->{_Step}.' ly='.$pscube->{_ly};

	} else { 
		print("pscube, ly, missing ly,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$pscube->{_n1}		= $n1;
		$pscube->{_note}		= $pscube->{_note}.' n1='.$pscube->{_n1};
		$pscube->{_Step}		= $pscube->{_Step}.' n1='.$pscube->{_n1};

	} else { 
		print("pscube, n1, missing n1,\n");
	 }
 }


=head2 sub n1tic 


=cut

 sub n1tic {

	my ( $self,$n1tic )		= @_;
	if ( $n1tic ne $empty_string ) {

		$pscube->{_n1tic}		= $n1tic;
		$pscube->{_note}		= $pscube->{_note}.' n1tic='.$pscube->{_n1tic};
		$pscube->{_Step}		= $pscube->{_Step}.' n1tic='.$pscube->{_n1tic};

	} else { 
		print("pscube, n1tic, missing n1tic,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$pscube->{_n2}		= $n2;
		$pscube->{_note}		= $pscube->{_note}.' n2='.$pscube->{_n2};
		$pscube->{_Step}		= $pscube->{_Step}.' n2='.$pscube->{_n2};

	} else { 
		print("pscube, n2, missing n2,\n");
	 }
 }


=head2 sub n2tic 


=cut

 sub n2tic {

	my ( $self,$n2tic )		= @_;
	if ( $n2tic ne $empty_string ) {

		$pscube->{_n2tic}		= $n2tic;
		$pscube->{_note}		= $pscube->{_note}.' n2tic='.$pscube->{_n2tic};
		$pscube->{_Step}		= $pscube->{_Step}.' n2tic='.$pscube->{_n2tic};

	} else { 
		print("pscube, n2tic, missing n2tic,\n");
	 }
 }


=head2 sub n3 


=cut

 sub n3 {

	my ( $self,$n3 )		= @_;
	if ( $n3 ne $empty_string ) {

		$pscube->{_n3}		= $n3;
		$pscube->{_note}		= $pscube->{_note}.' n3='.$pscube->{_n3};
		$pscube->{_Step}		= $pscube->{_Step}.' n3='.$pscube->{_n3};

	} else { 
		print("pscube, n3, missing n3,\n");
	 }
 }


=head2 sub n3tic 


=cut

 sub n3tic {

	my ( $self,$n3tic )		= @_;
	if ( $n3tic ne $empty_string ) {

		$pscube->{_n3tic}		= $n3tic;
		$pscube->{_note}		= $pscube->{_note}.' n3tic='.$pscube->{_n3tic};
		$pscube->{_Step}		= $pscube->{_Step}.' n3tic='.$pscube->{_n3tic};

	} else { 
		print("pscube, n3tic, missing n3tic,\n");
	 }
 }


=head2 sub perc 


=cut

 sub perc {

	my ( $self,$perc )		= @_;
	if ( $perc ne $empty_string ) {

		$pscube->{_perc}		= $perc;
		$pscube->{_note}		= $pscube->{_note}.' perc='.$pscube->{_perc};
		$pscube->{_Step}		= $pscube->{_Step}.' perc='.$pscube->{_perc};

	} else { 
		print("pscube, perc, missing perc,\n");
	 }
 }


=head2 sub side 


=cut

 sub side {

	my ( $self,$side )		= @_;
	if ( $side ne $empty_string ) {

		$pscube->{_side}		= $side;
		$pscube->{_note}		= $pscube->{_note}.' side='.$pscube->{_side};
		$pscube->{_Step}		= $pscube->{_Step}.' side='.$pscube->{_side};

	} else { 
		print("pscube, side, missing side,\n");
	 }
 }


=head2 sub size1 


=cut

 sub size1 {

	my ( $self,$size1 )		= @_;
	if ( $size1 ne $empty_string ) {

		$pscube->{_size1}		= $size1;
		$pscube->{_note}		= $pscube->{_note}.' size1='.$pscube->{_size1};
		$pscube->{_Step}		= $pscube->{_Step}.' size1='.$pscube->{_size1};

	} else { 
		print("pscube, size1, missing size1,\n");
	 }
 }


=head2 sub size2 


=cut

 sub size2 {

	my ( $self,$size2 )		= @_;
	if ( $size2 ne $empty_string ) {

		$pscube->{_size2}		= $size2;
		$pscube->{_note}		= $pscube->{_note}.' size2='.$pscube->{_size2};
		$pscube->{_Step}		= $pscube->{_Step}.' size2='.$pscube->{_size2};

	} else { 
		print("pscube, size2, missing size2,\n");
	 }
 }


=head2 sub size3 


=cut

 sub size3 {

	my ( $self,$size3 )		= @_;
	if ( $size3 ne $empty_string ) {

		$pscube->{_size3}		= $size3;
		$pscube->{_note}		= $pscube->{_note}.' size3='.$pscube->{_size3};
		$pscube->{_Step}		= $pscube->{_Step}.' size3='.$pscube->{_size3};

	} else { 
		print("pscube, size3, missing size3,\n");
	 }
 }


=head2 sub title 


=cut

 sub title {

	my ( $self,$title )		= @_;
	if ( $title ne $empty_string ) {

		$pscube->{_title}		= $title;
		$pscube->{_note}		= $pscube->{_note}.' title='.$pscube->{_title};
		$pscube->{_Step}		= $pscube->{_Step}.' title='.$pscube->{_title};

	} else { 
		print("pscube, title, missing title,\n");
	 }
 }


=head2 sub titlecolor 


=cut

 sub titlecolor {

	my ( $self,$titlecolor )		= @_;
	if ( $titlecolor ne $empty_string ) {

		$pscube->{_titlecolor}		= $titlecolor;
		$pscube->{_note}		= $pscube->{_note}.' titlecolor='.$pscube->{_titlecolor};
		$pscube->{_Step}		= $pscube->{_Step}.' titlecolor='.$pscube->{_titlecolor};

	} else { 
		print("pscube, titlecolor, missing titlecolor,\n");
	 }
 }


=head2 sub titlefont 


=cut

 sub titlefont {

	my ( $self,$titlefont )		= @_;
	if ( $titlefont ne $empty_string ) {

		$pscube->{_titlefont}		= $titlefont;
		$pscube->{_note}		= $pscube->{_note}.' titlefont='.$pscube->{_titlefont};
		$pscube->{_Step}		= $pscube->{_Step}.' titlefont='.$pscube->{_titlefont};

	} else { 
		print("pscube, titlefont, missing titlefont,\n");
	 }
 }


=head2 sub titlesize 


=cut

 sub titlesize {

	my ( $self,$titlesize )		= @_;
	if ( $titlesize ne $empty_string ) {

		$pscube->{_titlesize}		= $titlesize;
		$pscube->{_note}		= $pscube->{_note}.' titlesize='.$pscube->{_titlesize};
		$pscube->{_Step}		= $pscube->{_Step}.' titlesize='.$pscube->{_titlesize};

	} else { 
		print("pscube, titlesize, missing titlesize,\n");
	 }
 }


=head2 sub top 


=cut

 sub top {

	my ( $self,$top )		= @_;
	if ( $top ne $empty_string ) {

		$pscube->{_top}		= $top;
		$pscube->{_note}		= $pscube->{_note}.' top='.$pscube->{_top};
		$pscube->{_Step}		= $pscube->{_Step}.' top='.$pscube->{_top};

	} else { 
		print("pscube, top, missing top,\n");
	 }
 }


=head2 sub units 


=cut

 sub units {

	my ( $self,$units )		= @_;
	if ( $units ne $empty_string ) {

		$pscube->{_units}		= $units;
		$pscube->{_note}		= $pscube->{_note}.' units='.$pscube->{_units};
		$pscube->{_Step}		= $pscube->{_Step}.' units='.$pscube->{_units};

	} else { 
		print("pscube, units, missing units,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$pscube->{_verbose}		= $verbose;
		$pscube->{_note}		= $pscube->{_note}.' verbose='.$pscube->{_verbose};
		$pscube->{_Step}		= $pscube->{_Step}.' verbose='.$pscube->{_verbose};

	} else { 
		print("pscube, verbose, missing verbose,\n");
	 }
 }


=head2 sub wclip 


=cut

 sub wclip {

	my ( $self,$wclip )		= @_;
	if ( $wclip ne $empty_string ) {

		$pscube->{_wclip}		= $wclip;
		$pscube->{_note}		= $pscube->{_note}.' wclip='.$pscube->{_wclip};
		$pscube->{_Step}		= $pscube->{_Step}.' wclip='.$pscube->{_wclip};

	} else { 
		print("pscube, wclip, missing wclip,\n");
	 }
 }


=head2 sub whls 


=cut

 sub whls {

	my ( $self,$whls )		= @_;
	if ( $whls ne $empty_string ) {

		$pscube->{_whls}		= $whls;
		$pscube->{_note}		= $pscube->{_note}.' whls='.$pscube->{_whls};
		$pscube->{_Step}		= $pscube->{_Step}.' whls='.$pscube->{_whls};

	} else { 
		print("pscube, whls, missing whls,\n");
	 }
 }


=head2 sub wperc 


=cut

 sub wperc {

	my ( $self,$wperc )		= @_;
	if ( $wperc ne $empty_string ) {

		$pscube->{_wperc}		= $wperc;
		$pscube->{_note}		= $pscube->{_note}.' wperc='.$pscube->{_wperc};
		$pscube->{_Step}		= $pscube->{_Step}.' wperc='.$pscube->{_wperc};

	} else { 
		print("pscube, wperc, missing wperc,\n");
	 }
 }


=head2 sub wrgb 


=cut

 sub wrgb {

	my ( $self,$wrgb )		= @_;
	if ( $wrgb ne $empty_string ) {

		$pscube->{_wrgb}		= $wrgb;
		$pscube->{_note}		= $pscube->{_note}.' wrgb='.$pscube->{_wrgb};
		$pscube->{_Step}		= $pscube->{_Step}.' wrgb='.$pscube->{_wrgb};

	} else { 
		print("pscube, wrgb, missing wrgb,\n");
	 }
 }


=head2 sub x1beg 


=cut

 sub x1beg {

	my ( $self,$x1beg )		= @_;
	if ( $x1beg ne $empty_string ) {

		$pscube->{_x1beg}		= $x1beg;
		$pscube->{_note}		= $pscube->{_note}.' x1beg='.$pscube->{_x1beg};
		$pscube->{_Step}		= $pscube->{_Step}.' x1beg='.$pscube->{_x1beg};

	} else { 
		print("pscube, x1beg, missing x1beg,\n");
	 }
 }


=head2 sub x1end 


=cut

 sub x1end {

	my ( $self,$x1end )		= @_;
	if ( $x1end ne $empty_string ) {

		$pscube->{_x1end}		= $x1end;
		$pscube->{_note}		= $pscube->{_note}.' x1end='.$pscube->{_x1end};
		$pscube->{_Step}		= $pscube->{_Step}.' x1end='.$pscube->{_x1end};

	} else { 
		print("pscube, x1end, missing x1end,\n");
	 }
 }


=head2 sub x2beg 


=cut

 sub x2beg {

	my ( $self,$x2beg )		= @_;
	if ( $x2beg ne $empty_string ) {

		$pscube->{_x2beg}		= $x2beg;
		$pscube->{_note}		= $pscube->{_note}.' x2beg='.$pscube->{_x2beg};
		$pscube->{_Step}		= $pscube->{_Step}.' x2beg='.$pscube->{_x2beg};

	} else { 
		print("pscube, x2beg, missing x2beg,\n");
	 }
 }


=head2 sub x3end 


=cut

 sub x3end {

	my ( $self,$x3end )		= @_;
	if ( $x3end ne $empty_string ) {

		$pscube->{_x3end}		= $x3end;
		$pscube->{_note}		= $pscube->{_note}.' x3end='.$pscube->{_x3end};
		$pscube->{_Step}		= $pscube->{_Step}.' x3end='.$pscube->{_x3end};

	} else { 
		print("pscube, x3end, missing x3end,\n");
	 }
 }


=head2 sub xbox 


=cut

 sub xbox {

	my ( $self,$xbox )		= @_;
	if ( $xbox ne $empty_string ) {

		$pscube->{_xbox}		= $xbox;
		$pscube->{_note}		= $pscube->{_note}.' xbox='.$pscube->{_xbox};
		$pscube->{_Step}		= $pscube->{_Step}.' xbox='.$pscube->{_xbox};

	} else { 
		print("pscube, xbox, missing xbox,\n");
	 }
 }


=head2 sub ybox 


=cut

 sub ybox {

	my ( $self,$ybox )		= @_;
	if ( $ybox ne $empty_string ) {

		$pscube->{_ybox}		= $ybox;
		$pscube->{_note}		= $pscube->{_note}.' ybox='.$pscube->{_ybox};
		$pscube->{_Step}		= $pscube->{_Step}.' ybox='.$pscube->{_ybox};

	} else { 
		print("pscube, ybox, missing ybox,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 74;

    return($max_index);
}
 
 
1;
