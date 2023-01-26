package App::SeismicUnixGui::gmt::blockmean;

=head1 DOCUMENTATION

=head2 SYNOPSIS

 PACKAGE NAME: blockmean
 AUTHOR: Juan Lorenzo
 DATE:   
 DESCRIPTION:
 Version: 

=head2 USE

=head3 NOTES

=head4 Examples

=head3 GMT NOTES

	blockmean 4.5.7 [64-bit] - Block averaging by L2 norm

	usage: blockmean [infile(s)] -I<xinc>[u][=|+][/<yinc>[u][=|+]] -R<west>/<east>/<south>/<north>[r]
	[-C] [-E] [-F] [-H[i][<nrec>]] [-S[w|z]] [-V] [-W[i][o]] [-:[i|o]] [-b[i|o][s|S|d|D[<ncol>]|c[<var1>/...]]]
	[-f[i|o]<colinfo>]

	-I<xinc>[m|c|e|k|i|n|+][=][/<yinc>[m|c|e|k|i|n|+][=]]
	   Give increment and append unit (m)inute, se(c)ond, m(e)ter, (k)ilometer, m(i)les, (n)autical miles.
	   (Note: m,c,e,k,i,n only apply to geographic regions specified in degrees)
	   Append = to adjust the domain to fit the increment [Default adjusts increment to fit domain].
	   Alternatively, specify number of nodes by appending +. Then, the increments are calculated
	   from the given domain and node-registration settings (see Appendix B for details).
	   Note: If -R<grdfile> was used the increments were set as well; use -I to override.
	-R specifies the min/max coordinates of data region in user units.
	   Use dd:mm[:ss] format for regions given in degrees and minutes [and seconds].
	   Use [yyy[-mm[-dd]]]T[hh[:mm[:ss[.xxx]]]] format for time axes.
	   Append r if -R specifies the longitudes/latitudes of the lower left
	   and upper right corners of a rectangular area.
	   -Rg -Rd are accepted shorthands for -R0/360/-90/90 -R-180/180/-90/90
	   Alternatively, give a gridfile and use its limits (and increments if applicable).

	OPTIONS:
	-C Output center of block and mean z-value.  [Default outputs (mean x, mean y) location]
	-E Extend output with st.dev (s), low (l), and high (h) value per block, i,e,
	   output (x,y,z,s,l,h[,w]) [Default outputs (x,y,z[,w]); see -W regarding w.
	-F Offsets registration so block edges are on gridlines (pixel reg.).  [Default: grid reg.]
	-H[i][n_rec] means input/output file has 1 Header record(s) [OFF]
	   Optionally, append i for input only and/or number of header records
	-Sz report block sums rather than mean values [Default is mean values].
	   -Sw reports weight sums instead of data sums.
	-V Run in verbose mode [OFF].
	-W sets Weight options.
	   -Wi reads Weighted Input (4 cols: x,y,z,w) but writes only (x,y,z[,s,l,h]) Output.
	   -Wo reads unWeighted Input (3 cols: x,y,z) but reports sum (x,y,z[,s,l,h],w) Output.
	   -W with no modifier has both weighted Input and Output; Default is no weights used.
	-: Expect lat/lon input/output rather than lon/lat [OFF/OFF].
	-bi for binary input.  Append s for single precision [Default is double]
	    Append <n> for the number of columns in binary file(s).
	   Default is 3 columns (or 4 if -W is set).
	-bo for binary output. Append s for single precision [Default is double]
	    Append <n> for the number of columns in binary file(s).
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
use aliased 'App::SeismicUnixGui::gmt::GMTglobal_constants';

=head2 instantiation

=cut

my $get = GMTglobal_constants->new();

=head2 declare variables

=cut

my $gmt_var = $get->gmt_var();
my $on      = $gmt_var->{_on};
my $off     = $gmt_var->{_off};
my $true    = $gmt_var->{_true};
my $false   = $gmt_var->{_false};

=head2 Encapsulated

	hash of private variables

=cut

my $blockmean = {
    _grid_spacing => '',
    _I            => '',
    _R            => '',
    _inbound      => '',
    _limits       => '',
    _Rd           => '',
    _Rg           => '',
    _C            => '',
    _E            => '',
    _W            => '',
    _F            => '',
    _Sz           => '',
    _Sw           => '',
    _V            => '',
    _verbose      => '',
    _Wi           => '',
    _Wo           => '',
    _bi           => '',
    _bo           => '',
    _f            => '',
    _Step         => '',
    _note         => '',
};

=head2 sub clear

=cut

sub clear {
    $blockmean->{_grid_spacing} = '';
    $blockmean->{_I}            = '';
    $blockmean->{_R}            = '';
    $blockmean->{_inbound}      = '';
    $blockmean->{_limits}       = '';
    $blockmean->{_Rd}           = '';
    $blockmean->{_Rg}           = '';
    $blockmean->{_C}            = '';
    $blockmean->{_E}            = '';
    $blockmean->{_W}            = '';
    $blockmean->{_F}            = '';
    $blockmean->{_Sz}           = '';
    $blockmean->{_Sw}           = '';
    $blockmean->{_V}            = '';
    $blockmean->{_verbose}      = '';
    $blockmean->{_W}            = '';
    $blockmean->{_Wi}           = '';
    $blockmean->{_Wo}           = '';
    $blockmean->{_bi}           = '';
    $blockmean->{_bo}           = '';
    $blockmean->{_f}            = '';
    $blockmean->{_Step}         = '';
    $blockmean->{_note}         = '';
}

=head2 sub grid_spacing 


=cut

sub grid_spacing {
    my ( $self, $grid_spacing ) = @_;
    if ($grid_spacing) {
        $blockmean->{_grid_spacing} = $grid_spacing;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -I' . $blockmean->{_grid_spacing};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -I' . $blockmean->{_grid_spacing};
    }
}

=head2 sub I 


=cut

sub I {
    my ( $self, $I ) = @_;
    if ($I) {
        $blockmean->{_I}    = $I;
        $blockmean->{_note} = $blockmean->{_note} . ' -I' . $blockmean->{_I};
        $blockmean->{_Step} = $blockmean->{_Step} . ' -I' . $blockmean->{_I};
    }
}

=head2 sub inbound 


=cut

sub inbound {
    my ( $self, $inbound ) = @_;
    if ($inbound) {
        $blockmean->{_inbound} = $inbound;
        $blockmean->{_note} =
          $blockmean->{_note} . ' ' . $blockmean->{_inbound};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' ' . $blockmean->{_inbound};

        # print("blockmean,inbound:$blockmean->{_inbound}\n");
        #  print("blockmean,inbound,Step:$blockmean->{_Step}\n");
    }
}

=head2 sub limits 


=cut

sub limits {
    my ( $self, $limits ) = @_;
    if ($limits) {
        $blockmean->{_limits} = $limits;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -R' . $blockmean->{_limits};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -R' . $blockmean->{_limits};
    }
}

=head2 sub R 


=cut

sub R {
    my ( $self, $R ) = @_;
    if ($R) {
        $blockmean->{_R}    = $R;
        $blockmean->{_note} = $blockmean->{_note} . ' -R' . $blockmean->{_R};
        $blockmean->{_Step} = $blockmean->{_Step} . ' -R' . $blockmean->{_R};
    }
}

=head2 sub Rd 


=cut

sub Rd {
    my ( $self, $Rd ) = @_;
    if ($Rd) {
        $blockmean->{_Rd} = $Rd;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -Rd' . $blockmean->{_Rd};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -Rd' . $blockmean->{_Rd};
    }
}

=head2 sub Rg 


=cut

sub Rg {
    my ( $self, $Rg ) = @_;
    if ($Rg) {
        $blockmean->{_Rg} = $Rg;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -Rg' . $blockmean->{_Rg};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -Rg' . $blockmean->{_Rg};
    }
}

=head2 sub C 


=cut

sub C {
    my ( $self, $C ) = @_;
    if ($C) {
        $blockmean->{_C}    = $C;
        $blockmean->{_note} = $blockmean->{_note} . ' -C' . $blockmean->{_C};
        $blockmean->{_Step} = $blockmean->{_Step} . ' -C' . $blockmean->{_C};
    }
}

=head2 sub E 


=cut

sub E {
    my ( $self, $E ) = @_;
    if ($E) {
        $blockmean->{_E}    = $E;
        $blockmean->{_note} = $blockmean->{_note} . ' -E' . $blockmean->{_E};
        $blockmean->{_Step} = $blockmean->{_Step} . ' -E' . $blockmean->{_E};
    }
}

=head2 sub W 


=cut

sub W {
    my ( $self, $W ) = @_;
    if ($W) {
        $blockmean->{_W}    = $W;
        $blockmean->{_note} = $blockmean->{_note} . ' -W' . $blockmean->{_W};
        $blockmean->{_Step} = $blockmean->{_Step} . ' -W' . $blockmean->{_W};
    }
}

=head2 sub F 


=cut

sub F {
    my ( $self, $F ) = @_;
    if ( $F eq $on ) {
        $blockmean->{_F}    = '';
        $blockmean->{_note} = $blockmean->{_note} . ' -F' . $blockmean->{_F};
        $blockmean->{_Step} = $blockmean->{_Step} . ' -F' . $blockmean->{_F};
    }
}

=head2 sub Sz 


=cut

sub Sz {
    my ( $self, $Sz ) = @_;
    if ($Sz) {
        $blockmean->{_Sz} = $Sz;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -Sz' . $blockmean->{_Sz};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -Sz' . $blockmean->{_Sz};
    }
}

=head2 sub Sw 


=cut

sub Sw {
    my ( $self, $Sw ) = @_;
    if ($Sw) {
        $blockmean->{_Sw} = $Sw;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -Sw' . $blockmean->{_Sw};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -Sw' . $blockmean->{_Sw};
    }
}

=head2 sub verbose 


=cut

sub verbose {
    my ( $self, $verbose ) = @_;
    if ( $verbose eq $on ) {
        $blockmean->{_verbose} = '';
        $blockmean->{_note} =
          $blockmean->{_note} . ' -V' . $blockmean->{_verbose};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -V' . $blockmean->{_verbose};
    }
}

=head2 sub V 


=cut

sub V {
    my ( $self, $V ) = @_;
    if ( $V eq $on ) {
        $blockmean->{_V}    = '';
        $blockmean->{_note} = $blockmean->{_note} . ' -V' . $blockmean->{_V};
        $blockmean->{_Step} = $blockmean->{_Step} . ' -V' . $blockmean->{_V};
    }
}

=head2 sub Wi 


=cut

sub Wi {
    my ( $self, $Wi ) = @_;
    if ($Wi) {
        $blockmean->{_Wi} = $Wi;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -Wi' . $blockmean->{_Wi};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -Wi' . $blockmean->{_Wi};
    }
}

=head2 sub Wo 


=cut

sub Wo {
    my ( $self, $Wo ) = @_;
    if ($Wo) {
        $blockmean->{_Wo} = $Wo;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -Wo' . $blockmean->{_Wo};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -Wo' . $blockmean->{_Wo};
    }
}

=head2 sub bi 


=cut

sub bi {
    my ( $self, $bi ) = @_;
    if ($bi) {
        $blockmean->{_bi} = $bi;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -bi' . $blockmean->{_bi};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -bi' . $blockmean->{_bi};
    }
}

=head2 sub bo 


=cut

sub bo {
    my ( $self, $bo ) = @_;
    if ($bo) {
        $blockmean->{_bo} = $bo;
        $blockmean->{_note} =
          $blockmean->{_note} . ' -bo' . $blockmean->{_bo};
        $blockmean->{_Step} =
          $blockmean->{_Step} . ' -bo' . $blockmean->{_bo};
    }
}

=head2 sub f 


=cut

sub f {
    my ( $self, $f ) = @_;
    if ($f) {
        $blockmean->{_f}    = $f;
        $blockmean->{_note} = $blockmean->{_note} . ' -f' . $blockmean->{_f};
        $blockmean->{_Step} = $blockmean->{_Step} . ' -f' . $blockmean->{_f};
    }
}

=head2 sub Step 


=cut

sub Step {
    my ($self) = @_;
    if ($self) {
        $blockmean->{_Step} = 'gmt blockmean ' . $blockmean->{_Step};

        # print(" blockmean,Step,$blockmean->{_Step}\n");
        return ( $blockmean->{_Step} );
    }
}

=head2 sub note 


=cut

sub note {
    my ($self) = @_;
    if ($self) {
        $blockmean->{_note} = 'blockmean ' . $blockmean->{_note};
        return ( $blockmean->{_note} );
    }
}

1;
