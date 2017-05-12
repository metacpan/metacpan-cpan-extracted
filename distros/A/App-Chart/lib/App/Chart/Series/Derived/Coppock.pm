# Copyright 2006, 2007, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::Coppock;
use 5.010;
use strict;
use warnings;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::ROC;
use App::Chart::Series::Derived::WMA;

sub longname  { __('Coppock Curve') }
sub shortname { __('Coppock') }
sub manual    { __p('manual-node','Coppock Curve') }

use constant
  { type       => 'indicator',
    units      => 'roc_percent',
    hlines     => [ 0 ],
    parameter_info => App::Chart::Series::Derived::Momentum::parameter_info(),
  };

my $N1 = 11;
my $N2 = 14;
my $smooth = 10;

sub new {
  my ($class, $parent) = @_;

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ ],
     arrays     => { values => [] });
}

sub proc {
  my ($self_or_class) = @_;

  my $roc1_proc = App::Chart::Series::Derived::ROC->proc ($N1);
  my $roc2_proc = App::Chart::Series::Derived::ROC->proc ($N2);
  my $wma_proc = App::Chart::Series::Derived::WMA->proc ($smooth);

  return sub {
    my ($value) = @_;
    my $roc1 = $roc1_proc->($value);
    my $roc2 = $roc2_proc->($value);
    if (! defined $roc1 || ! defined $roc2) { return undef; }
    return $wma_proc->($roc1 + $roc2);
  };
}
sub warmup_count {
  my ($class_or_self) = @_;
  return $smooth - 1 + max($N1, $N2);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Coppock -- Coppock indicator
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Coppock;
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::ROC>,
# L<App::Chart::Series::Derived::WMA>
# 
# =cut
