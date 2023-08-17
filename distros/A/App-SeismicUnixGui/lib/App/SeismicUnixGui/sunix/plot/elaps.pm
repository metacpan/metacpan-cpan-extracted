package App::SeismicUnixGui::sunix::plot::elaps;

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
 ELAPS - plot a triangulated function p(x,z) via PostScript 		



 elaps <modelfile >postscriptfile [optional parameters] 		



 Optional Parameters: 							

 p=0			plot sqrt(a3333) (vertical P-wave velocity)	",	

 		     =1 plot sqrt(a1313)(vertical S-wave velocity)	

 		     =2 plot (v_Ph-v_Pv)/v_Pv

                    =3 plot (a1212-a1313)/(2*a1313) = gamma            

 gedge=0.0		gray to draw fixed edges (in interval [0.0,1.0])

 gtri=1.0		gray to draw non-fixed edges of triangles 	

			   put negative number for not drawing  	

 gmin=0.0		min gray to shade triangles (in interval [0.0,1.0])

 gmax=1.0		max gray to shade triangles (in interval [0.0,1.0])

 pgmin=minimum p(x,z)	p(x,y)-value corresponding to gmin 		

 pgmax=maximum p(x,z)	p(x,y)-value corresponding to gmax 		

 xbox=1.5		offset in inches of left side of axes box 	

 ybox=1.5		offset in inches of bottom side of axes box	

 wbox=6.0		width in inches of axes box			

 hbox=8.0		height in inches of axes box			

 xbeg=xmin		value at which x axis begins			

 xend=xmax		value at which x axis ends			

 dxnum=0.0		numbered tic interval on x axis (0.0 for automatic)

 fxnum=xmin		first numbered tic on x axis (used if dxnum not 0.0)

 nxtic=1		number of tics per numbered tic on x axis	

 gridx=none		grid lines on x axis - none, dot, dash, or solid

 labelx=		label on x axis					

 zbeg=zmin		value at which z axis begins			

 zend=zmax		value at which z axis ends			

 dznum=0.0		numbered tic interval on z axis (0.0 for automatic)

 fznum=zmin		first numbered tic on z axis (used if dynum not 0.0)

 nztic=1		number of tics per numbered tic on z axis	

 gridz=none		grid lines on z axis - none, dot, dash, or solid

 labelz=		label on z axis					

 labelfont=Helvetica	font name for axes labels			

 labelsize=12		font size for axes labels			

 title=		title of plot					

 titlecolor=black      color of title                                  

 axescolor=black       color of axes                                   

 gridcolor=black       color of grid                                   ",    

 titlefont=Helvetica-Bold font name for title				

 titlesize=24		font size for title				

 style=seismic	  normal (z axis horizontal, x axis vertical) or	

			seismic (z axis vertical, x axis horizontal)	







 AUTHOR:  Dave Hale, Colorado School of Mines, 10/18/90

 modified: Andreas Rueger, Colorado School of Mines, 01/25/94





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

my $elaps = {
	_axescolor  => '',
	_dxnum      => '',
	_dznum      => '',
	_fxnum      => '',
	_fznum      => '',
	_gedge      => '',
	_gmax       => '',
	_gmin       => '',
	_gridcolor  => '',
	_gridx      => '',
	_gridz      => '',
	_gtri       => '',
	_hbox       => '',
	_labelfont  => '',
	_labelsize  => '',
	_labelx     => '',
	_labelz     => '',
	_nxtic      => '',
	_nztic      => '',
	_p          => '',
	_pgmax      => '',
	_pgmin      => '',
	_style      => '',
	_title      => '',
	_titlecolor => '',
	_titlefont  => '',
	_titlesize  => '',
	_wbox       => '',
	_xbeg       => '',
	_xbox       => '',
	_xend       => '',
	_ybox       => '',
	_zbeg       => '',
	_zend       => '',
	_Step       => '',
	_note       => '',

};

