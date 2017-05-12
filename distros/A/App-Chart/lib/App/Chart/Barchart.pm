# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2015 Kevin Ryde

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


package App::Chart::Barchart;
use 5.006;
use strict;
use warnings;
use Carp;
use Date::Calc;
use Date::Parse;
use List::Util qw (min max);
use POSIX ();
use URI::Escape;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;
use App::Chart::DownloadHandler;
use App::Chart::IntradayHandler;
use App::Chart::Latest;
use App::Chart::Pagebits;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;

# uncomment this to run the ### lines
#use Smart::Comments;


our $latest_pred = App::Chart::Sympred::Any->new;
our $intraday_pred = App::Chart::Sympred::Any->new;
our $fiveday_pred = App::Chart::Sympred::Any->new;

# overridden by specific nodes
App::Chart::setup_source_help
  ($fiveday_pred, __p('manual-node','Barchart'));

sub setup {
  my ($setup_pred) = @_;
  $latest_pred->add ($setup_pred);
  $intraday_pred->add ($setup_pred);
  $fiveday_pred->add ($setup_pred);
}

#-----------------------------------------------------------------------------
# various

sub cookie_jar {
  require HTTP::Cookies;
  my $jar = HTTP::Cookies->new;

  # Set-Cookie: bcad_int=1; path=/; domain=barchart.com;
  $jar->set_cookie(undef,            # version
                   'bcad_int',       # key
                   '1',              # value
                   '/',              # path
                   '.barchart.com'); # domain
  return $jar;
}


#-----------------------------------------------------------------------------
# symbol munging

my @commodity_mung;

sub commodity_mung {
  my ($pred, %table) = @_;
  push @commodity_mung, [ $pred, \%table ];
}

sub symbol_to_barchart {
  my ($symbol) = @_;
  foreach my $elem (@commodity_mung) {
    if ($elem->[0]->match ($symbol)) {
      my $commodity = App::Chart::symbol_commodity ($symbol);
      my $barchart = $elem->[1]->{$commodity};
      if (defined $barchart) {
        $symbol =~ s/^\Q$commodity/$barchart/;
      }
      last;
    }
  }
  $symbol =~ s/.[^.]*$//;
  return $symbol;
}


#------------------------------------------------------------------------------
# latest
#
# The intraday commodity quotes pages are used, like oats
#
#     http://www2.barchart.com/ifutpage.asp?code=BSTK&sym=O
#
# which is about 35 kbytes each.  An alternative would be the combined
# pages like all grains
#
#     http://www2.barchart.com/mktcom.asp?code=BSTK&section=grains
#
# which has the front month or two of various at about 50kbytes the lot.

App::Chart::LatestHandler->new
  (pred => $latest_pred,
   proc => \&latest_download,
   max_symbols => 1);

sub latest_download {
  my ($symbol_list) = @_;

  my $symbol = $symbol_list->[0];
  my $commodity = App::Chart::symbol_commodity ($symbol);
  my $suffix    = App::Chart::symbol_suffix    ($symbol);
  my $barchart_commodity = symbol_to_barchart ("$commodity$suffix");

  App::Chart::Download::status
      (__x('Barchart quote {symbol} ({barchart_commodity})',
           symbol => "$commodity$suffix",
           barchart_commodity => $barchart_commodity));

  my $url = 'http://www2.barchart.com/ifutpage.asp?code=BSTK&sym='
    . URI::Escape::uri_escape ($barchart_commodity);

  my $resp = App::Chart::Download->get ($url,
                                       cookie_jar => cookie_jar(),
                                       referer => $url);
  my $h = ifutpage_parse ($commodity, $suffix, $resp);
  App::Chart::Download::write_latest_group ($h);
}

