# Copyright 2004, 2005, 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::Stochastics;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;
use App::Chart::Series::Derived::WilliamsR;


sub longname   { __('Stochastics %K/%D') }
sub shortname  { __('%R') }
sub manual     { __p('manual-node','Stochastics') }

use constant
  { type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    hlines     => [ 20, 80 ],
    parameter_info => [ { name    => __('%K Days'),
                          key     => 'stochastics_K_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 14 },
                        { name    => __('%D Days'),
                          key     => 'stochastics_D_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 3 },
                        { name    => __('Slow Days'),
                          key     => 'stochastics_slow_days',
                          type    => 'integer',
                          minimum => 0,
                          default => 0 }],

    line_colours => { K => App::Chart::DOWN_COLOUR(),
                      D => App::Chart::UP_COLOUR() },
  };

sub new {
  my ($class, $parent, $K_count, $D_count, $slow_count) = @_;

  $K_count    //= parameter_info()->[0]->{'default'};
  $D_count    //= parameter_info()->[1]->{'default'};
  $slow_count //= parameter_info()->[2]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $K_count, $D_count, $slow_count ],
     arrays     => { K => [],
                     D => [] },
     array_aliases => { values => 'K' });
}

sub name {
  my ($self) = @_;
  my ($K_count, $D_count, $slow_count) = @{$self->{'parameters'}};
  if ($slow_count == 0) {
    return __x('%K {K_count}, %D {D_count}, no slow',
               K_count => $K_count,
               D_count => $D_count);
  } else {
    return __x('%K {K_count}, %D {D_count}, slow {slow_count}',
               K_count => $K_count,
               D_count => $D_count,
               slow_count => $slow_count);
  }
}

sub warmup_count {
  my ($self_or_class, $K_count, $D_count, $slow_count) = @_;
  return $K_count
    + max (1, $slow_count) - 1
      + $D_count - 1;
}

sub proc {
  my ($class_or_self, $K_count, $D_count, $slow_count) = @_;
  my $williams_proc = App::Chart::Series::Derived::WilliamsR->proc($K_count);
  my $slow_proc = App::Chart::Series::Derived::SMA->proc($slow_count);
  my $sma_proc = App::Chart::Series::Derived::SMA->proc($D_count);

  return sub {
    my ($high, $low, $close) = @_;

    my $K = $slow_proc->($williams_proc->(@_) + 100);  # 0 to 100
    my $D = $sma_proc->($K);
    return ($K, $D);
  };
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($start, $hi);
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;

  my $sk = $self->array('K');
  my $sd = $self->array('D');
  $hi = min ($hi, $#$p);
  if ($#$sk < $hi) { $#$sk = $hi; }  # pre-extend
  if ($#$sd < $hi) { $#$sd = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $close = $p->[$i] // next;
    $proc->($ph->[$i], $pl->[$i], $close);
  }
  foreach my $i ($lo .. $hi) {
    my $close = $p->[$i] // next;
    ($sk->[$i], $sd->[$i]) = $proc->($ph->[$i], $pl->[$i], $close);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Stochastics -- stochastics %K and %D
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Stochastics($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>
# 
# =cut
