# Download cost recording and calculations.

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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


package App::Chart::DownloadCost;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;


sub cost_store_h {
  my ($h) = @_;
  my $key = $h->{'cost_key'};
  my $value = $h->{'cost_value'};
  if (! defined $value && defined $h->{'resp'}) {
    $value = length ($h->{'resp'}->content);
  }
  if (! defined $value) {
    croak "DownloadCost: missing cost_value or resp for cost_key '$key'";
  }
  cost_store ($key, $value);
}

sub cost_store {
  my ($key, $value) = @_;
  App::Chart::Database->write_extra ('', $key, $value);
}

sub cost_get {
  my ($key, $default) = @_;
  my $cost = App::Chart::Database->read_extra ('', $key);
  return (defined $cost ? $cost : $default);
}


# going by day or by symbol
#
# Decide whether to use daily downloads or individual symbol downloads to
# update all of SYMBOL-LIST.  Download will be from the
# `download-start-tdate' of each symbol, up to AVAIL-TDATE.
#
# DAILY-COST is the cost (in bytes) to download a day.
# (SYMBOL-COST-PROC tdate) should return the cost of downloading from TDATE
# to now (ie. AVAIL-TDATE) for a symbol.
# Both costs will get `http-get-cost' added to them automatically.
#
# The return is two values (USE-SYMBOL-LIST TDATE), which is a list of
# symbols to do individually, and a tdate to start from for daily
# downloads.  That tdate is (1+ avail-tdate) when no dailies should be
# done.
#
# As an example, if there's a few symbols quite a bit behind but the rest
# needing just a day or two then the result can be to do the laggards
# individually, then whole days for the most recent.
#

sub by_day_or_by_symbol {
  my (%param) = @_;

  if (! exists $param{'available_tdate'}) { croak 'missing available_tdate'; }
  my $avail = $param{'available_tdate'};

  if (! exists $param{'symbol_list'})     { croak 'missing symbol_list'; }
  my $symbol_list = $param{'symbol_list'};

  my $whole_cost;
  if (exists $param{'whole_cost'}) {
    $whole_cost = $param{'whole_cost'};
  } elsif (exists $param{'whole_cost_key'}) {
    $whole_cost = cost_get ($param{'whole_cost_key'},
                            $param{'whole_cost_default'});
  } else {
    croak 'no whole day cost method';
  }

  my $indiv_cost_proc;
  if (exists $param{'indiv_cost_proc'}) {
    $indiv_cost_proc = $param{'indiv_cost_proc'};
  } elsif (exists $param{'indiv_cost_key'}) {
    my $cost = cost_get ($param{'indiv_cost_key'},
                         $param{'indiv_cost_default'});
    $indiv_cost_proc = sub { return $cost; };
  } elsif (exists $param{'indiv_cost_fixed'}) {
    my $cost = $param{'indiv_cost_fixed'};
    $indiv_cost_proc = sub { return $cost; };
  } elsif (exists $param{'indiv_cost_daily'}) {
    my $indiv_cost_daily = $param{'indiv_cost_daily'};
    $indiv_cost_proc = sub { my ($lo) = @_;
                             return $indiv_cost_daily * ($avail - $lo + 1); };
  } else {
    croak 'no indiv cost method';
  }

  $whole_cost += $App::Chart::option{http_get_cost};

  # tdate => [ symbol, symbol, ... ]
  my %hash = ();
  foreach my $symbol (@$symbol_list) {
    my $start = App::Chart::Download::start_tdate_for_update ($symbol);
    my $aref = ($hash{$start} ||= []);
    push @$aref, $symbol;
  }

  my $best_whole_tdate = min (keys %hash);
  my $best_cost = $whole_cost * ($avail - $best_whole_tdate + 1);
  my @best_indiv_list = ();
  ### whole ...
  ### $best_whole_tdate
  ### $avail
  ### none indiv ...
  ### $best_cost
  ### whole_cost per day: $whole_cost

  my @indiv_list = ();
  my $indiv_cost = 0;

  while (%hash) {
    my $new_tdate = min (keys %hash);
    my $new_list = delete $hash{$new_tdate};
    my $new_cost = scalar (@$new_list)
      * (($indiv_cost_proc->($new_tdate)) + $App::Chart::option{http_get_cost});
    push @indiv_list, @$new_list;
    $indiv_cost += $new_cost;

    my $whole_tdate = min (keys %hash);
    if (! defined $whole_tdate) { $whole_tdate = $avail + 1; }
    my $cost = $whole_cost * ($avail - $whole_tdate + 1) + $indiv_cost;
    # if (DEBUG) { print "  [",scalar(%hash),
    #                "] whole $whole_tdate indiv ",scalar(@indiv_list),
    #                ": $cost (indiv $indiv_cost)\n"; }

    if ($cost < $best_cost) {
      ### is new best ...
      $best_cost = $cost;
      @best_indiv_list = @indiv_list;
      $best_whole_tdate = $whole_tdate;
    }
  }

#     # same order as original symbol-list
#     (set! best-symbol-list (lset-intersection string=?
# 					      symbol-list best-symbol-list))

  return $best_whole_tdate, @best_indiv_list;
}


1;
__END__

# =head1 NAME
# 
# App::Chart::DownloadCost -- download cost recording and calculations
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< App::Chart::DownloadCost::by_day_or_by_symbol (key=>value, ...) >>
# 
#     symbol_list
#     available_tdate
# 
#     whole_cost
#     whole_cost_key
#     whole_cost_default
# 
#     indiv_cost_proc
#     indiv_cost_fixed
#     indiv_cost_daily
#     indiv_cost_key
#     indiv_cost_default
# 
# =item C<App::Chart::DownloadCost::cost_store ($key, $data_body)>
# 
# ...
# 
# =item C<< App::Chart::DownloadCost::cost_get ($key, $default) >>
# 
# ...
# 
# =back
# 
# =cut
