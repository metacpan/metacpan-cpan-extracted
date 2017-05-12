# Copyright 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::TII;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::SMA;


# http://www.linnsoft.com/tour/techind/tii.htm
#     Sample Intel (INTC) 2001/2001, seems different to what get from the
#     code here.  Maybe not 60/30 parameters?
#
# http://working-money.com/Documentation/FEEDbk_docs/Archive/062002/Abstracts_new/Pee/pee.html
#     Start of article, rest for sale.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/062002/TradersTips/TradersTips.html
#     TASC Trader's Tips June 2002.
#     Linnsoft sample MSFT from Sep 2001.
#


sub longname   { __('TII - Trend Intensity Index') }
sub shortname  { __('TII') }
sub manual     { __p('manual-node','Trend Intensity Index') }

use constant
  { hlines     => [ 20, 50, 80 ],
    type       => 'indicator',
    units      => 'percentage',
    minimum    => 0,
    maximum    => 100,
    parameter_info => [ { name     => __('MA Days'),
                          key      => 'tii_ma_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 60 },
                        { name     => __('Dev Days'),
                          key      => 'tii_dev_days',
                          type     => 'integer',
                          minimum  => 1,
                          default  => 30 }],
  };

sub new {
  my ($class, $parent, $N_ma, $N_dev) = @_;

  $N_ma //= parameter_info()->[0]->{'default'};
  ($N_ma > 0) || croak "TII bad N_ma: $N_ma";

  $N_dev //= parameter_info()->[1]->{'default'};
  ($N_dev > 0) || croak "TII bad N_dev: $N_dev";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N_ma, $N_dev ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($class_or_self, $N_ma, $N_dev) = @_;
  return max($N_ma,$N_dev) - 1;
}
sub proc {
  my ($class_or_self, $N_ma, $N_dev) = @_;

  my $ma_proc = App::Chart::Series::Derived::SMA->proc ($N_ma);
  my @values;

  return sub {
    my ($value) = @_;

    my $ma = $ma_proc->($value);
    unshift @values, $value;
    if (@values >= $N_dev) { pop @values; }

    my $num = 0;
    my $den = 0;
    foreach my $value (@values) {
      my $diff = $value - $ma;
      if ($diff > 0) { $num += $diff; }
      $den += abs $diff;
    }
    return ($den == 0 ? 50 : 100 * $num/$den);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::TII -- trend intensity index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->TII($N);
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
