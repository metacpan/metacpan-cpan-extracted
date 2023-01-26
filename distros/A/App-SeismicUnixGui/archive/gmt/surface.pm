package App::SeismicUnixGui::gmt::surface;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: surface
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

  surface 4.5.7 [64-bit] - Adjustable tension continuous curvature surface gridding

  usage: surface [xyz-file] -G<output_grdfile_name> -I<xinc>[u][=|+][/<yinc>[u][=|+]]
	-R<west>/<east>/<south>/<north>[r] [-A<aspect_ratio>] [-C<convergence_limit>] [-H[i][<nrec>]]
	[-Ll<limit>] [-Lu<limit>] [-N<n_iterations>] ] [-S<search_radius>[m|c]] [-T<tension>[i][b]]
	[-Q] [-V[l]] [-Z<over_relaxation_parameter>] [-:[i|o]] [-bi[s|S|d|D[<ncol>]|c[<var1>/...]]] [-f[i|o]<colinfo>]

	surface will read from standard input or a single <xyz-file>.

	Required arguments to surface:
	-G sets output grid file name
	-I<xinc>[m|c|e|k|i|n|+][=][/<yinc>[m|c|e|k|i|n|+][=]]
	   Give increment and append unit (m)inute, se(c)ond, m(e)ter, (k)ilometer, m(i)les, (n)autical miles.
	   (Note: m,c,e,k,i,n only apply to geographic regions specified in degrees)
	   Append = to adjust the domain to fit the increment [Default adjusts increment to fit domain].
	   Alternatively, specify number of nodes by appending +. Then, the increments are calculated
	   from the given domain and node-registration settings (see Appendix B for details).
	   Note: If -R<grdfile> was used the increments were set as well; use -I to override.
		Note that only gridline registration can be used.
	-R specifies the min/max coordinates of data region in user units.
	   Use dd:mm[:ss] format for regions given in degrees and minutes [and seconds].
	   Use [yyy[-mm[-dd]]]T[hh[:mm[:ss[.xxx]]]] format for time axes.
	   Append r if -R specifies the longitudes/latitudes of the lower left
	   and upper right corners of a rectangular area.
	   -Rg -Rd are accepted shorthands for -R0/360/-90/90 -R-180/180/-90/90
	   Alternatively, give a gridfile and use its limits (and increments if applicable).

	OPTIONS:
	-A<aspect_ratio>  = 1.0  by default which gives an isotropic solution.
		i.e. xinc and yinc assumed to give derivatives of equal weight; if not, specify
		<aspect_ratio> such that yinc = xinc / <aspect_ratio>.
		e.g. if gridding lon,lat use <aspect_ratio> = cosine(middle of lat range).
	-C<convergence_limit> iteration stops when max abs change is less than <c.l.>
		default will choose 0.001 of the range of your z data (1 ppt precision).
		Enter your own convergence_limit limit in same units as z data.
	-H[i][n_rec] means input/output file has 1 Header record(s) [OFF]
	   Optionally, append i for input only and/or number of header records
	-L constrain the range of output values:
		-Ll<limit> specifies lower limit; forces solution to be >= <limit>.
		-Lu<limit> specifies upper limit; forces solution to be <= <limit>.
		<limit> can be any number, or the letter d for min (or max) input data value,
		or the filename of a grid with bounding values.  [Default solution unconstrained].
		Example:  -Ll0 gives a non-negative solution.
	-N sets max <n_iterations> in each cycle; default = 250.
	-S sets <search_radius> to initialize grid; default = 0 will skip this step.
		This step is slow and not needed unless grid dimensions are pathological;
		i.e., have few or no common factors.
		Append m or c to give <search_radius> in minutes or seconds.
	-T adds Tension to the gridding equation; use a value between 0 and 1.
		default = 0 gives minimum curvature (smoothest; bicubic) solution.
		1 gives a harmonic spline solution (local max/min occur only at data points).
		typically 0.25 or more is good for potential field (smooth) data;
		0.75 or so for topography.  Experiment.
		Append B or b to set tension in boundary conditions only;
		Append I or i to set tension in interior equations only;
		No appended letter sets tension for both to same value.
	-Q Query for grid sizes that might run faster than your -R -I give.
	-V Run in verbose mode [OFF].
		Append l for long verbose
	-Z sets <over_relaxation parameter>.  Default = 1.4
		Use a value between 1 and 2.  Larger number accelerates convergence_limit but can be unstable.
		Use 1 if you want to be sure to have (slow) stable convergence_limit.

	-: Expect lat/lon input/output rather than lon/lat [OFF/OFF].
	-bi for binary input.  Append s for single precision [Default is double]
	    Append <n> for the number of columns in binary file(s).
		Default is 3 input columns.

	-f Special formatting of input/output columns (e.g., time or geographical)
	   Specify i(nput) or o(utput) [Default is both input and output]
	   Give one or more columns (or column ranges) separated by commas.
	   Append T (Calendar format), t (time relative to TIME_EPOCH), f (plain floating point)
	   x (longitude), y (latitude) to each col/range item.
	   -f[i|o]g means -f[i|o]0x,1y (geographic coordinates).
	(See gmtdefaults man page for hidden GMT default parameters)
	(For additional details, see Smith & Wessel, Geophysics, 55, 293-305, 1990.)

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '1.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';    ##

