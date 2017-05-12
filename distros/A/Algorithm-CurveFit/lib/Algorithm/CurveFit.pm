package Algorithm::CurveFit;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.05';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    'all' => [ qw( curve_fit ) ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

use Carp qw/confess/;
use Math::Symbolic qw/parse_from_string/;
use Math::MatrixReal;
use Data::Dumper;

# machine epsilon
use constant EPS => 2.2e-16;
use constant SQRT_EPS => sqrt(EPS);

sub curve_fit {
    shift @_ if not ref $_[0] and defined $_[0] and $_[0] eq 'Algorithm::CurveFit';

    confess('Uneven number of arguments to Algorithm::CurveFit::curve_fit.')
      if @_ % 2;

    my %args = @_;

    # Formula
    confess("Missing 'formula' parameter.") if not defined $args{formula};
    my $formula;
    if (ref($args{formula}) =~ /^Math::Symbolic/) {
        $formula = $args{formula};
    }
    else {
        eval { $formula = parse_from_string( $args{formula} ); };
        confess( "Cannot parse formula '" . $args{formula} . "'. ($@)" )
          if not defined $formula or $@;
    }

    # Variable (optional)
    my $variable = $args{variable};
    $variable = 'x' if not defined $variable;
    confess("Formula '"
          . $args{formula}
          . "' not explicitly dependent on "
          . "variable '$variable'." )
      if not grep { $_ eq $variable } $formula->explicit_signature();

    # Parameters
    my $params = $args{params};

	confess("Parameter 'params' has to be an array reference.")
      if not defined $params
      or not ref($params) eq 'ARRAY';
    my @parameters = @$params;
    confess('No parameters specified.') if not @parameters;
    confess('Individual parameters need to be array references.')
      if grep { not defined $_ or not ref($_) eq 'ARRAY' } @parameters;
    foreach my $p (@parameters) {
        confess("Weird parameter\n'"
              . Dumper($p)
              . "' Should have the format\n"
              . "[ NAME_STRING, GUESSED_VALUE, ACCURACY ]\n"
              . "With the accuracy being optional. See docs." )
          if @$p > 3
          or @$p < 2
          or grep { not defined $_ } @$p;

        confess("Formula '"
              . $args{formula}
              . "' not explicitly dependent on "
              . "parameter '"
              . $p->[0]
              . "'." )
          if not grep { $_ eq $p->[0] } $formula->explicit_signature();
    }

    # XData
    my $xdata = $args{xdata};
    confess('X-Data missing.')
      if not defined $xdata
      or not ref($xdata) eq 'ARRAY'
      or not @$xdata;
    my @xdata = @$xdata;

    # YData
    my $ydata = $args{ydata};
    confess('Y-Data missing.')
      if not defined $ydata
      or not ref($ydata) eq 'ARRAY'
      or not @$ydata;
    confess('Y-Data and X-Data need to have the same number of elements.')
      if not @$ydata == @xdata;
    my @ydata = @$ydata;

    # Max_Iter (optional)
    my $max_iter = $args{maximum_iterations};
    $max_iter = 0 if not defined $max_iter;

    # Add third element (dlamda) to parameter arrays in case they're missing.
    foreach my $param (@parameters) {
        push @$param, 0 if @$param < 3;
    }

    # Array holding all first order partial derivatives of the function in respect
    # to the parameters in order.
    my @derivatives;
    my @param_names = ($variable, map {$_->[0]} @parameters);
    foreach my $param (@parameters) {
        my $deriv =
          Math::Symbolic::Operator->new( 'partial_derivative', $formula,
            $param->[0] );
        $deriv = $deriv->simplify()->apply_derivatives()->simplify();
        my ($sub, $trees) = Math::Symbolic::Compiler->compile_to_sub($deriv, \@param_names);
        if ($trees) {
            push @derivatives, $deriv; # residual trees, need to evaluate
        } else {
            push @derivatives, $sub;
        }
    }

    # if not compilable, close over a ->value call for convenience later on
    my $formula_sub = do {
        my ($sub, $trees) = Math::Symbolic::Compiler->compile_to_sub($formula, \@param_names);
        $trees
        ? sub {
              $formula->value(
                map { ($param_names[$_] => $_[$_]) } 0..$#param_names
              )
          }
        : $sub
    };

    my $dbeta;

    # Iterative approximation of the parameters
    my $iteration = 0;

    # As long as we're under max_iter or maxiter==0
    while ( !$max_iter || ++$iteration < $max_iter ) {
        # Generate Matrix A
        my @cols;
        my $pno = 0;
        my @par_values = map {$_->[1]} @parameters;
        foreach my $param (@parameters) {
            my $deriv = $derivatives[ $pno++ ];

            my @ary;
            if (ref $deriv eq 'CODE') {
                foreach my $x ( 0 .. $#xdata ) {
                    my $xv = $xdata[$x];
                    my $value = $deriv->($xv, @par_values);
                    if (not defined $value) { # fall back to numeric five-point stencil
                        my $h = SQRT_EPS*$xv; my $t = $xv + $h; $h = $t-$xv; # numerics. Cf. NR
                        $value = $formula_sub->($xv, @parameters)
                    }
                    push @ary, $value;
                }
            }
            else {
                $deriv = $deriv->new; # better safe than sorry
                foreach my $x ( 0 .. $#xdata ) {
                    my $xv = $xdata[$x];
                    my $value = $deriv->value(
                      $variable => $xv,
                      map { ( @{$_}[ 0, 1 ] ) } @parameters # a, guess
                    );
                    if (not defined $value) { # fall back to numeric five-point stencil
                        my $h = SQRT_EPS*$xv; my $t = $xv + $h; $h = $t-$xv; # numerics. Cf. NR
                        $value = $formula_sub->($xv, @parameters)
                    }
                    push @ary, $value;
                }
            }
            push @cols, \@ary;
        }

        # Prepare matrix of datapoints X parameters
        my $A = Math::MatrixReal->new_from_cols( \@cols );

        # transpose
        my $AT = ~$A;
        my $M  = $AT * $A;

        # residuals
        my @beta =
          map {
            $ydata[$_] - $formula_sub->(
                $xdata[$_],
                map { $_->[1] } @parameters
              )
          } 0 .. $#xdata;
        $dbeta = Math::MatrixReal->new_from_cols( [ \@beta ] );

        my $N = $AT * $dbeta;

        # Normalize before solving => better accuracy.
        my ( $matrix, $vector ) = $M->normalize($N);

        # solve
        my $LR = $matrix->decompose_LR();
        my ( $dim, $x, $B ) = $LR->solve_LR($vector);

        # extract parameter modifications and test for convergence
        my $last = 1;
        foreach my $pno ( 1 .. @parameters ) {
            my $dlambda = $x->element( $pno, 1 );
            $last = 0 if abs($dlambda) > $parameters[ $pno - 1 ][2];
            $parameters[ $pno - 1 ][1] += $dlambda;
        }
        last if $last;
    }

    # Recalculate dbeta for the squared residuals.
    my @beta =
      map {
        $ydata[$_] - $formula_sub->(
            $xdata[$_],
            map { $_->[1] } @parameters
          )
      } 0 .. $#xdata;
    $dbeta = Math::MatrixReal->new_from_cols( [ \@beta ] );

    my $square_residual = $dbeta->scalar_product($dbeta);
    return $square_residual;
}

