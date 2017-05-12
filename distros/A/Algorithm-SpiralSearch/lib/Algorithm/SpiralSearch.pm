package Algorithm::SpiralSearch;

#use 5.004;
use strict;
use warnings;
use Carp;
#use Math::Gradient 0.01;
use Math::Gradient;


require Exporter;

our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw(spiral_search);
our $VERSION     = '1.20';

sub spiral_search {
   my $usage = '($opt_x, $opt_y) = spiral_search($lower_boundx,$upper_boundx,' .
               '$lower_boundy,$upper_boundy,$iterations,$function,' .
               "'MAX|MIN')";

   my ($lbx, $ubx, $lby, $uby, $iters, $f, $max_or_min) = @_;

   croak 'A valid input/output funtion reference must be passed in'
      unless $f =~ /CODE/;

   croak 'Two or more iterations are required : ' if $iters < 2;
   croak 'Upper boundary on first parameter must be non-zero : ' if $ubx == 0.0;
   croak 'Upper boundary on second parameter must be non-zero : '
      if $uby == 0.0;

   croak 'Final parameter must be set to MAX or MIN : '
      unless $max_or_min =~ /MAX|MIN/i;

   # Set the initial start points to half the distances of the search space
   # extrema.
   my $x_init = ($ubx - $lbx) / 2;
   my $y_init = ($uby - $lby) / 2;

   # Find the gradients of each axis.
   my @grad_x = Math::Gradient::gradient($lbx, $ubx, $iters);
   my @grad_y = Math::Gradient::gradient($lby, $uby, $iters);

   my @x             = ();
   my @y             = ();
   my @nrv_ary       = ();
   my $x_inc         = $grad_x[1] - $grad_x[0];
   my $y_inc         = $grad_y[1] - $grad_y[0];
   my $maximize      = $max_or_min =~ /^\s*MIN\s*$/i ? -1 : 1;
   my $ret_val       = 0;
   my $new_ret_val   = 0;
   my $theta         = 0;
   my $best_x        = 0;
   my $best_y        = 0;
   my $out_of_bounds = 0;

   # Increase the radius of the search by the following factor
   # if a better function evaluation is not found.
   my $rad_inc  = 1.2;

   my $bounded  = 1;
   my $radius_x = 1;
   my $radius_y = 1;

   for (my $t = $iters; $t >= 1; $t--) {
      # Follow the spiral inwards.
      $theta   = atan2($grad_y[$t-1], $grad_x[$t-1]);
      $x[$t-1] = $x_init + $radius_x * exp(-0.1 * $theta) * cos($t);
      $y[$t-1] = $y_init + $radius_y * exp(-0.1 * $theta) * sin($t);

      # Make sure our spiral is within boundaries.
      if ($bounded) {
         if ($x[$t-1] < $lbx || $x[$t-1] > $ubx || $y[$t-1] < $lby ||
             $y[$t-1] > $uby)
         {
            $out_of_bounds = 1;
         } else {
            $out_of_bounds = 0;
         }
      }

      # If our new evaluation point is out of bounds, do not proceed with the
      # function evaluation.  Otherwise, continue.
      if (! $out_of_bounds) {
         # Evaluate the new parameters.
         $nrv_ary[$t-1] = $new_ret_val = &{$f}($x[$t-1], $y[$t-1]);

         # If the new result was better than the previous, increase the spiral's
         # radius.
         if ($maximize * $new_ret_val > $maximize * $ret_val) {
            $radius_x += $rad_inc * $x_inc;
            $radius_y += $rad_inc * $y_inc;

            $x_init = $x[$t-1];
            $y_init = $y[$t-1];
         }

         $ret_val = $new_ret_val;
      } else {
         $nrv_ary[$t-1] = 0;
      }
   }

   # Find the best return value and its corresponding input coordinates.
   {
      my $m = 0;

      for (my $i = 0; $i < @nrv_ary; $i++) {
         if ($maximize * $nrv_ary[$i] >= $maximize * $m) {
            $best_x = $x[$i];
            $best_y = $y[$i];
            $m      = $nrv_ary[$i];
         }
      }
   }

   return($best_x, $best_y);
}

1;

__END__

=head1 NAME

Algorithm::SpiralSearch - Function Optimization of Two Parameters

=head1 SYNOPSIS

  use Algorithm::SpiralSearch;

  my $lbx   = 0;
  my $ubx   = 1000;
  my $lby   = 0;
  my $uby   = 1000;
  my $iters = 50;
  my ($x, $y) = spiral_search($lbx, $ubx, $lby, $uby, $iters, \&f, 'MAX');

  sub f {
    my ($p1, $p2) = @_;
    my $ret = simulator($p1, $p2, ...);
    return $ret;
  }

=head1 DESCRIPTION

A spiral search is a method used to optimize a two-parameter, relatively,
well-behaved function. Boundary conditions, the maximum number of iterations, a
reference to a function, and an indicator to maximize or minimize the function
are passed to the spiral_search function.  spiral_search() returns the optimal
point in the function passed to it.  It's an elegant optimization algorithm, but
is not well-suited for most applications. SETI uses the spiral search in huntingfor strong radio signals. Spiral search is most effective in situations where
function evaluations are expensive and where there's a small amount of random
noise within the search space. The algorithm is of order O(n).

=head1 METHODS

=head2 Search Methods

B<spiral_search($lowerBound_x, $upperBound_x, $lowerBound_y, $upperBound_y,
   $iterations, \&function, $MAX_or_MIN)>

Initiates the spiral search. The first four parameters define the search space
plane. Spiral search is of order O(n), so the number of iterations defines how
many refinements the algorithm should take into account.  The greater the numberof iterations, the more accurate the findings.

The sixth parameter should be a reference to a function for which the parameters
will be plugged into. This function should return only one value - a scalar
output indicative of the accuracy of the inputs. The last input parameter shouldbe either one of the two strings 'MAX' or 'MIN', each corresponding to how
spiral_search will optimize its given function. spiral_search returns a pair of
parameters that are approximately optimal with respect to the given function.

=head1 AUTHOR

Sean Mostafavi, E<lt>seanm@undersea.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Sean Mostafavi

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.8.5 or, at your option, anylater version of Perl 5 you may have available.

=cut
