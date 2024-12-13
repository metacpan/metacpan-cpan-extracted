# Copyright 2007, 2008, 2009, 2010, 2011, 2015, 2016, 2017, 2019, 2020, 2023, 2024 Kevin Ryde

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


# Protocols:
#
# Don't know the full state of what Yahoo intends to offer.
# But there's a range of "v7", "v8", "v11" URL forms.  These might be
# meant as data sources for Yahoo client-side viewing software.
#
# Here currently using the v8 method, as it seems to be without
# protocol level hoops.  Presumably it's for personal use and possibly
# after creating a Yahoo account -- even if it works without doing so
# or logging in.
#
#
# Data Format:
#
# Each of these methods can apparently return results in either CSV or
# JSON format.
#
# The JSON form, maybe CSV too, has prices put through
# single-precision floats, ie. 24 bit mantissa, which causes some
# price strings like 123.44999999 instead of 123.45.
# 
# The parse here tries to massage that back to an apparent intended
# number of decimals.  Eg. 2 decimals for dollars and cents, but
# allowing for trading in fractions of a cent which is 3 decimals.
# 
# In daily data download, current day trading in progress shows in
# today's date and changes though the course of trading until being
# fixed maybe at marked close, or maybe the next day.  Don't know
# how pre-market or post-market trading is applied, or what happens
# if a few futures or similar might even be 24 hour trading.
#
#
# Cookies and Crumb:
#
# There's been some protocol hoops to jump through in recent times.
# It seems to be sometimes on the v7 form, maybe always on v11.
# The v7 had seemed fine asking for the latest few days daily data,
# and it's possible lately needs nothing for any amount.
#
# The hoops consist of
#
#     - Fetch one of the finance.yahoo.com web pages to get a
#       HTTP Set-Cookie header.
#     - Maybe answer the ridiculous EU cookie consent on the page.
#       Maybe that depends where your IP looks like it's from.
#     - Look deep within script in that page for a "crumb" string.
#       Or maybe a further "getcrumb" web fetch, but seems result
#       is embedded in the page.
#     - On each data download, HTTP Cookie header, and URL crumb
#       field.
#
# Presumably this is designed as a level of difficulty, to stop the
# past quotes and data that could be had from a single URL (and which
# Yahoo apparently found was widely abused beyond personal use).
#


package App::Chart::Yahoo;
use 5.010;
use strict;
use warnings;
use Carp;
use Date::Calc;
use Date::Parse;
use List::Util qw (min max);
use POSIX ();
use Time::Local;
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use Tie::TZ;
use App::Chart;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::DownloadHandler::IndivChunks;
use App::Chart::IntradayHandler;
use App::Chart::Latest;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;

# uncomment this to run the ### lines
use Smart::Comments;

use constant DEBUG => 0;


# .X or .XY or no suffix
our $yahoo_pred = App::Chart::Sympred::Proc->new
  (sub {
     my ($symbol) = @_;
     return ($symbol !~ /\.(FQ|LJ)$/
             && $symbol =~ /[.=]..?$|^[^.]+$/);
   });

my $download_pred = App::Chart::Sympred::Any->new ($yahoo_pred);
our $latest_pred  = App::Chart::Sympred::Any->new ($yahoo_pred);
our $index_pred   = App::Chart::Sympred::Regexp->new (qr/^\^|^0.*\.SS$/);
my $futures_pred  = App::Chart::Sympred::Any->new;

# overridden by specific nodes
App::Chart::setup_source_help
  ($yahoo_pred, __p('manual-node','Yahoo Finance'));


#-----------------------------------------------------------------------------
# Weblink - basic quote page
#
# This is for instance
#     https://finance.yahoo.com/quote/CSCO/
#     https://finance.yahoo.com/quote/BHP.AX/
#
# There was a short time in July 2024 when seemed had to be the
# national page like au.finaince.yahoo.com for BHP.AX and similar.
# Think that's no longer so.  But the page badly bloated to an mbyte
# of junk, so might not want to use.
#
# The accelerator key is "_Y" so as not to clash with "_S" for shares
# on various stock exchange links like "ASX IRM _Stock Information"

App::Chart::Weblink->new
  (pred => $yahoo_pred,
   name => __('_Yahoo Stock Page'),
   desc => __('Open web browser at the Yahoo quote page for this stock'),
   proc => sub {
     my ($symbol) = @_;
     return "https://"
       . App::Chart::Database->preference_get ('yahoo-quote-host',
                                               'finance.yahoo.com')
       . "/quote/"
       . URI::Escape::uri_escape($symbol);
   });


