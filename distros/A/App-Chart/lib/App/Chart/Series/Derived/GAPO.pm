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

package App::Chart::Series::Derived::GAPO;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';

# http://trader.online.pl/MSZ/e-w-Gopalakrishnan_Range_Index_GAPO.html
#     Formula, sample chart for WIG something.
#
# http://www.tradingsolutions.com/download/tip0105.zip
#     Formula.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/012001/TradersTips/TradersTips.html
#     Traders tips formulas for several packages.  Small sample chart of
#     ^IXIC nasdaq composite for 2000.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/012001/Abstracts_new/Jayanthi/Jayanthi.html
#     First few paras of article.
#
# http://store.traders.com/v19114gopran.html
#     Article for sale, first para only.


sub longname   { __('GAPO') }
*shortname = \&longname;
sub manual     { __p('manual-node','Gopalakrishnan Range Index') }

use constant
  { type       => 'indicator',
    priority   => -10,
    minimum    => 0,
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'gapo_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 5 } ],
  };
sub maximum {
  my ($self) = @_;
  if (defined $self) {
    return log ($self->{'N'});
  } else {
    return undef;
  }
}

sub new {
  my ($class, $parent, $N) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "GAPO bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     N          => $N,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  my $N = $self->{'N'};

  my $start = $parent->find_before ($lo, $N-1);
  $parent->fill ($lo, $hi);
  my $pp = $parent->values_array;
  my $ph = $parent->array('highs') || $pp;
  my $pl = $parent->array('lows')  || $pp;

  my $s = $self->values_array;
  $hi = min ($hi, $#$pp);
  if ($#$s < $hi) { $#$s = $hi; }  # pre-extend

  my @h;
  my @l;

  foreach my $i ($start .. $lo-1) {
    my $value = $pp->[$i] // next;
    unshift @h, $ph->[$i] // $value;
    unshift @l, $pl->[$i] // $value;
  }
  my $scale = 1 / log(scalar @h);

  foreach my $i ($lo .. $hi) {
    my $value = $pp->[$i] // next;

    if (@h >= $N) {
      # drop old
      pop @h;
      pop @l;
    } else {
      # gain new point, update scale
      $scale = 1 / log(scalar @h);
    }
    unshift @h, $ph->[$i] // $value;
    unshift @l, $pl->[$i] // $value;

    my $highhigh = max (@h);
    my $lowlow   = min (@l);
    my $range = $highhigh - $lowlow;
    $s->[$i] = log ($range) * $scale;
  }
}


1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::GAPO -- Gopalakrishnan range index
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->GAPO($N);
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
