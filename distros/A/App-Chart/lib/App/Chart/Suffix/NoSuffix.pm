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

package App::Chart::Suffix::NoSuffix;
use 5.010;
use strict;
use warnings;
use Carp;
use Date::Parse;
use URI::Escape;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Yahoo;

my $shares_re = qr/^[^^][^.]+$/;
my $pred_shares = App::Chart::Sympred::Regexp->new ($shares_re);

$App::Chart::Yahoo::latest_pred->add ($pred_shares);
App::Chart::setup_source_help
  ($pred_shares, __p('manual-node','Yahoo Finance'));


# (yahoo-quote-delay! usa-symbol?
#   (lambda (symbol exchange)
#     ;; exchange is NasdaqSC, NasdaqNM, etc, not sure what the suffix bit is
#     (if (string-prefix-ci? "nasdaq" exchange)
# 	15    ;; NASDAQ
# 	20))) ;; AMEX, NYSE


#------------------------------------------------------------------------------
# weblinks - US company info

my $pred_nyse = App::Chart::Sympred::Proc->new
  (sub {
     my ($symbol) = @_;
     $symbol =~ $shares_re or return 0;
     my $exchange = symbol_exchange($symbol) // return 1;
     return ($exchange eq 'NYSE');
   });
my $pred_amex = App::Chart::Sympred::Proc->new
  (sub {
     my ($symbol) = @_;
     $symbol =~ $shares_re or return 0;
     my $exchange = symbol_exchange($symbol) // return 1;
     return ($exchange eq 'AMEX');
   });
my $pred_nasdaq = App::Chart::Sympred::Proc->new
  (sub {
     my ($symbol) = @_;
     $symbol =~ $shares_re or return 0;
     my $exchange = symbol_exchange($symbol) // return 1;
     # allow NasdaqNM, NasdaqSC etc
     return ($exchange =~ /^Nasdaq/i);
   });

App::Chart::Weblink->new
  (pred => $pred_nyse,
   name => __('NYSE _Company Information'),
   desc => __('Open web browser at the New York Stock Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.nyse.com/about/listed/'
       . URI::Escape::uri_escape($symbol) . '.html';
   });
App::Chart::Weblink->new
  (pred => $pred_amex,
   name => __('AMEX _Company Information'),
   desc => __('Open web browser at the American Stock Exchange page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.amex.com/?href=/equities/listCmp/EqLCCmpDesc.jsp?Product_Symbol=' . URI::Escape::uri_escape ($symbol);
   });
App::Chart::Weblink->new
  (pred => $pred_nasdaq,
   name => __('NASDAQ _Company Information'),
   desc => __('Open web browser at the NASDAQ page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://quotes.nasdaq.com/asp/summaryquote.asp?symbol='
       . URI::Escape::uri_escape ($symbol);
   });

# return exchange name string, or undef if not known
sub symbol_exchange {
  my ($symbol) = @_;
  require App::Chart::DBI;
  return (App::Chart::DBI->read_single
          ('SELECT exchange FROM info WHERE symbol=?', $symbol)
          //
          App::Chart::DBI->read_single
          ('SELECT exchange FROM latest WHERE symbol=?', $symbol));
}


#------------------------------------------------------------------------------

