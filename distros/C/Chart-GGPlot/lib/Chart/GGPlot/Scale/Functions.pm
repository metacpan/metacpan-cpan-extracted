package Chart::GGPlot::Scale::Functions;

# ABSTRACT: Scale functions

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0011'; # VERSION

use List::AllUtils qw(pairgrep);
use Module::Load;
use Type::Params;
use Types::PDL qw(Piddle PiddleFromAny);
use Types::Standard qw(Any CodeRef Maybe Str);

use Chart::GGPlot::Aes::Functions qw(:all);
use Chart::GGPlot::Range::Functions qw(:all);
use Chart::GGPlot::Trans::Functions qw(as_trans);
use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util qw(:all);

use parent qw(Exporter::Tiny);

my @export_ggplot = (
    alias_color_functions(
        __PACKAGE__,
        qw(
          continuous_scale discrete_scale
          scale_x_continuous scale_y_continuous
          scale_x_log10 scale_y_log10
          scale_x_reverse scale_y_reverse
          scale_x_sqrt scale_y_sqrt
          scale_x_discrete scale_y_discrete
          scale_x_datetime scale_y_datetime
          scale_color_hue scale_color_discrete
          scale_fill_hue scale_fill_discrete
          scale_color_continuous scale_fill_continuous
          scale_color_brewer scale_fill_brewer
          scale_color_distiller scale_fill_distiller
          scale_color_gradient scale_fill_gradient
          scale_color_gradient2 scale_fill_gradient2
          scale_color_gradientn scale_fill_gradientn
          scale_color_viridis_d scale_fill_viridis_d
          scale_fill_ordinal scale_fill_ordinal
          scale_color_viridis_c scale_fill_viridis_c
          scale_size_continuous
          scale_alpha_continuous scale_alpha
          scale_color_identity scale_shape_identity scale_linetype_identity
          scale_alpha_identity scale_size_identity
          )
    )
);

our @EXPORT_OK = ( @export_ggplot, qw(find_scale scale_flip_position) );
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => \@export_ggplot,
);

my %scale_funcs;


fun find_scale ($aes, $x) {
    my $types = scale_type($x);

    for my $t (@$types) {
        my $func_name = join( '_', "scale", $aes, $t );
        if ( my $f = $scale_funcs{$func_name} ) {
            return ( wantarray ? ( $f, $func_name ) : $f );
        }
    }
    return;
}

fun scale_type ($x) {
    if ( $x->$_DOES('PDL::Factor') ) {
        return $x->DOES('PDL::Factor::Ordered')
          ? [qw(ordinal discrete)]
          : ['discrete'];
    }
    elsif ( $x->$_DOES('PDL::SV') ) {
        return ['discrete'];
    }
    elsif ( $x->$_DOES('PDL::DateTime') ) {
        return ['datetime'];
    }
    elsif ( $x->$_DOES('PDL') ) {
        if ( $x->type eq 'byte' ) {
            return ['discrete'];
        }
        else {
            return ['continuous'];
        }
    }
    return ['identity'];
}

fun _check_breaks_labels ( $breaks, $labels ) {
    state $check = Type::Params::compile(
        Maybe [ Piddle->plus_coercions(PiddleFromAny) | CodeRef ],
        Maybe [
            Piddle->plus_coercions( Any, sub { PDL::SV->new($_) } ) | CodeRef ]
    );
    ( $breaks, $labels ) = $check->( $breaks, $labels );

    return ( $breaks, $labels )
      unless ( defined $breaks and !$breaks->isempty );
    return ( $breaks, $labels )
      unless ( defined $labels and !$labels->isempty );

    # In R code there is check for is.atomic(breaks) && is.atomic(labels).
    # List or function is not atomic in R.
    if (   $breaks->$_isa('PDL')
        && $labels->$_isa('PDL')
        && ( $breaks->length != $labels->length ) )
    {
        die("`breaks` and `labels` must have the same length");
    }

    return ($breaks, $labels);
}