=head2 sub Step

collects switches and assembles bash instructions
by adding the program name

=cut

sub Step {

	$elaps->{_Step} = 'elaps' . $elaps->{_Step};
	return ( $elaps->{_Step} );

}

=head2 sub note

collects switches and assembles bash instructions
by adding the program name

=cut

sub note {

	$elaps->{_note} = 'elaps' . $elaps->{_note};
	return ( $elaps->{_note} );

}

=head2 sub clear

=cut

sub clear {

	$elaps->{_axescolor}  = '';
	$elaps->{_dxnum}      = '';
	$elaps->{_dznum}      = '';
	$elaps->{_fxnum}      = '';
	$elaps->{_fznum}      = '';
	$elaps->{_gedge}      = '';
	$elaps->{_gmax}       = '';
	$elaps->{_gmin}       = '';
	$elaps->{_gridcolor}  = '';
	$elaps->{_gridx}      = '';
	$elaps->{_gridz}      = '';
	$elaps->{_gtri}       = '';
	$elaps->{_hbox}       = '';
	$elaps->{_labelfont}  = '';
	$elaps->{_labelsize}  = '';
	$elaps->{_labelx}     = '';
	$elaps->{_labelz}     = '';
	$elaps->{_nxtic}      = '';
	$elaps->{_nztic}      = '';
	$elaps->{_p}          = '';
	$elaps->{_pgmax}      = '';
	$elaps->{_pgmin}      = '';
	$elaps->{_style}      = '';
	$elaps->{_title}      = '';
	$elaps->{_titlecolor} = '';
	$elaps->{_titlefont}  = '';
	$elaps->{_titlesize}  = '';
	$elaps->{_wbox}       = '';
	$elaps->{_xbeg}       = '';
	$elaps->{_xbox}       = '';
	$elaps->{_xend}       = '';
	$elaps->{_ybox}       = '';
	$elaps->{_zbeg}       = '';
	$elaps->{_zend}       = '';
	$elaps->{_Step}       = '';
	$elaps->{_note}       = '';
}

=head2 sub axescolor 


=cut

sub axescolor {

	my ( $self, $axescolor ) = @_;
	if ( $axescolor ne $empty_string ) {

		$elaps->{_axescolor} = $axescolor;
		$elaps->{_note} =
		  $elaps->{_note} . ' axescolor=' . $elaps->{_axescolor};
		$elaps->{_Step} =
		  $elaps->{_Step} . ' axescolor=' . $elaps->{_axescolor};

	}
	else {
		print("elaps, axescolor, missing axescolor,\n");
	}
}

=head2 sub dxnum 


=cut

sub dxnum {

	my ( $self, $dxnum ) = @_;
	if ( $dxnum ne $empty_string ) {

		$elaps->{_dxnum} = $dxnum;
		$elaps->{_note}  = $elaps->{_note} . ' dxnum=' . $elaps->{_dxnum};
		$elaps->{_Step}  = $elaps->{_Step} . ' dxnum=' . $elaps->{_dxnum};

	}
	else {
		print("elaps, dxnum, missing dxnum,\n");
	}
}

=head2 sub dznum 


=cut

sub dznum {

	my ( $self, $dznum ) = @_;
	if ( $dznum ne $empty_string ) {

		$elaps->{_dznum} = $dznum;
		$elaps->{_note}  = $elaps->{_note} . ' dznum=' . $elaps->{_dznum};
		$elaps->{_Step}  = $elaps->{_Step} . ' dznum=' . $elaps->{_dznum};

	}
	else {
		print("elaps, dznum, missing dznum,\n");
	}
}

=head2 sub fxnum 


=cut

