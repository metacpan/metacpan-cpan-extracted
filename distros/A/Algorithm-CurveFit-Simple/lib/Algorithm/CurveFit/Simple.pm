package Algorithm::CurveFit::Simple;

# ABSTRACT: Convenience wrapper around Algorithm::CurveFit.

our $VERSION = '1.03'; # VERSION 1.03

use strict;
use warnings;
use Algorithm::CurveFit;
use Time::HiRes;
use JSON::PP;

our %STATS_H;  # side-products of fit() stored here for profiling purposes

BEGIN {
    require Exporter;
    our $VERSION = '1.03';
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(fit %STATS_H);
}

# fit() - only public function for this distribution
# Given at least parameter "xy", generate a best-fit curve within a time limit.
# Output: max deviation, avg deviation, implementation source string (perl or C, for now).
# Optional parameters and their defaults:
#    terms       => 3      # number of terms in formula, max is 10
#    time_limit  => 3      # number of seconds to try for better fit
#    inv         => 1      # invert sense of curve-fit, from x->y to y->x
#    impl_lang   => 'perl' # programming language used for output implementation: perl, c
#    impl_name   => 'x2y'  # name given to output implementation function
sub fit {
    my %p = @_;

    my $formula = _init_formula(%p);
    my ($xdata, $ydata) = _init_data(%p);
    my $parameters = _init_parameters($xdata, $ydata, %p);

    my $iter_mode  = 'time';
    my $time_limit = 3;  # sane default?
    $time_limit = 0.01 if ($time_limit < 0.01);
    my $n_iter;
    if (defined($p{iterations})) {
        $iter_mode = 'iter';
        $n_iter    = $p{iterations} || 10000;
    } else {
        $time_limit = $p{time_limit} // $time_limit;
        $n_iter     = 10000 * $time_limit;  # will use this to figure out how long it -really- takes.
    }
    
    my ($n_sec, $params_ar_ar);
    if ($iter_mode eq 'time') {
        ($n_sec, $params_ar_ar) = _try_fit($formula, $parameters, $xdata, $ydata, $n_iter, $p{fitter_class});
        $STATS_H{iter_mode} = $iter_mode;
        $STATS_H{fit_calib_iter}  = $n_iter;
        $STATS_H{fit_calib_time}  = $n_sec;
        $STATS_H{fit_calib_parar} = $params_ar_ar;
        $n_iter = int(($time_limit / $n_sec) * $n_iter + 1);
    }

    ($n_sec, $params_ar_ar) = _try_fit($formula, $parameters, $xdata, $ydata, $n_iter, $p{fitter_class});
    $STATS_H{fit_iter}  = $n_iter;
    $STATS_H{fit_time}  = $n_sec;
    $STATS_H{fit_parar} = $params_ar_ar;

    my $coderef = _implement_formula($params_ar_ar, "coderef", "", $xdata, \%p);
    my ($max_dev, $avg_dev) = _calculate_deviation($coderef, $xdata, $ydata);
    my $impl_lang = $p{impl_lang} // 'perl';
       $impl_lang = lc($impl_lang);
    my $impl_name = $p{inv} ? "y2x" : "x2y";
       $impl_name = $p{impl_name} // $impl_name;
    my $impl = $coderef;
       $impl = _implement_formula($params_ar_ar, $impl_lang, $impl_name, $xdata, \%p) unless($impl_lang eq 'coderef');
    return ($max_dev, $avg_dev, $impl);
}

# ($n_sec, $params_ar_ar) = _try_fit($formula, $parameters, $xdata, $ydata, $n_iter, $p{fitter_class});
sub _try_fit {
    my ($formula, $parameters, $xdata, $ydata, $n_iter, $fitter_class) = @_;
    $fitter_class //= "Algorithm::CurveFit";
    my $params_ar_ar = [map {[@$_]} @$parameters];  # making a copy because curve_fit() is destructive
    my $tm0 = Time::HiRes::time();
    my $res = $fitter_class->curve_fit(
        formula  => $formula,
        params   => $params_ar_ar,
        variable => 'x',
        xdata    => $xdata,
        ydata    => $ydata,
        maximum_iterations => $n_iter
    );
    my $tm_elapsed = Time::HiRes::time() - $tm0;
    return ($tm_elapsed, $params_ar_ar);
}

sub _init_formula {
    my %p = @_;
    my $formula = 'k + a*x + b*x^2 + c*x^3';  # sane'ish default
    my $terms = $p{terms} // 3;
    die "maximum of 10 terms\n" if ($terms > 10);
    if ($terms != 3) {
        $formula = 'k';
        for (my $i = 1; $i <= $terms; $i++) {
            my $fact = chr(ord('a') + $i - 1);
            $formula .= " + $fact * x^$i";
        }
    }
    return $formula;
}

