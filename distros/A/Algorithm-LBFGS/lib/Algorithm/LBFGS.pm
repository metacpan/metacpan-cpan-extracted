package Algorithm::LBFGS;

use strict;
use warnings;

use XSLoader;

our $VERSION = '0.16';
XSLoader::load('Algorithm::LBFGS', $VERSION);

# constructor
sub new {
    my $class = shift;
    my %param = @_;
    my $self = bless { param => create_lbfgs_param() }, $class;
    $self->set_param(%param);
    return $self;
}

# destructor
sub DESTROY {
    my $self = shift;
    destroy_lbfgs_param($self->{param});
}

# set parameters
sub set_param {
    my $self = shift;
    my %param = @_;
    set_lbfgs_param($self->{param}, $_, $param{$_}) for keys %param;
}

# get parameters
sub get_param {
    my $self = shift;
    my $name = shift;
    return set_lbfgs_param($self->{param}, $name, undef);
}

# verbose monitor
my $verbose_monitor = sub {
    my ($x, $g, $fx, $xnorm, $gnorm, $step, $k, $ls, $user_data) = @_;
    ($fx, $xnorm, $gnorm, $step) = 
        map { sprintf("%g", $_) } ($fx, $xnorm, $gnorm, $step);
    my $hr = "=" x 79;
    my $s = ":";
    print <<MSG;
Iteration $k
$hr  
  f(x)             $s $fx
  || x ||          $s $xnorm
  || grad f(x) ||  $s $gnorm
  line search step $s $step
  evaluations num  $s $ls

MSG
    return 0;
};

# logging monitor
my $logging_monitor = sub {
    my ($x, $g, $fx, $xnorm, $gnorm, $step, $k, $ls, $user_data) = @_;
    push @$user_data, {
        x => $x, g => $g, fx => $fx, xnorm => $xnorm, gnorm => $gnorm,
	step => $step, k => $k, ls => $ls, user_data => $user_data
    };    
    return 0;
};

# do optimization
sub fmin {
    my $self = shift;
    my ($lbfgs_eval, $x0, $lbfgs_prgr, $user_data) = @_;
    if (defined($lbfgs_prgr)) {
        $lbfgs_prgr = $verbose_monitor if ($lbfgs_prgr eq 'verbose');
        $lbfgs_prgr = $logging_monitor if ($lbfgs_prgr eq 'logging');
    }
    my $instance =
        create_lbfgs_instance($lbfgs_eval, $lbfgs_prgr, $user_data);
    $self->{status} = status_2pv(do_lbfgs($self->{param}, $instance, $x0));
    destroy_lbfgs_instance($instance);
    return $x0;
}

# query status
sub get_status {
    my $self = shift;
    return $self->{status};
}

sub status_ok { return get_status(@_) == 0; }

1;

__END__

=head1 NAME

Algorithm::LBFGS - Perl extension for L-BFGS 

=head1 SYNOPSIS

  use Algorithm::LBFGS;

  # create an L-BFGS optimizer
  my $o = Algorithm::LBFGS->new;

  # f(x) = (x1 - 1)^2 + (x2 + 2)^2
  # grad f(x) = (2 * (x1 - 1), 2 * (x2 + 2));
  my $eval_cb = sub {
      my $x = shift;
      my $f = ($x->[0] - 1) * ($x->[0] - 1) + ($x->[1] + 2) * ($x->[1] + 2);
      my $g = [ 2 * ($x->[0] - 1), 2 * ($x->[1] + 2) ];
      return ($f, $g);
  };

  my $x0 = [0.0, 0.0]; # initial point
  my $x = $o->fmin($eval_cb, $x0); # $x is supposed to be [ 1, -2 ];

=head1 DESCRIPTION

L-BFGS (Limited-memory Broyden-Fletcher-Goldfarb-Shanno) is a quasi-Newton
method for unconstrained optimization. This method is especially efficient 
on problems involving a large number of variables.

