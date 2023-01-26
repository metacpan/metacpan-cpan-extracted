package App::SeismicUnixGui::gmt::psbasemap;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: psbasemap
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

	psbasemap 4.5.7 [64-bit] - To plot PostScript basemaps

	usage: psbasemap -B<params> -J<params> -R<west>/<east>/<south>/<north>[/<zmin/zmax>][r] [-E<azim>/<elev>[+w<lon>/<lat>[<z>][+v<x0>/<y0>]] [-G<fill>]
	[-K] [-Jz|Z<params>] [-L[f][x]<lon0>/<lat0>[/<slon>]/<slat>/<length>[m|n|k][+l<label>][+j<just>][+p<pen>][+f<fill>][+u]]
	[-O] [-P] [-T[f|m][x]<lon0>/<lat0>/<diameter>[/<info>][:w,e,s,n:][+<gint>[/<mint>]]] [-U[<just>/<dx>/<dy>/][c|<label>]] [-V]
	[-X[a|c|r]<x_shift>[u]] [-Y[a|c|r]<x_shift>[u]] [-Z<zlevel>] [-c<ncopies>]

	-B specifies Basemap frame info.  <tickinfo> is a textstring made up of one or
	   more substrings of the form [a|f|g]<stride>[+-<phase>][<unit>], where the (optional) a
	   indicates annotation and major tick interval, f minor tick interval and g grid interval	   axis item type, <stride> is the spacing between ticks or annotations, the (optional)
	   <phase> specifies phase-shifted annotations by that amount, and the (optional)
	   <unit> specifies the <stride> unit [Default is unit implied in -R]. There can be
	   no spaces between the substrings - just append to make one very long string.
	   -B[p] means (p)rimary annotations; use -Bs to specify (s)econdary annotations.
	   The optional <unit> modifies the <stride> value accordingly.  For maps, you may use
	     m: arc minutes [Default unit is degree].
	     c: arc seconds.
	   For time axes, several units are recognized:
	     Y: year - plot using all 4 digits.
	     y: year - plot only last 2 digits.
	     O: month - format annotation according to PLOT_DATE_FORMAT.
	     o: month - plot as 2-digit integer (1-12).
	     U: ISO week - format annotation according to PLOT_DATE_FORMAT.
	     u: ISO week - plot as 2-digit integer (1-53).
	     r: Gregorian week - 7-day stride from chosen start of week (Sunday).
	     K: ISO weekday - format annotation according to PLOT_DATE_FORMAT.
	     k: weekday - plot name of weekdays in selected language [us].
	     D: day  - format annotation according to PLOT_DATE_FORMAT, which also determines whether
	               we should plot day of month (1-31) or day of year (1-366).
	     d: day - plot as 2- (day of month) or 3- (day of year) integer.
	     R: Same as d but annotates from start of Gregorian week.
	     H: hour - format annotation according to PLOT_CLOCK_FORMAT.
	     h: hour - plot as 2-digit integer (0-23).
	     M: minute - format annotation according to PLOT_CLOCK_FORMAT.
	     m: minute - plot as 2-digit integer (0-59).
	     C: second - format annotation according to PLOT_CLOCK_FORMAT.
	     c: second - plot as 2-digit integer (0-59; 60-61 if leap seconds are enabled).
	   Specify an axis label by surrounding it with colons (e.g., :"my x label":).
	   To prepend a prefix to each annotation (e.g., $ 10, $ 20 ...) add a prefix that begins
	     with the equal-sign (=); the rest is used as annotation prefix (e.g. :='$':). If the prefix has
	     a leading hyphen (-) there will be no space between prefix and annotation (e.g., :=-'$':).
	   To append a unit to each annotation (e.g., 5 km, 10 km ...) add a label that begins
	     with a comma; the rest is used as unit annotation (e.g. :",km":). If the unit has
	     a leading hyphen (-) there will be no space between unit and annotation (e.g., :,-%:).
	   For separate x and y [and z if -Jz is used] tickinfo, separate the strings with slashes [/].
	   Specify an plot title by adding a label whose first character is a period; the rest
	     of the label is used as the title (e.g. :".My Plot Title":).
	   Append any combination of W, E, S, N, Z to annotate those axes only [Default is WESNZ (all)].
	     Use lower case w, e, s, n, z to draw & tick but not to annotate those axes.
	     Z+ will also draw a 3-D box .
	   Log10 axis: Append l to annotate log10 (x) or p for 10^(log10(x)) [Default annotates x].
	   Power axis: append p to annotate x at equidistant pow increments [Default is nonlinear].
	   See psbasemap man pages for more details and examples of all settings.
	-J Selects the map proJection system. The projection type is identified by a 1- or
	   2-character ID (e.g. 'm' or 'kf') or by an abbreviation followed by a slash
	   (e.g. 'cyl_stere/'). When using a lower-case ID <scale> can be given either as 1:<xxxx>
	   or in cm/degree along the standard parallel. Alternatively, when the projection ID is
	   Capitalized, <scale|width> denotes the width of the plot in cm
	   Append h for map height, + for max map dimension, and - for min map dimension.
	   When the central meridian (lon0) is optional and omitted, the center of the
	   longitude range specified by -R is used. The default standard parallel is the equator
	   Azimuthal projections set -Rg unless polar aspect or -R<...>r is given.
	   -Ja|A<lon0>/<lat0>[/<horizon>]/<scale|width> (Lambert Azimuthal Equal Area)
	     lon0/lat0 is the center of the projection.
	     horizon is max distance from center of the projection (<= 180, default 90).
	     Scale can also be given as <radius>/<lat>, where <radius> is the distance
	     in cm to the oblique parallel <lat>.
	   -Jb|B<lon0>/<lat0>/<lat1>/<lat2>/<scale|width> (Albers Equal-Area Conic)
	     Give origin, 2 standard parallels, and true scale
	   -Jc|C<lon0>/<lat0><scale|width> (Cassini)
	     Give central point and scale
	   -Jcyl_stere|Cyl_stere/[<lon0>/[<lat0>/]]<scale|width> (Cylindrical Stereographic)
	     Give central meridian (opt), standard parallel (opt) and scale
	     <lat0> = 66.159467 (Miller's modified Gall), 55 (Kamenetskiy's First),
	     45 (Gall Stereographic), 30 (Bolshoi Sovietskii Atlas Mira), 0 (Braun)
	   -Jd|D<lon0>/<lat0>/<lat1>/<lat2>/<scale|width> (Equidistant Conic)
	     Give origin, 2 standard parallels, and true scale
	   -Je|E<lon0>/<lat0>[/<horizon>]/<scale|width> (Azimuthal Equidistant)
	     lon0/lat0 is the center of the projection.
	     horizon is max distance from center of the projection (<= 180, default 180).
	     Scale can also be given as <radius>/<lat>, where <radius> is the distance
	     in cm to the oblique parallel <lat>. 
	   -Jf|F<lon0>/<lat0>[/<horizon>]/<scale|width> (Gnomonic)
	     lon0/lat0 is the center of the projection.
	     horizon is max distance from center of the projection (< 90, default 60).
	     Scale can also be given as <radius>/<lat>, where <radius> is distance
	     in cm to the oblique parallel <lat>. 
	   -Jg|G<lon0>/<lat0>/<scale|width> (Orthographic)
	     lon0/lat0 is the center of the projection.
	     Scale can also be given as <radius>/<lat>, where <radius> is distance
	     in cm to the oblique parallel <lat>. 
	   -Jg|G<lon0>/<lat0>/<altitude>/<azimuth>/<tilt>/<twist>/<Width>/<Height>/<scale|width> (General Perspective)
	     lon0/lat0 is the center of the projection.
	     Altitude is the height (in km) of the viewpoint above local sea level
	        - if altitude less than 10 then it is the distance 
	        from center of earth to viewpoint in earth radii
	        - if altitude has a suffix of 'r' then it is the radius 
	        from the center of earth in kilometers
	     Azimuth is azimuth east of North of view
	     Tilt is the upward tilt of the plane of projection
	       if tilt < 0 then viewpoint is centered on the horizon
	     Twist is the CW twist of the viewpoint in degree
	     Width is width of the viewpoint in degree
	     Height is the height of the viewpoint in degrees
	     Scale can also be given as <radius>/<lat>, where <radius> is distance
	     in cm to the oblique parallel <lat>. 
	   -Jh|H[<lon0>/]<scale|width> (Hammer-Aitoff)
	     Give central meridian (opt) and scale
	   -Ji|I[<lon0>/]<scale|width> (Sinusoidal)
	     Give central meridian (opt) and scale
	   -Jj|J[<lon0>/]<scale|width> (Miller)
	     Give central meridian (opt) and scale
	   -Jkf|Kf[<lon0>/]<scale|width> (Eckert IV)
	     Give central meridian (opt) and scale
	   -Jk|K[s][<lon0>/]<scale|width> (Eckert VI)
	     Give central meridian (opt) and scale
	   -Jl|L<lon0>/<lat0>/<lat1>/<lat2>/<scale|width> (Lambert Conformal Conic)
	     Give origin, 2 standard parallels, and true scale
	   -Jm|M[<lon0>/[<lat0>/]]<scale|width> (Mercator).
	     Give central meridian (opt), true scale parallel (opt), and scale
	   -Jn|N[<lon0>/]<scale|width> (Robinson projection)
	     Give central meridian (opt) and scale
	   -Jo|O<parameters> (Oblique Mercator).  Specify one of three definitions:
	     -Jo|O[a]<lon0>/<lat0>/<azimuth>/<scale|width>
	       Give origin, azimuth of oblique equator, and scale at oblique equator
	     -Jo|O[b]<lon0>/<lat0>/<lon1>/<lat1>/<scale|width>
	       Give origin, second point on oblique equator, and scale at oblique equator
	     -Jo|Oc<lon0>/<lat0>/<lonp>/<latp>/<scale|width>
	       Give origin, pole of projection, and scale at oblique equator
	       Specify region in oblique degrees OR use -R<>r
	   -Jp|P[a]<scale|width>[/<base>][r|z] (Polar (theta,radius))
	     Linear scaling for polar coordinates.
	     Optionally append 'a' to -Jp or -JP to use azimuths (CW from North) instead of directions (CCW from East) [default].
	     Give scale in cm/units, and append theta value for angular offset (base) [0]
	     Append r to reverse radial direction (s/n must be in 0-90 range) or z to annotate depths rather than radius [Default]
	   -Jpoly|Poly/[<lon0>/[<lat0>/]]<scale|width> ((American) Polyconic)
	     Give central meridian (opt), reference parallel (opt, default = equator), and scale
	   -Jq|Q[<lon0>/[<lat0>/]]<scale|width> (Equidistant Cylindrical)
	     Give central meridian (opt), standard parallel (opt), and scale
	     <lat0> = 61.7 (Min. linear distortion), 50.5 (R. Miller equirectangular),
	     45 (Gall isographic), 43.5 (Min. continental distortion), 42 (Grafarend & Niermann),
	     37.5 (Min. overall distortion), 0 (Plate Carree, default)
	   -Jr|R[<lon0>/]<scale|width> (Winkel Tripel)
	     Give central meridian and scale
	   -Js|S<lon0>/<lat0>[/<horizon>]/<scale|width> (Stereographic)
	     lon0/lat0 is the center or the projection.
	     horizon is max distance from center of the projection (< 180, default 90).
	     Scale is either <1:xxxx> (true at pole) or <slat>/<1:xxxx> (true at <slat>)
	     or <radius>/<lat> (distance in cm to the [oblique] parallel <lat>.
	   -Jt|T<lon0>/[<lat0>/]<scale|width> (Transverse Mercator).
	         Give central meridian and scale
	     Optionally, also give the central parallel (default = equator)
	   -Ju|U<zone>/<scale|width> (UTM)
	     Give zone (A,B,Y,Z, or 1-60 (negative for S hemisphere) or append C-X) and scale
	   -Jv|V[<lon0>/]<scale|width> (van der Grinten)
	     Give central meridian (opt) and scale
	   -Jw|W[<lon0>/]<scale|width> (Mollweide)
	     Give central meridian (opt) and scale
	   -Jy|Y[<lon0>/[<lat0>/]]<scale|width> (Cylindrical Equal-area)
	     Give central meridian (opt), standard parallel (opt) and scale
	     <lat0> = 50 (Balthasart), 45 (Gall-Peters), 37.5 (Hobo-Dyer), 37.4 (Trystan Edwards),
	              37.0666 (Caster), 30 (Behrmann), 0 (Lambert, default)
	   -Jx|X<x-scale|width>[/<y-scale|height>] (Linear, log, power scaling)
	     Scale in cm/units (or 1:xxxx). Optionally, append to <x-scale> and/or <y-scale>:
	       d         Geographic coordinate (in degrees)
	       l         Log10 projection
	       p<power>  x^power projection
	       t         Calendar time projection using relative time coordinates
	       T         Calendar time projection using absolute time coordinates
	     Use / to specify separate x/y scaling (e.g., -Jx0.5/0.3.).  Not allowed with 1:xxxxx.
	     If -JX is used then give axes lengths rather than scales.
	   -Jz for z component of 3-D projections.  Same syntax as -Jx.
	-R specifies the min/max coordinates of data region in user units.
	   Use dd:mm[:ss] format for regions given in degrees and minutes [and seconds].
	   Use [yyy[-mm[-dd]]]T[hh[:mm[:ss[.xxx]]]] format for time axes.
	   Append r if -R specifies the longitudes/latitudes of the lower left
	   and upper right corners of a rectangular area.
	   -Rg -Rd are accepted shorthands for -R0/360/-90/90 -R-180/180/-90/90
	   Alternatively, give a gridfile and use its limits (and increments if applicable).

	OPTIONS:
	-E set azimuth and elevation of viewpoint for 3-D pseudo perspective view [180/90].
	   Optionally, append +w<lon/lat[/z] to specify a fixed point and +vx/y for its justification.
	   Just append + by itself to select default values [region center and page center]
	-G<fill> Select fill inside of basemap. Specify <fill> as one of:
	   1) <gray> or <red>/<green>/<blue>, all in the range 0-255;
	   2) <c>/<m>/<y>/<k> in range 0-100%;
	   3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1;
	   4) any valid color name;
	   5) P|p<dpi>/<pattern>[:F<color>B<color>], with <dpi> of pattern, <pattern> from 1-90 or a filename,
	      optionally add fore/background colors (use - for transparency).
	-K means allow for more plot code to be appended later [OFF].
	-L Draws a simple map scale centered on <lon0>/<lat0>
	   Use -Lx to specify Cartesian coordinates instead.  Scale is calculated at latitude <slat>;
	   optionally give longitude <slon> [Default is central longitude].  <length> is in km [Default]
	   or [nautical] miles if [n] m is appended.  -Lf draws a "fancy" scale [Default is plain].
	   By default, the label is set to the distance unit and placed on top [+jt].  Use the +l<label>
	   and +j<just> mechanisms to specify another label and placement (t,b,l,r).  +u sets the label as a unit.
	   Append +p<pen> and/or +f<fill> to draw/paint a rectangle behind the scale [no rectangle]
	-O means Overlay plot mode [OFF].
	-P means Portrait page orientation [OFF].
	-T Draws a north-pointing map rose centered on <lon0>/<lat0>
	   Use -Tx to specify Cartesian coordinates instead.  -Tf draws a "fancy" rose [Default is plain].
	   Give rose <diameter> and optionally the west, east, south, north labels desired [W,E,S,N].
	   For fancy rose, specify as <info> the kind you want: 1 draws E-W, N-S directions [Default],
	   2 adds NW-SE and NE-SW, while 3 adds WNW-ESE, NNW-SSE, NNE-SSW, and ENE-WSW.
	   For Magnetic compass rose, specify -Tm.  Use the optional <info> = <dec>/<dlabel> (where <dec> is
	   the magnetic declination and <dlabel> is a label for the magnetic compass needle) to plot
	   directions to both magnetic and geographic north [Default is just geographic].
	   If the North label = '*' then a north star is plotted instead of the label.
	   Append +<gints>/<mints> to override default annotation/tick interval(s) [10/5/1/30/5/1].
	-U to plot Unix System Time stamp [and optionally appended text].
	   You may also set the reference points and position of stamp [BL/-2c/-2c].
	   Give -Uc to have the command line plotted [OFF].
	-V Run in verbose mode [OFF].
	-X -Y to shift origin of plot to (<xshift>, <yshift>) [a2.5c,a2.5c].
	   Prepend a for absolute [Default r is relative]
	   (Note that for overlays (-O), the default is [r0,r0].)
	   Give c to center plot on page in x and/or y.
	-Z For 3-D plots: Set the z-level of map [default is at bottom of z-axis]
	-c specifies the number of copies [1].
	(See gmtdefaults man page for hidden GMT default parameters)

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '1.0.1';
use aliased 'App::SeismicUnixGui::gmt::GMTglobal_constants';

