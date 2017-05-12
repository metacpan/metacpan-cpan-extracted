# Copyright 2007, 2009, 2010, 2013 Kevin Ryde

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

package App::Chart::Series::Derived::DarvasBoxes;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series::Indicator';
use App::Chart::Series::Derived::MFI;
use App::Chart::Series::Derived::TrueRange;


# http://www.gerryco.com/tech/darvas.html  ... gone, but at archive.org
# http://web.archive.org/web/20080212170344/http://www.gerryco.com/tech/darvas.html
#     State diagram.
#
# http://www.linnsoft.com/tour/techind/darvas.htm
#     Sample MSFT August 2002, using close-must-penetrate for breakouts.
#
# http://www.guppytraders.com/gup206.htm
#


# Darryl Guppy's modified Darvas (not implemented here):
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/052005/Abstracts_new/Guppy/guppy.html
#     TASC May 2005 intro, rest for sale.
#
# http://www.traders.com/Documentation/FEEDbk_docs/Archive/062005/TradersTips/TradersTips.html
#     Trader's Tips June 2005.



sub longname   { __('Darvas Boxes') }
sub shortname  { __('Darvas') }
sub manual     { __p('manual-node','Darvas Boxes') }

use constant
  { type       => 'average',
    parameter_info => [ ],
    default_linestyle => 'Stops',
  };

sub new {
  my ($class, $parent) = @_;

  return $class->SUPER::new
    (parent     => $parent,
     parameters => [ ],
     arrays     => { values => [] },
     arrays     => { upper  => [],
                     lower  => [] },
     array_aliases => { values => 'upper' });
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};

  # everything in one go
  $lo = 0;
  $hi = $parent->hi;

  $parent->fill ($lo, $hi);
  my $p = $parent->values_array;
  my $ph = $parent->array('highs') || $p;
  my $pl = $parent->array('lows')  || $p;

  my $s_upper = $self->array('upper');
  my $s_lower = $self->array('lower');
  $hi = min ($hi, $#$p);
  if ($#$s_upper < $hi) { $#$s_upper = $hi; }  # pre-extend
  if ($#$s_lower < $hi) { $#$s_lower = $hi; }  # pre-extend

  my $box_start; # date pos
  my $box_high;
  my $box_low;
  my $state = 0;

  my $fill_box = sub {
    my ($box_end) = @_;
    foreach my $i ($box_start .. $box_end) {
      $s_upper->[$i] = $box_high;
      $s_lower->[$i] = $box_low;
    }
  };

  foreach my $i ($lo .. $hi) {
    my $close = $p->[$i] // next;
    my $high = $ph->[$i] // $close;
    my $low  = $pl->[$i] // $close;

    if ($state == 0) {
      # initial
      $box_high = $high;
      $box_start = $i;
      $state = 1;

    } elsif ($state == 1) {
      if ($high > $box_high) {
        # breakout, stay here
        $box_high = $high;
        $box_start = $i;
      } else {
        # held, go onwards
        $state = 2;
      }

    } elsif ($state == 2) {
      if ($high > $box_high) {
        # breakout, back to 1
        $box_high = $high;
        $box_start = $i;
        $state = 1;
      } else {
        # held, go onwards
        $box_low = $low;
        $state = 3;
      }

    } elsif ($state == 3) {
      if ($high > $box_high) {
        # broke high, back to 1
        $box_high = $high;
        $box_start = $i;
        $state = 1;
      } elsif ($low < $box_low) {
        # break low, stay here
        $box_low = $low;
      } else {
        # held, go onwards
        $state = 4;
      }

    } elsif ($state == 4) {
      if ($high > $box_high) {
        # broke high, back to 1
        $box_high = $high;
        $box_start = $i;
        $state = 1;
      } elsif ($low < $box_low) {
        # break low, back to 3
        $box_low = $low;
        $state = 3;
      } else {
        # held, go onwards
        $state = 5;
      }

    } elsif ($state == 5) {
      if ($high > $box_high
          || $low < $box_low) {
        # possible "close-must-penetrate" style
        # ($close > $box_high || $close < $box_low)

        # break either way, stop box
        $fill_box->($i);
        $box_high = $high;
        $box_start = $i;
        $state = 1;
      }
    }
  }

  if ($state == 5) {
    $fill_box->($hi);
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Series::Derived::DarvasBoxes -- Darvas boxes
# 
# =head1 SYNOPSIS
# 
#  my $series = $parent->DarvasBoxes();
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
