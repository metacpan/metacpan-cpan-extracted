package App::SeismicUnixGui::sunix::plot::spsplot;

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
 SPSPLOT - plot a triangulated sloth function s(x,z) via PostScript	



 spsplot <modelfile >postscriptfile [optional parameters]		



 Optional Parameters:							

 gedge=0.0             gray to draw fixed edges (in interval [0.0,1.0])

 gtri=1.0              gray to draw non-fixed edges of triangles 	

 gmin=0.0              min gray to shade triangles (in interval [0.0,1.0])

 gmax=1.0              max gray to shade triangles (in interval [0.0,1.0])

 sgmin=minimum s(x,z)  s(x,y) corresponding to gmin 			

 sgmax=maximum s(x,z)  s(x,y) corresponding to gmax 			

 xbox=1.5              offset in inches of left side of axes box 	

 ybox=1.5              offset in inches of bottom side of axes box	

 wbox=6.0              width in inches of axes box			

 hbox=8.0              height in inches of axes box			

 xbeg=xmin             value at which x axis begins			

 xend=xmax             value at which x axis ends			

 dxnum=0.0             numbered tic interval on x axis (0.0 for automatic)

 fxnum=xmin            first numbered tic on x axis (used if dxnum not 0.0)

 nxtic=1               number of tics per numbered tic on x axis	

 gridx=none            grid lines on x axis - none, dot, dash, or solid

 labelx=               label on x axis					

 zbeg=zmin             value at which z axis begins			

 zend=zmax             value at which z axis ends			

 dznum=0.0             numbered tic interval on z axis (0.0 for automatic)

 fznum=zmin            first numbered tic on z axis (used if dynum not 0.0)

 nztic=1               number of tics per numbered tic on z axis	

 gridz=none            grid lines on z axis - none, dot, dash, or solid

 labelz=               label on z axis					

 labelfont=Helvetica   font name for axes labels			

 labelsize=12          font size for axes labels			

 title=                title of plot					

 titlefont=Helvetica-Bold  font name for title				

 titlesize=24          font size for title				

 titlecolor=black      color of title					

 axescolor=black       color of axes					

 gridcolor=black       color of grid					

 style=seismic         normal (z axis horizontal, x axis vertical) or	

                       seismic (z axis vertical, x axis horizontal)	



 Note:  A value of gedge or gtri outside the interval [0.0,1.0]	

 results in that class of edge not being drawn.			







 AUTHOR:  Dave Hale, Colorado School of Mines, 10/18/90

 MODIFIED: Craig Artley, Colorado School of Mines, 03/27/94

    Tweaks to improve PostScript header, add basic color support.



 NOTE:  Have observed errors in output when compiled with optimization

    under NEXTSTEP 3.1.  Caveat Emptor.



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

my $spsplot			= {
	_axescolor					=> '',
	_dxnum					=> '',
	_dznum					=> '',
	_fxnum					=> '',
	_fznum					=> '',
	_gedge					=> '',
	_gmax					=> '',
	_gmin					=> '',
	_gridcolor					=> '',
	_gridx					=> '',
	_gridz					=> '',
	_gtri					=> '',
	_hbox					=> '',
	_labelfont					=> '',
	_labelsize					=> '',
	_labelx					=> '',
	_labelz					=> '',
	_nxtic					=> '',
	_nztic					=> '',
	_sgmax					=> '',
	_sgmin					=> '',
	_style					=> '',
	_title					=> '',
	_titlecolor					=> '',
	_titlefont					=> '',
	_titlesize					=> '',
	_wbox					=> '',
	_xbeg					=> '',
	_xbox					=> '',
	_xend					=> '',
	_ybox					=> '',
	_zbeg					=> '',
	_zend					=> '',
	_Step					=> '',
	_note					=> '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  Step {

	$spsplot->{_Step}     = 'spsplot'.$spsplot->{_Step};
	return ( $spsplot->{_Step} );

 }


=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

 sub  note {

	$spsplot->{_note}     = 'spsplot'.$spsplot->{_note};
	return ( $spsplot->{_note} );

 }



=head2 sub clear

