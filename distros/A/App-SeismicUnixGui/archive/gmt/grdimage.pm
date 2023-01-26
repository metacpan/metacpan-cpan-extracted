package App::SeismicUnixGui::gmt::grdimage;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: grdimage
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

	grdimage 4.5.7 [64-bit] - Plot grid files in 2-D

	usage: grdimage <grd_z|grd_r grd_g grd_b> -J<params> [-B<params>] [-C<cpt_file>] [-D[r]] [-Ei|<dpi>] [-G[f|b]<rgb>]
	[-I<intensity_file>] [-K] [-M] [-N] [-O] [-P] [-Q] [-R<west>/<east>/<south>/<north>[r]] [-S[-]b|c|l|n[/<threshold>]] [-T]
	[-U[<just>/<dx>/<dy>/][c|<label>]] [-V] [-X[a|c|r]<x_shift>[u]] [-Y[a|c|r]<x_shift>[u]] [-c<ncopies>]

	<grd_z> is data set to be plotted.  Its z-values are in user units and will be
	  converted to rgb colors via the cpt file.  Alternatively, give three separate
	  grid files that contain the red, green, and blue components in the 0-255 range.
	  If -D is used then <grd_z> is instead expected to be an image.
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
	-B Boundary annotation, give -B[p|s]<xinfo>[/<yinfo>[/<zinfo>]][.:"title":][wesnzWESNZ+]
	   <?info> is 1-3 substring(s) of form [<type>]<stride>[<unit>][l|p][:"label":][:,[-]"unit":]
	   See psbasemap man pages for more details and examples of all settings.
	-C color palette file to convert z to rgb
	-D is used to read an image via GDAL.  Append r to equate image region to -R region.
	-E sets dpi for the projected grid which must be constructed
	   if -Jx or -Jm is not selected [Default gives same size as input grid]
	   Give i to do the interpolation in PostScript at device resolution.
	-G<color> sets transparency color for images that otherwise would result in 1-bit images
	   Specify <color> as one of:
	   1) <gray> or <red>/<green>/<blue>, all in the range 0-255;
	   2) <c>/<m>/<y>/<k> in range 0-100%;
	   3) <hue>-<sat>-<val> in ranges 0-360, 0-1, 0-1;
	   4) any valid color name.
	-I use illumination.  Append name of intensity grid file
	-K means allow for more plot code to be appended later [OFF].
	-M force monochrome image
	-N Do not clip image at the map boundary
	-O means Overlay plot mode [OFF].
	-P means Portrait page orientation [OFF].
	-Q use PS Level 3 colormasking to make nodes with z = NaN transparent.
	-R specifies the min/max coordinates of data region in user units.
	   Use dd:mm[:ss] format for regions given in degrees and minutes [and seconds].
	   Use [yyy[-mm[-dd]]]T[hh[:mm[:ss[.xxx]]]] format for time axes.
	   Append r if -R specifies the longitudes/latitudes of the lower left
	   and upper right corners of a rectangular area.
	   -Rg -Rd are accepted shorthands for -R0/360/-90/90 -R-180/180/-90/90
	   Alternatively, give a gridfile and use its limits (and increments if applicable).
	-S Determines the interpolation mode (b = B-spline, c = bicubic, l = bilinear,
	   n = nearest-neighbor) [Default: bicubic]
	   Optionally, prepend - to switch off antialiasing [Default: on]
	   Append /<threshold> to change the minimum weight in vicinity of NaNs. A threshold of
	   1.0 requires all nodes involved in interpolation to be non-NaN; 0.5 will interpolate
	   about half way from a non-NaN to a NaN node [Default: 0.5]
	-T OBSOLETE: See man pages
	-U to plot Unix System Time stamp [and optionally appended text].
	   You may also set the reference points and position of stamp [BL/-2c/-2c].
	   Give -Uc to have the command line plotted [OFF].
	-V Run in verbose mode [OFF].
	-X -Y to shift origin of plot to (<xshift>, <yshift>) [a2.5c,a2.5c].
	   Prepend a for absolute [Default r is relative]
	   (Note that for overlays (-O), the default is [r0,r0].)
	   Give c to center plot on page in x and/or y.
	-c specifies the number of copies [1].
	-f Special formatting of input/output columns (e.g., time or geographical)
	   Specify i(nput) or o(utput) [Default is both input and output]
	   Give one or more columns (or column ranges) separated by commas.
	   Append T (Calendar format), t (time relative to TIME_EPOCH), f (plain floating point)
	   x (longitude), y (latitude) to each col/range item.
	   -f[i|o]g means -f[i|o]0x,1y (geographic coordinates).
	(See gmtdefaults man page for hidden GMT default parameters)

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '1.0.1';
use GMTglobal_constants;

