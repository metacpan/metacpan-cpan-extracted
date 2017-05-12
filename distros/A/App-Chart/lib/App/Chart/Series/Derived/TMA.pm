# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Series::Derived::TMA;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');
use Math::Trig ();

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::SMA;

use constant DEBUG => 0;

# http://www.linnsoft.com/tour/techind/movAvg.htm
#     Formula, and sample TMA N=20 on Nasdaq 100 (symbol QQQ, yahoo now in
#     ^IXIC) from 2001.
#



sub longname   { __('TMA - Triangular MA') }
sub shortname  { __('TMA') }
sub manual     { __p('manual-node','Triangular Moving Average') }

use constant
  { priority   => -10,
    type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'tma_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;
  ### TMA new(): @_

  $N //= $class->parameter_info->[0]->{'default'};
  ($N > 0) || croak "TMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

sub proc {
  my ($self_or_class, $N) = @_;
  # eg. N=5 gives 1, 2, 3, 2, 1
  # eg. N=6 gives 1, 2, 3, 3, 2, 1
  return App::Chart::Series::Calculation::ma_proc_by_weights
    (1 .. int($N/2), (reverse 1 .. int(($N+1)/2)));
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::TMA -- triangular moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->TMA($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::SMA>,
# L<App::Chart::Series::Derived::SineMA>
# 
# =cut



# Old stuff done with a adjusting totals instead of vector product each time
# ...
#
# (define-public (tma-calc-proc count)
# 
#   ;; FACTORS is the weight factors, like '(1 2 3 2 1), stepped along to
#   ;;         build the divisor while the window isn't yet full
#   ;;
#   ;; DATA is a circular list of the accumulated window
#   ;;
#   ;; TOTAL is the sum of the DATA values with weighting factors applied
#   ;;
#   ;; STEP is how much to add to TOTAL to adjust for moving the DATA one
#   ;;      place along
#   ;;
#   ;; F-DATA and C-DATA are positions in DATA where the value stops adding
#   ;;        and starts subtracting, as it reaches its peak weighting then
#   ;;        starts decreasing
#   ;; 
#   (let* ((c-count (quotient (1+ count) 2))  ;; ceil(N/2)
# 	 (factors (tma-factors count))
# 	 (div-min (ceiling-exact (* indicator-minimum-fraction
# 				    (apply + factors))))
# 	 (div     0)
# 	 (total   0)
# 	 (step    0)
# 	 (data    (make-circular-list count #f))
# 	 (f-data  (list-cdr-ref data c-count)) ;; measured from other end
# 	 (c-data  (if (odd? count)
# 		      f-data
# 		      (cdr f-data))))
# 
#     (lambda  (x)
#       ;; shift up past points, and add in new point
#       (set! total (+ total step x))
#       (set! step (+ step x))
# 
#       (if (car data)
# 	  ;; window full, drop oldest point out of stepping
# 	  (set! step (+ step (car data)))
# 
# 	  ;; window not yet full, increase divisor for new point
# 	  (begin
# 	    (set! div (+ div (first factors)))
# 	    (set! factors (cdr factors))))
# 
#       ;; replace oldest point with new point
#       (set-car! data x)
#       (set! data (cdr data))
# 
#       ;; at floor(N/2) point stops adding
#       (if (car f-data)
# 	  (set! step (- step (car f-data))))
#       (set! f-data (cdr f-data))
# 
#       ;; at ceil(N/2) point starts subtracting
#       (if (car c-data)
# 	  (set! step (- step (car c-data))))
#       (set! c-data (cdr c-data))
# 
#       (and (>= div div-min)
# 	   (exact->inexact (/ total div))))))
