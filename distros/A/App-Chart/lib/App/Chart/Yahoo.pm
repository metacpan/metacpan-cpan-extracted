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
# There's a range of "v1", "v7", "v8", "v11" URL forms.
# These might be meant as data sources for Yahoo client-side viewing.
# Don't think they're documented as such, but a few people have
# explored or put traces under the web site operation.
# 
# The download forms might be only for logged-in Yahoo users.
# Would prefer not to require a Yahoo account for every user,
# esp since it's not as easy to do now as in the past.
# (But if that's a condition of use then would do so.)
#
# Here currently using
#    v1 JSON  for info (company name, exchange, decimals)
#    v8 JSON  for historical daily data
#    v7 JSON  for latest quote
#
# Each seem to be without protocol level hoops to jump through.
# Presumably all fall under the general Yahoo terms of service
# which think are personal use and no re-publication.
#
#
# Data Format:
#
# Each of these methods returns results in JSON format.
# The "download" URL form(s), as distinct from "chart", were/are CSV
# but might be restricted access now.
#
# JSON has prices put through single-precision floats,
# ie. 24 bit mantissa, which causes some price strings like
# 123.44999999 instead of 123.45.
# 
# The parse here rounds that back to an apparent intended number
# of decimals (eg. 2 decimals for dollars and cents), but still
# allowing for trading in fractions of a cent as 3 or more decimals.
# 
# In daily data, the current day's trading in progress shows at
# today's date and it changes though the course of trading.
# Don't know how or whether pre-market or post-market trading is
# applied, or what happens to a few futures or similar which might
# even be 24 hour trading.
# 
# Dividends and splits seem to only appear on the ex date.
# That's disappointing since upcoming dividends often influence price
# action.  (Which they shouldn't since everyone knows in advance.)
#
#
# Cookies and Crumb:
#
# In recent times there's been some protocol hoops to jump through.
# It seemed to be sometimes on the v7 download, maybe always on v11.
# The v7 JSON has been fine asking for the latest few days daily data,
# but not sure about bigger historical data.
#
# The hoops consisted of
#
#     - Fetch one of the finance.yahoo.com web pages to get a
#       HTTP Set-Cookie header.
#       As of September 2024, there seems no such cookie any more
#       (only a general user-tracking one for www.yahoo.com).
#     - Maybe answer the ridiculous EU cookie consent on the page.
#       Maybe that depends on where your IP seems to be from.
#       (Not that an IP reliably indicates legal jurisdiction.)
#     - Look deep within script in that page for a "crumb" string.
#       Or maybe a further "getcrumb" web fetch, but seems result
#       crumb is embedded in the page.
#     - On each data download, HTTP Cookie header, and URL crumb
#       field.
#
# Presumably this is designed either to track user activity, or
# as a level of difficulty to stop what Yahoo had said was
# widespread mis-use (contrary to personal use terms).
#


package App::Chart::Yahoo;
use 5.010;
use strict;
use warnings;
use Carp;
use Date::Calc;
use Date::Parse;
use JSON;
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
use App::Chart::DownloadHandler::IndivInfo;
use App::Chart::IntradayHandler;
use App::Chart::Latest;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;

# uncomment this to run the ### lines
# use Smart::Comments;


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
# There was a short time in July 2024 when seemed only the national
# page like au.finaince.yahoo.com worked for BHP.AX, and similar.
# Think that's no longer so.  But the page is badly bloated by
# script and junk, so might not want to use.
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
# Quote Delays - Exchanges Page
#
# This uses the help page
#
use constant EXCHANGES_URL =>
  'https://help.yahoo.com/kb/finance-app-for-android/exchanges-data-providers-yahoo-finance-sln2310.html';
#
# which has a table of quote delays for exchanges, by suffix.
#
# Past URL was https://help.yahoo.com/kb/SLN2310.html and the
# same SLN part would suggest it's about everything, meaning both
# web site data and any Yahoo mobile phone applications.
# Distant past URL was http://finance.yahoo.com/exchanges