=head2 instantiation##

=cut##

my $get = L_SU_global_constants->new();    ##

=head2 declare variables##
####
=cut##

my $var  = $get->var();                              ##
my $on   = $var->{_on};                              ##
my $off  = $var->{_off};                             ##
my $true = $var->{_true};                            ##

=head2 Encapsulated

	hash of private variables

=cut

my $surface = {
    _C                 => '',
    _convergence_limit => '',
    _G                 => '',
    _I                 => '',
    _inbound           => '',
    _R                 => '',
    _limits            => '',
    _Rg                => '',
    _L                 => '',
    _Ll0               => '',
    _N                 => '',
    _S                 => '',
    _T                 => '',
    _tension           => '',
    _Q                 => '',
    _V                 => '',
    _verbose           => '',
    _Z                 => '',
    _bi                => '',
    _f                 => '',
    _Step              => '',
    _note              => '',
};

=head2 sub clear

=cut

sub clear {
    $surface->{_convergence_limit} = '',
      $surface->{_C}               = '',
      $surface->{_G}               = '',
      $surface->{_I}               = '',
      $surface->{_inbound}         = '',
      $surface->{_R}               = '',
      $surface->{_limits}          = '',
      $surface->{_Rg}              = '',
      $surface->{_L}               = '',
      $surface->{_Ll0}             = '',
      $surface->{_N}               = '',
      $surface->{_S}               = '',
      $surface->{_T}               = '',
      $surface->{_tension}         = '',
      $surface->{_Q}               = '',
      $surface->{_V}               = '',
      $surface->{_verbose}         = '',
      $surface->{_Z}               = '',
      $surface->{_bi}              = '',
      $surface->{_f}               = '',
      $surface->{_Step}            = '',
      $surface->{_note}            = '',
      ;
}

=head2 sub C 

	outbound grd-format file

=cut

sub C {
    my ( $self, $C ) = @_;
    if ($C) {
        $surface->{_C}    = $C;
        $surface->{_note} = $surface->{_note} . ' -C' . $surface->{_C};
        $surface->{_Step} = $surface->{_Step} . ' -C' . $surface->{_C};
    }
}

=head2 sub convergence_limit 

	outbound grd-format file

=cut

sub convergence_limit {
    my ( $self, $convergence_limit ) = @_;
    if ($convergence_limit) {
        $surface->{_convergence_limit} = $convergence_limit;
        $surface->{_note} =
          $surface->{_note} . ' -C' . $surface->{_convergence_limit};
        $surface->{_Step} =
          $surface->{_Step} . ' -C' . $surface->{_convergence_limit};
    }
}

=head2 sub G 

	outbound grd-format file

=cut

sub G {
    my ( $self, $G ) = @_;
    if ($G) {
        $surface->{_G}    = $G;
        $surface->{_note} = $surface->{_note} . ' -G' . $surface->{_G};
        $surface->{_Step} = $surface->{_Step} . ' -G' . $surface->{_G};
    }
}

=head2 sub inbound 


=cut

sub inbound {
    my ( $self, $inbound ) = @_;
    if ($inbound) {
        $surface->{_inbound} = $inbound;
        $surface->{_note}    = $surface->{_note} . ' ' . $surface->{_inbound};
        $surface->{_Step}    = $surface->{_Step} . ' ' . $surface->{_inbound};
    }
}

=head2 sub outbound 


=cut

sub outbound {
    my ( $self, $outbound ) = @_;
    if ($outbound) {
        $surface->{_outbound} = $outbound;
        $surface->{_note} = $surface->{_note} . ' -G' . $surface->{_outbound};
        $surface->{_Step} = $surface->{_Step} . ' -G' . $surface->{_outbound};
    }
}

=head2 sub grid_spacing 


=cut

sub grid_spacing {
    my ( $self, $grid_spacing ) = @_;
    if ($grid_spacing) {
        $surface->{_grid_spacing} = $grid_spacing;
        $surface->{_note} =
          $surface->{_note} . ' -I' . $surface->{_grid_spacing};
        $surface->{_Step} =
          $surface->{_Step} . ' -I' . $surface->{_grid_spacing};
    }
}

=head2 sub I 


=cut

sub I {
    my ( $self, $I ) = @_;
    if ($I) {
        $surface->{_I}    = $I;
        $surface->{_note} = $surface->{_note} . ' -I' . $surface->{_I};
        $surface->{_Step} = $surface->{_Step} . ' -I' . $surface->{_I};
    }
}

=head2 sub R 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $surface->{_limits} = $limits;
        $surface->{_note}   = $surface->{_note} . ' -R' . $surface->{_limits};
        $surface->{_Step}   = $surface->{_Step} . ' -R' . $surface->{_limits};
    }
}

=head2 sub R 