#-----------------------------------------------------------------------------
# Quote Dealy from Exchanges Page
#
# This uses the help page
#
#     https://help.yahoo.com/kb/finance-app-for-android/exchanges-data-providers-yahoo-finance-sln2310.html
#
# which includes a table of quote delays for exchanges, by suffix.
#
# Past URL was https://help.yahoo.com/kb/SLN2310.html and the
# same SLN part would suggest it's about everything.
# Distant past URL was http://finance.yahoo.com/exchanges

use constant EXCHANGES_URL => 'https://help.yahoo.com/kb/finance-app-for-android/exchanges-data-providers-yahoo-finance-sln2310.html';

# Refetch the exchanges page after this many days.
# The page is bloated by a script greatly exceeding the actual info,
# and doesn't offer a Last-Modified.  Expect it changes infrequently.
#
use constant EXCHANGES_UPDATE_DAYS => 14;

# containing arefs [$pred,'.XX']
my @quote_delay_aliases;

sub setup_quote_delay_alias {
  my ($pred, $suffix) = @_;
  push @quote_delay_aliases, [ $pred, $suffix ];
}

sub symbol_quote_delay {
  my ($symbol) = @_;

  # indices all in real time
  if ($index_pred->match($symbol)) { return 0; }

  my $suffix = App::Chart::symbol_suffix ($symbol);
  my $h = exchanges_data();
  my $delay = $h->{$suffix};

  if (! defined $delay) {
    if (my $elem = List::Util::first { $_->[0]->match ($symbol) }
        @quote_delay_aliases) {
      $suffix = $elem->[1];
      $delay = $h->{$suffix};
    }
  }
  if (! defined $delay) {
    # guess default 20 minutes
    $delay = 20;
  }
  return $delay;
}

# exchanges_data() return a hashref of exchange delay data like
#   { '.AX' => 20, '.BI' => 15 }
# which means .AX quotes are delayed by 20 minutes.
#
sub exchanges_data {
  require App::Chart::Pagebits;
  return App::Chart::Pagebits::get
    (name      => __('Yahoo exchanges page'),
     url       => EXCHANGES_URL,
     key       => 'yahoo-quote-delays',
     freq_days => EXCHANGES_UPDATE_DAYS,
     parse     => \&exchanges_parse);
}
sub exchanges_parse {
  my ($content) = @_;
  my $h = {};

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new (headers => ['Suffix', 'Delay']);
  $te->parse($content);
  if (! $te->tables) {
    warn "Yahoo exchanges page unrecognised, assuming 15 min quote delay";
    return $h;
  }

  foreach my $row ($te->rows) {
    my $suffix = $row->[0];
    my $delay = $row->[1];
    next if ($suffix eq 'N/A');

    # eg "15 min"
    # or "15 min**"  with footnote
    #
    if ($delay =~ /^(\d+) min/) {
      $delay = $1;
    } elsif ($delay =~ /real/i) {
      $delay = 0;
    } else {
      warn "Yahoo exchanges page unrecognised delay: \"$delay\"\n";
      next;
    }

    $h->{$suffix} = $delay + 0;
  }
  return $h;
}


#-----------------------------------------------------------------------------
# Info - Share Names
# 
# This uses the info pages like
#
#    https://query2.finance.yahoo.com/v1/finance/search?q=CSCO&enableFuzzyQuery=false
# 
# which is a JSON format of various company information etc.
# 
# The JSON looks like
#     {"explains":[],
#      "count":7,
#      "quotes":[{"exchange":"NMS",
#                 "shortname":"Cisco Systems, Inc.",
#                 "quoteType":"EQUITY",
#                 "symbol":"CSCO",
#                 ...
#                 
# There can be multiple exchanges in the quotes list, use the first.
# Other fields include
# 
#     longname    occasionally shorter than shortname actually
#                 but use shortname
#                 
#     exchDisp    longer display name for the exchange,
#                 eg. exchange=NMS and exchDisp=NASDAQ.
#                 or  exchange=ASX and exchDisp=Australian.
#                 Think the exchange code more useful.
# 
# The URL has an optional &newsCount=0 for no news events, but think
# that's the default anyway.

# FIXME: Disabled temporarily.
# App::Chart::DownloadHandler->new
#   (name         => __('Yahoo info'),
#    key          => 'Yahoo-info',
#    pred         => $download_pred,
#    proc         => \&info_download,
#    recheck_days => 14);

sub info_url {
  my ($symbol) = @_;
  return 'https://query2.finance.yahoo.com/v1/finance/search?q='
    . URI::Escape::uri_escape ($symbol)
    . '&enableFuzzyQuery=false';
}

sub info_download {
  my ($symbol_list) = @_;

  foreach my $symbol (@$symbol_list) {
    App::Chart::Download::status(__('Yahoo info'), $symbol);
    my $url = info_url($symbol);
    my $resp = App::Chart::Download->get ($url);
    my $h = info_parse($resp);
    $h->{'recheck_list'} = [ $symbol ];
    App::Chart::Download::write_daily_group ($h);
  }
}