# Refetch the exchanges page after EXCHANGES_UPDATE_DAYS.
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
# which is a JSON format of company information like
# 
#     {"explains":[],
#      "count":7,
#      "quotes":[{"exchange":"NMS",
#                 "shortname":"Cisco Systems, Inc.",
#                 "quoteType":"EQUITY",
#                 "symbol":"CSCO",
#                 ...
#                 
# There can be multiple exchanges in the quotes list.  Use the first.
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
# The URL has an optional &newsCount=0 for no news events.
# Think that's the default anyway.


# {"chart":{"result":null,"error":{"code":"Bad Request","description":"Data doesn't exist for startDate = 1565740800, endDate = 1596067200"}}}


App::Chart::DownloadHandler::IndivInfo->new
  (name         => __('Yahoo info'),
   key          => 'Yahoo-info',
   pred         => $download_pred,
   url_func     => \&info_url_func,
   parse        => \&info_parse,
   recheck_days => 14);

sub info_url_func {
  my ($symbol) = @_;
  return 'https://query2.finance.yahoo.com/v1/finance/search?q='
    . URI::Escape::uri_escape ($symbol)
    . '&enableFuzzyQuery=false';
}

sub info_parse {
  my ($symbol, $resp) = @_;
  my @info;
  my $h = { source    => __PACKAGE__,
            info      => \@info };

  my $content = $resp->decoded_content (raise_error => 1);
  my $json = JSON::decode_json($content) // {};
  my $quotes = $json->{'quotes'} // [];
  my $e = $quotes->[0] // {};

  # Should have symbol in the data equal to $symbol requested.
  # May want to be relaxed about that, as the Yahoo server allows
  # different upper/lower case.
  #
  # my $quotes_symbol = $e->{'symbol'} // '';
  # if ($quotes_symbol ne $symbol) {
  #   die "Yahoo info: oops, wanted symbol $symbol got \"$quotes_symbol\"";
  # }

  my $name = $e->{'shortname'};
  if (defined $name) {
    # ASX shares have the symbol repeated at the end of shortname,
    # like "BHP FPO [BHP]".  Seems unnecessary, so strip that.
    my $end = '[' . App::Chart::symbol_sans_suffix ($symbol) .']';
    $name =~ s/\s*\Q$end\E$//;
  }

  return { symbol   => $symbol,
           name     => $name,
           exchange => $e->{'exchange'},
         };
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
#
# FUTURE: Intending to switch this over to v8 the same as the daily
# data, and possibly a single common parse.  But this latest quote
# way has survived without problem during cooking and crumb troubles,
# not don't need to rush to change what's working.

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

    # unknown symbol is 404 with JSON error details
    #
    my $resp = App::Chart::Download->get ($url, allow_404 => 1,);
    App::Chart::Download::write_latest_group
        (latest_parse($symbol,$resp,$tdate));
  }
}

