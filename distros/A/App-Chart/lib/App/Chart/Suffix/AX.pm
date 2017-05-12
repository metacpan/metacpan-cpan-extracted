# Australian Stock Exchange setups.

# Copyright 2007, 2008, 2009, 2015, 2016 Kevin Ryde

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

package App::Chart::Suffix::AX;
use 5.006;
use strict;
use warnings;
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Weblink::SandP;

use App::Chart::Google;
use App::Chart::Yahoo;

# no good, stuck at 5 Aug 08
# use App::Chart::Float;


# http://au.finance.yahoo.com/indices
# and on the ^AT symbols must avoid ^ATX in VI.pm
#
# ^AXJO
# ^AXPJ -- and more ^AX
# ^AORD -- all ords
# ^ATLI -- asx 20
# ^AFLI -- asx 50
# ^ATOI -- asx 100
#
our $pred_indexes = App::Chart::Sympred::Regexp->new
  (qr/^\^A(X|ORD|TLI|FLI|TOI)/);
our $pred_shares     = App::Chart::Sympred::Suffix->new ('.AX');

my $pred_any = App::Chart::Sympred::Any->new ($pred_shares, $pred_indexes);
App::Chart::TZ->sydney->setup_for_symbol ($pred_any);

# App::Chart::setup_source_help
#   ($pred_any, __p('manual-node','Australian Stock Exchange'));
# while nothing ASX specific ...
App::Chart::setup_source_help
  ($pred_any, __p('manual-node','Yahoo Finance'));

# ordinary shares like NAB.AX, not prefs like NABHA.AX
my $pred_ordinaries = App::Chart::Sympred::Regexp->new (qr/^.{0,3}\.AX$/);

# but no "spreadsheet format" for ASX, just the weblink for now
$App::Chart::Google::google_web_pred->add ($pred_ordinaries);




# See http://www.asx.com.au/resources/education/basics/trading_hours_asx.htm
# SEATS takes changes only between 7am and 7pm
# 5pm to 7pm is only amend/cancel, no new orders, which is unlikely to be
# too interesting, but update during that anyway
# (yahoo-quote-lock! australia-symbol?
# 		   #,(hms->seconds 7 0 0) #,(hms->seconds 19 0 0))
#
# ;; Yahoo index values are based on last trades, so they only update during
# ;; trading 10:00 to 16:06.  Not sure if they update for after hours
# ;; broker-to-broker trades 16:06 to 17:00, allow for that by locking only
# ;; after 17:00.
# (yahoo-quote-lock! yahoo-index-symbol-australia?
# 		   #,(hms->seconds 10 0 0) #,(hms->seconds 17 0 0))


#------------------------------------------------------------------------------
# weblink - ASX company info
# But is bloated by 1.5mbytes of script crap.
#
# http://www.asx.com.au/asx/research/companyInfo.do?by=asxCode&asxCode=ANZ

App::Chart::Weblink->new
  (pred => $pred_shares,
   name => __('ASX _Company Information'),
   desc => __('Open web browser at the Australian Stock Exchange page for this company (bad javascript bloat)'),
   proc => sub {
     my ($symbol) = @_;
     $symbol = App::Chart::symbol_sans_suffix($symbol);

     # As of Feb 2009 the info search doesn't accept a pref or convertible
     # note symbol like "NABHA", only the issuing company "NAB", so prune
     # accordingly.
     $symbol = substr($symbol,0,3);

     return 
       'http://www.asx.com.au/asx/research/companyInfo.do?by=asxCode&asxCode='
       . URI::Escape::uri_escape($symbol);
   });

#------------------------------------------------------------------------------
# weblink - S&P index info

my %sandp_table
  = ('^AORD' => 'asxallo',
     '^ATLI' => 'asx20',
     '^AFLI' => 'asx50',
     '^ATOI' => 'asx100',
     '^AXJO' => 'asx200',
     '^AXKO' => 'asx300',
     '^AXMD' => 'asxmc50',
     '^AXSO' => 'asxsmo',

     # sectors, only one shared page
     '^AXEJ' => 'asxsec',  # Energy
     '^AXMJ' => 'asxsec',  # Materials
     '^AXNJ' => 'asxsec',  # S&P ASX 200 Industrials
     '^AXDJ' => 'asxsec',  # S&P ASX 200 Consumer Discretionary
     '^AXSJ' => 'asxsec',  # S&P ASX 200 Consumer Staples
     '^AXHJ' => 'asxsec',  # S&P ASX 200 Health Care
     '^AXFJ' => 'asxsec',  # S&P ASX 200 Financials
     '^AXIJ' => 'asxsec',  # S&P ASX 200 Information Technology
     '^AXTJ' => 'asxsec',  # S&P ASX 200 Telecommunication Services
     '^AXUJ' => 'asxsec',  # S&P ASX 200 Utilities
     '^AXPJ' => 'asxsec',  # S&P ASX 200 Property Trusts
     '^AXXJ' => 'asxsec',  # S&P ASX 200 Financial-x-Property Trusts
    );

App::Chart::Weblink::SandP->new
  (url_pattern => 'http://www2.standardandpoors.com/portal/site/sp/{lang}/page.topic/indices_{symbol}/2,3,2,8,0,0,0,0,0,0,0,0,0,0,0,0.html',
   symbol_table => \%sandp_table);


1;
__END__





# Other Sites:
#
# eoddata.com -- pay
# www.tradingroom.com.au -- gone to afr.com with login required
# findata.co.nz -- ASX past 30 days, incl prefs, but login to download more
#
# asxhistoricaldata.com
# week's worth of all shares zipped like (about 80 kbytes) back to 1997
# http://www.asxhistoricaldata.com/wp-content/uploads/week20160429.zip
# monthly and yearly files before recent weeks
# ordinaries only, no prefs
#
# http://www.cooltrader.com.au
# Register, free 10am next day, renew annually, daily csv files.
#
# barchart.com includes ASX, but register for historical maybe
#
# http://www.smh.com.au/business/markets/quotes/price-history/BHP/bhp-billiton-limited
# http://www.smh.com.au/business/markets/quotes/price-history/BHP/bhp-billiton-limited?page=2
# HTML table of recent prices and page to go back, about 100k each month
# Maybe only selected top ordinaries
