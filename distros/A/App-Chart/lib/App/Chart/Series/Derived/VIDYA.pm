# Copyright 2006, 2007, 2009, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::VIDYA;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Calculation;
use App::Chart::Series::Derived::KAMA;
use App::Chart::Series::Derived::VIDYAalpha;


# http://trader.online.pl/ELZ/t-i-VIDYA.html
#     Formulas and S&P500 sample chart.
#
# http://www.fmlabs.com/reference/VIDYA.htm
#
# http://www.working-money.com/documentation/FEEDbk_docs/Archive/0298/TradersTips/Tips9802.html
#     TASC trader's tips February 1998, formulas.
#


sub longname   { __('VIDYA - Variable Index Dynamic') }
sub shortname  { __('VIDYA') }
sub manual     { __p('manual-node','Variable Index Dynamic Average') }

use constant
  { type       => 'average',
    parameter_info => App::Chart::Series::Derived::VIDYAalpha::parameter_info(),
  };

sub new {
  my ($class, $parent, $N_fast, $N_slow) = @_;

  $N_fast //= parameter_info()->[0]->{'default'};
  ($N_fast > 0) || croak "VIDYA bad N_fast: $N_fast";

  $N_slow //= parameter_info()->[1]->{'default'};
  ($N_slow > 0) || croak "VIDYA bad N_slow: $N_slow";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N_fast, $N_slow ],
     arrays     => { values => [] },
     array_aliases => { });
}

# warmup_count() gives a fixed amount, based on a guessed EMA alpha 0.1
# (giving GUESS_EMA_WARMUP==65), which is probably slower than occurs in
# practice.
#
# warmup_count_for_position() calculates a value on actual data, working
# backwards.  In practice it's as little as about 100.
#
use constant GUESS_EMA_WARMUP =>
  App::Chart::Series::Derived::EMA->warmup_count
  (App::Chart::Series::Derived::EMA::alpha_to_N
   (0.1));
### GUESS_EMA_WARMUP: GUESS_EMA_WARMUP()

sub warmup_count {
  my ($self_or_class, $N_fast, $N_slow) = @_;
  return GUESS_EMA_WARMUP
    + App::Chart::Series::Derived::VIDYAalpha->warmup_count($N_fast, $N_slow);
}
sub warmup_count_for_position {
  return App::Chart::Series::Derived::KAMA::warmup_count_for_position_alphaclass
    (@_, 'App::Chart::Series::Derived::VIDYAalpha');
}

sub proc {
  my ($class, $N_fast, $N_slow) = @_;
  my $alpha_proc = App::Chart::Series::Derived::VIDYAalpha->proc
    ($N_fast, $N_slow);
  my $ama_proc = App::Chart::Series::Derived::KAMA->adaptive_ema_proc();

  return sub {
    my ($value) = @_;
    my $alpha = $alpha_proc->($value) // return;
    return $ama_proc->($alpha, $value);
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::VIDYA -- Variable Index Dynamic Average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->VIDYA($N_fast, $N_slow);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::Stddev>
# 
# =cut
