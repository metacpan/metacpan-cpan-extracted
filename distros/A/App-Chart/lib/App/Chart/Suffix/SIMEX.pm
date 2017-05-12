# Singapore International Money Exchange (SIMEX) setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.


package App::Chart::Suffix::SIMEX;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Barchart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Suffix::SI;

my $pred = App::Chart::Sympred::Suffix->new ('.SIMEX');
$App::Chart::Suffix::SI::timezone_singapore->setup_for_symbol ($pred);

# barchart for database and for intraday graphs
$App::Chart::Barchart::intraday_pred->add ($pred);
$App::Chart::Barchart::fiveday_pred->add ($pred);

# FIXME: dunno what delay for simex, www.sgx.com says its quotes are
# delayed, but doesn't seem to say be how much
#
# App::Chart::Barchart::setup_quote_delay ($pred, 20);

App::Chart::Barchart::commodity_mung
  ($pred,
   # equity index futures
   'NK' => 'NX',  # nikkei 225
   'N3' => 'VN',  # nikkei 300
   #
   # 'JP' MSCI Japan seems to be missing from barchart, it looks
   # like that contract has had no volume for a long time, so it
   # doesn't matter
   #
   'JP' => undef,    # msci japan
   #
   'TW' => 'TI',  # msci taiwan
   'SG' => 'SV',  # msci singapore
   'ST' => 'VS',  # straits times
   'HK' => 'VK',  # msci hong kong
   'IN' => 'NH',  # cnx nifty

   # interest rate futures
   'ED' => 'DS',  # eurodollar
   'EY' => 'WT',  # euroyen tibor
   'EL' => 'SL',  # euroyen libor
   'JG' => 'JV',  # japan 10-yr bond
   'JB' => 'JX',  # japan 10-yr bond mini
   'SD' => 'VD',  # singapore dollar interest rate
   'SB' => 'JZ'); # singapore 5-yr bond


#-----------------------------------------------------------------------------
# web link - home page only for now
#

App::Chart::Weblink->new
  (pred => $pred,
   name => __('SGX _Home Page'),
   desc => __('Open web browser at the Singapore Stock Exchange home page'),
   url  => 'http://www.sgx.com');

1;