Generally, it solves a problem described as following:

  min f(x), x = (x1, x2, ..., xn)

Jorge Nocedal wrote a Fortran 77 version of this algorithm.

L<http://www.ece.northwestern.edu/~nocedal/lbfgs.html>

And, Naoaki Okazaki rewrote it in pure C (liblbfgs).

L<http://www.chokkan.org/software/liblbfgs/index.html>

This module is a Perl port of Naoaki Okazaki's C version.

=head2 new

C<new> creates a L-BFGS optimizer with given parameters.

  my $o1 = new Algorithm::LBFGS(m => 5);
  my $o2 = new Algorithm::LBFGS(m => 3, eps => 1e-6);
  my $o3 = new Algorithm::LBFGS;

If no parameter is specified explicitly, their default values are used.

The parameter can be changed after the creation of the optimizer by 
L</"set_param">. Also, they can be queryed by L</"get_param">.

Please refer to the L</"List of Parameters"> for details about parameters.

=head2 get_param

Query the value of a parameter.

   my $o = Algorithm::LBFGS->new;
   print $o->get_param('epsilon'); # 1e-5

=head2 set_param

Change the values of one or several parameters.

   my $o = Algorithm::LBFGS->new;
   $o->set_param(epsilon => 1e-6, m => 7);

=head2 fmin

The prototype of L</"fmin"> is like

  x = fmin(evaluation_cb, x0, progress_cb, user_data)
  
As the name says, it finds a vector x which minimize the function f(x). 

L</"evaluation_cb"> is a ref to the evaluation callback subroutine, 
L</"x0"> is the initial point of the optimization algorithm,
L</"progress_cb"> (optional) is a ref to the progress callback subroutine,
and L</"user_data"> (optional) is a piece of extra data that client program
want to pass to both L</"evaluation_cb"> and L</"progress_cb">.

Client program can use L</"get_status"> to find if any problem occured
during the optimization after their calling L</"fmin">. When the status is 
L</"LBFGS_OK">, the returning value C<x> (array ref) contains the optimized
variables, otherwise, there may be some problems occured and the value in
the returning C<x> is undefined.

=head3 evaluation_cb

The ref to the evaluation callback subroutine. 

The evaluation callback subroutine is supposed to calculate the function
value and gradient vector at a specified point C<x>. It is called
automatically by L</"fmin"> when an evaluation is needed.

The client program need to make sure their evaluation callback subroutine
has a prototype like

  (f, g) = evaluation_cb(x, step, user_data)

C<x> (array ref) is the current values of variables, C<step> is the
current step of the line search routine, L</"user_data"> is the extra user 
data specified when calling L</"fmin">. 

The evaluation callback subroutine is supposed to return both the function
value C<f> and the gradient vector C<g> (array ref) at current C<x>.

=head3 x0

The initial point of the optimization algorithm.
The final result may depend on your choice of C<x0>.

NOTE: The content of C<x0> will be modified after calling L</"fmin">.
When the algorithm terminates successfully, the content of C<x0> will be 
replaced by the optimized variables, otherwise, the content of C<x0> is
undefined.


=head3 progress_cb

The ref to the progress callback subroutine.

The progress callback subroutine is called by L</"fmin"> at the end of each
iteration, with information of current iteration. It is very useful for a
client program to monitor the optimization progress. 

The client program need to make sure their progress callback subroutine
has a prototype like

  s = progress_cb(x, g, fx, xnorm, gnorm, step, k, ls, user_data)

C<x> (array ref) is the current values of variables. C<g> (array ref) is the
current gradient vector. C<fx> is the current function value. C<xnorm>
and C<gnorm> is the L2 norm of C<x> and C<g>. C<step> is the line-search
step used for this iteration. C<k> is the iteration count. C<ls> is the
number of evaluations in this iteration. L</"user_data"> is the extra
user data specified when calling L</"fmin">. 