# ($xdata, $ydata) = _init_data(%p);
sub _init_data {
    my %p = @_;
    my ($xdata, $ydata);
    if (defined($p{xydata})) {
        my $xy = $p{xydata};
        unless (
            ref($xy) eq 'ARRAY'
            && @$xy >= 2
            && ref($xy->[0]) eq 'ARRAY'
            && ref($xy->[1]) eq 'ARRAY'
        ) {
            die "xydata must be either an arrayref of [x, y] data point arrayrefs or an arrayref [[x0, x1, ... xN], [y0, y1, ... yN]]\n";
        }
        if (@$xy == 2 && @{$xy->[0]} > 2) {
            # user has provided [[x, ..], [y, ..]]
            $xdata = $xy->[0];
            $ydata = $xy->[1];
        } else {
            # user has provided [[x, y], [x, y], ..]
            die "pairwise xydata must have two data points per element\n" unless(@{$xy->[0]} == 2);
            $xdata = [map {$_->[0]} @{$xy}];
            $ydata = [map {$_->[1]} @{$xy}];
        }
    }
    elsif (defined($p{xdata}) && defined($p{ydata})) {
        $xdata = $p{xdata};
        $ydata = $p{ydata};
    }
    else {
        die "must provide at least xydata or both xdata and ydata\n";
    }
    die "xdata and ydata must both be arrayref\n" unless (ref($xdata) eq "ARRAY" && ref($ydata) eq "ARRAY");
    die "xdata and ydata must have the same number of elements\n" unless (@$xdata == @$ydata);
    die "must have more than one data-point\n" unless (@$xdata > 1);
    if ($p{inv}) {
        $STATS_H{xdata} = $ydata;
        $STATS_H{ydata} = $xdata;
        return ($ydata, $xdata);
    }
    $STATS_H{xdata} = $xdata;
    $STATS_H{ydata} = $ydata;
    return ($xdata, $ydata);
}

# $parameters = _init_parameters($xdata, $ydata, %p);
sub _init_parameters {
    my ($xdata, $ydata, %p) = @_;
    my $k = 0;
    my $n_points = @$xdata;
    foreach my $v (@$ydata) { $k += $v; }
    $k /= $n_points;
    # zzapp -- implement any precision hints here.
    my @params = (['k', $k, 0.0000001]);
    my $terms = $p{terms} // 3;
    push @params, map {[chr(ord('a')+$_-1), 0.5, 0.0000001]} (1..$terms);
    return \@params;
}

# $impl = _implement_formula($params_ar_ar, $impl_lang, $impl_name, $xdata, \%p) unless($impl_lang eq 'coderef');
sub _implement_formula {
    my ($params_ar_ar, $impl_lang, $impl_name, $xdata, $opt_hr) = @_;
    return _implement_formula_as_coderef(@_) if ($impl_lang eq 'coderef');
#   return _implement_formula_as_python(@_)  if ($impl_lang eq 'python');  # zzapp
    return _implement_formula_as_C(@_)       if ($impl_lang eq 'c');
#   return _implement_formula_as_R(@_)       if ($impl_lang eq 'r');  # zzapp
#   return _implement_formula_as_MATLAB(@_)  if ($impl_lang eq 'matlab');  # zzapp
    return _implement_formula_as_perl(@_);
}

sub _implement_formula_as_coderef {
    my ($params_ar_ar, $impl_lang, $impl_name, $xdata, $opt_hr) = @_;
    my $k_ar = $params_ar_ar->[0];
    my $formula = sprintf("%f", $k_ar->[1]);
    for (my $i = 1; defined($params_ar_ar->[$i]); $i++) {
        my $fact = $params_ar_ar->[$i]->[1];
        my $pow  = ($i == 1) ? "" : "**$i";
        $formula .= sprintf(' + %f * $x%s', $fact, $pow);
    }
    $STATS_H{impl_formula} = $formula;
    my $bounder = '';
    if ($opt_hr->{bounds_check}) {
        my ($high_x, $low_x) = ($xdata->[0], $xdata->[0]);
        foreach my $x (@$xdata) {
            $high_x = $x if ($high_x < $x);
            $low_x  = $x if ($low_x  > $x);
        }
        $bounder = 'die "x out of bounds (high)" if ($x > '.$high_x.'); die "x out of bounds (low)" if ($x < '.$low_x.');';
    }
    my $rounder = '';
    $rounder = '$y = int($y + 0.5);' if ($opt_hr->{round_result});
    my $src = 'sub { my($x) = @_; '.$bounder.' my $y = '.$formula.'; '.$rounder.' return $y; }';
    $STATS_H{impl_source} = $src;
    $STATS_H{impl_exception} = '';
    my $coderef = eval($src);
    $STATS_H{impl_exception} = $@ unless(defined($coderef));
    return $coderef;
}

