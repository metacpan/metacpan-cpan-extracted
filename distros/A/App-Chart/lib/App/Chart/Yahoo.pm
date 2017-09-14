# Copyright 2007, 2008, 2009, 2010, 2011, 2015, 2016, 2017 Kevin Ryde

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


package App::Chart::Yahoo;
use 5.010;
use strict;
use warnings;
use Carp;
use Date::Calc;
use Date::Parse;
use List::Util qw (min max);
use POSIX ();
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
# use Smart::Comments;

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
our $index_pred    = App::Chart::Sympred::Regexp->new (qr/^\^|^0.*\.SS$/);
my $futures_pred  = App::Chart::Sympred::Any->new;

# max symbols to any /q? quotes request
# Finance::Quote::Yahoo uses a limit of 40 to stop the url getting too
# long, which apparently some servers or proxies can't handle
use constant MAX_QUOTES => 40;

# overridden by specific nodes
App::Chart::setup_source_help
  ($yahoo_pred, __p('manual-node','Yahoo Finance'));


#-----------------------------------------------------------------------------
# web link - basic quote page
#
# Eg. http://finance.yahoo.com/q?s=BHP.AX
#
# The accelerator is "_Y" so as not to clash with "_S" for stock on various
# stock exchange links like "ASX IRM _Stock Information"

App::Chart::Weblink->new
  (pred => $yahoo_pred,
   name => __('_Yahoo Stock Page'),
   desc => __('Open web browser at the Yahoo quote page for this stock'),
   proc => sub {
     my ($symbol) = @_;
     return "http://"
       . App::Chart::Database->preference_get ('yahoo-quote-host',
                                              'finance.yahoo.com')
         . "/q?s="
           . URI::Escape::uri_escape($symbol);
   });


#-----------------------------------------------------------------------------
# misc


# 	    (if (and (yahoo-futures-symbol? symbol)
# 		     (not (chart-symbol-mdate symbol)))
# 		(let* ((want-tdate (adate->tdate
# 				    (first
# 				     (yahoo-quote-adate-time symbol ""))))
# 		       (mdate (or (latest-symbol-mdate-nodownload symbol
# 								  want-tdate)
# 				  (begin
# 				    (weblink-message
# 				     (_ "Finding front month ..."))
# 				    (latest-symbol-mdate symbol want-tdate)))))
# 		  (if mdate # might still be unknown
# 		      (set! symbol
# 			    (string-append (chart-symbol-commodity symbol)
# 					   (mdate->MYY-str mdate)
# 					   (chart-symbol-suffix symbol))))))


#-----------------------------------------------------------------------------
# Exchanges page for quote delays
#
# This looks at the exchanges page
#
use constant EXCHANGES_URL => 'https://help.yahoo.com/kb/SLN2310.html';

# Exchanges page was previously http://finance.yahoo.com/exchanges, but why
# would they keep it the same when breaking everybody's links would be
# better.

# refetch the exchanges page after this many days
use constant EXCHANGES_UPDATE_DAYS => 7;

# containing arefs [$pred,'.XX']
my @quote_delay_aliases;

sub setup_quote_delay_alias {
  my ($pred, $suffix) = @_;
  push @quote_delay_aliases, [ $pred, $suffix ];
}

