# Copyright 2007, 2009, 2011 Kevin Ryde

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

package App::Chart::Series::Derived::Kirshenbaum;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::Bollinger;
use App::Chart::Series::Derived::EMA;
use App::Chart::Series::Derived::LinRegStderr;


sub longname  { __('Kirshenbaum Bands') }
sub shortname { __('Kirshenbaum') }
sub manual    { __p('manual-node','Kirshenbaum Bands') }

use constant
  { type       => 'average',
    parameter_info => [ { name    => __('Days'),
                          key     => 'kirshenbaum_days',
                          type    => 'integer',
                          minimum => 1,
                          default => 20 },
                        { name     => __('Stderrs'),
                          key      => 'kirshenbaum_stderrs',
                          type     => 'float',
                          default  => 1.75,
                          decimals => 2,
                          step     => 0.25,
                          minimum  => 0 }],
    line_colours => { upper => App::Chart::BAND_COLOUR(),
                      lower => App::Chart::BAND_COLOUR() },
  };

sub new {
  my ($class, $parent, $N, $stderr_factor) = @_;

  $N //= parameter_info()->[0]->{'default'};
  ($N > 0) || croak "Kirshenbaum bad N: $N";

  $stderr_factor //= parameter_info()->[1]->{'default'};

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ $N, $stderr_factor ],
     arrays     => { middle => [],
                     upper  => [],
                     lower  => [] },
     array_aliases => { values => 'middle' });
}

sub proc {
  my ($class_or_self, $N, $stderr_factor) = @_;
  my $ema_proc = App::Chart::Series::Derived::EMA->proc($N);
  my $stderr_proc = App::Chart::Series::Derived::LinRegStderr->proc($N);

  return sub {
    my ($value) = @_;
    my $ema = $ema_proc->($value);
    my $stderr = $stderr_proc->($value) * $stderr_factor;
    return ($ema, $ema + $stderr, $ema - $stderr);
  };
}
sub warmup_count {
  my ($self_or_class, $N, $stderr_factor) = @_;
  return max (App::Chart::Series::Derived::EMA->warmup_count($N),
              App::Chart::Series::Derived::LinRegStderr->warmup_count($N));
}
*fill_part = \&App::Chart::Series::Derived::Bollinger::fill_part;

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::Kirshenbaum -- kirshenbaum bands
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->Kirshenbaum($N);
#  my $series = $parent->Kirshenbaum($N, $stderr_factor);
# 
# =head1 DESCRIPTION
# 
# ...
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Series>, L<App::Chart::Series::Derived::SMA>
# 
# =cut
