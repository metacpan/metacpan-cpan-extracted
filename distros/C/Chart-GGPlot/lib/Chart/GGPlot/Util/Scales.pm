package Chart::GGPlot::Util::Scales;

# ABSTRACT: R 'scales' package functions used by Chart::GGPlot

# TODO: make a separate library, e.g. Color::Scales for the color palettes.
#  Some of the color palette function's signature may change.

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.002003'; # VERSION

use Color::Brewer;
use Color::Library;
use Convert::Color::LCh;
use Data::Munge qw(elem);
use Machine::Epsilon qw(machine_epsilon);
use Math::Round qw(round);
use Memoize;
use PDL::Primitive qw(which interpol);
use PDL::Graphics::ColorSpace 0.203 qw(rgb_to_lab lab_to_rgb);
use Number::Format 1.75;
use Scalar::Util qw(looks_like_number);
use Time::Moment;
use Types::Standard qw(Int);

use POSIX qw(ceil floor log10);

use Role::Tiny ();

use Type::Params;
use Types::PDL qw(Piddle Piddle1D PiddleFromAny);
use Types::Standard qw(ArrayRef ConsumerOf Num Optional Str Maybe);

use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util::_Base qw(:all);
use Chart::GGPlot::Util::_Labeling qw(:all);
use Chart::GGPlot::Util::Scales::_Viridis;

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  censor discard expand_range zero_range
  rescale squish
  hue_pal brewer_pal gradient_n_pal rescale_pal viridis_pal
  seq_gradient_pal div_gradient_pal
  area_pal
  identity_pal
  extended_breaks regular_minor_breaks log_breaks
  pretty pretty_breaks
  number comma percent dollar
  rgb255_to_csshex rgb_to_csshex
  csshex_to_rgb255
  colorname_to_csshex
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


fun censor ( $p, $range = pdl([ 0, 1 ]), $only_finite = true ) {
    my ( $min, $max ) = $range->minmax;
    my $finite = $only_finite ? $p->isfinite : PDL->ones( $p->length );
    return $p->setbadif( $finite & ( ( $p < $min ) | ( $p > $max ) ) );
}


fun discard ( $p, $range = pdl([ 0, 1 ]) ) {
    my ( $min, $max ) = $range->minmax;
    return $p->where( ( ( $p >= $min ) & ( $p <= $max ) ) );
}

# Expand a range with a multiplicative or additive constant
fun expand_range ( $range, $mul = 0, $add = 0, $zero_width = 1 ) {
    state $check =
      Type::Params::compile( Piddle->plus_coercions(PiddleFromAny) );
    ($range) = $check->($range);

    return if ( $range->isempty );  # TODO: return undef or return empty $range?

    my ( $min, $max ) = $range->minmax;
    if ( zero_range($range) ) {
        return pdl( [ $max - $zero_width / 2, $min + $zero_width / 2 ] );
    }
    else {
        my $delta = ( $max - $min ) * $mul + $add;
        return pdl( [ $min - $delta, $max + $delta ] );
    }
}


fun zero_range ( $range, $tol = 1000 * machine_epsilon() ) {
    state $check =
      Type::Params::compile( Piddle1D->where( sub { $_->length == 2 } ) );
    ($range) = $check->($range);
    return ( abs( $range->at(1) - $range->at(0) ) < $tol );
}


fun squish ( $p, $range = pdl([ 0, 1 ]), $only_finite = true ) {
    my ( $min, $max ) = $range->minmax;
    my $finite = $only_finite ? $p->isfinite : PDL->ones( $p->length );
    my $r = $p->copy;

    $r->where( ( $finite & ( $r < $min ) ) ) .= $min;
    $r->where( ( $finite & ( $r > $max ) ) ) .= $max;
    return $r;
}

## scale

# Rescale range to have specified minimum and maximum
fun rescale ( $p, $to = pdl([0, 1]), $from = range_($p) ) {
    my $from_diff = $from->at(1) - $from->at(0);
    my $to_diff = $to->at(1) - $to->at(0);
    if ($from_diff == 0) {
        return pdl([($to->at(0) + $to_diff/2) x $p->length]);
    }
    my $slope = $to_diff / $from_diff;
    return ( $p - $from->at(0) ) * $slope + $to->at(0);
}

## palette

