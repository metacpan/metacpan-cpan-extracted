package App::financeta::indicators;
use strict;
use warnings;
use 5.10.0;
use feature 'say';

our $VERSION = '0.10';
$VERSION = eval $VERSION;

use App::financeta::mo;
use Carp;
use PDL::Lite;
use PDL::NiceSlice;
use PDL::Finance::TA;
use Data::Dumper;
use POSIX ();

$PDL::doubleformat = "%0.6lf";
has debug => 0;
has plot_engine => 'gnuplot';
has color_idx => 0;
has colors => [qw(
    red
    yellow
    pink
    green
    cyan
    violet
    magenta
    purple
    brown
    blue
    gold
    goldenrod
    dark-orange
    beige
    salmon
    dark-magenta
    dark-green
    dark-cyan
    dark-yellow
    dark-red
    antiquewhite
    dark-spring-green
    royalblue
    web-green
    web-blue
    dark-blue
    steelblue
    dark-chartreuse
    orchid
    aquamarine
    turquoise
    light-red
    light-green
    light-blue
    light-magenta
    light-cyan
    light-goldenrod
    light-pink
    light-turquoise
    spring-green
    forest-green
    sea-green
    midnight-blue
    navy
    medium-blue
    skyblue
    dark-turquoise
    dark-pink
    coral
    light-coral
    orange-red
    dark-salmon
    khaki
    dark-khaki
    dark-goldenrod
    olive
    orange
    dark-violet
    plum
    dark-plum
    dark-olivegreen
    sandybrown
    light-salmon
    lemonchiffon
    bisque
    honeydew
    slategrey
    seagreen
    chartreuse
    greenyellow
    gray
    light-gray
    light-grey
    grey
    dark-grey
    dark-gray
    slategray
    black
    )];

sub next_color {
    my $self = shift;
    my $idx = $self->color_idx; # read
    my $colors = $self->colors;
    $idx = 0 if $idx >= scalar @$colors; # reset;
    say "Using Color Index: $idx" if $self->debug;
    $self->color_idx($idx + 1); # update
    return $colors->[$idx];
}

sub _plot_gnuplot_general {
    my ($self, $xdata, $output, $scale) = @_;
    # output is the same as the return value of the code-ref above
    my @plotinfo = ();
    foreach (@$output) {
        my $p = (defined $scale) ? $_->[1] / $scale : $_->[1];
        my %legend = (legend => $_->[0]) if length $_->[0];
        my $args = $_->[2] || {};
        say "Plot args: ", Dumper($args) if $self->debug;
        push @plotinfo, {
            with => 'lines',
            axes => 'x1y1',
            linecolor => $self->next_color,
            %legend,
            %$args,
        }, $xdata, $p;
    }
    return wantarray ? @plotinfo : \@plotinfo;
}

sub _plot_gnuplot_volume {
    my ($self, $xdata, $output) = @_;
    my @plotinfo = $self->_plot_gnuplot_general($xdata, $output, 1e6);
    return { volume => \@plotinfo };
}

sub _plot_gnuplot_additional {
    my ($self, $xdata, $output) = @_;
    my @plotinfo = $self->_plot_gnuplot_general($xdata, $output);
    return { additional => \@plotinfo };
}

sub _plot_gnuplot_candlestick {
    my ($self, $xdata, $output) = @_;
    my @plotinfo = ();
    foreach (@$output) {
        my $p = $_->[1];
        my %legend = (legend => $_->[0]) if length $_->[0];
        my $args = $_->[2] || {};
        say "Plot args: ", Dumper($args) if $self->debug;
        push @plotinfo, {
            with => 'impulses',
            axes => 'x1y2',
            linecolor => $self->next_color,
            %legend,
            %$args,
        }, $xdata, $p;
    }
    return { candle => \@plotinfo };
}

sub _plot_gnuplot_compare {
    my ($self, $xdata, $output) = @_;
    if (scalar @$output >= 2) {
        # we don't want to change the output variable itself
        # otherwise the plots don't stay the same
        my $o2 = [ @$output ]; # make a copy
        my $o1 = pop @$o2;
        my @g = $self->_plot_gnuplot_general($xdata, [$o1]);
        my @a = $self->_plot_gnuplot_general($xdata, $o2);
        return { general => \@g, additional => \@a };
    } else {
        my @a = $self->_plot_gnuplot_general($xdata, $output);
        return { additional => \@a };
    }
}

has ma_name => {
    0 => 'SMA',
    1 => 'EMA',
    2 => 'WMA',
    3 => 'DEMA',
    4 => 'TEMA',
    5 => 'TRIMA',
    6 => 'KAMA',
    7 => 'MAMA',
    8 => 'T3',
};

