# Chicago Board of Trade setups.

# Copyright 2005, 2006, 2007, 2008, 2009 Kevin Ryde

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

package App::Chart::Suffix::CBT;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Barchart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


# think GBL bund, GBM bobl and GBS schatz which traded on european time now
# delisted
#
my $pred = App::Chart::Sympred::Suffix->new ('.CBT');
App::Chart::TZ->chicago->setup_for_symbol ($pred);

$App::Chart::Yahoo::latest_pred->add ($pred);
$App::Chart::Barchart::intraday_pred->add ($pred);
$App::Chart::Barchart::fiveday_pred->add ($pred);


#------------------------------------------------------------------------------
# weblink
#
# contract specs can be found by tedious digging ...

App::Chart::Weblink->new
  (pred => $pred,
   name => __('_CBOT Home page'),
   desc => __('Open web browser at the Chicago Board of Trade home page'),
   url  => 'http://www.cbot.com');


#------------------------------------------------------------------------------
# barchart

# (set! barchart-suffix-delay-alist (acons ".CBOT" 20
# 					 barchart-suffix-delay-alist))

App::Chart::Barchart::commodity_mung
  ($pred,
   # agricultural
   # 'C'          # corn
   # 'ZC'         # corn electronic
   'XC' => 'XN',  # corn mini-size
   # 'YC'         # corn mini-size (electronic)
   # 'S'          # soybeans
   # 'ZS'         # soybeans electronic
   'XB' => 'XK',  # soybeans mini-size
   # 'YK'         # soybeans mini-size (electronic)
   # 'BO'         # soybean oil
   # 'ZL'         # soybean oil electronic
   # 'SM'         # soybean meal
   # 'ZM'         # soybean meal electronic
   'BS' => undef, # south american soybeans
   'ZK' => 'ZA',  # south american soybeans electronic
   'BCX' => 'CS', # soybean crush
   # 'W'          # wheat
   # 'ZW'         # wheat electronic
   # 'XW'         # wheat mini-size
   # 'YW'         # wheat mini-size (electronic)
   'AC' => 'AK',  # ethanol
   'ZE' => 'ZK',  # ethanol electronic
   'FZE' => 'FZ', # ethanol forward swap
   # 'O'          # oats
   # 'ZO'         # oats electronic
   # 'RR'         # rough rice
   # 'ZR'         # rough rice electronic

   # interest rate
   # 'US'         # 30-year bond
   # 'ZB'         # 30-year bond electronic
   # 'TY'         # 10-year bond
   # 'ZN'         # 10-year bond electronic
   # 'FV'         # 5-year bond
   # 'ZF'         # 5-year bond electronic
   # 'TU'         # 2-year bond
   # 'ZT'         # 2-year bond electronic
   # 'DJCBTI' => undef, # DJ CBOT treasury index
   #                    # only an index, not traded (?)
   # 'NZ'         # 30-year swaps
   # 'QS'         # 30-year swaps electronic
   # 'NI'         # 10-year interest rate swap
   # 'SR'         # 10-year interest rate swap electronic
   'NG' => 'NJ',  # 5-year interest rate swap
   # 'SA'         # 5-year interest rate swap electronic
   # 'YE'         # eurodollar mini (electronic)
   # 'FF'         # fed funds
   # 'ZQ'         # fed funds electronic
   # 'MB'         # 10-year muni bond
   # 'ZU'         # 10-year muni bond electronic

   # Dow
   # 'YM'         # DJIA mini $5 (electronic)
   # 'DJ'         # DJIA $10
   # 'ZD'         # DJIA $10 electronic
   # 'DD'         # Big DJIA $25 (electronic)
   'ER' => 'AH',  # DJ AIG excess index
   'RE' => 'DH',  # DJ real estate index
   # 'CX'         # liquid 50 swap index

   # Metals
   # 'ZG'         # gold
   # 'YG'         # gold mini
   # 'ZI'         # silver
   # 'YI'         # silver mini

   # these gone as of 2007 (?)
   # 'AI'           # DJ AIG commodity index
   # undef => 'AJ', # DJ AIG commodity index yield
   # 'GBL' => 'GL', # bund (electronic)
   # 'GBM' => 'GM', # bobl (electronic)
   # 'GBS' => 'GS', # schatz (electronic)
  );


1;
__END__
