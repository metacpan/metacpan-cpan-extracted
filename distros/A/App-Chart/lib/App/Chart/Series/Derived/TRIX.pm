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

package App::Chart::Series::Derived::TRIX;
use 5.010;
use strict;
use warnings;
use Carp;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::EMAx3;


# http://www.incrediblecharts.com/indicators/trix_indicator.php
#     Also called "Trix Oscillator".


sub longname   { __('TRIX') }
*shortname = \&longname;
sub manual     { __p('manual-node','TRIX') }

use constant
  { type       => 'indicator',
    units      => 'price_slope',
    hlines     => [ 0 ],
    parameter_info => [ { name    => __('Days'),
                          key     => 'trix_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 } ],
  };

sub new {
  my ($class, $parent, $N) = @_;
  ### TRIX->new: \@_

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "TRIX bad N: $N";

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N ],
     arrays     => { values => [] },
     array_aliases => { });
}
sub warmup_count {
  my ($self_or_class, $N) = @_;
  return 1 + App::Chart::Series::Derived::EMAx3->warmup_count($N);
}
sub proc {
  my ($class_or_self, $N) = @_;
  my $ema3_proc = App::Chart::Series::Derived::EMAx3->proc($N);
  my $prev;

  return sub {
    my ($value) = @_;
    my $e3 = $ema3_proc->($value);
    my $ret;
    if (defined $prev && $prev != 0) {
      $ret = 100 * ($e3 - $prev) / $prev;
    }
    $prev = $e3;
    return $ret;
  };
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::TRIX -- ...
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->TRIX($N);
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
