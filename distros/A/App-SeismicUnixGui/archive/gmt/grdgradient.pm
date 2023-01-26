package App::SeismicUnixGui::gmt::grdgradient;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: grdgradient
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

	grdgradient 4.5.7 [64-bit] - Compute directional gradients from grid files

	usage: grdgradient <infile> -G<outfile> [-A<azim>[/<azim2>]] [-D[a][o][n]]
[-E[s|p]<azim>/<elev[ambient/diffuse/specular/shine]>]
[-L<flag>] [-M] [-N[t_or_e][<amp>[/<sigma>[/<offset>]]]] [-S<slopefile>] [-V]

	<infile> is name of input grid file

	OPTIONS:
	-A sets azimuth (0-360 CW from North (+y)) for directional derivatives
	  -A<azim>/<azim2> will compute two directions and save the one larger in magnitude.
	-D finds the direction of grad z.
	   Append c to get cartesian angle (0-360 CCW from East (+x)) [Default:  azimuth]
	   Append o to get bidirectional orientations [0-180] rather than directions [0-360]
	   Append n to add 90 degrees to the values from c or o
	-E Compute Lambertian radiance appropriate to use with grdimage/grdview.
	   -E<azim/elev> sets azimuth and elevation of light vector.
	   -E<azim/elev/ambient/diffuse/specular/shine> sets azim, elev and
	    other parameters that control the reflectance properties of the surface.
	    Default values are: 0.55/0.6/0.4/10
	    Specify '=' to get the default value (e.g. -E60/30/=/0.5)
	   Append s to use a simpler Lambertian algorithm (note that with this form
	   you only have to provide the azimuth and elevation parameters)
	   Append p to use the Peucker piecewise linear approximation (simpler but faster algorithm)
	   Note that in this case the azimuth and elevation are hardwired to 315 and 45 degrees.
	   This means that even if you provide other values they will be ignored.
	-G output file for results from -A or -D
	-L sets boundary conditions.  <flag> can be either
	   g for geographic boundary conditions
	   or one or both of
	   x for periodic boundary conditions on x
	   y for periodic boundary conditions on y
	   [Default:  Natural conditions]
	-M to use map units.  In this case, dx,dy of grid
	   will be converted from degrees lon,lat into meters (Flat-earth approximation).
	   Default computes gradient in units of data/grid_distance.
	-N will normalize gradients so that max |grad| = <amp> [1.0]
	  -Nt will make atan transform, then scale to <amp> [1.0]
	  -Ne will make exp  transform, then scale to <amp> [1.0]
	  -Nt<amp>/<sigma>[/<offset>] or -Ne<amp>/<sigma>[/<offset>] sets sigma
	     (and offset) for transform. [sigma, offset estimated from data]
	-S output file for |grad z|; requires -D
	-V Run in verbose mode [OFF].

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

my $grdgradient = {
    _A          => '',
    _D          => '',
    _E          => '',
    _G          => '',
    _L          => '',
    _M          => '',
    _N          => '',
    _Nt         => '',
    _Ne         => '',
    _S          => '',
    _V          => '',
    _infile     => '',
    _outfile    => '',
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
    $grdgradient->{_A}          = '';
    $grdgradient->{_D}          = '';
    $grdgradient->{_E}          = '';
    $grdgradient->{_G}          = '';
    $grdgradient->{_L}          = '';
    $grdgradient->{_M}          = '';
    $grdgradient->{_N}          = '';
    $grdgradient->{_Nt}         = '';
    $grdgradient->{_Ne}         = '';
    $grdgradient->{_S}          = '';
    $grdgradient->{_V}          = '';
    $grdgradient->{_infile}     = '';
    $grdgradient->{_outfile}    = '';
    $grdgradient->{_limits}     = '';
    $grdgradient->{_projection} = '';
    $grdgradient->{_no_head}    = '';
    $grdgradient->{_no_tail}    = '';
    $grdgradient->{_Step}       = '';
    $grdgradient->{_note}       = '';
}

=head2 sub V

=cut

sub V {
    my ( $self, $V ) = @_;
    if ( $V eq $on ) {
        $grdgradient->{_V} = '';
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -V' . $grdgradient->{_V};
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -V' . $grdgradient->{_V};
    }
}

=head2 sub verbose

=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ( $verbose eq $on ) {
        $grdgradient->{_verbose} = '';
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -V' . $grdgradient->{_verbose};
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -V' . $grdgradient->{_verbose};
    }
}

=head2 sub A 