sub symbol_quote_delay {
  my ($symbol) = @_;

  # indexes all in real time
  if ($index_pred->match($symbol)) {
    return 0;
  }

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

# return a hashref of exchange delay data like { '.AX' => 20, '.BI' => 15 }
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


#------------------------------------------------------------------------------
# Quotes bits generally.
#
# This uses the csv format quotes like
#
#     http://download.finance.yahoo.com/d/quotes.csv?f=snl&e=.csv&s=BHP.AX
#
# The "f" field keys can be found at the following (open an account to get
# to them).
#
#         http://edit.my.yahoo.com/config/edit_pfview?.vk=v1
#         http://edit.finance.yahoo.com/e9?.intl=au
#
# http://download.finance.yahoo.com/d?
#   s=  # symbol
#   f=  # format, concat of the following
#     s   # symbol
#     n   # company name
#     l1  # last price
#     d1  # last trade date (in home exchange's timezone)
#     t1  # last trade time (in yahoo server timezone)
#     c1  # change
#     p2  # percent change
#     v   # volume
#     a2  # average daily volume
#     b   # bid
#     b6  # bid size
#     a   # ask
#     a5  # ask size
#     k1  # "time - last" (ECN), with <b> and <i> markup
#     c6  # change (ECN)
#     m2  # day's range (ECN)
#     b3  # bid (ECN)
#     b2  # ask (ECN)
#     p   # previous close
#     o   # today's open
#     m   # day's range, eg. "1.23 - 4.56"
#     w   # 52-week range, eg. "1.23 - 4.56"
#     e   # earnings per share
#     r   # p/e ratio
#     d   # div per share
#     q   # ex div date, eg. "Mar 31" or "N/A"
#     r1  # div pay date
#     y   # div yield
#     j1  # market cap
#     x   # stock exchange
#     c4  # currency, eg. "AUD"
#     i   # more info links, letters
#         #    c=chart, n=news, p=profile, r=research, i=insider,
#         #    m=message board (yahoo)
#     k   # 52-week high
#
# Don't know what the distinction between b,a and b3,b2 quotes are actually
# meant to be.
#     - For the Australian Stock Exchange, b,a are "N/A", and b3,b2 is the
#       SEATS best quote.
#     - For US stocks b,a seem to be "N/A", and b3,b2 an ECN quote.  The
#       latter has been seen a long way away from from recent trades though,
#       eg. in BRK-A.
#
# d1,t1 are a bit odd, the time is the yahoo server's zone, but the date
# seems to be always GMT.  The zone for the time can be seen easily by
# looking at a quote from the various international XX.finance.yahoo.com.
# For the zone for the date however you need to be watching at midnight
# GMT, where it ticks over (at all the international XX.finance.yahoo.com).


# quote_parse_div_date ($str) returns an iso YYYY-MM-DD date string for a
# dividend $str coming from quote.csv data, or undef if none.  There are
# several different formats,
#           "Jan 7"        # finance.yahoo.com
#           " 5 Jan"  	   # au.finance, uk.finance
#           "24-Sep-04"    # ABB.AX on finance.yahoo.com
#           "24 Sep, 2004" # ABB.AX on au.finance
#           "Sep 24, 2004" # ABB.AX on ca.finance
#
# An error is thrown for an unrecognised string, don't want some new form to
# end up with dividends silently forgotten.
#
sub quote_parse_div_date {
  my ($str) = @_;
  if (DEBUG) { print "quote_parse_div_date() '$str'\n"; }
  if (! defined $str || $str eq 'N/A' || $str eq '') {
    return undef; # no info
  }

  my ($ss,$mm,$hh,$day,$month,$year,$zone) = Date::Parse::strptime ($str);
  $month++;
  if ($year) {
    $year += 1900;
    if ($year < 2000) {  # "04" returned as 1904, bump to 2004
      $year += 100;
    }
  } else {
    # year not given, try nearest
    $year = App::Chart::Download::month_to_nearest_year ($month);
  }
  if (! Date::Calc::check_date ($year, $month, $day)) {
    warn "Yahoo invalid dividend date '$str'";
  }
  return App::Chart::ymd_to_iso ($year, $month, $day);
}

#------------------------------------------------------------------------------
# latest
#
# wget -S -O /dev/stdout 'http://download.finance.yahoo.com/d/quotes.csv?f=snc4b3b2d1t1oml1c1vqdx&e=.csv&s=GM'
#

use constant DEFAULT_DOWNLOAD_HOST => 'download.finance.yahoo.com';

App::Chart::LatestHandler->new
  (pred => $latest_pred,
   proc => \&latest_download,
   max_symbols => MAX_QUOTES);

sub latest_download {
  my ($symbol_list) = @_;

  App::Chart::Download::status
      (__x('Yahoo quotes {symbol_range}',
           symbol_range =>
           App::Chart::Download::symbol_range_string ($symbol_list)));

  my $host = App::Chart::Database->preference_get
    ('yahoo-quote-host', DEFAULT_DOWNLOAD_HOST);
  my $url = "http://$host/d/quotes.csv?f=snc4b3b2d1t1oml1c1vqdx&e=.csv&s="
    . join (',', map { URI::Escape::uri_escape($_) } @$symbol_list);

  my $resp = App::Chart::Download->get ($url);
  App::Chart::Download::write_latest_group (latest_parse ($resp));
}

sub latest_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);
  ### Yahoo quotes: $content

  my @data = ();
  my $h = { source => __PACKAGE__,
            resp   => $resp,
            prefer_decimals => 2,
            date_format => 'mdy',  # eg. '6/26/2015'
            data   => \@data };

  require Text::CSV_XS;
  my $csv = Text::CSV_XS->new;
  foreach my $line (App::Chart::Download::split_lines ($content)) {
    $csv->parse($line);
    ### csv fields: $csv->fields()
    my ($symbol, $name, $currency, $bid, $offer, $last_date, $last_time,
        $open, $range, $last, $change, $volume,
        $div_date, $div_amount, $exchange)
      = $csv->fields();
    if (! defined $symbol) {
      # blank line maybe
      print "Yahoo quotes blank line maybe:\n---\n$content\n---\n";
      next;
    }

    # for unknown stocks the name is a repeat of the symbol, which is pretty
    # useless
    if ($name eq $symbol) { $name = undef; }

    my ($low, $high) = split /-/, $range;
    my $quote_delay_minutes = symbol_quote_delay ($symbol);

    # have seen wildly garbage date for unknown symbols, like
    # GC.CMX","GC.CMX","MRA",N/A,N/A,"8/352/19019","4:58am",N/A,"N/A - N/A",0.00,N/A,N/A,"N/A",N/A,"N/A
    # depending what else in the same request ...
    #

    # In the past date/times were in New York timezone, for shares anywhere
    # in the world.  The Chart database is in the timezone of the exchange.
    # As of June 2015 believe Yahoo is now also the exchange timezone so no
    # transformation.
    #
    # my $symbol_timezone = App::Chart::TZ->for_symbol ($symbol);
    # ($last_date, $last_time)
    #   = quote_parse_datetime ($last_date, $last_time,
    #                           App::Chart::TZ->newyork,
    #                           $symbol_timezone);

    # dividend is "0.00" for various unknowns or estimates, eg. from ASX
    # trusts
    if (App::Chart::Download::str_is_zero ($div_amount)) {
      $div_amount = __('unknown');
    }

    # dividend shown only if it's today
    # don't show if no last_date, just in case have a div_date but no
    # last_date for some reason
    $div_date = quote_parse_div_date ($div_date);
    if (! ($div_date && $last_date && $div_date eq $last_date)) {
      $div_amount = undef;
    }

    push @data, { symbol      => $symbol,
                  name        => $name,
                  exchange    => $exchange,
                  currency    => $currency,

                  quote_delay_minutes => $quote_delay_minutes,
                  bid         => $bid,
                  offer       => $offer,

                  last_date   => $last_date,
                  last_time   => $last_time,
                  open        => $open,
                  high        => $high,
                  low         => $low,
                  last        => $last,
                  change      => $change,
                  volume      => $volume,
                  dividend    => $div_amount,
                };
  }

  ### $h
  return $h;
}

