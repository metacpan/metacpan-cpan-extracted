package App::SeismicUnixGui::gmt::pscoast;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: pscoast
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

pscoast(core) 5.4.3 (r19528) [64-bit] [MP] - Plot continents, countries, shorelines, rivers, and borders on maps

usage: pscoast -J<args> [-A<min_area>[/<min_level>/<max_level>][+ag|i|s|S][+r|l][+p<percent>]] [-B<args>]
	[-R<west>/<east>/<south>/<north>[/<zmin>/<zmax>][+r]] [-C[<feature>/]<fill>]
	[-D<resolution>][+] [-E<code1,code2,...>[+l|L][+g<fill>][+p<pen>][+r|R[<incs>]]] [-G[<fill>]]
	[-F[+c<clearance(s)>][+g<fill>][+i[[<gap>/]<pen>]][+p[<pen>]][+r[<radius>]][+s[<dx>/<dy>/][<fill>]]]
	[-I<feature>[/<pen>]] [-Jz|Z<args>] [-K]
	[-L[g|j|J|n|x]<refpoint>+c[<slon>/]<slat>+w<length>[e|f|M|n|k|u][+a<align>][+f][+j<justify>][+l[<label>]][+o<dx>[/<dy>]][+u]]
	[-M] [-N<feature>[/<pen>]] [-O] [-P] [-Q] [-S<fill>]
	[-Td[g|j|J|n|x]<refpoint>+w<width>[+f[<level>]][+j<justify>][+l<w,e,s,n>][+o<dx>[/<dy>]]]
	[-Tm[g|j|J|n|x]<refpoint>+w<width>[+d[<dec>[/<dlabel>]]][+i<pen>][+j<justify>][+l<w,e,s,n>][+p<pen>][+t<ints>][+o<dx>[/<dy>]]]
	[-U[[<just>]/<dx>/<dy>/][c|<label>]] [-V[<level>]] [-W[<feature>/][<pen>]]
	[-X[a|c|r]<xshift>[<unit>]] [-Y[a|c|r]<yshift>[<unit>]] [-bo[<ncol>][t][w][+L|B]] [-do<nodata>]
	[-p[x|y|z]<azim>[/<elev>[/<zlevel>]][+w<lon0>/<lat0>[/<z0>][+v<x0>/<y0>]] [-t<transp>] [-:[i|o]]

	-J Select map proJection. (<scale> in cm/degree, <width> in cm)
	   Append h for map height, or +|- for max|min map dimension.
	   Azimuthal projections set -Rg unless polar aspect or -R<...>r is set.

	   -Ja|A<lon0>/<lat0>[/<hor>]/<scl (or <radius>/<lat>)|<width> (Lambert Azimuthal EA)
	   -Jb|B<lon0>/<lat0>/<lat1>/<lat2>/<scl>|<width> (Albers Conic EA)
	   -Jcyl_stere|Cyl_stere/[<lon0>/[<lat0>/]]<lat1>/<lat2>/<scl>|<width> (Cylindrical Stereographic)
	   -Jc|C<lon0>/<lat0><scl>|<width> (Cassini)
	   -Jd|D<lon0>/<lat0>/<lat1>/<lat2>/<scl>|<width> (Equidistant Conic)
	   -Je|E<lon0>/<lat0>[/<horizon>]/<scl (or <radius>/<lat>)|<width>  (Azimuthal Equidistant)
	   -Jf|F<lon0>/<lat0>[/<horizon>]/<scl (or <radius>/<lat>)|<width>  (Gnomonic)
	   -Jg|G<lon0>/<lat0>/<scl (or <radius>/<lat>)|<width>  (Orthographic)
	   -Jg|G[<lon0>/]<lat0>[/<horizon>|/<altitude>/<azimuth>/<tilt>/<twist>/<Width>/<Height>]/<scl>|<width> (General Perspective)
	   -Jh|H[<lon0>/]<scl>|<width> (Hammer-Aitoff)
	   -Ji|I[<lon0>/]<scl>|<width> (Sinusoidal)
	   -Jj|J[<lon0>/]<scl>|<width> (Miller)
	   -Jkf|Kf[<lon0>/]<scl>|<width> (Eckert IV)
	   -Jks|Ks[<lon0>/]<scl>|<width> (Eckert VI)
	   -Jl|L<lon0>/<lat0>/<lat1>/<lat2>/<scl>|<width> (Lambert Conformal Conic)
	   -Jm|M[<lon0>/[<lat0>/]]<scl>|<width> (Mercator)
	   -Jn|N[<lon0>/]<scl>|<width> (Robinson projection)
	   -Jo|O (Oblique Mercator).  Specify one of three definitions:
	      -Jo|O[a|A]<lon0>/<lat0>/<azimuth>/<scl>|<width>
	      -Jo|O[b|B]<lon0>/<lat0>/<lon1>/<lat1>/<scl>|<width>
	      -Jo|Oc|C<lon0>/<lat0>/<lonp>/<latp>/<scl>|<width>
	   -Jpoly|Poly/[<lon0>/[<lat0>/]]<scl>|<width> ((American) Polyconic)
	   -Jq|Q[<lon0>/[<lat0>/]]<scl>|<width> (Equidistant Cylindrical)
	   -Jr|R[<lon0>/]<scl>|<width> (Winkel Tripel)
	   -Js|S<lon0>/<lat0>/[<horizon>/]<scl> (or <slat>/<scl> or <radius>/<lat>)|<width> (Stereographic)
	   -Jt|T<lon0>/[<lat0>/]<scl>|<width> (Transverse Mercator)
	   -Ju|U[<zone>/]<scl>|<width> (UTM)
	   -Jv|V<lon0>/<scl>|<width> (van der Grinten)
	   -Jw|W<lon0>/<scl>|<width> (Mollweide)
	   -Jy|Y[<lon0>/[<lat0>/]]<scl>|<width> (Cylindrical Equal-area)
	   -Jp|P[a]<scl>|<width>[/<origin>][r|z] (Polar [azimuth] (theta,radius))
	   -Jx|X<x-scl>|<width>[d|l|p<power>|t|T][/<y-scl>|<height>[d|l|p<power>|t|T]] (Linear, log, and power projections)
	   (See psbasemap for more details on projection syntax)
	   -JZ|z For z component of 3-D projections.  Same syntax as -JX|x, i.e.,
	   -Jz|Z<z-scl>|<height>[d|l|p<power>|t|T] (Linear, log, and power projections)
	-R Specify the west/east/south/north coordinates of map region.
	   Use decimal degrees or ddd[:mm[:ss]] degrees [ and minutes [and seconds]].
	   Use -R<unit>... for regions given in projected coordinates.
	   Append r if -R specifies the coordinates of the lower left and
	   upper right corners of a rectangular map area.
	   -Rg and -Rd are shorthands for -R0/360/-90/90 and -R-180/180/-90/90.
	   Or, give a gridfile to use its limits (and increments if applicable).

	OPTIONS:
	-A Place limits on coastline features from the GSHHG data base.
	   Features smaller than <min_area> (in km^2) or of levels (0-4) outside the min-max levels
	   will be skipped [0/4 (4 means lake inside island inside lake)].
	   Append +as to skip Antarctica (all data south of 60S) [use all].
	   Append +aS to skip anything BUT Antarctica (all data north of 60S) [use all].
	   Append +ag to use shelf ice grounding line for Antarctica coastline.
	   Append +ai to use ice/water front for Antarctica coastline [Default].
	   Append +r to only get riverlakes from level 2, or +l to only get lakes [both].
	   Append +p<percent> to exclude features whose size is < <percent>0f the full-resolution feature [use all].
	-B Specify both (1) basemap frame settings and (2) axes parameters.
	   (1) Frame settings are modified via an optional single invocation of
	     -B[<axes>][+g<fill>][+n][+o<lon>/<lat>][+t<title>]
	   (2) Axes parameters are specified via one or more invocations of
	       -B[p|s][x|y|z]<intervals>[+l<label>][+p<prefix>][+u<unit>]
	   <intervals> is composed of concatenated [<type>]<stride>[<unit>][l|p] sub-strings
	   See psbasemap man page for more details and examples of all settings.
	-C<fill> Set separate color for lakes and riverlakes [Default is same as ocean]. Specify <fill> as one of:
	   1) <gray> or <red>/<green>/<blue>, all in the range 0-255;
	   2) <c>/<m>/<y>/<k> in range 0-100%;
	   3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1;
	   4) any valid color name;
	   5) P|p<pattern>[+b<color>][+f<color>][+r<dpi>];
	      Give <pattern> number from 1-90 or a filename, optionally add +r<dpi> [300].
	      Optionally, use +f,+b to change fore- or background colors (set - for transparency).
	   For PDF fill transparency, append @<transparency> in the range 0-100 [0 = opaque].
	   Alternatively, set custom fills below.  Repeat the -C option as needed.
	      l = Lakes.
	      r = River-lakes.
	-D Choose one of the following resolutions:
	   a - auto: select best resolution given map scale.
	   f - full resolution (may be very slow for large regions).
	   h - high resolution (may be slow for large regions).
	   i - intermediate resolution.
	   l - low resolution [Default].
	   c - crude resolution, for busy plots that need crude continent outlines only.
	   Append + to use a lower resolution should the chosen one not be available [abort].
	-E Apply different fill or outline to specified list of countries.
	   Based on closed polygons from the Digital Chart of the World (DCW).
	   Append comma-separated list of ISO 3166 codes for countries to plot, i.e.,
	   <code1>,<code2>,... etc., using the 2-character country codes.
	   To select a state of a country (if available), append .state, e.g, US.TX for Texas.
	   To select a whole continent, use =AF|AN|AS|EU|OC|NA|SA as <code>.
	   Append +l to just list the countries and their codes [no plotting takes place].
	   Use +L to see states/territories for Australia, Brazil, Canada, and the US.
	   Use +r to obtain -Rw/e/s/n from polygon(s). Append <inc>, <xinc>/<yinc>, or <winc>/<einc>/<sinc>/<ninc>
	     for a region in these multiples [none].  Use +R to extend region by increments instead [0].
	   Append +p<pen> to draw outline [none] and +g<fill> to fill [none].
	   One of +p|g must be specified to plot; if -M is in effect we just get the data.
	   Repeat -F to give different groups of items separate pen/fill settings.
	   If modifier +r or +R is given and +w is present then we just print the -Rstring.
	-F Specify a rectangular panel behind the map scale or rose
	   Without further options: draw border around the scale panel (using MAP_FRAME_PEN)
	     [Default is no border].
	   Append +c<clearance> where <clearance> is <gap>, <xgap/ygap>, or <lgap/rgap/bgap/tgap> [4p].
	     Note: For a map insert the default clearance is zero.
	   Append +g<fill> to set the fill for the scale panel [Default is no fill].
	   Append +i[[<gap>/]<pen>] to add a secondary inner frame boundary [Default gap is 2p].
	   Append +p[<pen>] to draw the border and optionally change the border pen [thicker,black].
	   Append +r[<radius>] to plot rounded rectangles instead [Default radius is 6p].
	   Append +s[<dx>/<dy>/][<shade>] to plot a shadow behind the scale panel [Default is 4p/-4/gray50].
	   If using both -L and -T, you can repeat -F following each option.
	-G<fill> Paint or clip "dry" areas. Specify <fill> as one of:
	   1) <gray> or <red>/<green>/<blue>, all in the range 0-255;
	   2) <c>/<m>/<y>/<k> in range 0-100%;
	   3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1;
	   4) any valid color name;
	   5) P|p<pattern>[+b<color>][+f<color>][+r<dpi>];
	      Give <pattern> number from 1-90 or a filename, optionally add +r<dpi> [300].
	      Optionally, use +f,+b to change fore- or background colors (set - for transparency).
	   For PDF fill transparency, append @<transparency> in the range 0-100 [0 = opaque].
	   6) c to issue clip paths for land areas.
	-I Draw rivers.  Specify feature and optionally append pen [Default for all levels: default,black].
	   <pen> is a comma-separated list of three optional items in the order:
	       <width>[c|i|p], <color>, and <style>[c|i|p].
	   <width> >= 0.0 sets pen width (default units are points); alternatively a pen
	       name: Choose among faint, default, or [thin|thick|fat][er|est], or obese.
	   <color> = (1) <gray> or <red>/<green>/<blue>, all in range 0-255,
	             (2) <c>/<m>/<y>/<k> in 0-100% range,
	             (3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1,
	             (4) any valid color name.
	   <style> = (1) pattern of dashes (-) and dots (.), scaled by <width>.
	             (2) "dashed", "dotted", or "solid".
	             (3) <pattern>:<offset>; <pattern> holds lengths (default unit points)
	                 of any number of lines and gaps separated by underscores.
	                 <offset> shifts elements from start of the line [0].
	   For PDF stroke transparency, append @<transparency> in the range 0-100% [0 = opaque].
	   Choose from the features below.  Repeat the -I option as many times as needed.
	      0 = Double-lined rivers (river-lakes).
	      1 = Permanent major rivers.
	      2 = Additional major rivers.
	      3 = Additional rivers.
	      4 = Minor rivers.
	      5 = Intermittent rivers - major.
	      6 = Intermittent rivers - additional.
	      7 = Intermittent rivers - minor.
	      8 = Major canals.
	      9 = Minor canals.
	     10 = Irrigation canals.
	     Alternatively, specify preselected river groups:
	      a = All rivers and canals (0-10).
	      A = All rivers and canals except river-lakes (1-10).
	      r = All permanent rivers (0-4).
	      R = All permanent rivers except river-lakes (1-4).
	      i = All intermittent rivers (5-7).
	      c = All canals (8-10).
	-K Allow for more plot code to be appended later.
	-L Draw a map scale at specified reference point.
	   Positioning is specified via one of four coordinate systems:
	     Use -Lg to specify <refpoint> with map coordinates.
	     Use -Lj or -LJ to specify <refpoint> with 2-char justification code (BL, MC, etc).
	     Use -Ln to specify <refpoint> with normalized coordinates in 0-1 range.
	     Use -Lx to specify <refpoint> with plot coordinates.
	   All except -Lx require the -R and -J options to be set.
	   Append 2-char +j<justify> code to associate that anchor point on the map scale with <refpoint>.
	   If +j<justify> is not given then <justify> will default to the same as <refpoint> (with -Lj),
	     or the mirror opposite of <refpoint> (with -LJ), or MC (else).
	   Optionally, append +o<dx>[/<dy>] to offset map scale from <refpoint> in direction implied by <justify> [0/0].
	   Use +c<slat> (with central longitude) or +c<slon>/<slat> to specify scale origin.
	   Set scale length with +w<length> and append a unit from e|f|k|M|n|u [km].
	   Several modifiers are optional:
	   Add +f to draw a "fancy" scale [Default is plain].
	   By default, the scale label equals the distance unit name and is placed on top [+at].  Use the +l<label>
	   and +a<align> mechanisms to specify another label and placement (t,b,l,r).  For the fancy scale,
	   +u appends units to annotations while for plain scale it uses unit abbreviation instead of name as label.
	-M Dump a multisegment ASCII (or binary, see -bo) file to standard output.  No plotting occurs.
	   Specify one of -E, -I, -N, or -W.
	-N Draw boundaries.  Specify feature and optionally append pen [Default for all levels: default,black].
	   <pen> is a comma-separated list of three optional items in the order:
	       <width>[c|i|p], <color>, and <style>[c|i|p].
	   <width> >= 0.0 sets pen width (default units are points); alternatively a pen
	       name: Choose among faint, default, or [thin|thick|fat][er|est], or obese.
	   <color> = (1) <gray> or <red>/<green>/<blue>, all in range 0-255,
	             (2) <c>/<m>/<y>/<k> in 0-100% range,
	             (3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1,
	             (4) any valid color name.
	   <style> = (1) pattern of dashes (-) and dots (.), scaled by <width>.
	             (2) "dashed", "dotted", or "solid".
	             (3) <pattern>:<offset>; <pattern> holds lengths (default unit points)
	                 of any number of lines and gaps separated by underscores.
	                 <offset> shifts elements from start of the line [0].
	   For PDF stroke transparency, append @<transparency> in the range 0-100% [0 = opaque].
	   Choose from the features below.  Repeat the -N option as many times as needed.
	     1 = National boundaries.
	     2 = State boundaries within the Americas.
	     3 = Marine boundaries.
	     a = All boundaries (1-3).
	-O Set Overlay plot mode, i.e., append to an existing plot.
	-P Set Portrait page orientation [OFF].
	-Q Terminate previously set clip-paths.
	-S<fill> Paint of clip "wet" areas. Specify <fill> as one of:
	   1) <gray> or <red>/<green>/<blue>, all in the range 0-255;
	   2) <c>/<m>/<y>/<k> in range 0-100%;
	   3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1;
	   4) any valid color name;
	   5) P|p<pattern>[+b<color>][+f<color>][+r<dpi>];
	      Give <pattern> number from 1-90 or a filename, optionally add +r<dpi> [300].
	      Optionally, use +f,+b to change fore- or background colors (set - for transparency).
	   For PDF fill transparency, append @<transparency> in the range 0-100 [0 = opaque].
	   6) c to issue clip paths for water areas.
	-T Draw a north-pointing map rose at specified reference point.
	   Choose between a directional (-Td) or magnetic (-Tm) rose.
	   Both share most modifiers for locating and sizing the rose.
	   Positioning is specified via one of four coordinate systems:
	     Use -Td|mg to specify <refpoint> with map coordinates.
	     Use -Td|mj or -Td|mJ to specify <refpoint> with 2-char justification code (BL, MC, etc).
	     Use -Td|mn to specify <refpoint> with normalized coordinates in 0-1 range.
	     Use -Td|mx to specify <refpoint> with plot coordinates.
	   All except -Td|mx require the -R and -J options to be set.
	   Append 2-char +j<justify> code to associate that anchor point on the map rose with <refpoint>.
	   If +j<justify> is not given then <justify> will default to the same as <refpoint> (with -Td|mj),
	     or the mirror opposite of <refpoint> (with -Td|mJ), or MC (else).
	   Optionally, append +o<dx>[/<dy>] to offset map rose from <refpoint> in direction implied by <justify> [0/0].
	   Set the diameter of the rose with modifier +w<width>.
	   Several modifiers are optional:
	   Add labels with +l, which places the letters W, E, S, N at the cardinal points.
	     Optionally, append comma-separated west, east, south, north labels instead.
	   Directional rose: Add +f to draws a "fancy" rose [Default is plain].
	     Optionally, add <level> of fancy rose: 1 draws E-W, N-S directions [Default],
	     2 adds NW-SE and NE-SW, while 3 adds WNW-ESE, NNW-SSE, NNE-SSW, and ENE-WSW directions.
	   Magnetic compass rose:  Optional add +d<dec>[/<dlabel>], where <dec> is the
	     magnetic declination and <dlabel> is an optional label for the magnetic compass needle.
	     If +d does not include <dlabel> we default to "delta = <declination>".
	     Set <dlabel> to "-" to disable the declination label.
	     Append +p<pen> to draw outline of secondary (outer) circle [no circle].
	     Append +i<pen> to draw outline of primary (inner) circle [no circle].
	     Append +t<pint>[/<sint>] to override default primary and secondary annotation/tick interval(s) [30/5/1].
	   If the North label = '*' then a north star is plotted instead of the label.
	-U Plot Unix System Time stamp [and optionally appended text].
	   You may also set the reference points and position of stamp
	   [BL/-1.905c/-1.905c].  Give -Uc to have the command line plotted [OFF].
	-V Change the verbosity level (currently v).
	   Choose among 6 levels; each level adds more messages:
	     q - Quiet, not even fatal error messages.
	     n - Normal verbosity: only error messages.
	     c - Also produce compatibility warnings [Default when no -V is used].
	     v - Verbose progress messages [Default when -V is used].
	     l - Long verbose progress messages.
	     d - Debugging messages.
	-W Draw shorelines.  Append pen [Default for all levels: default,black].
	   <pen> is a comma-separated list of three optional items in the order:
	       <width>[c|i|p], <color>, and <style>[c|i|p].
	   <width> >= 0.0 sets pen width (default units are points); alternatively a pen
	       name: Choose among faint, default, or [thin|thick|fat][er|est], or obese.
	   <color> = (1) <gray> or <red>/<green>/<blue>, all in range 0-255,
	             (2) <c>/<m>/<y>/<k> in 0-100% range,
	             (3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1,
	             (4) any valid color name.
	   <style> = (1) pattern of dashes (-) and dots (.), scaled by <width>.
	             (2) "dashed", "dotted", or "solid".
	             (3) <pattern>:<offset>; <pattern> holds lengths (default unit points)
	                 of any number of lines and gaps separated by underscores.
	                 <offset> shifts elements from start of the line [0].
	   For PDF stroke transparency, append @<transparency> in the range 0-100% [0 = opaque].
	   Alternatively, set custom pens below.  Repeat the -W option as many times as needed.
	      1 = Coastline.
	      2 = Lake shores.
	      3 = Island in lakes shores.
	      4 = Lake in island in lake shores.
	   When feature-specific pens are used, those not set are deactivated.
	-X -Y Shift origin of plot to (<xshift>, <yshift>).
	   Prepend r for shift relative to current point (default), prepend a for temporary
	   adjustment of origin, prepend f to position relative to lower left corner of page,
	   prepend c for offset of center of plot to center of page.
	   For overlays (-O), the default setting is [r0], otherwise [f2.54c].
	-bo For binary output; append <type>[w][+L|B]; <type> = c|u|h|H|i|I|l|L|f|D..
	    Prepend <n> for the number of columns for each <type>.
	-do Replace any NaNs in output data with <nodata>.
	-p Select a 3-D pseudo perspective view.  Append the
	   azimuth and elevation of the viewpoint [180/90].
	   When used with -Jz|Z, optionally add zlevel for frame, etc. [bottom of z-axis]
	   Optionally, append +w<lon/lat[/z] to specify a fixed point
	   and +vx/y for its justification.  Just append + by itself
	   to select default values [region center and page center].
	   For a plain rotation about the z-axis, give rotation angle only
	   and optionally use +w or +v to select location of axis [plot origin].
	-t Set the layer PDF transparency from 0-100 [Default is 0; opaque].
	-^ (or -) Print short synopsis message.
	-+ (or +) Print longer synopsis message.
	-? (or no arguments) Print this usage message
	(See gmt.conf man page for GMT default parameters).

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

my $pscoast = {
    _J          => '',
    _Rg         => '',
    _R          => '',
    _Rg         => '',
    _A          => '',
    _B          => '',
    _C          => '',
    _D          => '',
    _E          => '',
    _F          => '',
    _L          => '',
    _I          => '',
    _I          => '',
    _K          => '',
    _L          => '',
    _Lg         => '',
    _Lj         => '',
    _Ln         => '',
    _Lx         => '',
    _Lx         => '',
    _M          => '',
    _N          => '',
    _O          => '',
    _P          => '',
    _Q          => '',
    _T          => '',
    _U          => '',
    _Uc         => '',
    _V          => '',
    _W          => '',
    _W          => '',
    _X          => '',
    _bo         => '',
    _do         => '',
    _p          => '',
    _t          => '',
    _infile     => '',
    _outfile    => '',
    _limits     => '',
    _projection => '',
    _no_head    => '',
    _no_tail    => '',
    _verbose    => '',
    _Step       => '',
    _note       => '',
};

=head2 sub clear

=cut

sub clear {
    $pscoast->{_J}          = '';
    $pscoast->{_Rg}         = '';
    $pscoast->{_R}          = '';
    $pscoast->{_Rg}         = '';
    $pscoast->{_A}          = '';
    $pscoast->{_B}          = '';
    $pscoast->{_C}          = '';
    $pscoast->{_D}          = '';
    $pscoast->{_E}          = '';
    $pscoast->{_M}          = '';
    $pscoast->{_F}          = '';
    $pscoast->{_F}          = '';
    $pscoast->{_L}          = '';
    $pscoast->{_I}          = '';
    $pscoast->{_I}          = '';
    $pscoast->{_K}          = '';
    $pscoast->{_L}          = '';
    $pscoast->{_Lg}         = '';
    $pscoast->{_Lj}         = '';
    $pscoast->{_Ln}         = '';
    $pscoast->{_Lx}         = '';
    $pscoast->{_Lx}         = '';
    $pscoast->{_M}          = '';
    $pscoast->{_N}          = '';
    $pscoast->{_O}          = '';
    $pscoast->{_P}          = '';
    $pscoast->{_Q}          = '';
    $pscoast->{_T}          = '';
    $pscoast->{_U}          = '';
    $pscoast->{_Uc}         = '';
    $pscoast->{_V}          = '';
    $pscoast->{_W}          = '';
    $pscoast->{_W}          = '';
    $pscoast->{_X}          = '';
    $pscoast->{_bo}         = '';
    $pscoast->{_do}         = '';
    $pscoast->{_p}          = '';
    $pscoast->{_t}          = '';
    $pscoast->{_infile}     = '';
    $pscoast->{_outfile}    = '';
    $pscoast->{_limits}     = '';
    $pscoast->{_projection} = '';
    $pscoast->{_no_head}    = '';
    $pscoast->{_no_tail}    = '';
    $pscoast->{_verbose}    = '';
    $pscoast->{_Step}       = '';
    $pscoast->{_note}       = '';
}

=head2 sub J 


=cut

sub J {
    my ( $self, $J ) = @_;
    if ($J) {
        $pscoast->{_J}    = $J;
        $pscoast->{_note} = $pscoast->{_note} . ' -J' . $pscoast->{_J};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -J' . $pscoast->{_J};
    }
}

=head2 sub Rg 


=cut

sub Rg {
    my ( $self, $Rg ) = @_;
    if ($Rg) {
        $pscoast->{_Rg}   = $Rg;
        $pscoast->{_note} = $pscoast->{_note} . ' -Rg' . $pscoast->{_Rg};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -Rg' . $pscoast->{_Rg};
    }
}

=head2 sub R 


=cut

sub R {
    my ( $self, $R ) = @_;
    if ($R) {
        $pscoast->{_R}    = $R;
        $pscoast->{_note} = $pscoast->{_note} . ' -R' . $pscoast->{_R};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -R' . $pscoast->{_R};
    }
}

=head2 sub A 


=cut

sub A {
    my ( $self, $A ) = @_;
    if ($A) {
        $pscoast->{_A}    = $A;
        $pscoast->{_note} = $pscoast->{_note} . ' -A' . $pscoast->{_A};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -A' . $pscoast->{_A};
    }
}

=head2 sub B 


=cut

sub B {
    my ( $self, $B ) = @_;
    if ($B) {
        $pscoast->{_B}    = $B;
        $pscoast->{_note} = $pscoast->{_note} . ' -B' . $pscoast->{_B};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -B' . $pscoast->{_B};
    }
}

=head2 sub C 


=cut

sub C {
    my ( $self, $C ) = @_;
    if ($C) {
        $pscoast->{_C}    = $C;
        $pscoast->{_note} = $pscoast->{_note} . ' -C' . $pscoast->{_C};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -C' . $pscoast->{_C};
    }
}

=head2 sub D 


=cut

sub D {
    my ( $self, $D ) = @_;
    if ($D) {
        $pscoast->{_D}    = $D;
        $pscoast->{_note} = $pscoast->{_note} . ' -D' . $pscoast->{_D};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -D' . $pscoast->{_D};
    }
}

=head2 sub E 


=cut

sub E {
    my ( $self, $E ) = @_;
    if ($E) {
        $pscoast->{_E}    = $E;
        $pscoast->{_note} = $pscoast->{_note} . ' -E' . $pscoast->{_E};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -E' . $pscoast->{_E};
    }
}

=head2 sub M 


=cut

sub M {
    my ( $self, $M ) = @_;
    if ($M) {
        $pscoast->{_M}    = $M;
        $pscoast->{_note} = $pscoast->{_note} . ' -M' . $pscoast->{_M};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -M' . $pscoast->{_M};
    }
}

=head2 sub F 


=cut

sub F {
    my ( $self, $F ) = @_;
    if ($F) {
        $pscoast->{_F}    = $F;
        $pscoast->{_note} = $pscoast->{_note} . ' -F' . $pscoast->{_F};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -F' . $pscoast->{_F};
    }
}

=head2 sub L 


=cut

sub L {
    my ( $self, $L ) = @_;
    if ($L) {
        $pscoast->{_L}    = $L;
        $pscoast->{_note} = $pscoast->{_note} . ' -L' . $pscoast->{_L};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -L' . $pscoast->{_L};
    }
}

=head2 sub I 


=cut

sub I {
    my ( $self, $I ) = @_;
    if ($I) {
        $pscoast->{_I}    = $I;
        $pscoast->{_note} = $pscoast->{_note} . ' -I' . $pscoast->{_I};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -I' . $pscoast->{_I};
    }
}

=head2 sub K 


=cut

sub K {
    my ( $self, $K ) = @_;
    if ($K) {
        $pscoast->{_K}    = $K;
        $pscoast->{_note} = $pscoast->{_note} . ' -K' . $pscoast->{_K};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -K' . $pscoast->{_K};
    }
}

=head2 sub Lg 


=cut

sub Lg {
    my ( $self, $Lg ) = @_;
    if ($Lg) {
        $pscoast->{_Lg}   = $Lg;
        $pscoast->{_note} = $pscoast->{_note} . ' -Lg' . $pscoast->{_Lg};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -Lg' . $pscoast->{_Lg};
    }
}

=head2 sub Lj 


=cut

sub Lj {
    my ( $self, $Lj ) = @_;
    if ($Lj) {
        $pscoast->{_Lj}   = $Lj;
        $pscoast->{_note} = $pscoast->{_note} . ' -Lj' . $pscoast->{_Lj};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -Lj' . $pscoast->{_Lj};
    }
}

=head2 sub Ln 


=cut

sub Ln {
    my ( $self, $Ln ) = @_;
    if ($Ln) {
        $pscoast->{_Ln}   = $Ln;
        $pscoast->{_note} = $pscoast->{_note} . ' -Ln' . $pscoast->{_Ln};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -Ln' . $pscoast->{_Ln};
    }
}

=head2 sub Lx 


=cut

sub Lx {
    my ( $self, $Lx ) = @_;
    if ($Lx) {
        $pscoast->{_Lx}   = $Lx;
        $pscoast->{_note} = $pscoast->{_note} . ' -Lx' . $pscoast->{_Lx};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -Lx' . $pscoast->{_Lx};
    }
}

=head2 sub N 


=cut

sub N {
    my ( $self, $N ) = @_;
    if ($N) {
        $pscoast->{_N}    = $N;
        $pscoast->{_note} = $pscoast->{_note} . ' -N' . $pscoast->{_N};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -N' . $pscoast->{_N};
    }
}

=head2 sub O 


=cut

sub O {
    my ( $self, $O ) = @_;
    if ($O) {
        $pscoast->{_O}    = $O;
        $pscoast->{_note} = $pscoast->{_note} . ' -O' . $pscoast->{_O};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -O' . $pscoast->{_O};
    }
}

=head2 sub P 


=cut

sub P {
    my ( $self, $P ) = @_;
    if ($P) {
        $pscoast->{_P}    = $P;
        $pscoast->{_note} = $pscoast->{_note} . ' -P' . $pscoast->{_P};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -P' . $pscoast->{_P};
    }
}

=head2 sub Q 


=cut

sub Q {
    my ( $self, $Q ) = @_;
    if ($Q) {
        $pscoast->{_Q}    = $Q;
        $pscoast->{_note} = $pscoast->{_note} . ' -Q' . $pscoast->{_Q};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -Q' . $pscoast->{_Q};
    }
}

=head2 sub T 


=cut

sub T {
    my ( $self, $T ) = @_;
    if ($T) {
        $pscoast->{_T}    = $T;
        $pscoast->{_note} = $pscoast->{_note} . ' -T' . $pscoast->{_T};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -T' . $pscoast->{_T};
    }
}

=head2 sub U 


=cut

sub U {
    my ( $self, $U ) = @_;
    if ($U) {
        $pscoast->{_U}    = $U;
        $pscoast->{_note} = $pscoast->{_note} . ' -U' . $pscoast->{_U};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -U' . $pscoast->{_U};
    }
}

=head2 sub Uc 


=cut

sub Uc {
    my ( $self, $Uc ) = @_;
    if ($Uc) {
        $pscoast->{_Uc}   = $Uc;
        $pscoast->{_note} = $pscoast->{_note} . ' -Uc' . $pscoast->{_Uc};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -Uc' . $pscoast->{_Uc};
    }
}

=head2 sub V 


=cut

sub V {
    my ( $self, $V ) = @_;
    if ($V) {
        $pscoast->{_V}    = $V;
        $pscoast->{_note} = $pscoast->{_note} . ' -V' . $pscoast->{_V};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -V' . $pscoast->{_V};
    }
}

=head2 sub W 


=cut

sub W {
    my ( $self, $W ) = @_;
    if ($W) {
        $pscoast->{_W}    = $W;
        $pscoast->{_note} = $pscoast->{_note} . ' -W' . $pscoast->{_W};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -W' . $pscoast->{_W};
    }
}

=head2 sub X 


=cut

sub X {
    my ( $self, $X ) = @_;
    if ($X) {
        $pscoast->{_X}    = $X;
        $pscoast->{_note} = $pscoast->{_note} . ' -X' . $pscoast->{_X};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -X' . $pscoast->{_X};
    }
}

=head2 sub bo 


=cut

sub bo {
    my ( $self, $bo ) = @_;
    if ($bo) {
        $pscoast->{_bo}   = $bo;
        $pscoast->{_note} = $pscoast->{_note} . ' -bo' . $pscoast->{_bo};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -bo' . $pscoast->{_bo};
    }
}

=head2 sub do 


=cut

sub do {
    my ( $self, $do ) = @_;
    if ($do) {
        $pscoast->{_do}   = $do;
        $pscoast->{_note} = $pscoast->{_note} . ' -do' . $pscoast->{_do};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -do' . $pscoast->{_do};
    }
}

=head2 sub p 


=cut

sub p {
    my ( $self, $p ) = @_;
    if ($p) {
        $pscoast->{_p}    = $p;
        $pscoast->{_note} = $pscoast->{_note} . ' -p' . $pscoast->{_p};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -p' . $pscoast->{_p};
    }
}

=head2 sub t 


=cut

sub t {
    my ( $self, $t ) = @_;
    if ($t) {
        $pscoast->{_t}    = $t;
        $pscoast->{_note} = $pscoast->{_note} . ' -t' . $pscoast->{_t};
        $pscoast->{_Step} = $pscoast->{_Step} . ' -t' . $pscoast->{_t};
    }
}

=head2 sub infile 


=cut

sub infile {
    my ( $self, $infile ) = @_;
    if ($infile) {
        $pscoast->{_infile} = $infile;
        $pscoast->{_note}   = $pscoast->{_note} . ' ' . $pscoast->{_infile};
        $pscoast->{_Step}   = $pscoast->{_Step} . ' ' . $pscoast->{_infile};
    }
}

=head2 sub outfile 


=cut

sub outfile {
    my ( $self, $outfile ) = @_;
    if ($outfile) {
        $pscoast->{_outfile} = $outfile;
        $pscoast->{_note}    = $pscoast->{_note} . ' -G' . $pscoast->{_outfile};
        $pscoast->{_Step}    = $pscoast->{_Step} . ' -G' . $pscoast->{_outfile};
    }
}

=head2 sub limits 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $pscoast->{_limits} = $limits;
        $pscoast->{_note}   = $pscoast->{_note} . ' -R' . $pscoast->{_limits};
        $pscoast->{_Step}   = $pscoast->{_Step} . ' -R' . $pscoast->{_limits};
    }
}