sub _implement_formula_as_perl {
    my ($params_ar_ar, $impl_lang, $impl_name, $xdata, $opt_hr) = @_;
    my $k_ar = $params_ar_ar->[0];
    my $formula = sprintf("%.11f", $k_ar->[1]);
    for (my $i = 1; defined($params_ar_ar->[$i]); $i++) {
        my $fact = $params_ar_ar->[$i]->[1];
        my $pow  = ($i == 1) ? "" : "**$i";
        $formula .= sprintf(' + %.11f * $x%s', $fact, $pow);
    }
    $STATS_H{impl_formula} = $formula;
    my $bounder = '';
    if ($opt_hr->{bounds_check}) {
        my ($high_x, $low_x) = ($xdata->[0], $xdata->[0]);
        foreach my $x (@$xdata) {
            $high_x = $x if ($high_x < $x);
            $low_x  = $x if ($low_x  > $x);
        }
        $bounder = sprintf('    die "x out of bounds (high)" if ($x > %.11f);'."\n", $high_x) .
                   sprintf('    die "x out of bounds (low)"  if ($x < %.11f);'."\n", $low_x);
    }
    my $rounder = '';
    $rounder = '    $y = int($y + 0.5);'."\n" if ($opt_hr->{round_result});
    my $src = join("\n",(
        "sub $impl_name {",
        '    my($x) = @_;',
        $bounder,
        '    my $y = '.$formula.';',
        $rounder,
        '    return $y;',
        '}'
    ));
    $STATS_H{impl_source} = $src;
    $STATS_H{impl_exception} = '';
    return $src;
}

sub _implement_formula_as_C {
    my ($params_ar_ar, $impl_lang, $impl_name, $xdata, $opt_hr) = @_;
    my $k_ar = $params_ar_ar->[0];
    my $src = "";
    $src .= "#include <math.h>\n" if ($opt_hr->{round_result} && !$opt_hr->{suppress_includes});
    $src .= "double $impl_name(double x) {\n";
    $src .= sprintf("    double y  = %.11f;\n", $k_ar->[1]);
    $src .= "    double xx = x;\n";  # eliminating pow() calls, which gcc doesn't seem willing to optimize completely away

    if ($opt_hr->{bounds_check}) {
        my ($high_x, $low_x) = ($xdata->[0], $xdata->[0]);
        foreach my $x (@$xdata) {
            $high_x = $x if ($high_x < $x);
            $low_x  = $x if ($low_x  > $x);
        }
        # zzapp -- this is kludgy.  better way to signal bounds violation?
        $src .= sprintf("    if (x > %.11f) return -1.0;\n", $high_x) .
                sprintf("    if (x < %.11f) return -1.0;\n", $low_x);
    }

    my $formula = "";
    for (my $i = 1; defined($params_ar_ar->[$i]); $i++) {
        my $fact = $params_ar_ar->[$i]->[1];
        $formula .= sprintf("    y += %.11f * xx;\n", $fact);
        $formula .= "    xx *= x;\n" if(defined($params_ar_ar->[$i+1]));
    }
    $STATS_H{impl_formula} = $formula;  # zzapp -- not clean!

    $src .= $formula;
    $src .= "    y = round(y);\n" if ($opt_hr->{round_result});
    $src .= "    return y;\n}\n";
    $STATS_H{impl_source} = $src;
    $STATS_H{impl_exception} = '';
    return $src;
}

# ($max_dev, $avg_dev) = _calculate_deviation($coderef, $xdata, $ydata);
sub _calculate_deviation {
    my ($coderef, $xdata, $ydata) = @_;
    my $max_off       = 1.0;
    my $max_off_datum = 0.0;
    my $tot_off       = 0.0;
    for (my $i = 0; defined($xdata->[$i]); $i++) {
        my $x = $xdata->[$i];
        my $y = eval { $coderef->($x); };
        unless(defined($y)) {
            $STATS_H{deviation_exception} = $@;
            $STATS_H{deviation_exception_datum} = $x;
            die "caught exception calculating deviations";
        }

        my $observed_y  = $ydata->[$i];
        if ($observed_y && $y) {
            my $deviation = $y > $observed_y ? $y / $observed_y : $observed_y / $y;
            my $dev_mag = abs($deviation - 1.0);
            my $max_mag = abs($max_off - 1.0);
            # print "x=$x\ty=$y\toy=$observed_y\tdev_mag=$dev_mag\tmax_mag=$max_mag\n";
            ($max_off, $max_off_datum) = ($deviation, $x) if ($dev_mag > $max_mag);
            $tot_off += $deviation;
        } else {
            $tot_off += 1.0;
        }
    }
    $STATS_H{deviation_max_offset_datum} = $max_off_datum;
    return ($max_off, $tot_off / @$xdata);
}


