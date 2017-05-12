# Copyright 2007, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::Fisher;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;


# http://www.mesasoftware.com/technicalpapers.htm
# http://www.mesasoftware.com/Papers/USING%20THE%20FISHER%20TRANSFORM.pdf
#     Paper by John Elhers.
#
# http://www.linnsoft.com/tour/techind/fish.htm
#     Sample NYSE QQQ, August 2002.

sub longname   { __('Fisher Transform') }
sub shortname  { __('Fisher') }
sub manual     { __p('manual-node','Fisher Transform') }

use constant
  { type       => 'indicator',
    units      => 'Fisher',
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'fisher_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 10 },
                      ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Fisher bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

# val-smooth is alpha=0.33, which is 5 days
# fish-smooth is alpha=0.5, which is 3 days
#
use constant _warmup_ema =>
  (App::Chart::Series::Derived::EMA->warmup_count (5)
   + App::Chart::Series::Derived::EMA->warmup_count (3));
sub warmup_count {
  my ($class_or_self, $N) = @_;
  return $N + _warmup_ema - 1;
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  my $N = $self->{'N'};

  my $start = $parent->find_before ($lo, $self->warmup_count($N));
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $ema5_proc = App::Chart::Series::Derived::EMA->proc(5);
  my $ema3_proc = App::Chart::Series::Derived::EMA->proc(3);

  my @array;
  foreach my $i ($start .. $hi) {
    my $value = $p->[$i] // next;

    unshift @array, $value;
    if (@array > $N) { pop @array; }
    my $l = min (@array);
    my $h = max (@array);
    my $f = $h - $l;
    if ($f != 0) {
      $f = 2 * ($value - $l) / $f - 1;  # raw = -1 to +1
      $f = $ema5_proc->($f);
      $f = max (-0.999, min (0.999, $f)); # avoid full +/-1 infinities
      $f = log ((1 + $f) / (1 - $f));
      $f = $ema3_proc->($f);
    }
    if ($i >= $lo) {
      $s->[$i] = $f;
    }
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Fisher -- Fisher transformed range
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Fisher($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::EMA>
# 
# =cut
