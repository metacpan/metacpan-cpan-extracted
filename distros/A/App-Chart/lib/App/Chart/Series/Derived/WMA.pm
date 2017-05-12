# Copyright 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::WMA;
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

# http://www.linnsoft.com/tour/techind/movAvg.htm
#     Formula, and sample WMA N=20 on Nasdaq 100 (symbol QQQ, yahoo now in
#     ^IXIC) from 2001.
#

sub longname   { __('WMA - Weighted MA') }
sub shortname  { __('WMA') }
sub manual     { __p('manual-node','Weighted Moving Average') }

use constant
  { priority   => 11,
    type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'wma_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "WMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
*warmup_count = \&App::Chart::Series::Derived::SMA::warmup_count;  # $N-1

sub proc {
  my ($class_or_self, $N) = @_;
  return App::Chart::Series::Calculation::ma_proc_by_weights (reverse 1 .. $N);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::WMA -- weighted moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->WMA($N);
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


# with accumulated sums ...
#
# (define*-public (wma-calc-proc count #:optional (data '()))
#   (set! data (take-right-maybe data count))
# 
#   ;; SUM is plain sum of DATA
#   ;; WSUM is weighted sum of DATA
#   ;; POINTS is number of non-#f in DATA
#   ;; DIV is divisor for weighting in DATA
#   ;; DIV-MIN is minimum DIV for valid result
# 
#   (let* ((points  (length data))
# 	 (sum     (apply + data))
# 	 (wsum    (dot-product data (iota points (1+ (- count points)))))
# 	 (div     (exact->inexact ;; avoid exact fraction in guile 1.8
# 		   (- (triangular count) (triangular (- count points)))))
# 	 (div-min (ceiling-exact (* indicator-minimum-fraction
# 				    (triangular count)))))
#     (set! data (indicator-circular count data))
# 
#     (lambda  (x)
# 
#       ;; drop old point, including one less of each in DATA
#       (set! wsum (- wsum sum))
#       (if (car data)
# 	  (set! sum (- sum (car data)))
# 	  (begin
# 	    (set! div    (+ div (- count points)))
# 	    (set! points (1+ points))))
# 
#       ;; hold this point
#       (set-car! data x)
#       (set! data (cdr data))
# 
#       ;; add this point
#       (set! sum  (+ sum x))
#       (set! wsum (+ wsum (* x count)))
#       
#       (and (>= div div-min)
# 	   (/ wsum div)))))
