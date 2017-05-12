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

package App::Chart::Series::Derived::HullMA;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');
use Math::Trig ();

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::WMA;


# http://www.alanhull.com/
# http://www.alanhull.com.au/
# http://www.justdata.com.au/Journals/AlanHull/hull_ma.htm
#     Alan Hull's explanation and formula, samples of BHP Billiton (symbol
#     BHP.AX) weekly 2001-2004.
#
# Old link: http://www.alanhull.com.au/hma/hma.html
#


sub longname   { __('Hull MA') }
*shortname = \&longname;
sub manual     { __p('manual-node','Hull Moving Average') }

use constant
  { type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'hull_ma_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;
  ### HullMA new(): $N

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "HullMA bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($self_or_class, $N) = @_;
  my $NS = int(sqrt($N));
  return (App::Chart::Series::Derived::WMA->warmup_count($N)
          + App::Chart::Series::Derived::WMA->warmup_count($NS));
}
sub proc {
  my ($self, $N) = @_;
  my $N2 = int($N/2);
  my $NS = int(sqrt($N));

  my $wma_N_proc  = App::Chart::Series::Derived::WMA->proc($N);
  my $wma_N2_proc = App::Chart::Series::Derived::WMA->proc($N2);
  my $wma_NS_proc = App::Chart::Series::Derived::WMA->proc($NS);

  return sub {
    my ($value) = @_;
    return $wma_NS_proc->(2 * $wma_N2_proc->($value) - $wma_N_proc->($value));
  };
}

sub FIXME_weights {
  my ($N) = @_;
  my @N_weights = reverse 1 .. $N;
  my $N_total = List::Util::sum (@N_weights);
  foreach (@N_weights) { $_ /= $N_total }

  my @N2_weights = reverse 1 .. int($N/2);
  my $N2_total = List::Util::sum (@N2_weights);
  foreach (@N_weights) { $_ /= $N2_total }

  for (my $i = 0; $i < @N2_weights; $i++) {
    $N_weights[$i] -= $N2_weights[$i];
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::HullMA -- Hull moving average
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->HullMA($N);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::WMA>
# 
# =cut
