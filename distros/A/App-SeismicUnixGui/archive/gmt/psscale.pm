package App::SeismicUnixGui::gmt::psscale;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: psscale
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

psscale 4.5.7 [64-bit] - To create grayscale or colorscale for maps

usage: psscale -D<xpos/ypos/length/width>[h] [-A[a|l|c]] [-C<cpt_file>] [-E[b|f][<length>]] [-B<params>] [-I[<max_intens>|<low_i>/<high_i>]
	[-K] [-L[i][<gap>]] [-M] [-N<dpi>] [-O] [-P] [-Q] [-S] [-U[<just>/<dx>/<dy>/][c|<label>]] [-V] [-X[a|c|r]<x_shift>[u]]
	[-Y[a|c|r]<x_shift>[u]] [-Z<zfile>] [-c<ncopies>]

	-D set mid-point position and length/width for scale.
	   Give negative length to reverse the scalebar
	   Append h for horizontal scale

	OPTIONS:
	-A Place the desired annotations/labels on the other side of the colorscale instead
	   Append a or l to move only the annotations or labels to the other side
	   Append c to plot vertical labels as columns
	-B Set scale annotation interval and label. Use y-label to set unit label
	   If no annotation interval is set it is taken from the cpt file
	-C Color palette file. If not set, stdin is read.
	   By default all color changes are annotated (but see -B).  To use a subset,
	   add an extra column to the cpt-file with a L, U, or B
	   to annotate Lower, Upper, or Both color segment boundaries
	   If a categorical CPT file is given the -Li is set automatically
	-E add sidebar triangles for back- and foreground colors.
	   Specify b(ackground) or f(oreground) to get one only [Default is both]
	   Optionally, append triangle height [Default is half the barwidth]
	-I add illumination for +-<max_intens> or <low_i> to <high_i> [-1.0/1.0]
	   Alternatively, specify <lower>/<upper> intensity values
	-K means allow for more plot code to be appended later [OFF].
	-L For equal-sized color rectangles. -B interval cannot be used.
	   Append i to annotate the interval range instead of lower/upper.
	   If <gap> is appended, we separate each rectangle by <gap> units and center each
	   lower (z0) annotation on the rectangle.  Ignored if not a discrete cpt table.
	   If -I is used then each rectangle will have the illuminated constant color.
	-M force monochrome colorbar using GMT_YIQ transformation
	-N effective dots-per-inch for color scale [300]
	-O means Overlay plot mode [OFF].
	-P means Portrait page orientation [OFF].
	-Q Plot colorbar using logarithmic scale and annotate powers of 10 [Default is linear]
	-S Skip drawing color boundary lines on color scale [Default draws lines]
	-U to plot Unix System Time stamp [and optionally appended text].
	   You may also set the reference points and position of stamp [BL/-2c/-2c].
	   Give -Uc to have the command line plotted [OFF].
	-V Run in verbose mode [OFF].
	-X -Y to shift origin of plot to (<xshift>, <yshift>) [a2.5c,a2.5c].
	   Prepend a for absolute [Default r is relative]
	   (Note that for overlays (-O), the default is [r0,r0].)
	   Give c to center plot on page in x and/or y.
	-Z give colorbar-width (in cm) per color entry
	   By default, width of entry is scaled to color range
	   i.e., z = 0-100 gives twice the width as z = 100-150.
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

my $psscale = {
    _D          => '',
    _A          => '',
    _B          => '',
    _C          => '',
    _Li         => '',
    _E          => '',
    _K          => '',
    _L          => '',
    _I          => '',
    _M          => '',
    _N          => '',
    _O          => '',
    _P          => '',
    _Q          => '',
    _S          => '',
    _U          => '',
    _Uc         => '',
    _V          => '',
    _X          => '',
    _Z          => '',
    _c          => '',
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
    $psscale->{_D}          = '';
    $psscale->{_A}          = '';
    $psscale->{_B}          = '';
    $psscale->{_C}          = '';
    $psscale->{_Li}         = '';
    $psscale->{_E}          = '';
    $psscale->{_I}          = '';
    $psscale->{_K}          = '';
    $psscale->{_L}          = '';
    $psscale->{_I}          = '';
    $psscale->{_M}          = '';
    $psscale->{_N}          = '';
    $psscale->{_O}          = '';
    $psscale->{_P}          = '';
    $psscale->{_Q}          = '';
    $psscale->{_S}          = '';
    $psscale->{_U}          = '';
    $psscale->{_Uc}         = '';
    $psscale->{_V}          = '';
    $psscale->{_X}          = '';
    $psscale->{_Z}          = '';
    $psscale->{_c}          = '';
    $psscale->{_infile}     = '';
    $psscale->{_outfile}    = '';
    $psscale->{_limits}     = '';
    $psscale->{_projection} = '';
    $psscale->{_no_head}    = '';
    $psscale->{_no_tail}    = '';
    $psscale->{_verbose}    = '';
    $psscale->{_Step}       = '';
    $psscale->{_note}       = '';
}

=head2 sub D 


=cut

sub D {
    my ( $self, $D ) = @_;
    if ($D) {
        $psscale->{_D}    = $D;
        $psscale->{_note} = $psscale->{_note} . ' -D' . $psscale->{_D};
        $psscale->{_Step} = $psscale->{_Step} . ' -D' . $psscale->{_D};
    }
}

=head2 sub A 


=cut

sub A {
    my ( $self, $A ) = @_;
    if ($A) {
        $psscale->{_A}    = $A;
        $psscale->{_note} = $psscale->{_note} . ' -A' . $psscale->{_A};
        $psscale->{_Step} = $psscale->{_Step} . ' -A' . $psscale->{_A};
    }
}

=head2 sub B 


=cut

sub B {
    my ( $self, $B ) = @_;
    if ($B) {
        $psscale->{_B}    = $B;
        $psscale->{_note} = $psscale->{_note} . ' -B' . $psscale->{_B};
        $psscale->{_Step} = $psscale->{_Step} . ' -B' . $psscale->{_B};
    }
}

=head2 sub C 


=cut

sub C {
    my ( $self, $C ) = @_;
    if ($C) {
        $psscale->{_C}    = $C;
        $psscale->{_note} = $psscale->{_note} . ' -C' . $psscale->{_C};
        $psscale->{_Step} = $psscale->{_Step} . ' -C' . $psscale->{_C};
    }
}

=head2 sub Li 


=cut

sub Li {
    my ( $self, $Li ) = @_;
    if ($Li) {
        $psscale->{_Li}   = $Li;
        $psscale->{_note} = $psscale->{_note} . ' -Li' . $psscale->{_Li};
        $psscale->{_Step} = $psscale->{_Step} . ' -Li' . $psscale->{_Li};
    }
}

=head2 sub E 


=cut

sub E {
    my ( $self, $E ) = @_;
    if ($E) {
        $psscale->{_E}    = $E;
        $psscale->{_note} = $psscale->{_note} . ' -E' . $psscale->{_E};
        $psscale->{_Step} = $psscale->{_Step} . ' -E' . $psscale->{_E};
    }
}

=head2 sub I 


=cut

sub I {
    my ( $self, $I ) = @_;
    if ($I) {
        $psscale->{_I}    = $I;
        $psscale->{_note} = $psscale->{_note} . ' -I' . $psscale->{_I};
        $psscale->{_Step} = $psscale->{_Step} . ' -I' . $psscale->{_I};
    }
}

=head2 sub K 


=cut

sub K {
    my ( $self, $K ) = @_;
    if ($K) {
        $psscale->{_K}    = $K;
        $psscale->{_note} = $psscale->{_note} . ' -K' . $psscale->{_K};
        $psscale->{_Step} = $psscale->{_Step} . ' -K' . $psscale->{_K};
    }
}

=head2 sub L 


=cut

sub L {
    my ( $self, $L ) = @_;
    if ($L) {
        $psscale->{_L}    = $L;
        $psscale->{_note} = $psscale->{_note} . ' -L' . $psscale->{_L};
        $psscale->{_Step} = $psscale->{_Step} . ' -L' . $psscale->{_L};
    }
}

=head2 sub M 


=cut

sub M {
    my ( $self, $M ) = @_;
    if ($M) {
        $psscale->{_M}    = $M;
        $psscale->{_note} = $psscale->{_note} . ' -M' . $psscale->{_M};
        $psscale->{_Step} = $psscale->{_Step} . ' -M' . $psscale->{_M};
    }
}

=head2 sub N 


=cut

sub N {
    my ( $self, $N ) = @_;
    if ($N) {
        $psscale->{_N}    = $N;
        $psscale->{_note} = $psscale->{_note} . ' -N' . $psscale->{_N};
        $psscale->{_Step} = $psscale->{_Step} . ' -N' . $psscale->{_N};
    }
}

=head2 sub O 


=cut

sub O {
    my ( $self, $O ) = @_;
    if ($O) {
        $psscale->{_O}    = $O;
        $psscale->{_note} = $psscale->{_note} . ' -O' . $psscale->{_O};
        $psscale->{_Step} = $psscale->{_Step} . ' -O' . $psscale->{_O};
    }
}

=head2 sub P 


=cut

sub P {
    my ( $self, $P ) = @_;
    if ($P) {
        $psscale->{_P}    = $P;
        $psscale->{_note} = $psscale->{_note} . ' -P' . $psscale->{_P};
        $psscale->{_Step} = $psscale->{_Step} . ' -P' . $psscale->{_P};
    }
}

=head2 sub Q 


=cut

sub Q {
    my ( $self, $Q ) = @_;
    if ($Q) {
        $psscale->{_Q}    = $Q;
        $psscale->{_note} = $psscale->{_note} . ' -Q' . $psscale->{_Q};
        $psscale->{_Step} = $psscale->{_Step} . ' -Q' . $psscale->{_Q};
    }
}

=head2 sub S 


=cut

sub S {
    my ( $self, $S ) = @_;
    if ($S) {
        $psscale->{_S}    = $S;
        $psscale->{_note} = $psscale->{_note} . ' -S' . $psscale->{_S};
        $psscale->{_Step} = $psscale->{_Step} . ' -S' . $psscale->{_S};
    }
}

=head2 sub U 


=cut

sub U {
    my ( $self, $U ) = @_;
    if ($U) {
        $psscale->{_U}    = $U;
        $psscale->{_note} = $psscale->{_note} . ' -U' . $psscale->{_U};
        $psscale->{_Step} = $psscale->{_Step} . ' -U' . $psscale->{_U};
    }
}

=head2 sub Uc 


=cut

sub Uc {
    my ( $self, $Uc ) = @_;
    if ($Uc) {
        $psscale->{_Uc}   = $Uc;
        $psscale->{_note} = $psscale->{_note} . ' -Uc' . $psscale->{_Uc};
        $psscale->{_Step} = $psscale->{_Step} . ' -Uc' . $psscale->{_Uc};
    }
}

=head2 sub V 


=cut

sub V {
    my ( $self, $V ) = @_;
    if ($V) {
        $psscale->{_V}    = $V;
        $psscale->{_note} = $psscale->{_note} . ' -V' . $psscale->{_V};
        $psscale->{_Step} = $psscale->{_Step} . ' -V' . $psscale->{_V};
    }
}

=head2 sub X 


=cut

sub X {
    my ( $self, $X ) = @_;
    if ($X) {
        $psscale->{_X}    = $X;
        $psscale->{_note} = $psscale->{_note} . ' -X' . $psscale->{_X};
        $psscale->{_Step} = $psscale->{_Step} . ' -X' . $psscale->{_X};
    }
}

=head2 sub Z 


=cut

sub Z {
    my ( $self, $Z ) = @_;
    if ($Z) {
        $psscale->{_Z}    = $Z;
        $psscale->{_note} = $psscale->{_note} . ' -Z' . $psscale->{_Z};
        $psscale->{_Step} = $psscale->{_Step} . ' -Z' . $psscale->{_Z};
    }
}

=head2 sub c 


=cut

sub c {
    my ( $self, $c ) = @_;
    if ($c) {
        $psscale->{_c}    = $c;
        $psscale->{_note} = $psscale->{_note} . ' -c' . $psscale->{_c};
        $psscale->{_Step} = $psscale->{_Step} . ' -c' . $psscale->{_c};
    }
}

=head2 sub infile 


=cut

sub infile {
    my ( $self, $infile ) = @_;
    if ($infile) {
        $psscale->{_infile} = $infile;
        $psscale->{_note}   = $psscale->{_note} . ' ' . $psscale->{_infile};
        $psscale->{_Step}   = $psscale->{_Step} . ' ' . $psscale->{_infile};
    }
}

=head2 sub outfile 


=cut

sub outfile {
    my ( $self, $outfile ) = @_;
    if ($outfile) {
        $psscale->{_outfile} = $outfile;
        $psscale->{_note}    = $psscale->{_note} . ' -G' . $psscale->{_outfile};
        $psscale->{_Step}    = $psscale->{_Step} . ' -G' . $psscale->{_outfile};
    }
}

=head2 sub limits 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $psscale->{_limits} = $limits;
        $psscale->{_note}   = $psscale->{_note} . ' -R' . $psscale->{_limits};
        $psscale->{_Step}   = $psscale->{_Step} . ' -R' . $psscale->{_limits};
    }
}