our @to_suffix =
  (
   # ^AEX
   [ '^AEX', '.AS' ],

   # ^ATX vienna
   # and must avoid ^ATLI and similar below
   [ '^ATX', '.VI' ],

   [ '^AX',   '.AX' ], # several, inc ^AXJO, ^AXPJ
   [ '^AORD', '.AX' ], # all ords
   [ '^ATLI', '.AX' ], # asx 20
   [ '^AFLI', '.AX' ], # asx 50
   [ '^ATOI', '.AX' ], # asx 100

   # ^BFX belgium
   [ '^BF', sub {
       my $pred = App::Chart::Sympred::Prefix->new ('^BF');
       my $timezone_brussels = App::Chart::TZ->new
         (name     => __('Brussels'),
          choose   => [ 'Europe/Brussels' ],
          fallback => 'CET-1');
       $timezone_brussels->setup_for_symbol ($pred);

       # only home page for now ...
       App::Chart::Weblink->new
           (pred => $pred,
            name => __('Brussels Stock Exchange Home Page'),
            desc => __('Open web browser at the Brussels Stock Exchange home page'),
            # now part of euronext ...
            url  => 'http://www.stockexchange.be');
     } ],

   # ^BVSP bovespa
   [ '^BV', '.SA' ],

   # ^BSESN bse sensitive
   [ '^BSE', '.BO' ],

   # ^CASE30
   [ '^CASE', '.CA' ],

   # ^CLDOW
   # ^CLDOWD
   [ '^CL', \&santiago ],

   # ^CCSI - cairo CMA
   [ '^CC', '.CA' ],

   # ^CSE composite
   [ '^CSE', sub {
       my $pred = App::Chart::Sympred::Prefix->new ('^CSE');
       my $timezone_colombo = App::Chart::TZ->new
         (name     => __('Colombo'),
          choose   => [ 'Asia/Colombo' ],
          fallback => 'LKT-5:30');
       $timezone_colombo->setup_for_symbol ($pred);

       # only home page for now ...
       App::Chart::Weblink->new
           (pred => $pred,
            name => __('_CSE Home Page'),
            desc => __('Open web browser at the Colombo Stock Exchange home page'),
            url  => 'http://www.cse.lk');
     } ],

   # ^DJEG20
   # ^DJEG20E
   # ^DJEG20D
   # ^DJEG20T
   # ^DJEG20ET
   # ^DJEG20DT
   [ '^DJEG', '.CA' ],

   # ^DWEG -- dow/wiltshire egypt
   [ '^DWEG', '.CA' ],

   [ '^DWCL', \&santiago ],

   # ^DWTH etc
   [ '^DWTH', '.BK' ],

   # ^DWVE
   # ^DWVED
   # ^DWVET
   # ^DWVEDT
   [ '^DWVE', '.CR' ],

   # ^FTSE
   [ '^FT', '.L' ],

   # ^GDAXI germany
   [ '^GDAXI', \&germany ],

   # ^GSPC  S&P 500
   [ '^GSPC', \&usa ],

   # ^GSPTSE - S&P TSX Composite, etc
   [ '^GSPT', '.TO' ],

   # ^HSI hang seng index
   [ '^H', '.HK' ],

   # paris
   [ '^FC', '.PA' ],

   # ^JKSE composite
   [ '^JK', '.JK' ],

   # http://finance.yahoo.com/intlindices?e=europe
   # ^IXX - ISE 100 options
   # http://www.ise.com/WebForm/options_product_indexDetails.aspx?categoryid=234&header0=true&menu2=true&link2=true&symbol=IXX
   [ '^IXX', '.JK' ],

   # ^KFX copenhagen
   [ '^KF', '.CO' ],

   # ^KLSE composite
   [ '^KL', '.KL' ],

   # ^KS11 korea
   # and avoid clash with ^KSE
   [ 'KS1', '.KS' ],

   # ^KSE karachi 100
   [ '^KSE', sub {
       my $pred = App::Chart::Sympred::Prefix->new ('^KSE');
       my $timezone_karachi = App::Chart::TZ->new
         (name     => __('Karachi'),
          choose   => [ 'Asia/Karachi' ],
          fallback => 'PKT-5');
       $timezone_karachi->setup_for_symbol ($pred);

       # only home page for now ...
       App::Chart::Weblink->new
           (pred => $pred,
            name => __('_Karachi Stock Exchange Home Page'),
            desc => __('Open web browser at the Karachi Stock Exchange home page'),
            url  => 'http://www.kse.com.pk');
     } ],

   # ^MERV
   [ '^MER', '.BA' ],

   # ^MIBTEL milan
   [ '^MIB', '.MI' ],

   # ^MXX ipc
   [ '^MX', '.MX' ],

   # ^N225
   # and not ^NZ50 etc
   [ '^N2', sub {
       my $pred = App::Chart::Sympred::Prefix->new ('^N2');
       App::Chart::TZ->tokyo->setup_for_symbol ($pred);

       # only home page for now ...
       App::Chart::Weblink->new
           (pred => $pred,
            name => __('_Tokyo Stock Exchange Home Page'),
            desc => __('Open web browser at the Tokyo Stock Exchange home page'),
            url  => App::Chart::Glib::Ex::MoreUtils::lang_select
            ('ja' => 'http://www.tse.or.jp',
             'en' => 'http://www.tse.or.jp/english/'));
     } ],
   # web link - TSE company info
   #
   # Eg. in english
   #     http://quote.tse.or.jp/tse/quote.cgi?F=listing/EDetail1&MKTN=T&QCODE=2001
   # and japanese
   #     http://quote.tse.or.jp/tse/quote.cgi?F=listing/Jdetail1&MKTN=T&QCODE=2001
   #

   # no tokyo symbols as such yet ...
   #
   # (weblink-handler! tokyo-symbol?
   #   (lambda (symbol)
   #     (list (_ 'TSE _Company Information')
   # 	  (_ 'Open web browser at the Tokyo Stock Exchange page for this company')
   # 	  (string-append 'http://quote.tse.or.jp/tse/quote.cgi?F=listing/'
   # 			 (lang-select '(('ja' 'J')
   # 					('en' 'E')))
   # 			 'Detail1&MKTN=T&QCODE='
   # 			 (chart-symbol-sans-dot symbol)))))


   # ^NZ50 new zealand
   [ '^NZ', '.NZ' ],

   # ^OEX  S&P 100
   [ '^OEX', \&usa ],

   # ^OMXSPI - stockholm
   [ '^OMX', '.ST' ],

   # ^OSEAX oslo
   [ '^OS', '.OL' ],

   # ^PSI - PSE composite phillipines
   [ '^PS', sub {
       my $pred = App::Chart::Sympred::Prefix->new ('^PS');
       my $timezone_manila = App::Chart::TZ->new
         (name     => __('Manila'),
          choose   => [ 'Asia/Manila' ],
          fallback => 'PHT-8');
       $timezone_manila->setup_for_symbol ($pred);

       # only home page for now ...
       App::Chart::Weblink->new
           (pred => $pred,
            name => __p('phillipine','_PSE Home Page'),
            desc => __('Open web browser at the Phillipine Stock Exchange home page'),
            url  => 'http://www.pse.org.ph');
     } ],

   # ^PX50 prague
   [ '^PX', sub {
       my $pred = App::Chart::Sympred::Prefix->new ('^PX');
       my $timezone_prague = App::Chart::TZ->new
         (name     => __('Prague'),
          choose   => [ 'Europe/Prague', 'Europe/Berlin' ],
          fallback => 'CET-1');
       $timezone_prague->setup_for_symbol ($pred);

       # only home page for now ...
       App::Chart::Weblink->new
           (pred => $pred,
            name => __p('prague','_PSE Home Page'),
            desc => __('Open web browser at the Prague Stock Exchange home page'),
            url  => App::Chart::Glib::Ex::MoreUtils::lang_select
            ('cs' => 'http://www.pse.cz',
             'en' => 'http://www.pse.cz/default.asp?language=english'));
     } ],

   # ^SMSI
   # not ^SML - S&P small 600
   [ '^SMS', '.MA' ],

   # ^SSEC shanghai composite
   # and not hitting ^SSMI
   [ '^SSE', '.SS' ],

   # ^SPCDNX - CDNX Index TSX venture
   [ '^SPC', '.V' ],

   # ^SPTSECP - S&P TSX 60 Capped, etc
   [ '^SPT', '.TO' ],

   # http://au.finance.yahoo.com/intlindices
   # ^SSMI - SMI switzerland
   # and not hitting ^SSEC
   [ 'SSM', '.SW' ],

   # ^STI straits times singapore
   [ '^STI', '.SI' ],

   # ^STOXX
   [ '^STO', \&germany ],

   # ^SXIP etc stoxx variations
   [ '^SX', \&germany ],

   # ^THDOW etc
   [ '^TH', '.BK' ],

   # ^TWII weighted
   [ '^TW', '.TW' ],

   # ^VEDOW
   # ^VEDOWD
   [ '^VE', '.CR' ],

  );