sub mktime_in_zone {
  my ($sec, $min, $hour, $mday, $mon, $year, $zone) = @_;
  my $timet;

  { local $Tie::TZ::TZ = $zone->tz;
    $timet = POSIX::mktime ($sec, $min, $hour,
                            $mday, $mon, $year, 0,0,0);
    my ($Xsec,$Xmin,$Xhour,$Xmday,$Xmon,$Xyear,$wday,$yday,$isdst)
      = localtime ($timet);
    return POSIX::mktime ($sec, $min, $hour,
                          $mday, $mon, $year, $wday,$yday,$isdst);
  }
}

# $date is dmy like 7/15/2007, in GMT
# $time is h:mp like 10:05am, in $server_zone
#
# return ($date, $time) iso strings like ('2008-06-11', '10:55:00') in
# $want_zone
#
sub quote_parse_datetime {
  my ($date, $time, $server_zone, $want_zone) = @_;
  if (DEBUG) { print "quote_parse_datetime $date, $time\n"; }
  if ($date eq 'N/A' || $time eq 'N/A') { return (undef, undef); }

  my ($sec,$min,$hour,$mday,$mon,$year)
    = Date::Parse::strptime($date . ' ' . $time);
  $sec //= 0; # undef if not present
  if (DEBUG) { print "  parse $sec,$min,$hour,$mday,$mon,$year\n"; }

  my $timet = mktime_in_zone ($sec, $min, $hour,
                              $mday, $mon, $year, $server_zone);
  if (DEBUG) {
    print "  timet     Serv ",do { local $Tie::TZ::TZ = $server_zone->tz;
                                   POSIX::ctime($timet) };
    print "  timet     GMT  ",do { local $Tie::TZ::TZ = 'GMT';
                                   POSIX::ctime($timet) };
  }

  my ($gmt_sec,$gmt_min,$gmt_hour,$gmt_mday,$gmt_mon,$gmt_year,$gmt_wday,$gmt_yday,$gmt_isdst) = gmtime ($timet);

  if ($gmt_mday != $mday) {
    if (DEBUG) { print "  mday $mday/$mon cf gmt_mday $gmt_mday/$gmt_mon, at $timet\n"; }
    if (cmp_modulo ($gmt_mday, $mday, 31) < 0) {
      $mday++;
    } else {
      $mday--;
    }
    $timet = mktime_in_zone ($sec, $min, $hour,
                             $mday, $mon, $year, $server_zone);
    if (DEBUG) { print "  switch to $mday        giving $timet = $timet\n"; }
    if (DEBUG) {
      print "  timet     GMT  ",do { local $Tie::TZ::TZ = 'GMT';
                                     POSIX::ctime($timet) };
      print "  timet     Targ ",do { local $Tie::TZ::TZ = $want_zone->tz;
                                     POSIX::ctime($timet) };
    }
  }
  return $want_zone->iso_date_time ($timet);
}