sub ifutpage_parse {
  my ($commodity, $suffix, $resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);

  my @data = ();
  my $h = { source      => __PACKAGE__,
            resp        => $resp,
            front_month => 1,
            data        => \@data };

  # eg. "   <B>CRUDE OIL</B> Delayed Futures -20:10 - Sunday, 19 June"
  #     "   <B>SIMEX NIKKEI 225</B> Delayed Futures -18:20 - Tuesday, 12 December</td>"
  #     "   <B>OATS   </B> Daily Futures -     Friday, 20 April                 </td>
  $content =~ m{([^<>\r\n]+) *</B> Delayed Futures *- *([0-9]+:[0-9]+) *- *[A-Za-z]+, ([0-9]+ [A-Za-z]+)}is
    or die 'Barchart: ifutpage name/date/time not matched';
  my $name = $1;
  my $head_time = $2;
  my $head_date = $3;
  ### ifutpage head name: $name
  ### $head_time
  ### $head_date
  require App::Chart::Suffix::NZ;
  $head_date = App::Chart::Suffix::NZ::dm_str_to_nearest_iso ($head_date);

  require HTML::TableExtract;

  my $te = HTML::TableExtract->new
    (headers => ['Contract', 'Last', 'Change', 'Open', 'High', 'Low', 'Time']);
  $te->parse($content);
  if (! $te->tables) { die 'Barchart: ifutpage price columns not matched'; }

  foreach my $row ($te->rows) {
    ### ifutpage row: $row

    my ($month, $last, $change, $open, $high, $low, $time) = @$row;

    # eg. "August '05 ( CLQ05 )"
    $month =~ /\( *([^ )]+) *\)/p
      or die 'Barchart: ifutpage month form not recognised';
    my $month_name = ${^PREMATCH}; # "August '05"
    my $bar_symbol = $1;           # "CLQ05"
    my $MYY = substr ($bar_symbol, -3);
    my $symbol = $commodity . $MYY . $suffix;
    $month_name = App::Chart::collapse_whitespace ($month_name);
    my $month_iso =App::Chart::Download::Decode_Date_EU_to_iso("1 $month_name");

    #     # subtract normal exchange delay to get quote time
    #     (set! quote-time (- quote-time (barchart-symbol-delay symbol)))
    #     (if (negative? quote-time)
    # 	(begin
    # 	  (set! quote-time (+ quote-time 86400))
    # 	  (set! quote-adate (1- quote-adate))))
    #

    # trailing "s" on last for settlement price
    # have also seen "c", maybe for close
    $last =~ s/[cs]$//i;

    my ($last_date, $last_time);
    if ($time =~ /:/) {
      # time is HH:MM on same day as the quote
      $last_date = $head_date;
      $last_time = $time;
      ($last_date, $last_time)
        = datetime_chicago_to_symbol ($symbol, $last_date, $last_time);

    } else {
      # time is a date MM/DD/YY later (on the weekend)
      $last_date = App::Chart::Download::Decode_Date_US_to_iso ($time);

      # FIXME: convert date from Chicago ?
    }

    # dash is frac in various CBOT
    if ($last =~ /-/) {
      $open   = dash_frac_to_decimals ($open);
      $high   = dash_frac_to_decimals ($high);
      $low    = dash_frac_to_decimals ($low);
      $last   = dash_frac_to_decimals ($last);
      $change = dash_frac_to_decimals ($change);
    }

    push @data, { symbol      => $symbol,
                  name        => "$name $month_name",
                  month       => $month_iso,

                  # quote_date  => $quote_date,
                  # quote_time  => $quote_time,

                  last_date   => $last_date,
                  last_time   => $last_time,
                  open        => $open,
                  high        => $high,
                  low         => $low,
                  last        => $last,
                  change      => $change,
                };
  }
  return $h;
}

sub datetime_chicago_to_symbol {
  my ($symbol, $date, $time) = @_;

  my $chicago = App::Chart::TZ->chicago;
  my $stimezone = App::Chart::TZ->for_symbol ($symbol);
  if ($stimezone == $chicago) { return ($date, $time); }

  my ($sec,$min,$hour,$mday,$mon,$year)
    = Date::Parse::strptime($date . ' ' . $time);
  require App::Chart::Yahoo;
  my $timet = App::Chart::Yahoo::mktime_in_zone
    ($sec, $min, $hour, $mday, $mon, $year, $chicago);
  return $stimezone->iso_date_time ($timet);
}

# FIXME: Share with Finance::Quote::Barchart
#
# convert number like "99-1" with dash fraction to decimals like "99.125"
# single dash digit is 1/8s
# three dash digits -xxy is xx 1/32s and y is 0,2,5,7 for further 1/4, 2/4,
# or 3/4 of 1/32
#
my %qu_to_quarter = (''=>0, 0=>0, 2=>1, 5=>2, 7=>3);
sub dash_frac_to_decimals {
  my ($str) = @_;

  $str =~ /^\+?(.+)-(.*)/p or return $str;
  my $int = $1;
  my $frac = $2;

  if (length ($frac) == 1) {
    # 99-1
    # only 2 decimals for 1/4s, since for various commodities that's the
    # minimum tick
    return $int + ($frac / 8);

  } elsif (length ($frac) == 2 || length ($frac) == 3) {
    # 109-30, in 1/32nds
    # 99-130, in 1/32s then last dig 0,2,5,7 further 1/4s of that
    my $th = substr $frac, 0, 2;
    if ($th > 31) {
      die "Barchart: dash thirtyseconds out of range: $str";
    }
    my $qu = substr($frac, 2, 1);
    if (! exists $qu_to_quarter{$qu}) {
      die "Barchart: dash thirtyseconds further quarters unrecognised: $str";
    }
    $qu = $qu_to_quarter{$qu};
    return $int + (($th + $qu / 4) / 32);

  } else {
    die "Barchart: unrecognised dash number: $str";
  }
}