=cut

sub R {
    my ( $self, $R ) = @_;
    if ($R) {
        $surface->{_R}    = $R;
        $surface->{_note} = $surface->{_note} . ' -R' . $surface->{_R};
        $surface->{_Step} = $surface->{_Step} . ' -R' . $surface->{_R};
    }
}

=head2 sub Rg 


=cut

sub Rg {
    my ( $self, $Rg ) = @_;
    if ($Rg) {
        $surface->{_Rg}   = $Rg;
        $surface->{_note} = $surface->{_note} . ' -Rg' . $surface->{_Rg};
        $surface->{_Step} = $surface->{_Step} . ' -Rg' . $surface->{_Rg};
    }
}

=head2 sub L 


=cut

sub L {
    my ( $self, $L ) = @_;
    if ($L) {
        $surface->{_L}    = $L;
        $surface->{_note} = $surface->{_note} . ' -L' . $surface->{_L};
        $surface->{_Step} = $surface->{_Step} . ' -L' . $surface->{_L};
    }
}

=head2 sub Ll0 


=cut

sub Ll0 {
    my ( $self, $Ll0 ) = @_;
    if ($Ll0) {
        $surface->{_Ll0}  = $Ll0;
        $surface->{_note} = $surface->{_note} . ' -Ll0' . $surface->{_Ll0};
        $surface->{_Step} = $surface->{_Step} . ' -Ll0' . $surface->{_Ll0};
    }
}

=head2 sub N 


=cut

sub N {
    my ( $self, $N ) = @_;
    if ($N) {
        $surface->{_N}    = $N;
        $surface->{_note} = $surface->{_note} . ' -N' . $surface->{_N};
        $surface->{_Step} = $surface->{_Step} . ' -N' . $surface->{_N};
    }
}

=head2 sub S 


=cut

sub S {
    my ( $self, $S ) = @_;
    if ($S) {
        $surface->{_S}    = $S;
        $surface->{_note} = $surface->{_note} . ' -S' . $surface->{_S};
        $surface->{_Step} = $surface->{_Step} . ' -S' . $surface->{_S};
    }
}

=head2 sub tension 


=cut

sub tension {
    my ( $self, $tension ) = @_;
    if ($tension) {
        $surface->{_tension} = $tension;
        $surface->{_note}    = $surface->{_note} . ' -T' . $surface->{_tension};
        $surface->{_Step}    = $surface->{_Step} . ' -T' . $surface->{_tension};
    }
}

=head2 sub T 


=cut

sub T {
    my ( $self, $T ) = @_;
    if ($T) {
        $surface->{_T}    = $T;
        $surface->{_note} = $surface->{_note} . ' -T' . $surface->{_T};
        $surface->{_Step} = $surface->{_Step} . ' -T' . $surface->{_T};
    }
}

=head2 sub Q 


=cut

sub Q {
    my ( $self, $Q ) = @_;
    if ($Q) {
        $surface->{_Q}    = $Q;
        $surface->{_note} = $surface->{_note} . ' -Q' . $surface->{_Q};
        $surface->{_Step} = $surface->{_Step} . ' -Q' . $surface->{_Q};
    }
}

=head2 sub verbose 


=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ( $verbose eq $on ) {
        $surface->{_verbose} = '';
        $surface->{_note}    = $surface->{_note} . ' -V' . $surface->{_verbose};
        $surface->{_Step}    = $surface->{_Step} . ' -V' . $surface->{_verbose};
    }
}

=head2 sub V 


=cut

sub V {
    my ( $self, $V ) = @_;
    if ( $V eq $on ) {
        $surface->{_V}    = '';
        $surface->{_note} = $surface->{_note} . ' -V' . $surface->{_V};
        $surface->{_Step} = $surface->{_Step} . ' -V' . $surface->{_V};
    }
}

=head2 sub Z 


=cut

sub Z {
    my ( $self, $Z ) = @_;
    if ($Z) {
        $surface->{_Z}    = $Z;
        $surface->{_note} = $surface->{_note} . ' -Z' . $surface->{_Z};
        $surface->{_Step} = $surface->{_Step} . ' -Z' . $surface->{_Z};
    }
}

=head2 sub bi 


=cut

sub bi {
    my ( $self, $bi ) = @_;
    if ($bi) {
        $surface->{_bi}   = $bi;
        $surface->{_note} = $surface->{_note} . ' -bi' . $surface->{_bi};
        $surface->{_Step} = $surface->{_Step} . ' -bi' . $surface->{_bi};
    }
}

=head2 sub f 


=cut

sub f {
    my ( $self, $f ) = @_;
    if ($f) {
        $surface->{_f}    = $f;
        $surface->{_note} = $surface->{_note} . ' -f' . $surface->{_f};
        $surface->{_Step} = $surface->{_Step} . ' -f' . $surface->{_f};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $surface->{_Step} = 'gmt surface ' . $surface->{_Step};
        return ( $surface->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $surface->{_note} = 'surface ' . $surface->{_note};
        return ( $surface->{_note} );
    }
}

1;