sub cmp_modulo {
  my ($x, $y, $modulus) = @_;
  my $half = int ($modulus / 2);
  return (($x - $y + $half) % $modulus) <=> $half;
}

sub decode_hms {
  my ($str) = @_;
  my ($hour, $minute, $second) = split /:/, $str;
  if (! defined $second) { $second = 0; }
  return ($hour, $minute, $second);
}


#-----------------------------------------------------------------------------
# download
#
# This uses the historical prices page like
#
#     https://finance.yahoo.com/quote/AMP.AX/history?p=AMP.AX
#
# which puts a cookie like
#
#     Set-Cookie: B=fab5sl9cqn2rd&b=3&s=i3; expires=Sun, 03-Sep-2018 04:56:13 GMT; path=/; domain=.yahoo.com
#
# and contains buried within a mountain of hideous script
#
#     "CrumbStore":{"crumb":"hdDX\u002FHGsZ0Q"}
#
# The \u002F is backslash character etc which is script string for "/"
# character.  The crumb is included in a CSV download query like
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
# The "9999s" are some dodgy rounding off to what should be usually at most
# 3 decimal places.
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
# For reference, there's a similar further which is json format (%7C = "|")
#
#     https://query2.finance.yahoo.com/v8/finance/chart/IBM?formatted=true&lang=en-US&region=US&period1=1504028419&period2=1504428419&interval=1d&events=div%7Csplit&corsDomain=finance.yahoo.com
#
# This doesn't require a cookie and crumb, has some info like symbol
# timezone.  The numbers look like they're rounded through 32-bit floating
# point, for example "142.55999755859375" which is 142.55 in a 23-bit
# mantissa.  log(14255000)/log(2) = 23.76 bits
#
# All prices look like they are split-adjusted, which is ok if that's what
# you ant and are downloading a full data set, but bad for incremental since
# you don't know when a change is applied.
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

    my $data  = daily_cookie_data($symbol);
    if (! defined $data) {
      print "Yahoo $symbol does not exist";
      next SYMBOL;
    }
    my $crumb = URI::Escape::uri_escape($data->{'crumb'});
    my $jar = http_cookies_from_string($data->{'cookies'} // '');

    my $h = { source          => __PACKAGE__,
              prefer_decimals => 2,
              date_format   => 'ymd',
            };
    foreach my $elem (['history',\&daily_parse],
                      ['div',    \&daily_parse_div],
                      ['split',  \&daily_parse_split]) {
      my ($events,$parse) = @$elem;
      my $url = "http://query1.finance.yahoo.com/v7/finance/download/"
        . URI::Escape::uri_escape($symbol)
        . "?period1=$lo_timet&period2=$hi_timet&interval=1d&events=$events&crumb=$crumb";

      my $resp = App::Chart::Download->get ($url,
                                            allow_401 => 1,
                                            allow_404 => 1,
                                            cookie_jar => $jar,
                                           );
      if ($resp->code == 401) {
        if (++$crumb_errors >= 2) { die "Yahoo: crumb authorization failed"; }
        App::Chart::Database->write_extra ('', 'yahoo-daily-cookies', undef);
        redo SYMBOL;
      }
      if ($resp->code == 404) {
        print "Yahoo $symbol does not exist";
        next SYMBOL;
      }
      $parse->($symbol,$resp,$h, $hi_tdate);
    }
    ### $h
    App::Chart::Download::write_daily_group ($h);
  }
}