=head2 sub no_head 


=cut

sub no_head {
    my ( $self, $no_head ) = @_;
    if ($no_head) {
        $pscoast->{_no_head} = $no_head;
        $pscoast->{_note}    = $pscoast->{_note} . ' -K' . $pscoast->{_no_head};
        $pscoast->{_Step}    = $pscoast->{_Step} . ' -K' . $pscoast->{_no_head};
    }
}

=head2 sub no_tail 


=cut

sub no_tail {
    my ( $self, $no_tail ) = @_;
    if ($no_tail) {
        $pscoast->{_no_tail} = $no_tail;
        $pscoast->{_note}    = $pscoast->{_note} . ' -O' . $pscoast->{_no_tail};
        $pscoast->{_Step}    = $pscoast->{_Step} . ' -O' . $pscoast->{_no_tail};
    }
}

=head2 sub projection 


=cut

sub projection {
    my ( $self, $projection ) = @_;
    if ($projection) {
        $pscoast->{_projection} = $projection;
        $pscoast->{_note} =
          $pscoast->{_note} . ' -J' . $pscoast->{_projection};
        $pscoast->{_Step} =
          $pscoast->{_Step} . ' -J' . $pscoast->{_projection};
    }
}

=head2 sub verbose 


=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ( $verbose eq $on ) {
        $pscoast->{_verbose} = '';
        $pscoast->{_Step}    = $pscoast->{_Step} . ' -V' . $pscoast->{_verbose};
        $pscoast->{_note}    = $pscoast->{_note} . ' -V' . $pscoast->{_verbose};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $pscoast->{_Step} = 'gmt pscoast ' . $pscoast->{_Step};
        return ( $pscoast->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $pscoast->{_note} = 'pscoast ' . $pscoast->{_note};
        return ( $pscoast->{_note} );
    }
}

1;