The progress callback subroutine is supposed to return an indicating value
C<s> for L</"fmin"> to decide whether the optimization should continue or
stop. C<fmin> continues to the next iteration when C<s=0>, otherwise, it
terminates with status code L</"LBFGSERR_CANCELED">.

The client program can also pass string values to L</"progress_cb">, which
means it want to use a predefined progress callback subroutine. There are
two predefined progress callback subroutines, 'verbose' and 'logging'.
'verbose' just prints out all information of each iteration, while 'logging'
logs the same information in an array ref provided by L</"user_data">.

  ...

  # print out the iterations
  fmin($eval_cb, $x0, 'verbose'); 

  # log iterations information in the array ref $log
  my $log = [];

  fmin($eval_cb, $x0, 'logging', $log);
  
  use Data::Dumper;
  print Dumper $log;


=head3 user_data

The extra user data. It will be sent to both L</"evaluation_cb"> and
L<"progress_cb">.

=head2 get_status

Get the status of previous call of L</"fmin">.

  ...
  $o->fmin(...);

  # check the status
  if ($o->get_status eq 'LBFGS_OK') {
     ...
  }

  # print the status out
  print $o->get_status;

The status code is a string, which could be one of those in the
L</"List of Status Codes">.

=head2 status_ok

This is a shortcut of saying L</"get_status"> eq L</"LBFGS_OK">.

  ...

  if ($o->fmin(...), $o->status_ok) {
      ...
  }

=head2 List of Parameters

=head3 m

The number of corrections to approximate the inverse hessian matrix.

The L-BFGS algorithm stores the computation results of previous L</"m">
iterations to approximate the inverse hessian matrix of the current
iteration. This parameter controls the size of the limited memories
(corrections). The default value is 6. Values less than 3 are not
recommended. Large values will result in excessive computing time. 

=head3 epsilon

Epsilon for convergence test.

This parameter determines the accuracy with which the solution is to be
found. A minimization terminates when
  
  ||grad f(x)|| < epsilon * max(1, ||x||)

where ||.|| denotes the Euclidean (L2) norm. The default value is 1e-5. 

=head3 max_iterations

The maximum number of iterations.

The L-BFGS algorithm terminates an optimization process with
L</"LBFGSERR_MAXIMUMITERATION"> status code when the iteration count
exceedes this parameter. Setting this parameter to zero continues an
optimization process until a convergence or error. The default value is 0. 

=head3 max_linesearch

The maximum number of trials for the line search.

This parameter controls the number of function and gradients evaluations
per iteration for the line search routine. The default value is 20. 

=head3 min_step

The minimum step of the line search routine.

The default value is 1e-20. This value need not be modified unless the
exponents are too large for the machine being used, or unless the problem
is extremely badly scaled (in which case the exponents should be increased).

=head3 max_step

The maximum step of the line search.

The default value is 1e+20. This value need not be modified unless the
exponents are too large for the machine being used, or unless the problem
is extremely badly scaled (in which case the exponents should be increased).

=head3 ftol

A parameter to control the accuracy of the line search routine.

The default value is 1e-4. This parameter should be greater than zero and
smaller than 0.5. 

=head3 gtol

A parameter to control the accuracy of the line search routine.

The default value is 0.9. If the function and gradient evaluations are
inexpensive with respect to the cost of the iteration (which is sometimes
the case when solving very large problems) it may be advantageous to set
this parameter to a small value. A typical small value is 0.1. This
parameter shuold be greater than the ftol parameter (1e-4) and smaller than
1.0. 

=head3 xtol

The machine precision for floating-point values.

This parameter must be a positive value set by a client program to estimate
the machine precision. The line search routine will terminate with the
status code (L</"LBFGSERR_ROUNDING_ERROR">) if the relative width of the
interval of uncertainty is less than this parameter. 

=head3 orthantwise_c

Coeefficient for the L1 norm of variables.

