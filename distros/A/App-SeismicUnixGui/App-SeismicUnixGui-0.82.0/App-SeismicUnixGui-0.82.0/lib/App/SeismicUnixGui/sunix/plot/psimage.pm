package App::SeismicUnixGui::sunix::plot::psimage;

=head2 SYNOPSIS

PACKAGE NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES
 PSIMAGE - PostScript IMAGE plot of a uniformly-sampled function f(x1,x2)

            with the option to display a second attribute		



 psimage n1= [optional parameters] <binaryfile >postscriptfile	



 Required Parameters:							

 n1			 number of samples in 1st (fast) dimension	



 Optional Parameters:							

 d1=1.0		 sampling interval in 1st dimension		

 f1=0.0		 first sample in 1st dimension			

 n2=all		 number of samples in 2nd (slow) dimension	

 d2=1.0		 sampling interval in 2nd dimension		

 f2=0.0		 first sample in 2nd dimension			

 perc=100.0		 percentile used to determine clip		

 clip=(perc percentile) clip used to determine bclip and wclip		

 bperc=perc		 percentile for determining black clip value	

 wperc=100.0-perc	 percentile for determining white clip value	

 bclip=clip		 data values outside of [bclip,wclip] are clipped

 wclip=-clip		 data values outside of [bclip,wclip] are clipped

                        bclip and wclip will be set to be inside       

                        [lbeg,lend] if lbeg and/or lend are supplied   

 threecolor=1		 supply 3 color values instead of only two,	

                        using not only black and white, but f.e. red,	

                        green and blue					

 brgb=0.0,0.0,0.0	 red, green, blue values corresponding to black	

 grgb=1.0,1.0,1.0	 red, green, blue values corresponding to grey	

 wrgb=1.0,1.0,1.0	 red, green, blue values corresponding to white	

 bhls=0.0,0.0,0.0	 hue, lightness, saturation corresponding to black

 ghls=0.0,1.0,0.0	 hue, lightness, saturation corresponding to grey

 whls=0.0,1.0,0.0	 hue, lightness, saturation corresponding to white

 bps=12		 bits per sample for color plots, either 12 or 24

 d1s=1.0		 factor by which to scale d1 before imaging	

 d2s=1.0		 factor by which to scale d2 before imaging	

 verbose=1		 =1 for info printed on stderr (0 for no info)	

 xbox=1.5		 offset in inches of left side of axes box	

 ybox=1.5		 offset in inches of bottom side of axes box	

 width=6.0		 width in inches of axes box			

 height=8.0		 height in inches of axes box			

 x1beg=x1min		 value at which axis 1 begins			

 x1end=x1max		 value at which axis 1 ends			

 d1num=0.0		 numbered tic interval on axis 1 (0.0 for automatic)

 f1num=x1min		 first numbered tic on axis 1 (used if d1num not 0.0)

 n1tic=1		 number of tics per numbered tic on axis 1	

 grid1=none		 grid lines on axis 1 - none, dot, dash, or solid

 label1=		 label on axis 1				

 x2beg=x2min		 value at which axis 2 begins			

 x2end=x2max		 value at which axis 2 ends			

 d2num=0.0		 numbered tic interval on axis 2 (0.0 for automatic)

 f2num=x2min		 first numbered tic on axis 2 (used if d2num not 0.0)

 n2tic=1		 number of tics per numbered tic on axis 2	

 grid2=none		 grid lines on axis 2 - none, dot, dash, or solid

 label2=		 label on axis 2				

 labelfont=Helvetica	 font name for axes labels			

 labelsize=18		 font size for axes labels			

 title=		 title of plot					

 titlefont=Helvetica-Bold font name for title				

 titlesize=24		  font size for title				

 titlecolor=black	 color of title					

 axescolor=black	 color of axes					

 gridcolor=black	 color of grid					

 axeswidth=1            width (in points) of axes                      

 ticwidth=axeswidth     width (in points) of tic marks			

 gridwidth=axeswidth    width (in points) of grid lines		

 style=seismic		 normal (axis 1 horizontal, axis 2 vertical) or	

			 seismic (axis 1 vertical, axis 2 horizontal)	

 legend=0	         =1 display the color scale			

 lnice=0                =1 nice legend arrangement                     

                        (overrides ybox,lx,width,height parameters)    

 lstyle=vertleft 	Vertical, axis label on left side   		

			 =vertright (Vertical, axis label on right side)

			 =horibottom (Horizontal, axis label on bottom)	

 units=		 unit label for legend				

 legendfont=times_roman10    font name for title			

 following are defaults for lstyle=0. They are changed for other lstyles

 lwidth=1.2		 colorscale (legend) width in inches 		

 lheight=height/3     	 colorscale (legend) height in inches		

 lx=1.0		 colorscale (legend) x-position in inches	

 ly=(height-lheight)/2+xybox    colorscale (legend) y-position in pixels

 lbeg= lmin or wclip-5*perc    value at which legend axis begins	

 lend= lmax or bclip+5*perc    value at which legend axis ends        	

 ldnum=0.0	 numbered tic interval on legend axis (0.0 for automatic)

 lfnum=lmin	 first numbered tic on legend axis (used if d1num not 0.0)

 lntic=1	 number of tics per numbered tic on legend axis 

 lgrid=none	 grid lines on legend axis - none, dot, dash, or solid



 curve=curve1,curve2,...  file(s) containing points to draw curve(s)   

 npair=n1,n2,n2,...            number(s) of pairs in each file         

 curvecolor=black,..	 color of curve(s)				

 curvewidth=axeswidth	 width (in points) of curve(s)			

 curvedash=0            solid curve(s), dash indices 1,...,11 produce  

                        curve(s) with various dash styles              



 infile=none            filename of second attribute n1xn2 array       

                        values must be from range 0.0 - 1.0            

                        (plain unformatted C-style file)               

 bckgr=0.5              background gray value				



 NOTES:								

 The curve file is an ascii file with the points specified as x1 x2 	

 pairs, one pair to a line.  A "vector" of curve files and curve	

 colors may be specified as curvefile=file1,file2,etc.			

 and curvecolor=color1,color2,etc, and the number of pairs of values   

 in each file as npair=npair1,npair2,... .				



 You may eliminate the blocky appearance of psimages by adjusting the  

 d1s= and d2s= parameters, so that psimages appear similar to ximages.	



 All color specifications may also be made in X Window style Hex format

 example:   axescolor=#255						



 Some example colormap settings:					

 red white blue: wrgb=1.0,0,0 grgb=1.0,1.0,1.0 brgb=0,0,1.0 		

 white red blue: wrgb=1.0,1.0,1.0 grgb=1.0,0.0,0.0 brgb=0,0,1.0 	

 blue red white: wrgb=0.0,0.0,1.0 grgb=1.0,0.0,0.0 brgb=1.0,1.0,1.0 	

 red green blue: wrgb=1.0,0,0 grgb=0,1.0,0 brgb=0,0,1.0		

 orange light-blue green: wrgb=1.0,.5,0 grgb=0,.7,1.0 brgb=0,1.0,0	

 red light-blue dark blue: wrgb=0.0,0,1.0 grgb=0,1.0,1.0 brgb=0,0,1.0 	



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







 AUTHOR:  Dave Hale, Colorado School of Mines, 05/29/90

 MODIFIED:  Craig Artley, Colorado School of Mines, 08/30/91

	    BoundingBox moved to top of PostScript output

 MODIFIED:  Craig Artley, Colorado School of Mines, 12/16/93

	    Added color options (Courtesy of Dave Hale, Advance Geophysical).

 Modified: Morten Wendell Pedersen, Aarhus University, 23/3-97

           Added ticwidth,axeswidth, gridwidth parameters 

 MODIFIED: Torsten Schoenfelder, Koeln, Germany 006/07/97

          colorbar (legend) (as in ximage (by Berend Scheffers, Delft))

 MODIFIED: Brian K. Macy, Phillips Petroleum, 01/14/99

	    Added curve plotting option

 MODIFIED: Torsten Schoenfelder, Koeln, Germany 02/10/99

          color scale with interpolation of three colors

 MODIFIED: Ekkehart Tessmer, University of Hamburg, Germany, 08/22/2007

          Added dashing option to curve plotting



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