1;
__END__

=head1 NAME

Algorithm::CurveFit - Nonlinear Least Squares Fitting

=head1 SYNOPSIS

use Algorithm::CurveFit;

  # Known form of the formula
  my $formula = 'c + a * x^2';
  my $variable = 'x';
  my @xdata = read_file('xdata'); # The data corresponsing to $variable
  my @ydata = read_file('ydata'); # The data on the other axis
  my @parameters = (
      # Name    Guess   Accuracy
      ['a',     0.9,    0.00001],  # If an iteration introduces smaller
      ['c',     20,     0.00005],  # changes that the accuracy, end.
  );
  my $max_iter = 100; # maximum iterations

  my $square_residual = Algorithm::CurveFit->curve_fit(
      formula            => $formula, # may be a Math::Symbolic tree instead
      params             => \@parameters,
      variable           => $variable,
      xdata              => \@xdata,
      ydata              => \@ydata,
      maximum_iterations => $max_iter,
  );

  use Data::Dumper;
  print Dumper \@parameters;
  # Prints
  # $VAR1 = [
  #          [
  #            'a',
  #            '0.201366784209602',
  #            '1e-05'
  #          ],
  #          [
  #            'c',
  #            '1.94690440147554',
  #            '5e-05'
  #          ]
  #        ];
  #
  # Real values of the parameters (as demonstrated by noisy input data):
  # a = 0.2
  # c = 2