sub info_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);
  my @info;
  my $h = { source    => __PACKAGE__,
            info      => \@info };
  require JSON;
  my $J = JSON::from_json($content) // {};
  my $quotes = $J->{'quotes'} // [];
  if (my $e = $quotes->[0]) {
    my $symbol = $e->{'symbol'};

    my $name = $e->{'shortname'};
    if (defined $name) {
      # ASX shares have the symbol repeated at the end of shortname,
      # like "BHP FPO [BHP]".  Seems unnecessary, so strip that.
      my $end = '[' . App::Chart::symbol_sans_suffix ($symbol) .']';
      $name =~ s/\s*\Q$end\E$//;
    }

    push @info, { symbol   => $symbol,
                  name     => $name,
                  exchange => $e->{'exchange'},
                };
  }
  return $h;
}


#------------------------------------------------------------------------------
# Latest
#
# This uses for example
#
#     https://query1.finance.yahoo.com/v7/finance/chart/BHP.AX?period1=1718841600&period2=1719532800&interval=1d&events=history&close=unadjusted
#
# periodi1 and period2 are Unix style seconds since 1 Jan 1970 GMT.
#
# https://stackoverflow.com/questions/47076404/currency-helper-of-yahoo-sorry-unable-to-process-request-at-this-time-erro
# ->
# https://stackoverflow.com/questions/47064776/has-yahoo-suddenly-today-terminated-its-finance-download-api

App::Chart::LatestHandler->new
  (pred => $latest_pred,
   proc => \&latest_download,
   max_symbols => 1);  # downloads go 1 at a time

sub latest_download {
  my ($symbol_list) = @_;

  foreach my $symbol (@$symbol_list) {
    my $tdate = daily_available_tdate ($symbol);
    App::Chart::Download::status(__('Yahoo quote'), $symbol);

    my $lo_timet = tdate_to_unix($tdate - 4);
    my $hi_timet = tdate_to_unix($tdate + 2);

    my $events = 'history';
    my $url = "https://query1.finance.yahoo.com/v7/finance/chart/"
      . URI::Escape::uri_escape($symbol)
      ."?period1=$lo_timet"
      ."&period2=$hi_timet"
      ."&interval=1d"
      ."&events=$events"
      ."&close=unadjusted";

    # unknown symbol is 404 with json error details
    #
    my $resp = App::Chart::Download->get ($url, allow_404 => 1,);
    App::Chart::Download::write_latest_group
        (latest_parse($symbol,$resp,$tdate));
  }
}