fun continuous_scale (:$aesthetics, :$scale_name,
                      :$palette, :$name=undef,
                      :$breaks=undef, :$minor_breaks=undef,
                      :$labels=undef, :$limits=null(),
                      :$rescaler=\&rescale, :$oob=\&censor, :$expand=undef,
                      :$na_value='nan',
                      :$trans="identity", :$guide="legend",
                      PositionEnum :$position="left",
                      Str :$super='Chart::GGPlot::Scale::Continuous',
                      %rest
  ) {
    ($breaks, $labels) = _check_breaks_labels( $breaks, $labels );

    if (    ( defined $breaks and $breaks->isempty )
        and !is_position_aes($aesthetics)
        and $guide ne "none" )
    {
        $guide = "none";
    }

    $trans = as_trans($trans);
    if ( defined $limits ) {
        $limits = $trans->transform->( pdl($limits) );
    }

    load $super;
    return $super->new(
        pairgrep { defined $b } 
        (
            aesthetics => $aesthetics,
            scale_name => $scale_name,
            palette    => $palette,
            range      => continuous_range(),
            limits     => $limits,
            trans      => $trans,
            na_value   => $na_value,
            expand     => $expand,
            rescaler   => $rescaler,     # Used by diverging and n color gradients
            oob          => $oob,
            name         => $name,
            breaks       => $breaks,
            minor_breaks => $minor_breaks,
            labels       => $labels,
            guide        => $guide,
            position     => $position,
            %rest
        )
    );
}


fun discrete_scale (:$aesthetics, :$scale_name,
                    :$palette, :$name=undef,
                    :$breaks=undef, :$labels=undef,
                    :$limits=PDL::SV->new([]),
                    :$expand=undef, :$na_translate=true, :$na_value=undef,
                    :$drop=true, :$guide="legend",
                    PositionEnum :$position = "left",
                    Str :$super = 'Chart::GGPlot::Scale::Discrete',
                    %rest
  ) {
    ($breaks, $labels) = _check_breaks_labels( $breaks, $labels );

    if (    ( defined $breaks and $breaks->isempty )
        and !is_position_aes($aesthetics)
        and $guide ne "none" )
    {
        $guide = "none";
    }

    load $super;
    return $super->new(
        pairgrep { defined $b }
        (
            aesthetics   => $aesthetics,
            scale_name   => $scale_name,
            palette      => $palette,
            range        => discrete_range(),
            limits       => $limits,
            na_value     => $na_value,
            na_translate => $na_translate,
            expand       => $expand,
            name         => $name,
            breaks       => $breaks,
            labels       => $labels,
            drop         => $drop,
            guide        => $guide,
            position     => $position,
            %rest
        )
    );
}

# In place modification of a scale to change the primary axis
fun scale_flip_position ($scale) {
    state $switch = {
        top    => "bottom",
        bottom => "top",
        left   => "right",
        right  => "left",
    };
    $scale->position( $switch->{ $scale->position } );
    return $scale;
}


fun _scale_hue ($aes) {
    return fun(:$h = pdl( [ 0, 360 ] ) + 15,
               :$c = 100, :$l = 65,
               :$h_start = 0,
               :$direction = 1,
               :$na_value = 'grey50',
               %rest
      ) {
        return discrete_scale(
            aesthetics => $aes,
            scale_name => 'hue',
            palette    => hue_pal(
                h         => $h,
                c         => $c,
                l         => $l,
                h_start   => $h_start,
                direction => $direction
            ),
            na_value => _na_value_color($na_value),
            %rest
        );
    };
}

*scale_color_hue      = _scale_hue('color');
*scale_color_discrete = \&scale_color_hue;
*scale_fill_hue       = _scale_hue('fill');
*scale_fill_discrete  = \&scale_fill_hue;


fun _scale_brewer ($aes) {
    return fun(ColorBrewerTypeEnum :$type = "seq",
               :$palette = 0,
               :$direction = 1,
               %rest
      ) {
        return discrete_scale(
            aesthetics => $aes,
            scale_name => "brewer",
            palette    => brewer_pal( $type, $palette, $direction ),
            %rest
        );
    };
}

*scale_color_brewer = _scale_brewer('color');
*scale_fill_brewer  = _scale_brewer('fill');


fun _scale_distiller ($aes) {
    return fun(ColorBrewerTypeEnum :$type = "seq",
               :$palette = 1,
               :$direction = -1, :$values = [], :$na_value = "grey50",
               :$guide = "colorbar",
               %rest
      ) {
        if ( $type eq "qual" ) {
            warn(   "Using a discrete color palette in a continuous scale.\n"
                  . "  Consider using type = \"seq\" or type = \"div\" instead"
            );
        }
        return continuous_scale(
            aesthetics => $aes,
            scale_name => 'distiller',
            palette    => gradient_n_pal(
                brewer_pal( $type, $palette, $direction )->[6], $values,
            ),
            na_value => _na_value_color($na_value),
            guide    => $guide,
            %rest
        );
    };
}