my %brewer = (
    div => [
        "BrBG",   "PiYG",   "PRGn", "PuOr", "RdBu", "RdGy",
        "RdYlBu", "RdYlGn", "Spectral"
    ],
    qual => [
        "Accent",  "Dark2", "Paired", "Pastel1",
        "Pastel2", "Set1",  "Set2",   "Set3"
    ],
    seq => [
        "Blues",   "BuGn", "BuPu", "GnBu",   "Greens", "Greys",
        "Oranges", "OrRd", "PuBu", "PuBuGn", "PuRd",   "Purples",
        "RdPu",    "Reds", "YlGn", "YlGnBu", "YlOrBr", "YlOrRd"
    ],
);

my %pal_names = map { $_ => 1 } map { @$_ } values %brewer;

fun _pal_name ( $palette, $type ) {
    if ( !looks_like_number($palette) ) {
        return exists( $pal_names{$palette} ) ? $palette : 'Greens';
    }
    return $brewer{$type}[$palette];
}


# This method would result color slightly different from R's equivalent
#  method, maybe it's because Convert::Color::LCh does rounding in a
#  different way from R's grDevices::hcl(). But it's fine as the
#  difference in result color channel is at max just 1/256.
fun hcl ($h, $c, $l) {
    my $c = Convert::Color::LCh->new( $l, $c, $h );
    return rgb_to_csshex($c->rgb);
}

fun hue_pal (:$h=pdl([0, 360])+15, :$c=100, :$l=65, :$h_start=0, :$direction=1) {
    my $check =
      Type::Params::compile( Piddle1D->where( sub { $_->length == 2 } )
          ->plus_coercions(PiddleFromAny) );
    ($h) = $check->($h);

    return fun(Int $n) {
        if ( $n == 0 ) {
            die "Must request at least one color from a hue palette.";
        }

        my $h_tmp = $h->copy;
        if ( ( $h_tmp->at(1) - $h_tmp->at(0) ) % 360 < 1 ) {
            $h_tmp = pdl( [ $h_tmp->at(0), $h_tmp->at(1) - 360 / $n ] );
        }
        my $rotate = sub { ( ( $_[0] + $h_start ) % 360 ) * $direction };
        my $hues = $rotate->( pdl( seq_n( $h_tmp->list, $n ) ) );
        return PDL::SV->new(
            $hues->unpdl->map( sub { hcl( $_, $c, $l ); } ) );
    };
}

fun brewer_pal ( $type, $palette = 0, $direction = 1 ) {
    my $pal_name = _pal_name( $palette, $type );

    # $n is number of colors
    return fun(Int $n) {
        my @colors = Color::Brewer::named_color_scheme(
            number_of_data_classes => List::AllUtils::max( $n, 3 ),
            name                   => $pal_name
        );

        # convert to Graphics::Color object
        @colors = map {
            my ( $r, $g, $b ) = $_ =~ /^rgb\((\d+),(\d+),(\d+)\)/;
            rgb255_to_csshex($r, $g, $b);
        } @colors[ 0 .. $n - 1 ];

        if ( $direction == -1 ) {
            @colors = reverse @colors;
        }
        return PDL::SV->new( \@colors );
    };
}

# Returns a function that maps the interval [0,1] to a set of colors.
# Interpolation is performed in the CIELAB color space. 
fun _color_ramp ($colors) {
    if ( $colors->isempty ) {
        die("Must provide at least one color to create a color ramp");
    }

    my $hot_spots = rgb_to_lab(
        pdl(
            map {
                /^\#/
                  ? pdl( csshex_to_rgb255($_) )
                  : pdl( colorname_to_rgb255($_) )
            } ( $colors->flatten )
        ) / 255.0, 
        'sRGB'
    );    # Lab space

    my $x = seq_n(0, 1, $colors->length);

    return fun( Piddle $p ) {
        my @mapped = do {
            map {
                my $xin = pdl($_);
                my $l = $xin->interpol($x, $hot_spots->index(0));
                my $a = $xin->interpol($x, $hot_spots->index(1));
                my $b = $xin->interpol($x, $hot_spots->index(2));
                my $rgb = lab_to_rgb(pdl($l, $a, $b), 'sRGB');
                rgb_to_csshex($rgb->flatten);
            } $p->flatten;
        };
        my $rslt = PDL::SV->new( \@mapped );
        $rslt = $rslt->setbadif( $p->isbad ) if $p->badflag;
        return $rslt;
    };
}

# Arbitrary color gradient palette (continous).
fun gradient_n_pal ( $colors, $values = [] ) {
    my $ramp = _color_ramp($colors);

    my $length = $values->length;
    my $xs = $length ? seq_n( 0, 1, $length ) : undef;

    return fun($p) {
        return PDL->null if ( $p->isempty );

        if (defined $xs) {
            my $p_adjusted = interpol($p, pdl($values), $xs);
            return $ramp->($p_adjusted);
        }
        else {
            return $ramp->($p);
        }
    };
}