sub fxnum {

	my ( $self, $fxnum ) = @_;
	if ( $fxnum ne $empty_string ) {

		$elaps->{_fxnum} = $fxnum;
		$elaps->{_note}  = $elaps->{_note} . ' fxnum=' . $elaps->{_fxnum};
		$elaps->{_Step}  = $elaps->{_Step} . ' fxnum=' . $elaps->{_fxnum};

	}
	else {
		print("elaps, fxnum, missing fxnum,\n");
	}
}

=head2 sub fznum 


=cut

sub fznum {

	my ( $self, $fznum ) = @_;
	if ( $fznum ne $empty_string ) {

		$elaps->{_fznum} = $fznum;
		$elaps->{_note}  = $elaps->{_note} . ' fznum=' . $elaps->{_fznum};
		$elaps->{_Step}  = $elaps->{_Step} . ' fznum=' . $elaps->{_fznum};

	}
	else {
		print("elaps, fznum, missing fznum,\n");
	}
}

=head2 sub gedge 


=cut

sub gedge {

	my ( $self, $gedge ) = @_;
	if ( $gedge ne $empty_string ) {

		$elaps->{_gedge} = $gedge;
		$elaps->{_note}  = $elaps->{_note} . ' gedge=' . $elaps->{_gedge};
		$elaps->{_Step}  = $elaps->{_Step} . ' gedge=' . $elaps->{_gedge};

	}
	else {
		print("elaps, gedge, missing gedge,\n");
	}
}

=head2 sub gmax 


=cut

sub gmax {

	my ( $self, $gmax ) = @_;
	if ( $gmax ne $empty_string ) {

		$elaps->{_gmax} = $gmax;
		$elaps->{_note} = $elaps->{_note} . ' gmax=' . $elaps->{_gmax};
		$elaps->{_Step} = $elaps->{_Step} . ' gmax=' . $elaps->{_gmax};

	}
	else {
		print("elaps, gmax, missing gmax,\n");
	}
}

=head2 sub gmin 


=cut

sub gmin {

	my ( $self, $gmin ) = @_;
	if ( $gmin ne $empty_string ) {

		$elaps->{_gmin} = $gmin;
		$elaps->{_note} = $elaps->{_note} . ' gmin=' . $elaps->{_gmin};
		$elaps->{_Step} = $elaps->{_Step} . ' gmin=' . $elaps->{_gmin};

	}
	else {
		print("elaps, gmin, missing gmin,\n");
	}
}

=head2 sub gridcolor 


=cut

sub gridcolor {

	my ( $self, $gridcolor ) = @_;
	if ( $gridcolor ne $empty_string ) {

		$elaps->{_gridcolor} = $gridcolor;
		$elaps->{_note} =
		  $elaps->{_note} . ' gridcolor=' . $elaps->{_gridcolor};
		$elaps->{_Step} =
		  $elaps->{_Step} . ' gridcolor=' . $elaps->{_gridcolor};

	}
	else {
		print("elaps, gridcolor, missing gridcolor,\n");
	}
}

=head2 sub gridx 


=cut

sub gridx {

	my ( $self, $gridx ) = @_;
	if ( $gridx ne $empty_string ) {

		$elaps->{_gridx} = $gridx;
		$elaps->{_note}  = $elaps->{_note} . ' gridx=' . $elaps->{_gridx};
		$elaps->{_Step}  = $elaps->{_Step} . ' gridx=' . $elaps->{_gridx};

	}
	else {
		print("elaps, gridx, missing gridx,\n");
	}
}

=head2 sub gridz 


=cut

sub gridz {

	my ( $self, $gridz ) = @_;
	if ( $gridz ne $empty_string ) {

		$elaps->{_gridz} = $gridz;
		$elaps->{_note}  = $elaps->{_note} . ' gridz=' . $elaps->{_gridz};
		$elaps->{_Step}  = $elaps->{_Step} . ' gridz=' . $elaps->{_gridz};

	}
	else {
		print("elaps, gridz, missing gridz,\n");
	}
}

=head2 sub gtri 


=cut