=head2 instantiation

=cut

my $get     = GMTglobal_constants->new();
my $gmt_var = $get->gmt_var();

=head2 declare variables##

=cut

my $on    = $gmt_var->{_on};
my $off   = $gmt_var->{_off};
my $true  = $gmt_var->{_true};
my $false = $gmt_var->{_false};

=head2 Encapsulated

	hash of private variables

=cut

my $grdimage = {
    _D           => '',
    _ticks       => '',
    _B           => '',
    _color_table => '',
    _infile      => '',
    _C           => '',
    _E           => '',
    _J           => '',
    _projection  => '',
    _I           => '',
    _K           => '',
    _M           => '',
    _N           => '',
    _O           => '',
    _portrait    => '',
    _P           => '',
    _Q           => '',
    _limits      => '',
    _R           => '',
    _S           => '',
    _T           => '',
    _U           => '',
    _Uc          => '',
    _verbose     => '',
    _V           => '',
    _X           => '',
    _c           => '',
    _f           => '',
    _Step        => '',
    _note        => '',
};

=head2 sub clear

=cut

sub clear {
    $grdimage->{_D}           = '';
    $grdimage->{_J}           = '';
    $grdimage->{_ticks}       = '';
    $grdimage->{_B}           = '';
    $grdimage->{_color_table} = '';
    $grdimage->{_C}           = '';
    $grdimage->{_E}           = '';
    $grdimage->{_projection}  = '';
    $grdimage->{_I}           = '';
    $grdimage->{_K}           = '';
    $grdimage->{_M}           = '';
    $grdimage->{_N}           = '';
    $grdimage->{_O}           = '';
    $grdimage->{_portrait}    = '';
    $grdimage->{_P}           = '';
    $grdimage->{_Q}           = '';
    $grdimage->{_R}           = '';
    $grdimage->{_limits}      = '';
    $grdimage->{_S}           = '';
    $grdimage->{_T}           = '';
    $grdimage->{_U}           = '';
    $grdimage->{_Uc}          = '';
    $grdimage->{_verbose}     = '';
    $grdimage->{_V}           = '';
    $grdimage->{_X}           = '';
    $grdimage->{_c}           = '';
    $grdimage->{_f}           = '';
    $grdimage->{_Step}        = '';
    $grdimage->{_note}        = '';
}

=head2 sub D 


=cut

sub D {
    my ( $self, $D ) = @_;
    if ($D) {
        $grdimage->{_D}    = $D;
        $grdimage->{_note} = $grdimage->{_note} . ' -D' . $grdimage->{_D};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -D' . $grdimage->{_D};
    }
}

=head2 sub ticks 


=cut

sub ticks {
    my ( $self, $ticks ) = @_;
    if ($ticks) {
        $grdimage->{_ticks} = $ticks;
        $grdimage->{_note}  = $grdimage->{_note} . ' -B' . $grdimage->{_ticks};
        $grdimage->{_Step}  = $grdimage->{_Step} . ' -B' . $grdimage->{_ticks};
    }
}

=head2 sub B 


=cut

sub B {
    my ( $self, $B ) = @_;
    if ($B) {
        $grdimage->{_B}    = $B;
        $grdimage->{_note} = $grdimage->{_note} . ' -B' . $grdimage->{_B};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -B' . $grdimage->{_B};
    }
}

=head2 sub color_table 


=cut

