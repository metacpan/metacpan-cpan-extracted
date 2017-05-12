# Copyright 2006, 2007, 2009 Kevin Ryde

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

package App::Chart::Series::Derived::SwingIndex;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::RSI;
use App::Chart::Series::Derived::TypicalPrice;


# http://www.ensignsoftware.com/espl/espl71.htm
#     Code for swing index, ASI part confusing though.
#
# http://www.investopedia.com/articles/technical/02/100702.asp
#     Sample chart of Apple (AAPL).
#


sub longname   { __('Swing Index') }
sub shortname  { __('Swing') }
sub manual     { __p('manual-node','Accumulative Swing Index') }

use constant
  { priority   => -10,
    type       => 'indicator',
    units      => 'swing_index',
    hlines     => [ 0 ],
    parameter_info => [ ],
  };

sub new {
  my ($class, $parent) = @_;

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ ],
     arrays     => { values => [] },
     array_aliases => { });
}
use constant warmup_count => 1;

sub swing_index_calc {
  my ($prev_open, $prev_close, $open, $high, $low, $close) = @_;

  $prev_open //= $prev_close;
  $open //= $close;
  $high //= $close;
  $low  //= $close;

  my $r1 = abs ($high - $prev_close);
  my $r2 = abs ($low  - $prev_close);
  my $r3 = $high - $low;
  my $r4 = abs ($prev_close - $prev_open);
  my $k  = max ($r1, $r2);
  my $r;
  if ($r1 >= max($r2,$r3)) {
    $r = $r1 - 0.5*$r2 + 0.25*$r4;
  } elsif ($r2 >= max($r1,$r3)) {
    $r = $r2 - 0.5*$r1 + 0.25*$r4;
  } else {
    $r = $r3 + 0.25*$r4;
  }
  if ($r == 0) { return 0; }

  return ($k
          * (($close - $prev_close)
             + 0.5  * ($close - $open)
             + 0.25 * ($prev_close - $prev_open))
          / $r);
}

sub proc {
  my ($class_or_self) = @_;
  my ($prev_open, $prev_close);

  return sub {
    my ($open, $high, $low, $close) = @_;

    my $swing;
    if (defined $prev_close) {
      $swing = swing_index_calc ($prev_open, $prev_close,
                                 $open, $high, $low, $close);
    }
    $prev_open  = $open;
    $prev_close = $close;
    return $swing;
  };
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  my $warmup_count = $self->warmup_count_for_position ($lo);
  my $start = $parent->find_before ($lo, $warmup_count);
  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;
  my $po = $parent->array('opens') || [];
  my $ph = $parent->array('highs') || [];
  my $pl = $parent->array('lows')  || [];

  my $s = $self->values_array;
  $hi = min ($hi, $#$p);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my $proc = $self->proc(@{$self->{'parameters'}});

  foreach my $i ($start .. $lo-1) {
    my $close = $p->[$i] // next;
    $proc->($po->[$i], $ph->[$i], $pl->[$i], $close);
  }
  foreach my $i ($lo .. $hi) {
    my $close = $p->[$i] // next;
    $s->[$i] = $proc->($po->[$i], $ph->[$i], $pl->[$i], $close);
  }
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::SwingIndex -- raw Accumulative Swing Index elements
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->SwingIndex();
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::ASI>
# 
# =cut