sub gtri {

	my ( $self, $gtri ) = @_;
	if ( $gtri ne $empty_string ) {

		$elaps->{_gtri} = $gtri;
		$elaps->{_note} = $elaps->{_note} . ' gtri=' . $elaps->{_gtri};
		$elaps->{_Step} = $elaps->{_Step} . ' gtri=' . $elaps->{_gtri};

	}
	else {
		print("elaps, gtri, missing gtri,\n");
	}
}

=head2 sub hbox 


=cut

sub hbox {

	my ( $self, $hbox ) = @_;
	if ( $hbox ne $empty_string ) {

		$elaps->{_hbox} = $hbox;
		$elaps->{_note} = $elaps->{_note} . ' hbox=' . $elaps->{_hbox};
		$elaps->{_Step} = $elaps->{_Step} . ' hbox=' . $elaps->{_hbox};

	}
	else {
		print("elaps, hbox, missing hbox,\n");
	}
}

=head2 sub labelfont 


=cut

sub labelfont {

	my ( $self, $labelfont ) = @_;
	if ( $labelfont ne $empty_string ) {

		$elaps->{_labelfont} = $labelfont;
		$elaps->{_note} =
		  $elaps->{_note} . ' labelfont=' . $elaps->{_labelfont};
		$elaps->{_Step} =
		  $elaps->{_Step} . ' labelfont=' . $elaps->{_labelfont};

	}
	else {
		print("elaps, labelfont, missing labelfont,\n");
	}
}

=head2 sub labelsize 


=cut

sub labelsize {

	my ( $self, $labelsize ) = @_;
	if ( $labelsize ne $empty_string ) {

		$elaps->{_labelsize} = $labelsize;
		$elaps->{_note} =
		  $elaps->{_note} . ' labelsize=' . $elaps->{_labelsize};
		$elaps->{_Step} =
		  $elaps->{_Step} . ' labelsize=' . $elaps->{_labelsize};

	}
	else {
		print("elaps, labelsize, missing labelsize,\n");
	}
}

=head2 sub labelx 


=cut

sub labelx {

	my ( $self, $labelx ) = @_;
	if ( $labelx ne $empty_string ) {

		$elaps->{_labelx} = $labelx;
		$elaps->{_note}   = $elaps->{_note} . ' labelx=' . $elaps->{_labelx};
		$elaps->{_Step}   = $elaps->{_Step} . ' labelx=' . $elaps->{_labelx};

	}
	else {
		print("elaps, labelx, missing labelx,\n");
	}
}

=head2 sub labelz 


=cut

sub labelz {

	my ( $self, $labelz ) = @_;
	if ( $labelz ne $empty_string ) {

		$elaps->{_labelz} = $labelz;
		$elaps->{_note}   = $elaps->{_note} . ' labelz=' . $elaps->{_labelz};
		$elaps->{_Step}   = $elaps->{_Step} . ' labelz=' . $elaps->{_labelz};

	}
	else {
		print("elaps, labelz, missing labelz,\n");
	}
}

=head2 sub nxtic 


=cut

sub nxtic {

	my ( $self, $nxtic ) = @_;
	if ( $nxtic ne $empty_string ) {

		$elaps->{_nxtic} = $nxtic;
		$elaps->{_note}  = $elaps->{_note} . ' nxtic=' . $elaps->{_nxtic};
		$elaps->{_Step}  = $elaps->{_Step} . ' nxtic=' . $elaps->{_nxtic};

	}
	else {
		print("elaps, nxtic, missing nxtic,\n");
	}
}

=head2 sub nztic 


=cut

sub nztic {

	my ( $self, $nztic ) = @_;
	if ( $nztic ne $empty_string ) {

		$elaps->{_nztic} = $nztic;
		$elaps->{_note}  = $elaps->{_note} . ' nztic=' . $elaps->{_nztic};
		$elaps->{_Step}  = $elaps->{_Step} . ' nztic=' . $elaps->{_nztic};

	}
	else {
		print("elaps, nztic, missing nztic,\n");
	}
}