sub latest_parse {
  my ($symbol, $resp, $tdate) = @_;

  my $content = $resp->decoded_content (raise_error => 1);
  require JSON;
  my $json = JSON::from_json($content);

  my %record = (symbol => $symbol,
               );
  my $h = { source      => __PACKAGE__,
            resp        => $resp,
            prefer_decimals => 2,
            date_format => 'ymd',
            data        => [ \%record ],
          };
  if (defined (my $error = $json->{'chart'}->{'error'}->{'code'})) {
    $record{'error'} = $error;
  }

  if (my $result = $json->{'chart'}->{'result'}->[0]) {
    my $meta = $result->{'meta'}
      // die "Yahoo JSON oops, no meta";
    $record{'currency'} = $meta->{'currency'},
      $record{'exchange'} = $meta->{'exchangeName'},

      my $symbol_timezone = App::Chart::TZ->for_symbol ($symbol);
    my $timestamps = $result->{'timestamp'}
      // die "Yahoo JSON oops, no timestamp";

    if (@$timestamps) {

      # timestamps are time of last trade, as can be seen by looking at
      # something with low enough volume, eg. RMX.AX
      #
      if (defined (my $timet = $timestamps->[-1])) {
        ($record{'last_date'}, $record{'last_time'})
          = $symbol_timezone->iso_date_time($timet);
      }

      if (my $indicators = $result->{'indicators'}->{'quote'}->[0]) {
        foreach my $key ('open','high','low') {
          if (my $aref = $indicators->{$key}) {
            $record{$key} = crunch_trailing_nines($aref->[$#$timestamps]);
          }
        }
        if (my $aref = $indicators->{'volume'}) {
          $record{'volume'} = $aref->[$#$timestamps];
        }
        if (my $aref = $indicators->{'close'}) {
          my $last = $record{'last'}
            = crunch_trailing_nines($aref->[$#$timestamps]);

          # "change" from second last timestamp, if there is one.
          # As of Nov 2017, XAUUSD=X only ever gives a single latest
          # quote from v7, no previous day to compare.
          #
          if (defined $last
              && scalar(@$timestamps) >= 2
              && defined(my $prev = $aref->[$#$timestamps - 1])) {
            $record{'change'}
              = App::Chart::decimal_sub($last, crunch_trailing_nines($prev));
          }
        }
      }
    }

    if (defined $record{'last_date'}
        && (my $splits = $result->{'events'}->{'splits'})) {
      while (my ($timet, $href) = each %$splits) {
        my $split_date = $symbol_timezone->iso_date($timet);
        if ($split_date eq $record{'last_date'}) {
          __x('Split {ratio}', ratio => $href->{'splitRatio'})
        }
      }
    }
  }
  return $h;
}


#-----------------------------------------------------------------------------
# Download Data
#
# This uses the historical prices page like
#
#     https://finance.yahoo.com/quote/AMP.AX/history?p=AMP.AX
#
# which puts a cookie like
#
#     Set-Cookie: B=fab5sl9cqn2rd&b=3&s=i3; expires=Sun, 03-Sep-2018 04:56:13 GMT; path=/; domain=.yahoo.com
#
# and contains buried within 1.5 mbytes of hideous script
#
#    <script type="application/json" data-sveltekit-fetched data-url="https://query1.finance.yahoo.com/v1/test/getcrumb?lang=en-US&amp;region=US" data-ttl="59">{"status":200,"statusText":"OK","headers":{},"body":"DKVWQE/ggh4"}</script>
#
# Any \u002F or similar is escaped "/" character or similar.
# The crumb is included in a CSV download query like the following
# (alas can't use http, it redirects to https)
#
#     https://query1.finance.yahoo.com/v7/finance/download/AMP.AX?period1=1503810440&period2=1504415240&interval=1d&events=history&crumb=hdDX/HGsZ0Q
#
# period1 is the start time, period2 the end time, both as Unix seconds
# since 1 Jan 1970.  Not sure of the timezone needed.  Some experiments
# suggest it depends on the timezone of the symbol.  http works as well as
# https.  The result is like
#
#     Date,Open,High,Low,Close,Adj Close,Volume
#     2017-09-07,30.299999,30.379999,30.000000,30.170000,30.170000,3451099
#
# The "9999s" are some bad rounding off to what would be usually at most
# 3 (maybe 4?) decimal places.
#
# Response is 404 if no such symbol, 401 unauthorized if no cookie or crumb.
#
# "events=div" gives dividends like
#
#     Date,Dividends
#     2017-08-11,0.161556
#
# "events=div" gives splits like, for a consolidation (GXY.AX)
#
#     Date,Stock Splits
#     2017-05-22,1/5
#
#----------------
# For reference, there's a "v8" which is json format (%7C = "|")
#
#     https://query2.finance.yahoo.com/v8/finance/chart/IBM?formatted=true&lang=en-US&region=US&period1=1504028419&period2=1504428419&interval=1d&events=div%7Csplit&corsDomain=finance.yahoo.com
#
# This doesn't require a cookie and crumb, has some info like symbol
# timezone.  The numbers look like they're rounded through 32-bit single
# precision floating point, for example "142.55999755859375" which is 142.55
# in a 23-bit mantissa.  log(14255000)/log(2) = 23.76 bits
# Are they about the same precision as the CSV ?
#
# FIXME: All prices look like they're split-adjusted, which is ok if that's
# what you want and are downloading a full data set, but bad for incremental
# since you don't know when a change is applied.
#

App::Chart::DownloadHandler->new
  (name       => __('Yahoo'),
   pred       => $download_pred,
   available_tdate_by_symbol => \&daily_available_tdate,
   available_tdate_extra     => 2,
   url_and_cookiejar_func    => \&daily_url_and_cookiejar,
   proc       => \&daily_download,
   chunk_size => 150);

sub daily_available_tdate {
  my ($symbol) = @_;

  # Sep 2017: daily data is present for the current day's trade, during the
  # trading session.  Try reckoning it complete at 6pm.
  return App::Chart::Download::tdate_today_after
    (18,0, App::Chart::TZ->for_symbol ($symbol));

  # return App::Chart::Download::tdate_today_after
  #   (10,30, App::Chart::TZ->for_symbol ($symbol))
  #     - 1;
}

sub daily_download {
  my ($symbol_list) = @_;
  App::Chart::Download::status (__('Yahoo daily data'));

  # App::Chart::Download::verbose_message ("Yahoo crumb $crumb cookies\n"
  #                                        . $jar->as_string);

  my $crumb_errors = 0;
 SYMBOL: foreach my $symbol (@$symbol_list) {
    my $lo_tdate = App::Chart::Download::start_tdate_for_update (@$symbol_list);
    my $hi_tdate = daily_available_tdate ($symbol);

    App::Chart::Download::status
        (__('Yahoo data'), $symbol,
         App::Chart::Download::tdate_range_string ($lo_tdate, $hi_tdate));

    my $lo_timet = tdate_to_unix($lo_tdate - 2);
    my $hi_timet = tdate_to_unix($hi_tdate + 2);

    # my $data  = cookie_and_crumb_data();
    # if (! defined $data) {
    #   print "Yahoo $symbol no daily cookie data\n";
    #   next SYMBOL;
    # }
    # my $crumb = URI::Escape::uri_escape($data->{'crumb'});
    # my $jar = http_cookies_from_string($data->{'cookies'} // '');

    my $h = { source          => __PACKAGE__,
              prefer_decimals => 2,
              date_format   => 'ymd',
            };
    foreach my $elem (['history',\&daily_parse_v8],
                      # ['div',    \&daily_parse_div],
                      # ['split',  \&daily_parse_split]
                     ) {
      my ($events,$parse) = @$elem;
      my $url = "https://query1.finance.yahoo.com/v7/finance/chart/"
        . URI::Escape::uri_escape($symbol)
        . "?period1=$lo_timet"
        . "&period2=$hi_timet"
        . "&interval=1d"
        . "&events=$events"
        # . "&crumb=$crumb"
        ;

      my $resp = App::Chart::Download->get ($url,
                                            allow_401 => 1,
                                            allow_404 => 1,
                                            # cookie_jar => $jar,
                                           );
      if ($resp->code == 401) {
        App::Chart::Download::verbose_message ($resp->as_string . "\n");
        if (++$crumb_errors >= 0) {
          die "Yahoo: crumb authorization failed"; 
        }
        App::Chart::Database->write_extra ('', 'yahoo-daily-cookies', undef);
        redo SYMBOL;
      }
      if ($resp->code == 404) {
        print "Yahoo $symbol does not exist\n";
        next SYMBOL;
      }
      $parse->($symbol,$resp,$h, $hi_tdate);
    }
    ### $h
    App::Chart::Download::write_daily_group ($h);
  }
}

sub daily_parse_v8 {
  my ($symbol, $resp) = @_;
  my $hi_tdate = daily_available_tdate ($symbol);
  my @data = ();
  my $h = { source          => __PACKAGE__,
            prefer_decimals => 2,  # default
            date_format     => 'ymd',
            data            => \@data,
          };

  my $content = $resp->decoded_content (raise_error => 1);
  require JSON;
  my $json = JSON::from_json($content);
  my $result = $json->{'chart'}->{'result'}->[0];

  my $meta = $result->{'meta'} // {};
  my $meta_symbol = $meta->{'symbol'} // '';
  if ($meta_symbol ne $symbol) {
    die "Yahoo JSON oops, symbol wanted $symbol got $meta_symbol";
  }
  # Trading in pence Sterling is "GBp", such as TSCO.L
  $h->{'currencies'}->{$symbol} = $meta->{'currency'};
  $h->{'exchanges'}->{$symbol} = $meta->{'exchangeName'};
  if (defined(my $decimals = $meta->{'priceHint'})) {
    $h->{'prefer_decimals'} = $decimals;
  }

  my $gmtoffset = $meta->{'gmtoffset'};
  my $timet_to_iso = sub {
    my ($t) = @_;
    return (defined $t ? POSIX::strftime('%Y-%m-%d', gmtime($t + $gmtoffset)) : undef);
  };

  my $timestamps = $result->{'timestamp'};
  my $quote= $result->{'indicators'}->{'quote'}->[0];
  my $opens   = $quote->{'open'}   // [];
  my $highs   = $quote->{'high'}   // [];
  my $lows    = $quote->{'low'}    // [];
  my $closes  = $quote->{'close'}  // [];
  my $volumes = $quote->{'volume'} // [];
  foreach my $i (0 .. $#$timestamps) {
    my $date = $timet_to_iso->($timestamps->[$i]);
    if (App::Chart::Download::iso_to_tdate_floor($date) > $hi_tdate) {
      # Current day's trading shows in the data.
      # Don't enter it in the database until close of trade.
      next;
    }
    push @data, { symbol => $symbol,
                  date   => $date,
                  open   => crunch_trailing_nines($opens->[$i]),
                  high   => crunch_trailing_nines($highs->[$i]),
                  low    => crunch_trailing_nines($lows->[$i]),
                  close  => crunch_trailing_nines($closes->[$i]),
                  volume => $volumes->[$i] };
  }

  my $events = $result->{'events'} // {};
  ### $events

  # Eg. BHP.AX
  #   date     1709766000
  #   amount   1.096196
  #
  foreach my $dividend (values %{$events->{'dividends'} // {}}) {
    push @{$h->{'dividends'}},
      { symbol  => $symbol,
        ex_date => $timet_to_iso->($dividend->{'date'}),
        amount  => $dividend->{'amount'},
      };
  }

  # eg. 1:30 split from NKLA.MX on 21 Jun 2024 is like
  #   date         1719322200
  #   numerator    1
  #   denominator  30
  #   splitRatio   1:30
  # closing price (unadjusted) drops from 193.80 to 6.47
  # new 30 shares = denominator
  # older prices when displayed adjusted are factor
  #   old/new = numerator/denominator
  #
  foreach my $split (values %{$events->{'splits'} // {}}) {
    push @{$h->{'splits'}},
      { symbol => $symbol,
        date   => $timet_to_iso->($split->{'date'}),
        new    => $split->{'denominator'},
        old    => $split->{'numerator'},
      };
  }

  return $h;
}

sub daily_parse {
  my ($symbol, $resp, $h, $hi_tdate) = @_;
  my @data = ();
  $h->{'data'} = \@data;
  my $hi_tdate_iso;
  if (defined $hi_tdate){ $hi_tdate_iso = App::Chart::tdate_to_iso($hi_tdate); }

  my $body = $resp->decoded_content (raise_error => 1);
  my @line_list = App::Chart::Download::split_lines($body);

  unless ($line_list[0] =~ /^Date,Open,High,Low,Close,Adj Close,Volume/) {
    die "Yahoo: unrecognised daily data headings: " . $line_list[0];
  }
  shift @line_list;

  foreach my $line (@line_list) {
    my ($date, $open, $high, $low, $close, $adj_volume, $volume)
      = split (/,/, $line);

    $date = daily_date_fixup ($symbol, $date);
    if (defined $hi_tdate_iso && $date gt $hi_tdate_iso) {
      # Sep 2017: There's a daily data record during the trading day, but
      # want to write the database only at the end of trading.
      ### skip date after hi_tdate ...
      next;
    }

    # Sep 2017 have seen "null,null,null,...", maybe for non-trading days
    foreach my $field ($open, $high, $low, $close, $adj_volume, $volume) {
      if ($field eq 'null') {
        $field = undef;
      }
    }

    if ($index_pred->match($symbol)) {
      # In the past indexes which not calculated intraday had
      # open==high==low==close and volume==0, eg. ^WIL5.  Use the close
      # alone in this case, with the effect of drawing line segments instead
      # of OHLC or Candle figures with no range.

      if (defined $open && defined $high && defined $low && defined $close
          && $open == $high && $high == $low && $low == $close && $volume == 0){
        $open = undef;
        $high = undef;
        $low = undef;
      }

    } else {
      # In the past shares with no trades had volume==0,
      # open==low==close==bid price, and high==offer price, from some time
      # during the day, maybe the end of day.  Zap all the prices in this
      # case.
      #
      # For a public holiday it might be good to zap the volume to undef
      # too, but don't have anything to distinguish holiday, suspension,
      # delisting vs just no trades.
      #
      # On the ASX when shares are suspended the bid/offer can be crossed as
      # usual for pre-open auction, and this gives high<low.  For a part-day
      # suspension then can have volume!=0 in this case too.  Don't want to
      # show a high<low, so massage high/low to open/close range if the high
      # looks like a crossed offer.

      if (defined $high && defined $low && $high < $low) {
        $high = App::Chart::max_maybe ($open, $close);
        $low  = App::Chart::min_maybe ($open, $close);
      }

      if (defined $open && defined $low && defined $close && defined $volume
          && $open == $low && $low == $close && $volume == 0) {
        $open  = undef;
        $high  = undef;
        $low   = undef;
        $close = undef;
      }
    }

    push @data, { symbol => $symbol,
                  date   => $date,
                  open   => crunch_trailing_nines($open),
                  high   => crunch_trailing_nines($high),
                  low    => crunch_trailing_nines($low),
                  close  => crunch_trailing_nines($close),
                  volume => $volume };
  }
  return $h;
}
sub daily_parse_div {
  my ($symbol, $resp, $h) = @_;
  my @dividends = ();
  $h->{'dividends'} = \@dividends;

  my $body = $resp->decoded_content (raise_error => 1);
  my @line_list = App::Chart::Download::split_lines($body);

  # Date,Dividends
  # 2015-11-04,1.4143
  # 2016-05-17,1.41428
  # 2017-05-16,1.4143
  # 2016-11-03,1.4143

  unless ($line_list[0] =~ /^Date,Dividends/) {
    warn "Yahoo: unrecognised dividend headings: " . $line_list[0];
    return;
  }
  shift @line_list;

  foreach my $line (@line_list) {
    my ($date, $amount) = split (/,/, $line);

    push @dividends, { symbol  => $symbol,
                       ex_date => daily_date_fixup ($symbol, $date),
                       amount  => $amount };
  }
  return $h;
}
sub daily_parse_split {
  my ($symbol, $resp, $h) = @_;
  my @splits = ();
  $h->{'splits'} = \@splits;

  my $body = $resp->decoded_content (raise_error => 1);
  my @line_list = App::Chart::Download::split_lines($body);

  # For example GXY.AX split so $10 shares become $2
  # Date,Stock Splits
  # 2017-05-22,1:5
  #
  # In the past it was a "/" instad of ":"
  # 2017-05-22,1/5

  unless ($line_list[0] =~ /^Date,Stock Splits/) {
    warn "Yahoo: unrecognised split headings: " . $line_list[0];
    return;
  }
  shift @line_list;

  foreach my $line (@line_list) {
    my ($date, $ratio) = split (/,/, $line);
    my ($old, $new) = split m{[:/]}, $ratio;

    push @splits, { symbol  => $symbol,
                    date    => daily_date_fixup ($symbol, $date),
                    new     => $new,
                    old     => $old };
  }
  return $h;
}

# ENHANCE-ME: The digits are 23-bit float formatted badly, or so it seems.
# That makes it 23 / (log(10)/log(2)) = 6.92 many high digits good.

# Maybe round-to-nearest of high 7 digits, or maybe only high 6 depending
# where the bit range falls (how many bits used by the high digit).
#
# $str is a string like "30.299999"
# Return it with trailing 9s turned into trailing 0s.
sub crunch_trailing_nines {
  my ($str) = @_;
  if (defined $str) {
    $str =~ s/(\....(99|00)).*/$1/;    # trailing garbage

    if ($str =~ /(.*)\.(....9+)$/) {
      $str = decimal_add_low($str,1);
    } elsif ($str =~ /(.*)\.(....*01)$/) {
      $str = decimal_add_low($str,-1);
    }

    if ($str =~ /(.*)\./) {
      my $ilen = length($1);
      my $decimals = ($ilen >= 4 ? 2
                      : $ilen == 3 ? 3
                      : 4);
      $str = round_decimals($str,$decimals);
    }
    $str = pad_decimals($str, 2);
  }
  return $str;
}
sub decimal_add_low {
  my ($str, $add) = @_;
  ### decimal_add_low(): "$str add $add"
  $str =~ /(.*)\.(.+)$/ or return $str+$add;
  my $pre  = $1;
  my $post = $2;
  ### $pre
  ### $post
  $str = $pre * 10**length($post) + $post + $add;
  while (length($post) >= length($str)) { $str = '0'.$str; }
  substr($str, -length($post),0, '.');
  return $str;
}
sub round_decimals {
  my ($str, $decimals) = @_;
  if (defined $str && $str =~ /(.*\.[0-9]{$decimals})([0-9])/) {
    $str = $1;
    if ($2 >= 5) { $str = decimal_add_low($str, 1); }
  }
  return $str;
}
sub pad_decimals {
  my ($str, $decimals) = @_;
  ### pad_decimals(): "$str  $decimals"
  my $got;
  if ($str =~ /\.(.*)/) {
    $got = length($1);
  } else {
    $got = 0;
    $str .= '.';
  }
  if ((my $add = $decimals - $got) > 0) {
    $str .= '0' x $add;
  }
  return $str;
}

# return a hashref
#   { cookies => string,   # in format HTTP::Cookies ->as_string()
#     crumb   => string
#   }
#
# If no such $symbol then return undef;
#
# Any $symbol which exists is good enough to get a crumb for all later use.
# Could hard-code something likely here, but better to go from the symbol
# which is wanted.
#
# As of April 2024, some User-Agent strings result in 503 Service Unavailable.
# Doesn't seem to affect other download parts, just this cookie/crumb
# getting part.  "Mozilla/5.0" works.
#
sub cookie_and_crumb_data {
  my ($symbol) = @_;
  my $key = 'yahoo-cookie-and-crumb';
  my $str = App::Chart::Database->read_extra ('', $key);
  my $h = eval ($str || '{}');
  $h = {};
  unless (App::Chart::Download::timestamp_within
          ($h->{'timestamp'}, 3 * 86400)) {

    App::Chart::Download::status ('Yahoo cookie');
    require HTTP::Cookies;
    my $jar = HTTP::Cookies->new;
    my $user_agent = 'Mozilla/5.0';
    {
      # first to get a cookie
      my $resp = App::Chart::Download->get
        ('https://www.yahoo.com/',
         user_agent => $user_agent,
         cookie_jar => $jar);
      ### jar: $jar->as_string
      App::Chart::Download::verbose_message ("Yahoo cookies: "
                                             . $jar->as_string);
    }

    App::Chart::Download::status ('Yahoo auth crumb');
    my $resp = App::Chart::Download->get
      ('https://finance.yahoo.com/quote/IBM/history/?p=IBM',
       user_agent => $user_agent,
       cookie_jar => $jar);
    my $crumb = crumb_parse($resp);
    App::Chart::Download::verbose_message ("Yahoo crumb: $crumb");
    my $cookies_str = $jar->as_string;
    $h = { crumb     => $crumb,
           cookies   => $cookies_str,
           timestamp => App::Chart::Download::timestamp_now(),
         };
    my $str = Data_Dumper_str($h);
    App::Chart::Database->write_extra ('', $key, $str);
  }
  return $h;
}
sub crumb_parse {
  my ($resp) = @_;

  # script like, with backslash escaping on "\uXXXX"
  #   "user":{"age":0,"crumb":"8OyCBPyO4ZS"
  # The form prior to about July 2023 was
  #   "user":{"crumb":"hdDX\u002FHGsZ0Q",
  # The form prior to about January 2023 was
  #   "CrumbStore":{"crumb":"hdDX\u002FHGsZ0Q"}
  # The form prior to about May 2024 was
  #   "RequestPlugin":{"user":{"age":0,"crumb":"8OyCBPyO4ZS"
  #

  my $content = $resp->decoded_content (raise_error => 1);
  $content =~ /getcrumb.*?"body":"([^"]*)"/
    or die "Yahoo getcrumb not found in parse";
  return App::Chart::Yahoo::javascript_string_unquote($1);
}

sub Data_Dumper_str {
  my ($h) = @_;
  my $dumper = Data::Dumper->new ([$h], ['var']);
  $dumper->Indent(1);
  $dumper->Terse(1);
  $dumper->Sortkeys(1);
  return $dumper->Dump;
}

# $str is an ISO date string like 2017-11-05
# It is date GMT of 9:30am in the timezone of $symbol.
# Return the date in the symbol timezone.
#
sub daily_date_fixup {
  my ($symbol, $str) = @_;
  ### daily_date_fixup: "$symbol  $str"
  my ($year, $month, $day) = App::Chart::iso_to_ymd ($str);

  my $timezone = App::Chart::TZ->for_symbol($symbol);
  if (timezone_gmtoffset_at_ymd($timezone, $year, $month, $day+1)
      <= - (10*60+20)*60) {
    my $adate = App::Chart::ymd_to_adate ($year, $month, $day);
    $str = App::Chart::adate_to_iso ($adate+1);
    my $today = $timezone->iso_date();
    if ($str gt $today) {
      $str = $today;
    }
  }
  return $str;
}

sub timezone_gmtoffset_at_ymd {
  my ($timezone, $year, $month, $day) = @_;
  my $timet = $timezone->call(\&POSIX::mktime,
                              0, 0, 0, $day, $month-1, $year-1900);
  my ($sec,$min,$hour,$gmt_day) = gmtime($timet);
  return $sec + 60*$min + 3600*$hour + 86400*($gmt_day - $day);
}

# Return seconds since 00:00:00, 1 Jan 1970 GMT.
sub tdate_to_unix {
  my ($tdate) = @_;
  my $adate = App::Chart::tdate_to_adate ($tdate);
  return ($adate + 4)*86400;
}

# $str is a string from previous HTTP::Cookies ->as_string()
# Return a new HTTP::Cookies object with that content.
sub http_cookies_from_string {
  my ($str) = @_;
  require File::Temp;
  my $fh = File::Temp->new (TEMPLATE => 'chart-XXXXXX',
                            TMPDIR => 1);
  print $fh "#LWP-Cookies-1.0\n", $str or die;
  close $fh or die;
  require HTTP::Cookies;
  my $jar = HTTP::Cookies->new;
  $jar->load($fh->filename);
  return $jar;
}


#------------------------------------------------------------------------------
# undo javascript string backslash quoting in STR, per
#
#     https://developer.mozilla.org/en/JavaScript/Guide/Values,_Variables,_and_Literals#String_Literals
#
# Encode::JavaScript::UCS does \u, but not the rest
#
# cf Java as such not quite the same:
#   unicode: http://java.sun.com/docs/books/jls/third_edition/html/lexical.html#100850
#   strings: http://java.sun.com/docs/books/jls/third_edition/html/lexical.html#101089
#
my %javascript_backslash = ('b' => "\b",   # backspace
                            'f' => "\f",   # formfeed
                            'n' => "\n",   # newline
                            'r' => "\r",
                            't' => "\t",   # tab
                            'v' => "\013", # vertical tab
                           );
sub javascript_string_unquote {
  my ($str) = @_;
  $str =~ s{\\(?:
              ((?:[0-3]?[0-7])?[0-7]) # $1 \377 octal latin-1
            |x([0-9a-fA-F]{2})        # $2 \xFF hex latin-1
            |u([0-9a-fA-F]{4})        # $3 \uFFFF hex unicode
            |(.)                      # $4 \n etc escapes
            )
         }{
           (defined $1 ? chr(oct($1))
            : defined $4 ? ($javascript_backslash{$4} || $4)
            : chr(hex($2||$3)))   # \x,\u hex
         }egx;
  return $str;
}

#------------------------------------------------------------------------------
1;
__END__
