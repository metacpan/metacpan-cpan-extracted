# Tokyo Grain Exchange (TGE) setups.                -*- coding: euc-jp -*-

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2011, 2013, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.


package App::Chart::Suffix::TGE;
use 5.010;
use strict;
use warnings;
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;
use App::Chart::DownloadHandler;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


my $pred = App::Chart::Sympred::Suffix->new ('.TGE');
App::Chart::TZ->tokyo->setup_for_symbol ($pred);
# (source-help! tge-symbol?
# 	     __p('manual-node','Tokyo Grain Exchange'))



#-----------------------------------------------------------------------------
# weblinks - contract specs
#
# eg. http://www.tge.or.jp/japanese/contract/cont_s_corn.shtml
#     http://www.tge.or.jp/english/contract/cont_s_soym.shtml
#

my %commodity_to_weblink = ('CO' => 'corn',  # Corn
                            'SM' => 'soym',  # Soybean Meal
                            'SB' => 'soy',   # Soybean
                            'NG' => 'gmo',   # Non-GMO Soybean
                            'RB' => 'azuki', # Azuki
                            'AC' => 'ara',   # Arabica Coffee
                            'RC' => 'rob',   # Robusta Coffee
                            'SG' => 'raw',   # Raw Sugar
                            'SL' => 'silk',  # Raw Silk
                            'VG' => 'vege'); # Vegetables

App::Chart::Weblink->new
  (pred => $pred,
   name => __('TGE _Contract Specifications'),
   desc => __('Open web browser at the Tokyo Grain Exchange contract specifications for this commodity'),
   proc => sub {
     my ($symbol) = @_;
     my $commodity = App::Chart::symbol_commodity ($symbol);
     my $code = $commodity_to_weblink{$commodity} || return undef;
     my $lang = App::Chart::Glib::Ex::MoreUtils::lang_select (ja => 'japanese',
                                                  en => 'english');
     return "http://www.tge.or.jp/$lang/contract/cont_s_$code.shtml";
   });

#-----------------------------------------------------------------------------
# misc

# return ISO date string of last trading for SYMBOL, or possibly a day or
# two after (because public holidays are not accounted for)
#
sub symbol_expiry {
  my ($symbol) = @_;
  my $mdate = symbol_mdate($symbol) // return undef;

  my $commodity = App::Chart::symbol_commodity ($symbol);
  # if ($commodity eq 'CO') {
  #     # corn
  #     # 15th calendar day of the month preceding the delivery month
  #     #       (receive-list (year month day)
  #     #        (mdate->ymd mdate)
  #     #        (ymd->tdate year (1- month) 15)))
  #   }
  #   when (['NG','RB','SB']) {
  #     # non-gm soybeans, azuki
  #     # 2 business days prior to delivery day; delivery day
  #     # is the business day prior to the last business day of
  #     # the delivery month or 24th for December
  #     #     (receive-list (year month day)
  #     #      (mdate->ymd mdate)
  #     #      (- (if (= 12 month)
  #     #          (ymd->tdate year month 24)
  #     #          (- (mdate->tdate (1+ mdate)) 2))
  #     #       2))
  #   }
  #   when (['NG','RB','SB']) {
  #     # arabica, robusta, soybean meal
  #     # 10 business days prior to the last business day of
  #     # the delivery month
  #     #     (- (mdate->tdate (1+ mdate)) 11)
  #   }
  #   when ('SG') {
  #     # raw sugar
  #     # last business day two months prior to delivery month
  #     #    (1- (mdate->tdate (1- mdate))))
  #   }
  #   default {
  #     # unknown, lets guess the last day of the contract month,
  #     # this won't be right but at least won't be early
  #     #       (1- (mdate->tdate (1+ mdate))))))
  #   }
  # }

  # FIXME:
  return undef;
}