=head2 sub p 


=cut

sub p {

	my ( $self, $p ) = @_;
	if ( $p ne $empty_string ) {

		$elaps->{_p}    = $p;
		$elaps->{_note} = $elaps->{_note} . ' p=' . $elaps->{_p};
		$elaps->{_Step} = $elaps->{_Step} . ' p=' . $elaps->{_p};

	}
	else {
		print("elaps, p, missing p,\n");
	}
}

=head2 sub pgmax 


=cut

sub pgmax {

	my ( $self, $pgmax ) = @_;
	if ( $pgmax ne $empty_string ) {

		$elaps->{_pgmax} = $pgmax;
		$elaps->{_note}  = $elaps->{_note} . ' pgmax=' . $elaps->{_pgmax};
		$elaps->{_Step}  = $elaps->{_Step} . ' pgmax=' . $elaps->{_pgmax};

	}
	else {
		print("elaps, pgmax, missing pgmax,\n");
	}
}

=head2 sub pgmin 


=cut

sub pgmin {

	my ( $self, $pgmin ) = @_;
	if ( $pgmin ne $empty_string ) {

		$elaps->{_pgmin} = $pgmin;
		$elaps->{_note}  = $elaps->{_note} . ' pgmin=' . $elaps->{_pgmin};
		$elaps->{_Step}  = $elaps->{_Step} . ' pgmin=' . $elaps->{_pgmin};

	}
	else {
		print("elaps, pgmin, missing pgmin,\n");
	}
}

=head2 sub style 


=cut

sub style {

	my ( $self, $style ) = @_;
	if ( $style ne $empty_string ) {

		$elaps->{_style} = $style;
		$elaps->{_note}  = $elaps->{_note} . ' style=' . $elaps->{_style};
		$elaps->{_Step}  = $elaps->{_Step} . ' style=' . $elaps->{_style};

	}
	else {
		print("elaps, style, missing style,\n");
	}
}

=head2 sub title 


=cut

sub title {

	my ( $self, $title ) = @_;
	if ( $title ne $empty_string ) {

		$elaps->{_title} = $title;
		$elaps->{_note}  = $elaps->{_note} . ' title=' . $elaps->{_title};
		$elaps->{_Step}  = $elaps->{_Step} . ' title=' . $elaps->{_title};

	}
	else {
		print("elaps, title, missing title,\n");
	}
}

=head2 sub titlecolor 


=cut

sub titlecolor {

	my ( $self, $titlecolor ) = @_;
	if ( $titlecolor ne $empty_string ) {

		$elaps->{_titlecolor} = $titlecolor;
		$elaps->{_note} =
		  $elaps->{_note} . ' titlecolor=' . $elaps->{_titlecolor};
		$elaps->{_Step} =
		  $elaps->{_Step} . ' titlecolor=' . $elaps->{_titlecolor};

	}
	else {
		print("elaps, titlecolor, missing titlecolor,\n");
	}
}

=head2 sub titlefont 


=cut

sub titlefont {

	my ( $self, $titlefont ) = @_;
	if ( $titlefont ne $empty_string ) {

		$elaps->{_titlefont} = $titlefont;
		$elaps->{_note} =
		  $elaps->{_note} . ' titlefont=' . $elaps->{_titlefont};
		$elaps->{_Step} =
		  $elaps->{_Step} . ' titlefont=' . $elaps->{_titlefont};

	}
	else {
		print("elaps, titlefont, missing titlefont,\n");
	}
}

=head2 sub titlesize 


=cut

