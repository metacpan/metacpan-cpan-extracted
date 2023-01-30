#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2015, 2016, 2017, 2018, 2019, 2020, 2023 Kevin Ryde

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

use strict;
use warnings;
use Data::Dumper;
use File::Slurp 'slurp';
use POSIX 'strftime';
use App::Chart::Yahoo;
use App::Chart::TZ;
use App::Chart::Download;
use Date::Calc;
use Date::Parse;

# uncomment this to run the ### lines
use Smart::Comments;

{
  require HTTP::Response;
  my $filename = "$ENV{HOME}/chart/samples/yahoo/history?p=BHP.AX";
  my $resp = HTTP::Response->new();
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/html; charset=utf-8');
  my @ret = App::Chart::Yahoo::daily_cookie_parse($content,$resp);
  ### @ret
  exit 0;
}
{
  # Date,Dividends
  # 2014-05-14,1.41429
  # 2015-05-15,1.41428
  # 2013-05-30,1.32857
  # 2013-11-06,1.38571
  # 2015-11-04,1.4143
  # 2016-05-17,1.41428
  # 2017-05-16,1.4143
  # 2014-11-06,1.4143
  # 2016-11-03,1.4143
  # 2012-11-08,1.28571

  # Date,Open,High,Low,Close,Adj Close,Volume
  # 2017-09-07,30.299999,30.379999,30.000000,30.170000,30.170000,3451099
  # 2017-09-08,30.170000,30.170000,29.830000,29.889999,29.889999,2129470

  # NAB.AX Mon 6 Nov 2017 gives
  # Date,Open,High,Low,Close,Adj Close,Volume
  # 2017-11-01,31.889999,32.389999,31.809999,31.950001,31.950001,12516393
  # 2017-11-02,32.000000,32.009998,31.610001,31.780001,31.780001,7329859
  # 2017-11-05,31.830000,31.830000,31.610001,31.620001,31.620001,736485
  # which is Thu 2 Nov and Sun 5 Nov, being 9:30am or some such in GMT

  my $symbol;
  $symbol = 'NOSUCH.AX';
  $symbol = 'NAB.AX';
  $symbol = 'FBU.NZ';
  my $events;
  $events = 'div';
  $events = 'split|history';
  $events = 'split';

  my $data  = App::Chart::Yahoo::daily_cookie_data($symbol);
  ### $data
  my $crumb = $data->{'crumb'};

  require App::Chart::UserAgent;
  my $ua = App::Chart::UserAgent->instance;
  my $jar   = App::Chart::Yahoo::http_cookies_from_string($data->{'cookies'} // '');
  $ua->cookie_jar ($jar);

  my $end   = time() + 86400  - 86400*90;
  my $start = $end - 86400*5;  # *365

  # GXY.AX split 22 May 17
  $symbol = 'GXY.AX';
  $start = Time::Local::timegm_modern (0,0,0, 10, 5-1, 2017);
  $end   = Time::Local::timegm_modern (0,0,0, 30, 5-1, 2017);

  my $url = "https://query1.finance.yahoo.com/v7/finance/download/$symbol?period1=$start&period2=$end&interval=1d&region-AU&events=$events&crumb=$crumb";
  print "$url\n";
  my $resp = $ua->get($url);
  print "\n";

  my $resp_size = length($resp->as_string);
  print "size $resp_size\n";
  print $resp->status_line,"\n";
  print $resp->headers->as_string;
  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');
  File::Slurp::write_file('/tmp/y', {err_mode=>'carp'}, $content);
  $content = $resp->decoded_content (raise_error => 1);
  print $content;

  exit 0;
}
{
  # daily_parse_split()
  require HTTP::Response;
  my $filename = "$ENV{HOME}/chart/samples/yahoo/GXY-split.csv";
  my $resp = HTTP::Response->new();
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/html; charset=utf-8');
  my $h = {};
  App::Chart::Yahoo::daily_parse_split('GXY.AX', $resp, $h);
  print Dumper(\$h);
  exit 0;
}
{
  # json v7 download

  my $symbol;
  $symbol = 'NAB.AX';
  $symbol = 'FBU.AX';
  $symbol = 'NOSUCH.AX';
  $symbol = '^AORD';
  $symbol = '^GSPC';
  $symbol = 'RMX.AX';
  $symbol = 'SCG.AX';
  $symbol = 'TTS.AX';
  $symbol = 'XAUUSD=X';
  my $end   = time() + 86400*2;
  my $start = $end - 86400*10;

  # GXY.AX split 22 May 17
  $symbol = 'GXY.AX';
  require Time::Local;
  $start = Time::Local::timegm_modern (0,0,0, 16, 5-1, 2017);
  $end   = Time::Local::timegm_modern (0,0,0, 28, 5-1, 2017);

  print POSIX::asctime(POSIX::gmtime($start));
  print POSIX::asctime(POSIX::gmtime($end));

  my $events;
  $events = "div%7Csplit";
  $events = "div";
  $events = "div|split";
  $events = "history%7Cdiv%7Csplit";
  $events = "split";
  my $url = "https://query1.finance.yahoo.com/v7/finance/chart/$symbol"
    ."?period1=$start&period2=$end&interval=1d&events=$events";

  # seem to be defaults:
  # &includeTimestamps=true
  # &indicators=quote

  require App::Chart::UserAgent;
  my $ua = App::Chart::UserAgent->instance;
  my $resp = $ua->get($url);

  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');
  File::Slurp::write_file('/tmp/z', {err_mode=>'carp'}, $content);
  $content = $resp->decoded_content (raise_error => 1);
  print $content;

  exit 0;
}
{
  # json v8 with flonum values rounding

  # https://query2.finance.yahoo.com/v8/finance/chart/IBM?formatted=true&lang=en-US&region=US&period1=1504028419&period2=1504428419&interval=1d&events=div%7Csplit&corsDomain=finance.yahoo.com

  # https://forums.yahoo.net/t5/Yahoo-Finance-help/Is-Yahoo-Finance-API-broken/td-p/250503/page/14
  # https://forums.yahoo.net/t5/Yahoo-Finance-help/Is-Yahoo-Finance-API-broken/td-p/250503/page/23

  # {"chart":
  #    {"result":
  #     [{"meta":
  #       {"currency":"AUD",
  #        "symbol":"NAB.AX",
  #        "exchangeName":"ASX",
  #        "instrumentType":"EQUITY",
  #        "firstTradeDate":570398400,
  #        "gmtoffset":36000,
  #        "timezone":"AEST",
  #        "exchangeTimezoneName":"Australia/Sydney",
  #        "currentTradingPeriod":
  #         {"pre":{"timezone":"AEST",
  #                 "end":1504828800,
  #                 "start":1504818000,
  #                 "gmtoffset":36000},
  #          "regular":{"timezone":"AEST",
  #                     "end":1504850400,
  #                     "start":1504828800,
  #                     "gmtoffset":36000},
  #          "post":{"timezone":"AEST",
  #                  "end":1504851120,
  #                  "start":1504850400,
  #                  "gmtoffset":36000}},
  #          "dataGranularity":"1d",
  #          "validRanges":["1d","5d","1mo","3mo","6mo","1y","2y","5y","10y","ytd","max"]},
  #       "timestamp":[1504483200,1504569600,1504656000,1504742400,1504845136],
  #       "indicators":
  #       {"quote":
  #          [{"high":[30.385000228881836,30.399999618530273,30.209999084472656,30.3799991607666,30.170000076293945],
  #            "low":[30.15999984741211,30.100000381469727,29.950000762939453,30.0,29.829999923706055],
  #            "close":[30.260000228881836,30.350000381469727,30.149999618530273,30.170000076293945,29.885000228881836],
  #            "open":[30.270000457763672,30.290000915527344,30.059999465942383,30.299999237060547,30.170000076293945],
  #            "volume":[2059508,2240849,4332445,3451099,2144174]}],
  #            "unadjclose":[{"unadjclose":[30.260000228881836,30.350000381469727,30.149999618530273,30.170000076293945,29.885000228881836]}],
  #            "adjclose":[{"adjclose":[30.260000228881836,30.350000381469727,30.149999618530273,30.170000076293945,29.885000228881836]}]}}],
  #            "error":null}}

  my $symbol;
  $symbol = 'NAB.AX';
  $symbol = 'XAUUSD=X';
  my $end   = time();
  my $start = $end - 86400*30;

  # # GXY.AX split 22 May 17
  # $symbol = 'GXY.AX';
  # require Time::Local;
  # $start = Time::Local::timegm_modern (0,0,0, 16, 3-1, 2017);
  # $end   = Time::Local::timegm_modern (0,0,0, 20, 3-1, 2017);

  print POSIX::asctime(POSIX::gmtime($start));
  print POSIX::asctime(POSIX::gmtime($end));

  my $events;
  $events = "div%7Csplit";
  $events = "split";
  $events = "div";
  $events = "history";
  $events = "history|split";
  my $url = "https://query2.finance.yahoo.com/v8/finance/chart/$symbol?formatted=true&lang=en-US&region=US&period1=$start&period2=$end&interval=1d&events=$events&corsDomain=finance.yahoo.com";

  require App::Chart::UserAgent;
  my $ua = App::Chart::UserAgent->instance;
  my $resp = $ua->get($url);

  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');
  File::Slurp::write_file('/tmp/z', {err_mode=>'carp'}, $content);
  $content = $resp->decoded_content (raise_error => 1);
  print $content;

  exit 0;
}


{
  # json v7 latest parse

  my $symbol = 'NAB.AX';
  my $filename = "$ENV{HOME}/chart/samples/yahoo/GXY-v7.json";
  $filename = "$ENV{HOME}/chart/samples/yahoo/NOSUCH-v7.json";
  $filename = "$ENV{HOME}/chart/samples/yahoo/GSPC-v7.json";
  $filename = "$ENV{HOME}/chart/samples/yahoo/RMX-v7.json";
  $filename = "$ENV{HOME}/chart/samples/yahoo/SCG-v7.json";
  require HTTP::Response;
  my $resp = HTTP::Response->new();
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/html; charset=utf-8');
  my $h = App::Chart::Yahoo::latest_parse ($symbol, $resp);
  print Dumper(\$h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;
}





{
  my $symbol = 'NAB.AX';
  $symbol = 'IBM';
  $symbol = 'BLT.L';
  $symbol = 'FBU.NZ';
  my $timezone = App::Chart::TZ->for_symbol($symbol);

  my $got;
  my $offset;
  $offset = App::Chart::Yahoo::daily_date_fixup($timezone,2017,11,5);
  $got = App::Chart::Yahoo::daily_date_fixup($symbol,'2017-11-05');
  ### $offset
  ### $got

  $offset = App::Chart::Yahoo::daily_date_fixup($timezone,2017,6,5);
  $got = App::Chart::Yahoo::daily_date_fixup($symbol,'2017-06-05');
  ### $offset
  ### $got

  print POSIX::asctime(POSIX::gmtime(1509874200));
  print POSIX::asctime(POSIX::gmtime(1509927735));
  print POSIX::asctime(POSIX::localtime(1509927735));
  exit 0;
}
{
  # daily_parse()

  my $symbol = 'NAB.AX';
  my $filename = "$ENV{HOME}/chart/samples/yahoo/daily.csv";
  require HTTP::Response;
  my $resp = HTTP::Response->new();
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/html; charset=utf-8');
  my $h = { source          => __PACKAGE__,
            prefer_decimals => 2,
            date_format   => 'ymd',
          };
  App::Chart::Yahoo::daily_parse
      ($symbol, $resp, $h, App::Chart::ymd_to_tdate_floor(2017,9,7));
  print Dumper(\$h);
  exit 0;

  # (chart-quote "NAB.AX")
  # (chart-latest "NAB.AX" 'last)
}
{
  # latest_parse() for quotes

  my $symbol = 'NAB.AX';
  my $filename = "$ENV{HOME}/chart/samples/yahoo/daily.csv";
  require HTTP::Response;
  my $resp = HTTP::Response->new();
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/html; charset=utf-8');
  my $h = App::Chart::Yahoo::latest_parse
    ($symbol, $resp, App::Chart::ymd_to_tdate_floor(2017,9,1));
  print Dumper(\$h);
  # App::Chart::Download::write_latest_group ($h);
  exit 0;

  # (chart-quote "NAB.AX")
  # (chart-latest "NAB.AX" 'last)
}

{
  # 13:30
  # -offset is 17:30
  # +offset is  9:30
  my $offset = -14400;
  print POSIX::asctime(POSIX::gmtime(1504099800 + $offset));
  print POSIX::asctime(POSIX::gmtime(1504272600 + $offset));

  # 14:32
  # +offset is 14:32
  $offset = 36000;
  print POSIX::asctime(POSIX::gmtime(1504845136 + $offset));
  exit 0;
}

{
  # kill the crumb
  App::Chart::Database->write_extra ('', 'yahoo-daily-cookies', undef);
  exit;
}


{
  # cf
  # https://gist.github.com/Mister-Meeseeks/df985c5e3abb1be88004319f11ebe3fb/raw/a6541d2a7cda6376ad0fc20fecd3388c7ada49ca/pullYahoo.sh
  #
  # "CrumbStore":{"crumb":"pwrULw9Alv\u002F"}

  require File::Slurp;
  require HTTP::Cookies;
  require App::Chart::UserAgent;

  my $symbol = 'GXY.AX';
  my $ua = App::Chart::UserAgent->instance;
  my $jar = HTTP::Cookies->new;
  $ua->cookie_jar ($jar);

  $ua->add_handler (request_send => sub {
                      my ($request, $ua, $headers) = @_;
                      print $request->method," ",$request->uri,"\n";
                      print $request->headers->as_string,"\n";
                      return;
                    });

  my $crumb;
  if (0) {
    my $url = "https://finance.yahoo.com/quote/$symbol/history?p=$symbol";
    my $resp = $ua->get($url);
    my $resp_size = length($resp->as_string);
    print "size $resp_size\n";
    print $resp->status_line,"\n";
    print $resp->headers->as_string;
    my $content = $resp->decoded_content (raise_error => 1, charset => 'none');
    File::Slurp::write_file('/tmp/x', {err_mode=>'carp'}, $content);
    $content = $resp->decoded_content (raise_error => 1);
    $content =~ /"CrumbStore":\{"crumb":"([^"]*)"}/;
    $crumb = $1;
    print "crumb raw     $crumb\n";
    $crumb = App::Chart::Yahoo::javascript_string_unquote($crumb);
    $jar->save('/tmp/cookie3.txt');
  } else {
    $crumb = 'GmF7zbT8OWV';
    $jar->load('/tmp/cookie3.txt');
  }
  print "crumb decoded $crumb\n";
  print "cookies\n";
  print $jar->as_string;
  print "\n";

  my $events;
  $events = 'history';
  $events = 'div';
  $events = 'split,history';

  print "now CSV\n";
  print "\n";
  my $end   = time();
  my $start = $end - 86400*5;
  my $url = "https://query1.finance.yahoo.com/v7/finance/download/$symbol?period1=$start&period2=$end&interval=1d&events=$events&crumb=$crumb";
  print "$url\n";
  my $resp = $ua->get($url);
  print "\n";

  my $resp_size = length($resp->as_string);
  print "size $resp_size\n";
  print $resp->status_line,"\n";
  print $resp->headers->as_string;
  my $content = $resp->decoded_content (raise_error => 1, charset => 'none');
  File::Slurp::write_file('/tmp/y', {err_mode=>'carp'}, $content);
  $content = $resp->decoded_content (raise_error => 1);
  print $content;

  exit 0;
}
{
  # timegm 00:00:00 AAPL last day missed, TSCO.L ok, BHP.AX ok
  # end +86399 AAPL ok, TSCO.L and BHP.AX extra day
  my $symbol;
  $symbol = 'BHP.AX';
  $symbol = 'AAPL';
  $symbol = 'TSCO.L';
  $symbol = 'WPL.AX';
  $symbol = 'WFD.AX';
  $App::Chart::option{'verbose'} = 2;
  my ($url,$jar) = App::Chart::Yahoo::daily_url_and_cookiejar
    ($symbol,
     App::Chart::ymd_to_tdate_floor (2017,8,15),
     App::Chart::ymd_to_tdate_floor (2017,9,8));
  ### $url
  ### jar: $jar->as_string
  my $resp = App::Chart::Download->get($url,
                                       cookie_jar => $jar,
                                       allow_404 => 1);
  my $resp_size = length($resp->as_string);
  print "size $resp_size\n";
  print $resp->status_line,"\n";
  print $resp->headers->as_string;
  my $content = $resp->decoded_content (raise_error => 1);
  print $content;
  print "\n";
  exit 0;
}


{
  # App::Chart::Database->write_extra ('', 'yahoo-daily-cookies', undef);

  $App::Chart::option{'verbose'} = 2;
  my ($url,$jar) = App::Chart::Yahoo::daily_url_and_cookiejar
    ('BHP.AX',
     App::Chart::ymd_to_tdate_floor (2017,8,20),
     App::Chart::ymd_to_tdate_floor (2017,9,4));
  ### $url
  ### jar: $jar->as_string
  exit 0;
}
{
  $App::Chart::option{'verbose'} = 1;
  my $h = App::Chart::Yahoo::daily_cookie_data('AMP.AX');
  ### $h
  exit 0;
}


#------------------------------------------------------------------------------

{
  my $filename = $ENV{'HOME'}.'/chart/samples/yahoo/exchanges.html';
  $filename = $ENV{'HOME'}.'/chart/samples/yahoo/SLN2310.html';
  require HTTP::Response;
  my $resp = HTTP::Response->new();
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/html; charset=utf-8');
  my $h = App::Chart::Yahoo::exchanges_parse ($content);
  print Dumper(\$h);
  exit 0;
}
{
  require HTTP::Response;
  require App::Chart::Suffix::AX;
  my $resp = HTTP::Response->new();
  #  my $filename = <~/chart/samples/yahoo/latest.csv>;
  my $filename = <~/chart/samples/yahoo/latest-C.csv>;
  # my $filename = "/tmp/d";
  my $content = slurp ($filename);
  $resp->content($content);
  $resp->content_type('text/plain');
  my $h = App::Chart::Yahoo::latest_parse ($resp);
  print Dumper(\$h);
  App::Chart::Download::write_latest_group ($h);
  exit 0;
}
{
  require HTTP::Response;
  my $resp = HTTP::Response->new();
  my $content = slurp ("$ENV{'HOME'}/chart/samples/yahoo/latest-C.csv");
  $resp->content($content);
  my $h = App::Chart::Yahoo::latest_parse($resp);
  print $h;
  exit 0;
}

{
  require App::Chart;
  require App::Chart::Suffix::AX;
  my $url = App::Chart::Yahoo::daily_url
    ('NABHA.AX',
     App::Chart::ymd_to_tdate_floor (2015,6,1),
     App::Chart::ymd_to_tdate_floor (2015,6,26));
  print $url,"\n";
  exit 0;
}


{
  require App::Chart::Suffix::AX;
  foreach my $symbol ('NAB.AX','NABHA.AX') {
    my $tz = App::Chart::TZ->for_symbol($symbol);
    print Dumper($tz);
  }
  exit 0;
}

{
  my $h = App::Chart::Yahoo::exchanges_data ();
  print Dumper(\$h);
  exit 0;
}


{
  my $timezone_gmt = App::Chart::TZ->new (tz => 'GMT');
  print $timezone_gmt->tz,"\n";
  # print App::Chart::Yahoo::mktime_in_zone (0,0,0,1,0,100, $timezone_gmt);
  exit 0;
}
{
  my $resp = HTTP::Response->new(200,'OK');
  my $content = slurp (<~/chart/samples/yahoo/info.csv>);
  $resp->content($content);
  my $h = App::Chart::Yahoo::info_parse ($resp);
  print Dumper ($h);
#  App::Chart::Download::write_daily_group ($h);
  exit 0;
}

{
  App::Chart::Database->add_symbol ('ETR.AX');
  my $resp = HTTP::Response->new();
  my $content = slurp ($ENV{'HOME'}.'/chart/samples/yahoo/etr.csv');
  $resp->{'_rc'} = 200;
  $resp->content($content);
  die if ($resp->decoded_content(charset=>'none') ne $content);
  my $h = App::Chart::Yahoo::daily_parse ('ETR.AX', $resp);
  print Dumper ($h);
  App::Chart::Download::write_daily_group ($h);
  exit 0;
}

{
  my $content = slurp ('/nosuchfile');
  exit 0;
}

{
  my $zone = App::Chart::TZ->sydney;
  print "syd ", Dumper (\$zone);
  $zone = App::Chart::TZ->for_symbol ('BHP.AX');
  print "AX ", Dumper (\$zone);
  $zone = App::Chart::TZ->for_symbol ('^GSPC');
  print "GSPC ", Dumper (\$zone);
  exit 0;
}

{
  App::Chart::Yahoo::latest_download (['BHP.AX','^GSPC']);
  exit 0;
}

{
  print App::Chart::Yahoo::latest_parse_div_date("24-Sep-12");
  print App::Chart::Yahoo::latest_parse_div_date(" 5 Jan");
  exit 0;
}
{
  my ($ss,$mm,$hh,$day,$month,$year,$zone) = Date::Parse::strptime ("24 Sep 2004");
  print "$ss,$mm,$hh,$day,$month,$year,$zone\n";
  exit 0;
}
{
  my ($year, $month, $day) = Date::Calc::Decode_Date_EU ("7 Jan");
  print "$year, $month, $day\n";
  exit 0;
}