=head2 instantiation of packages

=cut

my $get     = GMTglobal_constants->new();
my $gmt_var = $get->gmt_var();

=head2 declare variables

=cut

my $on    = $gmt_var->{_on};
my $off   = $gmt_var->{_off};
my $true  = $gmt_var->{_true};
my $false = $gmt_var->{_false};

=head2 Encapsulated

	hash of private variables

=cut

my $psbasemap = {
    _B          => '',
    _Bs         => '',
    _J          => '',
    _Jp         => '',
    _JX         => '',
    _Jz         => '',
    _R          => '',
    _Rg         => '',
    _E          => '',
    _K          => '',
    _L          => '',
    _Lx         => '',
    _Lf         => '',
    _O          => '',
    _P          => '',
    _T          => '',
    _Tx         => '',
    _U          => '',
    _Uc         => '',
    _V          => '',
    _X          => '',
    _Z          => '',
    _c          => '',
    _limits     => '',
    _projection => '',
    _no_head    => '',
    _no_tail    => '',
    _Step       => '',
    _note       => '',
};

=head2 sub clear

=cut

sub clear {
    $psbasemap->{_B}          = '';
    $psbasemap->{_Bs}         = '';
    $psbasemap->{_Jz}         = '';
    $psbasemap->{_J}          = '';
    $psbasemap->{_R}          = '';
    $psbasemap->{_Rg}         = '';
    $psbasemap->{_Jp}         = '';
    $psbasemap->{_JX}         = '';
    $psbasemap->{_Jz}         = '';
    $psbasemap->{_R}          = '';
    $psbasemap->{_R}          = '';
    $psbasemap->{_Rg}         = '';
    $psbasemap->{_E}          = '';
    $psbasemap->{_K}          = '';
    $psbasemap->{_L}          = '';
    $psbasemap->{_Lx}         = '';
    $psbasemap->{_Lf}         = '';
    $psbasemap->{_O}          = '';
    $psbasemap->{_P}          = '';
    $psbasemap->{_T}          = '';
    $psbasemap->{_Tx}         = '';
    $psbasemap->{_U}          = '';
    $psbasemap->{_Uc}         = '';
    $psbasemap->{_V}          = '';
    $psbasemap->{_X}          = '';
    $psbasemap->{_Z}          = '';
    $psbasemap->{_c}          = '';
    $psbasemap->{_limits}     = '';
    $psbasemap->{_projection} = '';
    $psbasemap->{_no_head}    = '';
    $psbasemap->{_no_tail}    = '';
    $psbasemap->{_Step}       = '';
    $psbasemap->{_note}       = '';
}