=cut

 sub clear {

		$spsplot->{_axescolor}			= '';
		$spsplot->{_dxnum}			= '';
		$spsplot->{_dznum}			= '';
		$spsplot->{_fxnum}			= '';
		$spsplot->{_fznum}			= '';
		$spsplot->{_gedge}			= '';
		$spsplot->{_gmax}			= '';
		$spsplot->{_gmin}			= '';
		$spsplot->{_gridcolor}			= '';
		$spsplot->{_gridx}			= '';
		$spsplot->{_gridz}			= '';
		$spsplot->{_gtri}			= '';
		$spsplot->{_hbox}			= '';
		$spsplot->{_labelfont}			= '';
		$spsplot->{_labelsize}			= '';
		$spsplot->{_labelx}			= '';
		$spsplot->{_labelz}			= '';
		$spsplot->{_nxtic}			= '';
		$spsplot->{_nztic}			= '';
		$spsplot->{_sgmax}			= '';
		$spsplot->{_sgmin}			= '';
		$spsplot->{_style}			= '';
		$spsplot->{_title}			= '';
		$spsplot->{_titlecolor}			= '';
		$spsplot->{_titlefont}			= '';
		$spsplot->{_titlesize}			= '';
		$spsplot->{_wbox}			= '';
		$spsplot->{_xbeg}			= '';
		$spsplot->{_xbox}			= '';
		$spsplot->{_xend}			= '';
		$spsplot->{_ybox}			= '';
		$spsplot->{_zbeg}			= '';
		$spsplot->{_zend}			= '';
		$spsplot->{_Step}			= '';
		$spsplot->{_note}			= '';
 }


=head2 sub axescolor 


=cut

 sub axescolor {

	my ( $self,$axescolor )		= @_;
	if ( $axescolor ne $empty_string ) {

		$spsplot->{_axescolor}		= $axescolor;
		$spsplot->{_note}		= $spsplot->{_note}.' axescolor='.$spsplot->{_axescolor};
		$spsplot->{_Step}		= $spsplot->{_Step}.' axescolor='.$spsplot->{_axescolor};

	} else { 
		print("spsplot, axescolor, missing axescolor,\n");
	 }
 }


=head2 sub dxnum 


=cut

 sub dxnum {

	my ( $self,$dxnum )		= @_;
	if ( $dxnum ne $empty_string ) {

		$spsplot->{_dxnum}		= $dxnum;
		$spsplot->{_note}		= $spsplot->{_note}.' dxnum='.$spsplot->{_dxnum};
		$spsplot->{_Step}		= $spsplot->{_Step}.' dxnum='.$spsplot->{_dxnum};

	} else { 
		print("spsplot, dxnum, missing dxnum,\n");
	 }
 }


=head2 sub dznum 


=cut

 sub dznum {

	my ( $self,$dznum )		= @_;
	if ( $dznum ne $empty_string ) {

		$spsplot->{_dznum}		= $dznum;
		$spsplot->{_note}		= $spsplot->{_note}.' dznum='.$spsplot->{_dznum};
		$spsplot->{_Step}		= $spsplot->{_Step}.' dznum='.$spsplot->{_dznum};

	} else { 
		print("spsplot, dznum, missing dznum,\n");
	 }
 }


=head2 sub fxnum 


=cut

 sub fxnum {

	my ( $self,$fxnum )		= @_;
	if ( $fxnum ne $empty_string ) {

		$spsplot->{_fxnum}		= $fxnum;
		$spsplot->{_note}		= $spsplot->{_note}.' fxnum='.$spsplot->{_fxnum};
		$spsplot->{_Step}		= $spsplot->{_Step}.' fxnum='.$spsplot->{_fxnum};

	} else { 
		print("spsplot, fxnum, missing fxnum,\n");
	 }
 }


=head2 sub fznum 


=cut

 sub fznum {

	my ( $self,$fznum )		= @_;
	if ( $fznum ne $empty_string ) {

		$spsplot->{_fznum}		= $fznum;
		$spsplot->{_note}		= $spsplot->{_note}.' fznum='.$spsplot->{_fznum};
		$spsplot->{_Step}		= $spsplot->{_Step}.' fznum='.$spsplot->{_fznum};

	} else { 
		print("spsplot, fznum, missing fznum,\n");
	 }
 }


=head2 sub gedge 


=cut

 sub gedge {

	my ( $self,$gedge )		= @_;
	if ( $gedge ne $empty_string ) {

		$spsplot->{_gedge}		= $gedge;
		$spsplot->{_note}		= $spsplot->{_note}.' gedge='.$spsplot->{_gedge};
		$spsplot->{_Step}		= $spsplot->{_Step}.' gedge='.$spsplot->{_gedge};

	} else { 
		print("spsplot, gedge, missing gedge,\n");
	 }
 }


=head2 sub gmax 


=cut

 sub gmax {

	my ( $self,$gmax )		= @_;
	if ( $gmax ne $empty_string ) {

		$spsplot->{_gmax}		= $gmax;
		$spsplot->{_note}		= $spsplot->{_note}.' gmax='.$spsplot->{_gmax};
		$spsplot->{_Step}		= $spsplot->{_Step}.' gmax='.$spsplot->{_gmax};

	} else { 
		print("spsplot, gmax, missing gmax,\n");
	 }
 }


