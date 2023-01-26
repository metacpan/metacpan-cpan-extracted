package App::SeismicUnixGui::gmt::makecpt;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: makecpt
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

	makecpt 4.5.7 [64-bit] - Make GMT color palette tables

	usage:  makecpt [-C<table>] [-D] [-I] [-M] [-N] [-Q[i|o]] [-T<z0/z1/dz> | -T<file>] [-V] [-Z]

	OPTIONS:
	-C Specify a colortable [Default is rainbow]:
	   [Default min/max values for -T are given in brackets]
	   ---------------------------------
	   cool      : Linear change from blue to magenta [0/1]
	   copper    : Dark to light copper brown [0/1]
	   cyclic    : Cyclic colormap, spans 360 degrees of hue [0/360]
	   drywet    : Goes from dry to wet colors [0/12]
	   gebco     : Colors for GEBCO bathymetric charts [-7000/0]
	   globe     : Colors for global bathy-topo relief [-10000/10000]
	   gray      : Grayramp from black to white [0/1]
	   haxby     : Bill Haxby's colortable for geoid & gravity [0/32]
	   hot       : Black through red and yellow to white [0/1]
	   jet       : Dark to light blue, white, yellow and red [0/1]
	   nighttime : Colors for DMSP-OLS Nighttime Lights Time Series [0/1]
	   no_green  : For those who hate green [-32/+32]
	   ocean     : white-green-blue bathymetry scale [-8000/0]
	   panoply   : Default colormap of Panoply [0/16]
	   paired    : Qualitative color map with 6 pairs of colors [0/12]
	   polar     : Blue via white to red [-1/+1]
	   rainbow   : Rainbow: magenta-blue-cyan-green-yellow-red [0/300]
	   red2green : Polar scale from red to green via white [-1/+1]
	   relief    : Wessel/Martinez colors for topography [-8000/+8000]
	   sealand   : Smith bathymetry/topography scale [-6000/+3000]
	   seis      : R-O-Y-G-B seismic tomography colors [-1/+1]
	   split     : Like polar, but via black instead of white [-1/+1]
	   topo      : Sandwell/Anderson colors for topography [-7000/+7000]
	   wysiwyg   : 20 well-separated RGB colors [0/20]
	   ---------------------------------
	-D Set back- and foreground color to match the bottom/top limits in the cpt file [Default uses color table].
	-I Reverses the sense of the color table as well as back- and foreground color.
	-M Use GMT defaults to set back-, foreground, and NaN colors [Default uses color table].
	-N Do not write back-, foreground, and NaN colors [Default will].
	-Q Assign a logarithmic colortable [Default is linear]
	   -Qi: z-values are actually log10(z). Assign colors and write z. [Default]
	   -Qo: z-values are z, but take log10(z), assign colors and write z.
	        If -T<z0/z1/dz> is given, dz is 1, 2, or 3 (as in logarithmic annotations)
	-T Give start, stop, and increment for colorscale in z-units, or filename with custom z-values
	   If not given, the range in the master cptfile is used
	-V Run in verbose mode [OFF].
	-Z Create a continuous color palette [Default is discontinuous, i.e., constant color intervals]

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '1.0.1';

=head2 Encapsulated

	hash of private variables

=cut

my $makecpt = {
    _color_table => '',
    _C           => '',
    _D           => '',
    _I           => '',
    _M           => '',
    _N           => '',
    _Q           => '',
    _T           => '',
    _V           => '',
    _Z           => '',
    _Step        => '',
    _note        => '',
};

=head2 sub clear

=cut

sub clear {
    $makecpt->{_color_table} = '';
    $makecpt->{_C}           = '';
    $makecpt->{_D}           = '';
    $makecpt->{_I}           = '';
    $makecpt->{_M}           = '';
    $makecpt->{_N}           = '';
    $makecpt->{_Q}           = '';
    $makecpt->{_T}           = '';
    $makecpt->{_V}           = '';
    $makecpt->{_Z}           = '';
    $makecpt->{_Step}        = '';
    $makecpt->{_note}        = '';
}

=head2 sub color_table 


=cut

sub color_table {
    my ( $self, $color_table ) = @_;
    if ($color_table) {
        $makecpt->{_color_table} = $color_table;
        $makecpt->{_note} =
          $makecpt->{_note} . ' -C' . $makecpt->{_color_table};
        $makecpt->{_Step} =
          $makecpt->{_Step} . ' -C' . $makecpt->{_color_table};
    }
}

=head2 sub C 


=cut

sub C {
    my ( $self, $C ) = @_;
    if ($C) {
        $makecpt->{_C}    = $C;
        $makecpt->{_note} = $makecpt->{_note} . ' -C' . $makecpt->{_C};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -C' . $makecpt->{_C};
    }
}

=head2 sub D 


=cut

sub D {
    my ( $self, $D ) = @_;
    if ($D) {
        $makecpt->{_D}    = $D;
        $makecpt->{_note} = $makecpt->{_note} . ' -D' . $makecpt->{_D};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -D' . $makecpt->{_D};
    }
}

=head2 sub I 


=cut

sub I {
    my ( $self, $I ) = @_;
    if ($I) {
        $makecpt->{_I}    = $I;
        $makecpt->{_note} = $makecpt->{_note} . ' -I' . $makecpt->{_I};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -I' . $makecpt->{_I};
    }
}

=head2 sub M 


=cut

sub M {
    my ( $self, $M ) = @_;
    if ($M) {
        $makecpt->{_M}    = $M;
        $makecpt->{_note} = $makecpt->{_note} . ' -M' . $makecpt->{_M};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -M' . $makecpt->{_M};
    }
}

=head2 sub N 


=cut

sub N {
    my ( $self, $N ) = @_;
    if ($N) {
        $makecpt->{_N}    = $N;
        $makecpt->{_note} = $makecpt->{_note} . ' -N' . $makecpt->{_N};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -N' . $makecpt->{_N};
    }
}

=head2 sub Q 


=cut

sub Q {
    my ( $self, $Q ) = @_;
    if ($Q) {
        $makecpt->{_Q}    = $Q;
        $makecpt->{_note} = $makecpt->{_note} . ' -Q' . $makecpt->{_Q};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -Q' . $makecpt->{_Q};
    }
}

=head2 sub T 


=cut

sub T {
    my ( $self, $T ) = @_;
    if ($T) {
        $makecpt->{_T}    = $T;
        $makecpt->{_note} = $makecpt->{_note} . ' -T' . $makecpt->{_T};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -T' . $makecpt->{_T};
    }
}

=head2 sub V 


=cut

sub V {
    my ( $self, $V ) = @_;
    if ($V) {
        $makecpt->{_V}    = $V;
        $makecpt->{_note} = $makecpt->{_note} . ' -V' . $makecpt->{_V};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -V' . $makecpt->{_V};
    }
}

=head2 sub Z 


=cut

sub Z {
    my ( $self, $Z ) = @_;
    if ($Z) {
        $makecpt->{_Z}    = $Z;
        $makecpt->{_note} = $makecpt->{_note} . ' -Z' . $makecpt->{_Z};
        $makecpt->{_Step} = $makecpt->{_Step} . ' -Z' . $makecpt->{_Z};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $makecpt->{_Step} = 'gmt makecpt ' . $makecpt->{_Step};
        return ( $makecpt->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $makecpt->{_note} = 'makecpt ' . $makecpt->{_note};
        return ( $makecpt->{_note} );
    }
}

1;
