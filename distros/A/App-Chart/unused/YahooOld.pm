# Copyright 2007, 2008, 2009, 2010, 2011, 2015, 2016, 2017, 2018 Kevin Ryde

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
# Latest Quotes by CSV

# wget -S -O /dev/stdout 'http://download.finance.yahoo.com/d/quotes.csv?f=snc4b3b2d1t1oml1c1vqdx&e=.csv&s=GM'
#

# sub latest_download {
#   my ($symbol_list) = @_;
#   App::Chart::Download::status (__('Yahoo quotes'));
# 
#   # App::Chart::Download::verbose_message ("Yahoo crumb $crumb cookies\n"
#   #                                        . $jar->as_string);
# 
#   my $crumb_errors = 0;
#  SYMBOL: foreach my $symbol (@$symbol_list) {
#     my $tdate = daily_available_tdate ($symbol);
# 
#     App::Chart::Download::status(__('Yahoo quote'), $symbol);
# 
#     my $lo_timet = tdate_to_unix($tdate - 4);
#     my $hi_timet = tdate_to_unix($tdate + 2);
# 
#     my $data  = daily_cookie_data($symbol);
#     if (! defined $data) {
#       print "Yahoo $symbol does not exist\n";
#       next SYMBOL;
#     }
#     my $crumb = URI::Escape::uri_escape($data->{'crumb'});
#     my $jar = http_cookies_from_string($data->{'cookies'} // '');
# 
#     my $events = 'history';
#     my $url = "http://query1.finance.yahoo.com/v7/finance/download/"
#       . URI::Escape::uri_escape($symbol)
#       . "?period1=$lo_timet&period2=$hi_timet&interval=1d&events=$events&crumb=$crumb";
# 
#     my $resp = App::Chart::Download->get ($url,
#                                           allow_401 => 1,
#                                           allow_404 => 1,
#                                           cookie_jar => $jar,
#                                          );
#     if ($resp->code == 401) {
#       if (++$crumb_errors >= 2) { die "Yahoo: crumb authorization failed"; }
#       App::Chart::Database->write_extra ('', 'yahoo-daily-cookies', undef);
#       redo SYMBOL;
#     }
#     if ($resp->code == 404) {
#       print "Yahoo $symbol does not exist\n";
#       next SYMBOL;
#     }
# 
#     App::Chart::Download::write_latest_group
#         (latest_parse($symbol,$resp,$tdate));
#   }
# }
# 
# sub latest_parse {
#   my ($symbol, $resp, $tdate) = @_;
# 
#   my $h = { source      => __PACKAGE__,
#             resp        => $resp,
#             prefer_decimals => 2,
#             date_format => 'ymd' };
#   daily_parse($symbol,$resp,$h);
# 
#   my $data = $h->{'data'};
#   @$data = sort {$a->{'date'} cmp $b->{'date'}} @$data;
# 
#   my $this = (@$data ? $data->[-1] : {});
#   $this->{'symbol'} = $symbol;
#   $this->{'last_date'} = delete $this->{'date'};
#   my $last = $this->{'last'} = delete $this->{'close'};
#   if (defined $last && @$data >= 2) {
#     my $prev = $data->[-2]->{'close'};
#     if (defined $prev) {
#       $this->{'change'} = decimal_subtract($last, $prev);
#     }
#   }
#   @$data = ($this);
#   return $h;
# }

# Return the difference $x - $y, done as a "decimal" subtract, so retaining
# as many decimal places there are on $x and $y.
# It's done with some sprint %f fakery, not actual decimal arithmetic, but
# that's close enough for 4 decimal place currencies.
sub decimal_subtract {
  my ($x, $y) = @_;
  my $decimals = max (App::Chart::count_decimals($x),
                      App::Chart::count_decimals($y));
  return sprintf ('%.*f', $decimals, $x - $y);
}