=head2 sub V

=cut

sub V {
    my ( $self, $V ) = @_;
    if ( $V eq $on ) {
        $psbasemap->{_V}    = '';
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -V' . $psbasemap->{_V};
        $psbasemap->{_note} = $psbasemap->{_note} . ' -V' . $psbasemap->{_V};
    }
}

=head2 sub verbose

=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ( $verbose eq $on ) {
        $psbasemap->{_verbose} = '';
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -V' . $psbasemap->{_verbose};
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -V' . $psbasemap->{_verbose};
    }
}

=head2 sub ticks 


=cut

sub ticks {
    my ( $self, $ticks ) = @_;
    if ($ticks) {
        $psbasemap->{_ticks} = $ticks;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -B' . $psbasemap->{_ticks};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -B' . $psbasemap->{_ticks};
    }
}

=head2 sub B 


=cut

sub B {
    my ( $self, $B ) = @_;
    if ($B) {
        $psbasemap->{_B}    = $B;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -B' . $psbasemap->{_B};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -B' . $psbasemap->{_B};
    }
}

=head2 sub Bs 


=cut

sub Bs {
    my ( $self, $Bs ) = @_;
    if ($Bs) {
        $psbasemap->{_Bs} = $Bs;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -Bs' . $psbasemap->{_Bs};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -Bs' . $psbasemap->{_Bs};
    }
}

