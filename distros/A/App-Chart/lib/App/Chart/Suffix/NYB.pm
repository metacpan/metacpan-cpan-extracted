# New York Board of Trade (NYBOT) setups.

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

package App::Chart::Suffix::NYB;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Barchart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Yahoo;


my $pred = App::Chart::Sympred::Suffix->new ('.NYB');
App::Chart::TZ->newyork->setup_for_symbol ($pred);

$App::Chart::Yahoo::latest_pred->add ($pred);
$App::Chart::Barchart::intraday_pred->add ($pred);
$App::Chart::Barchart::fiveday_pred->add ($pred);


#------------------------------------------------------------------------------
# weblink - contract specs

App::Chart::Weblink->new
  (pred => $pred,
   name => __('NYBOT _Contract Specifications'),
   desc => __('Open web browser at the NYBEX/COMEX contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.nymex.com/'
       . URI::Escape::uri_escape (App::Chart::symbol_commodity ($symbol))
         . '_spec.aspx';
   });


#------------------------------------------------------------------------------

# (set! barchart-suffix-delay-alist (acons ".NYBOT" 30
# 					 barchart-suffix-delay-alist))

App::Chart::Barchart::commodity_mung
  ($pred,
   # 'CC'         # COCOA
   # 'CT'         # COTTON NO. 2
   # 'MK'         # MINI COFFEE C
   # 'XA'         # ETHANOL
   # 'SE'         # SUGAR 14
   # 'OJ'         # FCOJ
   # 'OD'         # FCOJ DIFF: PAR=100
   'OB' => undef, # FCOJ-B -- seems to be missing from barchart
   'P' => 'PU',   # PULP
   # 'KC'         # COFFEE "C"
   # 'SB'         # SUGAR 11

   # 'AR'         # Aus. Dollar - N.Z. Dollar
   # 'AS'         # Australian Dollar - Canadian $
   # 'YA'         # Australian Dollar - Jap.Yen
   'MP' => 'OG',  # Small British Pd. - U.S. Dollar
   # 'SS'         # British Pd. - Swiss Franc
   # 'SY'         # British Pd. - Jap. Yen
   # 'HY'         # Canadian Dollar - Jap. Yen
   # 'EO'         # Euro - U.S. Dollar Regular (barchart "SMALL")
   # 'EP'         # Euro - Canadian Dollar
   # 'GB'         # Euro - Sterling
   # 'EJ'         # Euro - Jap. Yen
   # 'OL'         # Euro - Norw. Krone
   # 'RK'         # Euro - Swed. Krona
   'RA' => 'EQ',  # Euro - Australian Dollar
   # 'RZ'         # Euro - Swiss Franc
   # 'EU'         # Euro - U.S.Dollar Large
   'HR' => 'GY',  # Euro - Hungarian forint
   'EZ' => 'GZ',  # Euro - Czech koruna
   # 'ZY'         # Swiss Franc-Jap. Yen
   # 'DX'         # U.S. Dollar Index
   # 'AU'         # Aus. Dollar - U.S. Dollar
   # 'KU'         # U.S. Dollar - Swed. Krona
   # 'NS'         # U.S. Dollar - Norw. Krone
   # 'YF'         # U.S. Dollar - Swiss Franc
   'MF' => 'OF',  # Small U.S. Dollar - Swiss Franc
   # 'YP'         # U.S. Dollar - British Pound
   # 'YY'         # U.S. Dollar - Japanese Yen
   # 'SN'         # Small U.S. Dollar - Japanese Yen
   'ZR' => 'OR',  # U.S. Dollar - S.African Rand
   # 'ZX'         # U.S. Dollar - New Z Dollar
   # 'YD'         # U.S. Dollar - Canadian Dollar
   'SV' => 'OV',  # Small U.S. Dollar - Canadian Dollar
   'UF' => 'UY',  # U.S. Dollar - Hungarian forint
   # 'UZ'         # U.S. Dollar - Czech koruna
   'NJ' => 'EK',  # Norwegian Krone / Swedish krona

   # 'CR'         # Reuters CRB Index
   'R' => 'RX',   # Russell 1000
   'RM' => 'RJ',  # Russell 1000 Mini
   'GG' => 'VU',  # Russell 1000 Growth Index
   # 'VV'         # Russell 1000 Value Index
   # 'TO'         # Russell 2000
   'GH' => 'RG',  # Russell 2000 Growth Index
   'VB' => 'RV',  # Russell 2000 Value Index
   # 'TH'         # Russell 3000
   'YU' => 'YV',  # Revised NYSE Comp. Index
   # 'MU'         # Revised NYSE Small Comp. Index
  );


1;
__END__
