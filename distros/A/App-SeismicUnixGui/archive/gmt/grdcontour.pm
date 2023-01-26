package App::SeismicUnixGui::gmt::grdcontour;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: grdcontour
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

	grdcontour 4.5.7 [64-bit] - Contouring of 2-D gridded data sets

	usage: grdcontour <grdfile> -C<cont_int> -J<params>
	[-A[-|<annot_int>][<labelinfo>] [-B<params>] [-D<dumpfile>] [-E<azim>/<elev>[+w<lon>/<lat>[<z>][+v<x0>/<y0>]] [-F[l|r]] [-G[d|f|n|l|L|x|X]<params>]
	[-K] [-L<Low/high>] [-O] [-P] [-Q<cut>] [-R<west>/<east>/<south>/<north>[r]] [-S<smooth>]
	[-T[+|-][<gap>[c|i|m|p]/<length>[c|i|m|p]][:LH]] [-U[<just>/<dx>/<dy>/][c|<label>]] [-V] [-W[+]<type><pen>]
	[-X[a|c|r]<x_shift>[u]] [-Y[a|c|r]<x_shift>[u]] [-Z[<fact>[/shift>]][p]] [-bo[s|S|d|D[<ncol>]|c[<var1>/...]]] [-c<ncopies>] [-m[<flag>]]

	<grdfile> is 2-D netCDF grid file to be contoured
	-C Contours to be drawn can be specified in one of three ways:
	   1. Fixed contour interval
	   2. Name of file with contour levels in col 1 and C(ont) or A(nnot) in col 2
	      [and optionally an individual annotation angle in col 3.]
	   3. Name of cpt-file
	   If -T is used, only contours with upper case C or A is ticked
	     [cpt-file contours are set to C unless last column has flags; Use -A to force all to A]
	-J Selects map proJection. (<scale> in cm/degree, <width> in cm)
	   Append h for map height, + for max map dimension, and - for min map dimension.
	   Azimuthal projections set -Rg unless polar aspect or -R<...>r is given.

	   -Ja|A<lon0>/<lat0>[/<horizon>]/<scale (or radius/lat)|width> (Lambert Azimuthal Equal Area)
	   -Jb|B<lon0>/<lat0>/<lat1>/<lat2>/<scale|width> (Albers Equal-Area Conic)
	   -Jcyl_stere|Cyl_stere/[<lon0>/[<lat0>/]]<lat1>/<lat2>/<scale|width> (Cylindrical Stereographic)
	   -Jc|C<lon0>/<lat0><scale|width> (Cassini)
	   -Jd|D<lon0>/<lat0>/<lat1>/<lat2>/<scale|width> (Equidistant Conic)
	   -Je|E<lon0>/<lat0>[/<horizon>]/<scale (or radius/lat)|width>  (Azimuthal Equidistant)
	   -Jf|F<lon0>/<lat0>[/<horizon>]/<scale (or radius/lat)|width>  (Gnomonic)
	   -Jg|G<lon0>/<lat0>/<scale (or radius/lat)|width>  (Orthographic)
	   -Jg|G[<lon0>/]<lat0>[/<horizon>|/<altitude>/<azimuth>/<tilt>/<twist>/<Width>/<Height>]/<scale|width> (General Perspective)
	   -Jh|H[<lon0>/]<scale|width> (Hammer-Aitoff)
	   -Ji|I[<lon0>/]<scale|width> (Sinusoidal)
	   -Jj|J[<lon0>/]<scale|width> (Miller)
	   -Jkf|Kf[<lon0>/]<scale|width> (Eckert IV)
	   -Jks|Ks[<lon0>/]<scale|width> (Eckert VI)
	   -Jl|L<lon0>/<lat0>/<lat1>/<lat2>/<scale|width> (Lambert Conformal Conic)
	   -Jm|M[<lon0>/[<lat0>/]]<scale|width> (Mercator).
	   -Jn|N[<lon0>/]<scale|width> (Robinson projection)
	   -Jo|O (Oblique Mercator).  Specify one of three definitions:
	      -Jo|O[a]<lon0>/<lat0>/<azimuth>/<scale|width>
	      -Jo|O[b]<lon0>/<lat0>/<lon1>/<lat1>/<scale|width>
	      -Jo|Oc<lon0>/<lat0>/<lonp>/<latp>/<scale|width>
	   -Jpoly|Poly/[<lon0>/[<lat0>/]]<scale|width> ((American) Polyconic)
	   -Jq|Q[<lon0>/[<lat0>/]]<scale|width> (Equidistant Cylindrical)
	   -Jr|R[<lon0>/]<scale|width> (Winkel Tripel)
	   -Js|S<lon0>/<lat0>/[<horizon>/]<scale (or slat/scale or radius/lat)|width> (Stereographic)
	   -Jt|T<lon0>/[<lat0>/]<scale|width> (Transverse Mercator).
	   -Ju|U<zone>/<scale|width> (UTM)
	   -Jv|V<lon0>/<scale|width> (van der Grinten)
	   -Jw|W<lon0>/<scale|width> (Mollweide)
	   -Jy|Y[<lon0>/[<lat0>/]]<scale|width> (Cylindrical Equal-area)
	   -Jp|P[a]<scale|width>[/<origin>][r|z] (Polar [azimuth] (theta,radius))
	   -Jx|X<x-scale|width>[d|l|p<power>|t|T][/<y-scale|height>[d|l|p<power>|t|T]] (Linear, log, and power projections)
	   (See psbasemap for more details on projection syntax)

	OPTIONS:
	-A Annotation label information. [Default is no annoted contours].
	   Give annotation interval OR - to disable all contour annotations implied in -C
	   <labelinfo> controls the specifics of the labels.  Append what you need:
	      +a<angle> for annotations at a fixed angle, +an for line-normal, or +ap for line-parallel [Default]
	        For +ap, optionally append u for up-hill and d for down-hill cartographic annotations
	      +c<dx>[/<dy>] to change the clearance between label and text box [15%]
	      +d turns on debug which draws helper points and lines
	      +f followed by desired label font [Default is 0].
	      +g[<color>] for opaque text box [Default is transparent]; optionally give color [white]
	      +j<just> to set label justification [Default is CM]
	      +k<color> to change color of label text [Default is black]
	      +n<dx>[/<dy>] to nudge placement of label along line (+N for along x/y axis)
	      +o to use rounded rectangular text box [Default is rectangular]
	      +p[<pen>] draw outline of textbox  [Default is no outline]; optionally give pen [Default is default pen]
	      +r<min_rad> places no labels where radius of curvature < <min_rad> [Default is 0].
	      +s followed by desired font size in points [Default is 9 point].
	      +u<unit> to append unit to labels; Start with - for no space between annotation and unit.
	       If no unit appended, use z-unit from grdfile. [Default is no unit]
	      +v for placing curved text along path [Default is straight]
	      +w to set how many (x,y) points to use for angle calculation [Default is 10]
	      +=<prefix> to give labels a prefix; Start with - for no space between annotation and prefix.
	-B Boundary annotation, give -B[p|s]<xinfo>[/<yinfo>[/<zinfo>]][.:"title":][wesnzWESNZ+]
	   <?info> is 1-3 substring(s) of form [<type>]<stride>[<unit>][l|p][:"label":][:,[-]"unit":]
	   See psbasemap man pages for more details and examples of all settings.
	-D to Dump contour lines to individual files (but see -m)
	   Append file prefix [contour].  Files will be called <dumpfile>_<cont>_#[_i].xyz|b
	   where <cont> is the contour value and # is a segment counter.
	   _i is inserted for interior (closed) contours, with xyz (ascii) or b (binary) as extension.
	   However, if -D- is given then files are C#_e or C#_i plus extension, where # is a running number.
	-E set azimuth and elevation of viewpoint for 3-D pseudo perspective view [180/90].
	   Optionally, append +w<lon/lat[/z] to specify a fixed point and +vx/y for its justification.
	   Just append + by itself to select default values [region center and page center]
	-F force dumped contours to be oriented so that the higher z-values are to the left (-Fl [Default])
	   or right (-Fr) as we move along the contour [Default is not oriented]
	-G Controls placement of labels along contours.  Choose among five algorithms:
	   d<dist>[c|i|m|p] or D<dist>[d|e|k|m|n].
	      d: Give distance between labels in specified unit [Default algorithm is d10.16c]
	      D: Specify distance between labels in m(e)ter [Default], (k)m, (m)ile, (n)autical mile, or (d)egree.
	      The first label appears at <frac>*<dist>; change by appending /<frac> [0.25].
	   f<ffile.d> reads the file <ffile.d> and places labels at those locations that match
	      individual points along the contours
	   l|L<line1>[,<line2>,...] Give start and stop coordinates for straight line segments.
	      Labels will be placed where these lines intersect contours.  The format of each <line> is
	      <start>/<stop>, where <start> or <stop> = <lon/lat> or a 2-character XY key that uses the
	      "pstext"-style justification format to specify a point on the map as [LCR][BMT].
	      In addition, you can use Z-, Z+ to mean the global min, max locations in the grid.
	      L: Let point pairs define great circles [Default is a straight line].
	   n|N<n_label> specifies the number of equidistant labels per contour.
	      N: Starts labeling exactly at the start of contour [Default centers the labels].
	      N-1 places one label at start, while N+1 places one label at the end of the contour.
	      Append /<min_dist> to enforce a minimum distance between successive labels [0]
	   x|X<xfile.d> reads the multi-segment file <xfile.d> and places labels at the intersections
	      between the contours and the lines in <xfile.d>.  X: Resample the lines first.
	      For all options, append +r<radius>[unit] to specify minimum radial separation between labels [0]
	-K means allow for more plot code to be appended later [OFF].
	-L only contour inside this range
	-O means Overlay plot mode [OFF].
	-P means Portrait page orientation [OFF].
	-Q Do not draw closed contours with less than <cut> points [Draw all contours]
	-R specifies the min/max coordinates of data region in user units.
	   Use dd:mm[:ss] format for regions given in degrees and minutes [and seconds].
	   Use [yyy[-mm[-dd]]]T[hh[:mm[:ss[.xxx]]]] format for time axes.
	   Append r if -R specifies the longitudes/latitudes of the lower left
	   and upper right corners of a rectangular area.
	   -Rg -Rd are accepted shorthands for -R0/360/-90/90 -R-180/180/-90/90
	   Alternatively, give a gridfile and use its limits (and increments if applicable).
	   [Default is extent of grid]
	-S will Smooth contours by splining and resampling
	   at approximately gridsize/<smooth> intervals
	-T will embellish innermost, closed contours with ticks pointing in the downward direction
	   User may specify to tick only highs (-T+) or lows (-T-) [-T means both]
	   Append spacing/ticklength (append units) to change defaults [0.5/0.1 cm]
	   Append :LH to plot the characters L and H in the center of closed contours
	   for local Lows and Highs (e.g, give :-+ to plot - and + signs)
	-U to plot Unix System Time stamp [and optionally appended text].
	   You may also set the reference points and position of stamp [BL/-2c/-2c].
	   Give -Uc to have the command line plotted [OFF].
	-V Run in verbose mode [OFF].
	-W sets pen attributes. Append a<pen> for annotated contours or c<pen> for regular contours [Default]
	   <pen> is a comma-separated list of optional <width>[cipm], <color>, and <texture>[cipm]
	   <width> >= 0.0, or a pen name: faint, default, or {thin, thick, fat}[er|est], obese.
	   <color> = (1) <gray> or <red>/<green>/<blue>, all in the range 0-255,
	             (2) <c>/<m>/<y>/<k> in 0-100% range,
	             (3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1,
	             (4) any valid color name.
	   <texture> = (1) pattern of dashes (-) and dots (.) which will be scaled by pen width.
	               (2) a for d(a)shed or o for d(o)tted lines, scaled by pen width.
	               (3) <pattern>:<offset>; <pattern> holds lengths of lines and gaps separated
	                   by underscores and <offset> is a phase offset.
	   If no unit is appended, then dots-per-inch is assumed [current dpi = 300].
	   The default settings are
	   Contour pen:  width = 0.25p, color = (0/0/0), texture = solid
	   Annotate pen: width = 0.75p, color = (0/0/0), texture = solid
	   Use + to draw colored contours based on the cpt file
	-X -Y to shift origin of plot to (<xshift>, <yshift>) [a2.5c,a2.5c].
	   Prepend a for absolute [Default r is relative]
	   (Note that for overlays (-O), the default is [r0,r0].)
	   Give c to center plot on page in x and/or y.
	-Z to subtract <shift> and multiply data by <fact> before contouring [1/0].
	   Append p for z-data that is periodic in 360 (i.e., phase data)
	-bo for binary output. Append s for single precision [Default is double]
	    Append <n> for the number of columns in binary file(s).
	-c specifies the number of copies [1].
	-f Special formatting of input/output columns (e.g., time or geographical)
	   Specify i(nput) or o(utput) [Default is both input and output]
	   Give one or more columns (or column ranges) separated by commas.
	   Append T (Calendar format), t (time relative to TIME_EPOCH), f (plain floating point)
	   x (longitude), y (latitude) to each col/range item.
	   -f[i|o]g means -f[i|o]0x,1y (geographic coordinates).
	-m Used with -D.   Create a single multiple segment file where contours are separated by a record
	   whose first character is <flag> ['>'].  This header also has the contour level value

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '1.0.1';

=head2 Encapsulated

	hash of private variables

=cut

my $grdcontour = {
    _C          => '',
    _A          => '',
    _projection => '',
    _J          => '',
    _infile     => '',
    _Rg         => '',
    _C          => '',
    _B          => '',
    _D          => '',
    _E          => '',
    _F          => '',
    _G          => '',
    _K          => '',
    _L          => '',
    _O          => '',
    _portrait   => '',
    _P          => '',
    _Q          => '',
    _limits     => '',
    _R          => '',
    _S          => '',
    _T          => '',
    _U          => '',
    _Uc         => '',
    _verbose    => '',
    _V          => '',
    _W          => '',
    _X          => '',
    _Z          => '',
    _bo         => '',
    _c          => '',
    _f          => '',
    _m          => '',
    _Step       => '',
    _note       => '',
};

=head2 sub clear

=cut

sub clear {
    $grdcontour->{_C}          = '';
    $grdcontour->{_A}          = '';
    $grdcontour->{_infile}     = '';
    $grdcontour->{_projection} = '';
    $grdcontour->{_J}          = '';
    $grdcontour->{_Rg}         = '';
    $grdcontour->{_C}          = '';
    $grdcontour->{_B}          = '';
    $grdcontour->{_D}          = '';
    $grdcontour->{_E}          = '';
    $grdcontour->{_F}          = '';
    $grdcontour->{_G}          = '';
    $grdcontour->{_K}          = '';
    $grdcontour->{_L}          = '';
    $grdcontour->{_O}          = '';
    $grdcontour->{_P}          = '';
    $grdcontour->{_Q}          = '';
    $grdcontour->{_limits}     = '';
    $grdcontour->{_R}          = '';
    $grdcontour->{_Rg}         = '';
    $grdcontour->{_S}          = '';
    $grdcontour->{_T}          = '';
    $grdcontour->{_U}          = '';
    $grdcontour->{_Uc}         = '';
    $grdcontour->{_verbose}    = '';
    $grdcontour->{_V}          = '';
    $grdcontour->{_W}          = '';
    $grdcontour->{_X}          = '';
    $grdcontour->{_Z}          = '';
    $grdcontour->{_bo}         = '';
    $grdcontour->{_c}          = '';
    $grdcontour->{_f}          = '';
    $grdcontour->{_m}          = '';
    $grdcontour->{_Step}       = '';
    $grdcontour->{_note}       = '';
}

=head2 sub infile 


=cut

sub infile {
    my ( $self, $infile ) = @_;
    if ($infile) {
        $grdcontour->{_infile} = $infile;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' ' . $grdcontour->{_infile};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' ' . $grdcontour->{_infile};
    }
}

=head2 sub C 


=cut

sub C {
    my ( $self, $C ) = @_;
    if ($C) {
        $grdcontour->{_C} = $C;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -C' . $grdcontour->{_C};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -C' . $grdcontour->{_C};
    }
}

=head2 sub T 


=cut

sub T {
    my ( $self, $T ) = @_;
    if ($T) {
        $grdcontour->{_T} = $T;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -T' . $grdcontour->{_T};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -T' . $grdcontour->{_T};
    }
}

=head2 sub A 


=cut

sub A {
    my ( $self, $A ) = @_;
    if ($A) {
        $grdcontour->{_A} = $A;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -A' . $grdcontour->{_A};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -A' . $grdcontour->{_A};
    }
}

=head2 sub projection 


=cut

sub projection {
    my ( $self, $projection ) = @_;
    if ($projection) {
        $grdcontour->{_projection} = $projection;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -J' . $grdcontour->{_projection};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -J' . $grdcontour->{_projection};
    }
}

=head2 sub J 


=cut

sub J {
    my ( $self, $J ) = @_;
    if ($J) {
        $grdcontour->{_J} = $J;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -J' . $grdcontour->{_J};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -J' . $grdcontour->{_J};
    }
}

=head2 sub Rg 


=cut

sub Rg {
    my ( $self, $Rg ) = @_;
    if ($Rg) {
        $grdcontour->{_Rg} = $Rg;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -Rg' . $grdcontour->{_Rg};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -Rg' . $grdcontour->{_Rg};
    }
}

=head2 sub B 


=cut

sub B {
    my ( $self, $B ) = @_;
    if ($B) {
        $grdcontour->{_B} = $B;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -B' . $grdcontour->{_B};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -B' . $grdcontour->{_B};
    }
}

=head2 sub D 


=cut

sub D {
    my ( $self, $D ) = @_;
    if ($D) {
        $grdcontour->{_D} = $D;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -D' . $grdcontour->{_D};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -D' . $grdcontour->{_D};
    }
}

=head2 sub E 


=cut

sub E {
    my ( $self, $E ) = @_;
    if ($E) {
        $grdcontour->{_E} = $E;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -E' . $grdcontour->{_E};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -E' . $grdcontour->{_E};
    }
}

=head2 sub F 


=cut

sub F {
    my ( $self, $F ) = @_;
    if ($F) {
        $grdcontour->{_F} = $F;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -F' . $grdcontour->{_F};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -F' . $grdcontour->{_F};
    }
}

=head2 sub G 


=cut

sub G {
    my ( $self, $G ) = @_;
    if ($G) {
        $grdcontour->{_G} = $G;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -G' . $grdcontour->{_G};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -G' . $grdcontour->{_G};
    }
}

=head2 sub K 


=cut

sub K {
    my ( $self, $K ) = @_;
    if ($K) {
        $grdcontour->{_K} = $K;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -K' . $grdcontour->{_K};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -K' . $grdcontour->{_K};
    }
}

=head2 sub L 


=cut

sub L {
    my ( $self, $L ) = @_;
    if ($L) {
        $grdcontour->{_L} = $L;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -L' . $grdcontour->{_L};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -L' . $grdcontour->{_L};
    }
}

=head2 sub O 


=cut

sub O {
    my ( $self, $O ) = @_;
    if ($O) {
        $grdcontour->{_O} = $O;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -O' . $grdcontour->{_O};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -O' . $grdcontour->{_O};
    }
}

=head2 sub portrait 


=cut

sub portrait {
    my ( $self, $portrait ) = @_;
    if ($portrait) {
        $grdcontour->{_portrait} = $portrait;
        $grdcontour->{_note}     = $grdcontour->{_note} . ' -P';
        $grdcontour->{_Step}     = $grdcontour->{_Step} . ' -P';
    }
}

=head2 sub P 


=cut

sub P {
    my ( $self, $P ) = @_;
    if ($P) {
        $grdcontour->{_P} = $P;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -P' . $grdcontour->{_P};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -P' . $grdcontour->{_P};
    }
}

=head2 sub Q 


=cut

sub Q {
    my ( $self, $Q ) = @_;
    if ($Q) {
        $grdcontour->{_Q} = $Q;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -Q' . $grdcontour->{_Q};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -Q' . $grdcontour->{_Q};
    }
}

=head2 sub limits 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $grdcontour->{_limits} = $limits;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -R' . $grdcontour->{_limits};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -R' . $grdcontour->{_limits};
    }
}

=head2 sub R 


=cut

sub R {
    my ( $self, $R ) = @_;
    if ($R) {
        $grdcontour->{_R} = $R;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -R' . $grdcontour->{_R};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -R' . $grdcontour->{_R};
    }
}

=head2 sub S 


=cut

sub S {
    my ( $self, $S ) = @_;
    if ($S) {
        $grdcontour->{_S} = $S;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -S' . $grdcontour->{_S};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -S' . $grdcontour->{_S};
    }
}

=head2 sub U 


=cut

sub U {
    my ( $self, $U ) = @_;
    if ($U) {
        $grdcontour->{_U} = $U;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -U' . $grdcontour->{_U};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -U' . $grdcontour->{_U};
    }
}

=head2 sub Uc 


=cut

sub Uc {
    my ( $self, $Uc ) = @_;
    if ($Uc) {
        $grdcontour->{_Uc} = $Uc;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -Uc' . $grdcontour->{_Uc};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -Uc' . $grdcontour->{_Uc};
    }
}

=head2 sub verbose 


=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ($verbose) {
        $grdcontour->{_verbose} = $verbose;
        $grdcontour->{_note}    = $grdcontour->{_note} . ' -V';
        $grdcontour->{_Step}    = $grdcontour->{_Step} . ' -V';
    }
}

