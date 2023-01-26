package App::SeismicUnixGui::gmt::psxy;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: psxy
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

psxy(core) 5.4.3 (r19528) [64-bit] [MP] - Plot lines, polygons, and symbols on maps

usage: psxy [<table>] -J<args> -R<west>/<east>/<south>/<north>[/<zmin>/<zmax>][+r] [-A[m|p|x|y]]
	[-B<args>] [-C<cpt>] [-D<dx>/<dy>] [-E[x|y|X|Y][+a][+c[l|f]][+n][+p<pen>][+w<width>]] [-F<arg>] [-G<fill>]
	[-I<intens>] [-K] [-L[+b|d|D][+xl|r|x0][+yb|t|y0][+p<pen>]] [-N[c|r]] [-O] [-P]
	[-S[<symbol>][<size>[unit]]] [-T] [-U[[<just>]/<dx>/<dy>/][c|<label>]] [-V[<level>]] [-W[<pen>][<attr>]]
	[-X[a|c|r]<xshift>[<unit>]] [-Y[a|c|r]<yshift>[<unit>]] [-a<col>=<name>[,...]]
	[-bi[<ncol>][t][w][+L|B]] [-di<nodata>] [-e[~]<pattern>]
	[-f[i|o]<info>] [-g[a]x|y|d|X|Y|D|[<col>]z[-|+]<gap>[<unit>]] [-h[i|o][<nrecs>][+c][+d][+r<remark>][+t<title>]]
	[-i<cols>[+l][+s<scale>][+o<offset>][,...]] [-p[x|y|z]<azim>[/<elev>[/<zlevel>]][+w<lon0>/<lat0>[/<z0>][+v<x0>/<y0>]]
	[-t<transp>] [-:[i|o]]

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
	-R Specify the min/max coordinates of data region in user units.
	   Use dd:mm[:ss] for regions given in degrees, minutes [and seconds].
	   Use -R<unit>... for regions given in projected coordinates.
	   Use [yyy[-mm[-dd]]]T[hh[:mm[:ss[.xxx]]]] format for time axes.
	   Append r if -R specifies the coordinates of the lower left and
	   upper right corners of a rectangular area.
	   -Rg and -Rd are shorthands for -R0/360/-90/90 and -R-180/180/-90/90.
	   Or use -R<code><x0>/<y0>/<n_columns>/<n_rows> for origin and grid dimensions, where
	     <code> is a 2-char combo from [T|M|B][L|C|R] (top/middle/bottom/left/center/right)
	     and grid spacing must be specified via -I<dx>[/<dy>] (also see -r).
	   Or, give a gridfile to use its limits (and increments if applicable).

	OPTIONS:
	<table> is one or more data files (in ASCII, binary, netCDF).
	   If no files are given, standard input is read.
	-A Suppress drawing geographic line segments as great circle arcs, i.e., draw
	   straight lines unless m or p is appended to first follow meridian
	   then parallel, or vice versa.
	   For Cartesian data, use -Ax or -Ay to draw x- or y-staircase curves.
	-B Specify both (1) basemap frame settings and (2) axes parameters.
	   (1) Frame settings are modified via an optional single invocation of
	     -B[<axes>][+g<fill>][+n][+o<lon>/<lat>][+t<title>]
	   (2) Axes parameters are specified via one or more invocations of
	       -B[p|s][x|y|z]<intervals>[+l<label>][+p<prefix>][+u<unit>]
	   <intervals> is composed of concatenated [<type>]<stride>[<unit>][l|p] sub-strings
	   See psbasemap man page for more details and examples of all settings.
	-C Use CPT (or specify -Ccolor1,color2[,color3,...]) to assign symbol
	   colors based on z-value in 3rd column.
	   Note: requires -S. Without -S, psxy excepts lines/polygons
	   and looks for -Z<val> options in each segment header. Then, color is
	   applied for polygon fill (-L) or polygon pen (no -L).
	-D Offset symbol or line positions by <dx>/<dy> [no offset].
	-E Draw (symmetrical) standard error bars for x and/or y.  Append +a for
	   asymmetrical errors (reads two columns) [symmetrical reads one column].
	   If X or Y are specified instead then a box-and-whisker diagram is drawn,
	   requiring four extra columns with the 0%, 25%, 75%, and 1000antiles.
	   (The x or y coordinate is expected to represent the 500antile.)
	   Add cap-width with +w [7p] and error pen attributes with +p<pen>
	   Given -C, use +cl to apply cpt color to error pen and +cf for error fill [both].
	   Append +n for a notched box-and whisker (notch width represents uncertainty.
	   in the median.  A 5th extra column with the sample size is required.
	   The settings of -W, -G affect the appearance of the 25-750ox.
	-F Alter the way points are connected and the data are segmented.
	    Append one of three line connection schemes:
	     c: Draw continuous line segments for each group [Default].
	     r: Draw line segments from a reference point reset for each group.
	     n: Draw networks of line segments between all points in each group.
	     Optionally, append one of five ways to define a "group":
	       a: All data is consider a single group; reference point is first point in the group.
	       f: Each file is a separate group; reference point is reset to first point in the group.
	       s: Each segment is a group; reference point is reset to first point in the group [Default].
	       r: Each segment is a group, but reference point is reset to each point in the group.
	          Only available with the -Fr scheme.
	       <refpoint> : Specify a fixed external reference point instead.
	-G<fill> Specify color or pattern [no fill]. Specify <fill> as one of:
	   1) <gray> or <red>/<green>/<blue>, all in the range 0-255;
	   2) <c>/<m>/<y>/<k> in range 0-100%;
	   3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1;
	   4) any valid color name;
	   5) P|p<pattern>[+b<color>][+f<color>][+r<dpi>];
	      Give <pattern> number from 1-90 or a filename, optionally add +r<dpi> [300].
	      Optionally, use +f,+b to change fore- or background colors (set - for transparency).
	   For PDF fill transparency, append @<transparency> in the range 0-100 [0 = opaque].
	   -G option can be present in all segment headers (not with -S).
	-I Use the intensity to modulate the fill color (requires -C or -G).
	-K Allow for more plot code to be appended later.
	-L Force closed polygons.  Alternatively, append modifiers to build polygon from a line.
	   Append +d to build symmetrical envelope around y(x) using deviations dy(x) from col 3.
	   Append +D to build asymmetrical envelope around y(x) using deviations dy1(x) and dy2(x) from cols 3-4.
	   Append +b to build asymmetrical envelope around y(x) using bounds yl(x) and yh(x) from cols 3-4.
	   Append +xl|r|x0 to connect 1st and last point to anchor points at xmin, xmax, or x0, or
	   append +yb|t|y0 to connect 1st and last point to anchor points at ymin, ymax, or y0.
	   Polygon may be painted (-G) and optionally outlined via +p<pen> [no outline].
	-N Do not skip or clip symbols that fall outside the map border [clipping is on]
	   Use -Nr to turn off clipping and plot repeating symbols for periodic maps.
	   Use -Nc to retain clipping but turn off plotting of repeating symbols for periodic maps.
	   [Default will clip or skip symbols that fall outside and plot repeating symbols].
	-O Set Overlay plot mode, i.e., append to an existing plot.
	-P Set Portrait page orientation [OFF].
	-S Select symbol type and symbol size (in cm).  Choose between
	   -(xdash), +(plus), st(a)r, (b|B)ar, (c)ircle, (d)iamond, (e)llipse,
	   (f)ront, octa(g)on, (h)exagon, (i)nvtriangle, (j)rotated rectangle,
	   (k)ustom, (l)etter, (m)athangle, pe(n)tagon, (p)oint, (q)uoted line, (r)ectangle,
	   (R)ounded rectangle, (s)quare, (t)riangle, (v)ector, (w)edge, (x)cross, (y)dash,
	   =(geovector, i.e., great or small circle vectors) or ~(decorated line).
	   If no size is specified, then the 3rd column must have sizes.
	   If no symbol is specified, then last column must have symbol codes.
	   [Note: if -C is selected then 3rd means 4th column, etc.]
	   Symbols A, C, D, G, H, I, N, S, T are adjusted to have same area
	   as a circle of the specified diameter.
	   Bars: Append b[<base>] to give the y-value of the base [Default = 0 (1 for log-scales)].
	      Append u if width is in x-input units [Default is cm].
	      Use upper case -SB for horizontal bars (<base> then refers to x
	      and width may be in y-units [Default is vertical]. To read the <base>
	      value from file, specify b with no trailing value.
	   Decorated line: Give [d|f|l|n|s|x]<info>[:<symbolinfo>].
	     <code><info> controls placement of a symbol along lines.  Select
	       d<dist>[c|i|p] or D<dist>[d|m|s|e|f|k|M|n|u]  [Default is d10.16c].
	          d: Give distance between symbols with specified map unit in c|i|p.
	          D: Specify geographic distance between symbols in d|m|s|e|f|k|M|n|u,
	          The first symbol appears at <frac>*<dist>; change by appending /<frac> [0.25].
	       f<file.d> reads file <file.d> and places symbols at locations
	          that match individual points along the decorated lines.
	       l|L<line1>[,<line2>,...] Give start and stop coordinates for
	          straight line segments; symbols will be placed where these
	          lines intersect decorated lines.  The format of each <line>
	          is <start>/<stop>, where <start> or <stop> = <lon/lat> or a
	          2-character XY key that uses the "pstext"-style justification
	          format to specify a point on the map as [LCR][BMT].
	          L Let point pairs define great circles [Straight lines].
	       n|N<n_symbol> sets number of equidistant symbols per decorated line.
	          N: Starts symbol exactly at the start of decorated line
	            [Default centers the symbols on the decorated line].
	          N-1 places a single symbol at start of the decorated line, while
	          N+1 places a single symbol at the end of the decorated line.
	          Append /<min_dist> to enforce a minimum spacing between
	          consecutive symbols [0]
	       x|X<xfile.d> reads the multi-segment file <xfile.d> and places
	          symbols at intersections between decorated lines and lines in
	          <xfile.d>.  Use X to resample the lines first.
	     <symbolinfo> controls the symbol attributes.  Choose from
	        +a<angle> will place all symbol at a fixed angle.
	        Or, specify +an (line-normal) or +ap (line-parallel) [Default].
	        +d turns on debug which draws helper points and lines.
	        +g<fill> sets the fill for the symbol [transparent]
	        +n<dx>[/<dy>] to nudge symbol along line (+N for along x/y axis).
	        +p[<pen>] draw outline of textbox [Default is no outline].
	          Optionally append a pen [Default is default pen].
	        +s<symbol><size> specifies the decorative symbol and its size.
	        +w sets how many (x,y) points to use for angle calculation [auto].
	   Ellipses: Direction, major, and minor axis must be in columns 3-5.
	     If -SE rather than -Se is selected, psxy will expect azimuth, and
	     axes [in km], and convert azimuths based on map projection.
	     Use -SE- for a degenerate ellipse (circle) with only its diameter given
	     in column 3, or append a fixed diameter to -SE- instead.
	     Append any of the units in d|m|s|e|f|k|M|n|u to the axes [k].
	     For linear projection we scale the axes by the map scale.
	   Rotatable Rectangle: Direction, x- and y-dimensions in columns 3-5.
	     If -SJ rather than -Sj is selected, psxy will expect azimuth, and
	     dimensions [in km] and convert azimuths based on map projection.
	     Use -SJ- for a degenerate rectangle (square w/no rotation) with one dimension given
	     in column 3, or append a fixed dimension to -SJ- instead.
	     Append any of the units in d|m|s|e|f|k|M|n|u to the dimensions [k].
	     For linear projection we scale dimensions by the map scale.
	   Fronts: Give <tickgap>[/<ticklen>][+l|+r][+<type>][+o<offset>][+p[<pen>]].
	     If <tickgap> is negative it means the number of gaps instead.
	     The <ticklen> defaults to 150f <tickgap> if not given.  Append
	     +l or +r   : Plot symbol to left or right of front [centered]
	     +<type>    : +b(ox), +c(ircle), +f(ault), +s|S(lip), +t(riangle) [f]
	     	      +s optionally accepts the arrow angle [20].
	       box      : square when centered, half-square otherwise.
	       circle   : full when centered, half-circle otherwise.
	       fault    : centered cross-tick or tick only in specified direction.
	       slip     : left-or right-lateral strike-slip arrows.
	       Slip     : Same but with curved arrow-heads.
	       triangle : diagonal square when centered, directed triangle otherwise.
	     +o<offset> : Plot first symbol when along-front distance is offset [0].
	     +p[<pen>]  : Alternate pen for symbol outline; if no <pen> then no outline [Outline with -W pen].
	   Kustom: Append <symbolname> immediately after 'k'; this will look for
	     <symbolname>.def in the current directory, in $GMT_USERDIR,
	     or in $GMT_SHAREDIR (searched in that order).
	     Use upper case 'K' if your custom symbol refers a variable symbol, ?.
	     Available custom symbols (See Appendix N):
	     ---------------------------------------------------------
	     astroid     : 4-pointed concave star symbol
	     crosshair   : Bullseye crosshair
	     deltoid     : 3-pointed concave triangle symbol
	     flash       : Lightning flash symbol
	     hlens       : Horizontal convex lens symbol
	     hlozenge    : Narrow horizontal diamond-like symbol
	     hneedle     : Horizontal, very narrow diamond
	     hurricane   : Hurricane symbol
	     lcrescent   : Crescent with belly to the left
	     lflag       : Post with flag to the left
	     ltriangle   : Triangle pointing to the left
	     meca        : Focal mechanism (beachball)
	     pacman      : A Pacman symbol
	     rcrescent   : Crescent with belly to the right
	     rflag       : Post with flag to the right
	     rtriangle   : Triangle pointing to the right
	     sectoid     : Concave, triangular sector
	     squaroid    : Concave square
	     star3       : 3-pointed triangular star symbol
	     star4       : 4-pointed diagonal star symbol
	     starp       : 4-pointed polar star
	     sun         : Shining sun symbol
	     trirot1     : 90-degree triangle in 1st quadrant
	     trirot2     : 90-degree triangle in 2nd quadrant
	     trirot3     : 90-degree triangle in 3rd quadrant
	     trirot4     : 90-degree triangle in 4th quadrant
	     vlens       : Vertical convex lens symbol
	     vlozenge    : Narrow vertical diamond-like symbol
	     vneedle     : Vertical, very narrow diamond
	     volcano     : Active with some bad fume bubbles
	     ---------------------------------------------------------
	   Letter: append +t<string> after symbol size, and optionally +f<font> and +j<justify>.
	   Mathangle: radius, start, and stop directions of math angle must be in columns 3-5.
	     If -SM rather than -Sm is used, we draw straight angle symbol if 90 degrees.
	   Append length of vector head, with optional modifiers:
	   [Left and right are defined by looking from start to end of vector]
	     +a<angle> to set angle of the vector head apex [30]
	     +b to place a vector head at the beginning of the vector [none].
	       Append t for terminal, c for circle, s for square, a for arrow [Default],
	       i for tail, A for plain arrow, and I for plain tail.
	       Append l|r to only draw left or right side of this head [both sides].
	     +e to place a vector head at the end of the vector [none].
	       Append t for terminal, c for circle, s for square, a for arrow [Default],
	       i for tail, A for plain arrow, and I for plain tail.
	       Append l|r to only draw left or right side of this head [both sides].
	     +h sets the vector head shape in -2/2 range [0].
	     +l to only draw left side of all specified vector heads [both sides].
	     +m[f|r] to place vector head at mid-point of segment [Default expects +b|+e].
	       Specify f or r for forward|reverse direction [forward].
	       Append t for terminal, c for circle, s for square, or a for arrow [Default].
	       Append l|r to only draw left or right side of this head [both sides].
	     +n<norm> to shrink attributes if vector length < <norm> [none].
	     +o[<plon/plat>] sets pole [north pole] for great or small circles; only give length via input.
	     +q if start and stop opening angle is given instead of (azimuth,length) on input.
	     +r to only draw right side of all specified vector heads [both sides].
	     +t[b|e]<trim(s)>[unit] to shift begin or end position along vector by given amount [no shifting].
	   Quoted line: Give [d|f|l|n|s|x]<info>[:<labelinfo>].
	     <code><info> controls placement of labels along lines.  Select
	       d<dist>[c|i|p] or D<dist>[d|m|s|e|f|k|M|n|u]  [Default is d10.16c].
	          d: Give distance between labels with specified map unit in c|i|p.
	          D: Specify geographic distance between labels in d|m|s|e|f|k|M|n|u,
	          The first label appears at <frac>*<dist>; change by appending /<frac> [0.25].
	       f<file.d> reads file <file.d> and places labels at locations
	          that match individual points along the quoted lines.
	       l|L<line1>[,<line2>,...] Give start and stop coordinates for
	          straight line segments; labels will be placed where these
	          lines intersect quoted lines.  The format of each <line>
	          is <start>/<stop>, where <start> or <stop> = <lon/lat> or a
	          2-character XY key that uses the "pstext"-style justification
	          format to specify a point on the map as [LCR][BMT].
	          L Let point pairs define great circles [Straight lines].
	       n|N<n_label> sets number of equidistant labels per quoted line.
	          N: Starts label exactly at the start of quoted line
	            [Default centers the labels on the quoted line].
	          N-1 places a single label at start of the quoted line, while
	          N+1 places a single label at the end of the quoted line.
	          Append /<min_dist> to enforce a minimum spacing between
	          consecutive labels [0]
	       s|S<n_label> sets number of equidistant label per segmented quoted line.
	          Same as n|N but splits input lines to series of 2-point segments first.
	       x|X<xfile.d> reads the multi-segment file <xfile.d> and places
	          labels at intersections between quoted lines and lines in
	          <xfile.d>.  Use X to resample the lines first.
	          For all options, append +r<radius>[unit] to specify minimum
	          radial separation between labels [0]
	     <labelinfo> controls the label attributes.  Choose from
	        +a<angle> will place all label at a fixed angle.
	        Or, specify +an (line-normal) or +ap (line-parallel) [Default].
	        +c<dx>[/<dy>] sets clearance between label and text box [15%].
	        +d turns on debug which draws helper points and lines.
	        +e delays the plotting of the text as text clipping is set instead.
	        +f sets specified label font [Default is 12p,Helvetica,black].
	        +g[<color>] paints text box [transparent]; append color [white].
	        +j<just> sets label justification [Default is MC].
	        +l<text> Use text as label (quote text if containing spaces).
	        +L<d|D|f|h|n|N|x>[<unit>] Sets label according to given flag:
	          d Cartesian plot distance; append a desired unit from c|i|p.
	          D Map distance; append a desired unit from d|m|s|e|f|k|M|n|u.
	          f Label is last column of given label location file.
	          h Use segment header labels (via -Lstring).
	          n Use the current segment number (starting at 0).
	          N Use current file number / segment number (starting at 0/0).
	          x Like h, but us headers in file with crossing lines instead.
	        +n<dx>[/<dy>] to nudge label along line (+N for along x/y axis); ignored with +v.
	        +o to use rounded rectangular text box [Default is rectangular].
	        +p[<pen>] draw outline of textbox [Default is no outline].
	          Optionally append a pen [Default is default pen].
	        +r<rmin> skips labels where radius of curvature < <rmin> [0].
	        +t[<file>] saves (x y angle label) to <file> [Line_labels.txt].
	        +u<unit> to append unit to all labels.
	        +v for placing curved text along path [Default is straight].
	        +w sets how many (x,y) points to use for angle calculation [auto].
	        +x[first,last] adds <first> and <last> to these two labels [,'].
	          This modifier is only allowed if -SqN2 is used.
	        +=<prefix> to give all labels a prefix.
	   Rectangles: x- and y-dimensions must be in columns 3-4.
	   Rounded rectangles: x- and y-dimensions and corner radius must be in columns 3-5.
	   Vectors: Direction and length must be in columns 3-4.
	     If -SV rather than -Sv is selected, psxy will expect azimuth and
	     length and convert azimuths based on the chosen map projection.
	   Append length of vector head, with optional modifiers:
	   [Left and right are defined by looking from start to end of vector]
	     +a<angle> to set angle of the vector head apex [30]
	     +b to place a vector head at the beginning of the vector [none].
	       Append t for terminal, c for circle, s for square, a for arrow [Default],
	       i for tail, A for plain arrow, and I for plain tail.
	       Append l|r to only draw left or right side of this head [both sides].
	     +e to place a vector head at the end of the vector [none].
	       Append t for terminal, c for circle, s for square, a for arrow [Default],
	       i for tail, A for plain arrow, and I for plain tail.
	       Append l|r to only draw left or right side of this head [both sides].
	     +h sets the vector head shape in -2/2 range [0].
	     +j<just> to justify vector at (b)eginning [default], (e)nd, or (c)enter.
	     +l to only draw left side of all specified vector heads [both sides].
	     +m[f|r] to place vector head at mid-point of segment [Default expects +b|+e].
	       Specify f or r for forward|reverse direction [forward].
	       Append t for terminal, c for circle, s for square, or a for arrow [Default].
	       Append l|r to only draw left or right side of this head [both sides].
	     +n<norm> to shrink attributes if vector length < <norm> [none].
	     +o[<plon/plat>] sets pole [north pole] for great or small circles; only give length via input.
	     +q if start and stop opening angle is given instead of (azimuth,length) on input.
	     +r to only draw right side of all specified vector heads [both sides].
	     +s if (x,y) coordinates of tip is given instead of (azimuth,length) on input.
	     +t[b|e]<trim(s)>[unit] to shift begin or end position along vector by given amount [no shifting].
	     +z if (dx,dy) vector components are given instead of (azimuth,length) on input.
	       Append <scale>[unit] to convert components to length in given unit.
	   Wedges: Start and stop directions of wedge must be in columns 3-4.
	     If -SW rather than -Sw is selected, specify two azimuths instead.
	     For geo-wedges, specify <size><unit> with units from d|m|s|e|f|k|M|n|u.
	     Append +a to just draw arc or +r to just draw radial lines [wedge].
	   Geovectors: Azimuth and length must be in columns 3-4.
	     Append any of the units in d|m|s|e|f|k|M|n|u to length [k].
	   Append length of vector head, with optional modifiers:
	   [Left and right are defined by looking from start to end of vector]
	     +a<angle> to set angle of the vector head apex [30]
	     +b to place a vector head at the beginning of the vector [none].
	       Append t for terminal, c for circle, s for square, a for arrow [Default],
	       i for tail, A for plain arrow, and I for plain tail.
	       Append l|r to only draw left or right side of this head [both sides].
	     +e to place a vector head at the end of the vector [none].
	       Append t for terminal, c for circle, s for square, a for arrow [Default],
	       i for tail, A for plain arrow, and I for plain tail.
	       Append l|r to only draw left or right side of this head [both sides].
	     +h sets the vector head shape in -2/2 range [0].
	     +j<just> to justify vector at (b)eginning [default], (e)nd, or (c)enter.
	     +l to only draw left side of all specified vector heads [both sides].
	     +m[f|r] to place vector head at mid-point of segment [Default expects +b|+e].
	       Specify f or r for forward|reverse direction [forward].
	       Append t for terminal, c for circle, s for square, or a for arrow [Default].
	       Append l|r to only draw left or right side of this head [both sides].
	     +n<norm> to shrink attributes if vector length < <norm> [none].
	     +o[<plon/plat>] sets pole [north pole] for great or small circles; only give length via input.
	     +q if start and stop opening angle is given instead of (azimuth,length) on input.
	     +r to only draw right side of all specified vector heads [both sides].
	     +s if (x,y) coordinates of tip is given instead of (azimuth,length) on input.
	     +t[b|e]<trim(s)>[unit] to shift begin or end position along vector by given amount [no shifting].
	-T Ignore all input files.
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
	-W Set pen attributes [Default pen is default,black]:
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
	   Additional line attribute modifiers are also available.  Choose from:
	     +o<offset>[unit] Trim the line from the end inward by the specified amount.
	        Choose <unit> as plot distances (c|i|p) or map distances (d|m|s|e|f|k|M|n|u) [Cartesian].
	        To trim the two ends differently, give two offsets separated by a slash (/).
	     +s Draw line using a Bezier spline in the PostScript [Linear spline].
	     +v[b|e]<vecspecs> Add vector head with the given specs at the ends of lines.
	        Use +ve and +vb separately to give different endings (+v applies to both).
	        See vector specifications for details. Note: +v must be last modifier for a pen.
	     +c Controls how pens and fills are affected if a CPT is specified via -C:
	          Append l to let pen colors follow the CPT setting.
	          Append f to let fill/font colors follow the CPT setting.
	          Default is both effects.
	-X -Y Shift origin of plot to (<xshift>, <yshift>).
	   Prepend r for shift relative to current point (default), prepend a for temporary
	   adjustment of origin, prepend f to position relative to lower left corner of page,
	   prepend c for offset of center of plot to center of page.
	   For overlays (-O), the default setting is [r0], otherwise [f2.54c].
	-a Give one or more comma-separated <col>=<name> associations.
	-bi For binary input; [<n>]<type>[w][+L|B]; <type> = c|u|h|H|i|I|l|L|f|D.
	    Prepend <n> for the number of columns for each <type>.
	   Default is the required number of columns.
	-di Replace any <nodata> in input data with NaN.
	-e Only accept input data records that contain the string "pattern".
	   Use -e~"pattern" to only accept data records that DO NOT contain this pattern.
	   If your pattern begins with ~, escape it with \~.  To match against
	   extended regular expressions use -e[~]/regexp/[i] (i for case-insensitive).
	   Give +f<file> for a file list with such patterns, one per line.
	   To give a single pattern starting with +f, escape it with \+f.
	-f Special formatting of input/output columns (time or geographical).
	   Specify i(nput) or o(utput) [Default is both input and output].
	   Give one or more columns (or column ranges) separated by commas.
	   Append T (Calendar format), t (time relative to TIME_EPOCH),
	   f (floating point), x (longitude), y (latitude) to each item.
	   -f[i|o]g means -f[i|o]0x,1y (geographic coordinates).
	   -f[i|o]c means -f[i|o]0-1f (Cartesian coordinates).
	   -fp[<unit>] means input x,y are in projected coordinates.
	-g Use data point separations to determine if there are data gaps.
	   Append x|X or y|Y to identify data gaps in x or y coordinates,
	   respectively, and append d|D for distance gaps.  Upper case X|Y|D
	   means we first project the points (requires -J).  Append [+|-]<gap>[unit].
	   For geographic data: choose from e|f|k|M|n|u [Default is meter (e)].
	   For gaps based on mapped coordinates: choose unit from c|i|p [cm].
	   For time data: the unit is controlled by TIME_UNIT.
	   For generic data: the unit is as the data implies (user units).
	   Repeat the -g option to specify multiple criteria, and add -ga
	   to indicate that all criteria must be met [just one must be met].
	-h[i][<n>][+c][+d][+r<remark>][+t<title>] Input/output file has [0] Header record(s) [OFF]
	   Optionally, append i for input only and/or number of header records [0].
	     -hi turns off the writing of all headers on output.
	   Append +c to add header record with column information [none].
	   Append +d to delete headers before adding new ones [Default will append headers].
	   Append +r to add a <remark> comment to the output [none].
	   Append +t to add a <title> comment to the output [none].
	     (these strings may contain \n to indicate line-breaks)
	   For binary files, <n> is considered to mean number of bytes.
	-i Sets alternate input column order and optional transformations [Default reads all columns in order].
	-p Select a 3-D pseudo perspective view.  Append the
	   azimuth and elevation of the viewpoint [180/90].
	   When used with -Jz|Z, optionally add zlevel for frame, etc. [bottom of z-axis]
	   Optionally, append +w<lon/lat[/z] to specify a fixed point
	   and +vx/y for its justification.  Just append + by itself
	   to select default values [region center and page center].
	   For a plain rotation about the z-axis, give rotation angle only
	   and optionally use +w or +v to select location of axis [plot origin].
	-t Set the layer PDF transparency from 0-100 [Default is 0; opaque].
	-: Swap 1st and 2nd column on input and/or output [OFF/OFF].
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

my $psxy = {
    _J          => '',
    _Rg         => '',
    _R          => '',
    _Rg         => '',
    _A          => '',
    _Ax         => '',
    _B          => '',
    _C          => '',
    _D          => '',
    _E          => '',
    _G          => '',
    _F          => '',
    _Fr         => '',
    _G          => '',
    _I          => '',
    _K          => '',
    _L          => '',
    _N          => '',
    _Nr         => '',
    _Nc         => '',
    _O          => '',
    _P          => '',
    _S          => '',
    _SB         => '',
    _SE         => '',
    _SJ         => '',
    _W          => '',
    _SM         => '',
    _SqN2       => '',
    _SV         => '',
    _SW         => '',
    _T          => '',
    _U          => '',
    _Uc         => '',
    _V          => '',
    _V          => '',
    _V          => '',
    _W          => '',
    _X          => '',
    _a          => '',
    _bi         => '',
    _di         => '',
    _e          => '',
    _f          => '',
    _g          => '',
    _hi         => '',
    _i          => '',
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
    $psxy->{_J}          = '';
    $psxy->{_Rg}         = '';
    $psxy->{_R}          = '';
    $psxy->{_R}          = '';
    $psxy->{_Rg}         = '';
    $psxy->{_A}          = '';
    $psxy->{_Ax}         = '';
    $psxy->{_B}          = '';
    $psxy->{_C}          = '';
    $psxy->{_D}          = '';
    $psxy->{_E}          = '';
    $psxy->{_G}          = '';
    $psxy->{_F}          = '';
    $psxy->{_Fr}         = '';
    $psxy->{_G}          = '';
    $psxy->{_I}          = '';
    $psxy->{_K}          = '';
    $psxy->{_L}          = '';
    $psxy->{_N}          = '';
    $psxy->{_Nr}         = '';
    $psxy->{_Nc}         = '';
    $psxy->{_O}          = '';
    $psxy->{_P}          = '';
    $psxy->{_S}          = '';
    $psxy->{_C}          = '';
    $psxy->{_SB}         = '';
    $psxy->{_SE}         = '';
    $psxy->{_SJ}         = '';
    $psxy->{_W}          = '';
    $psxy->{_SM}         = '';
    $psxy->{_SqN2}       = '';
    $psxy->{_SV}         = '';
    $psxy->{_SW}         = '';
    $psxy->{_T}          = '';
    $psxy->{_U}          = '';
    $psxy->{_Uc}         = '';
    $psxy->{_V}          = '';
    $psxy->{_V}          = '';
    $psxy->{_V}          = '';
    $psxy->{_W}          = '';
    $psxy->{_X}          = '';
    $psxy->{_a}          = '';
    $psxy->{_bi}         = '';
    $psxy->{_di}         = '';
    $psxy->{_e}          = '';
    $psxy->{_f}          = '';
    $psxy->{_g}          = '';
    $psxy->{_g}          = '';
    $psxy->{_hi}         = '';
    $psxy->{_i}          = '';
    $psxy->{_p}          = '';
    $psxy->{_t}          = '';
    $psxy->{_infile}     = '';
    $psxy->{_outfile}    = '';
    $psxy->{_limits}     = '';
    $psxy->{_projection} = '';
    $psxy->{_no_head}    = '';
    $psxy->{_no_tail}    = '';
    $psxy->{_verbose}    = '';
    $psxy->{_Step}       = '';
    $psxy->{_note}       = '';
}

=head2 sub J 


=cut

sub J {
    my ( $self, $J ) = @_;
    if ($J) {
        $psxy->{_J}    = $J;
        $psxy->{_note} = $psxy->{_note} . ' -J' . $psxy->{_J};
        $psxy->{_Step} = $psxy->{_Step} . ' -J' . $psxy->{_J};
    }
}

=head2 sub Rg 


=cut

sub Rg {
    my ( $self, $Rg ) = @_;
    if ($Rg) {
        $psxy->{_Rg}   = $Rg;
        $psxy->{_note} = $psxy->{_note} . ' -Rg' . $psxy->{_Rg};
        $psxy->{_Step} = $psxy->{_Step} . ' -Rg' . $psxy->{_Rg};
    }
}

=head2 sub R 


=cut

sub R {
    my ( $self, $R ) = @_;
    if ($R) {
        $psxy->{_R}    = $R;
        $psxy->{_note} = $psxy->{_note} . ' -R' . $psxy->{_R};
        $psxy->{_Step} = $psxy->{_Step} . ' -R' . $psxy->{_R};
    }
}

=head2 sub A 


=cut

sub A {
    my ( $self, $A ) = @_;
    if ($A) {
        $psxy->{_A}    = $A;
        $psxy->{_note} = $psxy->{_note} . ' -A' . $psxy->{_A};
        $psxy->{_Step} = $psxy->{_Step} . ' -A' . $psxy->{_A};
    }
}

=head2 sub Ax 


=cut

sub Ax {
    my ( $self, $Ax ) = @_;
    if ($Ax) {
        $psxy->{_Ax}   = $Ax;
        $psxy->{_note} = $psxy->{_note} . ' -Ax' . $psxy->{_Ax};
        $psxy->{_Step} = $psxy->{_Step} . ' -Ax' . $psxy->{_Ax};
    }
}

=head2 sub B 


=cut

sub B {
    my ( $self, $B ) = @_;
    if ($B) {
        $psxy->{_B}    = $B;
        $psxy->{_note} = $psxy->{_note} . ' -B' . $psxy->{_B};
        $psxy->{_Step} = $psxy->{_Step} . ' -B' . $psxy->{_B};
    }
}

=head2 sub C 


=cut

sub C {
    my ( $self, $C ) = @_;
    if ($C) {
        $psxy->{_C}    = $C;
        $psxy->{_note} = $psxy->{_note} . ' -C' . $psxy->{_C};
        $psxy->{_Step} = $psxy->{_Step} . ' -C' . $psxy->{_C};
    }
}

=head2 sub D 


=cut

sub D {
    my ( $self, $D ) = @_;
    if ($D) {
        $psxy->{_D}    = $D;
        $psxy->{_note} = $psxy->{_note} . ' -D' . $psxy->{_D};
        $psxy->{_Step} = $psxy->{_Step} . ' -D' . $psxy->{_D};
    }
}

=head2 sub E 


=cut

sub E {
    my ( $self, $E ) = @_;
    if ($E) {
        $psxy->{_E}    = $E;
        $psxy->{_note} = $psxy->{_note} . ' -E' . $psxy->{_E};
        $psxy->{_Step} = $psxy->{_Step} . ' -E' . $psxy->{_E};
    }
}

=head2 sub G 


=cut

sub G {
    my ( $self, $G ) = @_;
    if ($G) {
        $psxy->{_G}    = $G;
        $psxy->{_note} = $psxy->{_note} . ' -G' . $psxy->{_G};
        $psxy->{_Step} = $psxy->{_Step} . ' -G' . $psxy->{_G};
    }
}

=head2 sub fill


=cut

sub fill {
    my ( $self, $fill ) = @_;
    if ($fill) {
        $psxy->{_fill} = $fill;
        $psxy->{_note} = $psxy->{_note} . ' -G' . $psxy->{_fill};
        $psxy->{_Step} = $psxy->{_Step} . ' -G' . $psxy->{_fill};
    }
}

=head2 sub F 


=cut

sub F {
    my ( $self, $F ) = @_;
    if ($F) {
        $psxy->{_F}    = $F;
        $psxy->{_note} = $psxy->{_note} . ' -F' . $psxy->{_F};
        $psxy->{_Step} = $psxy->{_Step} . ' -F' . $psxy->{_F};
    }
}

=head2 sub Fr 


=cut

sub Fr {
    my ( $self, $Fr ) = @_;
    if ($Fr) {
        $psxy->{_Fr}   = $Fr;
        $psxy->{_note} = $psxy->{_note} . ' -Fr' . $psxy->{_Fr};
        $psxy->{_Step} = $psxy->{_Step} . ' -Fr' . $psxy->{_Fr};
    }
}

=head2 sub I 


=cut

sub I {
    my ( $self, $I ) = @_;
    if ($I) {
        $psxy->{_I}    = $I;
        $psxy->{_note} = $psxy->{_note} . ' -I' . $psxy->{_I};
        $psxy->{_Step} = $psxy->{_Step} . ' -I' . $psxy->{_I};
    }
}

=head2 sub K 


=cut

sub K {
    my ( $self, $K ) = @_;
    if ($K) {
        $psxy->{_K}    = $K;
        $psxy->{_note} = $psxy->{_note} . ' -K' . $psxy->{_K};
        $psxy->{_Step} = $psxy->{_Step} . ' -K' . $psxy->{_K};
    }
}

=head2 sub L 


=cut

sub L {
    my ( $self, $L ) = @_;
    if ($L) {
        $psxy->{_L}    = $L;
        $psxy->{_note} = $psxy->{_note} . ' -L' . $psxy->{_L};
        $psxy->{_Step} = $psxy->{_Step} . ' -L' . $psxy->{_L};
    }
}

=head2 sub N 


=cut

sub N {
    my ( $self, $N ) = @_;
    if ($N) {
        $psxy->{_N}    = $N;
        $psxy->{_note} = $psxy->{_note} . ' -N' . $psxy->{_N};
        $psxy->{_Step} = $psxy->{_Step} . ' -N' . $psxy->{_N};
    }
}

=head2 sub Nr 


=cut

sub Nr {
    my ( $self, $Nr ) = @_;
    if ($Nr) {
        $psxy->{_Nr}   = $Nr;
        $psxy->{_note} = $psxy->{_note} . ' -Nr' . $psxy->{_Nr};
        $psxy->{_Step} = $psxy->{_Step} . ' -Nr' . $psxy->{_Nr};
    }
}

=head2 sub Nc 


=cut

sub Nc {
    my ( $self, $Nc ) = @_;
    if ($Nc) {
        $psxy->{_Nc}   = $Nc;
        $psxy->{_note} = $psxy->{_note} . ' -Nc' . $psxy->{_Nc};
        $psxy->{_Step} = $psxy->{_Step} . ' -Nc' . $psxy->{_Nc};
    }
}

=head2 sub O 


=cut

sub O {
    my ( $self, $O ) = @_;
    if ($O) {
        $psxy->{_O}    = $O;
        $psxy->{_note} = $psxy->{_note} . ' -O' . $psxy->{_O};
        $psxy->{_Step} = $psxy->{_Step} . ' -O' . $psxy->{_O};
    }
}

=head2 sub P 


=cut

sub P {
    my ( $self, $P ) = @_;
    if ($P) {
        $psxy->{_P}    = $P;
        $psxy->{_note} = $psxy->{_note} . ' -P' . $psxy->{_P};
        $psxy->{_Step} = $psxy->{_Step} . ' -P' . $psxy->{_P};
    }
}

=head2 sub S 


=cut

sub S {
    my ( $self, $S ) = @_;
    if ($S) {
        $psxy->{_S}    = $S;
        $psxy->{_note} = $psxy->{_note} . ' -S' . $psxy->{_S};
        $psxy->{_Step} = $psxy->{_Step} . ' -S' . $psxy->{_S};
    }
}

=head2 sub symbol 


=cut

sub symbol {
    my ( $self, $symbol ) = @_;
    if ($symbol) {
        $psxy->{_symbol} = $symbol;
        $psxy->{_note}   = $psxy->{_note} . ' -S' . $psxy->{_symbol};
        $psxy->{_Step}   = $psxy->{_Step} . ' -S' . $psxy->{_symbol};
    }
}

=head2 sub SB 


=cut

sub SB {
    my ( $self, $SB ) = @_;
    if ($SB) {
        $psxy->{_SB}   = $SB;
        $psxy->{_note} = $psxy->{_note} . ' -SB' . $psxy->{_SB};
        $psxy->{_Step} = $psxy->{_Step} . ' -SB' . $psxy->{_SB};
    }
}

=head2 sub SE 


=cut

sub SE {
    my ( $self, $SE ) = @_;
    if ($SE) {
        $psxy->{_SE}   = $SE;
        $psxy->{_note} = $psxy->{_note} . ' -SE' . $psxy->{_SE};
        $psxy->{_Step} = $psxy->{_Step} . ' -SE' . $psxy->{_SE};
    }
}

=head2 sub SJ 


=cut

sub SJ {
    my ( $self, $SJ ) = @_;
    if ($SJ) {
        $psxy->{_SJ}   = $SJ;
        $psxy->{_note} = $psxy->{_note} . ' -SJ' . $psxy->{_SJ};
        $psxy->{_Step} = $psxy->{_Step} . ' -SJ' . $psxy->{_SJ};
    }
}

=head2 sub W 


=cut

sub W {
    my ( $self, $W ) = @_;
    if ($W) {
        $psxy->{_W}    = $W;
        $psxy->{_note} = $psxy->{_note} . ' -W' . $psxy->{_W};
        $psxy->{_Step} = $psxy->{_Step} . ' -W' . $psxy->{_W};
    }
}

=head2 sub outline 


=cut

sub outline {
    my ( $self, $outline ) = @_;
    if ($outline) {
        $psxy->{_outline} = $outline;
        $psxy->{_note}    = $psxy->{_note} . '  -W' . $psxy->{_outline};
        $psxy->{_Step}    = $psxy->{_Step} . '  -W' . $psxy->{_outline};
    }
}

=head2 sub SM 


=cut

sub SM {
    my ( $self, $SM ) = @_;
    if ($SM) {
        $psxy->{_SM}   = $SM;
        $psxy->{_note} = $psxy->{_note} . ' -SM' . $psxy->{_SM};
        $psxy->{_Step} = $psxy->{_Step} . ' -SM' . $psxy->{_SM};
    }
}

=head2 sub SqN2 


=cut

sub SqN2 {
    my ( $self, $SqN2 ) = @_;
    if ($SqN2) {
        $psxy->{_SqN2} = $SqN2;
        $psxy->{_note} = $psxy->{_note} . ' -SqN2' . $psxy->{_SqN2};
        $psxy->{_Step} = $psxy->{_Step} . ' -SqN2' . $psxy->{_SqN2};
    }
}

=head2 sub SV 


=cut

sub SV {
    my ( $self, $SV ) = @_;
    if ($SV) {
        $psxy->{_SV}   = $SV;
        $psxy->{_note} = $psxy->{_note} . ' -SV' . $psxy->{_SV};
        $psxy->{_Step} = $psxy->{_Step} . ' -SV' . $psxy->{_SV};
    }
}

=head2 sub SW 


=cut

sub SW {
    my ( $self, $SW ) = @_;
    if ($SW) {
        $psxy->{_SW}   = $SW;
        $psxy->{_note} = $psxy->{_note} . ' -SW' . $psxy->{_SW};
        $psxy->{_Step} = $psxy->{_Step} . ' -SW' . $psxy->{_SW};
    }
}

=head2 sub T 


=cut

sub T {
    my ( $self, $T ) = @_;
    if ($T) {
        $psxy->{_T}    = $T;
        $psxy->{_note} = $psxy->{_note} . ' -T' . $psxy->{_T};
        $psxy->{_Step} = $psxy->{_Step} . ' -T' . $psxy->{_T};
    }
}

=head2 sub U 


=cut

sub U {
    my ( $self, $U ) = @_;
    if ($U) {
        $psxy->{_U}    = $U;
        $psxy->{_note} = $psxy->{_note} . ' -U' . $psxy->{_U};
        $psxy->{_Step} = $psxy->{_Step} . ' -U' . $psxy->{_U};
    }
}

=head2 sub Uc 


=cut

sub Uc {
    my ( $self, $Uc ) = @_;
    if ($Uc) {
        $psxy->{_Uc}   = $Uc;
        $psxy->{_note} = $psxy->{_note} . ' -Uc' . $psxy->{_Uc};
        $psxy->{_Step} = $psxy->{_Step} . ' -Uc' . $psxy->{_Uc};
    }
}

=head2 sub V 


=cut

sub V {
    my ( $self, $V ) = @_;
    if ($V) {
        $psxy->{_V}    = $V;
        $psxy->{_note} = $psxy->{_note} . ' -V' . $psxy->{_V};
        $psxy->{_Step} = $psxy->{_Step} . ' -V' . $psxy->{_V};
    }
}

=head2 sub X 


=cut

sub X {
    my ( $self, $X ) = @_;
    if ($X) {
        $psxy->{_X}    = $X;
        $psxy->{_note} = $psxy->{_note} . ' -X' . $psxy->{_X};
        $psxy->{_Step} = $psxy->{_Step} . ' -X' . $psxy->{_X};
    }
}

=head2 sub a 


=cut

sub a {
    my ( $self, $a ) = @_;
    if ($a) {
        $psxy->{_a}    = $a;
        $psxy->{_note} = $psxy->{_note} . ' -a' . $psxy->{_a};
        $psxy->{_Step} = $psxy->{_Step} . ' -a' . $psxy->{_a};
    }
}

=head2 sub bi 


=cut

sub bi {
    my ( $self, $bi ) = @_;
    if ($bi) {
        $psxy->{_bi}   = $bi;
        $psxy->{_note} = $psxy->{_note} . ' -bi' . $psxy->{_bi};
        $psxy->{_Step} = $psxy->{_Step} . ' -bi' . $psxy->{_bi};
    }
}

=head2 sub di 


=cut

sub di {
    my ( $self, $di ) = @_;
    if ($di) {
        $psxy->{_di}   = $di;
        $psxy->{_note} = $psxy->{_note} . ' -di' . $psxy->{_di};
        $psxy->{_Step} = $psxy->{_Step} . ' -di' . $psxy->{_di};
    }
}

=head2 sub e 


=cut

sub e {
    my ( $self, $e ) = @_;
    if ($e) {
        $psxy->{_e}    = $e;
        $psxy->{_note} = $psxy->{_note} . ' -e' . $psxy->{_e};
        $psxy->{_Step} = $psxy->{_Step} . ' -e' . $psxy->{_e};
    }
}

=head2 sub f 


=cut

sub f {
    my ( $self, $f ) = @_;
    if ($f) {
        $psxy->{_f}    = $f;
        $psxy->{_note} = $psxy->{_note} . ' -f' . $psxy->{_f};
        $psxy->{_Step} = $psxy->{_Step} . ' -f' . $psxy->{_f};
    }
}

=head2 sub g 


=cut

sub g {
    my ( $self, $g ) = @_;
    if ($g) {
        $psxy->{_g}    = $g;
        $psxy->{_note} = $psxy->{_note} . ' -g' . $psxy->{_g};
        $psxy->{_Step} = $psxy->{_Step} . ' -g' . $psxy->{_g};
    }
}

=head2 sub hi 


=cut

sub hi {
    my ( $self, $hi ) = @_;
    if ($hi) {
        $psxy->{_hi}   = $hi;
        $psxy->{_note} = $psxy->{_note} . ' -hi' . $psxy->{_hi};
        $psxy->{_Step} = $psxy->{_Step} . ' -hi' . $psxy->{_hi};
    }
}

=head2 sub i 


=cut

sub i {
    my ( $self, $i ) = @_;
    if ($i) {
        $psxy->{_i}    = $i;
        $psxy->{_note} = $psxy->{_note} . ' -i' . $psxy->{_i};
        $psxy->{_Step} = $psxy->{_Step} . ' -i' . $psxy->{_i};
    }
}

=head2 sub p 


=cut

sub p {
    my ( $self, $p ) = @_;
    if ($p) {
        $psxy->{_p}    = $p;
        $psxy->{_note} = $psxy->{_note} . ' -p' . $psxy->{_p};
        $psxy->{_Step} = $psxy->{_Step} . ' -p' . $psxy->{_p};
    }
}

=head2 sub t 


=cut

sub t {
    my ( $self, $t ) = @_;
    if ($t) {
        $psxy->{_t}    = $t;
        $psxy->{_note} = $psxy->{_note} . ' -t' . $psxy->{_t};
        $psxy->{_Step} = $psxy->{_Step} . ' -t' . $psxy->{_t};
    }
}

=head2 sub infile 


=cut

sub infile {
    my ( $self, $infile ) = @_;
    if ($infile) {
        $psxy->{_infile} = $infile;
        $psxy->{_note}   = $psxy->{_note} . ' ' . $psxy->{_infile};
        $psxy->{_Step}   = $psxy->{_Step} . ' ' . $psxy->{_infile};
    }
}

=head2 sub outfile 


=cut

sub outfile {
    my ( $self, $outfile ) = @_;
    if ($outfile) {
        $psxy->{_outfile} = $outfile;
        $psxy->{_note}    = $psxy->{_note} . ' -G' . $psxy->{_outfile};
        $psxy->{_Step}    = $psxy->{_Step} . ' -G' . $psxy->{_outfile};
    }
}

=head2 sub limits 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $psxy->{_limits} = $limits;
        $psxy->{_note}   = $psxy->{_note} . ' -R' . $psxy->{_limits};
        $psxy->{_Step}   = $psxy->{_Step} . ' -R' . $psxy->{_limits};
    }
}

