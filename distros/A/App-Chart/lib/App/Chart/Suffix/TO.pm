# Toronto Stock Exchange setups (incl TSX Venture).

# Copyright 2005, 2006, 2007, 2008, 2009, 2010 Kevin Ryde

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

package App::Chart::Suffix::TO;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;
use App::Chart::Weblink::SandP;
use App::Chart::Yahoo;


our $timezone_toronto = App::Chart::TZ->new
  (name     => __('Toronto'),
   choose   => [ 'America/Toronto' ],
   fallback => 'EST+5');

# http://ca.finance.yahoo.com/indices?u
#   ^GSPTSE - S&P TSX Composite
#   ^SPTSECP - S&P TSX 60 Capped
#   ^SPTSECP3 - S&P TSX 300 Capped
#   ^SPTSEM - Midcap
#   ^SPTSES - Smallcap
#   ^SPTTEN - Energy
#   ^SPTTFS - Financials
#   ^SPTTGD - Gold
#   ^SPTTTK - Information Technology
#   ^GSPTTCD - Consumer Discretionary
#   ^GSPTTCS - Consumer Staples
#   ^GSPTTHC - Health Care
#   ^GSPTTIN - Industrials
#   ^GSPTTMN - Diversified Metals & Mining
#   ^GSPTTMT - Materials
#   ^GSPTTRE - Real Estate
#   ^GSPTTTS - Telecommunications Services
#   ^GSPTTUT - Utilities
#
# TSX Venture
#   ^SPCDNX - CDNX Index
#

my $pred_indexes = App::Chart::Sympred::Regexp->new (qr/^\^(GSPT|SPT|SPC)/);
my $pred_shares = App::Chart::Sympred::Regexp->new (qr/\.(TO|V)$/);

my $pred_any = App::Chart::Sympred::Any->new ($pred_indexes, $pred_shares);
$timezone_toronto->setup_for_symbol ($pred_any);


# ;; TSX trades 9:30 to 4pm and extended session 4:10pm to 5pm for member firms
# ;; see: http://www.tsx.com/en/contactUs/index.html#holidays
# (yahoo-quote-lock! toronto-symbol?
# 		   #,(hms->seconds 9 30 0) #,(hms->seconds 17 0 0))
#
# ;; dunno if indexes update in extended session, cover that just in case
# (yahoo-quote-lock! yahoo-index-symbol-toronto?
# 		   #,(hms->seconds 9 30 0) #,(hms->seconds 17 0 0))

#------------------------------------------------------------------------------
# weblink - only the home page for now ...

App::Chart::Weblink->new
  (pred => $pred_any,
   name => __('_Toronto Stock Exchange Home Page'),
   desc => __('Open web browser at the Toronto Stock Exchange home page'),
   url  => 'http://www.tsx.com');



#------------------------------------------------------------------------------
# weblink - S&P index info

my %sandp_table
  = ('^GSPTSE'   => 'tsx',
     '^SPTSECP'  => 'tsx60cap',
     # '^SPTSECP3' => undef, # S&P TSX 300 Capped
     '^SPTSEM'   => 'tsxmid',
     '^SPTSES'   => 'tsxsml',
     '^SPCDNX'   => 'tsxven', # TSX Venture

     #
     # sectors, one shared page
     '^SPTTEN' => 'tsxsec',  # Energy
     '^SPTTFS' => 'tsxsec', # Financials
     '^SPTTGD' => 'tsxsec', # Gold
     '^SPTTTK' => 'tsxsec', # Information Technology
     '^GSPTTCD'=> 'tsxsec', # Consumer Discretionary
     '^GSPTTCS'=> 'tsxsec', # Consumer Staples
     '^GSPTTHC'=> 'tsxsec', # Health Care
     '^GSPTTIN'=> 'tsxsec', # Industrials
     '^GSPTTMN'=> 'tsxsec', # Diversified Metals & Mining
     '^GSPTTMT'=> 'tsxsec', # Materials
     '^GSPTTRE'=> 'tsxsec', # Real Estate
     '^GSPTTTS'=> 'tsxsec', # Telecommunications Services
     '^GSPTTUT' => 'tsxsec', # Utilities
    );

App::Chart::Weblink::SandP->new
  (url_pattern => 'http://www2.standardandpoors.com/portal/site/sp/{lang}/page.topic/indices_{symbol}/2,3,2,3,0,0,0,0,0,0,0,0,0,0,0,0.html',
   symbol_table => \%sandp_table);


1;
__END__