fun seq_gradient_pal ($low, $high) {
    return gradient_n_pal( [ $low, $high ] );
}

fun div_gradient_pal ($low, $mid, $high) {
    return gradient_n_pal( [ $low, $mid, $high ] );
}

# Rescale palette (continuous).
fun rescale_pal ( $range = PDL->new( [ 0.1, 1 ] ) ) {
    return fun($p) {
        rescale( $p, $range, PDL->new( [ 0, 1 ] ) );
    };
}

fun viridis_pal ($begin=0, $end=1, $direction=1, $option='viridis') {
    return fun(Int $n) {
        my $colors =
          Chart::GGPlot::Util::Scales::_Viridis::viridis( $n, $begin, $end,
            $direction, $option );
        my @palette = map { rgb_to_csshex(@$_); } @$colors;
        return PDL::SV->new( \@palette );
    };
}

fun area_pal ($range) {
    state $check =
      Type::Params::compile( Piddle1D->plus_coercions(PiddleFromAny) );
    ($range) = $check->($range);

    return fun($x) { return rescale( $x->sqrt, $range, pdl( [ 0, 1 ] ) ); };
}

fun identity_pal() {
    return fun($x) { $x };
}

## trans

fun extended_breaks ( $n = 5, @rest ) {
    return fun($p) {
        $p = $p->where( $p->isfinite );
        return null if ( $p->isempty );

        my $range = range_($p);
        return labeling_extended( $range->at(0), $range->at(1), $n, @rest );
    };
}