=head2 sub J 


=cut

sub J {
    my ( $self, $J ) = @_;
    if ($J) {
        $psbasemap->{_J}    = $J;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -J' . $psbasemap->{_J};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -J' . $psbasemap->{_J};
    }
}

=head2 sub Rg 


=cut

sub Rg {
    my ( $self, $Rg ) = @_;
    if ($Rg) {
        $psbasemap->{_Rg} = $Rg;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -Rg' . $psbasemap->{_Rg};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -Rg' . $psbasemap->{_Rg};
    }
}

=head2 sub Jp 


=cut

sub Jp {
    my ( $self, $Jp ) = @_;
    if ($Jp) {
        $psbasemap->{_Jp} = $Jp;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -Jp' . $psbasemap->{_Jp};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -Jp' . $psbasemap->{_Jp};
    }
}

=head2 sub JX 


=cut

sub JX {
    my ( $self, $JX ) = @_;
    if ($JX) {
        $psbasemap->{_JX} = $JX;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -JX' . $psbasemap->{_JX};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -JX' . $psbasemap->{_JX};
    }
}

=head2 sub Jz 


=cut

sub Jz {
    my ( $self, $Jz ) = @_;
    if ($Jz) {
        $psbasemap->{_Jz} = $Jz;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -Jz' . $psbasemap->{_Jz};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -Jz' . $psbasemap->{_Jz};
    }
}

