# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Series::Derived::Collapse;
use 5.010;
use strict;
use warnings;
use Carp;
# use Locale::TextDomain ('App-Chart');

use App::Chart;
use base 'App::Chart::Series';

# uncomment this to run the ### lines
#use Smart::Comments;

use constant DEBUG => 0;


use constant { longname  => 'Timebase Collapse',
               shortname => 'Collapse',
               manual    => undef,
               type      => 'special',
             };


sub new {
  my ($class, $parent, $timebase_class) = @_;

  if ($timebase_class !~ /::/) {
    $timebase_class = "App::Chart::Timebase::\u$timebase_class";
  }
  require Module::Load;
  Module::Load::load ($timebase_class);

  my $parent_timebase = $parent->timebase;
  my $new_timebase = $timebase_class->new_from_timebase ($parent_timebase);
  my $self = $class->SUPER::new (parent   => $parent,
                                 timebase => $new_timebase,
                                 arrays   => { map {; ($_ => []) }
                                               $parent->array_names },
                                 array_aliases => $parent->{'array_aliases'});
  return $self;
}

sub name {
  my ($self) = @_;
  if (exists $self->{'name'}) {
    return $self->{'name'}
  } else {
    my $timebase = $self->timebase;
    my $parent = $self->{'parent'};
    return ($self->{'name'}
            = join (' - ', $parent->name||'', $timebase->adjective));
  }
}

sub hi {
  my ($self) = @_;
  my $self_timebase = $self->{'timebase'};
  my $parent = $self->{'parent'};
  my $parent_timebase = $parent->timebase;
  return $self_timebase->convert_from_ceil ($parent_timebase, $parent->hi);
}

sub range_default_names {
  my ($self) = @_;
  return $self->{'parent'}->range_default_names;
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  ### Collapse fill_part: "$lo $hi"

  my $timebase = $self->timebase;
  my $parent = $self->{'parent'};
  my $parent_timebase = $parent->timebase;

  my $p_lo = $parent_timebase->convert_from_floor ($timebase, $lo);
  my $p_hi = $parent_timebase->convert_from_ceil  ($timebase, $hi);
  ### parent has: "lo=$p_lo hi=$p_hi"

  $parent->fill ($p_lo, $p_hi);
  my $p_opens    = $parent->array('opens') || [];
  my $p_highs    = $parent->array('highs');
  my $p_lows     = $parent->array('lows');
  my $p_values   = $parent->values_array;
  my $p_volumes  = $parent->array('volumes');
  my $p_openints = $parent->array('openints');

  my $s_opens    = $self->array('opens');
  my $s_highs    = $self->array('highs');
  my $s_lows     = $self->array('lows');
  my $s_values   = $self->values_array;
  my $s_volumes  = $self->array('volumes');
  my $s_openints = $self->array('openints');

  my $p_t = $p_lo;
  for (my $t = $lo; $t <= $hi; $t++) {
    my $p_t_next = $parent_timebase->convert_from_floor ($timebase, $t + 1);
    my $p_end = $p_t_next - 1;
    if (DEBUG) { print "  at t=$t p_t=$p_t p_end=$p_end\n"; }

    if ($s_opens) {
      # Open is first day with an open or a close.  Look at the close in case
      # a closes-only series as happens for various indexes and sources.

      if (DEBUG) { local $,=' ';
                   print "    p_opens", @{$p_opens}[$p_t..$p_end], "\n"; }
      foreach my $i ($p_t .. $p_end) {
        if (defined $p_opens->[$i]) {
          $s_opens->[$t] = $p_opens->[$i];
          last;
        }
        if (defined $p_values->[$i]) {
          $s_values->[$t] = $p_values->[$i];
          last;
        }
      }
    }

    # some data sources only give closes, so include them in the high/low
    # calc; likewise maybe some data sources might only offer opens+closes,
    # so include the opens
    #
    if ($s_highs) {
      $s_highs->[$t]  = App::Chart::max_maybe (@$p_highs [$p_t .. $p_end],
                                              @$p_opens [$p_t .. $p_end],
                                              @$p_values[$p_t .. $p_end]);
    }
    if ($s_lows) {
      $s_lows->[$t]   = App::Chart::min_maybe (@$p_lows  [$p_t .. $p_end],
                                              @$p_opens [$p_t .. $p_end],
                                              @$p_values[$p_t .. $p_end]);
    }

    # FIXME: treat other named arrays likewise
    #
    # close is the last close in the period
    for (my $i = $p_end; $i >= $p_t; $i--) {
      if (defined $p_values->[$i]) {
        $s_values->[$t] = $p_values->[$i];
        last;
      }
    }

    # volume is the total in the period, or undef if in period are undef
    # note List::Util::sum() unhelpfully returns empty string for no args
    if ($s_volumes) {
      my @volumes = grep {defined} @$p_volumes[$p_t .. $p_end];
      if (@volumes) {
        $s_volumes->[$t] = List::Util::sum (@volumes);
      }
    }

    # openint i the last openint in the period
    # this might be on a different day than the final close ...
    if ($s_openints) {
      for (my $i = $p_end; $i >= $p_t; $i--) {
        if (defined $p_openints->[$i]) {
          $s_openints->[$t] = $p_openints->[$i];
          last;
        }
      }
    }

    $p_t = $p_t_next;
  }
}


1;
__END__

=for stopwords OHLCVI

=head1 NAME

App::Chart::Series::Derived::Collapse -- series collapsed to coarser timebase

=for test_synopsis my ($series)

=head1 SYNOPSIS

 my $wseries = $series->collapse ('Weeks');

=head1 DESCRIPTION

A C<App::Chart::Series::Collapse> series collapses data in a given OHLCVI
series down to a coarser timebase, for example daily data might be collapsed
to weekly.

=head1 SEE ALSO

L<App::Chart::Series>

=cut

# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< App::Chart::Series::Collapse->derive ($series, $timebase_class) >>
# 
# Create a new series which collapses C<$series> to the given
# C<$new_timebase>.  For example
# 
#     my $daily_series = App::Chart::Series::Database ('BHP.AX');
#     my $weekly_timebase = App::Chart::Timebase::Weekly->new_from_timebase
#                             ($daily_series->timebase);
# 
#     my $weekly_series = App::Chart::Series::Database
#                           ($daily_series, $weekly_timebase);
# 
# =back
