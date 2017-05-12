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
#     http://finance.yahoo.com/q/hp?s=AMP.AX
#
# which has a CSV link like
#
#     http://ichart.finance.yahoo.com/table.csv?s=NABHA.AX&d=5&e=26&f=2015&g=d&a=3&b=26&c=2015&ignore=.csv
#
# #     http://ichart.finance.yahoo.com/table.csv?s=IFN.AX&d=6&e=8&f=2009&g=d&a=9&b=28&c=2005&ignore=.csv
#
# or on the national sites like au.finance.yahoo.com with a redirector like
#
#     http://au.rd.yahoo.com/finance/quotes/internal/historical/download/*http://ichart.finance.yahoo.com/table.csv?s=AMP.AX&d=10&e=26&f=2007&g=d&a=0&b=4&c=2000&ignore=.csv
#
# If there's no data at all in the requested range the response is a 404
# (with various bits of HTML in the body).

App::Chart::DownloadHandler::IndivChunks->new
  (name       => __('Yahoo'),
   pred       => $download_pred,
   available_tdate_by_symbol => \&daily_available_tdate,
   available_tdate_extra     => 2,
   url_func   => \&daily_url,
   parse      => \&daily_parse,
   chunk_size => 150);

sub daily_available_tdate {
  my ($symbol) = @_;
  return App::Chart::Download::tdate_today_after
    (10,30, App::Chart::TZ->for_symbol ($symbol))
      - 1;
}

sub daily_url {
  my ($symbol, $lo_tdate, $hi_tdate) = @_;
  my ($lo_year, $lo_month, $lo_day) = App::Chart::tdate_to_ymd ($lo_tdate);
  my ($hi_year, $hi_month, $hi_day) = App::Chart::tdate_to_ymd ($hi_tdate);
  return 'http://ichart.finance.yahoo.com/table.csv?'
    . 's=' . URI::Escape::uri_escape ($symbol)
    . '&d=' . ($hi_month - 1)
    . '&e=' . $hi_day
    . '&f=' . $hi_year
    . '&g=d'
    . '&a=' . ($lo_month - 1)
    . '&b=' . $lo_day
    . '&c=' . $lo_year
    . '&ignore=.csv';
}

sub daily_parse {
  my ($symbol, $resp) = @_;
  my @data = ();
  my $h = { source          => __PACKAGE__,
            prefer_decimals => 2,
            data            => \@data };

  my $body = $resp->decoded_content (raise_error => 1);
  my @line_list = App::Chart::Download::split_lines($body);

  # "Adj. Close*" in the past
  # "Adj Close" as of Jan 2007
  if ($line_list[0] !~ /^Date,Open,High,Low,Close,Volume,Adj\.? Close\*?/) {
    die "Yahoo: unrecognised daily data headings: " . $line_list[0];
  }
  shift @line_list;

  foreach my $line (@line_list) {
    my ($date, $open, $high, $low, $close, $volume, $adj_volume)
      = split (/,/, $line);

    if ($index_pred->match($symbol)) {
      # Indexes which aren't calculated intraday have open==high==low==close
      # and volume==0, eg. ^WIL5.  Use the close alone in this case, with
      # the effect of drawing line segments instead of OHLC or Candle
      # figures with no range.

      if ($open == $high && $high == $low && $low == $close && $volume == 0) {
        $open = undef;
        $high = undef;
        $low = undef;
      }

    } else {
      # Shares with no trades have volume==0, open==low==close==bid price,
      # and high==offer price, from some time during the day, maybe the end
      # of day.  Zap all the prices in this case.
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

      if ($high < $low) {
        $high = App::Chart::max_maybe ($open, $close);
        $low  = App::Chart::min_maybe ($open, $close);
      }

      if ($open == $low && $low == $close && $volume == 0) {
        $open  = undef;
        $high  = undef;
        $low   = undef;
        $close = undef;
      }
    }

    push @data, { symbol => $symbol,
                  date   => daily_date_to_iso ($date),
                  open   => $open,
                  high   => $high,
                  low    => $low,
                  close  => $close,
                  volume => $volume };
  }
  return $h;
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


#-----------------------------------------------------------------------------
# intraday images
#
# Images are fetched from the yahoo charts section, gifs like
#
#     http://ichart.finance.yahoo.com/z?s=%5EGSPC&t=1d&q=l&l=off&z=l&p=s
#
# or the link from au.finance.yahoo.com is say
#
#     http://cchart.yahoo.com/z?s=CML.AX&t=5d&l=off&z=l&q=l&i=au
#
# Those two hostnames resolve to the same IP, don't know which one is
# really meant to be used.
#
# The parts are
#
#     s=SYMBOL
#     t=1d   1 day
#       5d   5 days
#     q=l    line
#       b    bar
#       c    candle
#     l=on   logarithmic
#       off  linear
#     z=m    medium size
#       l    large size
#     a=  comma separated list of indicators
#       v    volume
#       vm   volume moving average
#       r14  RSI
#
# Unfortunately there's no last-modified or etag to indicate when the image
# has nothing new yet, or is unchanged outside trading hours.

# the futures charts from yahoo don't look too good, eg OU07.CBT, so stay
# with barchart for them
sub is_intraday_symbol {
  my ($symbol) = @_;
  my $suffix = App::Chart::symbol_suffix ($symbol);
  return (length($suffix) <= 3
          && $latest_pred->match($symbol));
}
my $intraday_pred = App::Chart::Sympred::Proc->new (\&is_intraday_symbol);

foreach my $n (1, 5) {
  App::Chart::IntradayHandler->new
      (pred => $intraday_pred,
       proc => \&intraday_url,
       mode => "${n}d",
       name => __nx('_{n} Day',
                    '_{n} Days',
                    $n,
                    n => $n));
}

sub intraday_url {
  my ($self, $symbol, $mode) = @_;
  App::Chart::Download::status (__x('Yahoo intraday {symbol} {mode}',
                                    symbol => $symbol,
                                    mode => $mode));
  return 'http://ichart.finance.yahoo.com/z?s='
    . URI::Escape::uri_escape ($symbol)
      . '&t=' . $mode
        . '&l=off&z=m&q=l&a=v';
}


1;
__END__