#-----------------------------------------------------------------------------
# 5-day download
#
# This uses the rolling 5-day quote pages like
#
#     http://www.barchart.com/detailedquote/futures/CLZ16
#
use constant FIVEDAY_URL_BASE =>
  'http://www.barchart.com/detailedquote/futures/';
#
# which has daily open, high, low and close, volume.
#
# Going back only five days isn't good for much, but it's better than
# nothing and regular updates accumulate enough for a short-term picture.

App::Chart::DownloadHandler->new
  (name            => __('Barchart'),
   pred            => $fiveday_pred,
   available_tdate => \&fiveday_available_tdate,
   proc            => \&fiveday_download,
   max_symbols     => 1);

# latest data available from barchart 5-day quote page
# the support page says the daily pages update at 5pm US central, try 5pm
# local for the 5-day
sub fiveday_available_tdate {
  return App::Chart::Download::weekday_tdate_after_time
    (17,0, App::Chart::TZ->chicago, -1);
}

sub fiveday_download {
  my ($symbol_list) = @_;

  my $symbol = $symbol_list->[0];
  if (App::Chart::symbol_is_front ($symbol)) { return; }

  # my $commodity = App::Chart::symbol_commodity ($symbol);
  my $suffix    = App::Chart::symbol_suffix    ($symbol);
  my $barchart_symbol = symbol_to_barchart ($symbol);

  if ($barchart_symbol.$suffix eq $symbol) {
    App::Chart::Download::status
        (__x('Barchart five day {symbol}',
             symbol => $symbol));
  } else {
    App::Chart::Download::status
        (__x('Barchart five day {symbol} ({barchart_symbol})',
             symbol => $symbol,
             barchart_symbol => $barchart_symbol));
  }

  my $url = FIVEDAY_URL_BASE . URI::Escape::uri_escape ($barchart_symbol);

  my $resp = App::Chart::Download->get ($url,
                                       cookie_jar => cookie_jar(),
                                       referer => $url);
  my $h = fiveday_parse ($symbol, $resp);
  App::Chart::Download::write_daily_group ($h);
}

sub fiveday_parse {
  my ($symbol, $resp) = @_;

  my @data;
  my $h = { source          => __PACKAGE__,
            prefer_decimals => 2,
            date_format     => 'mdy',
            data            => \@data };

  my $content = $resp->decoded_content (raise_error => 1);

  # message in table when no info for given symbol (eg. an old month/year)
  if ($content =~ /In order to form an extended quote/) {
    return $h;
  }

  # eg. <h1 class="fl" id="symname">Crude Oil WTI December 2016 (CLZ16)</h1>
  #
  $content =~ m{<h1[^>]* id="symname">(([^<\r\n]*?) [a-z]+ [0-9]+)}si
    or die "Barchart fiveday heading not matched";
  my $name = $1;
  ### $name

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => ['Date', 'Open', 'High', 'Low', 'Last', 'Volume']);
  $te->parse($content);
  my ($ts) = $te->tables
    or die 'Barchart: fiveday price columns not matched';

  foreach my $row ($ts->rows) {
    ### fiveday row: $row
    my ($date, $open, $high, $low, $close, $volume) = @$row;

    $open  = dash_frac_to_decimals ($open);
    $high  = dash_frac_to_decimals ($high);
    $low   = dash_frac_to_decimals ($low);
    $close = dash_frac_to_decimals ($close);

    push @data, { symbol  => $symbol,
                  name    => $name,
                  date    => $date,
                  open    => $open,
                  high    => $high,
                  low     => $low,
                  close   => $close,
                  volume  => $volume,
                };
  }
  return $h;
}