=head2 sub V 


=cut

sub V {
    my ( $self, $V ) = @_;
    if ($V) {
        $grdcontour->{_V} = $V;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -V' . $grdcontour->{_V};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -V' . $grdcontour->{_V};
    }
}

=head2 sub W 


=cut

sub W {
    my ( $self, $W ) = @_;
    if ($W) {
        $grdcontour->{_W} = $W;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -W' . $grdcontour->{_W};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -W' . $grdcontour->{_W};
    }
}

=head2 sub X 


=cut

sub X {
    my ( $self, $X ) = @_;
    if ($X) {
        $grdcontour->{_X} = $X;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -X' . $grdcontour->{_X};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -X' . $grdcontour->{_X};
    }
}

=head2 sub Z 


=cut

sub Z {
    my ( $self, $Z ) = @_;
    if ($Z) {
        $grdcontour->{_Z} = $Z;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -Z' . $grdcontour->{_Z};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -Z' . $grdcontour->{_Z};
    }
}

=head2 sub bo 


=cut

sub bo {
    my ( $self, $bo ) = @_;
    if ($bo) {
        $grdcontour->{_bo} = $bo;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -bo' . $grdcontour->{_bo};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -bo' . $grdcontour->{_bo};
    }
}

=head2 sub c 


=cut

sub c {
    my ( $self, $c ) = @_;
    if ($c) {
        $grdcontour->{_c} = $c;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -c' . $grdcontour->{_c};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -c' . $grdcontour->{_c};
    }
}

=head2 sub f 


=cut

sub f {
    my ( $self, $f ) = @_;
    if ($f) {
        $grdcontour->{_f} = $f;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -f' . $grdcontour->{_f};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -f' . $grdcontour->{_f};
    }
}

=head2 sub m 


=cut

sub m {
    my ( $self, $m ) = @_;
    if ($m) {
        $grdcontour->{_m} = $m;
        $grdcontour->{_note} =
          $grdcontour->{_note} . ' -m' . $grdcontour->{_m};
        $grdcontour->{_Step} =
          $grdcontour->{_Step} . ' -m' . $grdcontour->{_m};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $grdcontour->{_Step} = 'gmt grdcontour ' . $grdcontour->{_Step};
        return ( $grdcontour->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $grdcontour->{_note} = 'grdcontour ' . $grdcontour->{_note};
        return ( $grdcontour->{_note} );
    }
}

1;