1;

=head1 NAME

Algorithm::CurveFit::Simple - Convenience wrapper around Algorithm::CurveFit

=head1 SYNOPSIS

    use Algorithm::CurveFit::Simple qw(fit);

    my ($max_dev, $avg_dev, $src) = fit(xdata => \@xdata, ydata => \@ydata, ..options..);

    # Alternatively pass xdata and ydata together:
    my ($max_dev, $avg_dev, $src) = fit(xydata => [\@xdata, \@ydata], ..options..);

    # Alternatively pass data as array of [x,y] pairs:
    my ($max_dev, $avg_dev, $src) = fit(xydata => [[1, 2], [2, 5], [3, 10]], ..options..);

=head1 DESCRIPTION

This is a convenience wrapper around L<Algorithm::CurveFit>.  Given a body of (x, y) data points, it will generate a polynomial formula f(x) = y which fits that data.

Its main differences from L<Algorithm::CurveFit> are:

=over 4

=item * It synthesizes the initial formula for you,

=item * It allows for a time limit on the curve-fit instead of an iteration count,

=item * It implements the formula as source code (or as a perl coderef, if you want to use the formula immediately in your program).

=back

Additionally it returns a maximum deviation and average deviation of the formula vs the xydata, which is more useful (to me, at least) than L<Algorithm::CurveFit>'s square residual output.  Closer to 1.0 indicates a better fit.  Play with C<terms =E<gt> #> until these deviations are as close to 1.0 as possible, and beware overfitting.

=head1 SUBROUTINES

There is only one public subroutine, C<fit()>.  It B<must> be given either C<xydata> or C<xdata> and C<ydata> parameters.  All other paramters are optional.

It returns three values: A maximum deviation, the average deviation and the formula implementation.

=head2 Options

=over 4

=item C<fit(xdata =E<gt> \@xdata, ydata =E<gt> \@ydata)>

The data points the formula will fit.  Same as L<Algorithm::CurveFit> parameters of the same name.

=item C<fit(xydata =E<gt> [[1, 2, 3, 4], [10, 17, 26, 37]])>

=item C<fit(xydata =E<gt> [[1, 10], [2, 17], [3, 26], [4, 37]])>

A more convenient way to provide data points.  C<fit()> will try to detect how the data points are organized -- list of x and list of y, or list of [x,y].

=item C<fit(terms =E<gt> 3)>

Sets the order of the polynomial, which will be of the form C<k + a*x + b*x**2 + c*x**3 ...>.  The default is 3 and the limit is 10.

There is no need to specify initial C<k>.  It will be calculated from C<xydata>.

=item C<fit(time_limit =E<gt> 3)>

If a time limit is given (in seconds), C<fit()> will spend no more than that long trying to fit the data.  It may return in much less time.  The default is 3.

=item C<fit(iterations =E<gt> 10000)>

If an iteration count is given, C<fit()> will ignore any time limit and iterate up to C<iterations> times trying to fit the curve.  Same as L<Algorithm::CurveFit> parameter of the same name.

=item C<fit(inv =E<gt> 1)>

Setting C<inv> inverts the sense of the fit.  Instead of C<f(x) = y> the formula will fit C<f(y) = x>.

=item C<fit(impl_lang =E<gt> "perl")>

Sets the programming language in which the formula will be implemented.  Currently supported languages are C<"C">, C<"coderef"> and the default, C<"perl">.

When C<impl_lang =E<gt> "coderef"> is specified, a code reference is returned instead which may be used immediately by your perl script:

    my($max_dev, $avg_dev, $x2y) = fit(xydata => \@xy, impl_lang => "coderef");

    my $y = $x2y->(42);

More implementation languages will be supported in the future.

=item C<fit(impl_name =E<gt> "x2y")>