=head2 sub gmin 


=cut

 sub gmin {

	my ( $self,$gmin )		= @_;
	if ( $gmin ne $empty_string ) {

		$spsplot->{_gmin}		= $gmin;
		$spsplot->{_note}		= $spsplot->{_note}.' gmin='.$spsplot->{_gmin};
		$spsplot->{_Step}		= $spsplot->{_Step}.' gmin='.$spsplot->{_gmin};

	} else { 
		print("spsplot, gmin, missing gmin,\n");
	 }
 }


=head2 sub gridcolor 


=cut

 sub gridcolor {

	my ( $self,$gridcolor )		= @_;
	if ( $gridcolor ne $empty_string ) {

		$spsplot->{_gridcolor}		= $gridcolor;
		$spsplot->{_note}		= $spsplot->{_note}.' gridcolor='.$spsplot->{_gridcolor};
		$spsplot->{_Step}		= $spsplot->{_Step}.' gridcolor='.$spsplot->{_gridcolor};

	} else { 
		print("spsplot, gridcolor, missing gridcolor,\n");
	 }
 }


=head2 sub gridx 


=cut

 sub gridx {

	my ( $self,$gridx )		= @_;
	if ( $gridx ne $empty_string ) {

		$spsplot->{_gridx}		= $gridx;
		$spsplot->{_note}		= $spsplot->{_note}.' gridx='.$spsplot->{_gridx};
		$spsplot->{_Step}		= $spsplot->{_Step}.' gridx='.$spsplot->{_gridx};

	} else { 
		print("spsplot, gridx, missing gridx,\n");
	 }
 }


=head2 sub gridz 


=cut

 sub gridz {

	my ( $self,$gridz )		= @_;
	if ( $gridz ne $empty_string ) {

		$spsplot->{_gridz}		= $gridz;
		$spsplot->{_note}		= $spsplot->{_note}.' gridz='.$spsplot->{_gridz};
		$spsplot->{_Step}		= $spsplot->{_Step}.' gridz='.$spsplot->{_gridz};

	} else { 
		print("spsplot, gridz, missing gridz,\n");
	 }
 }


=head2 sub gtri 


=cut

 sub gtri {

	my ( $self,$gtri )		= @_;
	if ( $gtri ne $empty_string ) {

		$spsplot->{_gtri}		= $gtri;
		$spsplot->{_note}		= $spsplot->{_note}.' gtri='.$spsplot->{_gtri};
		$spsplot->{_Step}		= $spsplot->{_Step}.' gtri='.$spsplot->{_gtri};

	} else { 
		print("spsplot, gtri, missing gtri,\n");
	 }
 }


=head2 sub hbox 


=cut

 sub hbox {

	my ( $self,$hbox )		= @_;
	if ( $hbox ne $empty_string ) {

		$spsplot->{_hbox}		= $hbox;
		$spsplot->{_note}		= $spsplot->{_note}.' hbox='.$spsplot->{_hbox};
		$spsplot->{_Step}		= $spsplot->{_Step}.' hbox='.$spsplot->{_hbox};

	} else { 
		print("spsplot, hbox, missing hbox,\n");
	 }
 }


=head2 sub labelfont 


=cut

 sub labelfont {

	my ( $self,$labelfont )		= @_;
	if ( $labelfont ne $empty_string ) {

		$spsplot->{_labelfont}		= $labelfont;
		$spsplot->{_note}		= $spsplot->{_note}.' labelfont='.$spsplot->{_labelfont};
		$spsplot->{_Step}		= $spsplot->{_Step}.' labelfont='.$spsplot->{_labelfont};

	} else { 
		print("spsplot, labelfont, missing labelfont,\n");
	 }
 }


=head2 sub labelsize 


=cut

 sub labelsize {

	my ( $self,$labelsize )		= @_;
	if ( $labelsize ne $empty_string ) {

		$spsplot->{_labelsize}		= $labelsize;
		$spsplot->{_note}		= $spsplot->{_note}.' labelsize='.$spsplot->{_labelsize};
		$spsplot->{_Step}		= $spsplot->{_Step}.' labelsize='.$spsplot->{_labelsize};

	} else { 
		print("spsplot, labelsize, missing labelsize,\n");
	 }
 }


=head2 sub labelx 