sub daily_parse {
  my ($symbol, $resp, $h, $hi_tdate) = @_;
  my @data = ();
  $h->{'data'} = \@data;
  my $hi_tdate_iso = App::Chart::tdate_to_iso($hi_tdate);

  my $body = $resp->decoded_content (raise_error => 1);
  my @line_list = App::Chart::Download::split_lines($body);

  unless ($line_list[0] =~ /^Date,Open,High,Low,Close,Adj Close,Volume/) {
    die "Yahoo: unrecognised daily data headings: " . $line_list[0];
  }
  shift @line_list;

  foreach my $line (@line_list) {
    my ($date, $open, $high, $low, $close, $adj_volume, $volume)
      = split (/,/, $line);

    $date = daily_date_to_iso ($date);
    if ($date gt $hi_tdate_iso) {
      # Sep 2017: There's a daily data record during the trading day, but
      # want to write the database only at the end of trading.
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
                       ex_date => daily_date_to_iso ($date),
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

  # GXY.AX split so $10 shares become $2
  # Date,Stock Splits
  # 2017-05-22,1/5

  unless ($line_list[0] =~ /^Date,Stock Splits/) {
    warn "Yahoo: unrecognised split headings: " . $line_list[0];
    return;
  }
  shift @line_list;

  foreach my $line (@line_list) {
    my ($date, $ratio) = split (/,/, $line);
    my ($old, $new) = split m{/}, $ratio;

    push @splits, { symbol  => $symbol,
                    date    => daily_date_to_iso ($date),
                    new     => $new,
                    old     => $old };
  }
  return $h;
}

# $str is a string like "30.299999"
# Return it with trailing 9s turned into trailing 0s.
sub crunch_trailing_nines {
  my ($str) = @_;
  if (defined $str) {
    if ($str =~ /(.*)\.(...9+)$/) {
      return decimal_add_low($str,1);
    }
    if ($str =~ /(.*)\.(....*01)$/) {
      return decimal_add_low($str,-1);
    }
  }
  return $str;
}
sub decimal_add_low {
  my ($str, $add) = @_;
  $str =~ /(.*)\.(.+)$/ or return $str+$add;
  my $pre  = $1;
  my $post = $2;
  $str = $pre * 10**length($post) + $post + $add;
  substr($str, -length($post),0, '.');
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
sub daily_cookie_data {
  my ($symbol) = @_;
  require App::Chart::Pagebits;
  $symbol = URI::Escape::uri_escape($symbol);
  return App::Chart::Pagebits::get
    (name      => __('Yahoo daily cookie'),
     url       => "https://finance.yahoo.com/quote/$symbol/history?p=$symbol",
     key       => 'yahoo-daily-cookies',
     freq_days => 3,
     parse     => \&daily_cookie_parse,
     allow_404 => 1);
}
sub daily_cookie_parse {
  my ($content, $resp) = @_;

  # script like, with backslash escaping on "\uXXXX"
  #"CrumbStore":{"crumb":"hdDX\u002FHGsZ0Q"}
  #
  $content =~ /"CrumbStore":\{"crumb":"([^"]*)"}/
    or die "Yahoo daily data: CrumbStore not found";
  my $crumb = App::Chart::Yahoo::javascript_string_unquote($1);

  # header like
  # Set-Cookie: B=fab5sl9cqn2rd&b=3&s=i3; expires=Sun, 03-Sep-2018 04:56:13 GMT; path=/; domain=.yahoo.com
  #
  # Expiry time is +1 year, but dunno if would really work that long.
  # 
  require HTTP::Cookies;
  my $jar = HTTP::Cookies->new;
  $jar->extract_cookies($resp);
  my $cookies_str = $jar->as_string;

  App::Chart::Download::verbose_message ("Yahoo new crumb $crumb\n"
                                         . $cookies_str);
  return { crumb   => $crumb,
           cookies => $cookies_str };
}

# return tdate for a date STR from historical data
#     "2005-03-07"   AGK.AX seen in jan07, maybe transient
#     "20-Aug-02"    past format
#
sub daily_date_to_iso {
  my ($str) = @_;
  if ($str =~ /[A-Za-z]/) {
    return App::Chart::Download::Decode_Date_EU_to_iso ($str); # dmy
  } else {
    return $str;
  }
}

# Return seconds since 00:00:00, 1 Jan 1970 GMT.
sub tdate_to_unix {
  my ($tdate) = @_;
  my ($year, $month, $day) = App::Chart::tdate_to_ymd ($tdate);
  require Time::Local;
  return Time::Local::timegm (0, 0, 0, $day, $month-1, $year-1900);
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


#-----------------------------------------------------------------------------
# stock info
#
# Eg. http://download.finance.yahoo.com/d?f=snxc4qr1d&s=TLS.AX

App::Chart::DownloadHandler->new
  (name         => __('Yahoo info'),
   key          => 'Yahoo-info',
   pred         => $download_pred,
   proc         => \&info_download,
   recheck_days => 7,
   max_symbols  => MAX_QUOTES);

sub info_download {
  my ($symbol_list) = @_;

  App::Chart::Download::status
      (__x('Yahoo info {symbolrange}',
           symbolrange =>
           App::Chart::Download::symbol_range_string ($symbol_list)));

  my $url = 'http://download.finance.yahoo.com/d?f=snxc4qr1d&s='
    . join (',', map { URI::Escape::uri_escape($_) } @$symbol_list);
  my $resp = App::Chart::Download->get ($url);
  my $h = info_parse($resp);
  $h->{'recheck_list'} = $symbol_list;
  App::Chart::Download::write_daily_group ($h);
}

sub info_parse {
  my ($resp) = @_;

  my $content = $resp->decoded_content (raise_error => 1);
  if (DEBUG >= 2) { print "Yahoo info:\n$content\n"; }

  my @info;
  my @dividends;
  my $h = { source    => __PACKAGE__,
            info      => \@info,
            dividends => \@dividends };

  require Text::CSV_XS;
  my $csv = Text::CSV_XS->new;

  foreach my $line (App::Chart::Download::split_lines ($content)) {
    $csv->parse($line);
    my ($symbol, $name, $exchange, $currency, $ex_date, $pay_date, $amount)
      = $csv->fields();

    $ex_date  = quote_parse_div_date ($ex_date);
    $pay_date = quote_parse_div_date ($pay_date);

    push @info, { symbol => $symbol,
                  name   => $name,
                  currency => $currency,
                  exchange => $exchange };
    # circa 2015 the "d" dividend amount field is "N/A" when after the
    # dividend payment (with "r1" pay date "N/A" too)
    if ($ex_date && $amount ne 'N/A' && $amount != 0) {
      push @dividends, { symbol   => $symbol,
                         ex_date  => $ex_date,
                         pay_date => $pay_date,
                         amount   => $amount };
    }
  }
  return $h;
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