# use constant DEFAULT_DOWNLOAD_HOST => 'download.finance.yahoo.com';
# 
# App::Chart::LatestHandler->new
#   (pred => $latest_pred,
#    proc => \&latest_download,
#    max_symbols => MAX_QUOTES);
# 
# sub latest_download {
#   my ($symbol_list) = @_;
# 
#   App::Chart::Download::status
#       (__x('Yahoo quotes {symbol_range}',
#            symbol_range =>
#            App::Chart::Download::symbol_range_string ($symbol_list)));
# 
#   my $host = App::Chart::Database->preference_get
#     ('yahoo-quote-host', DEFAULT_DOWNLOAD_HOST);
#   my $url = "http://$host/d/quotes.csv?f=snc4b3b2d1t1oml1c1vqdx&e=.csv&s="
#     . join (',', map { URI::Escape::uri_escape($_) } @$symbol_list);
# 
#   my $resp = App::Chart::Download->get ($url);
#   App::Chart::Download::write_latest_group (latest_parse ($resp));
# }
#
# sub latest_parse {
#   my ($resp) = @_;
#   my $content = $resp->decoded_content (raise_error => 1);
#   ### Yahoo quotes: $content
# 
#   my @data = ();
#   my $h = { source => __PACKAGE__,
#             resp   => $resp,
#             prefer_decimals => 2,
#             date_format => 'mdy',  # eg. '6/26/2015'
#             data   => \@data };
# 
#   require Text::CSV_XS;
#   my $csv = Text::CSV_XS->new;
#   foreach my $line (App::Chart::Download::split_lines ($content)) {
#     $csv->parse($line);
#     ### csv fields: $csv->fields()
#     my ($symbol, $name, $currency, $bid, $offer, $last_date, $last_time,
#         $open, $range, $last, $change, $volume,
#         $div_date, $div_amount, $exchange)
#       = $csv->fields();
#     if (! defined $symbol) {
#       # blank line maybe
#       print "Yahoo quotes blank line maybe:\n---\n$content\n---\n";
#       next;
#     }
# 
#     # for unknown stocks the name is a repeat of the symbol, which is pretty
#     # useless
#     if ($name eq $symbol) { $name = undef; }
# 
#     my ($low, $high) = split /-/, $range;
#     my $quote_delay_minutes = symbol_quote_delay ($symbol);
# 
#     # have seen wildly garbage date for unknown symbols, like
#     # GC.CMX","GC.CMX","MRA",N/A,N/A,"8/352/19019","4:58am",N/A,"N/A - N/A",0.00,N/A,N/A,"N/A",N/A,"N/A
#     # depending what else in the same request ...
#     #
# 
#     # In the past date/times were in New York timezone, for shares anywhere
#     # in the world.  The Chart database is in the timezone of the exchange.
#     # As of June 2015 believe Yahoo is now also the exchange timezone so no
#     # transformation.
#     #
#     # my $symbol_timezone = App::Chart::TZ->for_symbol ($symbol);
#     # ($last_date, $last_time)
#     #   = quote_parse_datetime ($last_date, $last_time,
#     #                           App::Chart::TZ->newyork,
#     #                           $symbol_timezone);
# 
#     # dividend is "0.00" for various unknowns or estimates, eg. from ASX
#     # trusts
#     if (App::Chart::Download::str_is_zero ($div_amount)) {
#       $div_amount = __('unknown');
#     }
# 
#     # dividend shown only if it's today
#     # don't show if no last_date, just in case have a div_date but no
#     # last_date for some reason
#     $div_date = quote_parse_div_date ($div_date);
#     if (! ($div_date && $last_date && $div_date eq $last_date)) {
#       $div_amount = undef;
#     }
# 
#     push @data, { symbol      => $symbol,
#                   name        => $name,
#                   exchange    => $exchange,
#                   currency    => $currency,
# 
#                   quote_delay_minutes => $quote_delay_minutes,
#                   bid         => $bid,
#                   offer       => $offer,
# 
#                   last_date   => $last_date,
#                   last_time   => $last_time,
#                   open        => $open,
#                   high        => $high,
#                   low         => $low,
#                   last        => $last,
#                   change      => $change,
#                   volume      => $volume,
#                   dividend    => $div_amount,
#                 };
#   }
# 
#   ### $h
#   return $h;
# }
# 
# sub mktime_in_zone {
#   my ($sec, $min, $hour, $mday, $mon, $year, $zone) = @_;
#   my $timet;
# 
#   { local $Tie::TZ::TZ = $zone->tz;
#     $timet = POSIX::mktime ($sec, $min, $hour,
#                             $mday, $mon, $year, 0,0,0);
#     my ($Xsec,$Xmin,$Xhour,$Xmday,$Xmon,$Xyear,$wday,$yday,$isdst)
#       = localtime ($timet);
#     return POSIX::mktime ($sec, $min, $hour,
#                           $mday, $mon, $year, $wday,$yday,$isdst);
#   }
# }
# 
# # $date is dmy like 7/15/2007, in GMT
# # $time is h:mp like 10:05am, in $server_zone
# #
# # return ($date, $time) iso strings like ('2008-06-11', '10:55:00') in
# # $want_zone
# #
# sub quote_parse_datetime {
#   my ($date, $time, $server_zone, $want_zone) = @_;
#   if (DEBUG) { print "quote_parse_datetime $date, $time\n"; }
#   if ($date eq 'N/A' || $time eq 'N/A') { return (undef, undef); }
# 
#   my ($sec,$min,$hour,$mday,$mon,$year)
#     = Date::Parse::strptime($date . ' ' . $time);
#   $sec //= 0; # undef if not present
#   if (DEBUG) { print "  parse $sec,$min,$hour,$mday,$mon,$year\n"; }
# 
#   my $timet = mktime_in_zone ($sec, $min, $hour,
#                               $mday, $mon, $year, $server_zone);
#   if (DEBUG) {
#     print "  timet     Serv ",do { local $Tie::TZ::TZ = $server_zone->tz;
#                                    POSIX::ctime($timet) };
#     print "  timet     GMT  ",do { local $Tie::TZ::TZ = 'GMT';
#                                    POSIX::ctime($timet) };
#   }
# 
#   my ($gmt_sec,$gmt_min,$gmt_hour,$gmt_mday,$gmt_mon,$gmt_year,$gmt_wday,$gmt_yday,$gmt_isdst) = gmtime ($timet);
# 
#   if ($gmt_mday != $mday) {
#     if (DEBUG) { print "  mday $mday/$mon cf gmt_mday $gmt_mday/$gmt_mon, at $timet\n"; }
#     if (cmp_modulo ($gmt_mday, $mday, 31) < 0) {
#       $mday++;
#     } else {
#       $mday--;
#     }
#     $timet = mktime_in_zone ($sec, $min, $hour,
#                              $mday, $mon, $year, $server_zone);
#     if (DEBUG) { print "  switch to $mday        giving $timet = $timet\n"; }
#     if (DEBUG) {
#       print "  timet     GMT  ",do { local $Tie::TZ::TZ = 'GMT';
#                                      POSIX::ctime($timet) };
#       print "  timet     Targ ",do { local $Tie::TZ::TZ = $want_zone->tz;
#                                      POSIX::ctime($timet) };
#     }
#   }
#   return $want_zone->iso_date_time ($timet);
# }
# 
# sub cmp_modulo {
#   my ($x, $y, $modulus) = @_;
#   my $half = int ($modulus / 2);
#   return (($x - $y + $half) % $modulus) <=> $half;
# }
# 
# sub decode_hms {
#   my ($str) = @_;
#   my ($hour, $minute, $second) = split /:/, $str;
#   if (! defined $second) { $second = 0; }
#   return ($hour, $minute, $second);
# }



#------------------------------------------------------------------------------
# quote_parse_div_date()

SKIP: {
  $have_test_mocktime or skip 'due to Test::MockTime not available', 6;

  Test::MockTime::set_fixed_time ('1981-01-01T00:00:00Z');
  is (App::Chart::Yahoo::quote_parse_div_date('Jan  7'), '1981-01-07');
  is (App::Chart::Yahoo::quote_parse_div_date(' 5 Jan'), '1981-01-05');
  is (App::Chart::Yahoo::quote_parse_div_date('31 Dec'), '1980-12-31');
  is (App::Chart::Yahoo::quote_parse_div_date('24-Sep-04'),    '2004-09-24');
  is (App::Chart::Yahoo::quote_parse_div_date('24 Sep, 2004'), '2004-09-24');
  is (App::Chart::Yahoo::quote_parse_div_date('Sep 24, 2004'), '2004-09-24');
  Test::MockTime::restore_time();
}