#-----------------------------------------------------------------------------
# intraday
#
# This uses the charting pages like
#
#     http://www.barchart.com/charts/futures/CLZ10
#
# which for a 2-day intraday is
#
#     http://www.barchart.com/chart.php?sym=CLZ10&style=technical&p=I&d=O&im=&sd=&ed=&size=M&log=0&t=BAR&v=2&g=1&evnt=1&late=1&o1=&o2=&o3=&x=41&y=11&indicators=&addindicator=&submitted=1&fpage=&txtDate=#jump
#
# must be fetched (about 50kbytes unfortunately), and it has a gif url.
# That url is some generated 4-digit number, apparently different each
# time, even outside trading hours.  The server doesn't give an etag or
# last-modified to avoid re-downloading.
#
# The form fields are
#
#     sym=
#     date=
#     size=A      504 by 288
#          E      576 by 360
#          B      612 by 360
#          C      720 by 432
#          D      864 by 504
#     data=Z05    minutes
#          Z10     "
#          Z15     "
#          Z30     "
#          Z45     "
#          Z60     "
#          Z90     "
#          A      daily
#          D      weekly
#          G      monthly
#     den=HIGH    density
#         MEDHI
#         MED     [default]
#         MEDLO
#         LOW
#         this combines with data period for how much is shown
#                  5min    10min   15min
#         HIGH    3.5day  7day    10day  ... etc
#         MEDHI   2day    4.5day  7day
#         MED     1.5day  3day    4day
#         MEDLO   1day    2day    3day
#         LOW     0.5day  1.5day  2day
#     evnt=ADV    events
#          off
#     grid=Y/N    background green grid
#     sky=Y/N     fine grid lines
#     jav=ADV     prices on, gif file
#                 [other options for subscribers]
#     size=A      504 by 288
#          E      576 by 360
#          B      612 by 360
#          C      720 by 432
#          D      864 by 504
#     sly=N       linear
#         L       log
#         Y       fit available space
#     late=
#     ch1=011     OHLC [default]
#         012     close-only
#         013     candlestick
#         ...
#     ov1=
#     ch2=
#     ov2=
#     code=BSTKIC IC for interactive chart
#     vol=y/n     volume (not avail for 5min)

foreach my $n (1, 2, 5) {
  App::Chart::IntradayHandler->new
      (pred => $intraday_pred,
       proc => \&intraday_url,
       mode => "${n}d",
       name => __nx('_{n} Day',
                    '_{n} Days',
                    $n,
                    n => $n));
}
App::Chart::IntradayHandler->new
  (pred => $intraday_pred,
   proc => \&intraday_url,
   mode => 'daily',
   name => __('_Daily 2 Months'));
App::Chart::IntradayHandler->new
  (pred => $intraday_pred,
   proc => \&intraday_url,
   mode => 'daily',
   name => __('_Daily 1 Year'));

# 5 minute, linear scale

my %intraday_mode_to_data = ('1d'    => '&p=I&d=L',
                             '2d'    => '&p=I&d=O',
                             '3d'    => '&p=I&d=M',
                             '4d'    => '&p=I&d=H',
                             '5d'    => '&p=I&d=X',
                             'daily2m' => '&p=DO&d=L',
                             'daily1y' => '&p=DO&d=X');

#                              '7d'    => '&data=Z60&den=MEDHIGH',
#                              'daily' => '&data=A');

sub intraday_url {
  my ($self, $symbol, $mode) = @_;

  App::Chart::Download::status
      (__x('Barchart intraday page {symbol} {mode}',
           symbol => $symbol,
           mode   => $mode));
  my $url = 'http://www.barchart.com/chart.php?sym='
    . URI::Escape::uri_escape (symbol_to_barchart ($symbol))
      . $intraday_mode_to_data{$mode};
  App::Chart::Download::verbose_message ("Intraday page", $url);

  my $jar = cookie_jar();
  my $resp = App::Chart::Download->get ($url,
                                        cookie_jar => $jar,
                                        referer => $url);
  return (intraday_resp_to_url ($resp, $symbol),
          cookie_jar => $jar,
          referer => $url);
}
# separate func for offline testing ...
sub intraday_resp_to_url {
  my ($resp, $symbol) = @_;
  my $content = $resp->decoded_content (raise_error => 1);

  require HTML::LinkExtor;
  my $parser = HTML::LinkExtor->new(undef, $resp->base);
  $parser->parse($content);
  $parser->eof;

  # eg. 

  # </map><img src="/cache/bde71ebe23ddac66f2d25081b1b5f953.png"
  # must match some of the link target name since there's other images in
  # the page
  foreach my $link ($parser->links) {
    my ($tag, %attr) = @$link;
    $tag eq 'img' or next;
    my $url = $attr{'src'};
    index ($url, '/cache/') >= 0 or next;
    ### $url
    return URI->new_abs($url,$resp->base)->as_string;
  }

  if ($content =~ /Could not find any symbols/i) {
    die __x("No such symbol {symbol}\n",
            symbol => $symbol);
  } else {
    die 'Barchart Customer: Intraday page not matched';
  }
}

1;
__END__