*scale_color_distiller = _scale_distiller('color');
*scale_fill_distiller  = _scale_distiller('fill');


fun _scale_gradient ($aes) {
    return fun(:$low = "#132B43", :$high = "#56B1F7",
               :$na_value = "grey50",
               :$guide = "colorbar",
               %rest
      ) {
        return continuous_scale(
            aesthetics => $aes,
            scale_name => "gradient",
            palette    => seq_gradient_pal( $low, $high ),
            na_value   => _na_value_color($na_value),
            guide      => $guide,
            %rest
        );
    };
}

*scale_color_gradient = _scale_gradient('color');
*scale_fill_gradient  = _scale_gradient('fill');


fun _scale_gradient2 ($aes) {
    return fun(:$low = muted("red"), :$mid = "white",
               :$high = muted("blue"),
               :$midpoint = 0,
               :$na_value = "grey50",
               :$guide = "colorbar",
               %rest
      ) {
        return continuous_scale(
            aesthetics => $aes,
            scale_name => "gradient2",
            palette    => div_gradient_pal( $low, $mid, $high ),
            na_value   => _na_value_color($na_value),
            guide      => $guide,
            rescaler   => _mid_rescaler($midpoint),
            %rest
        );
    };
}

*scale_color_gradient2 = _scale_gradient2('color');
*scale_fill_gradient2  = _scale_gradient2('fill');


fun _scale_gradientn ($aes) {
    return fun(:$values = [], :$na_value = "grey50",
               :$guide = "colorbar",
               %rest
      ) {
        my $colors = ( delete $rest{colors} ) // ( delete $rest{colours} );
        continuous_scale(
            aesthetics => $aes,
            scale_name => "gradientn",
            palette    => gradient_n_pal( $colors, $values ),
            na_value   => _na_value_color($na_value),
            guide      => $guide,
            %rest
        );
    };
}

*scale_color_gradientn = _scale_gradientn('color');
*scale_fill_gradientn  = _scale_gradientn('fill');


fun _scale_viridis_d ($aes) {
    return fun (:$begin = 0, :$end = 1,
                :$direction = 1, :$option = 'viridis',
                %rest
            ) {
        return discrete_scale(
            aesthetics => $aes,
            scale_name => "viridis_d",
            palette    => viridis_pal( $begin, $end, $direction, $option ),
            %rest,
        );
    };
}

*scale_color_viridis_d = _scale_viridis_d('color');
*scale_color_ordinal   = \&scale_color_viridis_d;
*scale_fill_viridis_d  = _scale_viridis_d('fill');
*scale_fill_ordinal    = \&scale_fill_viridis_d;


fun _scale_viridis_c ($aes) {
    return fun (:$begin = 0, :$end = 1,
                :$direction = 1, :$option = 'viridis', :$values = null(),
                :$na_value = 'grey50',
                :$guide = 'colorbar',
                %rest
            ) {
        
        my $pal =
          gradient_n_pal( viridis_pal( $begin, $end, $direction, $option )->(6),
            $values );
        return continuous_scale(
            aesthetics => $aes,
            scale_name => "viridis_c",
            palette    => $pal,
            na_value   => $na_value,
            guide      => $guide,
            %rest,
        );
    };
}

*scale_color_viridis_c = _scale_viridis_c('color');
*scale_fill_viridis_c  = _scale_viridis_c('fill');


fun scale_color_continuous (:$type = "gradient", %rest) {
    state $switch = {
        gradient => \&scale_color_gradient,
        viridis  => \&scale_color_viridis_c,
    };
    if ( my $func = $switch->{$type} ) {
        return $func->(%rest);
    }
    die("Unknown scale type");
}

fun scale_fill_continuous (:$type = "gradient", %rest) {
    state $switch = {
        gradient => \&scale_fill_gradient,
        viridis  => \&scale_fill_viridis_c,
    };
    if ( my $func = $switch->{$type} ) {
        return $func->(%rest);
    }
    die("Unknown scale type");
}


fun scale_alpha_continuous (:$range=[0, 1], %rest) {
    return continuous_scale(
        pairgrep { defined $b } (
            aesthetics => "alpha",
            scale_name => "alpha_c",
            palette    => rescale_pal($range),
            %rest
        )
    );
}
*scale_alpha = \&scale_alpha_continuous;