=head2 sub no_head 


=cut

sub no_head {
    my ( $self, $no_head ) = @_;
    if ($no_head) {
        $psxy->{_no_head} = $no_head;
        $psxy->{_note}    = $psxy->{_note} . ' -K' . $psxy->{_no_head};
        $psxy->{_Step}    = $psxy->{_Step} . ' -K' . $psxy->{_no_head};
    }
}

=head2 sub no_tail 


=cut

sub no_tail {
    my ( $self, $no_tail ) = @_;
    if ($no_tail) {
        $psxy->{_no_tail} = $no_tail;
        $psxy->{_note}    = $psxy->{_note} . ' -O' . $psxy->{_no_tail};
        $psxy->{_Step}    = $psxy->{_Step} . ' -O' . $psxy->{_no_tail};
    }
}

=head2 sub projection 


=cut

sub projection {
    my ( $self, $projection ) = @_;
    if ($projection) {
        $psxy->{_projection} = $projection;
        $psxy->{_note}       = $psxy->{_note} . ' -J' . $psxy->{_projection};
        $psxy->{_Step}       = $psxy->{_Step} . ' -J' . $psxy->{_projection};
    }
}

=head2 sub verbose 


=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ( $verbose eq $on ) {
        $psxy->{_verbose} = '';
        $psxy->{_Step}    = $psxy->{_Step} . ' -V' . $psxy->{_verbose};
        $psxy->{_note}    = $psxy->{_note} . ' -V' . $psxy->{_verbose};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $psxy->{_Step} = 'gmt psxy ' . $psxy->{_Step};
        return ( $psxy->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $psxy->{_note} = 'psxy ' . $psxy->{_note};
        return ( $psxy->{_note} );
    }
}

1;
