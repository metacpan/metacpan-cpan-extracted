package App::SeismicUnixGui::sunix::plot::psmovie;

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
 PSMOVIE - PostScript MOVIE plot of a uniformly-sampled function f(x1,x2,x3)



 psmovie n1= [optional parameters] <binaryfile >postscriptfile		



 Required Parameters:							

 n1                     number of samples in 1st (fast) dimension	



 Optional Parameters:							

 d1=1.0                 sampling interval in 1st dimension		

 f1=0.0                 first sample in 1st dimension			

 n2=all                 number of samples in 2nd (slow) dimension	

 d2=1.0                 sampling interval in 2nd dimension		

 f2=0.0                 first sample in 2nd dimension			

 perc=100.0             percentile used to determine clip		

 clip=(perc percentile) clip used to determine bclip and wclip		

 bperc=perc             percentile for determining black clip value	

 wperc=100.0-perc       percentile for determining white clip value	

 bclip=clip             data values outside of [bclip,wclip] are clipped

 wclip=-clip            data values outside of [bclip,wclip] are clipped

 d1s=1.0                factor by which to scale d1 before imaging	

 d2s=1.0                factor by which to scale d2 before imaging	

 verbose=1              =1 for info printed on stderr (0 for no info)	

 xbox=1.0               offset in inches of left side of axes box	

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

 style=seismic          normal (axis 1 horizontal, axis 2 vertical) or	

                        seismic (axis 1 vertical, axis 2 horizontal)	

 n3=1                   number of samples in third dimension		

 title2=                second title to annotate different frames	

 loopdsp=3              display loop type (1=loop over n1; 2=loop over n2;

                                           3 = loop over n3)		

 d3=1.0                 sampling interval in 3rd dimension		

 f3=d3                  first sample in 3rd dimension			



 NeXT: view movie via:   psmovie < infile n1= [optional params...] | open

 Note: currently only the Preview Application can handle the multipage  

       PostScript output by this program.				



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