fun _scale_position_continuous ($aes) {
    return fun(:$name = undef, :$breaks = undef, :$minor_breaks = undef,
               :$labels = undef, :$limits = [],
               :$expand = undef, :$oob = \&censor, :$na_value = 'nan',
               :$trans = 'identity', :$position = _default_position($aes),
               :$sec_axis = undef,
               %rest,
      )
    {
        if ( defined $sec_axis ) {
            if ( is_formula($sec_axis) ) {
                $sec_axis = sec_axis($sec_axis);
            }
            if ( $sec_axis->$_isa('Chart::GGPlot::AxisSecondary') ) {
                die(
"Secondary axes must be specified using a Chart::GGPlot::AxisSecondary object"
                );
            }
        }

        return continuous_scale(
            pairgrep { defined $b } (
                aesthetics   => $aes,
                scale_name   => 'position_c',
                palette      => \&identity,
                name         => $name,
                breaks       => $breaks,
                minor_breaks => $minor_breaks,
                labels       => $labels,
                limits       => $limits,
                expand       => $expand,
                oob          => $oob,
                na_value     => $na_value,
                trans        => $trans,
                guide        => "none",
                position     => $position,
                ( $sec_axis ? ( secondary_axis => $sec_axis ) : () ),
                super        => 'Chart::GGPlot::Scale::ContinuousPosition',
                %rest
            )
        );
    };
}

*scale_x_continuous = _scale_position_continuous(
    [
        qw(x xmin xmax xend xintercept xmin_final xmax_final xlower xmiddle xupper)
    ]
);
*scale_y_continuous = _scale_position_continuous(
    [qw(y ymin ymax yend yintercept ymin_final ymax_final lower middle upper)]
);

for my $trans (qw(log10 reverse sqrt)) {
    for my $aes (qw(x y)) {
        my $scale_func      = "scale_${aes}_${trans}";
        my $continuous_func = "scale_${aes}_continuous";
        no strict 'refs';
        *{$scale_func} = sub { $continuous_func->( @_, trans => $trans ) }
    }
}


fun scale_size_continuous (:$name=undef, :$breaks=undef, :$labels=undef,
                          :$limits=[], :$range=[1, 6],
                          :$trans='identity', :$guide='legend') {
    return continuous_scale(
        pairgrep { defined $b } (
            aesthetics => 'size',
            scale_name => 'area',
            palette    => area_pal($range),
            name       => $name,
            breaks     => $breaks,
            labels     => $labels,
            limits     => $limits,
            trans      => $trans,
            guide      => "none",
        )
    );
}


fun _scale_discrete ($aes) {
    return fun( :$expand = undef, :$position = _default_position($aes),
                %rest ) {
        return discrete_scale(
            pairgrep { defined $b } (
                aesthetics => $aes,
                scale_name => 'position_c',
                palette    => \&identity,
                expand     => $expand,
                guide      => "none",
                position   => $position,
                range_c    => continuous_range(),
                super      => 'Chart::GGPlot::Scale::DiscretePosition',
                %rest
            )
        );
    };
}

*scale_x_discrete = _scale_discrete( [qw(x xmin xmax xend)] );
*scale_y_discrete = _scale_discrete( [qw(y ymin ymax yend)] );



fun scale_continuous_identity ( :$aesthetics, :$guide='none', %rest ) {
    return continuous_scale(
        pairgrep { defined $b } {
            aesthetics => $aesthetics,
            scale_name => 'identity',
            palette    => identity_pal(),
            guide      => $guide,
            super      => 'Chart::GGPlot::Scale::ContinuousIdentity',
            %rest,
        }
    );
}

fun scale_discrete_identity ( :$aesthetics, :$guide='none', %rest ) {
    return discrete_scale(
        pairgrep { defined $b } (
            aesthetics => $aesthetics,
            scale_name => 'identity',
            palette    => identity_pal(),
            guide      => $guide,
            super      => 'Chart::GGPlot::Scale::DiscreteIdentity',
            %rest,
        )
    );
}

for my $aes (qw(fill shape linetype color)) {
    my $scale_func = "scale_${aes}_identity";
    no strict 'refs';
    *{$scale_func} = fun(%rest) {
        scale_discrete_identity( %rest, aesthetics => $aes )
    };
}

for my $aes (qw(alpha size)) {
    my $scale_func = "scale_${aes}_identity";
    no strict 'refs';
    *{$scale_func} = fun(%rest) {
        scale_continuous_identity( %rest, aesthetics => $aes )
    };
}