=head2 sub R 


=cut

sub R {
    my ( $self, $R ) = @_;
    if ($R) {
        $psbasemap->{_R}    = $R;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -R' . $psbasemap->{_R};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -R' . $psbasemap->{_R};
    }
}

=head2 sub E 


=cut

sub E {
    my ( $self, $E ) = @_;
    if ($E) {
        $psbasemap->{_E}    = $E;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -E' . $psbasemap->{_E};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -E' . $psbasemap->{_E};
    }
}

=head2 sub K 


=cut

sub K {
    my ( $self, $K ) = @_;
    if ($K) {
        $psbasemap->{_K}    = $K;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -K' . $psbasemap->{_K};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -K' . $psbasemap->{_K};
    }
}

=head2 sub L 


=cut

sub L {
    my ( $self, $L ) = @_;
    if ($L) {
        $psbasemap->{_L}    = $L;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -L' . $psbasemap->{_L};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -L' . $psbasemap->{_L};
    }
}

=head2 sub Lx 


=cut

sub Lx {
    my ( $self, $Lx ) = @_;
    if ($Lx) {
        $psbasemap->{_Lx} = $Lx;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -Lx' . $psbasemap->{_Lx};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -Lx' . $psbasemap->{_Lx};
    }
}

=head2 sub Lf 


