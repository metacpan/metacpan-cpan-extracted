# Copyright 2009 Kevin Ryde

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

package App::Chart::StockMonkey;
use strict;
use warnings;

# my @averages = qw(Math::Business::SMA
#                   Math::Business::EMA
#                   Math::Business::WMA
#                   Math::Business::HMA
# 
#          my $avg = new Math::Business::EMA;
#             $avg->set_days(7);
# 
#          my @closing_values = qw(
#              3 4 4 5 6 5 6 5 5 5 5
#              6 6 6 6 7 7 7 8 8 8 8
#          );
# 
#          # choose one:
#          $avg->insert( @closing_values );
#          $avg->insert( $_ ) for @closing_values;
# 
#          if( defined(my $q = $avg->query) ) {
# 
# Math::Business::LaguerreFilter
#          my $avg = new Math::Business::LaguerreFilter;
#             $avg->set_days(9);
#             $avg->set_alpha(0.2); # same (roughly)
# 
#          my @closing_values = qw(
#              3 4 4 5 6 5 6 5 5 5 5
#              6 6 6 6 7 7 7 8 8 8 8
#          );
# 
#          # choose one:
#          $avg->insert( @closing_values );
#          $avg->insert( $_ ) for @closing_values;
# 
#          if( defined(my $q = $avg->query) ) {
# 
# Math::Business::MACD
#          print "       MACD: ", scalar $macd->query,    "\n",
#                "Trigger EMA: ", $macd->query_trig_ema,  "\n",
#                "   Fast EMA: ", $macd->query_fast_ema,  "\n",
#                "   Slow EMA: ", $macd->query_slow_ema,  "\n";
#                "  Histogram: ", $macd->query_histogram, "\n";
# 
# Math::Business::RSI
#          my $rsi = Math::Business::RSI->recommended;
# 
# Math::Business::BollingerBands
# 
# Math::Business::ATR
#              [ 5, 3, 4 ], # high, low, close
#              [ 6, 4, 5 ],
#              [ 5, 4, 4.5 ],
#          );
# 
#          # choose one:
#          $atr->insert( @data_points );
#          $atr->insert( $_ ) for @data_points;
# 
# Math::Business::DMI
#          my @data_points = (
#              [ 5, 3, 4 ], # high, low, close
#              [ 6, 4, 5 ],
#              [ 5, 4, 4.5 ],
#          );
# 
#          # choose one:
#          $dmi->insert( @data_points );
#          $dmi->insert( $_ ) for @data_points;
# 
# Math::Business::ParabolicSAR
#          my @data_points = (
#              ["35.0300", "35.1300", "34.3600", "34.3900"],
#              ["34.6400", "35.0000", "34.2100", "34.7400"],
#              ["34.6900", "35.1400", "34.3800", "34.7900"],
#              ["35.2900", "35.7900", "35.0800", "35.5200"],
#              ["35.9000", "36.0600", "35.7500", "36.0600"],
#              ["36.1300", "36.7200", "36.0500", "36.5800"],
#              ["36.4100", "36.6400", "36.2600", "36.6100"],
#              ["36.3500", "36.5500", "35.9400", "35.9700"],
#          );
# 
#          # choose one:
#          $sar->insert( @data_points );
#          $sar->insert( $_ ) for @data_points;
# 
#          my $sar = $sar->query;
#          print "SAR: $sar\n";

1;
__END__