#=func scale_x_date
#
#    scale_x_date(:$name = undef, :$breaks = undef,
#        :$date_breaks = undef, :$labels = undef, :$date_labels = undef, 
#        :$minor_breaks = undef, :$date_minor_breaks = undef,
#        :$limits = undef, :$expand = undef,
#        PositionEnum :$position = "bottom",
#        :$sec_axis = undef)
#
#=func scale_y_date
#
#    scale_y_date(:$name = undef, :$breaks = undef,
#        :$date_breaks = undef, :$labels = undef, :$date_labels = undef, 
#        :$minor_breaks = undef, :$date_minor_breaks = undef,
#        :$limits = undef, :$expand = undef,
#        PositionEnum :$position = "left",
#        :$sec_axis = undef)


fun datetime_scale (:$aesthetics, :$trans, :$palette,
                    :$breaks = pretty_breaks(), :$minor_breaks = undef,
                    :$labels = undef, :$date_breaks = undef,
                    :$date_labels = undef,
                    :$date_minor_breaks = undef, :$timezone = undef,
                    :$guide = 'legend',
                    %rest) {

    # TODO: handle timezone

    if ( defined $date_breaks ) {
        $breaks = date_breaks($date_breaks);
    }
    if ( defined $date_minor_breaks ) {
        $minor_breaks = date_breaks($date_minor_breaks);
    }
    if ( defined $date_labels ) {
        $labels = sub {
            my ($x) = @_;
            return $x->as_pdlsv;
        };
    }

    my $name = 'datetime';

    state $positional_aes =
      { map { $_ => 1 } qw(x xmin xmax xend y ymin ymax yend) };
    my $scale_class;
    if ( List::AllUtils::all { $positional_aes->exists($_) }
        $aesthetics->flatten )
    {
        if ($name eq 'datetime') {
            $scale_class = 'Chart::GGPlot::Scale::ContinuousDateTime';
        }
    }
    else {
        $scale_class = 'Chart::GGPlot::Scale::Continuous';
    }

    my $sc = continuous_scale(
        pairgrep { defined $b } (
            aesthetics   => $aesthetics,
            scale_name   => $name,
            palette      => $palette,
            breaks       => $breaks,
            minor_breaks => $minor_breaks,
            labels       => $labels,
            guide        => $guide,
            trans        => $trans,
            super        => $scale_class,
            %rest,
        )
    );

    #$sc->timezone($timezone);
    return $sc;
}

fun _scale_datetime ($aes) {
    return fun(:$name = undef, :$breaks = undef, :$date_breaks = undef,
               :$labels = undef, :$date_labels = undef, 
               :$minor_breaks = undef, :$date_minor_breaks = undef,
               :$timezone = undef,
               :$limits = undef, :$expand = undef,
               PositionEnum :$position = _default_position($aes),
               :$sec_axis = undef) {
        my $sc = datetime_scale(
            aesthetics        => $aes,
            trans             => 'time',
            name              => $name,
            palette           => \&identify,
            breaks            => $breaks,
            date_breaks       => $date_breaks,
            labels            => $labels,
            date_labels       => $date_labels,
            minor_breaks      => $minor_breaks,
            date_minor_breaks => $date_minor_breaks,
            timezone          => $timezone,
            guide             => 'none',
            limits            => $limits,
            expand            => $expand,
            position          => $position,
        );
        return $sc;
    };
}

*scale_x_datetime = _scale_datetime([qw(x xmin xmax xend)]);
*scale_y_datetime = _scale_datetime([qw(y ymin ymax yend)]);

fun _mid_rescaler ($mid) {
    return fun( $v, $to = [ 0, 1 ], $from = range( $v, true ) ) {
        rescale_mid( $v, $to, $from, $mid );
    };
}

# TODO: remove this
sub _na_value_color { $_[0] }

sub _default_position {
    my ($aes) = @_;
    $aes = $aes->[0] if ref($aes);
    return ($aes =~ /^x/ ? 'bottom' : 'left');
}

# register scale functions within this pacakge
fun _register_scale (Str $name, CodeRef $func) {
    $scale_funcs{$name} = $func;
}

use Package::Stash;

