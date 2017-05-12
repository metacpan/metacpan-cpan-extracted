# Chicago Mercantile Exchange setups.

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

package App::Chart::Suffix::CME;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Barchart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;

my $pred = App::Chart::Sympred::Suffix->new ('.CME');
App::Chart::TZ->chicago->setup_for_symbol ($pred);

$App::Chart::Yahoo::latest_pred->add ($pred);
$App::Chart::Barchart::intraday_pred->add ($pred);
$App::Chart::Barchart::fiveday_pred->add ($pred);


#------------------------------------------------------------------------------
# weblink - contract specs

App::Chart::Weblink->new
  (pred => $pred,
   name => __('CME _Contract Specifications'),
   desc => __('Open web browser at the Chicago Mercantile Exchange contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.cme.com/clearing/clr/spec/contract_specifications_cl.html?product='
       . URI::Escape::uri_escape (App::Chart::symbol_commodity ($symbol));
   });


#------------------------------------------------------------------------------

# (set! barchart-suffix-delay-alist (acons ".CME" 10
# 					 barchart-suffix-delay-alist))


App::Chart::Barchart::commodity_mung
  ($pred,
   # interest rate products (IMM)
   # "EM"        # 1-month LIBOR
   'GLB' => 'GH',  # 1-month LIBOR electronic
   'TB'  => undef, # 13-week treasury bills
   'GTB' => undef, # 13-week treasury bills electronic
   # 'S2'          # 2-year swap pit+electronic
   # 'S5'          # 5-year swap electronic
   'SW5' => undef,   # 5-year swap pit
   # 'S0'         # 10-year swap
   'SW0' => 'S0', # 10-year swap electronic
   'TIE' => 'F3', # 28-day mexican TIIE
   'GTI' => 'F4', # 28-day mexican TIIE electronic
   'CET' => 'F1', # 91-day mexican CETES
   'GCE' => 'F2', # 91-day mexican CETES electronic
   'Y5'  => undef,    # 5-year eurodollar bundle options
   'CPI' => 'CI', # consumer price index
   # 'ED'         # eurodollar
   # 'GE'         # eurodollar electronic
   '3F' => undef,    # eurodollar FRA
   # 'EY'        # euroyen
   # 'EL'        # euroyen LIBOR
   'TZ' => undef,    # fed funds turn
   # 'JB'        # japanese government bonds
   # (F0, F5 agency swaps delisted 11 Apr 05)

   # equity products
   # 'NQ'        # e-mini nasdaq 100
   # 'ES'        # e-mini s&p 500
   'EMD' => 'MD', # e-mini s&p 500
   'FIN' => 'PF', # financial spctr
   # 'GI'        # GSCI
   'GD' => undef,    # GSCI electronic
   # 'ND'        # nasdaq 100 pit+electronic
   # 'NK'        # nikkei 225 dollar
   'NKD' => 'NY', # nikkei 225 dollar electronic
   'NIY' => 'NL', # nikkei 225 yen electronic
   'RS1' => 'RW', # russell 1000
   # 'RL'        # russell 2000 pit+electronic
   'ER2' => 'EZ', # e-mini russell 2000
   # 'SP'        # s&p 500
   # 'SG'        # s&p 500 barra growth
   # 'SU'        # s&p 500 barra value
   # 'MD'        # s&p midcap 400 pit+electronic
   'SMC' => 'PC', # s&p smallcap 600 electronic
   'QCN' => 'NC', # e-mini nasdaq composite pit+elec
   'TEC' => 'PT', # technology spctr
   'X1' => undef,    # X-Funds 1 index
   'X2' => undef,    # X-Funds 2 index
   'X3' => undef,    # X-Funds 3 index
   'X4' => undef,    # X-Funds 4 index
   'X5' => undef,    # X-Funds 5 index

   # FX products
   # 'AD'        # australian dollar
   '6A' => 'A6',  # australian dollar electronic
   'UAC' => 'UG', # AUD/CAND
   'ACD' => undef,   # AUD/CAND electronic
   'UAY' => 'UI', # AUD/NZD
   'AJY' => undef,   # AUD/NZD electronic
   'UAN' => 'UK', # AUD/Yen
   'ANE' => undef,   # AUD/Yen electronic
   # 'BR'        # brazilian real
   '6L' => 'L6',  # brazilian real electronic
   # 'BP'        # british pound
   '6B' => 'B6',  # british pound electronic
   'UPS' => 'UN', # pound/swiss franc
   'PSF' => undef,   # pound/swiss franc electronic
   'UPY' => 'UR', # pound/yen
   'PJY' => undef,   # pound/yen electronic
   # 'CD'        # canadian dollar
   '6C' => 'D6',  # canadian dollar electronic
   'UCY' => 'UF', # canadian/yen
   'CJY' => undef,   # canadian/yen electronic
   'CZK' => 'WC', # czech koruna pit+electronic
   # 'E7'        # e-mini euro
   # 'J7'        # e-mini yen
   # 'EC'        # euro fx
   '6E' => 'E6',  # euro fx electronic
   'UEA' => 'UC', # euro/australian
   'EAD' => undef,   # euro/australian electronic
   'UE' => 'RP',  # euro/pound
   # 'RP'        # euro/pound electronic
   'UEC' => 'UE', # euro/canadian
   'ECD' => undef,   # euro/canadian electronic
   'ECZ' => 'WE', # euro/czech koruna
   'ECK' => undef,   # euro/czech koruna electronic
   'EHU' => 'WU', # euro/hungarian forint
   'EHF' => undef,   # euro/hungarian forint electronic
   'UH' => 'RY',  # euro/yen
   # 'RY'        # euro/yen electronic
   'UEN' => 'UB', # euro/norwegian krone
   'ENK' => undef,   # euro/norwegian krone electronic
   'EPL' => 'WZ', # euro/polish zloty
   'EPZ' => undef,   # euro/polish zloty electronic
   'UES' => 'UA', # euro/swedish krona
   'ESK' => undef,   # euro/swedish krona electronic
   'UA' => 'RF',  # euro/swiss franc
   # 'RF'        # euro/swiss franc electronic
   'HFO' => 'WH', # hungarian forint pit+electronic
   # 'JY'        # yen
   '6J' => 'J6',  # yen electronic
   'MP' => 'MQ',  # mexican peso
   '6M' => 'M6',  # mexican peso electronic
   # 'NE'        # new zealand dollar
   '6N' => 'N6',  # new zealand dollar electronic
   'UNK' => 'NR', # norwegian krone
   'NOK' => undef,   # norwegian krone electronic
   'PLZ' => 'WP', # polish zloty
   'PLN' => undef,   # polish zloty electronic
   # 'RU'        # russian ruble
   '6R' => 'R6',  # russian ruble electronic
   # 'RA'        # south african rand
   '6Z' => 'T6',  # south african rand electronic
   'USK' => 'SK', # swedish krona
   'SEK' => undef,   # swedish krona electronic
   # 'SF'        # swiss franc
   '6S' => 'S6',  # swiss franc electronic
   'USY' => 'UP', # swiss franc/yen
   'SJY' => undef,   # swiss franc/yen electronic

   # commodity products
   # 'DB'        # butter
   # 'DA'        # class III milk
   # 'DK'        # class IV milk
   # 'FC'        # feeder cattle
   # 'GF'        # feeder cattle electronic
   'GPB' => 'PD', # pork bellies electronic
   # 'PB'        # frozen pork bellies
   # 'LH'        # lean hogs
   # 'HE'        # lean hogs electronic
   # 'LC'        # live cattle
   # 'LE'        # live cattle electronic
   'NF' => 'DF',  # non-fat dry milk
   'AA' => undef,    # spot butter grade AA
   'BK' => undef,    # spot cheese blocks
   'RB' => undef,    # spot cheese barrels
   'NM' => undef,    # spot nonfat dry milk grade A
   'NX' => undef,    # spot nonfat dry milk extra grade
   # 'LB'        # lumber
   'DP' => 'TD',  # diammonium phosphate (DAP)
   'UL' => 'TL',  # ammonium nitrate (UAN)
   'UF' => 'TZ',  # urea

   # environmental products
   'QM' => undef,    # NYMEX e-miNY light sweet crude
   'QG' => undef,    # NYMEX e-miNY natural gas
   # weather ...

   # TRAKRS Products
   'CCC' => undef,   # Commodity TRAKRS
   'ECT' => undef,   # Euro Currency TRAKRS
   'GLD' => undef,   # Gold TRAKRS
   'OOO' => undef,   # LMC TRAKRS
   'MLT' => undef,   # Long-Short Tech TRAKRS
   'LST' => undef,   # Long-Short Tech TRAKRS III
   'TTT' => undef,   # Select 50 TRAKRS
  );


1;
__END__