#TODO: verify parameters that are entered by the user
has overlaps => {
    bbands => {
        name => 'Bollinger Bands',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 5],
            [ 'InNbDevUp', 'Upper Deviation multiplier', PDL::float, 2.0],
            [ 'InNbDevDn', 'Lower Deviation multiplier', PDL::float, 2.0],
            # this will show up in a combo list
            [ 'InMAType', 'Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_bbands with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my ($upper, $middle, $lower) = PDL::ta_bbands($inpdl, @args);
            return [
                ["Upper Band($period)", $upper, undef, "bbands_upper_$period"],
                ["Middle Band($period)", $middle, undef, "bbands_middle_$period"],
                ["Lower Band($period)", $lower, undef, "bbands_lower_$period"],
            ];
        },
        # use Gnuplot related stuff
        gnuplot => \&_plot_gnuplot_general,
    },
    dema => {
        name => 'Double Exponential Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 30],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_dema with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_dema($inpdl, @args);
            return [
                ["DEMA($period)", $outpdl, undef, "dema_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    ema => {
        name => 'Exponential Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 30],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_ema with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_ema($inpdl, @args);
            return [
                ["EMA($period)", $outpdl, undef, "ema_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    ht_trendline => {
        name => 'Hilbert Transform - Instantaneous Trendline',
        params => [
            # no params
        ],
        code => sub {
            my ($obj, $inpdl) = @_;
            say "Executing ta_ht_trendline" if $obj->debug;
            my $outpdl = PDL::ta_ht_trendline($inpdl);
            return [
                ['HT-trendline', $outpdl, undef, "ht_trend"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    kama => {
        name => 'Kaufman Adaptive Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 30],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_kama with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_kama($inpdl, @args);
            return [
                ["KAMA($period)", $outpdl, undef, "kama_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    ma => {
        name => 'Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 30],
            # this will show up in a combo list
            [ 'InMAType', 'Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_ma with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $type = $obj->ma_name->{$args[1]} || 'UNKNOWN';
            my $outpdl = PDL::ta_ma($inpdl, @args);
            return [
                ["MA($period)($type)", $outpdl, undef, "ma_$type\_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    mama => {
        name => 'MESA Adaptive Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InFastLimit', 'Upper Limit (0.01 - 0.99)', PDL::double, 0.5],
            [ 'InSlowLimit', 'Lower Limit (0.01 - 0.99)', PDL::double, 0.05],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_mama with parameters: ", Dumper(\@args) if $obj->debug;
            my ($omama, $ofama) = PDL::ta_mama($inpdl, @args);
            return [
                ["MAMA", $omama, undef, "mama"],
                ["FAMA", $ofama, undef, "fama"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    mavp => {
        name => 'Moving Average with Variable Period',
        input => [qw/close/],
        params => [
            # key, pretty name, type, default value
            [ 'InPeriods', 'List of periods (comma separated values)', 'PDL', ''],
            [ 'InMinPeriod', 'Minimum Period (2 - 100000)', PDL::long, 2],
            [ 'InMaxPeriod', 'Maximum Period (2 - 100000)', PDL::long, 30],
            # this will show up in a combo list
            [ 'InMAType', 'Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        code => sub {
            my ($obj, $inpdl, $period_pdl, @args) = @_;
            say "Executing ta_mavp with parameters: ", $period_pdl, "\t", Dumper(\@args) if $obj->debug;
            my $type = $obj->ma_name->{$args[2]} || 'UNKNOWN';
            if ($period_pdl->isnull) {
                carp "The list of periods cannot be null";
                return;
            }
            # the period-pdl has to be the same size as the input-pdl
            my $sz = $inpdl->dim(0); #1-D pdl
            my $np = $period_pdl;
            if ($period_pdl->dim(0) != $sz) {
                my $rep = POSIX::ceil($inpdl->dim(0) / $period_pdl->dim(0));
                $np = $period_pdl(,*$rep)->clump(0, 1);
                $np = $np->dice([0 .. $sz - 1]);
            }
            if ($np->dim(0) != $sz) {
                carp "Sizes of the PDLs are not the same: ", $np->dim(0), " vs $sz";
                return;
            }
            my $outpdl = PDL::ta_mavp($inpdl, $np, @args);
            return [
                ["MAVP($type)", $outpdl, undef, "mavp_$type"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    midpoint => {
        name => 'Mid-point over period',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_midpoint with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_midpoint($inpdl, @args);
            return [
                ["MIDPOINT($period)", $outpdl, undef, "midpt_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    midprice => {
        name => 'Mid-point Price over period',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        input => ['high', 'low'],
        code => sub {
            my ($obj, $highpdl, $lowpdl, @args) = @_;
            say "Executing ta_midprice parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_midprice($highpdl, $lowpdl, @args);
            return [
                ["MIDPRICE($period)", $outpdl, undef, "midpx_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    sar => {
        name => 'Parabolic Stop And Reverse (SAR)',
        params => [
            # key, pretty name, type, default value
            [ 'InAcceleration', 'Acceleration Factor(>= 0)', PDL::double, 0.02],
            [ 'InMaximum', 'Max. Acceleration Factor(>= 0)', PDL::double, 0.2],
        ],
        input => ['high', 'low'],
        code => sub {
            my ($obj, $highpdl, $lowpdl, @args) = @_;
            say "Executing ta_sar parameters: ", Dumper(\@args) if $obj->debug;
            my $outpdl = PDL::ta_sar($highpdl, $lowpdl, @args);
            return [
                ["SAR", $outpdl, {with => 'points pointtype 7'}, "sar"], #bug in P:G:G
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    sarext => {
        name => 'Parabolic Stop And Reverse (SAR) - Extended',
        params => [
            # key, pretty name, type, default value
            [ 'InStartValue', 'Start Value', PDL::double, 0.0],
            [ 'InOffsetOnReverse', 'Percent Offset(>= 0)', PDL::double, 0.0],
            [ 'InAccelerationInitLong', 'Acceleration Factor Initial Long(>= 0)', PDL::double, 0.02],
            [ 'InAccelerationLong', 'Acceleration Factor Long(>= 0)', PDL::double, 0.02],
            [ 'InAccelerationMaxLong', 'Acceleration Factor Max. Long(>= 0)', PDL::double, 0.2],
            [ 'InAccelerationInitShort', 'Acceleration Factor Initial Short(>= 0)', PDL::double, 0.02],
            [ 'InAccelerationShort', 'Acceleration Factor Short(>= 0)', PDL::double, 0.02],
            [ 'InAccelerationMaxShort', 'Acceleration Factor Max. Short(>= 0)', PDL::double, 0.2],
        ],
        input => ['high', 'low'],
        code => sub {
            my ($obj, $highpdl, $lowpdl, @args) = @_;
            say "Executing ta_sarext parameters: ", Dumper(\@args) if $obj->debug;
            my $outpdl = PDL::ta_sarext($highpdl, $lowpdl, @args);
            my $shortpdl = $outpdl;
            $shortpdl = $shortpdl->setbadif($shortpdl > 0)->abs;
            $outpdl = $outpdl->setbadif($outpdl < 0);
            return [
                ["SAR(long)", $outpdl, {with => 'points pointtype 7', linecolor => 'red'}, "sar_long"], # bug in P:G:G
                ["SAR(short)", $shortpdl, {with => 'points pointtype 7', linecolor => 'green'}, "sar_short"], # bug in P:G:G
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    sma => {
        name => 'Simple Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 30],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_sma with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_sma($inpdl, @args);
            return [
                ["SMA($period)", $outpdl, undef, "sma_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    t3 => {
        name => 'Triple Exponential Moving Average (T3)',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 5],
            [ 'InVFactor', 'Volume Factor(0.0 - 1.0)', PDL::double, 0.7],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_t3 with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_t3($inpdl, @args);
            return [
                ["T3-EMA($period)", $outpdl, undef, "t3ema_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    tema => {
        name => 'Triple Exponential Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 30],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_trima with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_tema($inpdl, @args);
            return [
                ["TEMA($period)", $outpdl, undef, "tema_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    trima => {
        name => 'Triangular Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 30],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_trima with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_trima($inpdl, @args);
            return [
                ["TRIMA($period)", $outpdl, undef, "trima_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    wma => {
        name => 'Weighted Moving Average',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 30],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_wma with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_wma($inpdl, @args);
            return [
                ["WMA($period)", $outpdl, undef, "wma_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    ### SKELETON
    #key => {
    #   name => 'Pretty Name',
    #   params => [
    #       ['key', 'pretty name', 'type', 'default value'],
    #       #...add more if required...
    #   ],
    #   input => [qw/high low/] # default is [/close/]
    #   code => sub {
    #       my ($indicator_obj, $input_pdl, @params) = @_;
    #       #...add code here...
    #       # output array-ref
    #       return [ ['Pretty Name', $output_pdl_1, {plot => 'params'}, "varname"],...];
    #   },
    #   gnuplot => sub {
    #       my ($indicator_obj, $x_axis_pdl, $output_array_ref) = @_;
    #       #...add plotting arguments here in an array
    #       return @plot_args;
    #   },
    #}
};

has volatility => {
    atr => {
        name => 'Average True Range',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (1 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_atr with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_atr($high, $low, $close, @args);
            return [
                ["ATR($period)", $outpdl, undef, "atr_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    natr => {
        name => 'Normalized Average True Range',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (1 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_natr with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_natr($high, $low, $close, @args);
            return [
                ["NATR($period)", $outpdl, undef, "natr_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    trange => {
        name => 'True Range',
        params => [
            # no params
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close) = @_;
            say "Executing ta_trange" if $obj->debug;
            my $outpdl = PDL::ta_trange($high, $low, $close);
            return [
                ["True Range", $outpdl, undef, "truerange"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
};

has momentum => {
    adx => {
        name => 'Average Directional Movement Index',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_adx with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_adx($high, $low, $close, @args);
            return [
                ["ADX($period)", $outpdl, undef, "adx_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    adxr => {
        name => 'Average Directional Movement Index Rating',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_adxr with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_adxr($high, $low, $close, @args);
            return [
                ["ADX RATING($period)", $outpdl, undef, "adx_rating_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    apo => {
        name => 'Absolute Price Oscillator',
        params => [
            # key, pretty name, type, default value
            [ 'InFastPeriod', 'Fast MA Period Window (2 - 100000)', PDL::long, 12],
            [ 'InSlowPeriod', 'Slow MA Period Window (2 - 100000)', PDL::long, 26],
            # this will show up in a combo list
            [ 'InMAType', 'Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_apo with parameters ", Dumper(\@args) if $obj->debug;
            my $fast = $args[0];
            my $slow = $args[1];
            my $type = $obj->ma_name->{$args[2]} || 'UNKNOWN';
            my $outpdl = PDL::ta_apo($inpdl, @args);
            return [
                ["APO($fast,$slow)($type)", $outpdl, { axes => 'x1y2' }, "apo_$fast\_$slow\_$type"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    aroon => {
        name => 'Aroon',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low/],
        code => sub {
            my ($obj, $high, $low, @args) = @_;
            say "Executing ta_aroon with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my ($adown, $aup) = PDL::ta_aroon($high, $low, @args);
            return [
                ["AROON($period) DOWN", $adown, undef, "aroon_down_$period"],
                ["AROON($period) UP", $aup, undef, "aroon_up_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    aroonosc => {
        name => 'Aroon Oscillator',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low/],
        code => sub {
            my ($obj, $high, $low, @args) = @_;
            say "Executing ta_aroonosc with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_aroonosc($high, $low, @args);
            return [
                ["AROON OSC($period)", $outpdl, undef, "aroon_osc_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    bop => {
        name => 'Balance Of Power',
        params => [
            # no params
        ],
        input => [qw/open high low close/],
        code => sub {
            my ($obj, $open, $high, $low, $close) = @_;
            say "Executing ta_bop" if $obj->debug;
            my $outpdl = PDL::ta_bop($open, $high, $low, $close);
            return [
                ["Balance of Power", $outpdl, undef, "balpow"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    cci => {
        name => 'Commodity Channel Index',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_cci with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_cci($high, $low, $close, @args);
            return [
                ["CCI($period)", $outpdl, undef, "cci_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    cmo => {
        name => 'Chande Momentum Oscillator',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_cmo with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_cmo($inpdl, @args);
            return [
                ["CMO($period)", $outpdl, undef, "cmo_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    dx => {
        name => 'Directional Movement Index',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_dx with parameters: ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_dx($high, $low, $close, @args);
            return [
                ["DX($period)", $outpdl, undef, "dx_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    macd => {
        name => 'Moving Average Convergence/Divergence',
        params => [
            # key, pretty name, type, default value
            [ 'InFastPeriod', 'Fast MA Period Window (2 - 100000)', PDL::long, 12],
            [ 'InSlowPeriod', 'Slow MA Period Window (2 - 100000)', PDL::long, 26],
            [ 'InSignalPeriod', 'Signal Line Smoothing (1 - 100000)', PDL::long, 9],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_macd with parameters ", Dumper(\@args) if $obj->debug;
            my $fast = $args[0];
            my $slow = $args[1];
            my $signal = $args[2];
            my ($omacd, $omacdsig, $omacdhist) = PDL::ta_macd($inpdl, @args);
            return [
                ["MACD($fast/$slow/$signal)", $omacd, undef, "macd_$fast\_$slow\_$signal"],
                ["MACD Signal($fast/$slow/$signal)", $omacdsig, undef, "macdsig_$fast\_$slow\_$signal"],
                ["MACD Histogram($fast/$slow/$signal)", $omacdhist, { with => 'impulses' }, "macdhist_$fast\_$slow\_$signal"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    macdext => {
        name => 'MACD with different Mov. Avg',
        params => [
            # key, pretty name, type, default value
            [ 'InFastPeriod', 'Fast MA Period Window (2 - 100000)', PDL::long, 12],
            # this will show up in a combo list
            [ 'InFastMAType', 'Fast Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
            [ 'InSlowPeriod', 'Slow MA Period Window (2 - 100000)', PDL::long, 26],
            # this will show up in a combo list
            [ 'InSlowMAType', 'Slow Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
            [ 'InSignalPeriod', 'Signal Line Smoothing (1 - 100000)', PDL::long, 9],
            # this will show up in a combo list
            [ 'InSignalMAType', 'Signal Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_macdext with parameters ", Dumper(\@args) if $obj->debug;
            my $fast = $args[0];
            my $slow = $args[2];
            my $signal = $args[4];
            my ($omacd, $omacdsig, $omacdhist) = PDL::ta_macdext($inpdl, @args);
            return [
                ["MACDEXT($fast/$slow/$signal)", $omacd, undef, "macdext_$fast\_$slow\_$signal"],
                ["MACDEXT Signal($fast/$slow/$signal)", $omacdsig, undef, "macdextsig_$fast\_$slow\_$signal"],
                ["MACDEXT Histogram($fast/$slow/$signal)", $omacdhist, { with => 'impulses' }, "macdexthist_$fast\_$slow\_$signal"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    macdfix => {
        name => 'MACD Fixed to 12/26',
        params => [
            # key, pretty name, type, default value
            [ 'InSignalPeriod', 'Signal Line Smoothing (1 - 100000)', PDL::long, 9],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_macdfix with parameters ", Dumper(\@args) if $obj->debug;
            my $signal = $args[0];
            my ($omacd, $omacdsig, $omacdhist) = PDL::ta_macdfix($inpdl, @args);
            return [
                ["MACD(12/26/$signal)", $omacd, undef, "macd_12_26_$signal"],
                ["MACD Signal(12/26/$signal)", $omacdsig, undef, "macdsig_12_26_$signal"],
                ["MACD Histogram(12/26/$signal)", $omacdhist, { with => 'impulses' }, undef, "macdhist_12_26_$signal"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    mfi => {
        name => 'Money Flow Index',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(2 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close volume/],
        code => sub {
            my ($obj, $high, $low, $close, $volume, @args) = @_;
            say "Executing ta_mfi with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_mfi($high, $low, $close, $volume, @args);
            return [
                ["MFI($period)", $outpdl, undef, "mfi_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    minus_di => {
        name => 'Minus Directional Indicator',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_minus_di with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_minus_di($high, $low, $close, @args);
            return [
                ["MINUS-DI($period)", $outpdl, undef, "minusdi_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    minus_dm => {
        name => 'Minus Directional Movement',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low/],
        code => sub {
            my ($obj, $high, $low, @args) = @_;
            say "Executing ta_minus_dm with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_minus_dm($high, $low, @args);
            return [
                ["MINUS-DM($period)", $outpdl, undef, "minusdm_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    mom => {
        name => 'Momentum',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 10],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_mom with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_mom($inpdl, @args);
            return [
                ["MOM($period)", $outpdl, undef, "mom_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    plus_di => {
        name => 'Plus Directional Indicator',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_plus_di with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_plus_di($high, $low, $close, @args);
            return [
                ["PLUS-DI($period)", $outpdl, undef, "plusdi_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    plus_dm => {
        name => 'Plus Directional Indicator',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low/],
        code => sub {
            my ($obj, $high, $low, @args) = @_;
            say "Executing ta_plus_dm with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_plus_dm($high, $low, @args);
            return [
                ["PLUS-DM($period)", $outpdl, undef, "plusdm_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    ppo => {
        name => 'Percentage Price Oscillator',
        params => [
            # key, pretty name, type, default value
            [ 'InFastPeriod', 'Fast MA Period Window (2 - 100000)', PDL::long, 12],
            [ 'InSlowPeriod', 'Slow MA Period Window (2 - 100000)', PDL::long, 26],
            # this will show up in a combo list
            [ 'InMAType', 'Fast Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_ppo with parameters ", Dumper(\@args) if $obj->debug;
            my $fast = $args[0];
            my $slow = $args[1];
            my $type = $obj->ma_name->{$args[2]} || 'UNKNOWN';
            my $outpdl = PDL::ta_ppo($inpdl, @args);
            return [
                ["PPO($fast/$slow)($type)", $outpdl, undef, "ppo_$fast\_$slow\_$type"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    roc => {
        name => 'Rate of Change',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 10],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_roc with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_roc($inpdl, @args);
            return [
                ["ROC($period)", $outpdl, undef, "roc_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    rocp => {
        name => 'Rate of Change Precentage',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 10],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_rocp with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_rocp($inpdl, @args);
            return [
                ["ROCP($period)", $outpdl, undef, "rocp_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    rocr => {
        name => 'Rate of Change Ratio',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 10],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_rocr with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_rocr($inpdl, @args);
            return [
                ["ROCR($period)", $outpdl, undef, "rocr_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    rocr100 => {
        name => 'Rate of Change Ratio - scale 100',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(1 - 100000)', PDL::long, 10],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_rocr100 with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_rocr100($inpdl, @args);
            return [
                ["ROCR*100($period)", $outpdl, undef, "rocr100_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    rsi => {
        name => 'Relative Strength Index',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window(2 - 100000)', PDL::long, 14],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_rsi with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_rsi($inpdl, @args);
            return [
                ["RSI($period)", $outpdl, undef, "rsi_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    stoch => {
        name => 'Stochastic',
        params => [
            # key, pretty name, type, default value
            [ 'InFastK_Period', 'Fast-K Line Period Window (1 - 100000)', PDL::long, 5],
            [ 'InSlowK_Period', 'Slow-K Line Period Window (1 - 100000)', PDL::long, 3],
            # this will show up in a combo list
            [ 'InSlowK_MAType', 'Slow-K Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
            [ 'InSlowD_Period', 'Slow-D Line Period Window (1 - 100000)', PDL::long, 3],
            # this will show up in a combo list
            [ 'InSlowD_MAType', 'Slow-D Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_stoch with parameters ", Dumper(\@args) if $obj->debug;
            my $slowK = $args[1];
            my $slowD = $args[3];
            my ($oslowK, $oslowD) = PDL::ta_stoch($high, $low, $close, @args);
            return [
                ["Slow-K($slowK)", $oslowK, undef, "slowK_$slowK"],
                ["Slow-D($slowD)", $oslowD, undef, "slowD_$slowD"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    stochf => {
        name => 'Stochastic Fast',
        params => [
            # key, pretty name, type, default value
            [ 'InFastK_Period', 'Fast-K Line Period Window (1 - 100000)', PDL::long, 5],
            [ 'InFastD_Period', 'Fast-D Line Period Window (1 - 100000)', PDL::long, 3],
            # this will show up in a combo list
            [ 'InFastD_MAType', 'Fast-D Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_stochf with parameters ", Dumper(\@args) if $obj->debug;
            my $fastK = $args[0];
            my $fastD = $args[1];
            my ($ofastK, $ofastD) = PDL::ta_stochf($high, $low, $close, @args);
            return [
                ["Fast-K($fastK)", $ofastK, undef, "fastK_$fastK"],
                ["Fast-D($fastD)", $ofastD, undef, "fastD_$fastD"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    stochrsi => {
        name => 'Stochastic Relative Strength Index',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
            [ 'InFastK_Period', 'Fast-K Line Period Window (1 - 100000)', PDL::long, 5],
            [ 'InFastD_Period', 'Fast-D Line Period Window (1 - 100000)', PDL::long, 3],
            # this will show up in a combo list
            [ 'InFastD_MAType', 'Fast-D Moving Average Type', 'ARRAY',
                [
                    'Simple', #SMA
                    'Exponential', #EMA
                    'Weighted', #WMA
                    'Double Exponential', #DEMA
                    'Triple Exponential', #TEMA
                    'Triangular', #TRIMA
                    'Kaufman Adaptive', #KAMA
                    'MESA Adaptive', #MAMA
                    'Triple Exponential (T3)', #T3
                ],
            ],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_stochrsi with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $fastK = $args[1];
            my $fastD = $args[2];
            my ($ofastK, $ofastD) = PDL::ta_stochrsi($high, $low, $close, @args);
            return [
                ["Fast-K($fastK, $period)", $ofastK, undef, "fastK_$fastK\_$period"],
                ["Fast-D($fastD, $period)", $ofastD, undef, "fastD_$fastD\_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    trix => {
        name => '1-day ROC of Triple Smooth EMA',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (1 - 100000)', PDL::long, 30],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_trix with parameters", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_trix($inpdl, @args);
            return [
                ["TRIX($period)", $outpdl, undef, "trix_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    ultosc => {
        name => 'Ultimate Oscillator',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod1', 'Period Window (1 - 100000)', PDL::long, 7],
            [ 'InTimePeriod2', 'Period Window (1 - 100000)', PDL::long, 14],
            [ 'InTimePeriod3', 'Period Window (1 - 100000)', PDL::long, 28],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_ultosc with parameters ", Dumper(\@args) if $obj->debug;
            my $p1 = $args[0];
            my $p2 = $args[1];
            my $p3 = $args[2];
            my $outpdl = PDL::ta_ultosc($high, $low, $close, @args);
            return [
                ["ULT.OSC.($p1/$p2/$p3)", $outpdl, undef, "ultosc_$p1\_$p2\_$p3"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    willr => {
        name => q/Williams' %R/,
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close, @args) = @_;
            say "Executing ta_willr with parameters ", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_willr($high, $low, $close, @args);
            return [
                ["WILLR($period)", $outpdl, undef, "willr_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
};

has cycle => {
    ht_dcperiod => {
        name => 'Hilbert Transform - Dominant Cycle Period',
        params => [
            #no params,
        ],
        code => sub {
            my ($obj, $inpdl) = @_;
            say "Executing ta_ht_dcperiod" if $obj->debug;
            my $outpdl = PDL::ta_ht_dcperiod($inpdl);
            return [
                ['HT-DCperiod', $outpdl, { axes => 'x1y2' }, "ht_dcperiod"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    ht_dcphase => {
        name => 'Hilbert Transform - Dominant Cycle Phase',
        params => [
            #no params,
        ],
        code => sub {
            my ($obj, $inpdl) = @_;
            say "Executing ta_ht_dcphase" if $obj->debug;
            my $outpdl = PDL::ta_ht_dcphase($inpdl);
            return [
                ['HT-DCphase', $outpdl, undef, "ht_dcphase"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    ht_phasor => {
        name => 'Hilbert Transform - Phasor Components',
        params => [
            #no params,
        ],
        code => sub {
            my ($obj, $inpdl) = @_;
            say "Executing ta_ht_phasor" if $obj->debug;
            my ($oinphase, $oquad) = PDL::ta_ht_phasor($inpdl);
            return [
                ['HT-InPhase', $oinphase, undef, "ht_inphase"],
                ['HT-Quadrature', $oquad, undef, "ht_quad"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    ht_sine => {
        name => 'Hilbert Transform - Sine Wave',
        params => [
            #no params,
        ],
        code => sub {
            my ($obj, $inpdl) = @_;
            say "Executing ta_ht_sine" if $obj->debug;
            my ($osine, $oleadsine) = PDL::ta_ht_sine($inpdl);
            return [
                ['HT-Sine', $osine, { axes => 'x1y2' }, "ht_sine"],
                ['HT-LeadSine', $oleadsine, { axes => 'x1y2' }, "ht_leadsine"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    ht_trendmode => {
        name => 'Hilbert Transform - Trend vs Cycle Mode',
        params => [
            #no params,
        ],
        code => sub {
            my ($obj, $inpdl) = @_;
            say "Executing ta_ht_trendmode" if $obj->debug;
            my $outpdl = PDL::ta_ht_trendmode($inpdl);
            return [
                ['HT-Trend vs Cycle', $outpdl, { with => 'impulses', axes => 'x1y2' }, "ht_trendcycle"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
};

has volume => {
    ad => {
        name => 'Chaikin Accumulation/Distribution line',
        params => [
            # no params
        ],
        input => [qw/high low close volume/],
        code => sub {
            my ($obj, $high, $low, $close, $volume) = @_;
            say "Executing ta_ad" if $obj->debug;
            my $outpdl = PDL::ta_ad($high, $low, $close, $volume);
            return [
                ["Chaikin A/D", $outpdl, undef, "chaikin"],
            ];
        },
        gnuplot => \&_plot_gnuplot_volume,
    },
    adosc => {
        name => 'Chaikin Accumulation/Distribution Oscillator',
        params => [
            # key, pretty name, type, default value
            [ 'InFastPeriod', 'Fast MA Period Window (2 - 100000)', PDL::long, 3],
            [ 'InSlowPeriod', 'Slow MA Period Window (2 - 100000)', PDL::long, 10],
        ],
        input => [qw/high low close volume/],
        code => sub {
            my ($obj, $high, $low, $close, $volume, @args) = @_;
            say "Executing ta_adosc with parameters ", Dumper(\@args) if $obj->debug;
            my $fast = $args[0];
            my $slow = $args[1];
            my $outpdl = PDL::ta_adosc($high, $low, $close, $volume, @args);
            return [
                ["Chaikin A/D($fast,$slow)", $outpdl, undef, "chaikin_$fast\_$slow"],
            ];
        },
        gnuplot => \&_plot_gnuplot_volume,
    },
    obv => {
        name => 'On Balance Volume',
        params => [
            # no params
        ],
        input => [qw/close volume/],
        code => sub {
            my ($obj, $close, $volume) = @_;
            say "Executing ta_obv" if $obj->debug;
            my $outpdl = PDL::ta_obv($close, $volume);
            return [
                ["OBV", $outpdl, undef, "obv"],
            ];
        },
        gnuplot => \&_plot_gnuplot_volume,
    },
};

sub _execute_candlestick {
    my ($obj, $fn, $fname, $tag, $o, $h, $l, $c, @args) = @_;
    return unless ref $fn eq 'CODE';
    if (@args) {
        say "Executing $fname with parameters ", Dumper(\@args) if $obj->debug;
    } else {
        say "Executing $fname" if $obj->debug;
    }
    my $outpdl = &$fn($o, $h, $l, $c, @args);
    my $varname = $fname;
    $varname =~ s/^ta_//g;
    return [
        [$tag, $outpdl, undef, $varname],
    ];
}

has candlestick => {
    cdl2crows => {
        name => 'Two Crows',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdl2crows, 'ta_cdl2crows', '2CROWS', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdl3blackcrows => {
        name => 'Three Black Crows',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdl3blackcrows, 'ta_cdl3blackcrows', '3BLACKCROWS', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdl3inside => {
        name => 'Three Inside Up/Down',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdl3inside, 'ta_cdl3inside', '3INSIDE', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdl3linestrike => {
        name => 'Three Line Strike',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdl3linestrike, 'ta_cdl3linestrike', '3LINESTRIKE', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdl3outside => {
        name => 'Three Outside Up/Down',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdl3outside, 'ta_cdl3outside', '3OUTSIDE', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdl3starsinsouth => {
        name => 'Three Stars In The South',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdl3starsinsouth, 'ta_cdl3starsinsouth', '3STARSSOUTH', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdl3whitesoldiers => {
        name => 'Three Advancing White Soldiers',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdl3whitesoldiers, 'ta_cdl3whitesoldiers', '3WHITESOLDIER', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlabandonedbaby => {
        name => 'Abandoned Baby',
        input => [qw(open high low close)],
        params => [
            # key, pretty name, type, default value
            [ 'InPenetration', 'Percentage of penetration of candles (>=0)', PDL::double, 0.3],
        ],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlabandonedbaby, 'ta_cdlabandonedbaby', 'ABANDONBABY', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdladvanceblock => {
        name => 'Advance Block',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdladvanceblock, 'ta_cdladvanceblock', 'ADVANCEBLK', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlbelthold => {
        name => 'Belt Hold',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlbelthold, 'ta_cdlbelthold', 'BELTHOLD', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlbreakaway => {
        name => 'Break Away',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlbreakaway, 'ta_cdlbreakaway', 'BREAKAWAY', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlclosingmarubozu => {
        name => 'Closing Marubozu',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlclosingmarubozu, 'ta_cdlclosingmarubozu', 'CLOSEMARUBOZU', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlconcealbabyswall => {
        name => 'Concealing Baby Swallow',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlconcealbabyswall, 'ta_cdlconcealbabyswall', 'BABYSWALLOW', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlcounterattack => {
        name => 'Counter Attack',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlcounterattack, 'ta_cdlcounterattack', 'CTRATTACK', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdldarkcloudcover => {
        name => 'Dark Cloud Cover',
        input => [qw(open high low close)],
        params => [
            # key, pretty name, type, default value
            [ 'InPenetration', 'Percentage of penetration of candles (>=0)', PDL::double, 0.5],
        ],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdldarkcloudcover, 'ta_cdldarkcloudcover', 'DARKCLOUD', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdldoji => {
        name => 'Doji',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdldoji, 'ta_cdldoji', 'DOJI', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdldojistar => {
        name => 'Doji Star',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdldojistar, 'ta_cdldojistar', 'DOJISTAR', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdldragonflydoji => {
        name => 'Dragonfly Doji',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdldragonflydoji, 'ta_cdldragonflydoji', 'DRGNFLYDOJI', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlengulfing => {
        name => 'Engulfing Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlengulfing, 'ta_cdlengulfing', 'ENGULFING', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdleveningdojistar => {
        name => 'Evening Doji Star',
        input => [qw(open high low close)],
        params => [
            # key, pretty name, type, default value
            [ 'InPenetration', 'Percentage of penetration of candles (>=0)', PDL::double, 0.3],
        ],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdleveningdojistar, 'ta_cdleveningdojistar', 'EVEDOJISTAR', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdleveningstar => {
        name => 'Evening Star',
        input => [qw(open high low close)],
        params => [
            # key, pretty name, type, default value
            [ 'InPenetration', 'Percentage of penetration of candles (>=0)', PDL::double, 0.3],
        ],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdleveningstar, 'ta_cdleveningstar', 'EVESTAR', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlgapsidesidewhite => {
        name => 'Up/Down Gap Side-by-Side White Lines',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlgapsidesidewhite, 'ta_cdlgapsidesidewhite', 'GAPSxSWHITE', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlgravestonedoji => {
        name => 'Gravestone Doji',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlgravestonedoji, 'ta_cdlgravestonedoji', 'GRVSTNDOJI', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlhammer => {
        name => 'Hammer',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlhammer, 'ta_cdlhammer', 'HAMMER', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlhangingman => {
        name => 'Hanging Man',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlhangingman, 'ta_cdlhangingman', 'HANGMAN', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlharami => {
        name => 'Harami Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlharami, 'ta_cdlharami', 'HARAMI', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlharamicross => {
        name => 'Harami Cross Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlharamicross, 'ta_cdlharamicross', 'HARAMI-X',@_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlhighwave => {
        name => 'High-Wave Candle',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlhighwave, 'ta_cdlhighwave', 'HIGHWAVE', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlhikkake => {
        name => 'Hikkake Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlhikkake, 'ta_cdlhikkake', 'HIKKAKE', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlhikkakemod => {
        name => 'Modified Hikkake Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlhikkakemod, 'ta_cdlhikkakemod', 'HIKKAKEMOD', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlhomingpigeon => {
        name => 'Homing Pigeon',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlhomingpigeon, 'ta_cdlhomingpigeon', 'HOMINGPIGEON', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlidentical3crows => {
        name => 'Identical Three Crows',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlidential3crows, 'ta_cdlidential3crows', 'ID3CROWS', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlinneck => {
        name => 'In-Neck Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlinneck, 'ta_cdlinneck', 'IN-NECK', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlinvertedhammer => {
        name => 'Inverted Hammer',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlinvertedhammer, 'ta_cdlinvertedhammer', 'INVHAMMER', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlkicking => {
        name => 'Kicking',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlkicking, 'ta_cdlkicking', 'KICKING', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlkickingbylength => {
        name => 'Kicking - Marubozu Length based',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlkickingbylength, 'ta_cdlkickingbylength', 'KICKLEN', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlladderbottom => {
        name => 'Ladder Bottom',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlladderbottom, 'ta_cdlladderbottom', 'LADDERBTM', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdllongleggeddoji => {
        name => 'Long Legged Doji',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdllongleggeddoji, 'ta_cdllongleggeddoji', 'LONGDOJI', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdllongline => {
        name => 'Long Line Candle',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdllongline, 'ta_cdllongline', 'LONGLINE', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlmarubozu => {
        name => 'Marubozu',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlmarubozu, 'ta_cdlmarubozu', 'MARUBOZU', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlmatchinglow => {
        name => 'Matching Low',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlmatchinglow, 'ta_cdlmatchinglow', 'MATCHLOW', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlmathold => {
        name => 'Mat Hold',
        input => [qw(open high low close)],
        params => [
            # key, pretty name, type, default value
            [ 'InPenetration', 'Percentage of penetration of candles (>=0)', PDL::double, 0.5],
        ],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlmathold, 'ta_cdlmathold', 'MATHOLD', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlmorningdojistar => {
        name => 'Morning Doji Star',
        input => [qw(open high low close)],
        params => [
            # key, pretty name, type, default value
            [ 'InPenetration', 'Percentage of penetration of candles (>=0)', PDL::double, 0.3],
        ],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlmorningdojistar, 'ta_cdlmorningdojistar', 'MORNDOJISTAR', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlmorningstar => {
        name => 'Morning Star',
        input => [qw(open high low close)],
        params => [
            # key, pretty name, type, default value
            [ 'InPenetration', 'Percentage of penetration of candles (>=0)', PDL::double, 0.3],
        ],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlmorningstar, 'ta_cdlmorningstar', 'MORNINGSTAR', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlonneck => {
        name => 'On-Neck Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlonneck, 'ta_cdlonneck', 'ON-NECK', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlpiercing => {
        name => 'Piercing Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlpiercing, 'ta_cdlpiercing', 'PIERCING', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlrickshawman => {
        name => 'Rickshaw Man',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlrickshawman, 'ta_cdlrickshawman', 'RICKSHAW', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlrisefall3methods => {
        name => 'Rising/Falling Three Methods',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlrisefall3methods, 'ta_cdlrisefall3methods', 'RISEFALL3M', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlseparatinglines => {
        name => 'Separating Lines',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlseparatinglines, 'ta_cdlseparatinglines', 'SEPARATELINES', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlshootingstar => {
        name => 'Shooting Star',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlshootingstar, 'ta_cdlshootingstar', 'SHOOTINGSTAR', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlshortline => {
        name => 'Short Line Candle',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlshortline, 'ta_cdlshortline', 'SHORTLINE', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlspinningtop => {
        name => 'Spinning Top',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlspinningtop, 'ta_cdlspinningtop', 'SPINTOP', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlstalledpattern => {
        name => 'Stalled Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlstalledpattern, 'ta_cdlstalledpattern', 'STALLED', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlsticksandwich => {
        name => 'Stick Sandwich',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlsticksandwich, 'ta_cdlsticksandwich', 'SANDWICH', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdltakuri => {
        name => 'Takuri',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdltakuri, 'ta_cdltakuri', 'TAKURI', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdltasukigap => {
        name => 'Tasuki Gap',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdltasukigap, 'ta_cdltasukigap', 'TASUKI', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlthrusting => {
        name => 'Thrusting Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlthrusting, 'ta_cdlthrusting', 'THRUSTING', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdltristar => {
        name => 'Tristar Pattern',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdltristar, 'ta_cdltristar', 'TRISTAR', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlunique3river => {
        name => 'Unique Three River',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlunique3river, 'ta_cdlunique3river', 'U3RIVER', @_); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlupsidegap2crows => {
        name => 'Upside Gap Two Crows',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlupsidegap2crows, 'ta_cdlupsidegap2crows', 'UPSIDEGAP2CROWS'); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
    cdlxsidegap3methods => {
        name => 'Upside/Downside Gap Three Methods',
        params => [],
        input => [qw(open high low close)],
        code => sub { return shift->_execute_candlestick(\&PDL::ta_cdlxsidegap3methods, 'ta_cdlxsidegap3methods', 'XSIDEGAP3M'); },
        gnuplot => \&_plot_gnuplot_candlestick,
    },
};

has statistic => {
    beta => {
        name => 'Beta',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (1 - 100000)', PDL::long, 5],
            # this is a special key and if you change this will break
            # functionality in the gui.pm file.
            [ 'CompareWith', 'Compare With Security', PDL::byte, '' ],
        ],
        input => [qw/close/],
        code => sub {
            my ($obj, $inpdl1, $inpdl2, $period, $name) = @_;
            say "Executing ta_beta with parameters: $period and $name" if $obj->debug;
            if ($inpdl1->dim(0) != $inpdl2->dim(0)) {
                carp "Cannot compare unless the sizes of the PDLs are same";
                return;
            }
            my $outpdl = PDL::ta_beta($inpdl1, $inpdl2, $period);
            return [
                ["BETA($period)", $outpdl, undef, "beta_$period"],
                [$name, $inpdl2, { axes => 'x1y2' }, "$name\_close"],
            ];
        },
        gnuplot => \&_plot_gnuplot_compare,
    },
    correl => {
        name => q/Pearson's Correlation Coefficient/,
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (1 - 100000)', PDL::long, 5],
            # this is a special key and if you change this will break
            # functionality in the gui.pm file.
            [ 'CompareWith', 'Compare With Security', PDL::byte, '' ],
        ],
        input => [qw/close/],
        code => sub {
            my ($obj, $inpdl1, $inpdl2, $period, $name) = @_;
            say "Executing ta_beta with parameters: $period and $name" if $obj->debug;
            if ($inpdl1->dim(0) != $inpdl2->dim(0)) {
                carp "Cannot compare unless the sizes of the PDLs are same";
                return;
            }
            my $outpdl = PDL::ta_correl($inpdl1, $inpdl2, $period);
            return [
                ["CORRELATION($period)", $outpdl, undef, "correl_$period"],
                [$name, $inpdl2, { axes => 'x1y2' }, "$name\_close"],
            ];
        },
        gnuplot => \&_plot_gnuplot_compare,
    },
    linearreg => {
        name => 'Linear Regression',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_linearreg with parameters", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_linearreg($inpdl, @args);
            return [
                ["REGRESSION($period)", $outpdl, undef, "linreg_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    linearreg_angle => {
        name => 'Linear Regression Angle',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_linearreg_angle with parameters", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_linearreg_angle($inpdl, @args);
            return [
                ["REGRESSION ANGLE($period)", $outpdl, { axes => 'x1y2' }, "linregangle_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    linearreg_intercept => {
        name => 'Linear Regression Intercept',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_linearreg_intercept with parameters", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_linearreg_intercept($inpdl, @args);
            return [
                ["REGRESSION INTERCEPT($period)", $outpdl, undef, "linregint_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    linearreg_slope => {
        name => 'Linear Regression Slope',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_linearreg_slope with parameters", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_linearreg_slope($inpdl, @args);
            return [
                ["REGRESSION SLOPE($period)", $outpdl, { axes => 'x1y2' }, "linregslope_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    stddev => {
        name => 'Standard Deviation',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 5],
            [ 'InNbDev', 'No. of Deviations', PDL::double, 1.0],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_stddev with parameters", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $num = $args[1];
            my $outpdl = PDL::ta_stddev($inpdl, @args);
            return [
                ["$num x STD.DEV.($period)", $outpdl, undef, "stddev_$num\_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
    tsf => {
        name => 'Timeseries Forecast',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 14],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_tsf with parameters", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $outpdl = PDL::ta_tsf($inpdl, @args);
            return [
                ["FORECAST($period)", $outpdl, undef, "forecast_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    var => {
        name => 'Variance',
        params => [
            # key, pretty name, type, default value
            [ 'InTimePeriod', 'Period Window (2 - 100000)', PDL::long, 5],
            [ 'InNbDev', 'No. of Deviations', PDL::double, 1.0],
        ],
        code => sub {
            my ($obj, $inpdl, @args) = @_;
            say "Executing ta_var with parameters", Dumper(\@args) if $obj->debug;
            my $period = $args[0];
            my $num = $args[1];
            my $outpdl = PDL::ta_var($inpdl, @args);
            return [
                ["$num x VARIANCE($period)", $outpdl, undef, "var_$num\_$period"],
            ];
        },
        gnuplot => \&_plot_gnuplot_additional,
    },
};

has price => {
    avgprice => {
        name => 'Average Price',
        params => [
            # no params
        ],
        input => [qw/open high low close/],
        code => sub {
            my ($obj, $open, $high, $low, $close) = @_;
            say "Executing ta_avgprice" if $obj->debug;
            my $outpdl = PDL::ta_avgprice($open, $high, $low, $close);
            return [
                ["Avg. Price", $outpdl, undef, "avgpx"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    medprice => {
        name => 'Median Price',
        params => [
            # no params
        ],
        input => [qw/high low/],
        code => sub {
            my ($obj, $high, $low) = @_;
            say "Executing ta_medprice" if $obj->debug;
            my $outpdl = PDL::ta_medprice($high, $low);
            return [
                ["Median Price", $outpdl, undef, "medianpx"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    typprice => {
        name => 'Typical Price',
        params => [
            # no params
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close) = @_;
            say "Executing ta_typprice" if $obj->debug;
            my $outpdl = PDL::ta_typprice($high, $low, $close);
            return [
                ["Typical Price", $outpdl, undef, "typpx"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
    wclprice => {
        name => 'Weighted Close Price',
        params => [
            # no params
        ],
        input => [qw/high low close/],
        code => sub {
            my ($obj, $high, $low, $close) = @_;
            say "Executing ta_wclprice" if $obj->debug;
            my $outpdl = PDL::ta_wclprice($high, $low, $close);
            return [
                ["Wt. Close Price", $outpdl, undef, "wclpx"],
            ];
        },
        gnuplot => \&_plot_gnuplot_general,
    },
};

has group_name => {
    overlaps => 'Overlap Studies',
    volatility => 'Volatility Indicators',
    momentum => 'Momentum Indicators',
    cycle => 'Cycle Indicators',
    volume => 'Volume Indicators',
    candlestick => 'Candlestick Patterns',
    statistic => 'Statistic Functions',
    price => 'Price Transform',
};

has group_key => {
    'Overlap Studies' => 'overlaps',
    'Volatility Indicators' => 'volatility',
    'Momentum Indicators' => 'momentum',
    'Cycle Indicators' => 'cycle',
    'Volume Indicators' => 'volume',
    'Candlestick Patterns' => 'candlestick',
    'Statistic Functions' => 'statistic',
    'Price Transform' => 'price',
};

sub get_groups {
    my $self = shift;
    ## NEEDS TO BE IN THIS ORDER
    my @groups = (
        'Overlap Studies',
        'Volatility Indicators',
        'Momentum Indicators',
        'Cycle Indicators',
        'Volume Indicators',
        'Candlestick Patterns',
        'Statistic Functions',
        'Price Transform',
    );
    return wantarray ? @groups : \@groups;
}

sub get_funcs($) {
    my ($self, $grp) = @_;
    $grp = $self->group_key->{$grp} if defined $grp;
    if (defined $grp and $self->has($grp)) {
        my $r = $self->$grp;
        my @funcs = ();
        foreach my $k (sort(keys %$r)) {
            push @funcs, $r->{$k}->{name};
        }
        say "Found funcs: ", Dumper(\@funcs) if $self->debug;
        return wantarray ? @funcs : \@funcs;
    }
}

sub get_params($$) {
    my ($self, $fn_name, $grp) = @_;
    $grp = $self->group_key->{$grp} if defined $grp;
    my $fn;
    # find the function parameters
    if (defined $grp and $self->has($grp)) {
        my $r = $self->$grp;
        foreach my $k (sort (keys %$r)) {
            $fn = $k if $r->{$k}->{name} eq $fn_name;
            last if defined $fn;
        }
        my $params = $r->{$fn}->{params} if defined $fn;
        say "Found params: ", Dumper($params) if $self->debug;
        return $params;
    }
}

sub _find_func_key($$) {
    my ($self, $iref) = @_;
    return unless ref $iref eq 'HASH';
    my $params = $iref->{params};
    my $fn_name = $iref->{func};
    my $fn_key;
    my $grp = $self->group_key->{$iref->{group}} if defined $iref->{group};
    if (defined $grp and $self->has($grp) and $fn_name) {
        my $r = $self->$grp;
        foreach my $k (sort (keys %$r)) {
            $fn_key = $k if $r->{$k}->{name} eq $fn_name;
            last if defined $fn_key;
        }
    }
    return unless defined $fn_key;
    say "Found function key: $fn_key" if $self->debug;
    return $fn_key;
}

sub execute_ohlcv($$) {
    my ($self, $data, $iref, $data2) = @_;
    return unless ref $data eq 'PDL';
    my $fn_key = $self->_find_func_key($iref);
    return unless defined $fn_key;
    # ok now we found the function so let's invoke it
    my $grp = $self->group_key->{$iref->{group}} if defined $iref->{group};
    return unless defined $grp;
    my $params = $iref->{params};
    my $func = $self->$grp->{$fn_key}->{func};
    my $coderef = $self->$grp->{$fn_key}->{code};
    my $paramarray = $self->$grp->{$fn_key}->{params};
    my @args = ();
    for (my $i = 0; $i < scalar @$paramarray; ++$i) {
        my $k = $paramarray->[$i]->[0];
        next unless defined $k;
        if (exists $params->{$k . '_index'}) {
            # handle ARRAY
            push @args, $params->{$k . '_index'};
        } elsif (exists $params->{$k . '_pdl'}) {
            my $csv = $params->{$k};
            $csv =~ s/\s//g if length $csv;
            my @a = split /,/, $csv if length $csv;
            push @args, PDL->new(@a) if @a;
            push @args, PDL::null unless @a;
        } elsif ($k =~ /CompareWith/i) {
            # dont eval it
            push @args, $params->{$k};
        } else {
            push @args, eval $params->{$k};
        }
    }
    my $input_cols = $self->$grp->{$fn_key}->{input} || ['close'];
    $input_cols = ['close'] unless scalar @$input_cols;
    my @input_pdls = ();
    foreach (@$input_cols) {
        push @input_pdls, $data(,(0)) if $_ eq 'time';
        push @input_pdls, $data(,(1)) if $_ eq 'open';
        push @input_pdls, $data(,(2)) if $_ eq 'high';
        push @input_pdls, $data(,(3)) if $_ eq 'low';
        push @input_pdls, $data(,(4)) if $_ eq 'close';
        push @input_pdls, $data(,(5)) if $_ eq 'volume';
    }
    if (defined $data2 and ref $data2 eq 'PDL') {
        push @input_pdls, $data2(,(4)); # always use close
        say "Adding close2 price" if $self->debug;
    }
    unless (scalar @input_pdls) {
        carp "These input columns are not supported yet: ", Dumper($input_cols);
        return;
    }
    return &$coderef($self, @input_pdls, @args) if ref $coderef eq 'CODE';
}

sub get_plot_args($$$) {
    my ($self, $xdata, $output, $iref) = @_;
    my $fn_key = $self->_find_func_key($iref);
    return unless defined $fn_key;
    my $grp = $self->group_key->{$iref->{group}} if defined $iref->{group};
    return unless defined $grp;
    my $plotref = $self->$grp->{$fn_key}->{lc($self->plot_engine)};
    carp "There is no plotting function available for $fn_key" unless ref $plotref eq 'CODE';
    return &$plotref($self, $xdata, $output) if ref $plotref eq 'CODE';
}

1;
__END__
### COPYRIGHT: 2014 Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 17th Aug 2014
### LICENSE: Refer LICENSE file