# see table in http://www.tge.or.jp/japanese/price/prisel.js.php
# ENHANCE-ME: maybe download and parse that page
my %commodity_to_nav
  = ('CO' => 'tou',  # corn
     'SM' => 'dai',  # soybean meal
     'SB' => 'ipd',  # soybeans
     'NG' => 'ngd',  # non-gmo soybeans
     'RB' => 'azu',  # azuki
     'AC' => 'ara',  # arabica coffee
     'RC' => 'rob',  # robusta coffee
     'SG' => 'sot',  # raw sugar
     'SL' => 'rsl',  # raw silk
     'VG' => 'veg'); # vegetables

#-----------------------------------------------------------------------------
# download
#
# This uses the "download" under the price data page
#
#     http://www.tge.or.jp/english/price/pri_sel_01.shtml
#
# There's two files for each commodity,
#
#     http://www.tge.or.jp/data/down_load/co01.csv
#     http://www.tge.or.jp/data/down_load/co01040610050609.zip
#
# The csv is only about 600 bytes, it has just the most recent day and is
# used when that's all that's needed to update (which will be the case if
# you're updating every day).
#
# The zip is about 35kbytes and has the same most recent day as the csv,
# plus the past 12 months.  The filename is a date range
# (XX01yymmddyymmdd.zip), but there's only one file, you can't get an
# arbitrary range.
#
# The zip filename is formed from today's date, or a day or two earlier,
# but if we don't hit it that way there's a fallback to fetch and parse the
# actual download page.  The pattern in the filename is pretty clear, so
# perhaps that fallback is unnecessary.
#
# There's an ETag / Last-Modified on the year file, but it's hardly needed
# since the dates are in the name.

App::Chart::DownloadHandler->new
  (name   => __('TGE'),
   pred   => $pred,
   proc   => \&download,
   backto => undef,
   available_tdate => \&available_tdate,
   by_commodity    => 1);

sub download {
  my ($symbol_list) = @_;
  download_day ($symbol_list)
    || download_year ($symbol_list);

  # (download-name-from-latest (_ "TGE") symbol-list))
}

# return tdate for available download data
# the .csv downloads have been seen with a Last-Modified headers
#     Wed, 24 Aug 2005 01:00:20 GMT      == 10am tokyo
#     Thu, 01 Sep 2005 22:33:05 GMT      ==  7am tokyo
# so try at 10:05am tokyo
#
sub available_tdate {
  App::Chart::Download::weekday_tdate_after_time
      (10,5, App::Chart::TZ->tokyo, -1);
}

# do a download of the last day .csv file for $symbol_list, if that would
# update all those
# return true if updated successfully, or false if not (should use zip instead)
# 
sub download_day {
  my ($symbol_list) = @_;

  my $commodity = App::Chart::symbol_commodity ($symbol_list->[0]);
  my $avail_tdate = available_tdate();
  my $start_tdate = App::Chart::Download::start_tdate_for_update(@$symbol_list);

  # use csv if all of $symbol_list just wanting $avail_tdate
  if ($start_tdate < $avail_tdate) {
    return 0;
  }
  my $filename = "\L$commodity\E01.csv";
  my $url = 'http://www.tge.or.jp/data/down_load/'
    . URI::Escape::uri_escape ($filename);

  App::Chart::Download::status (__x('TGE data {filename}',
                                   filename => $filename));
  my $resp = App::Chart::Download->get ($url,
                                       url_tags_key => 'TGE-day');
  if (! $resp->is_success) {
    # not modified, no new data
    return 1;
  }
  my $got_tdate = csv_tdate ($resp);
  if ($got_tdate == $start_tdate) {
    # got the expected data, process it
    my $content = $resp->decoded_content (charset => 'none');
    my $h = csv_parse ($content);
    $h->{'url_tags_key'} = 'TGE-day';
    return 1;
  } elsif ($got_tdate < $avail_tdate) {
    # got something older, there's no new data
    return 1;
  } else {
    return 0;
  }
}