=cut

 sub labelx {

	my ( $self,$labelx )		= @_;
	if ( $labelx ne $empty_string ) {

		$spsplot->{_labelx}		= $labelx;
		$spsplot->{_note}		= $spsplot->{_note}.' labelx='.$spsplot->{_labelx};
		$spsplot->{_Step}		= $spsplot->{_Step}.' labelx='.$spsplot->{_labelx};

	} else { 
		print("spsplot, labelx, missing labelx,\n");
	 }
 }


=head2 sub labelz 


=cut

 sub labelz {

	my ( $self,$labelz )		= @_;
	if ( $labelz ne $empty_string ) {

		$spsplot->{_labelz}		= $labelz;
		$spsplot->{_note}		= $spsplot->{_note}.' labelz='.$spsplot->{_labelz};
		$spsplot->{_Step}		= $spsplot->{_Step}.' labelz='.$spsplot->{_labelz};

	} else { 
		print("spsplot, labelz, missing labelz,\n");
	 }
 }


=head2 sub nxtic 


=cut

 sub nxtic {

	my ( $self,$nxtic )		= @_;
	if ( $nxtic ne $empty_string ) {

		$spsplot->{_nxtic}		= $nxtic;
		$spsplot->{_note}		= $spsplot->{_note}.' nxtic='.$spsplot->{_nxtic};
		$spsplot->{_Step}		= $spsplot->{_Step}.' nxtic='.$spsplot->{_nxtic};

	} else { 
		print("spsplot, nxtic, missing nxtic,\n");
	 }
 }


=head2 sub nztic 


=cut

 sub nztic {

	my ( $self,$nztic )		= @_;
	if ( $nztic ne $empty_string ) {

		$spsplot->{_nztic}		= $nztic;
		$spsplot->{_note}		= $spsplot->{_note}.' nztic='.$spsplot->{_nztic};
		$spsplot->{_Step}		= $spsplot->{_Step}.' nztic='.$spsplot->{_nztic};

	} else { 
		print("spsplot, nztic, missing nztic,\n");
	 }
 }


=head2 sub sgmax 


=cut

 sub sgmax {

	my ( $self,$sgmax )		= @_;
	if ( $sgmax ne $empty_string ) {

		$spsplot->{_sgmax}		= $sgmax;
		$spsplot->{_note}		= $spsplot->{_note}.' sgmax='.$spsplot->{_sgmax};
		$spsplot->{_Step}		= $spsplot->{_Step}.' sgmax='.$spsplot->{_sgmax};

	} else { 
		print("spsplot, sgmax, missing sgmax,\n");
	 }
 }


=head2 sub sgmin 


=cut

 sub sgmin {

	my ( $self,$sgmin )		= @_;
	if ( $sgmin ne $empty_string ) {

		$spsplot->{_sgmin}		= $sgmin;
		$spsplot->{_note}		= $spsplot->{_note}.' sgmin='.$spsplot->{_sgmin};
		$spsplot->{_Step}		= $spsplot->{_Step}.' sgmin='.$spsplot->{_sgmin};

	} else { 
		print("spsplot, sgmin, missing sgmin,\n");
	 }
 }


=head2 sub style 


=cut

 sub style {

	my ( $self,$style )		= @_;
	if ( $style ne $empty_string ) {

		$spsplot->{_style}		= $style;
		$spsplot->{_note}		= $spsplot->{_note}.' style='.$spsplot->{_style};
		$spsplot->{_Step}		= $spsplot->{_Step}.' style='.$spsplot->{_style};

	} else { 
		print("spsplot, style, missing style,\n");
	 }
 }


=head2 sub title 


=cut

 sub title {

	my ( $self,$title )		= @_;
	if ( $title ne $empty_string ) {

		$spsplot->{_title}		= $title;
		$spsplot->{_note}		= $spsplot->{_note}.' title='.$spsplot->{_title};
		$spsplot->{_Step}		= $spsplot->{_Step}.' title='.$spsplot->{_title};

	} else { 
		print("spsplot, title, missing title,\n");
	 }
 }


=head2 sub titlecolor 


=cut

 sub titlecolor {

	my ( $self,$titlecolor )		= @_;
	if ( $titlecolor ne $empty_string ) {

		$spsplot->{_titlecolor}		= $titlecolor;
		$spsplot->{_note}		= $spsplot->{_note}.' titlecolor='.$spsplot->{_titlecolor};
		$spsplot->{_Step}		= $spsplot->{_Step}.' titlecolor='.$spsplot->{_titlecolor};

	} else { 
		print("spsplot, titlecolor, missing titlecolor,\n");
	 }
 }


=head2 sub titlefont 


