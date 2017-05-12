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

package App::Chart::Series::Derived::TEMA;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::EMAx2;
use App::Chart::Series::Derived::EMAx3;

sub longname  { __('TEMA - Triple EMA') }
sub shortname { __('TEMA') }
sub manual    { __p('manual-node','Double and Triple Exponential Moving Average') }

use constant
  { type       => 'average',
    priority   => -10,
    parameter_info => [ { name    => __('Days'),
                          key     => 'tema_days',
                          type    => 'integer',
                          minimum => 0,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) or croak "TEMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     N          => $N,
     arrays     => { values => [] },
     array_aliases => { });
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $ema_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $ema2_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $ema3_proc = App::Chart::Series::Derived::EMA->proc($N);

  return sub {
    my ($value) = @_;
    my $e = $ema_proc->($value);
    my $e2 = $ema2_proc->($e);
    my $e3 = $ema3_proc->($e2);

    return 3*$e - 3*$e2 + $e3;
  };
}
# A TEMA is in theory influenced by all preceding data, but warmup_count()
# is designed to determine a warmup count.  The next point will have an
# omitted weight of no more than 0.1% of the total.  Omitting 0.1% should be
# negligable, unless past values are ridiculously bigger than recent ones.
#
# FIXME: this is almost certainly more than needed, but a calculation like
# DEMA warmup_count() is a bit tricky
#
sub warmup_count {
  my ($self_or_class, $N) = @_;
  return App::Chart::Series::Derived::EMAx3->warmup_count($N);

  #   return max(App::Chart::Series::Derived::EMA->warmup_count($N),
  #              App::Chart::Series::Derived::EMAx2->warmup_count($N),
  #              );
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::TEMA -- triple-exponential moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->TEMA($N);
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