sub latest_parse {
  my ($symbol, $resp, $tdate) = @_;
  my $content = $resp->decoded_content (raise_error => 1);
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
    $record{'currency'} = $meta->{'currency'};
    $record{'exchange'} = $meta->{'exchangeName'};
    my $symbol_timezone = App::Chart::TZ->for_symbol ($symbol);

    # Delisted shares are known symbols and currency,
    # possibly junk name and exchange,
    # and no data which means no timestamp field exists.
    my $timestamps = $result->{'timestamp'} // [];
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
# Download Data, including dividends and splits
#
# This uses the "v8" historical prices downloads in JSON format like
#
#     https://query2.finance.yahoo.com/v8/finance/chart/IBM?period1=1504028419&period2=1504428419&interval=1d&events=div%7Csplit&close=unadjusted
#
# period1 is the start time, period2 the end time, both as Unix
# seconds since 1 Jan 1970 in GMT.
#
# close=unadjusted means prices are without any adjustment for
# splits, so prices as traded at the time.
#
# If no trading in the date range (eg. before first listing) then
#
#     400 Bad Request
#     {"chart":{"result":null,"error":{"code":"Bad Request","description":"Data doesn't exist for startDate = 1565827200, endDate = 1596153600"}}}
#

# One download for each symbol.
# Date ranges in limited size chunks.
# (Don't know whether Yahoo has a limit on size of download,
# but let's try not to discover one.)
#
App::Chart::DownloadHandler::IndivChunks->new
  (name             => __('Yahoo'),
   pred             => $download_pred,
   url_func         => \&daily_url_func,
   parse            => \&daily_parse,
   allow_http_codes => [400,404],
   chunk_size       => 250,  # about 1 year at a time
   available_tdate_by_symbol => \&daily_available_tdate,
   available_tdate_extra     => 2,
  );

sub daily_available_tdate {
  my ($symbol) = @_;

  # As of September 2017, daily data is present for the current
  # day's trade, during the trading session.
  # Try reckoning it complete at 6pm.
  return App::Chart::Download::tdate_today_after
    (18,0, App::Chart::TZ->for_symbol ($symbol));
}

sub daily_url_func {
  my ($symbol, $lo_tdate, $hi_tdate) = @_;
  my $lo_timet = tdate_to_unix($lo_tdate - 2);
  my $hi_timet = tdate_to_unix($hi_tdate);

  # As of September 2024, dividends only appear on (or after?)
  # the ex date.  But try hi_timet well ahead hoping for
  # upcoming dividends (ex date announced).
  if ($hi_tdate >= daily_available_tdate($symbol)) {
    $hi_timet += 60 * 86400;
  }

  return "https://query1.finance.yahoo.com/v8/finance/chart/"
    . URI::Escape::uri_escape($symbol)
    ."?formatted=true&lang=en-US&region=US"
    ."&period1=$lo_timet"
    ."&period2=$hi_timet"
    ."&interval=1d"
    ."&events=". URI::Escape::uri_escape('div|split')
    ."&close=unadjusted";
}

# $resp is a HTTP::Response object with is Yahoo v8 JSON data for $symbol..
# Return $h which is a write_daily_group() style hashref of the data.
#
sub daily_parse {
  my ($symbol, $resp) = @_;
  my $hi_tdate = daily_available_tdate ($symbol);
  my @data = ();
  my $h = { source          => __PACKAGE__,
            prefer_decimals => 2,  # default
            date_format     => 'ymd',
            data            => \@data,
          };

  my $content = $resp->decoded_content (raise_error => 1);
  my $json = JSON::decode_json($content);
  my $result = $json->{'chart'}->{'result'}->[0];

  my $meta = $result->{'meta'} // {};

  # Should have symbol in the data equal to $symbol requested.
  # May want to be relaxed about that, as the Yahoo server allows
  # different upper/lower case.  The intention is to have all
  # symbols in the database as a canonical form.
  #
  # my $meta_symbol = $meta->{'symbol'} // '';
  # if ($meta_symbol ne $symbol) {
  #   die "Yahoo JSON oops, symbol wanted $symbol got $meta_symbol";
  # }

  # Trading in pence Sterling is "GBp", such as TSCO.L
  $h->{'currencies'}->{$symbol} = $meta->{'currency'};
  $h->{'exchanges'}->{$symbol} = $meta->{'exchangeName'};
  my $decimals = $meta->{'priceHint'};
  if (defined $decimals) {
    $h->{'prefer_decimals'} = $decimals;
  }
  $decimals //= 2;

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

# $str is a string like "30.299999"
# Return it with trailing 9s turned into trailing 0s.
sub crunch_trailing_nines {
  my ($str) = @_;

  # ENHANCE-ME: The digits are 23-bit float formatted badly, or so it seems.
  # That makes it 23 / (log(10)/log(2)) = 6.92 many high digits good.
  # Maybe round-to-nearest of high 7 digits, or maybe only high 6 depending
  # where the bit range falls (how many bits used by the high digit).

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

# Return seconds since 00:00:00, 1 Jan 1970 GMT.
sub tdate_to_unix {
  my ($tdate) = @_;
  my $adate = App::Chart::tdate_to_adate ($tdate);
  return ($adate + 4)*86400;
}

#------------------------------------------------------------------------------
1;
__END__