=cut

sub A {
    my ( $self, $A ) = @_;
    if ($A) {
        $grdgradient->{_A} = $A;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -A' . $grdgradient->{_A};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -A' . $grdgradient->{_A};
    }
}

=head2 sub D 


=cut

sub D {
    my ( $self, $D ) = @_;
    if ($D) {
        $grdgradient->{_D} = $D;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -D' . $grdgradient->{_D};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -D' . $grdgradient->{_D};
    }
}

=head2 sub E 


=cut

sub E {
    my ( $self, $E ) = @_;
    if ($E) {
        $grdgradient->{_E} = $E;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -E' . $grdgradient->{_E};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -E' . $grdgradient->{_E};
    }
}

=head2 sub G 


=cut

sub G {
    my ( $self, $G ) = @_;
    if ($G) {
        $grdgradient->{_G} = $G;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -G' . $grdgradient->{_G};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -G' . $grdgradient->{_G};
    }
}

=head2 sub L 


=cut

sub L {
    my ( $self, $L ) = @_;
    if ($L) {
        $grdgradient->{_L} = $L;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -L' . $grdgradient->{_L};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -L' . $grdgradient->{_L};
    }
}

=head2 sub M 


=cut

sub M {
    my ( $self, $M ) = @_;
    if ($M) {
        $grdgradient->{_M} = $M;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -M' . $grdgradient->{_M};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -M' . $grdgradient->{_M};
    }
}

=head2 sub N 


=cut

sub N {
    my ( $self, $N ) = @_;
    if ($N) {
        $grdgradient->{_N} = $N;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -N' . $grdgradient->{_N};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -N' . $grdgradient->{_N};
    }
}

=head2 sub Nt 


=cut

sub Nt {
    my ( $self, $Nt ) = @_;
    if ($Nt) {
        $grdgradient->{_Nt} = $Nt;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -Nt' . $grdgradient->{_Nt};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -Nt' . $grdgradient->{_Nt};
    }
}

=head2 sub Ne 


=cut

sub Ne {
    my ( $self, $Ne ) = @_;
    if ($Ne) {
        $grdgradient->{_Ne} = $Ne;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -Ne' . $grdgradient->{_Ne};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -Ne' . $grdgradient->{_Ne};
    }
}

=head2 sub S 


=cut

sub S {
    my ( $self, $S ) = @_;
    if ($S) {
        $grdgradient->{_S} = $S;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -S' . $grdgradient->{_S};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -S' . $grdgradient->{_S};
    }
}

=head2 sub infile 


=cut

sub infile {
    my ( $self, $infile ) = @_;
    if ($infile) {
        $grdgradient->{_infile} = $infile;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' ' . $grdgradient->{_infile};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' ' . $grdgradient->{_infile};
    }
}

=head2 sub outfile 


=cut

sub outfile {
    my ( $self, $outfile ) = @_;
    if ($outfile) {
        $grdgradient->{_outfile} = $outfile;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -G' . $grdgradient->{_outfile};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -G' . $grdgradient->{_outfile};
    }
}

=head2 sub limits 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $grdgradient->{_limits} = $limits;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -R' . $grdgradient->{_limits};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -R' . $grdgradient->{_limits};
    }
}

=head2 sub no_head 


=cut

sub no_head {
    my ( $self, $no_head ) = @_;
    if ($no_head) {
        $grdgradient->{_no_head} = $no_head;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -K' . $grdgradient->{_no_head};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -K' . $grdgradient->{_no_head};
    }
}

=head2 sub no_tail 


=cut

sub no_tail {
    my ( $self, $no_tail ) = @_;
    if ($no_tail) {
        $grdgradient->{_no_tail} = $no_tail;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -O' . $grdgradient->{_no_tail};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -O' . $grdgradient->{_no_tail};
    }
}

=head2 sub projection 


=cut

sub projection {
    my ( $self, $projection ) = @_;
    if ($projection) {
        $grdgradient->{_projection} = $projection;
        $grdgradient->{_note} =
          $grdgradient->{_note} . ' -J' . $grdgradient->{_projection};
        $grdgradient->{_Step} =
          $grdgradient->{_Step} . ' -J' . $grdgradient->{_projection};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $grdgradient->{_Step} = 'gmt grdgradient ' . $grdgradient->{_Step};
        return ( $grdgradient->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $grdgradient->{_note} = 'grdgradient ' . $grdgradient->{_note};
        return ( $grdgradient->{_note} );
    }
}

1;