sub symbol_setups {
  my ($symbol) = @_;
  foreach my $elem (@to_suffix) {
    my $prefix = $elem->[0];
    if ($symbol =~ /^\Q$prefix\E/) {
      my $action = $elem->[1];
      $elem->[1] = \&noop;  # once only
      if (ref($action)) {
        &$action();
      } else {
        my $dummy = 'DUMMY' . $action;
        App::Chart::symbol_setups ($dummy);
      }
      return;
    }
  }

  my $pred = App::Chart::Sympred::Equal->new ($symbol);
  App::Chart::TZ->newyork->setup_for_symbol ($pred);
}
sub noop {}

# not sure if these indexes are based on a particular exchange
use constant::defer germany => sub {
  my $pred = App::Chart::Sympred::Any->new
    (App::Chart::Sympred::Prefix->new ('^STO'),
     App::Chart::Sympred::Prefix->new ('^SX'),
     App::Chart::Sympred::Regexp->new (qr/^.*DAX/));
  require App::Chart::Suffix::BE;
  no warnings 'once';
  $App::Chart::Suffix::BE::timezone_berlin->setup_for_symbol ($pred);
  return;
};

use constant::defer santiago => sub {
  # ^CLDOW
  # ^CLDOWD
  # ^DWCL
  # ^DWCLD
  # ^DWCLT
  # ^DWCLTD
  # used to have ^IPSA, but shows 0.00 as of March 2007
  my $pred = App::Chart::Sympred::Any->new
    (App::Chart::Sympred::Prefix->new ('^CL'),
     App::Chart::Sympred::Prefix->new ('^DWCL'));

  my $timezone_santiago = App::Chart::TZ->new
    (name     => __('Santiago'),
     choose   => [ 'America/Santiago' ],
     fallback => 'CLT+4');
  $timezone_santiago->setup_for_symbol ($pred);

  # only home page for now ...
  App::Chart::Weblink->new
      (pred => $pred,
       name => __('_Santiago Stock Exchange Home Page'),
       desc => __('Open web browser at the Santiago Stock Exchange home page'),
       url  => App::Chart::Glib::Ex::MoreUtils::lang_select
       ('es' => 'http://www.bolsadesantiago.com',
        'en' => 'http://www.bolsadesantiago.com/english/index.asp'));
  return;
};