This parameter should be set to zero for standard minimization problems.
Setting this parameter to a positive value minimizes the objective function
f(x) combined with the L1 norm |x| of the variables, f(x) + c|x|.
This parameter is the coeefficient for the |x|, i.e., c. As the L1
norm |x| is not differentiable at zero, the module modify function and
gradient evaluations from a client program suitably; a client program thus
have only to return the function value f(x) and gradients grad f(x) as
usual. The default value is zero. 

=head2 List of Status Codes

=head3 LBFGS_OK

No error occured.

=head3 LBFGSERR_UNKNOWNERROR

Unknown error.

=head3 LBFGSERR_LOGICERROR

Logic error.

=head3 LBFGSERR_OUTOFMEMORY

Insufficient memory.

=head3 LBFGSERR_CANCELED

The minimization process has been canceled.

=head3 LBFGSERR_INVALID_N

Invalid number of variables specified.

=head3 LBFGSERR_INVALID_N_SSE

Invalid number of variables (for SSE) specified.

=head3 LBFGSERR_INVALID_MINSTEP

Invalid parameter L</"max_step"> specified.

=head3 LBFGSERR_INVALID_MAXSTEP

Invalid parameter L</"max_step"> specified.

=head3 LBFGSERR_INVALID_FTOL

Invalid parameter L</"ftol"> specified.

=head3 LBFGSERR_INVALID_GTOL

Invalid parameter L</"gtol"> specified.

=head3 LBFGSERR_INVALID_XTOL

Invalid parameter L</"xtol"> specified.

=head3 LBFGSERR_INVALID_MAXLINESEARCH

Invalid parameter L</"max_linesearch"> specified.

=head3 LBFGSERR_INVALID_ORTHANTWISE

Invalid parameter L</"orthantwise_c"> specified.

=head3 LBFGSERR_OUTOFINTERVAL

The line-search step went out of the interval of uncertainty.

=head3 LBFGSERR_INCORRECT_TMINMAX

A logic error occurred; alternatively, the interval of uncertainty became
too small.

=head3 LBFGSERR_ROUNDING_ERROR

A rounding error occurred; alternatively, no line-search step satisfies
the sufficient decrease and curvature conditions.

=head3 LBFGSERR_MINIMUMSTEP

The line-search step became smaller than L</"min_step">.

=head3 LBFGSERR_MAXIMUMSTEP

The line-search step became larger than L</"max_step">.

=head3 LBFGSERR_MAXIMUMLINESEARCH

The line-search routine reaches the maximum number of evaluations.

=head3 LBFGSERR_MAXIMUMITERATION

The algorithm routine reaches the maximum number of iterations.

=head3 LBFGSERR_WIDTHTOOSMALL

Relative width of the interval of uncertainty is at most L</"xtol">.

=head3 LBFGSERR_INVALIDPARAMETERS

A logic error (negative line-search step) occurred.

=head3 LBFGSERR_INCREASEGRADIENT

The current search direction increases the objective function value. 

=head1 SEE ALSO

L<PDL>, L<PDL::Opt::NonLinear>

=head1 AUTHOR

Laye Suen, E<lt>laye@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1990, Jorge Nocedal

Copyright (C) 2007, Naoaki Okazaki

Copyright (C) 2008, Laye Suen

This library is distributed under the term of the MIT license.

L<http://opensource.org/licenses/mit-license.php>

=head1 REFERENCE

=over

=item
J. Nocedal. Updating Quasi-Newton Matrices with Limited Storage (1980)
, Mathematics of Computation 35, pp. 773-782.

=item
D.C. Liu and J. Nocedal. On the Limited Memory Method for Large Scale
Optimization (1989), Mathematical Programming B, 45, 3, pp. 503-528.

=item
Jorge Nocedal's Fortran 77 implementation,
L<http://www.ece.northwestern.edu/~nocedal/lbfgs.html>

=item
Naoaki Okazaki's C implementation (liblbfgs),
L<http://www.chokkan.org/software/liblbfgs/index.html>

=back

=cut