# Minor breaks. Places minor breaks between major breaks.
fun regular_minor_breaks ( $reverse = false ) {

    # $n : To create $n - 1 minor breaks between two major breaks
    return fun( $b, $limits, $n ) {
        my $b1 = $b->where( !is_na($b) );

        return PDL->null if ( $b1->length < 2 );

        my ( $min_b,     $max_b )     = ( $b1->min,     $b1->max );
        my ( $min_limit, $max_limit ) = ( $limits->min, $limits->max );

        my @b  = @{ $b1->unpdl };
        my $bd = $b[1] - $b[0];
        if ( !$reverse ) {
            if ( $min_limit < $min_b ) { unshift @b, ( $b[0] - $bd ); }
            if ( $max_limit > $max_b ) { push @b, ( $b[-1] + $bd ); }
        }
        else {
            if ( $max_limit > $max_b ) { unshift @b, ( $b[0] - $bd ); }
            if ( $min_limit < $min_b ) { push @b, ( $b[-1] + $bd ); }
        }

        my $seq_between = fun( $a, $b ) {
            my $rslt = seq_n( $a, $b, $n + 1 )->unpdl;
            pop @$rslt;
            return $rslt;
        };

        my @breaks =
          map { @{ $seq_between->( $b[$_], $b[ $_ + 1 ] ) } } ( 0 .. $#b - 1 );
        return discard( PDL->new( [ @breaks, $b[-1] ] ), $limits );
    }
}



# Intermediate log-scale breaks
# Integer powers of base do not always return sufficient breaks. This function
# adds intermediate breaks which are integer multiples of integer powers of
# base.

# $rng is $base-base log range
fun log_sub_breaks ($base, $n, $rng) {
    my $min = floor( $rng->at(0) );
    my $max = ceil( $rng->at(1) );
    if ( $base <= 2 ) {
        return $base**pdl( [ $min .. $max ] );
    }
    my @steps = (1);

    # delta() calculates the smallest distance in the log scale between the
    # currectly selected breaks and a new candidate 'x'
    my $delta = sub {
        my ($x) = @_;
        return ( pdl( [ $x, @steps, $base ] )->qsort->log / log($base) )
          ->diff->min;
    };
    my $candidate =
      pdl( [ 2 .. ( floor($base) == $base ? $base - 1 : $base ) ] );
    while ( $candidate->length ) {
        my $best =
          pdl( [ map { $delta->($_) } $candidate->flatten ] )->maximum_ind;
        push @steps, $candidate->at($best);
        $candidate = $candidate->slice(
            pdl(
                [ ( 0 .. $best - 1 ), ( $best + 1 .. $candidate->length - 1 ) ]
            )
        );

        my $breaks = pdl( map { ( $base**pdl( [ $min .. $max ] ) * $_ )->flatten }
              @steps );
        my $relevant_breaks =
          ( ( $base**$rng->at(0) <= $breaks ) &
              ( $breaks <= $base**$rng->at(1) ) );
        if ( $relevant_breaks->sum >= $n - 2 ) {
            my $breaks = $breaks->qsort;
            my $lower_end =
              List::AllUtils::max(
                which( $base**$rng->at(0) <= $breaks )->min - 1, 0 );
            my $upper_end =
              List::AllUtils::min(
                which( $breaks <= $base**$rng->at(1) )->max + 1,
                $breaks->length - 1 );
            return $breaks->slice( pdl( [ $lower_end .. $upper_end ] ) );
        }
    }

    return extended_breaks($n)->( $base**$rng );
}

fun log_breaks ($base=10, $n=5) {
    return fun($x) {
        my $rng = range_( $x, true )->log / pdl($base)->log;
        my $min = floor( $rng->at(0) );
        my $max = ceil( $rng->at(1) );
        if ( $max == $min ) { 
            return $base**$min;
        }   
        my $by     = floor( ( $max - $min ) / $n + 1 );
        do {
            my $breaks = $base**seq_by( $min, $max, $by );
            my $relevant_breaks =
              ( ( $base**$rng->at(0) <= $breaks ) & 
                  ( $breaks <= $base**$rng->at(1) ) );
            if ( $relevant_breaks->sum >= $n - 2 ) { 
                return $breaks;
            }   
            $by -= 1;
        } while ( $by > 0 );
        return log_sub_breaks( $base, $n, $rng );
    };  
}


# This is ported from R "labeling" package's rpretty(), which is unlike R's
# pretty() function in that it does not handle DateTime objects.
fun pretty($x, :$n=5, :$min_n = $n % 3, :$shrink_sml = 0.75,
           :$high_u_bias = 1.5, :$u5_bias = 0.5 + 1.5 * $high_u_bias) {
    my ($dmin, $dmax) = $x->minmax;
    my $ndiv = $n;
    my $h = $high_u_bias;
    my $h5 = $u5_bias;
    my $dx   = $dmax - $dmin;

    my $cell;
    my $i_small;
    my $u;
    if ($dx == 0 and $dmax == 0) {
        $cell = $u = 1;
        $i_small = true;
    } else {
        $cell = List::AllUtils::max(abs($dmin), abs($dmax));
        $u = 1 + (($h5 >= 1.5 * $h + 0.5) ? 1 / (1 + $h) : 1.5/(1 + $h5));
        $i_small = $dx < ($cell * $u * List::AllUtils::max(1, $ndiv) * 1e-7 * 3);
    }
    if ($i_small) {
        if ($cell > 10) {
            $cell = 9 + $cell / 10;
        }
        $cell = $cell * $shrink_sml;
        if ($min_n > 1) {
            $cell = $cell / $min_n;
        }
    }
    else {
        $cell = $dx;
        if ($ndiv > 1) {
            $cell = $cell / $ndiv;
        }
    }
    $cell = List::AllUtils::max($cell, 20 * 1e-7);

    my $base = 10 ** floor(log10($cell));
    my $unit = $base;
    if ((2 * $base) - $cell < $h * ($cell - $unit)) {
        $unit = 2 * $base;
        if ((5 * $base) - $cell < $h5 * ($cell - $unit)) {
            $unit = 5 * $base;
            if ((10 * $base) - $cell < $h * ($cell - $unit)) {
                $unit = 10 * $base;
            }
        }
    }

    my $ns = floor($dmin/$unit + 1e-07);
    my $nu = ceil($dmax/$unit - 1e-07);
    while ($ns * $unit > $dmin + (1e-07 * $unit)) { $ns--; }
    while ($nu * $unit < $dmax - (1e-07 * $unit)) { $nu++; }

    my $k = floor(0.5 + $nu - $ns);
    if ($k < $min_n) {
        $k = $min_n - $k;
        if ($ns >= 0) {
            $nu = $nu + $k/2;
            $ns = $ns - $k/2 + $k % 2;
        }
        else {
            $ns = $ns - $k/2;
            $nu = $nu + $k/2 + $k % 2;
        }
        $ndiv = $min_n;
    }
    else {
        $ndiv = $k;
    }
    my $graphmin = $ns * $unit;
    my $graphmax = $nu * $unit;

    return seq_by($graphmin, $graphmax, $unit);
}

fun seq_dt (:$beg, :$end=undef, :$by, :$length=undef) {
    state $check = Type::Params::compile(
        ConsumerOf ['PDL::DateTime'],
        Maybe [ ConsumerOf ['PDL::DateTime'] ],
        Str
    );
    ($beg, $end, $by) = $check->($beg, $end, $by);

    my $start_time = $beg->dt_at(0);

    if ( $by ne 'halfmonth' ) {
        my ( $step, $unit ) = split( /\s+/, $by );
        unless (defined $length) {
            my $delta_f = "delta_${unit}s";
            no strict 'refs';
            $length = $beg->dt_unpdl('Time::Moment')->[0]
              ->$delta_f( $end->dt_unpdl('Time::Moment')->[0] ) / $step;
            if ( ceil($length) == $length ) {
                $length += 1;
            }
            $length = ceil($length);
        }
        return PDL::DateTime->new_sequence( $start_time, $length, $unit,
            $step );
    }

    # else: by "halfmonth"
    my $at =
      defined $length
      ? seq_dt( beg => $beg, by => '1 month', length => ceil( $length / 2 ) )
      : seq_dt( beg => $beg, by => '1 month', end    => $end );

    #TODO: $at->dt_day would hang here. For now let's workaround...
    #my $md = List::AllUtils::uniq( @{ $at->dt_day } );
    my @md = List::AllUtils::uniq( map { $_->day_of_month } @{ $at->dt_unpdl('Time::Moment') } );
    die unless @md == 1;
    
    my $md = $md[0];
    my $at2 =
        $md < 15
      ? $at->dt_add( day => 14 )
      : $at->dt_add( day => 1 - $md, month => 1 );
    my $rslt = PDL::DateTime->new(
        [ sort { $a <=> $b } ( @{ $at->unpdl }, @{ $at2->unpdl } ) ] );
    return $rslt;
}

fun dt_align ($pdldt, $unit, $start_on_monday=true) {
    if (
        elem(
            $unit,
            [
                qw(
                  second minute hour
                  day week month quarter year
                  )
            ]
        )
      )
    {
        return $pdldt->dt_align($unit);
    }

    state $round_year = sub {
        my ( $x, $n ) = @_;

        return PDL::DateTime->new_from_datetime(
            $x->dt_align('year')->dt_unpdl()->map(
                sub {
                    my ( $y, $m, $d ) = split( /\-/, $_ );
                    $y = int( $y / $n ) * $n;
                    "$y-$m-$d";
                }
            )
        );
    };

    if ( $unit eq 'decade' ) {
        return $round_year->( $pdldt, 10 );
    }
    elsif ( $unit eq 'century' ) {
        return $round_year->( $pdldt, 100 );
    }
}

# R pretty.Date()
fun pretty_dt($x, :$n = 5, :$min_n = $n % 2, %rest) {
    state $check = Type::Params::compile(ConsumerOf['PDL::DateTime']);
    ($x) = $check->($x);
    
    my $zz = my $rx = PDL::DateTime->new([$x->min, $x->max]);

    my $MIN = 60;
    my $HOUR = $MIN * 60;
    my $DAY = $HOUR * 24;
    my $YEAR = $DAY * 365.25;
    my $MONTH = $YEAR / 12;

    state $diff_secs = sub {
        my ($zz) = @_;
        my $x = $zz->double_epoch;
        return ($x->at(1) - $x->at(0));
    };

    my $D = $diff_secs->($zz);

    state $make_output = sub {
        my ($at, $s, $round) = @_;

        # TODO: R implementation may round to date here if $x is Date.
        # We don't do it so far because we don't have Date vs. DateTime yet.
        # $round //= true;
        Role::Tiny->apply_roles_to_object($at, 'PDL::Role::HasNames');
        $at->names($at->dt_unpdl($s->{format}));
        return $at;
    };

    if ($D < $n * $DAY) {

        # TODO: Shall not align to day before we have Date vs DateTime.
        # $zz = $zz->dt_align('day');   
        my $r = round($n - $D / $DAY);
        my $m = List::AllUtils::max(0, $r % 2);
        my $m2 = $m + ($r % 2);
        my $dd = seq_dt(
            beg => PDL::DateTime->new( $zz->at(0) - $m * $DAY ),
            end => PDL::DateTime->new( $zz->at(1) + $m2 * $DAY ),
            by  => '1 day'
        );
        while ($dd->length < $min_n + 1) {
            if ($m < $m2) {
                $m = $m+1;
            } else {
                $m2 = $m2 + 1;
            }
        }   
        return $make_output->($dd, { format => "%b %d" }, false);
    } elsif ($D < 1) {  # unique values / sub-second ranges
        my $m = List::AllUtils::min(30, List::AllUtils::max($D, $n/2));

        # TODO: won't reach here now as we don't have Date vs. DateTime.
    }
    my $xspan = $diff_secs->($zz);
    my $steps = [
        { spec => '1 second',  secs => 1, format => '%S', start => 'minute' },
        { spec => '2 second',  secs => 2 },
        { spec => '5 second',  secs => 5 },
        { spec => '10 second', secs => 10 },
        { spec => '15 second', secs => 15 },
        { spec => '30 second', secs => 30, format => '%H:%M:%S' },
        { spec => '1 minute',  secs => $MIN, format => '%H:%M' },
        { spec => '2 minute',  secs => 2 * $MIN, start => 'hour' },
        { spec => '5 minute',  secs => 5 * $MIN },
        { spec => '10 minute', secs => 10 * $MIN },
        { spec => '15 minute', secs => 15 * $MIN },
        { spec => '30 minute', secs => 30 * $MIN },
        {
            spec   => '1 hour',
            secs   => $HOUR,
            format => ( $xspan < $DAY ? '%H:%M' : '%b %d %H:%M' )
        },
        { spec => '3 hour',    secs => 3 * $HOUR,    start  => 'day' },
        { spec => '6 hour',    secs => 6 * $HOUR,    format  => '%b %d %H:%M' },
        { spec => '12 hour',   secs => 12 * $HOUR },
        { spec => '1 day',     secs => $DAY,         format => '%b %d' },
        { spec => '2 day',     secs => 2 * $DAY },
        { spec => '1 week',    secs => 7 * $DAY,     start  => 'week' },
        { spec => 'halfmonth', secs => 0.5 * $MONTH, start  => 'month' },
        {
            spec   => '1 month',
            secs   => $MONTH,
            format => ( $xspan < $YEAR ? '%b' : '%b %Y' )
        },
        { spec => '3 month',   secs => 3 * $MONTH, start  => 'year' },
        { spec => '6 month',   secs => 6 * $MONTH, format => '%Y-%m' },
        { spec => '1 year',    secs => $YEAR,      format => '%Y' },
        { spec => '2 year',    secs => 2 * $YEAR,  start  => 'decade' },
        { spec => '5 year',    secs => 5 * $YEAR },
        { spec => '10 year',   secs => 10 * $YEAR },
        { spec => '20 year',   secs => 20 * $YEAR, start  => 'century' },
        { spec => '50 year',   secs => 50 * $YEAR },
        { spec => '100 year',  secs => 100 * $YEAR },
        { spec => '200 year',  secs => 200 * $YEAR },
        { spec => '500 year',  secs => 500 * $YEAR },
        { spec => '1000 year', secs => 1000 * $YEAR },
    ];
    for my $i (1 .. $#$steps) {
        $steps->[$i]{format} //= $steps->[$i-1]{format};
        $steps->[$i]{start} //= $steps->[$i-1]{start};
    }

    # crudely work out number of steps in the given interval
    my $nsteps = $xspan / pdl($steps->map(sub { $_->{secs} }));
    my $init_i = my $init_i0 = ($nsteps-$n)->abs->minimum_ind;

    # calculate actual number of ticks in the given interval

    my $calc_steps = sub {
        my ( $s, $lim ) = @_;
        $lim //= range_($zz);

        my $spec  = $s->{spec};

        my $start = dt_align( PDL::DateTime->new($lim->at(0)), $s->{start} );
        my $at = seq_dt(
            beg => $start,
            end => PDL::DateTime->new( $lim->at(1) ),
            by  => $spec
        );
        my $r1 = List::AllUtils::max( $at->where( $at <= $lim->at(0) )->length - 1, 0 );
        my $r2 = $at->length - $at->where( $at >= $lim->at(1) )->length;
        if ( $r2 == $at->length )
        {    # not covering at right -- add point at right
            my $nat = seq_dt(
                beg => PDL::DateTime->new( $at->at(-1) ),
                by  => $spec,
                length => 2
            )->slice( pdl( [1] ) );
            unless ( $nat->where( $nat > $at->at(-1) )->length == $nat->length ) {    # failed
                $r2 = $at->length - 1;
            }
            $at = PDL::DateTime->new( $at->glue( 0, $nat ) );
        }
        return $at->slice( pdl( [ $r1 .. $r2 ] ) );
    };

    my $init_at = $calc_steps->(my $st_i = $steps->[$init_i]);

    # bump it up if below acceptable threshold
    my $R = true;
    my $L_fail = my $R_fail = false;
    my $init_n = $init_at->length - 2;
    while ($init_n < $min_n) {
        if ($init_i == 0) {  # keep steps->[0]
            # add new interval right or left
            if ($R) {
                my $nat = seq_dt(beg => $init_at->at(-1), by => $st_i->{spec}, length => 2)->slice(pdl([1]));
                $R_fail = ($nat->isbad->at(0) or $nat->at(0) > $init_at->at(-1));
                unless ($R_fail) {
                    $init_at->dt_set(-1, $nat->dt_at(0));
                } 
            } else {    # left
                my $nat = seq_dt(beg => $init_at->at(-1), by => "-$st_i->{spec}", length => 2)->slice(pdl([1]));
                $L_fail = ($nat->isbad->at(0) or $nat->at(0) < $init_at->at(0));
                unless ($L_fail) {
                    $init_at->dt_set(0, $nat->dt_at(0));
                } 
            }
            if ($R_fail and $L_fail) {
                die q{failed to add more ticks; $min_n too large?};
            }
            $R = !$R;   # alternating right <-> left
        } else {    # smaller step sizes
            $init_i = $init_i - 1;
            $st_i = $steps->[$init_i];
            $init_at = $calc_steps->($st_i);
        }
    }

    if ($init_n == $n - 1 ) {   # perfect
        return $make_output->($init_at, $st_i);
    }
    # else: have a different dn
    my $dn = $init_n - ($n - 1);
    if ($dn > 0) {
        # ticks "outside", on left and right, keep at least one on each side
        my $nl = $init_at->where( $init_at <= $rx->at(0) )->length - 1;
        my $nr = $init_at->where( $init_at >= $rx->at(1) )->length - 1;
        if ($nl > 0 or $nr > 0) {
            my $n_c = $nl + $nr;
            if ($dn < $n_c) { # remove $dn, not all
                $nl = round($dn * $nl / $n_c);
                $nr = $dn - $nl;
            }
            # remove nl on left,  nr on right
            $init_at = $init_at->slice(pdl([$nl .. $init_at->length-$nr - 1]));
        }
    }

    $dn = $init_at->length - 1 - $n;
    if (    $dn == 0    # perfect
            or ($dn > 0 and $init_i < $init_i0)    # too many, but we tried $init_i + 1 already
            or ($dn < 0 and $init_i == 0))  # too few but $init_i == 0
    {
        return $make_output->($init_at, $st_i);
    }

    my $new_i =
      ( $dn > 0
        ? List::AllUtils::min( $init_i + 1, $steps->length - 1 )
        : $init_i - 1 );
    my $new_at = $calc_steps->($steps->[$new_i]);
    my $new_n = $new_at->length - 1;

    # work out whether new.at or init.at is better
    if ($new_n < $min_n) {
        $new_n = "-Inf";
    }
    return
      abs( $new_n - $n ) < abs($dn)
      ? $make_output->( $new_at,  $steps->[$new_i] )
      : $make_output->( $init_at, $st_i );
}


fun pretty_breaks($n=5, %rest) {
    return sub {
        my ($x) = @_;

        my $f = $x->$_DOES('PDL::DateTime') ? 'pretty_dt' : 'pretty';
        no strict 'refs';
        return $f->($x, n=>$n, %rest);
    };
}

fun dollar ($p, :$accuracy=undef, :$scale=1, 
            :$prefix='$', :$suffix='',
            :$big_mark=',', :$decimal_mark='.',
            :$largest_with_cents=1e5, :$negative_parens=false) {
    return PDL::SV->new( [] ) if ( $p->length == 0 );

    $accuracy //= _need_cents( $p * $scale, $largest_with_cents ) ? 0.01 : 1;
    my $precision = List::AllUtils::max( -floor( log10($accuracy) ), 0 );
    my $negative  = ( $p->isgood & ( $p < 0 ) );

    my $fmt = Number::Format->new(
        -thousands_sep     => $big_mark,
        -mon_thousands_sep => $big_mark,
        -decimal_point     => $decimal_mark,
        -mon_decimal_point => $decimal_mark,
        -int_curr_symbol   => $prefix,
        ( $negative_parens ? ( -n_sign_posn => 0 ) : () ),

        # Number::Format would use locale's settings like P/N_SEP_BY_SPACE.
        # Here we force these values to align with R's scale::dollar to make
        # the behavior simple.
        -p_sep_by_space => 0,
        -n_sep_by_space => 0,
        -p_cs_precedes  => 1,
        -n_cs_precedes  => 1,
    );

    no warnings 'numeric';
    my @amount = map { $fmt->format_price( $_, $precision ); } @{ $p->unpdl };

    my $rslt = PDL::SV->new( \@amount );
    $rslt = $rslt->setbadif( $p->isbad ) if $p->badflag;
    return $rslt;
}

fun _need_cents ($p, $threshold) {
    return false if ($p->badflag and $p->isbad->all);
    return false if ($p->abs->max > $threshold);
    return !(
        (
            $p->badflag
            ? ( ( $p->floor == $p ) | $p->isbad )
            : ( $p->floor == $p )
        )->all
    );
}

fun percent ($p, :$accuracy=undef, :$scale=100,
             :$prefix='', :$suffix="%",
             :$big_mark=',', :$decimal_mark='.'
        ) {
    return number(
        $p,
        accuracy => $accuracy,
        scale    => $scale,
        prefix   => $prefix,
        suffix   => $suffix
    );
}

fun comma ($p, :$big_mark=',', %rest) {
    return number($p, big_mark => $big_mark, %rest);
}

fun number ($p, :$accuracy=1, :$scale=1,
            :$big_mark=' ', :$decimal_mark='.',
            :$prefix='', :$suffix=''
        ) {
    return PDL::SV->new( [] ) if $p->length == 0;

    $accuracy //= _accuracy($p);
    my $precision =
      List::AllUtils::max( -floor( log10( $accuracy / $scale ) ), 0 );
    my $fmt = Number::Format->new(
        -thousands_sep => $big_mark,
        -decimal_point => $decimal_mark
    );

    my @s = ( $p * $scale )->list;
    no warnings 'numeric';
    @s = map { "${prefix}${_}${suffix}" }
      map { $_ eq 'BAD' ? $_ : $fmt->format_number( $_, $precision ); } @s;

    my $rslt = PDL::SV->new( \@s );
    $rslt->setbadif( $p->isbad ) if $p->badflag;
    return $rslt;
}

fun _accuracy ($p) {
    return 1 if ((!$p->isfinite)->all);

    my $rng = range_($p, true, true);
    my $span = zero_range($rng) ? $rng->at(0)->abs : $rng->at(1) - $rng->at(0);
    return 1 if ($span == 0);
    return 10 ** (pdl($span)->log10->floor);  
}


sub rgb255_to_csshex { sprintf("#%02x%02x%02x", @_); }

sub rgb_to_csshex {
    rgb255_to_csshex(
        map { List::Util::max( 0, List::Util::min( 255, int( $_ * 256.0 ) ) ) }
          @_ );
}

sub csshex_to_rgb255 {
    my ($csshex) = @_;
    return map { hex($_) } ( $csshex =~ /^#(..)(..)(..)/);
}

sub colorname_to_rgb255 {
    my ($color_name) = @_;
    my $color = Color::Library->color($color_name);
    die "unknown color id '$color_name'" unless defined $color;
    return $color->rgb;
}

sub colorname_to_csshex {
    my ($color_name) = @_;
    return rgb255_to_csshex( colorname_to_rgb255($color_name) );
}
memoize('colorname_to_csshex');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Util::Scales - R 'scales' package functions used by Chart::GGPlot

=head1 VERSION

version 0.002003

=head1 FUNCTIONS

=head2 censor

    censor($p, $range=pdl([0,1]), $only_finite=true)

Censor any values outside of range.

=head2 discard

    discar($p, $range=pdl([0,1]))

Discard any values outside of range.

=head2 zero_range

    zero_range($range, $tol=1000*machine_epsilon)

Determine if range is close to zero, with a specified tolerance.

=head2 squish

    squish($p, $range=pdl([0,1]), $only_finite=true)

Squish values into range.

=head2 hue_pal

    hue_pal($h=pdl([0, 360]), $c=100, $l=65, $h_start=0, $direction=1)

=head2 log_breaks

    log_breaks($base=10, $n=5)

=head2 pretty

Compute a sequence of about n+1 equally spaced 'round' values which cover
the range of the values in x. The values are chosen so that they are
1, 2 or 5 times a power of 10.

=head2 pretty_breaks

Pretty breaks. Uses default break algorithm as implemented in C<pretty()>.

=head2 rgb255_to_csshex

    rgb255_to_csshex($r, $g, $b)

You must make sure the arguments are beteen [0, 255] yourself.

=head2 rgb_to_csshex

    rgb_to_csshex($r, $g, $b)

Similar as C<rgb255_to_csshex()> but the arguments should be between
[0, 1]. This function would process arguments not within [0, 1]. 

=head2 csshex_to_rgb255

    ($r, $g, $b) = csshex_to_rgb255($color_hex)

=head2 colorname_to_csshex

    colorname_to_csshex($color_name)

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