use constant::defer usa => sub {
  my %sandp_table
    = ('^GSPC' => '500', # S&P 500
       '^OEX'  => '100', # S&P 100
      );

  require App::Chart::Weblink::SandP;
  my $weblink = App::Chart::Weblink::SandP->new
      (url_pattern  => 'http://www2.standardandpoors.com/portal/site/sp/{lang}/page.topic/indices_{symbol}/2,3,2,2,0,0,0,0,0,0,0,0,0,0,0,0.html',
       symbol_table => \%sandp_table);

  my $pred = $weblink->{'pred'};
  App::Chart::TZ->newyork->setup_for_symbol ($pred);
  return;
};

1;
__END__




# ^TV.N - total volume NYSE
(define (nyse-symbol? symbol)
  (string-suffix? '.N' symbol))

# ^TV.O - total volume NASDAQ
(define (nasdaq-symbol? symbol)
  (string-suffix? '.O' symbol))

(define (yahoo-index-symbol-usa? symbol)
  (or
   # http://finance.yahoo.com/indices?e=nasdaq -- and more below
   # ^IXBK - nasdaq banking
   # ^IXIC - nasdaq composite
   # ^IXF  - nasdaq financials
   # ^IXID - nasdaq industrials
   # ^IXIS - nasdaq insurance
   # ^IXQ  - nasdaq nnm composite
   # ^IXK  - nasdaq computer
   # ^IXFN - nasdaq other finances
   # ^IXUT - nasdaq telecommunications
   # ^IXTR - nasdaq transports
   (string-prefix? '^IX' symbol)

   (member symbol
	   '(
	     '^VIX'  # volatility
	     '^VXO'  # CBOE options volatility

	     # http://finance.yahoo.com/indices?e=dow_jones
	     '^DJA'  # Dow average
	     '^DJI'  # Dow
	     '^DJT'  # Dow transports
	     '^DJU'  # Dow utilities

	     # http://finance.yahoo.com/indices?e=new_york
	     '^NYA'  # NYSE composite
	     '^NIN'  # NYSE international
	     '^NTM'  # NYSE TMT
	     '^NUS'  # NYSE US 100
	     '^NWL'  # NYSE world leaders

	     # http://finance.yahoo.com/indices?e=nasdaq
	     '^NBI'  # nasdaq biotech
	     '^NDX'  # nasdaq 100 drm

	     # http://finance.yahoo.com/indices?e=sp
	     '^OEX'    # S&P 100
	     '^MID'    # S&P 400 midcap
	     '^GSPC'   # S&P 500
	     '^SPSUPX' # S&P composite 1500
	     '^SML'    # S&P small 600

	     # http://finance.yahoo.com/indices?e=other
	     '^XAX'    # AMEX composite
	     '^IIX'    # AMEX internet
	     '^NWX'    # AMEX networking
	     '^DWC'    # DJ wilshire 5000 tot
	     '^XMI'    # major market index
	     '^PSE'    # NYSE arca tech 100
	     '^SOXX'   # Philadelphia semiconductor
	     '^DOT'    # Philadelphia/thestreet.com internet
	     '^RUI'    # Russell 1000
	     '^RUT'    # Russell 2000
	     '^RUA'    # Russell 3000

	     # http://finance.yahoo.com/indices?e=treasury
	     '^TNX'    # 10-year treasury bond interest rate
	     '^IRX'    # 13-week treasury note interest rate
	     '^TYX'    # 30-year treasury bond interest rate
	     '^FVX'    # 5-year treasury bond interest rate

	     # http://finance.yahoo.com/indices?e=commodities
	     '^DJC'    # Dow commodities
	     '^DJS2'   # Dow industrial avg settle
	     '^XAU'    # Philadelphia gold and silver index

	     # old bits
	     '^WIL5' # Wiltshire 5000 - gone, now ^DWC maybe
	     ))))