sub titlesize {

	my ( $self, $titlesize ) = @_;
	if ( $titlesize ne $empty_string ) {

		$elaps->{_titlesize} = $titlesize;
		$elaps->{_note} =
		  $elaps->{_note} . ' titlesize=' . $elaps->{_titlesize};
		$elaps->{_Step} =
		  $elaps->{_Step} . ' titlesize=' . $elaps->{_titlesize};

	}
	else {
		print("elaps, titlesize, missing titlesize,\n");
	}
}

=head2 sub wbox 


=cut

sub wbox {

	my ( $self, $wbox ) = @_;
	if ( $wbox ne $empty_string ) {

		$elaps->{_wbox} = $wbox;
		$elaps->{_note} = $elaps->{_note} . ' wbox=' . $elaps->{_wbox};
		$elaps->{_Step} = $elaps->{_Step} . ' wbox=' . $elaps->{_wbox};

	}
	else {
		print("elaps, wbox, missing wbox,\n");
	}
}

=head2 sub xbeg 


=cut

sub xbeg {

	my ( $self, $xbeg ) = @_;
	if ( $xbeg ne $empty_string ) {

		$elaps->{_xbeg} = $xbeg;
		$elaps->{_note} = $elaps->{_note} . ' xbeg=' . $elaps->{_xbeg};
		$elaps->{_Step} = $elaps->{_Step} . ' xbeg=' . $elaps->{_xbeg};

	}
	else {
		print("elaps, xbeg, missing xbeg,\n");
	}
}

=head2 sub xbox 


=cut

sub xbox {

	my ( $self, $xbox ) = @_;
	if ( $xbox ne $empty_string ) {

		$elaps->{_xbox} = $xbox;
		$elaps->{_note} = $elaps->{_note} . ' xbox=' . $elaps->{_xbox};
		$elaps->{_Step} = $elaps->{_Step} . ' xbox=' . $elaps->{_xbox};

	}
	else {
		print("elaps, xbox, missing xbox,\n");
	}
}

=head2 sub xend 


=cut

sub xend {

	my ( $self, $xend ) = @_;
	if ( $xend ne $empty_string ) {

		$elaps->{_xend} = $xend;
		$elaps->{_note} = $elaps->{_note} . ' xend=' . $elaps->{_xend};
		$elaps->{_Step} = $elaps->{_Step} . ' xend=' . $elaps->{_xend};

	}
	else {
		print("elaps, xend, missing xend,\n");
	}
}

=head2 sub ybox 


=cut

sub ybox {

	my ( $self, $ybox ) = @_;
	if ( $ybox ne $empty_string ) {

		$elaps->{_ybox} = $ybox;
		$elaps->{_note} = $elaps->{_note} . ' ybox=' . $elaps->{_ybox};
		$elaps->{_Step} = $elaps->{_Step} . ' ybox=' . $elaps->{_ybox};

	}
	else {
		print("elaps, ybox, missing ybox,\n");
	}
}

=head2 sub zbeg 


=cut

sub zbeg {

	my ( $self, $zbeg ) = @_;
	if ( $zbeg ne $empty_string ) {

		$elaps->{_zbeg} = $zbeg;
		$elaps->{_note} = $elaps->{_note} . ' zbeg=' . $elaps->{_zbeg};
		$elaps->{_Step} = $elaps->{_Step} . ' zbeg=' . $elaps->{_zbeg};

	}
	else {
		print("elaps, zbeg, missing zbeg,\n");
	}
}

=head2 sub zend 


=cut

sub zend {

	my ( $self, $zend ) = @_;
	if ( $zend ne $empty_string ) {

		$elaps->{_zend} = $zend;
		$elaps->{_note} = $elaps->{_note} . ' zend=' . $elaps->{_zend};
		$elaps->{_Step} = $elaps->{_Step} . ' zend=' . $elaps->{_zend};

	}
	else {
		print("elaps, zend, missing zend,\n");
	}
}

=head2 sub get_max_index

max index = number of input variables -1
 
=cut

sub get_max_index {
	my ($self) = @_;
	my $max_index = 33;

	return ($max_index);
}

1;