=head1 DESCRIPTION

C<Algorithm::CurveFit> implements a nonlinear least squares curve fitting
algorithm. That means, it fits a curve of known form (sine-like, exponential,
polynomial of degree n, etc.) to a given set of data points.

For details about the algorithm and its capabilities and flaws, you're
encouraged to read the MathWorld page referenced below. Note, however, that it
is an iterative algorithm that improves the fit with each iteration until it
converges. The following rule of thumb usually holds true:

=over 2

=item

A good guess improves the probability of convergence and the quality
of the fit.

=item

Increasing the number of free parameters decreases the quality and
convergence speed.

=item

Make sure that there are no correlated parameters such as in 'a + b * e^(c+x)'.
(The example can be rewritten as 'a + b * e^c * e^x' in which 'c' and 'b' are
basically equivalent parameters.

=back

The curve fitting algorithm is accessed via the 'curve_fit' subroutine.
It requires the following parameters as 'key => value' pairs:

=over 2

=item formula

The formula should be a string that can be parsed by Math::Symbolic.
Alternatively, it can be an existing Math::Symbolic tree.
Please refer to the documentation of that module for the syntax.

Evaluation of the formula for a specific value of the variable (X-Data)
and the parameters (see below) should yield the associated Y-Data value
in case of perfect fit.

=item variable

The 'variable' is the variable in the formula that will be replaced with the
X-Data points for evaluation. If omitted in the call to C<curve_fit>, the
name 'x' is default. (Hence 'xdata'.)

=item params

The parameters are the symbols in the formula whose value is varied by the
algorithm to find the best fit of the curve to the data. There may be
one or more parameters, but please keep in mind that the number of parameters
not only increases processing time, but also decreases the quality of the fit.

The value of this options should be an anonymous array. This array should
hold one anonymous array for each parameter. That array should hold (in order)
a parameter name, an initial guess, and optionally an accuracy measure.

Example:

  $params = [
    ['parameter1', 5,  0.00001],
    ['parameter2', 12, 0.0001 ],
    ...
  ];

  Then later:
  curve_fit(
  ...
    params => $params,
  ...
  );

The accuracy measure means that if the change of parameters from one iteration
to the next is below each accuracy measure for each parameter, convergence is
assumed and the algorithm stops iterating.

In order to prevent looping forever, you are strongly encouraged to make use of
the accuracy measure (see also: maximum_iterations).

The final set of parameters is B<not> returned from the subroutine but the
parameters are modified in-place. That means the original data structure will
hold the best estimate of the parameters.

=item xdata

This should be an array reference to an array holding the data for the
variable of the function. (Which defaults to 'x'.)

=item ydata

This should be an array reference to an array holding the function values
corresponding to the x-values in 'xdata'.

=item maximum_iterations

Optional parameter to make the process stop after a given number of iterations.
Using the accuracy measure and this option together is encouraged to prevent
the algorithm from going into an endless loop in some cases.

=back

The subroutine returns the sum of square residuals after the final iteration
as a measure for the quality of the fit.

=head2 EXPORT

None by default, but you may choose to export C<curve_fit> using the
standard Exporter semantics.

=head2 SUBROUTINES

This is a list of public subroutines

=over 2

=item curve_fit

This subroutine implements the curve fitting as explained in
L<DESCRIPTION> above.

=back

=head1 NOTES AND CAVEATS

=over 2

=item *

When computing the derivative symbolically using C<Math::Symbolic>, the
formula simplification algorithm can sometimes fail to find the equivalent
of C<(x-x_0)/(x-x_0)>. Typically, these would be hidden in a more complex
product. The effect is that for C<x -E<gt> x_0>, the evaluation of the
derivative becomes undefined.

Since version 1.05, we fall back to numeric differentiation
using five-point stencil in such cases. This should help with one of the
primary complaints about the reliability of the module.

=item *

This module is NOT fast.
For slightly better performance, the formulas are compiled to
Perl code if possible.

=back

=head1 SEE ALSO

The algorithm implemented in this module was taken from:

Eric W. Weisstein. "Nonlinear Least Squares Fitting." From MathWorld--A Wolfram Web Resource. http://mathworld.wolfram.com/NonlinearLeastSquaresFitting.html

New versions of this module can be found on http://steffen-mueller.net or CPAN.

This module uses the following modules. It might be a good idea to be familiar
with them. L<Math::Symbolic>, L<Math::MatrixReal>, L<Test::More>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