sub download_year {
  my ($symbol_list) = @_;
  my $commodity = App::Chart::symbol_commodity ($symbol_list->[0]);
  my $avail_tdate = available_tdate();


  # try 0, -1, -2 direct filenames, then finally download page
  # (allowing for new COMM_NUM values too)
  #
  download_year_attempt (download_tdate_url ($commodity, $avail_tdate))
    || download_year_attempt (download_tdate_url ($commodity, $avail_tdate - 1))
      || download_year_attempt (download_tdate_url ($commodity, $avail_tdate - 2))
        || download_year_attempt (download_page ($commodity));
}

# return true if successful
sub download_year_attempt {
  my ($commodity, $url) = @_;

  $url =~ m{/([^/]+)$/};
  my $filename = $1;
  App::Chart::Download::status (__x('TGE data {filename}',
                                   filename => $filename));

  my $resp = App::Chart::Download->get ($url, allow_404 => 1);
  if (! $resp->is_success) { return 0; }

  # got the expected data, process it
  my $h = zip_parse ($resp);
  $h->{'url_tags_key'} = 'TGE-day';
  return 1;
}

# eg. http://www.tge.or.jp/data/down_load/co01040610050609.zip
#     for Jun/10/2004 - Jun/09/2005
sub download_tdate_url {
  my ($commodity, $tdate) = @_;
  my ($end_year, $end_month, $end_day) = App::Chart::tdate_to_ymd ($tdate);

  # a year ago, plus one day
  my ($start_year, $start_month, $start_day) = Date::Calc::Add_Delta_YMD
    ($end_year, $end_month, $end_day,  -1, 0, 1);

  return sprintf 'http://www.tge.or.jp/data/down_load/%s01%02d%02d%02d%02d%02d%02d.zip',
    lc($commodity),
      $start_year % 100, $start_month, $start_day,
        $end_year % 100, $end_month, $end_day;
}

sub zip_parse {
  my ($resp) = @_;
  my $zipstr = $resp->decoded_content (charset => 'none', raise_error => 1);
  my $h;

  require Archive::Zip;
  require IO::String;
  my $zip = Archive::Zip->new;
  my $io = IO::String->new ($zipstr);
  $zip->readFromFileHandle ($io);

  foreach my $member ($zip->members) {
    my $csv = $member->contents;
    my $hh = csv_parse ($csv);
    if ($h) {
      push @{$h->{'data'}}, @{$hh->{'data'}};
    } else {
      $h = $hh;
    }
  }
  return $h;
}

sub csv_parse {
  my ($content) = @_;
  $content =~ s/\r//g;
  my @lines = split /\n/, $content;

  my $heading = shift @lines;
  $heading eq 'yr_mo_dy,contract,contract_month,contract_price_m1,contract_price_m2,contract_price_m3,contract_price_a1,contract_price_a2,contract_price_a3,sett_price,volume,open_int,net_position'
    or die "TGE: unrecognised CSV headings: $heading";

  my @data;
  my $h = { source        => __PACKAGE__,
            currency      => 'JPY',
            month_format  => 'MMM_YY',
            expiry_proc   => \&symbol_expiry_date,
            date_format   => 'ymd',
            suffix        => '.TGE',
            last_download => 1,
            data          => \@data };

  foreach my $line (@lines) {
    my ($date, $commodity, $month, $m1, $m2, $m3, $a1, $a2, $a3, $settle,
        $volume, $openint, $net)
      = split /,/, $line;

    push @data, { date      => $date,  # eg. '20040603'
                  commodity => $commodity,
                  month     => YYYYMM_to_iso($month), # eg. '200407'
                  sessions  => [$m1, $m2, $m3, $a1, $a2, $a3, $settle],
                  volume    => $volume,
                  openint   => $openint };
  }
  return $h;
}

sub YYYYMM_to_iso {
  my ($str) = @_;
  return substr($str,0,4) . '-' . substr($str,4) . '-01';
}

1;
__END__