Sets the name of the function implementing the formula.  The default is C<"x2y">.  Has no effect when used with C<impl_lang =E<gt> "coderef")>.

    my($max_dev, $avg_dev, $src) = fit(xydata => \@xy, impl_name => "converto");

    print "$src\n";

    sub converto {
        my($x) = @_;
        my $y = -5340.93059104837 + 249.23009968947 * $x + -3.87745746448 * $x**2 + 0.02114780993 * $x**3;
        return $y;
    }

=item C<fit(bounds_check =E<gt> 1)>

When set, the implementation will include logic for checking whether the input is out-of-bounds, per the highest and lowest x points in the data used to fit the formula.  For implementation languages which support exceptions, an exception will be thrown.  For others (like C), C<-1.0> will be returned to indicate the error.

For instance, if the highest x in C<$xydata> is 83.0 and the lowest x is 60.0:

    my($max_dev, $avg_dev, $src) = fit(xydata => \@xy, bounds_check => 1);

    print "$src\n";

    sub x2y {
        my($x) = @_;
        die "x out of bounds (high)" if ($x > 83.80000000000);
        die "x out of bounds (low)"  if ($x < 60.80000000000);
        my $y = -5340.93059104837 + 249.23009968947 * $x + -3.87745746448 * $x**2 + 0.02114780993 * $x**3;
        return $y;
    }

=item C<fit(round_result =E<gt> 1)>

When set, the implementation will round the output to the nearest whole number.  When the implementation language is C<"C"> this adds an C<#include E<lt>math.hE<gt>> directive to the source code, which will have to be compiled against libm -- see C<man 3 round>.

    my($max_dev, $avg_dev, $src) = fit(xydata => \@xy, round_result => 1);

    print "$src\n";

    sub x2y {
        my($x) = @_;
        my $y = -5340.93059104837 + 249.23009968947 * $x + -3.87745746448 * $x**2 + 0.02114780993 * $x**3;
        $y = int($y + 0.5);
        return $y;
    }

=item C<fit(suppress_includes =E<gt> 1)>

When set and C<lang_impl =E<gt> "C">, any C<#include> directives which the implementation might need will be suppressed.

=back

=head1 VARIABLES

The class variable C<%STATS_H> contains various intermediate values which might be helpful.  For instance, C<$STATS_H{deviation_max_offset_datum}> contains the x data point which corresponds to the maximum deviation returned.

The contents of C<%STATS_H> is subject to change and might not be fully documented in future versions.  The current fields are:

=over 4

=item C<deviation_max_offset_datum>: The x data point corresponding with returned maximum deviation.

=item C<fit_calib_parar>: Arrayref of formula parameters as returned by L<Algorithm::CurveFit> after a short fitting attempt used for timing calibration.

=item C<fit_calib_time>: The number of seconds L<Algorithm::CurveFit> spent in the calibration run.

=item C<fit_iter>: The iterations parameter passed to L<Algorithm::CurveFit>.

=item C<fit_parar>: Arrayref of formula parameters as returned by L<Algorithm::CurveFit>.

=item C<fit_time>: The number of seconds L<Algorithm::CurveFit> actually spent fitting the formula.

=item C<impl_exception>: The exception thrown when the implementation was used to calculate the deviations, or the empty string if none.

=item C<impl_formula>: The formula part of the implementation.

=item C<impl_source>: The implementation source string.

=item C<iter_mode>: One of C<"time"> or C<"iter">, indicating whether a time limit was used or an iteration count.

=item C<xdata>: Arrayref of x data points as passed to L<Algorithm::CurveFit>.

=item C<ydata>: Arrayref of y data points as passed to L<Algorithm::CurveFit>.

=back

=head1 CAVEATS

=over 4

=item * Only simple polynomial functions are supported.  Sometimes you need something else.  Use L<Algorithm::CurveFit> for such cases.

=item * If C<xydata> is very large, iterating over it to calculate deviances can take more time than permitted by C<time_limit>.

=item * The dangers of overfitting are real!  L<https://en.wikipedia.org/wiki/Overfitting>

=item * Using too many terms can dramatically reduce the accuracy of the fitted formula.

=item * Sometimes calling L<Algorithm::CurveFit> with a ten-term polynomial causes it to hang.

=back

=head1 TO DO

=over 4

=item * Support more programming languages for formula implementation: R, MATLAB, python

=item * Calculate the actual term sigfigs and set precision appropriately in the formula implementation instead of just "%.11f".

=item * Support trying a range of terms and returning whatever gives the best fit.

=item * Support piecewise output formulas.

=item * Work around L<Algorithm::CurveFit>'s occasional hang problem when using ten-term polynomials.

=back

=head1 SEE ALSO

L<Algorithm::CurveFit>

L<curvefit>

=cut