sub color_table {
    my ( $self, $color_table ) = @_;
    if ($color_table) {
        $grdimage->{_color_table} = $color_table;
        $grdimage->{_note} =
          $grdimage->{_note} . ' -C' . $grdimage->{_color_table};
        $grdimage->{_Step} =
          $grdimage->{_Step} . ' -C' . $grdimage->{_color_table};
    }
}

=head2 sub C 


=cut

sub C {
    my ( $self, $C ) = @_;
    if ($C) {
        $grdimage->{_C}    = $C;
        $grdimage->{_note} = $grdimage->{_note} . ' -C' . $grdimage->{_C};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -C' . $grdimage->{_C};
    }
}

=head2 sub E 


=cut

sub E {
    my ( $self, $E ) = @_;
    if ($E) {
        $grdimage->{_E}    = $E;
        $grdimage->{_note} = $grdimage->{_note} . ' -E' . $grdimage->{_E};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -E' . $grdimage->{_E};
    }
}

=head2 sub infile 


=cut

sub infile {
    my ( $self, $infile ) = @_;
    if ($infile) {
        $grdimage->{_infile} = $infile;
        $grdimage->{_note}   = $grdimage->{_note} . ' ' . $grdimage->{_infile};
        $grdimage->{_Step}   = $grdimage->{_Step} . ' ' . $grdimage->{_infile};
    }
}

=head2 sub projection 


=cut

sub projection {
    my ( $self, $projection ) = @_;
    if ($projection) {
        $grdimage->{_projection} = $projection;
        $grdimage->{_note} =
          $grdimage->{_note} . ' -J' . $grdimage->{_projection};
        $grdimage->{_Step} =
          $grdimage->{_Step} . ' -J' . $grdimage->{_projection};
    }
}

=head2 sub J 


=cut

sub J {
    my ( $self, $J ) = @_;
    if ($J) {
        $grdimage->{_J}    = $J;
        $grdimage->{_note} = $grdimage->{_note} . ' -J' . $grdimage->{_J};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -J' . $grdimage->{_J};
    }
}

=head2 sub I 


=cut

sub I {
    my ( $self, $I ) = @_;
    if ($I) {
        $grdimage->{_I}    = $I;
        $grdimage->{_note} = $grdimage->{_note} . ' -I' . $grdimage->{_I};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -I' . $grdimage->{_I};
    }
}

=head2 sub K 


=cut

sub K {
    my ( $self, $K ) = @_;
    if ($K) {
        $grdimage->{_K}    = $K;
        $grdimage->{_note} = $grdimage->{_note} . ' -K' . $grdimage->{_K};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -K' . $grdimage->{_K};
    }
}

=head2 sub M 


=cut

sub M {
    my ( $self, $M ) = @_;
    if ($M) {
        $grdimage->{_M}    = $M;
        $grdimage->{_note} = $grdimage->{_note} . ' -M' . $grdimage->{_M};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -M' . $grdimage->{_M};
    }
}

=head2 sub N 


=cut

sub N {
    my ( $self, $N ) = @_;
    if ($N) {
        $grdimage->{_N}    = $N;
        $grdimage->{_note} = $grdimage->{_note} . ' -N' . $grdimage->{_N};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -N' . $grdimage->{_N};
    }
}

=head2 sub O 


=cut

sub O {
    my ( $self, $O ) = @_;
    if ($O) {
        $grdimage->{_O}    = $O;
        $grdimage->{_note} = $grdimage->{_note} . ' -O' . $grdimage->{_O};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -O' . $grdimage->{_O};
    }
}

=head2 sub portrait 


=cut

sub portrait {
    my ( $self, $portrait ) = @_;
    if ( $portrait eq $on ) {
        $grdimage->{_portrait} = '';
        $grdimage->{_note} =
          $grdimage->{_note} . ' -P' . $grdimage->{_portrait};
        $grdimage->{_Step} =
          $grdimage->{_Step} . ' -P' . $grdimage->{_portrait};
    }
}

=head2 sub P 


=cut

sub P {
    my ( $self, $P ) = @_;
    if ($P) {
        $grdimage->{_P}    = $P;
        $grdimage->{_note} = $grdimage->{_note} . ' -P' . $grdimage->{_P};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -P' . $grdimage->{_P};
    }
}