=cut

 sub titlefont {

	my ( $self,$titlefont )		= @_;
	if ( $titlefont ne $empty_string ) {

		$spsplot->{_titlefont}		= $titlefont;
		$spsplot->{_note}		= $spsplot->{_note}.' titlefont='.$spsplot->{_titlefont};
		$spsplot->{_Step}		= $spsplot->{_Step}.' titlefont='.$spsplot->{_titlefont};

	} else { 
		print("spsplot, titlefont, missing titlefont,\n");
	 }
 }


=head2 sub titlesize 


=cut

 sub titlesize {

	my ( $self,$titlesize )		= @_;
	if ( $titlesize ne $empty_string ) {

		$spsplot->{_titlesize}		= $titlesize;
		$spsplot->{_note}		= $spsplot->{_note}.' titlesize='.$spsplot->{_titlesize};
		$spsplot->{_Step}		= $spsplot->{_Step}.' titlesize='.$spsplot->{_titlesize};

	} else { 
		print("spsplot, titlesize, missing titlesize,\n");
	 }
 }


=head2 sub wbox 


=cut

 sub wbox {

	my ( $self,$wbox )		= @_;
	if ( $wbox ne $empty_string ) {

		$spsplot->{_wbox}		= $wbox;
		$spsplot->{_note}		= $spsplot->{_note}.' wbox='.$spsplot->{_wbox};
		$spsplot->{_Step}		= $spsplot->{_Step}.' wbox='.$spsplot->{_wbox};

	} else { 
		print("spsplot, wbox, missing wbox,\n");
	 }
 }


=head2 sub xbeg 


=cut

 sub xbeg {

	my ( $self,$xbeg )		= @_;
	if ( $xbeg ne $empty_string ) {

		$spsplot->{_xbeg}		= $xbeg;
		$spsplot->{_note}		= $spsplot->{_note}.' xbeg='.$spsplot->{_xbeg};
		$spsplot->{_Step}		= $spsplot->{_Step}.' xbeg='.$spsplot->{_xbeg};

	} else { 
		print("spsplot, xbeg, missing xbeg,\n");
	 }
 }


=head2 sub xbox 


=cut

 sub xbox {

	my ( $self,$xbox )		= @_;
	if ( $xbox ne $empty_string ) {

		$spsplot->{_xbox}		= $xbox;
		$spsplot->{_note}		= $spsplot->{_note}.' xbox='.$spsplot->{_xbox};
		$spsplot->{_Step}		= $spsplot->{_Step}.' xbox='.$spsplot->{_xbox};

	} else { 
		print("spsplot, xbox, missing xbox,\n");
	 }
 }


=head2 sub xend 


=cut

 sub xend {

	my ( $self,$xend )		= @_;
	if ( $xend ne $empty_string ) {

		$spsplot->{_xend}		= $xend;
		$spsplot->{_note}		= $spsplot->{_note}.' xend='.$spsplot->{_xend};
		$spsplot->{_Step}		= $spsplot->{_Step}.' xend='.$spsplot->{_xend};

	} else { 
		print("spsplot, xend, missing xend,\n");
	 }
 }


=head2 sub ybox 


=cut

 sub ybox {

	my ( $self,$ybox )		= @_;
	if ( $ybox ne $empty_string ) {

		$spsplot->{_ybox}		= $ybox;
		$spsplot->{_note}		= $spsplot->{_note}.' ybox='.$spsplot->{_ybox};
		$spsplot->{_Step}		= $spsplot->{_Step}.' ybox='.$spsplot->{_ybox};

	} else { 
		print("spsplot, ybox, missing ybox,\n");
	 }
 }


=head2 sub zbeg 


=cut

 sub zbeg {

	my ( $self,$zbeg )		= @_;
	if ( $zbeg ne $empty_string ) {

		$spsplot->{_zbeg}		= $zbeg;
		$spsplot->{_note}		= $spsplot->{_note}.' zbeg='.$spsplot->{_zbeg};
		$spsplot->{_Step}		= $spsplot->{_Step}.' zbeg='.$spsplot->{_zbeg};

	} else { 
		print("spsplot, zbeg, missing zbeg,\n");
	 }
 }


=head2 sub zend 


=cut

 sub zend {

	my ( $self,$zend )		= @_;
	if ( $zend ne $empty_string ) {

		$spsplot->{_zend}		= $zend;
		$spsplot->{_note}		= $spsplot->{_note}.' zend='.$spsplot->{_zend};
		$spsplot->{_Step}		= $spsplot->{_Step}.' zend='.$spsplot->{_zend};

	} else { 
		print("spsplot, zend, missing zend,\n");
	 }
 }


=head2 sub get_max_index

max index = number of input variables -1
 
=cut
 
sub get_max_index {
 	  my ($self) = @_;
	my $max_index = 32;

    return($max_index);
}
 
 
1;