=head2 sub no_head 


=cut

sub no_head {
    my ( $self, $no_head ) = @_;
    if ($no_head) {
        $psscale->{_no_head} = $no_head;
        $psscale->{_note}    = $psscale->{_note} . ' -K' . $psscale->{_no_head};
        $psscale->{_Step}    = $psscale->{_Step} . ' -K' . $psscale->{_no_head};
    }
}

=head2 sub no_tail 


=cut

sub no_tail {
    my ( $self, $no_tail ) = @_;
    if ($no_tail) {
        $psscale->{_no_tail} = $no_tail;
        $psscale->{_note}    = $psscale->{_note} . ' -O' . $psscale->{_no_tail};
        $psscale->{_Step}    = $psscale->{_Step} . ' -O' . $psscale->{_no_tail};
    }
}

=head2 sub projection 


=cut

sub projection {
    my ( $self, $projection ) = @_;
    if ($projection) {
        $psscale->{_projection} = $projection;
        $psscale->{_note} =
          $psscale->{_note} . ' -J' . $psscale->{_projection};
        $psscale->{_Step} =
          $psscale->{_Step} . ' -J' . $psscale->{_projection};
    }
}

=head2 sub verbose 


=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ( $verbose eq $on ) {
        $psscale->{_verbose} = '';
        $psscale->{_Step}    = $psscale->{_Step} . ' -V' . $psscale->{_verbose};
        $psscale->{_note}    = $psscale->{_note} . ' -V' . $psscale->{_verbose};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $psscale->{_Step} = 'gmt psscale ' . $psscale->{_Step};
        return ( $psscale->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $psscale->{_note} = 'psscale ' . $psscale->{_note};
        return ( $psscale->{_note} );
    }
}

1;