=cut

sub Lf {
    my ( $self, $Lf ) = @_;
    if ($Lf) {
        $psbasemap->{_Lf} = $Lf;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -Lf' . $psbasemap->{_Lf};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -Lf' . $psbasemap->{_Lf};
    }
}

=head2 sub O 


=cut

sub O {
    my ( $self, $O ) = @_;
    if ($O) {
        $psbasemap->{_O}    = $O;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -O' . $psbasemap->{_O};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -O' . $psbasemap->{_O};
    }
}

=head2 sub portrait 


=cut

sub portrait {
    my ( $self, $portrait ) = @_;
    if ( $portrait eq $on ) {
        $psbasemap->{_portrait} = '';
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -P' . $psbasemap->{_portrait};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -P' . $psbasemap->{_portrait};
    }
}

=head2 sub P 


=cut

sub P {
    my ( $self, $P ) = @_;
    if ($P) {
        $psbasemap->{_P}    = $P;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -P' . $psbasemap->{_P};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -P' . $psbasemap->{_P};
    }
}

=head2 sub T 


=cut

sub T {
    my ( $self, $T ) = @_;
    if ($T) {
        $psbasemap->{_T}    = $T;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -T' . $psbasemap->{_T};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -T' . $psbasemap->{_T};
    }
}