=head2 sub Q 


=cut

sub Q {
    my ( $self, $Q ) = @_;
    if ($Q) {
        $grdimage->{_Q}    = $Q;
        $grdimage->{_note} = $grdimage->{_note} . ' -Q' . $grdimage->{_Q};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -Q' . $grdimage->{_Q};
    }
}

=head2 sub limits 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $grdimage->{_limits} = $limits;
        $grdimage->{_note} =
          $grdimage->{_note} . ' -R' . $grdimage->{_limits};
        $grdimage->{_Step} =
          $grdimage->{_Step} . ' -R' . $grdimage->{_limits};
    }
}

=head2 sub R 


=cut

sub R {
    my ( $self, $R ) = @_;
    if ($R) {
        $grdimage->{_R}    = $R;
        $grdimage->{_note} = $grdimage->{_note} . ' -R' . $grdimage->{_R};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -R' . $grdimage->{_R};
    }
}

=head2 sub S 


=cut

sub S {
    my ( $self, $S ) = @_;
    if ($S) {
        $grdimage->{_S}    = $S;
        $grdimage->{_note} = $grdimage->{_note} . ' -S' . $grdimage->{_S};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -S' . $grdimage->{_S};
    }
}

=head2 sub T 


=cut

sub T {
    my ( $self, $T ) = @_;
    if ($T) {
        $grdimage->{_T}    = $T;
        $grdimage->{_note} = $grdimage->{_note} . ' -T' . $grdimage->{_T};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -T' . $grdimage->{_T};
    }
}

=head2 sub U 


=cut

sub U {
    my ( $self, $U ) = @_;
    if ($U) {
        $grdimage->{_U}    = $U;
        $grdimage->{_note} = $grdimage->{_note} . ' -U' . $grdimage->{_U};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -U' . $grdimage->{_U};
    }
}

=head2 sub Uc 


=cut

sub Uc {
    my ( $self, $Uc ) = @_;
    if ($Uc) {
        $grdimage->{_Uc}   = $Uc;
        $grdimage->{_note} = $grdimage->{_note} . ' -Uc' . $grdimage->{_Uc};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -Uc' . $grdimage->{_Uc};
    }
}

=head2 sub verbose 


=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ( $verbose eq $on ) {
        $grdimage->{_verbose} = '';
        $grdimage->{_note} =
          $grdimage->{_note} . ' -V' . $grdimage->{_verbose};
        $grdimage->{_Step} =
          $grdimage->{_Step} . ' -V' . $grdimage->{_verbose};
    }
}

=head2 sub V 


=cut

sub V {
    my ( $self, $V ) = @_;
    if ( $V eq $on ) {
        $grdimage->{_V}    = '';
        $grdimage->{_note} = $grdimage->{_note} . ' -V' . $grdimage->{_V};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -V' . $grdimage->{_V};
    }
}

=head2 sub X 


=cut

sub X {
    my ( $self, $X ) = @_;
    if ($X) {
        $grdimage->{_X}    = $X;
        $grdimage->{_note} = $grdimage->{_note} . ' -X' . $grdimage->{_X};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -X' . $grdimage->{_X};
    }
}

=head2 sub c 


=cut

sub c {
    my ( $self, $c ) = @_;
    if ($c) {
        $grdimage->{_c}    = $c;
        $grdimage->{_note} = $grdimage->{_note} . ' -c' . $grdimage->{_c};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -c' . $grdimage->{_c};
    }
}

=head2 sub f 


=cut

sub f {
    my ( $self, $f ) = @_;
    if ($f) {
        $grdimage->{_f}    = $f;
        $grdimage->{_note} = $grdimage->{_note} . ' -f' . $grdimage->{_f};
        $grdimage->{_Step} = $grdimage->{_Step} . ' -f' . $grdimage->{_f};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $grdimage->{_Step} = 'gmt grdimage ' . $grdimage->{_Step};
        return ( $grdimage->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $grdimage->{_note} = 'grdimage ' . $grdimage->{_note};
        return ( $grdimage->{_note} );
    }
}

1;