my $stash   = Package::Stash->new(__PACKAGE__);
my $symbols = $stash->get_all_symbols('CODE');
for my $key ( grep { /^scale_/ } keys %$symbols ) {
    _register_scale( $key, $symbols->{$key} );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Scale::Functions - Scale functions

=head1 VERSION

version 0.0011

=head1 FUNCTIONS

=head2 find_scale($aes, $x)

Find scale function by aes name and data type. The scale function is in the
form of C<scale_${aes}_${type}>, where C<$type> is decided by C<$x>.

=head2 continuous_scale

    continuous_scale (:$aesthetics, :$scale_name, :$palette, :$name=undef,
        :$breaks=undef, :$minor_breaks=undef, :$labels=undef,
        :$limits=null(), :$rescaler=\&rescale, :$oob=\&censor,
        :$expand=undef, :$na_value='nan', :$trans="identity",
        :$guide="legend", PositionEnum :$position="left",
        Str :$super='Chart::GGPlot::Scale::Continuous',
        %rest)

Continuous scale constructor.
It's internally used by the continous scales in this module.

Arguments:

=over 4

=item * $aesthetics

The name of the aesthetics that this scale works with.

=item * $scale_name

The name of the scale.

=item * $palette

A palette function that when called with a numeric piddle with values
between 0 and 1 returns the corresponding values in the range the scale maps
to.

=item * $name

The name of the scale. Used as the axis or legend title.
If C<undef>, the default, the name of the scale is taken from the first
mapping used for that aesthetic.

=item * $breaks

Major breaks.

One of:

=over 8

=item *

An empty piddle for no breaks

=item *

C<undef> for default breaks computed by the transformation object

=item *

A numeric piddle of positions

=item *

A function that given the limits and returns a piddle of breaks

=back

=item * $minor_breaks

One of:

=over 8

=item *

An empty piddle for no minor breaks

=item *

C<undef> for the default breaks (one minor break betwen each major break)

=item *

A numeric piddle of positions

=item *

A function that given the limits and return a piddle of minor breaks

=back

=item * $labels

One of:

=over 8

=item *

An empty piddle for no labels

=item *

C<undef> for the default labels computed by the transformation object

=item *

A L<PDL::SV> piddle giving labels (must be same length as C<$breaks>)

=item *

A function that given the breaks and returns labels

=back

=item * $limits

A numeric piddle of length two providing limits of the scale. Use C<BAD>
to refer to the existing minimum or maximum.

=item * $rescaler

A function used to scale the input values to the range C<[0, 1]>.
Used by diverging and n color gradients (i.e. C<scale_color_gradient2()>,
C<scale_colour_gradientn()>). 

=item * $oob 	

Function that handles limits outside of the scale limits (out of bounds).
The default replaces out of bounds values with C<BAD>.

=item * $expand

Vector of range expansion constants used to add some padding around the
data, to ensure that they are placed some distance away from the axes.
Use the convenience function C<expand_scale()> to generate the values for
the expand argument.
The defaults are to expand the scale by 5% on each side for continuous
variables, and by 0.6 units on each side for discrete variables.

=item * $na_value

Missing values will be replaced with this value.

=item * $trans

Either the name of a transformation object, or the object itself.
See L<Chart::GGPlot::Trans::Functions> for built-in transformations.
Default is C<"identity">.

=item * $guide

A function used to create a guide or its name.

=item * $position

The position of the axis. C<"left"> or C<"right"> for vertical scales,
C<"top"> or C<"bottom"> for horizontal scales.

=item * super 	

The class to use for the constructed scale.
Default is L<Chart::GGPlot::Scale::Continuous>.

=back

=head2 discrete_scale

    discrete_scale(:$aesthetics, :$scale_name, :$palette, :$name=undef,
        :$breaks=undef, :$labels=undef, :$limits=PDL::SV->new([]),
        :$expand=undef, :$na_translate=true, :$na_value=undef,
        :$drop=true, :$guide="legend", PositionEnum :$position = "left",
        Str :$super = 'Chart::GGPlot::Scale::Discrete',
        %rest)

Discrete scale constructor.
It's internally used by the discrete scales in this module.

Arguments:

=over 4

=item * $aesthetics

The name of the aesthetics that this scale works with.

=item * $scale_name

The name of the scale.

=item * $palette

A palette function that when called with a single argument (the number of
levels in the scale) returns the values that they should take.

=item * $name

The name of the scale. Used as the axis or legend title.
If C<undef>, the default, the name of the scale is taken from the first
mapping used for that aesthetic.

=item * $breaks

Major breaks.

One of:

=over 8

=item *

An empty piddle for no breaks

=item *

C<undef> for default breaks computed by the transformation object

=item *

A L<PDL::SV> piddle of positions

=item *

A function that given the limits and returns a piddle of breaks

=back

=item * $minor_breaks

One of:

=over 8

=item *

An empty piddle for no minor breaks

=item *

C<undef> for the default breaks (one minor break betwen each major break)

=item *

A L<PDL::SV> piddle of positions

=item *

A function that given the limits and return a piddle of minor breaks

=back

=item * $labels

One of:

=over 8

=item *

An empty piddle for no labels

=item *

C<undef> for the default labels computed by the transformation object

=item *

A L<PDL::SV> piddle giving labels (must be same length as C<$breaks>)

=item *

A function that given the breaks and returns labels

=back

=item * $limits

A L<PDL::SV> piddle of length two providing limits of the scale. Use C<BAD>
to refer to the existing minimum or maximum.

=item * $expand

Vector of range expansion constants used to add some padding around the
data, to ensure that they are placed some distance away from the axes.
Use the convenience function C<expand_scale()> to generate the values for
the expand argument.
The defaults are to expand the scale by 5% on each side for continuous
variables, and by 0.6 units on each side for discrete variables.

=item * $na_translate

Unlike continuous scales, discrete scales can easily show missing values,
and do so by default. If you want to remove missing values from a discrete
scale, specify C<na_translate =C<gt> 0>.

=item * $na_value

Missing values will be replaced with this value.

=item * $drop

Should unused factor levels be omitted from the scale? The default, true,
uses the levels that appear in the data; false uses all the levels in the
factor.

=item * $guide

A function used to create a guide or its name.

=item * $position

The position of the axis. C<"left"> or C<"right"> for vertical scales,
C<"top"> or C<"bottom"> for horizontal scales.

=item * super 	

The class to use for the constructed scale.
Default is L<Chart::GGPlot::Scale::Discrete>.

=back

=head2 scale_color_hue

    scale_color_hue(:$h = pdl( [ 0, 360 ] ) + 15, :$c = 100, :$l = 65,
        :$h_start = 0, :$direction = 1, :$na_value = 'grey50',
        %rest)

=head2 scale_color_discrete

This is same as the C<scale_color_hue()> function.

=head2 scale_fill_hue

    scale_fill_hue(:$h = pdl( [ 0, 360 ] ) + 15, :$c = 100, :$l = 65,
        :$h_start = 0, :$direction = 1, :$na_value = 'grey50',
        %rest)

=head2 scale_fill_discrete

This is same as the C<scale_fill_hue()> function.

=head2 scale_color_brewer

    scale_color_brewer(ColorBrewerTypeEnum :$type = "seq",
        :$palette = 0, :$direction = 1,
        %rest)

=head2 scale_fill_brewer

    scale_fill_brewer(ColorBrewerTypeEnum :$type = "seq",
        :$palette = 0, :$direction = 1,
        %rest)

=head2 scale_color_distiller

    scale_color_distiller(ColorBrewerTypeEnum :$type = "seq",
        :$palette = 1, :$direction = -1,
        :$values = [], :$na_value = "grey50", :$guide = "colorbar",
        %rest)

=head2 scale_fill_distiller

    scale_fill_distiller(ColorBrewerTypeEnum :$type = "seq",
        :$palette = 1, :$direction = -1,
        :$values = [], :$na_value = "grey50", :$guide = "colorbar",
        %rest)

=head2 scale_color_gradient

    scale_color_gradient(:$low = "#132B43", :$high = "#56B1F7",
        :$na_value = "grey50", :$guide = "colorbar",
        %rest)

=head2 scale_fill_gradient

    scale_fill_gradient(:$low = "#132B43", :$high = "#56B1F7",
        :$na_value = "grey50", :$guide = "colorbar",
        %rest)

=head2 scale_color_gradient2

    scale_color_gradient2(:$low = muted("red"), :$mid = "white",
        :$high = muted("blue"), :$midpoint = 0, :$na_value = "grey50",
        :$guide = "colorbar",
        %rest)

=head2 scale_fill_gradient2

    scale_fill_gradient2(:$low = muted("red"), :$mid = "white",
        :$high = muted("blue"), :$midpoint = 0, :$na_value = "grey50",
        :$guide = "colorbar",
        %rest)

=head2 scale_color_gradientn

    scale_color_gradientn(:$colors, :$values = [],
        :$na_value = "grey50", :$guide = "colorbar",
        %rest)

=head2 scale_fill_gradientn

    scale_fill_gradientn(:$colors, :$values = [],
        :$na_value = "grey50", :$guide = "colorbar",
        %rest)

=head2 scale_color_viridis_d

    scale_color_viridis_d(:$begin = 0, :$end = 1,
        :$direction = 1, :$option = 'viridis',
        %rest)

=head2 scale_color_ordinal

This is same as the C<scale_color_viridis_d()> function.

=head2 scale_fill_viridis_d

    scale_fill_viridis_d(:$begin = 0, :$end = 1,
        :$direction = 1, :$option = 'viridis',
        %rest)

=head2 scale_fill_ordinal

This is same as the C<scale_fill_viridis_d()> function.

=head2 scale_color_viridis_c

    scale_color_viridis_c(:$begin = 0, :$end = 1,
        :$direction = 1, :$option = 'viridis', :$values = null(),
        :$na_value = 'grey50', :$guide = 'colorbar',
        %rest)

=head2 scale_fill_viridis_c

    scale_fill_viridis_c(:$begin = 0, :$end = 1,
        :$direction = 1, :$option = 'viridis', :$values = null(),
        :$na_value = 'grey50', :$guide = 'colorbar',
        %rest)

=head2 scale_color_continuous

    scale_color_continuous(:$type="gradient, %rest")

Depending on C<$type>, 

=over 4

=item *

C<"gradient"> calls C<scale_color_gradient(%rest)>

=item *

C<"viridis"> calls C<scale_color_viridis_c(%rest)>

=back

=head2 scale_fill_continuous

    scale_fill_continuous(:$type="gradient, %rest")

Depending on C<$type>, 

=over 4

=item *

C<"gradient"> calls C<scale_fill_gradient(%rest)>

=item *

C<"viridis"> calls C<scale_fill_viridis_c(%rest)>

=back

=head2 scale_alpha_continuous

=head2 scale_alpha

This is same as the C<scale_alpha_continuous()> method.

=head2 scale_x_continuous

    scale_x_continuous(:$name = undef, :$breaks = undef,
        :$minor_breaks = undef, :$labels = undef, :$limits = [],
        :$expand = undef, :$oob = \&censor, :$na_value = 'nan',
        :$trans = 'identity', :$position = "bottom", :$sec_axis = undef,
        %rest)

=head2 scale_y_continuous

    scale_y_continuous(:$name = undef, :$breaks = undef,
        :$minor_breaks = undef, :$labels = undef, :$limits = [],
        :$expand = undef, :$oob = \&censor, :$na_value = 'nan',
        :$trans = 'identity', :$position = "left", :$sec_axis = undef,
        %rest)

=head2 scale_x_log10

    scale_x_log10(...)

=head2 scale_y_log10

    scale_y_log10(...)

=head2 scale_x_reverse

    scale_x_reverse(...)

=head2 scale_y_reverse

    scale_y_reverse(...)

=head2 scale_x_sqrt

    scale_x_sqrt(...)

=head2 scale_y_sqrt

    scale_y_sqrt(...)

=head2 scale_size_continuous

    scale_size_continuous(:$range=[1,6], %rest)

=head2 scale_size

This is same as the C<scale_size_continuous()> function.

=head2 scale_size_discrete

    scale_size_discrete(:$range=[1,6], %rest)

=head2 scale_x_discrete

    scale_x_discrete(:$expand = undef, :$position = "bottom", %rest )

=head2 scale_y_discrete

    scale_y_discrete(:$expand = undef, :$position = "left", %rest )

=head2 scale_color_identity

    scale_color_identity(:$guide="none", %rest)

=head2 scale_fill_identity

    scale_fill_identity(:$guide="none", %rest)

=head2 scale_shape_identity

    scale_shape_identity(:$guide="none", %rest)

=head2 scale_linetype_identity

    scale_linetype_identity(:$guide="none", %rest)

=head2 scale_alpha_identity

    scale_alpha_identity(:$guide="none", %rest)

=head2 scale_size_identity

    scale_size_identity(:$guide="none", %rest)

=head2 scale_continuous_identity

    scale_continuous_identity(:$aesthetics, :$guide="none", %rest)

=head2 scale_discrete_identity

    scale_discrete_identity(:$aesthetics, :$guide="none", %rest)

=head2 scale_x_datetime

    scale_y_date(:$name = undef, :$breaks = undef,
        :$date_breaks = undef, :$labels = undef, :$date_labels = undef, 
        :$minor_breaks = undef, :$date_minor_breaks = undef,
        :$limits = undef, :$expand = undef,
        PositionEnum :$position = "bottom",
        :$sec_axis = undef)

=head2 scale_y_datetime

    scale_y_date(:$name = undef, :$breaks = undef,
        :$date_breaks = undef, :$labels = undef, :$date_labels = undef, 
        :$minor_breaks = undef, :$date_minor_breaks = undef,
        :$limits = undef, :$expand = undef,
        PositionEnum :$position = "left",
        :$sec_axis = undef)

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