my $psimage			= {
	_axescolor					=> '',
	_axeswidth					=> '',
	_bckgr					=> '',
	_bclip					=> '',
	_bhls					=> '',
	_bperc					=> '',
	_bps					=> '',
	_brgb					=> '',
	_clip					=> '',
	_curve					=> '',
	_curvecolor					=> '',
	_curvedash					=> '',
	_curvefile					=> '',
	_curvewidth					=> '',
	_d1					=> '',
	_d1num					=> '',
	_d1s					=> '',
	_d2					=> '',
	_d2num					=> '',
	_d2s					=> '',
	_f1					=> '',
	_f1num					=> '',
	_f2					=> '',
	_f2num					=> '',
	_ghls					=> '',
	_grgb					=> '',
	_grid1					=> '',
	_grid2					=> '',
	_gridcolor					=> '',
	_gridwidth					=> '',
	_height					=> '',
	_infile					=> '',
	_label1					=> '',
	_label2					=> '',
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
	_lnice					=> '',
	_lntic					=> '',
	_lstyle					=> '',
	_lwidth					=> '',
	_lx					=> '',
	_ly					=> '',
	_n1					=> '',
	_n1tic					=> '',
	_n2					=> '',
	_n2tic					=> '',
	_npair					=> '',
	_perc					=> '',
	_style					=> '',
	_threecolor					=> '',
	_ticwidth					=> '',
	_title					=> '',
	_titlecolor					=> '',
	_titlefont					=> '',
	_titlesize					=> '',
	_units					=> '',
	_verbose					=> '',
	_wclip					=> '',
	_whls					=> '',
	_width					=> '',
	_wperc					=> '',
	_wrgb					=> '',
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

	$psimage->{_Step}     = 'psimage'.$psimage->{_Step};
	return ( $psimage->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$psimage->{_note}     = 'psimage'.$psimage->{_note};
	return ( $psimage->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$psimage->{_axescolor}			= '';
		$psimage->{_axeswidth}			= '';
		$psimage->{_bckgr}			= '';
		$psimage->{_bclip}			= '';
		$psimage->{_bhls}			= '';
		$psimage->{_bperc}			= '';
		$psimage->{_bps}			= '';
		$psimage->{_brgb}			= '';
		$psimage->{_clip}			= '';
		$psimage->{_curve}			= '';
		$psimage->{_curvecolor}			= '';
		$psimage->{_curvedash}			= '';
		$psimage->{_curvefile}			= '';
		$psimage->{_curvewidth}			= '';
		$psimage->{_d1}			= '';
		$psimage->{_d1num}			= '';
		$psimage->{_d1s}			= '';
		$psimage->{_d2}			= '';
		$psimage->{_d2num}			= '';
		$psimage->{_d2s}			= '';
		$psimage->{_f1}			= '';
		$psimage->{_f1num}			= '';
		$psimage->{_f2}			= '';
		$psimage->{_f2num}			= '';
		$psimage->{_ghls}			= '';
		$psimage->{_grgb}			= '';
		$psimage->{_grid1}			= '';
		$psimage->{_grid2}			= '';
		$psimage->{_gridcolor}			= '';
		$psimage->{_gridwidth}			= '';
		$psimage->{_height}			= '';
		$psimage->{_infile}			= '';
		$psimage->{_label1}			= '';
		$psimage->{_label2}			= '';
		$psimage->{_labelfont}			= '';
		$psimage->{_labelsize}			= '';
		$psimage->{_lbeg}			= '';
		$psimage->{_ldnum}			= '';
		$psimage->{_legend}			= '';
		$psimage->{_legendfont}			= '';
		$psimage->{_lend}			= '';
		$psimage->{_lfnum}			= '';
		$psimage->{_lgrid}			= '';
		$psimage->{_lheight}			= '';
		$psimage->{_lnice}			= '';
		$psimage->{_lntic}			= '';
		$psimage->{_lstyle}			= '';
		$psimage->{_lwidth}			= '';
		$psimage->{_lx}			= '';
		$psimage->{_ly}			= '';
		$psimage->{_n1}			= '';
		$psimage->{_n1tic}			= '';
		$psimage->{_n2}			= '';
		$psimage->{_n2tic}			= '';
		$psimage->{_npair}			= '';
		$psimage->{_perc}			= '';
		$psimage->{_style}			= '';
		$psimage->{_threecolor}			= '';
		$psimage->{_ticwidth}			= '';
		$psimage->{_title}			= '';
		$psimage->{_titlecolor}			= '';
		$psimage->{_titlefont}			= '';
		$psimage->{_titlesize}			= '';
		$psimage->{_units}			= '';
		$psimage->{_verbose}			= '';
		$psimage->{_wclip}			= '';
		$psimage->{_whls}			= '';
		$psimage->{_width}			= '';
		$psimage->{_wperc}			= '';
		$psimage->{_wrgb}			= '';
		$psimage->{_x1beg}			= '';
		$psimage->{_x1end}			= '';
		$psimage->{_x2beg}			= '';
		$psimage->{_x2end}			= '';
		$psimage->{_xbox}			= '';
		$psimage->{_ybox}			= '';
		$psimage->{_Step}			= '';
		$psimage->{_note}			= '';
 }


=head2 sub axescolor 


=cut

 sub axescolor {

	my ( $self,$axescolor )		= @_;
	if ( $axescolor ne $empty_string ) {

		$psimage->{_axescolor}		= $axescolor;
		$psimage->{_note}		= $psimage->{_note}.' axescolor='.$psimage->{_axescolor};
		$psimage->{_Step}		= $psimage->{_Step}.' axescolor='.$psimage->{_axescolor};

	} else { 
		print("psimage, axescolor, missing axescolor,\n");
	 }
 }


=head2 sub axeswidth 


=cut

 sub axeswidth {

	my ( $self,$axeswidth )		= @_;
	if ( $axeswidth ne $empty_string ) {

		$psimage->{_axeswidth}		= $axeswidth;
		$psimage->{_note}		= $psimage->{_note}.' axeswidth='.$psimage->{_axeswidth};
		$psimage->{_Step}		= $psimage->{_Step}.' axeswidth='.$psimage->{_axeswidth};

	} else { 
		print("psimage, axeswidth, missing axeswidth,\n");
	 }
 }


=head2 sub bckgr 


=cut

 sub bckgr {

	my ( $self,$bckgr )		= @_;
	if ( $bckgr ne $empty_string ) {

		$psimage->{_bckgr}		= $bckgr;
		$psimage->{_note}		= $psimage->{_note}.' bckgr='.$psimage->{_bckgr};
		$psimage->{_Step}		= $psimage->{_Step}.' bckgr='.$psimage->{_bckgr};

	} else { 
		print("psimage, bckgr, missing bckgr,\n");
	 }
 }


=head2 sub bclip 


=cut

 sub bclip {

	my ( $self,$bclip )		= @_;
	if ( $bclip ne $empty_string ) {

		$psimage->{_bclip}		= $bclip;
		$psimage->{_note}		= $psimage->{_note}.' bclip='.$psimage->{_bclip};
		$psimage->{_Step}		= $psimage->{_Step}.' bclip='.$psimage->{_bclip};

	} else { 
		print("psimage, bclip, missing bclip,\n");
	 }
 }


=head2 sub bhls 


=cut

 sub bhls {

	my ( $self,$bhls )		= @_;
	if ( $bhls ne $empty_string ) {

		$psimage->{_bhls}		= $bhls;
		$psimage->{_note}		= $psimage->{_note}.' bhls='.$psimage->{_bhls};
		$psimage->{_Step}		= $psimage->{_Step}.' bhls='.$psimage->{_bhls};

	} else { 
		print("psimage, bhls, missing bhls,\n");
	 }
 }


=head2 sub bperc 


=cut

 sub bperc {

	my ( $self,$bperc )		= @_;
	if ( $bperc ne $empty_string ) {

		$psimage->{_bperc}		= $bperc;
		$psimage->{_note}		= $psimage->{_note}.' bperc='.$psimage->{_bperc};
		$psimage->{_Step}		= $psimage->{_Step}.' bperc='.$psimage->{_bperc};

	} else { 
		print("psimage, bperc, missing bperc,\n");
	 }
 }


=head2 sub bps 


=cut

 sub bps {

	my ( $self,$bps )		= @_;
	if ( $bps ne $empty_string ) {

		$psimage->{_bps}		= $bps;
		$psimage->{_note}		= $psimage->{_note}.' bps='.$psimage->{_bps};
		$psimage->{_Step}		= $psimage->{_Step}.' bps='.$psimage->{_bps};

	} else { 
		print("psimage, bps, missing bps,\n");
	 }
 }


=head2 sub brgb 


=cut

 sub brgb {

	my ( $self,$brgb )		= @_;
	if ( $brgb ne $empty_string ) {

		$psimage->{_brgb}		= $brgb;
		$psimage->{_note}		= $psimage->{_note}.' brgb='.$psimage->{_brgb};
		$psimage->{_Step}		= $psimage->{_Step}.' brgb='.$psimage->{_brgb};

	} else { 
		print("psimage, brgb, missing brgb,\n");
	 }
 }


=head2 sub clip 


=cut

 sub clip {

	my ( $self,$clip )		= @_;
	if ( $clip ne $empty_string ) {

		$psimage->{_clip}		= $clip;
		$psimage->{_note}		= $psimage->{_note}.' clip='.$psimage->{_clip};
		$psimage->{_Step}		= $psimage->{_Step}.' clip='.$psimage->{_clip};

	} else { 
		print("psimage, clip, missing clip,\n");
	 }
 }


=head2 sub curve 


=cut

 sub curve {

	my ( $self,$curve )		= @_;
	if ( $curve ne $empty_string ) {

		$psimage->{_curve}		= $curve;
		$psimage->{_note}		= $psimage->{_note}.' curve='.$psimage->{_curve};
		$psimage->{_Step}		= $psimage->{_Step}.' curve='.$psimage->{_curve};

	} else { 
		print("psimage, curve, missing curve,\n");
	 }
 }


=head2 sub curvecolor 


=cut

 sub curvecolor {

	my ( $self,$curvecolor )		= @_;
	if ( $curvecolor ne $empty_string ) {

		$psimage->{_curvecolor}		= $curvecolor;
		$psimage->{_note}		= $psimage->{_note}.' curvecolor='.$psimage->{_curvecolor};
		$psimage->{_Step}		= $psimage->{_Step}.' curvecolor='.$psimage->{_curvecolor};

	} else { 
		print("psimage, curvecolor, missing curvecolor,\n");
	 }
 }


=head2 sub curvedash 


=cut

 sub curvedash {

	my ( $self,$curvedash )		= @_;
	if ( $curvedash ne $empty_string ) {

		$psimage->{_curvedash}		= $curvedash;
		$psimage->{_note}		= $psimage->{_note}.' curvedash='.$psimage->{_curvedash};
		$psimage->{_Step}		= $psimage->{_Step}.' curvedash='.$psimage->{_curvedash};

	} else { 
		print("psimage, curvedash, missing curvedash,\n");
	 }
 }


=head2 sub curvefile 


=cut

 sub curvefile {

	my ( $self,$curvefile )		= @_;
	if ( $curvefile ne $empty_string ) {

		$psimage->{_curvefile}		= $curvefile;
		$psimage->{_note}		= $psimage->{_note}.' curvefile='.$psimage->{_curvefile};
		$psimage->{_Step}		= $psimage->{_Step}.' curvefile='.$psimage->{_curvefile};

	} else { 
		print("psimage, curvefile, missing curvefile,\n");
	 }
 }


=head2 sub curvewidth 


=cut

 sub curvewidth {

	my ( $self,$curvewidth )		= @_;
	if ( $curvewidth ne $empty_string ) {

		$psimage->{_curvewidth}		= $curvewidth;
		$psimage->{_note}		= $psimage->{_note}.' curvewidth='.$psimage->{_curvewidth};
		$psimage->{_Step}		= $psimage->{_Step}.' curvewidth='.$psimage->{_curvewidth};

	} else { 
		print("psimage, curvewidth, missing curvewidth,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$psimage->{_d1}		= $d1;
		$psimage->{_note}		= $psimage->{_note}.' d1='.$psimage->{_d1};
		$psimage->{_Step}		= $psimage->{_Step}.' d1='.$psimage->{_d1};

	} else { 
		print("psimage, d1, missing d1,\n");
	 }
 }


=head2 sub d1num 


=cut

 sub d1num {

	my ( $self,$d1num )		= @_;
	if ( $d1num ne $empty_string ) {

		$psimage->{_d1num}		= $d1num;
		$psimage->{_note}		= $psimage->{_note}.' d1num='.$psimage->{_d1num};
		$psimage->{_Step}		= $psimage->{_Step}.' d1num='.$psimage->{_d1num};

	} else { 
		print("psimage, d1num, missing d1num,\n");
	 }
 }


=head2 sub d1s 


=cut

 sub d1s {

	my ( $self,$d1s )		= @_;
	if ( $d1s ne $empty_string ) {

		$psimage->{_d1s}		= $d1s;
		$psimage->{_note}		= $psimage->{_note}.' d1s='.$psimage->{_d1s};
		$psimage->{_Step}		= $psimage->{_Step}.' d1s='.$psimage->{_d1s};

	} else { 
		print("psimage, d1s, missing d1s,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$psimage->{_d2}		= $d2;
		$psimage->{_note}		= $psimage->{_note}.' d2='.$psimage->{_d2};
		$psimage->{_Step}		= $psimage->{_Step}.' d2='.$psimage->{_d2};

	} else { 
		print("psimage, d2, missing d2,\n");
	 }
 }


=head2 sub d2num 


=cut

 sub d2num {

	my ( $self,$d2num )		= @_;
	if ( $d2num ne $empty_string ) {

		$psimage->{_d2num}		= $d2num;
		$psimage->{_note}		= $psimage->{_note}.' d2num='.$psimage->{_d2num};
		$psimage->{_Step}		= $psimage->{_Step}.' d2num='.$psimage->{_d2num};

	} else { 
		print("psimage, d2num, missing d2num,\n");
	 }
 }


=head2 sub d2s 


=cut

 sub d2s {

	my ( $self,$d2s )		= @_;
	if ( $d2s ne $empty_string ) {

		$psimage->{_d2s}		= $d2s;
		$psimage->{_note}		= $psimage->{_note}.' d2s='.$psimage->{_d2s};
		$psimage->{_Step}		= $psimage->{_Step}.' d2s='.$psimage->{_d2s};

	} else { 
		print("psimage, d2s, missing d2s,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$psimage->{_f1}		= $f1;
		$psimage->{_note}		= $psimage->{_note}.' f1='.$psimage->{_f1};
		$psimage->{_Step}		= $psimage->{_Step}.' f1='.$psimage->{_f1};

	} else { 
		print("psimage, f1, missing f1,\n");
	 }
 }


=head2 sub f1num 


=cut

 sub f1num {

	my ( $self,$f1num )		= @_;
	if ( $f1num ne $empty_string ) {

		$psimage->{_f1num}		= $f1num;
		$psimage->{_note}		= $psimage->{_note}.' f1num='.$psimage->{_f1num};
		$psimage->{_Step}		= $psimage->{_Step}.' f1num='.$psimage->{_f1num};

	} else { 
		print("psimage, f1num, missing f1num,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$psimage->{_f2}		= $f2;
		$psimage->{_note}		= $psimage->{_note}.' f2='.$psimage->{_f2};
		$psimage->{_Step}		= $psimage->{_Step}.' f2='.$psimage->{_f2};

	} else { 
		print("psimage, f2, missing f2,\n");
	 }
 }


=head2 sub f2num 


=cut

 sub f2num {

	my ( $self,$f2num )		= @_;
	if ( $f2num ne $empty_string ) {

		$psimage->{_f2num}		= $f2num;
		$psimage->{_note}		= $psimage->{_note}.' f2num='.$psimage->{_f2num};
		$psimage->{_Step}		= $psimage->{_Step}.' f2num='.$psimage->{_f2num};

	} else { 
		print("psimage, f2num, missing f2num,\n");
	 }
 }


=head2 sub ghls 


=cut

 sub ghls {

	my ( $self,$ghls )		= @_;
	if ( $ghls ne $empty_string ) {

		$psimage->{_ghls}		= $ghls;
		$psimage->{_note}		= $psimage->{_note}.' ghls='.$psimage->{_ghls};
		$psimage->{_Step}		= $psimage->{_Step}.' ghls='.$psimage->{_ghls};

	} else { 
		print("psimage, ghls, missing ghls,\n");
	 }
 }


=head2 sub grgb 


=cut

 sub grgb {

	my ( $self,$grgb )		= @_;
	if ( $grgb ne $empty_string ) {

		$psimage->{_grgb}		= $grgb;
		$psimage->{_note}		= $psimage->{_note}.' grgb='.$psimage->{_grgb};
		$psimage->{_Step}		= $psimage->{_Step}.' grgb='.$psimage->{_grgb};

	} else { 
		print("psimage, grgb, missing grgb,\n");
	 }
 }


=head2 sub grid1 


=cut

 sub grid1 {

	my ( $self,$grid1 )		= @_;
	if ( $grid1 ne $empty_string ) {

		$psimage->{_grid1}		= $grid1;
		$psimage->{_note}		= $psimage->{_note}.' grid1='.$psimage->{_grid1};
		$psimage->{_Step}		= $psimage->{_Step}.' grid1='.$psimage->{_grid1};

	} else { 
		print("psimage, grid1, missing grid1,\n");
	 }
 }


=head2 sub grid2 


=cut

 sub grid2 {

	my ( $self,$grid2 )		= @_;
	if ( $grid2 ne $empty_string ) {

		$psimage->{_grid2}		= $grid2;
		$psimage->{_note}		= $psimage->{_note}.' grid2='.$psimage->{_grid2};
		$psimage->{_Step}		= $psimage->{_Step}.' grid2='.$psimage->{_grid2};

	} else { 
		print("psimage, grid2, missing grid2,\n");
	 }
 }


=head2 sub gridcolor 


=cut

 sub gridcolor {

	my ( $self,$gridcolor )		= @_;
	if ( $gridcolor ne $empty_string ) {

		$psimage->{_gridcolor}		= $gridcolor;
		$psimage->{_note}		= $psimage->{_note}.' gridcolor='.$psimage->{_gridcolor};
		$psimage->{_Step}		= $psimage->{_Step}.' gridcolor='.$psimage->{_gridcolor};

	} else { 
		print("psimage, gridcolor, missing gridcolor,\n");
	 }
 }


=head2 sub gridwidth 


=cut

 sub gridwidth {

	my ( $self,$gridwidth )		= @_;
	if ( $gridwidth ne $empty_string ) {

		$psimage->{_gridwidth}		= $gridwidth;
		$psimage->{_note}		= $psimage->{_note}.' gridwidth='.$psimage->{_gridwidth};
		$psimage->{_Step}		= $psimage->{_Step}.' gridwidth='.$psimage->{_gridwidth};

	} else { 
		print("psimage, gridwidth, missing gridwidth,\n");
	 }
 }


=head2 sub height 


=cut

 sub height {

	my ( $self,$height )		= @_;
	if ( $height ne $empty_string ) {

		$psimage->{_height}		= $height;
		$psimage->{_note}		= $psimage->{_note}.' height='.$psimage->{_height};
		$psimage->{_Step}		= $psimage->{_Step}.' height='.$psimage->{_height};

	} else { 
		print("psimage, height, missing height,\n");
	 }
 }


=head2 sub infile 


=cut

 sub infile {

	my ( $self,$infile )		= @_;
	if ( $infile ne $empty_string ) {

		$psimage->{_infile}		= $infile;
		$psimage->{_note}		= $psimage->{_note}.' infile='.$psimage->{_infile};
		$psimage->{_Step}		= $psimage->{_Step}.' infile='.$psimage->{_infile};

	} else { 
		print("psimage, infile, missing infile,\n");
	 }
 }


=head2 sub label1 


=cut

 sub label1 {

	my ( $self,$label1 )		= @_;
	if ( $label1 ne $empty_string ) {

		$psimage->{_label1}		= $label1;
		$psimage->{_note}		= $psimage->{_note}.' label1='.$psimage->{_label1};
		$psimage->{_Step}		= $psimage->{_Step}.' label1='.$psimage->{_label1};

	} else { 
		print("psimage, label1, missing label1,\n");
	 }
 }


=head2 sub label2 


=cut

 sub label2 {

	my ( $self,$label2 )		= @_;
	if ( $label2 ne $empty_string ) {

		$psimage->{_label2}		= $label2;
		$psimage->{_note}		= $psimage->{_note}.' label2='.$psimage->{_label2};
		$psimage->{_Step}		= $psimage->{_Step}.' label2='.$psimage->{_label2};

	} else { 
		print("psimage, label2, missing label2,\n");
	 }
 }


=head2 sub labelfont 


=cut

 sub labelfont {

	my ( $self,$labelfont )		= @_;
	if ( $labelfont ne $empty_string ) {

		$psimage->{_labelfont}		= $labelfont;
		$psimage->{_note}		= $psimage->{_note}.' labelfont='.$psimage->{_labelfont};
		$psimage->{_Step}		= $psimage->{_Step}.' labelfont='.$psimage->{_labelfont};

	} else { 
		print("psimage, labelfont, missing labelfont,\n");
	 }
 }


=head2 sub labelsize 


=cut

 sub labelsize {

	my ( $self,$labelsize )		= @_;
	if ( $labelsize ne $empty_string ) {

		$psimage->{_labelsize}		= $labelsize;
		$psimage->{_note}		= $psimage->{_note}.' labelsize='.$psimage->{_labelsize};
		$psimage->{_Step}		= $psimage->{_Step}.' labelsize='.$psimage->{_labelsize};

	} else { 
		print("psimage, labelsize, missing labelsize,\n");
	 }
 }


=head2 sub lbeg 


=cut

 sub lbeg {

	my ( $self,$lbeg )		= @_;
	if ( $lbeg ne $empty_string ) {

		$psimage->{_lbeg}		= $lbeg;
		$psimage->{_note}		= $psimage->{_note}.' lbeg='.$psimage->{_lbeg};
		$psimage->{_Step}		= $psimage->{_Step}.' lbeg='.$psimage->{_lbeg};

	} else { 
		print("psimage, lbeg, missing lbeg,\n");
	 }
 }


=head2 sub ldnum 


=cut

 sub ldnum {

	my ( $self,$ldnum )		= @_;
	if ( $ldnum ne $empty_string ) {

		$psimage->{_ldnum}		= $ldnum;
		$psimage->{_note}		= $psimage->{_note}.' ldnum='.$psimage->{_ldnum};
		$psimage->{_Step}		= $psimage->{_Step}.' ldnum='.$psimage->{_ldnum};

	} else { 
		print("psimage, ldnum, missing ldnum,\n");
	 }
 }


=head2 sub legend 


=cut

 sub legend {

	my ( $self,$legend )		= @_;
	if ( $legend ne $empty_string ) {

		$psimage->{_legend}		= $legend;
		$psimage->{_note}		= $psimage->{_note}.' legend='.$psimage->{_legend};
		$psimage->{_Step}		= $psimage->{_Step}.' legend='.$psimage->{_legend};

	} else { 
		print("psimage, legend, missing legend,\n");
	 }
 }


=head2 sub legendfont 


=cut

 sub legendfont {

	my ( $self,$legendfont )		= @_;
	if ( $legendfont ne $empty_string ) {

		$psimage->{_legendfont}		= $legendfont;
		$psimage->{_note}		= $psimage->{_note}.' legendfont='.$psimage->{_legendfont};
		$psimage->{_Step}		= $psimage->{_Step}.' legendfont='.$psimage->{_legendfont};

	} else { 
		print("psimage, legendfont, missing legendfont,\n");
	 }
 }


=head2 sub lend 


=cut

 sub lend {

	my ( $self,$lend )		= @_;
	if ( $lend ne $empty_string ) {

		$psimage->{_lend}		= $lend;
		$psimage->{_note}		= $psimage->{_note}.' lend='.$psimage->{_lend};
		$psimage->{_Step}		= $psimage->{_Step}.' lend='.$psimage->{_lend};

	} else { 
		print("psimage, lend, missing lend,\n");
	 }
 }


=head2 sub lfnum 


=cut

 sub lfnum {

	my ( $self,$lfnum )		= @_;
	if ( $lfnum ne $empty_string ) {

		$psimage->{_lfnum}		= $lfnum;
		$psimage->{_note}		= $psimage->{_note}.' lfnum='.$psimage->{_lfnum};
		$psimage->{_Step}		= $psimage->{_Step}.' lfnum='.$psimage->{_lfnum};

	} else { 
		print("psimage, lfnum, missing lfnum,\n");
	 }
 }


=head2 sub lgrid 


=cut

 sub lgrid {

	my ( $self,$lgrid )		= @_;
	if ( $lgrid ne $empty_string ) {

		$psimage->{_lgrid}		= $lgrid;
		$psimage->{_note}		= $psimage->{_note}.' lgrid='.$psimage->{_lgrid};
		$psimage->{_Step}		= $psimage->{_Step}.' lgrid='.$psimage->{_lgrid};

	} else { 
		print("psimage, lgrid, missing lgrid,\n");
	 }
 }


=head2 sub lheight 


=cut

 sub lheight {

	my ( $self,$lheight )		= @_;
	if ( $lheight ne $empty_string ) {

		$psimage->{_lheight}		= $lheight;
		$psimage->{_note}		= $psimage->{_note}.' lheight='.$psimage->{_lheight};
		$psimage->{_Step}		= $psimage->{_Step}.' lheight='.$psimage->{_lheight};

	} else { 
		print("psimage, lheight, missing lheight,\n");
	 }
 }


=head2 sub lnice 


=cut

 sub lnice {

	my ( $self,$lnice )		= @_;
	if ( $lnice ne $empty_string ) {

		$psimage->{_lnice}		= $lnice;
		$psimage->{_note}		= $psimage->{_note}.' lnice='.$psimage->{_lnice};
		$psimage->{_Step}		= $psimage->{_Step}.' lnice='.$psimage->{_lnice};

	} else { 
		print("psimage, lnice, missing lnice,\n");
	 }
 }


=head2 sub lntic 


=cut

 sub lntic {

	my ( $self,$lntic )		= @_;
	if ( $lntic ne $empty_string ) {

		$psimage->{_lntic}		= $lntic;
		$psimage->{_note}		= $psimage->{_note}.' lntic='.$psimage->{_lntic};
		$psimage->{_Step}		= $psimage->{_Step}.' lntic='.$psimage->{_lntic};

	} else { 
		print("psimage, lntic, missing lntic,\n");
	 }
 }


=head2 sub lstyle 


=cut

 sub lstyle {

	my ( $self,$lstyle )		= @_;
	if ( $lstyle ne $empty_string ) {

		$psimage->{_lstyle}		= $lstyle;
		$psimage->{_note}		= $psimage->{_note}.' lstyle='.$psimage->{_lstyle};
		$psimage->{_Step}		= $psimage->{_Step}.' lstyle='.$psimage->{_lstyle};

	} else { 
		print("psimage, lstyle, missing lstyle,\n");
	 }
 }


=head2 sub lwidth 


=cut

 sub lwidth {

	my ( $self,$lwidth )		= @_;
	if ( $lwidth ne $empty_string ) {

		$psimage->{_lwidth}		= $lwidth;
		$psimage->{_note}		= $psimage->{_note}.' lwidth='.$psimage->{_lwidth};
		$psimage->{_Step}		= $psimage->{_Step}.' lwidth='.$psimage->{_lwidth};

	} else { 
		print("psimage, lwidth, missing lwidth,\n");
	 }
 }


=head2 sub lx 


=cut

 sub lx {

	my ( $self,$lx )		= @_;
	if ( $lx ne $empty_string ) {

		$psimage->{_lx}		= $lx;
		$psimage->{_note}		= $psimage->{_note}.' lx='.$psimage->{_lx};
		$psimage->{_Step}		= $psimage->{_Step}.' lx='.$psimage->{_lx};

	} else { 
		print("psimage, lx, missing lx,\n");
	 }
 }


=head2 sub ly 


=cut

 sub ly {

	my ( $self,$ly )		= @_;
	if ( $ly ne $empty_string ) {

		$psimage->{_ly}		= $ly;
		$psimage->{_note}		= $psimage->{_note}.' ly='.$psimage->{_ly};
		$psimage->{_Step}		= $psimage->{_Step}.' ly='.$psimage->{_ly};

	} else { 
		print("psimage, ly, missing ly,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$psimage->{_n1}		= $n1;
		$psimage->{_note}		= $psimage->{_note}.' n1='.$psimage->{_n1};
		$psimage->{_Step}		= $psimage->{_Step}.' n1='.$psimage->{_n1};

	} else { 
		print("psimage, n1, missing n1,\n");
	 }
 }


=head2 sub n1tic 


=cut

 sub n1tic {

	my ( $self,$n1tic )		= @_;
	if ( $n1tic ne $empty_string ) {

		$psimage->{_n1tic}		= $n1tic;
		$psimage->{_note}		= $psimage->{_note}.' n1tic='.$psimage->{_n1tic};
		$psimage->{_Step}		= $psimage->{_Step}.' n1tic='.$psimage->{_n1tic};

	} else { 
		print("psimage, n1tic, missing n1tic,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$psimage->{_n2}		= $n2;
		$psimage->{_note}		= $psimage->{_note}.' n2='.$psimage->{_n2};
		$psimage->{_Step}		= $psimage->{_Step}.' n2='.$psimage->{_n2};

	} else { 
		print("psimage, n2, missing n2,\n");
	 }
 }


=head2 sub n2tic 


=cut

 sub n2tic {

	my ( $self,$n2tic )		= @_;
	if ( $n2tic ne $empty_string ) {

		$psimage->{_n2tic}		= $n2tic;
		$psimage->{_note}		= $psimage->{_note}.' n2tic='.$psimage->{_n2tic};
		$psimage->{_Step}		= $psimage->{_Step}.' n2tic='.$psimage->{_n2tic};

	} else { 
		print("psimage, n2tic, missing n2tic,\n");
	 }
 }


=head2 sub npair 


=cut

 sub npair {

	my ( $self,$npair )		= @_;
	if ( $npair ne $empty_string ) {

		$psimage->{_npair}		= $npair;
		$psimage->{_note}		= $psimage->{_note}.' npair='.$psimage->{_npair};
		$psimage->{_Step}		= $psimage->{_Step}.' npair='.$psimage->{_npair};

	} else { 
		print("psimage, npair, missing npair,\n");
	 }
 }


=head2 sub perc 


=cut

 sub perc {

	my ( $self,$perc )		= @_;
	if ( $perc ne $empty_string ) {

		$psimage->{_perc}		= $perc;
		$psimage->{_note}		= $psimage->{_note}.' perc='.$psimage->{_perc};
		$psimage->{_Step}		= $psimage->{_Step}.' perc='.$psimage->{_perc};

	} else { 
		print("psimage, perc, missing perc,\n");
	 }
 }


=head2 sub style 


=cut

 sub style {

	my ( $self,$style )		= @_;
	if ( $style ne $empty_string ) {

		$psimage->{_style}		= $style;
		$psimage->{_note}		= $psimage->{_note}.' style='.$psimage->{_style};
		$psimage->{_Step}		= $psimage->{_Step}.' style='.$psimage->{_style};

	} else { 
		print("psimage, style, missing style,\n");
	 }
 }


=head2 sub threecolor 


=cut

 sub threecolor {

	my ( $self,$threecolor )		= @_;
	if ( $threecolor ne $empty_string ) {

		$psimage->{_threecolor}		= $threecolor;
		$psimage->{_note}		= $psimage->{_note}.' threecolor='.$psimage->{_threecolor};
		$psimage->{_Step}		= $psimage->{_Step}.' threecolor='.$psimage->{_threecolor};

	} else { 
		print("psimage, threecolor, missing threecolor,\n");
	 }
 }


=head2 sub ticwidth 


=cut

 sub ticwidth {

	my ( $self,$ticwidth )		= @_;
	if ( $ticwidth ne $empty_string ) {

		$psimage->{_ticwidth}		= $ticwidth;
		$psimage->{_note}		= $psimage->{_note}.' ticwidth='.$psimage->{_ticwidth};
		$psimage->{_Step}		= $psimage->{_Step}.' ticwidth='.$psimage->{_ticwidth};

	} else { 
		print("psimage, ticwidth, missing ticwidth,\n");
	 }
 }


=head2 sub title 


=cut

 sub title {

	my ( $self,$title )		= @_;
	if ( $title ne $empty_string ) {

		$psimage->{_title}		= $title;
		$psimage->{_note}		= $psimage->{_note}.' title='.$psimage->{_title};
		$psimage->{_Step}		= $psimage->{_Step}.' title='.$psimage->{_title};

	} else { 
		print("psimage, title, missing title,\n");
	 }
 }


=head2 sub titlecolor 


=cut

 sub titlecolor {

	my ( $self,$titlecolor )		= @_;
	if ( $titlecolor ne $empty_string ) {

		$psimage->{_titlecolor}		= $titlecolor;
		$psimage->{_note}		= $psimage->{_note}.' titlecolor='.$psimage->{_titlecolor};
		$psimage->{_Step}		= $psimage->{_Step}.' titlecolor='.$psimage->{_titlecolor};

	} else { 
		print("psimage, titlecolor, missing titlecolor,\n");
	 }
 }


=head2 sub titlefont 


=cut

 sub titlefont {

	my ( $self,$titlefont )		= @_;
	if ( $titlefont ne $empty_string ) {

		$psimage->{_titlefont}		= $titlefont;
		$psimage->{_note}		= $psimage->{_note}.' titlefont='.$psimage->{_titlefont};
		$psimage->{_Step}		= $psimage->{_Step}.' titlefont='.$psimage->{_titlefont};

	} else { 
		print("psimage, titlefont, missing titlefont,\n");
	 }
 }


=head2 sub titlesize 


=cut

 sub titlesize {

	my ( $self,$titlesize )		= @_;
	if ( $titlesize ne $empty_string ) {

		$psimage->{_titlesize}		= $titlesize;
		$psimage->{_note}		= $psimage->{_note}.' titlesize='.$psimage->{_titlesize};
		$psimage->{_Step}		= $psimage->{_Step}.' titlesize='.$psimage->{_titlesize};

	} else { 
		print("psimage, titlesize, missing titlesize,\n");
	 }
 }


=head2 sub units 


=cut

 sub units {

	my ( $self,$units )		= @_;
	if ( $units ne $empty_string ) {

		$psimage->{_units}		= $units;
		$psimage->{_note}		= $psimage->{_note}.' units='.$psimage->{_units};
		$psimage->{_Step}		= $psimage->{_Step}.' units='.$psimage->{_units};

	} else { 
		print("psimage, units, missing units,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$psimage->{_verbose}		= $verbose;
		$psimage->{_note}		= $psimage->{_note}.' verbose='.$psimage->{_verbose};
		$psimage->{_Step}		= $psimage->{_Step}.' verbose='.$psimage->{_verbose};

	} else { 
		print("psimage, verbose, missing verbose,\n");
	 }
 }


=head2 sub wclip 


=cut

 sub wclip {

	my ( $self,$wclip )		= @_;
	if ( $wclip ne $empty_string ) {

		$psimage->{_wclip}		= $wclip;
		$psimage->{_note}		= $psimage->{_note}.' wclip='.$psimage->{_wclip};
		$psimage->{_Step}		= $psimage->{_Step}.' wclip='.$psimage->{_wclip};

	} else { 
		print("psimage, wclip, missing wclip,\n");
	 }
 }


=head2 sub whls 


=cut

 sub whls {

	my ( $self,$whls )		= @_;
	if ( $whls ne $empty_string ) {

		$psimage->{_whls}		= $whls;
		$psimage->{_note}		= $psimage->{_note}.' whls='.$psimage->{_whls};
		$psimage->{_Step}		= $psimage->{_Step}.' whls='.$psimage->{_whls};

	} else { 
		print("psimage, whls, missing whls,\n");
	 }
 }


=head2 sub width 


=cut

 sub width {

	my ( $self,$width )		= @_;
	if ( $width ne $empty_string ) {

		$psimage->{_width}		= $width;
		$psimage->{_note}		= $psimage->{_note}.' width='.$psimage->{_width};
		$psimage->{_Step}		= $psimage->{_Step}.' width='.$psimage->{_width};

	} else { 
		print("psimage, width, missing width,\n");
	 }
 }


=head2 sub wperc 


=cut

 sub wperc {

	my ( $self,$wperc )		= @_;
	if ( $wperc ne $empty_string ) {

		$psimage->{_wperc}		= $wperc;
		$psimage->{_note}		= $psimage->{_note}.' wperc='.$psimage->{_wperc};
		$psimage->{_Step}		= $psimage->{_Step}.' wperc='.$psimage->{_wperc};

	} else { 
		print("psimage, wperc, missing wperc,\n");
	 }
 }


=head2 sub wrgb 


=cut

 sub wrgb {

	my ( $self,$wrgb )		= @_;
	if ( $wrgb ne $empty_string ) {

		$psimage->{_wrgb}		= $wrgb;
		$psimage->{_note}		= $psimage->{_note}.' wrgb='.$psimage->{_wrgb};
		$psimage->{_Step}		= $psimage->{_Step}.' wrgb='.$psimage->{_wrgb};

	} else { 
		print("psimage, wrgb, missing wrgb,\n");
	 }
 }


=head2 sub x1beg 


=cut

 sub x1beg {

	my ( $self,$x1beg )		= @_;
	if ( $x1beg ne $empty_string ) {

		$psimage->{_x1beg}		= $x1beg;
		$psimage->{_note}		= $psimage->{_note}.' x1beg='.$psimage->{_x1beg};
		$psimage->{_Step}		= $psimage->{_Step}.' x1beg='.$psimage->{_x1beg};

	} else { 
		print("psimage, x1beg, missing x1beg,\n");
	 }
 }


=head2 sub x1end 


=cut

 sub x1end {

	my ( $self,$x1end )		= @_;
	if ( $x1end ne $empty_string ) {

		$psimage->{_x1end}		= $x1end;
		$psimage->{_note}		= $psimage->{_note}.' x1end='.$psimage->{_x1end};
		$psimage->{_Step}		= $psimage->{_Step}.' x1end='.$psimage->{_x1end};

	} else { 
		print("psimage, x1end, missing x1end,\n");
	 }
 }


=head2 sub x2beg 


=cut

 sub x2beg {

	my ( $self,$x2beg )		= @_;
	if ( $x2beg ne $empty_string ) {

		$psimage->{_x2beg}		= $x2beg;
		$psimage->{_note}		= $psimage->{_note}.' x2beg='.$psimage->{_x2beg};
		$psimage->{_Step}		= $psimage->{_Step}.' x2beg='.$psimage->{_x2beg};

	} else { 
		print("psimage, x2beg, missing x2beg,\n");
	 }
 }


=head2 sub x2end 


=cut

 sub x2end {

	my ( $self,$x2end )		= @_;
	if ( $x2end ne $empty_string ) {

		$psimage->{_x2end}		= $x2end;
		$psimage->{_note}		= $psimage->{_note}.' x2end='.$psimage->{_x2end};
		$psimage->{_Step}		= $psimage->{_Step}.' x2end='.$psimage->{_x2end};

	} else { 
		print("psimage, x2end, missing x2end,\n");
	 }
 }


=head2 sub xbox 


=cut

 sub xbox {

	my ( $self,$xbox )		= @_;
	if ( $xbox ne $empty_string ) {

		$psimage->{_xbox}		= $xbox;
		$psimage->{_note}		= $psimage->{_note}.' xbox='.$psimage->{_xbox};
		$psimage->{_Step}		= $psimage->{_Step}.' xbox='.$psimage->{_xbox};

	} else { 
		print("psimage, xbox, missing xbox,\n");
	 }
 }


=head2 sub ybox 


=cut

 sub ybox {

	my ( $self,$ybox )		= @_;
	if ( $ybox ne $empty_string ) {

		$psimage->{_ybox}		= $ybox;
		$psimage->{_note}		= $psimage->{_note}.' ybox='.$psimage->{_ybox};
		$psimage->{_Step}		= $psimage->{_Step}.' ybox='.$psimage->{_ybox};

	} else { 
		print("psimage, ybox, missing ybox,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 75;

    return($max_index);
}
 
 
1;