=head2 sub Tx 


=cut

sub Tx {
    my ( $self, $Tx ) = @_;
    if ($Tx) {
        $psbasemap->{_Tx} = $Tx;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -Tx' . $psbasemap->{_Tx};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -Tx' . $psbasemap->{_Tx};
    }
}

=head2 sub U 


=cut

sub U {
    my ( $self, $U ) = @_;
    if ($U) {
        $psbasemap->{_U}    = $U;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -U' . $psbasemap->{_U};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -U' . $psbasemap->{_U};
    }
}

=head2 sub Uc 


=cut

sub Uc {
    my ( $self, $Uc ) = @_;
    if ($Uc) {
        $psbasemap->{_Uc} = $Uc;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -Uc' . $psbasemap->{_Uc};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -Uc' . $psbasemap->{_Uc};
    }
}

=head2 sub X 


=cut

sub X {
    my ( $self, $X ) = @_;
    if ($X) {
        $psbasemap->{_X}    = $X;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -X' . $psbasemap->{_X};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -X' . $psbasemap->{_X};
    }
}

=head2 sub Z 


=cut

sub Z {
    my ( $self, $Z ) = @_;
    if ($Z) {
        $psbasemap->{_Z}    = $Z;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -Z' . $psbasemap->{_Z};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -Z' . $psbasemap->{_Z};
    }
}

=head2 sub c 


=cut

sub c {
    my ( $self, $c ) = @_;
    if ($c) {
        $psbasemap->{_c}    = $c;
        $psbasemap->{_note} = $psbasemap->{_note} . ' -c' . $psbasemap->{_c};
        $psbasemap->{_Step} = $psbasemap->{_Step} . ' -c' . $psbasemap->{_c};
    }
}

=head2 sub limits 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $psbasemap->{_limits} = $limits;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -R' . $psbasemap->{_limits};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -R' . $psbasemap->{_limits};
    }
}

=head2 sub no_head 


=cut

sub no_head {
    my ( $self, $no_head ) = @_;
    if ($no_head) {
        $psbasemap->{_no_head} = $no_head;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -K' . $psbasemap->{_no_head};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -K' . $psbasemap->{_no_head};
    }
}

=head2 sub no_tail 


=cut

sub no_tail {
    my ( $self, $no_tail ) = @_;
    if ($no_tail) {
        $psbasemap->{_no_tail} = $no_tail;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -O' . $psbasemap->{_no_tail};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -O' . $psbasemap->{_no_tail};
    }
}

=head2 sub projection 


=cut

sub projection {
    my ( $self, $projection ) = @_;
    if ($projection) {
        $psbasemap->{_projection} = $projection;
        $psbasemap->{_note} =
          $psbasemap->{_note} . ' -J' . $psbasemap->{_projection};
        $psbasemap->{_Step} =
          $psbasemap->{_Step} . ' -J' . $psbasemap->{_projection};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $psbasemap->{_Step} = 'gmt psbasemap ' . $psbasemap->{_Step};
        return ( $psbasemap->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $psbasemap->{_note} = 'psbasemap ' . $psbasemap->{_note};
        return ( $psbasemap->{_note} );
    }
}

1;