my $psmovie			= {
	_axescolor					=> '',
	_bclip					=> '',
	_bperc					=> '',
	_clip					=> '',
	_d1					=> '',
	_d1num					=> '',
	_d1s					=> '',
	_d2					=> '',
	_d2num					=> '',
	_d2s					=> '',
	_d3					=> '',
	_f1					=> '',
	_f1num					=> '',
	_f2					=> '',
	_f2num					=> '',
	_f3					=> '',
	_grid1					=> '',
	_grid2					=> '',
	_hbox					=> '',
	_label1					=> '',
	_label2					=> '',
	_labelfont					=> '',
	_labelsize					=> '',
	_loopdsp					=> '',
	_n1					=> '',
	_n1tic					=> '',
	_n2					=> '',
	_n2tic					=> '',
	_n3					=> '',
	_perc					=> '',
	_style					=> '',
	_title					=> '',
	_title2					=> '',
	_titlefont					=> '',
	_titlesize					=> '',
	_verbose					=> '',
	_wbox					=> '',
	_wclip					=> '',
	_wperc					=> '',
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

	$psmovie->{_Step}     = 'psmovie'.$psmovie->{_Step};
	return ( $psmovie->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$psmovie->{_note}     = 'psmovie'.$psmovie->{_note};
	return ( $psmovie->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$psmovie->{_axescolor}			= '';
		$psmovie->{_bclip}			= '';
		$psmovie->{_bperc}			= '';
		$psmovie->{_clip}			= '';
		$psmovie->{_d1}			= '';
		$psmovie->{_d1num}			= '';
		$psmovie->{_d1s}			= '';
		$psmovie->{_d2}			= '';
		$psmovie->{_d2num}			= '';
		$psmovie->{_d2s}			= '';
		$psmovie->{_d3}			= '';
		$psmovie->{_f1}			= '';
		$psmovie->{_f1num}			= '';
		$psmovie->{_f2}			= '';
		$psmovie->{_f2num}			= '';
		$psmovie->{_f3}			= '';
		$psmovie->{_grid1}			= '';
		$psmovie->{_grid2}			= '';
		$psmovie->{_hbox}			= '';
		$psmovie->{_label1}			= '';
		$psmovie->{_label2}			= '';
		$psmovie->{_labelfont}			= '';
		$psmovie->{_labelsize}			= '';
		$psmovie->{_loopdsp}			= '';
		$psmovie->{_n1}			= '';
		$psmovie->{_n1tic}			= '';
		$psmovie->{_n2}			= '';
		$psmovie->{_n2tic}			= '';
		$psmovie->{_n3}			= '';
		$psmovie->{_perc}			= '';
		$psmovie->{_style}			= '';
		$psmovie->{_title}			= '';
		$psmovie->{_title2}			= '';
		$psmovie->{_titlefont}			= '';
		$psmovie->{_titlesize}			= '';
		$psmovie->{_verbose}			= '';
		$psmovie->{_wbox}			= '';
		$psmovie->{_wclip}			= '';
		$psmovie->{_wperc}			= '';
		$psmovie->{_x1beg}			= '';
		$psmovie->{_x1end}			= '';
		$psmovie->{_x2beg}			= '';
		$psmovie->{_x2end}			= '';
		$psmovie->{_xbox}			= '';
		$psmovie->{_ybox}			= '';
		$psmovie->{_Step}			= '';
		$psmovie->{_note}			= '';
 }



=head2 sub axescolor 


=cut

 sub axescolor {

	my ( $self,$axescolor )		= @_;
	if ( $axescolor ne $empty_string ) {

		$psmovie->{_axescolor}		= $axescolor;
		$psmovie->{_note}		= $psmovie->{_note}.' axescolor='.$psmovie->{_axescolor};
		$psmovie->{_Step}		= $psmovie->{_Step}.' axescolor='.$psmovie->{_axescolor};

	} else { 
		print("psmovie, axescolor, missing axescolor,\n");
	 }
 }


=head2 sub bclip 


=cut

 sub bclip {

	my ( $self,$bclip )		= @_;
	if ( $bclip ne $empty_string ) {

		$psmovie->{_bclip}		= $bclip;
		$psmovie->{_note}		= $psmovie->{_note}.' bclip='.$psmovie->{_bclip};
		$psmovie->{_Step}		= $psmovie->{_Step}.' bclip='.$psmovie->{_bclip};

	} else { 
		print("psmovie, bclip, missing bclip,\n");
	 }
 }


=head2 sub bperc 


=cut

 sub bperc {

	my ( $self,$bperc )		= @_;
	if ( $bperc ne $empty_string ) {

		$psmovie->{_bperc}		= $bperc;
		$psmovie->{_note}		= $psmovie->{_note}.' bperc='.$psmovie->{_bperc};
		$psmovie->{_Step}		= $psmovie->{_Step}.' bperc='.$psmovie->{_bperc};

	} else { 
		print("psmovie, bperc, missing bperc,\n");
	 }
 }


=head2 sub clip 


=cut

 sub clip {

	my ( $self,$clip )		= @_;
	if ( $clip ne $empty_string ) {

		$psmovie->{_clip}		= $clip;
		$psmovie->{_note}		= $psmovie->{_note}.' clip='.$psmovie->{_clip};
		$psmovie->{_Step}		= $psmovie->{_Step}.' clip='.$psmovie->{_clip};

	} else { 
		print("psmovie, clip, missing clip,\n");
	 }
 }


=head2 sub d1 


=cut

 sub d1 {

	my ( $self,$d1 )		= @_;
	if ( $d1 ne $empty_string ) {

		$psmovie->{_d1}		= $d1;
		$psmovie->{_note}		= $psmovie->{_note}.' d1='.$psmovie->{_d1};
		$psmovie->{_Step}		= $psmovie->{_Step}.' d1='.$psmovie->{_d1};

	} else { 
		print("psmovie, d1, missing d1,\n");
	 }
 }


=head2 sub d1num 


=cut

 sub d1num {

	my ( $self,$d1num )		= @_;
	if ( $d1num ne $empty_string ) {

		$psmovie->{_d1num}		= $d1num;
		$psmovie->{_note}		= $psmovie->{_note}.' d1num='.$psmovie->{_d1num};
		$psmovie->{_Step}		= $psmovie->{_Step}.' d1num='.$psmovie->{_d1num};

	} else { 
		print("psmovie, d1num, missing d1num,\n");
	 }
 }


=head2 sub d1s 


=cut

 sub d1s {

	my ( $self,$d1s )		= @_;
	if ( $d1s ne $empty_string ) {

		$psmovie->{_d1s}		= $d1s;
		$psmovie->{_note}		= $psmovie->{_note}.' d1s='.$psmovie->{_d1s};
		$psmovie->{_Step}		= $psmovie->{_Step}.' d1s='.$psmovie->{_d1s};

	} else { 
		print("psmovie, d1s, missing d1s,\n");
	 }
 }


=head2 sub d2 


=cut

 sub d2 {

	my ( $self,$d2 )		= @_;
	if ( $d2 ne $empty_string ) {

		$psmovie->{_d2}		= $d2;
		$psmovie->{_note}		= $psmovie->{_note}.' d2='.$psmovie->{_d2};
		$psmovie->{_Step}		= $psmovie->{_Step}.' d2='.$psmovie->{_d2};

	} else { 
		print("psmovie, d2, missing d2,\n");
	 }
 }


=head2 sub d2num 


=cut

 sub d2num {

	my ( $self,$d2num )		= @_;
	if ( $d2num ne $empty_string ) {

		$psmovie->{_d2num}		= $d2num;
		$psmovie->{_note}		= $psmovie->{_note}.' d2num='.$psmovie->{_d2num};
		$psmovie->{_Step}		= $psmovie->{_Step}.' d2num='.$psmovie->{_d2num};

	} else { 
		print("psmovie, d2num, missing d2num,\n");
	 }
 }


=head2 sub d2s 


=cut

 sub d2s {

	my ( $self,$d2s )		= @_;
	if ( $d2s ne $empty_string ) {

		$psmovie->{_d2s}		= $d2s;
		$psmovie->{_note}		= $psmovie->{_note}.' d2s='.$psmovie->{_d2s};
		$psmovie->{_Step}		= $psmovie->{_Step}.' d2s='.$psmovie->{_d2s};

	} else { 
		print("psmovie, d2s, missing d2s,\n");
	 }
 }


=head2 sub d3 


=cut

 sub d3 {

	my ( $self,$d3 )		= @_;
	if ( $d3 ne $empty_string ) {

		$psmovie->{_d3}		= $d3;
		$psmovie->{_note}		= $psmovie->{_note}.' d3='.$psmovie->{_d3};
		$psmovie->{_Step}		= $psmovie->{_Step}.' d3='.$psmovie->{_d3};

	} else { 
		print("psmovie, d3, missing d3,\n");
	 }
 }


=head2 sub f1 


=cut

 sub f1 {

	my ( $self,$f1 )		= @_;
	if ( $f1 ne $empty_string ) {

		$psmovie->{_f1}		= $f1;
		$psmovie->{_note}		= $psmovie->{_note}.' f1='.$psmovie->{_f1};
		$psmovie->{_Step}		= $psmovie->{_Step}.' f1='.$psmovie->{_f1};

	} else { 
		print("psmovie, f1, missing f1,\n");
	 }
 }


=head2 sub f1num 


=cut

 sub f1num {

	my ( $self,$f1num )		= @_;
	if ( $f1num ne $empty_string ) {

		$psmovie->{_f1num}		= $f1num;
		$psmovie->{_note}		= $psmovie->{_note}.' f1num='.$psmovie->{_f1num};
		$psmovie->{_Step}		= $psmovie->{_Step}.' f1num='.$psmovie->{_f1num};

	} else { 
		print("psmovie, f1num, missing f1num,\n");
	 }
 }


=head2 sub f2 


=cut

 sub f2 {

	my ( $self,$f2 )		= @_;
	if ( $f2 ne $empty_string ) {

		$psmovie->{_f2}		= $f2;
		$psmovie->{_note}		= $psmovie->{_note}.' f2='.$psmovie->{_f2};
		$psmovie->{_Step}		= $psmovie->{_Step}.' f2='.$psmovie->{_f2};

	} else { 
		print("psmovie, f2, missing f2,\n");
	 }
 }


=head2 sub f2num 


=cut

 sub f2num {

	my ( $self,$f2num )		= @_;
	if ( $f2num ne $empty_string ) {

		$psmovie->{_f2num}		= $f2num;
		$psmovie->{_note}		= $psmovie->{_note}.' f2num='.$psmovie->{_f2num};
		$psmovie->{_Step}		= $psmovie->{_Step}.' f2num='.$psmovie->{_f2num};

	} else { 
		print("psmovie, f2num, missing f2num,\n");
	 }
 }


=head2 sub f3 


=cut

 sub f3 {

	my ( $self,$f3 )		= @_;
	if ( $f3 ne $empty_string ) {

		$psmovie->{_f3}		= $f3;
		$psmovie->{_note}		= $psmovie->{_note}.' f3='.$psmovie->{_f3};
		$psmovie->{_Step}		= $psmovie->{_Step}.' f3='.$psmovie->{_f3};

	} else { 
		print("psmovie, f3, missing f3,\n");
	 }
 }


=head2 sub grid1 


=cut

 sub grid1 {

	my ( $self,$grid1 )		= @_;
	if ( $grid1 ne $empty_string ) {

		$psmovie->{_grid1}		= $grid1;
		$psmovie->{_note}		= $psmovie->{_note}.' grid1='.$psmovie->{_grid1};
		$psmovie->{_Step}		= $psmovie->{_Step}.' grid1='.$psmovie->{_grid1};

	} else { 
		print("psmovie, grid1, missing grid1,\n");
	 }
 }


=head2 sub grid2 


=cut

 sub grid2 {

	my ( $self,$grid2 )		= @_;
	if ( $grid2 ne $empty_string ) {

		$psmovie->{_grid2}		= $grid2;
		$psmovie->{_note}		= $psmovie->{_note}.' grid2='.$psmovie->{_grid2};
		$psmovie->{_Step}		= $psmovie->{_Step}.' grid2='.$psmovie->{_grid2};

	} else { 
		print("psmovie, grid2, missing grid2,\n");
	 }
 }


=head2 sub hbox 


=cut

 sub hbox {

	my ( $self,$hbox )		= @_;
	if ( $hbox ne $empty_string ) {

		$psmovie->{_hbox}		= $hbox;
		$psmovie->{_note}		= $psmovie->{_note}.' hbox='.$psmovie->{_hbox};
		$psmovie->{_Step}		= $psmovie->{_Step}.' hbox='.$psmovie->{_hbox};

	} else { 
		print("psmovie, hbox, missing hbox,\n");
	 }
 }


=head2 sub label1 


=cut

 sub label1 {

	my ( $self,$label1 )		= @_;
	if ( $label1 ne $empty_string ) {

		$psmovie->{_label1}		= $label1;
		$psmovie->{_note}		= $psmovie->{_note}.' label1='.$psmovie->{_label1};
		$psmovie->{_Step}		= $psmovie->{_Step}.' label1='.$psmovie->{_label1};

	} else { 
		print("psmovie, label1, missing label1,\n");
	 }
 }


=head2 sub label2 


=cut

 sub label2 {

	my ( $self,$label2 )		= @_;
	if ( $label2 ne $empty_string ) {

		$psmovie->{_label2}		= $label2;
		$psmovie->{_note}		= $psmovie->{_note}.' label2='.$psmovie->{_label2};
		$psmovie->{_Step}		= $psmovie->{_Step}.' label2='.$psmovie->{_label2};

	} else { 
		print("psmovie, label2, missing label2,\n");
	 }
 }


=head2 sub labelfont 


=cut

 sub labelfont {

	my ( $self,$labelfont )		= @_;
	if ( $labelfont ne $empty_string ) {

		$psmovie->{_labelfont}		= $labelfont;
		$psmovie->{_note}		= $psmovie->{_note}.' labelfont='.$psmovie->{_labelfont};
		$psmovie->{_Step}		= $psmovie->{_Step}.' labelfont='.$psmovie->{_labelfont};

	} else { 
		print("psmovie, labelfont, missing labelfont,\n");
	 }
 }


=head2 sub labelsize 


=cut

 sub labelsize {

	my ( $self,$labelsize )		= @_;
	if ( $labelsize ne $empty_string ) {

		$psmovie->{_labelsize}		= $labelsize;
		$psmovie->{_note}		= $psmovie->{_note}.' labelsize='.$psmovie->{_labelsize};
		$psmovie->{_Step}		= $psmovie->{_Step}.' labelsize='.$psmovie->{_labelsize};

	} else { 
		print("psmovie, labelsize, missing labelsize,\n");
	 }
 }


=head2 sub loopdsp 


=cut

 sub loopdsp {

	my ( $self,$loopdsp )		= @_;
	if ( $loopdsp ne $empty_string ) {

		$psmovie->{_loopdsp}		= $loopdsp;
		$psmovie->{_note}		= $psmovie->{_note}.' loopdsp='.$psmovie->{_loopdsp};
		$psmovie->{_Step}		= $psmovie->{_Step}.' loopdsp='.$psmovie->{_loopdsp};

	} else { 
		print("psmovie, loopdsp, missing loopdsp,\n");
	 }
 }


=head2 sub n1 


=cut

 sub n1 {

	my ( $self,$n1 )		= @_;
	if ( $n1 ne $empty_string ) {

		$psmovie->{_n1}		= $n1;
		$psmovie->{_note}		= $psmovie->{_note}.' n1='.$psmovie->{_n1};
		$psmovie->{_Step}		= $psmovie->{_Step}.' n1='.$psmovie->{_n1};

	} else { 
		print("psmovie, n1, missing n1,\n");
	 }
 }


=head2 sub n1tic 


=cut

 sub n1tic {

	my ( $self,$n1tic )		= @_;
	if ( $n1tic ne $empty_string ) {

		$psmovie->{_n1tic}		= $n1tic;
		$psmovie->{_note}		= $psmovie->{_note}.' n1tic='.$psmovie->{_n1tic};
		$psmovie->{_Step}		= $psmovie->{_Step}.' n1tic='.$psmovie->{_n1tic};

	} else { 
		print("psmovie, n1tic, missing n1tic,\n");
	 }
 }


=head2 sub n2 


=cut

 sub n2 {

	my ( $self,$n2 )		= @_;
	if ( $n2 ne $empty_string ) {

		$psmovie->{_n2}		= $n2;
		$psmovie->{_note}		= $psmovie->{_note}.' n2='.$psmovie->{_n2};
		$psmovie->{_Step}		= $psmovie->{_Step}.' n2='.$psmovie->{_n2};

	} else { 
		print("psmovie, n2, missing n2,\n");
	 }
 }


=head2 sub n2tic 


=cut

 sub n2tic {

	my ( $self,$n2tic )		= @_;
	if ( $n2tic ne $empty_string ) {

		$psmovie->{_n2tic}		= $n2tic;
		$psmovie->{_note}		= $psmovie->{_note}.' n2tic='.$psmovie->{_n2tic};
		$psmovie->{_Step}		= $psmovie->{_Step}.' n2tic='.$psmovie->{_n2tic};

	} else { 
		print("psmovie, n2tic, missing n2tic,\n");
	 }
 }


=head2 sub n3 


=cut

 sub n3 {

	my ( $self,$n3 )		= @_;
	if ( $n3 ne $empty_string ) {

		$psmovie->{_n3}		= $n3;
		$psmovie->{_note}		= $psmovie->{_note}.' n3='.$psmovie->{_n3};
		$psmovie->{_Step}		= $psmovie->{_Step}.' n3='.$psmovie->{_n3};

	} else { 
		print("psmovie, n3, missing n3,\n");
	 }
 }


=head2 sub perc 


=cut

 sub perc {

	my ( $self,$perc )		= @_;
	if ( $perc ne $empty_string ) {

		$psmovie->{_perc}		= $perc;
		$psmovie->{_note}		= $psmovie->{_note}.' perc='.$psmovie->{_perc};
		$psmovie->{_Step}		= $psmovie->{_Step}.' perc='.$psmovie->{_perc};

	} else { 
		print("psmovie, perc, missing perc,\n");
	 }
 }


=head2 sub style 


=cut

 sub style {

	my ( $self,$style )		= @_;
	if ( $style ne $empty_string ) {

		$psmovie->{_style}		= $style;
		$psmovie->{_note}		= $psmovie->{_note}.' style='.$psmovie->{_style};
		$psmovie->{_Step}		= $psmovie->{_Step}.' style='.$psmovie->{_style};

	} else { 
		print("psmovie, style, missing style,\n");
	 }
 }


=head2 sub title 


=cut

 sub title {

	my ( $self,$title )		= @_;
	if ( $title ne $empty_string ) {

		$psmovie->{_title}		= $title;
		$psmovie->{_note}		= $psmovie->{_note}.' title='.$psmovie->{_title};
		$psmovie->{_Step}		= $psmovie->{_Step}.' title='.$psmovie->{_title};

	} else { 
		print("psmovie, title, missing title,\n");
	 }
 }


=head2 sub title2 


=cut

 sub title2 {

	my ( $self,$title2 )		= @_;
	if ( $title2 ne $empty_string ) {

		$psmovie->{_title2}		= $title2;
		$psmovie->{_note}		= $psmovie->{_note}.' title2='.$psmovie->{_title2};
		$psmovie->{_Step}		= $psmovie->{_Step}.' title2='.$psmovie->{_title2};

	} else { 
		print("psmovie, title2, missing title2,\n");
	 }
 }


=head2 sub titlefont 


=cut

 sub titlefont {

	my ( $self,$titlefont )		= @_;
	if ( $titlefont ne $empty_string ) {

		$psmovie->{_titlefont}		= $titlefont;
		$psmovie->{_note}		= $psmovie->{_note}.' titlefont='.$psmovie->{_titlefont};
		$psmovie->{_Step}		= $psmovie->{_Step}.' titlefont='.$psmovie->{_titlefont};

	} else { 
		print("psmovie, titlefont, missing titlefont,\n");
	 }
 }


=head2 sub titlesize 


=cut

 sub titlesize {

	my ( $self,$titlesize )		= @_;
	if ( $titlesize ne $empty_string ) {

		$psmovie->{_titlesize}		= $titlesize;
		$psmovie->{_note}		= $psmovie->{_note}.' titlesize='.$psmovie->{_titlesize};
		$psmovie->{_Step}		= $psmovie->{_Step}.' titlesize='.$psmovie->{_titlesize};

	} else { 
		print("psmovie, titlesize, missing titlesize,\n");
	 }
 }


=head2 sub verbose 


=cut

 sub verbose {

	my ( $self,$verbose )		= @_;
	if ( $verbose ne $empty_string ) {

		$psmovie->{_verbose}		= $verbose;
		$psmovie->{_note}		= $psmovie->{_note}.' verbose='.$psmovie->{_verbose};
		$psmovie->{_Step}		= $psmovie->{_Step}.' verbose='.$psmovie->{_verbose};

	} else { 
		print("psmovie, verbose, missing verbose,\n");
	 }
 }


=head2 sub wbox 


=cut

 sub wbox {

	my ( $self,$wbox )		= @_;
	if ( $wbox ne $empty_string ) {

		$psmovie->{_wbox}		= $wbox;
		$psmovie->{_note}		= $psmovie->{_note}.' wbox='.$psmovie->{_wbox};
		$psmovie->{_Step}		= $psmovie->{_Step}.' wbox='.$psmovie->{_wbox};

	} else { 
		print("psmovie, wbox, missing wbox,\n");
	 }
 }


=head2 sub wclip 


=cut

 sub wclip {

	my ( $self,$wclip )		= @_;
	if ( $wclip ne $empty_string ) {

		$psmovie->{_wclip}		= $wclip;
		$psmovie->{_note}		= $psmovie->{_note}.' wclip='.$psmovie->{_wclip};
		$psmovie->{_Step}		= $psmovie->{_Step}.' wclip='.$psmovie->{_wclip};

	} else { 
		print("psmovie, wclip, missing wclip,\n");
	 }
 }


=head2 sub wperc 


=cut

 sub wperc {

	my ( $self,$wperc )		= @_;
	if ( $wperc ne $empty_string ) {

		$psmovie->{_wperc}		= $wperc;
		$psmovie->{_note}		= $psmovie->{_note}.' wperc='.$psmovie->{_wperc};
		$psmovie->{_Step}		= $psmovie->{_Step}.' wperc='.$psmovie->{_wperc};

	} else { 
		print("psmovie, wperc, missing wperc,\n");
	 }
 }


=head2 sub x1beg 


=cut

 sub x1beg {

	my ( $self,$x1beg )		= @_;
	if ( $x1beg ne $empty_string ) {

		$psmovie->{_x1beg}		= $x1beg;
		$psmovie->{_note}		= $psmovie->{_note}.' x1beg='.$psmovie->{_x1beg};
		$psmovie->{_Step}		= $psmovie->{_Step}.' x1beg='.$psmovie->{_x1beg};

	} else { 
		print("psmovie, x1beg, missing x1beg,\n");
	 }
 }


=head2 sub x1end 


=cut

 sub x1end {

	my ( $self,$x1end )		= @_;
	if ( $x1end ne $empty_string ) {

		$psmovie->{_x1end}		= $x1end;
		$psmovie->{_note}		= $psmovie->{_note}.' x1end='.$psmovie->{_x1end};
		$psmovie->{_Step}		= $psmovie->{_Step}.' x1end='.$psmovie->{_x1end};

	} else { 
		print("psmovie, x1end, missing x1end,\n");
	 }
 }


=head2 sub x2beg 


=cut

 sub x2beg {

	my ( $self,$x2beg )		= @_;
	if ( $x2beg ne $empty_string ) {

		$psmovie->{_x2beg}		= $x2beg;
		$psmovie->{_note}		= $psmovie->{_note}.' x2beg='.$psmovie->{_x2beg};
		$psmovie->{_Step}		= $psmovie->{_Step}.' x2beg='.$psmovie->{_x2beg};

	} else { 
		print("psmovie, x2beg, missing x2beg,\n");
	 }
 }


=head2 sub x2end 


=cut

 sub x2end {

	my ( $self,$x2end )		= @_;
	if ( $x2end ne $empty_string ) {

		$psmovie->{_x2end}		= $x2end;
		$psmovie->{_note}		= $psmovie->{_note}.' x2end='.$psmovie->{_x2end};
		$psmovie->{_Step}		= $psmovie->{_Step}.' x2end='.$psmovie->{_x2end};

	} else { 
		print("psmovie, x2end, missing x2end,\n");
	 }
 }


=head2 sub xbox 


=cut

 sub xbox {

	my ( $self,$xbox )		= @_;
	if ( $xbox ne $empty_string ) {

		$psmovie->{_xbox}		= $xbox;
		$psmovie->{_note}		= $psmovie->{_note}.' xbox='.$psmovie->{_xbox};
		$psmovie->{_Step}		= $psmovie->{_Step}.' xbox='.$psmovie->{_xbox};

	} else { 
		print("psmovie, xbox, missing xbox,\n");
	 }
 }


=head2 sub ybox 


=cut

 sub ybox {

	my ( $self,$ybox )		= @_;
	if ( $ybox ne $empty_string ) {

		$psmovie->{_ybox}		= $ybox;
		$psmovie->{_note}		= $psmovie->{_note}.' ybox='.$psmovie->{_ybox};
		$psmovie->{_Step}		= $psmovie->{_Step}.' ybox='.$psmovie->{_ybox};

	} else { 
		print("psmovie, ybox, missing ybox,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 44;

    return($max_index);
}
 
 
1;
